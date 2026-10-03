# Cythera 1.0.4 — trade and economy (code reading)

Register: **code reading**. Every claim carries HIGH (quoted bytecode or decompiled lines prove
it), MED (inferred) or LOW (conjecture). Listing citations are `segid @ offset` from
`ghidra/cythera-scripts/<segid>.txt` (scriptdis output, decrypted, git-ignored); engine citations
are `function @ addr` from `ghidra/Cythera_pef.decompiled.c` / `Cythera_builtins.decompiled.c`.
Headline: **trade is entirely scenario bytecode** on top of eight inventory builtins. One live
buy routine (`R0EA5`, 22 call sites), one live sell routine (`R0EA9`, 2 call sites), a money
library on page 0x0D, and per-merchant **markup bytes** in `CharEntry +0x17` make up the economy.
Six older shop routines on page 0x0E are dead in 1.0.4.

---------------------------------------------------------------------------------------------
## 0. Scope, method, what was not read

- Read this session: `script-census.md` (whole), `script-vm.md` (whole), `script-builtins.md`
  §1–§4, `rules.md` (whole), `data-format.md` §1.3, §4, §5, §6.1, `engine-classes.md` §2 (names
  only). Listings read in full: 0D01–0D0A, 0E91, 0E92, 0E93, 0E94, 0EA2, 0EA4–0EA9, 0EAC, 0EAF,
  0EB1, 0E8B, 0812, 0813 (first 50 lines), 0301, 100E, 1082, 1146, 1AFC, 1AFD, 300F, 3015, 3043,
  and the trade sections of 1810–186A (each `R0EA5`/`R0EA9`/`R0D05` site with its context).
- Engine bodies read: `Builtin_B4/B7/B8/C0/CA`, `GetObjectWeight @ 100554e4`, `GetMaxInvEncumb @
  100558f8`, `GetCurInvEncumb @ 10055a58`, `GetCurEquEncumb @ 10055c00`, `TakeCommand @
  10053fd8`, `WieldCommand @ 100545b8` (encumbrance part), `ConjoinProp @ 10055f48`,
  `GetItemCount @ 1005577c`, `SetItemCount @ 1005560c`, `GetField @ 100921b4` (cases 4–0xA,
  0x27, class 0x48), `SetField @ 10092bd4` (0x27, 9), `GetGlobal` (6, 7), `FillIntfCache` (0x24),
  `IsEqual @ 10080adc`, `DoExpr` case 0x4D, `DrawWeightPart @ 1002c7e0`.
- Data read with `tools/seg.py`: 0xF009 byte +0x17 for all 256 CharEntries, 0xF008 byte 6 for
  the first 128 records, 0x0201 names.
- **Not read**: `TInteraction::PickItem` / `HowMany` bodies (cited from script-builtins.md as
  MED); the sysnew widget classes 0x06/0x08/0x10/0x11/0x12 (their fields `f37`, `f3C`–`f40` are
  read only as the scripts use them); `TInventoryWindow`, `TInventoryPile`, `TDroppableWindow`
  (pointers: engine-classes.md §2.1 rows 36–41 — they move props, they do not price them);
  0813 rumour lines beyond the first page; the combat use of weapon quality.
- **Hintbook**: the data folder holds only a link file ("Stuck_ Get the Cythera Hintbook"), no
  PDF — no hintbook page could be cited. Every LOW below is plain conjecture.
- Arithmetic notation: `/` is the VM's 0x4D, C signed division truncating toward zero, ÷0 → 0
  (`DoExpr` case 0x4d: `((int)(local_44 << 4 | …) >> 4) / ((int)(local_48 << 4 | …) >> 4)`; zero
  divisor pushes 0) [HIGH]. `random(lo, hi)` = `lo + Random() mod (hi − lo)`, i.e. lo..hi−1
  (script-builtins.md AC) [HIGH].

---------------------------------------------------------------------------------------------
## 1. Currency: the obol (prop type 130) and the page-0x0D money library

### 1.1 The item
- **Type 130 = 0x082 is the coin** ("obol\s/oi" in 0xF004). Its class segment 0x1082 defines
  only properties: `1082 @ 0053 .dict … {36/p_weight: @0041, 40/p_typeflags28: @0047, 51: @0002,
  60: @004D}` with `@0041 array[1] = [1]`, `@0047 array[1] = [34]`, `@004D array[1] = [1]`.
  [HIGH]
- Weight 1 per coin: `FillIntfCache` reads element 0 of property 0x24 and stores it in the byte
  weight table when it is an integer (`_GetProperty__7TInterpFs5VAddrs(&local_4c,0x24,local_44,0);
  if ((local_4c & 0xf0000000) == 0) { … PTR_DAT_100cde7c[(short)uVar8] = (char)…`). [HIGH]
- Type flags 34 = 0x22 → 0x200 (u16 count at +6) and 0x2000 (frame shows stack size)
  per data-format.md §4.4. [HIGH via that table]
- **Selector 60 (0x3C) = "value per unit"**: census §5 lists exactly **one** class defining
  property 60 — this one — and every money routine multiplies `prop(x, sel60, 0) * count`
  (§1.2). So money = Σ count of type-130 stacks; there is no second denomination. [HIGH for the
  one definer; MED for the name]

