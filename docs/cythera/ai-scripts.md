# Cythera 1.0.4 — combat AI scripts (`.ai`)

Register: **code reading only**; nothing behaviour-verified. Two oracles: the shipped manual
`AI Scripting Document` (summarised, not copied) and the compiler/evaluator in the binary:
`GetToken__FPPcPc @ 100ade34`, `MatchStr__FsPcPcs @ 100ae06c`, `CompileHeader__15SCombatAIHeaderFPc
@ 100ae25c`, `CompileLine__14SCombatAIEntryFPc @ 100ae3b8`, `CompileAIFile__FR6FSSpecs @ 100b0ef8`,
`CalculateObject__14SCombatAIEntry @ 100af158`, `EvaluateCondition__14SCombatAIEntry @ 100affe8`,
`PerformAction__14SCombatAIEntry @ 100b0698`, `EvaluateAI__14SCombatAIEntry @ 100b07a0`,
`PerformAI__FP14TActiveMonsters @ 100b0ba4`, `GetCombatAIName__FsPUc @ 100b0da8`, debugger
`TAIDebug` (`Disassemble`, `SetCurrentLine`), decompiler `DecompileLine/DecompileObject`.

The language is NOT the general game script (that is the bytecode VM in `script-vm.md`); it is
a small rule language compiled to 8-byte entries. Scenario-specific tests/actions are delegated
to game-script routines (§5).

---------------------------------------------------------------------------------------------
## 1. Vocabulary comes from `STR#` resources (app resource fork)

`MatchStr(id, token, sigOut, n)` walks `STR# id` items 1..0x3E6 and returns the 1-based index of
the first item whose text **before `(`** is a **prefix of the token**; items starting with `;` are
skipped; the text inside `(...)` is returned as the parameter signature. [HIGH]
⚑ corrected (review 2026-10-03): not "equals". `MatchStr @ 100ae06c` compares only `len(item-prefix)` characters and
returns on exhausting the item, so a longer token still matches (`Continuex` → `Continue()`) and a
shorter token fails. Item order therefore matters when one item is a prefix of another. [HIGH]

Dump command: `python3 docs/cythera/tools/rsrc.py` style parse of `$G/Cythera.rsrc` (see INDEX).