### 1.2 Money routines (page 0x0D; no 0x0101 symtab names — names are ours)
| routine | signature | body (quoted) | reading | conf |
|---|---|---|---|---|
| R0D01 | `money_of(char)` | `0029: set L00 = (L00 + (prop(L01, sel60, 0) * L01.f09:count))` over `iterate_descendants(&L02, 0, A30)` | Σ value·count of every sel60 prop anywhere under the char (inventory, equipped, inside bags) | HIGH |
| R0D02 | `take_money(char, n)` | `0034: jf (L04 > A31)`; `003B: setfield L01.f09:count = (L04 - (A31 / prop(L01, sel60, 0)))`; `004F: set A31 = (A31 - L04)`; `0055: delete_prop(L01)` | walks the char's coin stacks in prop order: a stack worth more than the remainder is reduced, else deleted and subtracted; stops at 0. **No sufficiency check** | HIGH |
| R0D03 | `weight_of_coins(char, n)` | `003B: … weight_if_added(L01.f04:type, (((A31 + prop(L01, sel60, 0)) - 1) / prop(L01, sel60, 0)))`; `005F: … weight_if_added(L01.f04:type, L01.f09:count)` | weight of the coins R0D02 would remove — but through builtin B8's char/item confusion (§2.2) | HIGH (bytes) |
| R0D04 | `party_money()` | `0026: set L00 = (L00 + R0D01(L01))` over `iterate_party` | Σ R0D01 over the party | HIGH |
| R0D05 | `take_party_money(n)` | `0029: jf (L03 >= A30) -> 003D`; `0030: call R0D02(L00, A30)`; `0045: set A30 = (A30 - L03)`; `004B: call R0D02(L00, L03)` | takes from party members **in party order**: the first member who covers the remainder pays it all; poorer members are emptied first. No sufficiency check — every caller tests R0D04 first | HIGH |
| R0D09 | `give_money(char, n)` | `0003: jf (A31 > free_capacity(A30)) -> 0053`; `0014: give_item(A30, 130, 0, free_capacity(A30))`; text "Some money falls to the floor.\n"; `003E: create_prop(1, A30.f01:x, A30.f02:y, 0, 130, 0, L00)`; `0053: give_item(A30, 130, 0, A31)` | coins up to the free weight capacity go to the char; the rest (`L00 = A31 − free`) is dropped as a kind-1 map prop at the char's cell | HIGH |
| R0D0A | `split_money(n)` | `0003: set L00 = (A30 / G07:party_size7)`; `000A: set L01 = (A30 - (L00 * G07:party_size7))`; `0036: call R0D09(L02, (L00 + 1))`; `0049: call R0D09(L02, L00)` | each member gets `n / size`; the first `n mod size` members (party order) get one more; overflow drops per §R0D09 | HIGH |

- G06 and G07 are the same value: `GetGlobal` `case 6:` and `case 7:` both return `*(short
  *)PTR_DAT_100cdb9c` (party size). [HIGH]
- `iterate_party`'s third argument (True/False at the call sites) is stored and never read:
  `Builtin_CA @ 100975b8` mode 0 writes `piVar3[1] = param_2[2]` and nothing reads `piVar3[1]`;
  every member is yielded, dead or alive. [HIGH]
- **Zero-capacity duplication.** When a member's free capacity is exactly 0 and `n > 0`, R0D09
  calls `give_item(A30, 130, 0, 0)`: `ConjoinProp @ 10055f48` reads count 0 as 1 (`if (uVar8 ==
  0) { uVar8 = 1; }`) and adds it to an existing stack, while the full `n` is also dropped on the
  floor (`L00 = A31 − 0`). Net: one extra obol. With no existing stack the new prop's count 0
  reads as 1 (`GetItemCount @ 1005577c`: `if (*(char *)(param_1 + 6) == '\0' && *(char
  *)(param_1 + 7) == '\0') { sVar2 = 1; }`). [HIGH arithmetic; replicate literally]
- Macros 252 "Split Cash" and 253 "Pool Cash" (skill/macro classes 0x1AFC/0x1AFD, sent selector
  9): `1AFC @ 0039: set L00 = R0D04()`, `0040: call R0D05(L00)`, `0045: call R0D0A(L00)` —
  take everything, redistribute evenly; `1AFD @ 003D/0044/0049`: take everything, `R0D09(G09:speaker,
  L00)` — give it all to the acting member (overflow to the floor). [HIGH bytes; "acting member"
  for G09 MED]

---------------------------------------------------------------------------------------------
## 2. Weight and carrying capacity

### 2.1 Limits and units
- Inventory limit = Body × 20, equipment limit = Body × 10 (`GetMaxInvEncumb @ 100558f8`:
  `iVar1 = (uint)(byte)PTR_DAT_100cdbf0[(short)param_1 * 0x20 + 9] * 0x14;` for 0 ≤ index ≤
  0x100; other indices read property 0x16 of the prop, else 1). Cross-checks rules.md §2
  "Encumbrance". [HIGH]
- Current load = Σ `GetObjectWeight(type, frame, count)` over kind-0x10 props parented to the
  index plus kind-8/9 container chains ending at it (`GetCurInvEncumb @ 10055a58`). Weight =
  `weight[type] × count` (byte table) or, for "weight by frame" types, `property24[frame] ×
  count` (`GetObjectWeight @ 100554e4`). [HIGH]
- **Unit = 1/10 of a displayed unit**: the character window prints `(w + 5) / 10`
  (`DrawWeightPart @ 1002c7e0`: `iVar2 = (sVar4 + 5) / 10 + …` for "Inv %d/%d" and "Use
  %d/%d"). So one obol is 0.1 displayed weight; a Body-20 character carries 400 units = 400
  coins and nothing else. [HIGH for the formula; "stone"-like unit name not in code]
- `free_capacity(char)` (B7) = `GetMaxInvEncumb − GetCurInvEncumb`, floored at 0 (`if ((short)(sVar1
  - sVar2) < 0) { *param_1 = 0; }`). [HIGH]
- What over-encumbrance does is **not traced** (rules.md §2 says the same); `TakeCommand`
  refuses a take that would exceed the limit ("There isn't room") — `if ((int)local_4a < (int)sVar10
  + (int)sVar9 + (int)local_4c)` — but scripts' `give_item` never checks. [HIGH for both code paths]

### 2.2 `weight_if_added` (B8) — the char/item confusion
- Body: `sVar2 = GetCurInvEncumb(sVar3); sVar3 = GetObjectWeight(sVar3 & 0x3ff, sVar3 >> 10,
  count); *param_1 = sVar3 + sVar2` — one argument is both an inventory owner and an item code.
  [HIGH, script-builtins.md B8]
- The native model it copies is `TakeCommand`: `sVar9 = GetCurInvEncumb(param_2)` (the
  **contents** of the prop being taken) `+ GetObjectWeight(prop's type, frame, n)` — "weight of a
  prop including its contents". B8 passes an *item code* where `TakeCommand` passes a *prop
  index*. [HIGH for TakeCommand; MED that B8 was meant to mirror it]
- Effect in scripts: `weight_if_added(130, n)` (R0D03) = `GetCurInvEncumb(130)` (whatever
  character 130 carries, plus the contents of any container chain ending at prop 130) + n. The
  only trade routines using B8 are the dead ones (§6); `DoVolumeCheck` 0E45 and type 0x1147 also
  use it (not in this domain). [HIGH for the call sites]
- **The live buy routine has no capacity check at all**: `0ea5.txt` contains no `free_capacity`
  / `weight_if_added` (grep of every B7/B8 site, §0); purchases go to the leader via
  `give_item` whatever the load. Selling pays through R0D09, which *does* respect capacity and
  spills the excess onto the floor. [HIGH]

### 2.3 Per-type weights of traded goods (selector 36, element 0, read this session)
| type | name (0xF004) | weight | | type | name | weight |
|---|---|---|---|---|---|---|
| 31 | potion | 1 | | 109 | light shield | 25 |
| 38 | unlit torch | 5 | | 111 | full shield | 40 |
| 69 | flatbread (all food frames) | 1 | | 112 | leather helmet | 4 |
| 95 | dagger | 4 | | 113 | helmet | 10 |
| 97 | axe | 47 | | 114 | full helmet | 24 |
| 98 | sword | 34 | | 130 | obol | 1 |
| 99 | sword (short) | 14 | | 136 | cloak | 10 |
| 102 | arrow | 1 | | 137 | sandals | 2 |
| 103 | bow | 10 | | 138 | boots | 3 |
| 105 | sling | 6 | | 139 | sack | 32 |
| 106 | cuirass | 24 | | 151 | cloth | 4 |
| 107 | metal breast plate | 68 | | 158 | shovel | 18 |
| 162 | bale of flax | 22 | | 238/242/243 | obsidian/ruby/diamond | 1 |
| 265 | lockpick | 1 | | 285 | cape | 10 |
| 322 | bomb | 30 | | 281 | sword (type 281) | 20 |
All [HIGH] — each is `<seg> … 36/p_weight: @x` → `@x .array array[1] = [w]` in `10xx/11xx.txt`.

---------------------------------------------------------------------------------------------
## 3. The live buy routine `R0EA5(prompt, stock, markup, haggleTable)`

Called 22 times, always as `setfield A30.f27:ce17 = R0EA5("…", blk@…, A30.f27:ce17, blk@…|Nil)`
(e.g. `1810 @ 01BF`), except Pelops `1869 @ 0215: call R0EA5("Flax", blk@0221, 10, Nil)` and
Alcmena `186a @ 0447: call R0EA5("Cheese", blk@0455, 10, Nil)` (fixed markup 10, not stored). [HIGH]

### 3.1 The merchant's markup is `CharEntry +0x17`
- Field 0x27 is that byte: `GetField` `case 0x27: *param_1 = (uint)(byte)PTR_DAT_100cdbf0[sVar4 *
  0x20 + 0x17];` and `SetField` `case 0x27: *(char *)((int)puVar12 + 0x17) = (char)…`. This
  resolves data-format.md §6.1's "0x17 not traced (0 for 110 chars; 10–18 for 21)": the 21
  non-zero bytes are the merchants of §7 (plus Dymas, char 69, value 16, who has no R0EA5 call).
  [HIGH bytes; MED for Dymas being an unused merchant]
- Unit: tenths of base price — 10 = base price, 15 = 150 %. Entry rule `0003: jf (A32 < 9) ->
  0010` / `000B: set A32 = 20`: a markup below 9 (Thoas has 0) becomes 200 %. [HIGH]
- The byte is written back with whatever R0EA5 returns (§3.4), so haggled prices **persist** per
  merchant across visits and saves (CharEntry is saved, data-format.md §6.1). Values wrap at 256
  (byte store). [HIGH; wrap MED — needs ~240 insults]

### 3.2 Stock list format and the menu
- Stock entry = `[item, name, basePrice, units]`; item = `type | frame<<10`. E.g. `1840 @ 0197:
  [0] 102 [1] "Arrows (12)" [2] 4 [3] 12`. [HIGH]
- `0034: set L05 = L02[3]` / `003B: set L05 = callx[L05](L02)` / `004A: send
  L01.sel6(sysnew_01(L02[0], L02[1], L02[2], L05, L02[2]))`: `units` may be a routine (called
  with the entry; falsy → item hidden). Every shipped entry holds a plain integer (1, or 12 for
  arrows), which 0x9C FFFF returns unchanged (script-vm.md §8; the possible stack-slot leak noted
  there applies to all 22 sites). [HIGH for the data; leak MED, per script-vm.md]
- Display price: `00A2: atput L02[2] = (((L02[4] * A32) + 9) / 10)` — **unit price =
  ⌈base × markup / 10⌉** (integer ceiling for non-negative values). [HIGH]
- A one-entry list skips the menu (`00C4: jf (len(L01) == 1) -> 00D7`, `00CD: set L07 = L01[0]`);
  otherwise `00D7: pick_item(A30, "|%i|%s|-100%d ob|", L01, L06)` with the extra button
  `L06 = ["Done"]`; −1 closes. [HIGH; the `%i/%s/%d` drawer format MED — `PickItem` not read]
- Broke check: `0103: jf (R0D04() == 0) -> 0157` then a refusal text — only a party with **zero**
  oboloi is turned away before the dialog. [HIGH]

### 3.3 The sale dialog and payment
- Window `sysnew_window(350, 300)` with "Item For Sale", item icon, name, "Current Price",
  Accept / Cancel, a price field `L0D.f37 = L0E` and a quantity spinner `L0F` with `f37 = 1`,
  `f3E = 1`, `f3F = 100` (`025B`–`0269`): quantity 1..100. [HIGH bytes; spinner semantics MED]
- Quantity change: `081F: setfield L0D.f37 = (L0E * L0F.f37)`. [HIGH]
- Accept (`0829`–`087D`):
  ```
  0830: set L15 = (L0E * L0F.f37)
  0838: jf (L15 > R0D04()) -> 0866        ; else status "You don't have the oboloi!"
  0866: call R0D05(L15)
  086B: give_item(G05:leader, L07[0], 0, (L07[3] * L0F.f37))
  087D: goto -> 0A0E
  ```
  **total = unitPrice × qty** paid from the whole party (R0D05 order), goods = `units × qty` to the
  **leader**, quality byte 0, no weight check. [HIGH]
- After Accept or Cancel the window is released and the menu loops (`0A11: jf (len(L01) == 1) ->
  0A1D` → `goto 0082`), single-item shops exit; `0A23: return A32`. [HIGH]
- Uses a scratch prop: `06C0: set L02 = prop#0`, `06C8: setfield L02.f00:kind = 24`, `06D6:
  setfield L02.f05:item = L07[0]` — prop 0 is overwritten to query the item class's selector 69
  (the same trick `GetObjectWeight` plays natively). [HIGH; side effects on prop 0 MED]

### 3.4 Return value
`A32` (the possibly haggled markup) on normal exit; `L00 + 1` (the entry markup + 1) after an
insult (§4, `09E6: return (L00 + 1)`). [HIGH]

---------------------------------------------------------------------------------------------
## 4. Haggling (inside R0EA5; only when `haggleTable` ≠ Nil)

- Reasons (index → player lines, `031D` block): 0 "can't afford", 1 "poor quality" (item's own
  selector-69 lines if present — `06DF: jf has(L02, sel69)`, `06E6: atput L11[1] = prop(L02,
  sel69, 0)` — else three generic ones), 2 "better price elsewhere", 3 "indifferent". Merchant
  replies per reason in `L12` (`0476`), `L12[4]` = hold firm, `L12[5]` = insulted. [HIGH]
- Three reason buttons are filled by `R0EA8(widgets, lines, map, last)`: each slot draws
  `random(0, 4)` until it differs from `last` and from the slots already drawn (`0EA8 @ 0061:
  set L00 = random(0, 4)`, `006A: jf (L00 != A33)`, `0096: jf (A32[L07] == L00)`). [HIGH]
- One haggle attempt with reason r (`08E1`–`09F6`), A32 = current markup, L00 = entry markup:
  ```
  L17 = A33[r] - random(0,10) - (A32 - L00)/2              ; 08ED
  if find_skill(leader, 204 "Haggling"): L17 -= random(0,5) ; 08FF, 090A
  if (L09 == 0) && R0D04() > ((((base*A32)+9)/10)*3)/2:     ; 0915
        L17 += random(1,4) + random(1,4)                    ; 0935
  if L17 <= 0:                                              ; 0947
      if A32 <= 10: status "This is the best I can do"
      else: A32 -= 1; if L17 < -5 && A32 > 10: A32 -= 1     ; 097A, 0981, 098E
            unit price recomputed, reply L12[r]
  elif L17 > 5: release windows, print L12[5] line, return L00 + 1   ; 09C4..09E6
  else: status = random line of L12[4]                       ; 09EF
  ```
  [HIGH — every line is a listing statement]
- Consequences: random(0,10) is 0..9, so table value v succeeds with roughly (10 − v)/10 at the
  entry markup, and each step down adds `(L00 − A32)/2` (truncating) to L17, making later steps
  harder; Haggling skill subtracts 0..4 more. The floor is **markup 10 = base price**. An insult
  (L17 > 5) ends the dialog and raises the stored markup to entry + 1. [HIGH arithmetic; the
  "roughly" because `Random()` mod 10 is not exactly uniform — MED]
- **Dead lie check (original bug)**: the "can't afford" penalty tests `L09 == 0`, but L09 is the
  status-line widget object (`02A1: set L09 = sysnew_06(L08, "", 0, 136, 350, 32)`), and `IsEqual
  @ 10080adc` compares raw VAddrs unless both are strings (`return param_2 == param_1;`). An
  object is never integer 0, so the penalty never fires — claiming poverty while rich is free. The
  older routine 0EA7 tests the reason correctly (`0EA7 @ 00C8: jf ((L02 == 0) && …`). [HIGH for
  the compare; MED that a sysnew object can never be 0]

---------------------------------------------------------------------------------------------
## 5. The live sell routine `R0EA9(prompt, wantList, markup)`

Call sites: Atreus `1810 @ 02BC: setfield A30.f27:ce17 = R0EA9("Got any quality gems?",
blk@02DD, A30.f27:ce17)` and Hebe `1823 @ 0474: call R0EA9("Flax", blk@0480, 10)`. [HIGH]

- Markup rule differs from buying: `0014: jf (A32 == 0) -> 0021` / `001C: set A32 = 10` — only 0
  is replaced, by 10. [HIGH]
- Want entry = `[item, name, basePrice]`. For each, the party is scanned:
  `008F: jf (L0A.f05:item == L03[0])` over `iterate_descendants` of every member — any stack
  whose full u16 item (type + frame + mirror bit, `GetField case 5: *(ushort *)(puVar8 + 1)`)
  matches, **any quality**, including equipped items and bag contents; `L06 = [total, props…]`.
  [HIGH; "mirror bit included" HIGH from `GetField`]
- Offer: `00D5: send L02.sel6(sysnew_01(L03[0], L03[1], L06[0], ((((L03[2] * L06[0]) * 10) + 5) /
  A32), L03[2], L06))` — **sell total = round(base × qty × 10 / markup)** (nearest, halves up).
  The quantity spinner defaults to and is capped at the whole holding (`0285`/`028E`), minimum 1;
  changing it recomputes `0350: … ((((L14.f37 * L0D[4]) * 10) + 5) / A32)`. [HIGH]
- So a merchant's buy and sell prices are inverse in the same byte: Atreus at 15 buys a ruby
  (base 15) for `(150 + 5)/15 = 10` and sells one (base 30) for `(450 + 9)/10 = 45`; haggling his
  markup down **also raises what he pays**. [HIGH arithmetic]
- Accept: `02EC: call R0D0A(L13.f37)` (payment **split across the party**, overflow to the floor
  per member), then the stacks in `L06[1..]` are reduced/deleted in order (`0306`–`032E`). Cancel
  and Accept both close the window; the list is rebuilt and the loop repeats while more than one
  wanted item remains. [HIGH]
- Nothing to sell: "Sorry, you've got nothing I'm interested in." only on the first pass
  (`011C: jf L01 -> 0127`); `R0EA9` never changes the markup (`0388: return A32`). [HIGH]
- Quirk: `0373: release L02` precedes `0376: jf (len(L02) == 1)` and the exit path releases L02
  again at `0385` — use after release and double release of a heap list. Behaviour depends on
  `THeap` reuse (not traced). [HIGH bytes; effect MED]

---------------------------------------------------------------------------------------------
## 6. Dead shop API (page 0x0E, never called in 1.0.4)

Census §7 lists 0E91, 0E92, 0E94, 0EA4, 0EA7 as never called statically; 0EA6 is called only by
0E94/0EA4. A grep for `R0E91|R0E92|R0E94|R0EA4|R0EA7` over all listings finds no caller. [HIGH]

| routine | signature (ours) | what it does |
|---|---|---|
| 0E91 | `buy_one(whoPrompt, price, item, ?)` | `who_will_prompt`; money check `R0D01(L00) < A31` on **one** member; room check `(R0D03(L01, A31) + weight_if_added(A32, 1)) > free_capacity(L01)`; `R0D02` + `give_item(L00, A32, 0, 0)` |
| 0E92 | `buy_n(whoPrompt, price, unitsPer, item, ?)` | "How many, X, at P each?"; `how_many(Nil, 0, 200)`; total `A31 * L02`, goods `L02 * A32` |
| 0E94 / 0EA4 | `buy_from_menu(prompt, prices[], items[], names)` | `R0EA6` = `pick_item(Nil, "%s", A30, Nil)` (4th arg Nil); index 0 = refuse; 0EA4 asks a quantity |
| 0EA7 | `haggle(base, markup, ?, ?)` | standalone "Haggle" menu (Can't Afford / Poor Quality / Better Price Elsewhere / Indifferent), table `[5, 6, 4, 5]`, same formula family as §4 (`00B5: L03 = ((L03 - random(0, 10)) - ((A31 - 12) / 2))`, lie penalty `random(1, 4)` when money > ((base·markup+9)/10)·15/10) |
[HIGH bytes; argument names MED]

These differ from the live code in three ways a replica must **not** copy into R0EA5: per-member
payment (R0D02 on the chosen member), a weight check, and the weight check's **sign**: 0E91/0E92
*add* the coins' weight (`R0D03(…) + weight_if_added(…)`) while 0E94/0EA4 *subtract* it
(`weight_if_added(…) - R0D03(…)`). [HIGH]

---------------------------------------------------------------------------------------------
## 7. Price tables (shop data, read this session)

Columns: merchant (segment = 0x1800 + char id, name from 0x0201), markup byte `+0x17` → value
used, items as `name (type/frame) base→unit price at the stored markup`, haggle table
`[afford, quality, elsewhere, indifferent]`. Unit price = `((base*m)+9)/10`. Every row [HIGH]
(stock from the `blk@` lists under each call; markup from 0xF009 via `seg.py`).

| merchant | m | stock: base → price | haggle |
|---|---|---|---|
| 1810 Atreus | 15 | Obsidian (238/0) 10→15; Ruby (242/0) 30→45; Diamond (243/0) 50→75 | 7,3,5,5 |
| 1812 Ariethous | 16 | Skewer (69/6) 3→5; Haunch (69/8) 6→10; Ribs (69/10) 9→15; Steak (69/12) 8→13 | 5,7,5,3 |
| 181E Milcom `@0796` | 17 | Sword (98/0) 45→77; Metal Breast Plate (107/0) 50→85; Full Helm (114/0) 17→29; Full Shield (111/0) 27→46; Smith's Friend Potion (31/6) 50→85 | 3,7,5,5 |
| 181E Milcom `@08A1` | 17 | same four, no potion | 3,7,5,5 |
| 1820 Ake | 12 | Blue/Red/Green Cloth (151/0,1,2) 10→12 | Nil |
| 1825 Alastor | 15 | Sling (105/0) 10→15; Cuirass (106/0) 40→60; Leather Helm (112/0) 7→11 | 5,7,3,5 |
| 1828 Parium, 1829 Crito, 182A Apis | 15 | Cheese (69/2) 5→8; Bread (69/1) 3→5; Fish (69/9) 3→5; Ribs (69/10) 9→14 | 7,5,3,5 |
| 182D Dares, 182E Diomede | 18 | Cheese 5→9; Bread 3→6; Fish 3→6; Ribs 9→17 | 5,5,3,7 |
| 1837 Tlepolemus | 12 | Fish (69/9) 4→5 | 5,7,3,5 |
| 1838 Eteocles (guild flag 4 only, `06A9: jf test_flag(4)`) | 12 | Lock Pick (265/0) 7→9; Boots (138/0) 10→12; Torch (38/0) 4→5; Shovel (158/0) 15→18; Bomb (322/0) 200→240 | 3,5,7,5 |
| 1839 Laomedon | 14 | Meat Skewers (69/6) 3→5; Sausages (69/11) 3→5; Roast (69/8) 6→9; Ribs 9→13 | 5,7,5,3 |
| 183A Ilus | 14 | Grapes (69/3) 2→3; Pomegranate (69/4) 1→2 | 5,7,5,3 |
| 1840 Oeneus | 15 | Bow (103/0) 30→45; Arrows (102/0) 4→6 per 12 | 5,5,3,7 |
| 1841 Periphas | 14 | Loaf of Bread (69/1) 3→5 | 5,7,5,3 |
| 1842 Theano | 14 | Cheese (69/2) 6→9 | 5,7,5,3 |
| 1843 Hypsenor | 16 | Cloak (136/0) 30→48; Cape (285/0) 20→32 | 5,5,7,3 |
| 1844 Thoas | 0→20 | Dagger (95/0) 10→20; Axe (97/0) 45→90; Short Sword (99/0) 35→70; Buckler (108/0) 17→34; Light Shield (109/0) 23→46; Helmet (113/0) 14→28 | 5,5,3,7 |
| 1857 Paris | 16 | Torch (38/0) 6→10; Sandals (137/0) 3→5; Cloak (136/0) 5→8; Sack (139/0) 4→7 | 3,5,7,5 |
| 1869 Pelops | lit. 10 | Flax (162/0) 7→7 | Nil |
| 186A Alcmena | lit. 10 | Cheese (69/2) 4→4 | Nil |

Notes: Milcom's two calls are alternative branches of his talk method (`181e @ 0796`, `@ 08A1`);
which one runs is not traced. Cloak is 30 at Hypsenor and 5 at Paris (base prices are per
merchant, not per item). Ribs (69/10) base 9 everywhere. [HIGH for the data; branch condition
not traced]

Sell side:
| buyer | m | wants: base → paid per unit (qty 1) / per 10 |
|---|---|---|
| 1810 Atreus | 15 (stored) | Obsidian 5 → 3 / 33; Ruby 15 → 10 / 100; Diamond 25 → 17 / 167 |
| 1823 Hebe | literal 10 | Flax (162/0) 10 → 10 / 100 |
[HIGH; per-10 values from `((base*10*10)+5)/m`]

---------------------------------------------------------------------------------------------
## 8. Services paid in oboloi (every R0D05 / R0D02 consumer outside page 0x0D/0x0E)

All use the pattern `jf (R0D04() >= cost) -> refuse` then `R0D05(cost)` (or `R0D01/R0D02` on
char 1). The list is complete for 1.0.4 (grep of `R0D0[1-5A9]` over all listings). [HIGH]

| where | service | cost (oboloi) | evidence |
|---|---|---|---|
| 1828 Parium (inn id 2) | room for the night + meal | party_size × 7 | `05A7: jf (R0D04() >= (G06:party_size * 7))`, `05FC: gstore seg0301[0016] = 2`, `0604: call R0D05((G06:party_size * 7))` |
| 1829 Crito (inn id 1) | room + meal | party_size × 6 | `08F7`, `094C: gstore seg0301[0016] = 1`, `0954` |
| 182A Apis (inn id 3) | room + meal | party_size × 5 | `078D`, `07E2: gstore seg0301[0016] = 3`, `07EA` |
| Parium / Dares / Diomede | meal | 5 per person | `1828 @ 06BD`, `182d @ 0449`, `182e @ 03FC` |
| Crito | meal | 4 per person | `1829 @ 0A0D` |
| Apis | meal | 3 per person | `182a @ 08A3` |
| 1858 Helen | meal | 6 per person | `1858 @ 047A` |
| 1812, 1828, 1829, 182A, 182D, 182E, 1858 | round of drinks | party_size × 1 | e.g. `1828 @ 04A7`, `04BE: call R0D05(G06:party_size)` |
| 1828 Parium | a companion's bar tab | 25 from char 1 only | `023B: jf (R0D01(1) >= 25)`, `0249: call R0D02(1, 25)` |
| 1829 Crito | (char-1-only payment) | 20 | `035E: jf (R0D01(1) >= 20)`, `036C: call R0D02(1, 20)` (context not read) |
| 1822 Meleager | hire fee | 50, or 35 with Haggling after refusing | `07FA`, `0853: call R0D05(50)`; `0866: jf find_skill(G05:leader, 204)`, `093D: call R0D05(35)` |
| 1838 Eteocles | guild dues | 50; with Haggling 40, then 35 | `042F: set L00 = 50`, `044A: set L00 = 40`, `04C5: set L00 = 35`, `057C: call R0D05(L00)` |
| 1824 Antenor | a building | 10000 | `035E: jf (R0D04() >= 10000)`, `0407: call R0D05(10000)` |
| 1811 Ennomus, 185D Eumelus | donation (how_many 0..all) | player's choice | `1811 @ 026C: how_many("Give how many oboloi?", 0, L00)`, `02A5: call R0D05(L01)` |
| 0812 (dice, Parium/Crito/Apis) | gambling | 1 per loss | `056D: call R0D05(1)` |

- **Meal** (`1828 @ 0002` sub): every party member `food = 20` if below 20, else `food + 1`
  (`007B: jf (L00.f28:food < 20)`, `0085: setfield L00.f28:food = 20`, `008F: … + 1`); field
  0x28 = CharEntry +0x1B food hours (data-format.md §6.1). Room buyers get the meal free once
  (flag bit 2, `066B: jf R0F02(A30, 2)`). [HIGH]
- **Drinks**: each round increments a per-conversation counter `L00` and calls `R0EA2(L00)`:
  per member, `jf ((random(0, 6) + (3 * A30)) > (L00.f17:body + L00.f1B:level))` →
  `temp_ability(L00, 21, ((A30 + 2) * 3))` — ability 21 (drunk, LOW) for `(n+2)·3` units when
  `random(0..5) + 3n > Body + Level`. Then `R0813` prints a rumour (zone- and flag-dependent).
  [HIGH bytes; ability 21's meaning LOW]
- **Inn token**: `seg0301[0016]` (a persistent script word, `0x85` re-saves it) holds the paid inn
  id. A bed (type 14, `100E` sel9) with quality q: q = 0 free bed, q = 255 "somebody else is
  staying here", else `jf (A30.f06:quality != seg0301[0016])` → "You need to pay the innkeeper
  first."; on sleeping the token is cleared (`039D: gstore seg0301[0016] = 0`). [HIGH]
- **Rest bonus**: `00AF: set L00 = seg0301[0012][seg0301[0016]]` → array `0301 @ 0000 [2, 3, 1,
  1]` (word @0012 = code pointer 0x83010000 → that array): bonus 3 at Crito (id 1), 1 at Parium
  (2), 1 at Apis (3); a free bed gives 0 ("You toss and turn…") except in room 2, which gives 4 (`000A: jf
  (G12:room == 2)`, `0014: set L00 = 4`). Sleep routine `R0E93(hours, x, y, bonus)`: after the
  sleep `health += ((health − healthBefore) × bonus) / 2`, capped at health_max (`01E7`, `01FA`,
  `0203`). [HIGH]
- Rest-bonus bug: the magic half compares and clamps against **health_max** (`0214: jf
  ((L03.f1E:magic < L03.f1D:health_max) && …`, `0243: setfield L03.f1E:magic =
  L03.f1D:health_max`) while the overflow test uses magic_max (`023A`). Replicate. [HIGH]
- **Dice** (`0812`, entered from the inns' "dice/game"): house dice L03, L05 and player die L04,
  each `random(0, 6)`; with Gambling (skill 207), if L03 ≠ L04 then with probability ~1/6
  (`0488: jf (random(0, 6) == L03)`) `L04 = L03`. Result L06: match → 2; else the distance of L04
  outside the house pair (`052F: set L06 = (L03 - L04)`, `053F: (L04 - L05)`, `054F: (L05 - L04)`,
  `055F: (L04 - L03)`), 0 when between. L06 = 0 → `R0D05(1)`; L06 = 1 → push; L06 > 1 →
  `R0D09(G05:leader, (L06 - 1))` (the text prints L06, the payout is L06 − 1). Requires money > 0,
  no stake cap. [HIGH]
- **Donations** (Ennomus 1811, Eumelus 185D): broke → `R0F11(1)` (karma −1); else
  `R0D05(L01)` and `jf (L01 > 10) -> …` / `R0F12((L01 / 10))` (karma + n/10 when n > 10);
  Ennomus gives an item when `L01 >= 40` (`0329`). Karma = G0C, clamped 0..100 (script-vm.md §8).
  [HIGH]
- **Not found**: no ferry/passage fare, no paid healing, no temple fee and no item repair service
  in any listing (grep of `R0D0[1-5]` sites above; `repair` occurs only in 1146 "broken sword …
  beyond repair" and 1156 bridge repair). [HIGH for the greps; absence of other payment paths MED
  — a script could in principle `remove_items(…, 130, …)` directly: the 9 B1 sites (census §4)
  name types 2258, 166, 3150, 134, 26, 271, 270, 301 — none is 130]

---------------------------------------------------------------------------------------------
## 9. Training and healing costs

- Skill lessons cost **training points, not oboloi**. `R0EB1(char, teacher, skill, flag)` refuses
  when `jf (L01.f21:training == 0)` → "You need some more experience before you can train." and
  calls `R0EAF`, which does `0098: setfield L01.f21:training = (L01.f21:training - 1)` and raises
  the skill prop's level (`00A8: setfield L00.f03:frame = (L00.f03:frame + 1)`) or creates it
  (`create_prop(28, 0, A30, 1|0, A31, 0, 0)`). [HIGH]
- Attribute training ("Train what part of your basic identity?", 1802) costs **4** training points:
  `0F11: jf (G05:leader.f21:training >= 4)`, `0F9A: setfield … training = (… - 4)`. [HIGH]
- Skill level = the skill prop's frame (0..15); bit 16 = suppressed: `R0EAC(char, skill)` returns
  `0` when `(L00.f03:frame & 16)` else `L00.f03:frame`. [HIGH bytes; "suppressed" MED]
- Healing: no oboloi path found (§8). 0E86 rescales health on level change (`001D: health =
  ((health * health_max) / L00)`), 1801 handles death/revival — both outside trade. [HIGH for the
  absence in R0D05 sites]

---------------------------------------------------------------------------------------------
## 10. Item quality, durability, repair

- The quality byte is prop byte 6 for types without the u16-count flag (`GetItemQuality`
  `if ((… & 0x200) == 0) { uVar1 = *(undefined1 *)(param_1 + 6); }`); coins and other u16-count
  types have no quality (byte 6 is the count's high byte). [HIGH]
- Trade ignores quality: R0EA5 always gives quality 0; R0EA9 matches any quality. [HIGH]
- **Weapon improvement** (Eioneus, 1827) is the only quality market: eligible types 98, 95, 99, 281
  (`0437`), cost **`10 << quality` pieces of obsidian** (type 238) — 10, 20, 40, 80, 160, 320 — for
  quality < 6 (`0518: jf (L0A.f06:quality >= 6)`), result `0799: setfield L0A.f06:quality =
  (L0A.f06:quality + 1)`; obsidian is counted and removed across the whole party (`05F8`,
  `06CC`–`06E8`). Labels "Unimproved" … "Legendary Improvement" for qualities 0..7. [HIGH]
  What quality does in combat: combat domain, not read.
- No durability decrement and no repair service were found in the trade code (§8). "broken sword"
  (type 326) is a separate item type ("It is broken, and beyond repair."). [MED — weapon wear, if
  any, would live in the selector-28 combat scripts, not read]

---------------------------------------------------------------------------------------------
## 11. Theft

- Native: `TakeCommand @ 10053fd8` sends selector 15 to the prop for map/container takes into a
  character; result False aborts, any non-Nil result broadcasts **signal 0x100**:
  `_DoInterp__7TInterpFs5VAddr(&local_60,0xf,local_64); … if (local_60 == False) return; if
  (local_60 != Nil) _SendSignal__8TGameSysFs(param_1,0x100);`. [HIGH]
- Types with their own sel15 return Nil (e.g. `1045 @ 00CC: return Nil`, `1025`, `1084`): never
  theft. Everything else falls to routine **0x300F** (`DoInterp0`'s 0x3000 + selector fallback). [HIGH]
- 0x300F: if the current zone object answers selector 36 → `return Nil` (free to take; 16 of the
  42 zone classes define it: 1403, 140F, 1410, 1413, 1415, 1419–1422, 1428 …). Else
  `L01 = R0EAC(leader, 214 "Thievery")`, `L02 = find_skill(leader, 205 "Awareness")`:
  - neither → `return True` silently (the take happens **and** is broadcast as theft);
  - otherwise a window ("That doesn't seem to belong to you..." or, with Thievery, "You sense that
    somebody is watching you 'borrow' that...") with Take/Steal and Leave; Leave → False (abort);
  - Take without Thievery → True; Steal with level k: up to k tries of `random(0, 6) == 3`; any
    success → a distraction bark and `return Nil` (unseen); all fail → bark and `return True`.
  Success chance `1 − (5/6)^k` (approximately, `Random()` mod 6). [HIGH bytes; probability MED]
- Reactions to signal 256 (only outside selector-36 zones, each handler re-tests it):
  - the Hero (1801 `18D1: setglobal G0C = (G0C - 1)`, "Your deeds stain your soul.") — karma −1;
  - characters without their own signal method run `0x3015`: class-0x48 field 0x35 (= byte 6 of
    the character's 16-byte record in segment 0xF008's first 0x800 bytes, `GetField` class 0x48
    `case 0x35: *param_1 = (uint)pbVar7[6];`) selects R0D06 (value 0) or R0D07 (value 2);
  - R0D06: on 256, if `leader_can_see(self)` → bark one of three lines and `send_signal(320)`; on
    321, if `leader_can_see(self)` → `target = leader`, `activity = 6`; R0D07 (also the shared signal method of the guard type
    0x102E and chars 70–73, 100, 101): any 320 or 321 → `target = leader`, `activity = 6`. [HIGH]
  - So one witness who sees the leader calls the guards (320); guards and value-2 characters turn
    on the leader. Signal 321 is also sent by 0x3043 (the default for selector 67, which no class
    defines and scripts send 8 times, census §5) when its receiver is not in the party, its
    argument is (`006F: jf (!R0F13(A30) && R0F13(A31))`) and the receiver's value is 0 or 2.
    [HIGH bytes; activity 6 = "attack" and selector 67 = "was attacked" MED]
- F008 byte 6 census (first 128 characters): 0 ×101, 1 ×11, 2 ×4 (chars 0, 2 Alaric, 3 Magpie,
  4 Hadrian), 3 ×12. Values 1 and 3 (most merchants) select **neither** handler — merchants who
  do not bark. Note data-format.md §5 describes 0xF008's first 0x800 bytes as a header; GetField
  indexes it per character. [HIGH data; reconciliation with data-format.md left to that bank]
- Thievery (214) is read only through R0EAC in 0x300F; no `find_skill(…, 214)` exists. [HIGH]

---------------------------------------------------------------------------------------------
## 12. Worked example — buying a ruby from Atreus, end to end

State: fresh game, party of 2, member A (leader) holds 30 oboloi, member B holds 40; Atreus
(char 16) `+0x17 = 15`.
1. Talk → Atreus's talk method reaches `1810 @ 01BF: setfield A30.f27:ce17 = R0EA5("Interested
   in the highest quality gems?", blk@01F2, A30.f27:ce17, blk@0252)`; A32 = 15 (≥ 9, kept),
   L00 = 15.
2. Menu prices: Obsidian `((10*15)+9)/10 = 159/10 = 15`, Ruby `459/10 = 45`, Diamond `759/10 = 75`.
   Player picks Ruby; `R0D04() = 70 ≠ 0`, the dialog opens with L0E = 45, quantity 1.
3. Haggle: reason 2 "better price elsewhere" (table `[7,3,5,5]` → 5). Say random(0,10) = 7, no
   Haggling skill: `L17 = 5 − 7 − (15 − 15)/2 = −2` ≤ 0 → A32 = 14 (−2 is not < −5, no second
   step) → L0E = `((30*14)+9)/10 = 429/10 = 42`; a reply line from `L12[2]`.
4. Haggle again, reason 3 (table 5), random = 2: `L17 = 5 − 2 − (14 − 15)/2 = 3 − (−1/2) = 3 − 0 =
   3` (−1/2 truncates to 0) → 1..5 → "hold firm" line, price stays 42.
5. Accept: `L15 = 42 × 1 = 42`; `42 > R0D04() = 70` is false → `R0D05(42)`: member A has 30 <
   42 → `R0D02(A, 30)` deletes A's stack, remainder 12; member B has 40 ≥ 12 → `R0D02(B, 12)`
   leaves 28. Then `give_item(leader, 242, 0, 1)` puts one ruby (weight 1) on A with no capacity
   test.
6. Done → `return A32 = 14` → `setfield A30.f27:ce17 = 14`: Atreus now sells the ruby for 42 and,
   via R0EA9, buys one for `((15*1*10)+5)/14 = 155/14 = 11` instead of 10.
[HIGH — each step is a quoted listing statement with the stated inputs]

---------------------------------------------------------------------------------------------
## 13. Open items

1. `TInteraction::PickItem` / `HowMany` bodies: the `|%i|%s|-100%d ob|` drawer format, what a
   cancelled pick returns (scripts test −1), and B4's two integers (0, max — MED from
   `TakeCommand`'s `HowMany("Move how many?", 0, count)`).
2. sysnew widget classes 0x06/0x08/0x10/0x11/0x12 and fields f37/f3C–f40 (spinner value/min/max,
   status text) — read only through script use.
3. Which branch of Milcom's talk method offers the potion (`181e @ 0796` vs `@ 08A1`); Dymas
   (char 69) has markup 16 but no shop call — leftover or reached another way.
4. `R0D03` / B8's `GetCurInvEncumb(130)` term in the dead routines and in DoVolumeCheck 0E45 —
   magnitude depends on what character 130 / prop 130 holds at run time.
5. 0x9C FFFF with an integer target (R0EA5 `003B`, 22 sites): the stack-slot leak from
   script-vm.md §8 is unverified at PPC level; it runs once per stock entry per menu pass.
6. R0EA9's release-then-`len` and double release (`0373`, `0376`, `0385`): THeap behaviour.
7. Over-encumbrance effects (rules.md §2 open item) — the live shop can push the leader over.
8. Meaning of temp ability 21 (drinks), activity 6 (theft response), F008 byte 6 values 1/3, and
   the 0813 rumour table conditions.
9. Crito's 20-obol char-1 payment (`1829 @ 035E`) — context not read.
10. Whether any combat script decrements weapon quality (durability) — combat bank.