| STR# | name | role in compiler | items |
|---|---|---|---|
| 9300 (0x2454) | Objects | base individuals → code 0xF0+i−1 | myself, main, target, last |
| 9301 (0x2455) | Groups | base groups → 1..8 | good, evil, neutral, feral, ally, enemy, bystander, everybody |
| 9302 (0x2456) | (species) | species names for `$` | **absent from the resource fork** |
| 9303 (0x2457) | Modifiers | `.Modifier`; last 2 chars = input type, output type | CurTarget@@, Allies@\*, Enemies@\*, Attackers@\*, ByRange\*\*, ByDamage\*\*, ByHealth\*\*, ByStrongest\*\*, ByWeakest\*\*, Randomize\*\*, Best\*@, Random\*@, Pick\*@, Protecting@@, ProtectedBy@\*, LastAttacker@@ |
| 9304 (0x2458) | Tests | built-in tests, index 1..16 | True(), False(), IsSpecies(@,$), IsA(@,\*), HealthIs(@,0), HealthAtLeast(@,0), HealthLessThan(@,0), InParty(@), BeenMet(@), InRange(@,#), Random(#), TestFlag(@,1), IsTarget(@), Exists(@), ManaAtLeast(#), InLOS(@) |
| 9305 (0x2459) | Actions | built-in actions, index 1..2 | Continue(), Debug(#) |
| 9306 (0x245A) | Scenario Characters | named individuals | **0 items** |
| 9307 (0x245B) | Scenario AI Tests | index + 0x80 | HasSpell(#), HasMeleeWeapon(@), HasRangedWeapon(@,#), UsingMeleeWeapon(@), UsingRangedWeapon(@,#), OutOfAmmo() |
| 9308 (0x245C) | Scenario AI Actions | index + 0x80 | CastSpell(@,#), SetTarget(@), Retreat(), Pass(#), WalkTo(@), BattleCry(), EquipMelee(), EquipRanged(#), RunAwayFrom(@,#), RunToward(@,#), DoAttack(), FinishCombat(), SetProtecting(@) |
| 9320 (`'0'`+0x2438) | HealthState | parameter type `0` | Dead, Critical, Serious, Wounded, Scratch, Complete |
| 9321 (`'1'`+0x2438) | ObjectFlags | parameter type `1` | IsAlive, IsPoisoned, IsEnhorsed, IsAngry, IsRegen, IsFear, IsParalyse, IsInvisible, IsXray, IsCharmed, IsNightVision, IsCursed, IsBlessed, IsConfused, IsSleep, IsLavaProof |

Signature characters: `@` individual, `*` group, `$` species, `#` decimal number, `0`–`9` → list
`STR# 0x2438+digit`, `A`–`Z` → list `STR# 0x2431+letter` (none present). [HIGH: `CompileLine`
branches `cVar1 == '$'`, `'/' < c < ':'` → `*pcVar16 + 0x2438`, `'A'..'Z'` → `+ 0x2431`]

Consequences read from the resources [HIGH]: `IsSpecies` can never compile a valid species (list
9302 missing → "Expecting species parameter"); no named characters are available (9306 empty).
The manual likewise leaves the species list blank.

---------------------------------------------------------------------------------------------
## 2. Lexer and grammar (as implemented)

`GetToken`: skips spaces/tabs; end of line = `\n`, `\r`, NUL; single-char tokens `# ( ) . , " ; :`;
anything else runs to the next delimiter. Case-sensitive comparison (`FUN_100b6d94` = strcmp; the
keyword strings resolved with `tools/toc.py`: `IF`, `NOT`, `THEN`, `OR`, `NAME`, `"`, `(`, `)`,
`.`, `,`). [HIGH]

`CompileAIFile`: reads lines (≤ 0x400 B); skips leading blanks; blank line → skip; **an empty
first character ends the file**; a line whose *first column* is `;` is a comment (a `;` after
indentation is not a comment — it is handed to the line compiler, where `GetToken` returns `;`
→ "Unknown action"). The first non-comment line must be the header. [HIGH — `local_440[0] != ';'`
tests column 0, the compile call gets the indent-stripped `pcVar15`.]

```
file     := header line*
header   := 'NAME' '"' chars-up-to-quote   (name ≤ 23 chars, no closing-quote check)
line     := test | action
test     := 'IF' ['NOT'] TEST '(' params ')' ('THEN' | 'OR') [anything]
action   := ['#' weight] ACTION '(' params ')' [anything]
params   := [object-expr [',' value]] | value
object-expr := BASE ('.' MODIFIER){0,3}
```
Trailing text after `THEN`/`OR`/`)` is ignored (so `IF HasSpell(10) THEN ; Has healing` compiles).
Weight is decimal, > 100 → "Weight higher than 100". Up to 3 modifiers ("Maximum number of
modifiers exceeded" at the 4th). Type checking follows the modifier signature chars; the final
type must match the parameter (`@`/`*`). [HIGH]

**Not accepted by this compiler (used in the manual only):** `!Exists(...)` (the `!` form) and
`CurHealthLessThan` — neither is in the vocabulary. The shipped `.ai` files use `NOT` and
`HealthLessThan`. [HIGH: absent from STR# 9304; token `!Exists` would be one token]

---------------------------------------------------------------------------------------------
## 3. Compiled form

### 3.1 Header (0x20 bytes) — `SCombatAIHeader`
| off | meaning |
|---|---|
| 0 | name length (≤ 0x17) |
| 1..0x17 | name bytes |
| 0x18..0x1F | zero |

### 3.2 Entry (8 bytes) — `SCombatAIEntry`
| off | meaning |
|---|---|
| 0 | 0x65 `IF … THEN`, 0x66 `IF NOT … THEN`, 0x67 `IF … OR`, 0x68 `IF NOT … OR`; otherwise **weight** 0..100 (0 = continuation of the previous weighted action group) |
| 1 | test/action index (1-based); +0x80 for the scenario lists 9307/9308 |
| 2 | object base: 0xF0 myself, 0xF1 main, 0xF2 target, 0xF3 last (= `index − 0x11`); 1..8 = group; species/character index otherwise |
| 3 | the non-object parameter (number, HealthState 1..6, ObjectFlag 1..16, species) |
| 4..6 | modifiers (STR# 9303 index), 0-terminated |
| 7 | 0 |

`CompileAIFile` concatenates header + entries and writes them to segment **0x360 + slot** of the
current player file (`SaveSegment(*piVar5, param_2 + 0x360, …)`), then `RefindSegment` so the
overlay sees it. [HIGH]

### 3.3 Slots and names
`GetCombatAIName`: slot 0xB0..0xCF → "User Combat AI #n" (n = slot − 0xAF), slot ≥ 0xD0 →
"Scenario Combat AI #n" (n = slot − 0xCF), unless the segment exists (≥ 0x20 bytes), in which case
the header name is used. `AppendUserBehaviors` lists slots 0xB0..0xCF in the character window's
behaviour menu. [HIGH] Strings resolved: `tools/toc.py 100cf038 100cf03c` → "User Combat AI #",
"Scenario Combat AI #".

Shipped data (`Cythera Data`, page 0x04): user slots 1..7 = 0x0410..0x0416 and scenario slots
1..7 = 0x0430..0x0436, plain (not encrypted):

| seg | slot | name | entries |
|---|---|---|---|
| 0x0410 | user 1 | Attack Nearest | 12 |
| 0x0411 | user 2 | Attack Weakest | 12 |
| 0x0412 | user 3 | Attack Strongest | 12 |
| 0x0413 | user 4 | Defend | 17 (stored at file offset 0x556226 — appended late, i.e. updated after the original build) |
| 0x0414 | user 5 | Beserk | 7 |
| 0x0415 | user 6 | Missile Script | 18 |
| 0x0416 | user 7 | Healer | 11 |
| 0x0430–0x0436 | scenario 1–7 | Attack Nearest, Attack Strongest, Attack Weakest, Beserk, Defend (late, 0x5562CE), Missile Script, Healer | — |

Worked decode — `Attack Nearest.ai` vs segment 0x0410:
```
$ xxd -s 0x106a4 -l 0x80 "$G/Cythera Data"
000106a4: 0e41 7474 6163 6b20 4e65 6172 6573 74d2  .Attack Nearest.
000106b4: 0000 4334 007f 8865 0000 0000 0000 0000  ..C4...e........
000106c4: 6582 f000 0000 0000 650e f000 1000 0000  e.......e.......
000106d4: 660d f000 1000 0000 650a f002 1000 0000  f.......e.......
000106e4: 4b82 f300 0000 0000 008b 0000 0000 0000  K...............
000106f4: 1901 0000 0000 0000 650e 0600 050d 0000  ........e.......
00010704: 6482 f300 0000 0000 008b 0000 0000 0000  d...............
00010714: 6501 0000 0000 0000 648c 0000 0000 0000  e.......d.......
```
| entry | decode | source line |
|---|---|---|
| `65 82 f0 00 …` | IF, scenario test 2 HasMeleeWeapon, myself | `IF HasMeleeWeapon(myself) THEN` |
| `65 0e f0 00 10` | IF Exists, myself.LastAttacker (mod 16) | `IF Exists(myself.LastAttacker) THEN` |
| `66 0d f0 00 10` | IF NOT IsTarget(myself.LastAttacker) | ✓ |
| `65 0a f0 02 10` | IF InRange(myself.LastAttacker, 2) | ✓ |
| `4b 82 f3` | #75 SetTarget(last) | ✓ |
| `00 8b` | (cont.) DoAttack() | ✓ |
| `19 01` | #25 Continue() | ✓ |
| `65 0e 06 00 05 0d` | IF Exists(enemy.ByRange.Pick) | ✓ |
| `64 82 f3` | #100 SetTarget(last) | ✓ |
| `00 8b`, `65 01`, `64 8c` | DoAttack(); IF True() THEN; #100 FinishCombat() | ✓ |

Header bytes after the name (0x0F..0x17 here: `d2 00 00 43 34 00 7f 88 65`) are leftover buffer
contents — `CompileHeader` only writes the length and name bytes; bytes 0x18..0x1F are zero as the
compiler writes them. Entries start at +0x20 (`6582 f000 …` at 0x106c4), 12 entries = (0x80−0x20)/8.
[HIGH]

---------------------------------------------------------------------------------------------
## 4. Evaluation (`EvaluateAI`)

Pseudocode faithful to `EvaluateAI__14SCombatAIEntry @ 100b07a0` [HIGH, every branch read]:
```
roll = 100; cont = false; p = first entry
loop:
  if p >= end: return
  if roll <= 0 and p.op != 0:            # a group was chosen and we reached the next group/rule
      if not cont: return
      skip while p.op < 0x65              # skip the rest of this rule's actions
      roll = 100; cont = false; continue
  switch p.op:
    0x65 (IF..THEN):     if test: p++ ; roll = rand%100+1
                         else: skip tests (op>100), then skip actions (op<0x65)
    0x66 (IF NOT..THEN): if !test: p++ ; roll = rand%100+1
                         else: skip tests, then actions
    0x67 (IF..OR):       if test: skip remaining tests; roll = rand%100+1   else: p++
    0x68 (IF NOT..OR):   if !test: skip remaining tests (+ one discarded Random())  else: p++
                         then roll = rand%100+1
    weight w (0..100):   roll -= w
                         if roll < 1: if action == Continue: cont = true else PerformAction
                         p++
```
Weighted choice: a uniform 1..100 roll is decremented by each weight in order; the line that takes
it to ≤ 0 fires, and every following weight-0 (continuation) line fires too, until the next
weighted line or test ends the rule. If the weights total < 100 nothing may fire, and evaluation
falls through to the next rule (the manual's warning). [HIGH]

Consequence for the shipped `Missile User.ai`: `IF OutOfAmmo() THEN` is followed by an
**unweighted** `Retreat()` (compiled `00 83`, segment 0x0415 entry 6); a weight-0 line never
fires on its own, so the out-of-ammo rule is a no-op and evaluation continues. [HIGH as a
reading of compiled data + evaluator]

### 4.1 Objects and groups (`CalculateObject`)
Working set: a 512-byte score array indexed by character, built from the active-monster list
(`*_DAT_100cde6c`, linked by `TActiveMonster+0x38`). [HIGH]

| base | result |
|---|---|
| myself (0xF0) | the evaluating monster's character |
| main (0xF1) | the current party leader (`PTR_DAT_100cdbec`) |
| target (0xF2) | `TActiveMonster+0x1C` (current target) |
| last (0xF3) | the result of the **previous** `CalculateObject` call (static) |
| good / evil / neutral / feral | members with CharEntry `+0x19` == 2 / 1 / 0 / 3, score 0xFF |
| ally / enemy / bystander | `GetEnemyStatus(myself, m)` == 1 / 0 / 2 |
| everybody | all active |

| modifier | effect on scores (each in-set member, `s = s·f >> 9` with f in 0x100..0x1FF) |
|---|---|
| CurTarget | individual → its `+0x1C` target |
| Allies / Enemies | rebuild set from `GetEnemyStatus(indiv, m)` == 1 / == 0 |
| Attackers | set = monsters whose target is the individual |
| ByRange | Chebyshev distance d from myself; f = 0x100 + 0x100·(0xF0/0x100)^(d−1) (integer, repeated `·0xF0 >> 8`) |
| ByDamage | f = 0x100 + (max−cur)·0x100/max (more damaged → higher) |
| ByHealth | f = 0x100 + cur·0x100/max |
| ByStrongest | **identical code to ByHealth** |
| ByWeakest | **identical code to ByDamage** |
| Randomize | f = 0x181 + (rand & 0x7F) |
| Best | highest score (first in list order on ties) |
| Random | highest of score + (rand & 0x3F) |
| Pick | highest of score + (rand & 0x0F) |
| Protecting | individual → `TActiveMonster+0x24` |
| ProtectedBy | set = monsters whose `+0x24` is the individual |
| LastAttacker | individual → `TActiveMonster+0x20` |

"Strongest" therefore means "healthiest by HP ratio" as implemented — no stat comparison. [HIGH:
cases 7/8 and 6/9 are byte-identical in the decompile]

### 4.2 Built-in tests (`EvaluateCondition`, index < 0x80)
| # | test | implementation |
|---|---|---|
| 1 | True | true |
| 2 | False | false |
| 3 | IsSpecies | **always false** (`case 3: bVar9 = false`) |
| 4 | IsA | **always false** (`case 4`) |
| 5/6/7 | HealthIs / AtLeast / LessThan | category c = 0 if max = 0; 5 if cur > max; else cur·5/max (integer). Compared with param−1 (Dead 0 … Complete 5) |
| 8 | InParty | CharEntry `+8 & 0x40` |
| 9 | BeenMet | CharEntry `+8 & 0x80` |
| 10 | InRange(o,r) | dx² + dy² ≤ r² (Euclidean, from myself) |
| 11 | Random(n) | n ≥ rand%100 + 1 |
| 12 | TestFlag(o,f) | CharEntry `+6` bit (f−1), f ≤ 16 — so the 16 ObjectFlags name the 16 bits of the status word (IsAlive = bit 0 … IsLavaProof = bit 15) |
| 13 | IsTarget(o) | o's monster == myself's target |
| 14 | Exists(o) | o has an active monster (on stage) |
| 15 | ManaAtLeast(n) | myself CharEntry `+0x10` ≥ n |
| 16 | InLOS(o) | `TViewer::IsStraightAbs` between the two positions |

Actions < 0x80: 1 Continue (handled in EvaluateAI), 2 Debug(n) → prints "AI Debug %d". [HIGH]

---------------------------------------------------------------------------------------------
## 5. Scenario tests/actions are game-script routines

`EvaluateCondition` for index ≥ 0x80 calls `TInterp::DoInterpRoutine(index + 0x880, self, obj,
param)` and tests `IsTrue` of the result; `PerformAction` for ≥ 0x80 calls `DoInterpRoutine(index
+ 0x900, …)`. Arguments: self = `VAddr(4, 0x40, selfChar)`, obj = `VAddr(4, 0x40, objChar)`, the
param byte. [HIGH]

So scenario test k (1..6) runs script segment **0x0900 + k** and action k (1..13) runs segment
**0x0980 + k**. The data has page 0x09 with 19 segments 0x0901..0x098D — exactly 6 tests + 13
actions. [HIGH: id arithmetic + census `page 09: 19 segs ids 0901..098d`]. Their bytecode
semantics (what `DoAttack`, `CastSpell`, `Retreat` actually do) are in the script VM, not native
code — NOT RESOLVED beyond identification.

---------------------------------------------------------------------------------------------
## 6. Binding to characters

- CharEntry `+0x1E` holds the behaviour; values ≥ 0xB0 select a user/scenario AI slot (character
  window popup, `RecalcUserAIMenu`: control value = `+0x1E − 0xAD`). [MED]
- Values < 0xB0 (3..8 in data; `HatchEgg` derives them from the activity byte) appear to be
  built-in tactics; `STR# 502` lists seven built-in behaviour names (Attack Strongest, Defend,
  Attack Weakest, Beserk, Retreat, Attack Nearest, Target Attack) and `TActiveMonster` has
  `FindStrongest/FindWeakest/FindNearest/DoDefend/DoRetreat/DoRoam` — the mapping value → tactic is
  **NOT RESOLVED** [LOW].
- **No direct caller of `PerformAI` or `CompileAIFile` exists in the dump** (`grep` of the call
  names returns only their own definitions). They are reached indirectly — most likely from the
  script builtins in the undisassembled block after `IsString__7TInterp` (see `script-vm.md` §6) or
  from dialog callbacks. NOT RESOLVED.
  ⚑ corrected (review 2026-10-03): the dump has an unmentioned **`EditUserBehaviors__Fv @ 100b1b38`** that constructs
  `TEditUserBehavior` (0x18 bytes) and invokes it through the pointer-call glue — the obvious owner
  of the `.ai` → `CompileAIFile` path [MED]. The builtin table is now decompiled
  (`script-builtins.md`): **no builtin calls `PerformAI` or `CompileAIFile`**, so the scripts are
  not the route; `PerformAI`'s caller remains NOT RESOLVED (a TVector/vtable entry is the likely
  path).
- Debugging: slots 0xB0..0xCE with a non-zero byte in a per-slot table (`_DAT_100cf0fc`) open the
  `TAIDebug` window, which single-steps entries (`SetCurrentLine`). [MED]

---------------------------------------------------------------------------------------------
## 7. The `.rsrc` siblings

Each `*.ai.rsrc` (1,454 B) holds exactly two resources: `MPSR 1005` (72 B; MPW Shell editor
state — font "Monaco", size 9, window rects) and `BBST 128` (1048 B; BBEdit state). Editor
metadata only; the game never reads them. [HIGH: `rsrc.py` census; MPSR bytes `0009 4d6f6e61636f`
= size 9 + "Monaco"]

---------------------------------------------------------------------------------------------
## 8. The seven shipped scripts, annotated (paraphrase of logic, as the evaluator will run them)

- **Attack Nearest / Attack Weakest / Attack Strongest** — same shape: if armed for melee and
  someone hit me who isn't my target and is within range 2 → 75% (Nearest) or 50% (others)
  retarget to them and attack, else (`Continue`) fall through; then pick `enemy.ByRange` /
  `ByWeakest` (=ByDamage) / `ByStrongest` (=ByHealth) `.Pick` and attack; if nothing exists,
  `FinishCombat`. Note `SetTarget(last)` relies on `last` = the object computed by the rule's last
  test. [HIGH]
- **Beserk** — the first rule's action (`#100 SetTarget(enemy.ByStrongest.ByRange.Pick)`) is
  preceded by a column-0 comment line; compiles normally. If no target, pick and attack; else
  attack until dead; else finish. [HIGH]
- **Defend** — retreat if health below Scratch (i.e. any damage, category < 4); switch to a range-5
  weapon if available (Continue); target last attacker, else nearest enemy; if the nearest enemy is
  within 3, target it and `RunAwayFrom(last,5)`; else finish. [HIGH]
- **Dummy ("Test AI")** — retreat below Wounded; else 20/10/70 target by damage/health/range; no
  attack action. [HIGH]
- **Healer** — heal (spell 10) the most damaged ally below Wounded; if mana < 10 `Pass(10)`;
  spell 14 on `enemy.ByStrongest.Pick`; spell 18 on `enemy.ByDamage.Pick`; else finish. [HIGH]
- **Missile User ("Missile Script")** — equip ranged if not using one (Continue); the out-of-ammo
  retreat is inert (§4); back off to 5 if nearest enemy within 3; retarget if target beyond 7 and
  an enemy within 4; close to 5 on a far target; else attack. [HIGH]
