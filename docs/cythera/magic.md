# Cythera 1.0.4 — magic, abilities, skills, alchemy (code reading)

Register: **code reading**. What the shipped bytecode and the PPC engine do; nothing designed,
nothing play-verified. Labels: **HIGH** = quoted bytecode / decompiled lines prove it; **MED** =
inferred from structure, names or one source; **LOW** = conjecture. Formulas are integer
arithmetic exactly as executed. Notation follows `script-builtins.md` §0 and the listings
(`A30…` args, `L00…` locals, `.fNN` fields, `G09` speaker, `R0EA1` routine 0x0EA1).

---------------------------------------------------------------------------------------------
## 0. Scope, method, what was not read

- **Read this session:** `script-census.md`, `script-vm.md`, `script-builtins.md`, `rules.md`,
  `engine-classes.md`, `data-format.md` §4.3; listings `ghidra/cythera-scripts/` for all 87
  page-0x1A segments (spell `use`/`use_on`/`sel11` bodies in full), routines 0x0EA1 0x0E85 0x0EAC
  0x0E96 0x0EB5 0x0E83 0x0E82 0x0E8A 0x0E8B 0x0E86 0x0E81 0x0E8C 0x0EB8 0x0EAD 0x0EAE 0x0EAF
  0x0EB1 0x0EA2 0x0E0A 0x0901 0x0981 0x0C4B 0x0C4C 0x0F14 0x0A00–0x0A07, defaults 0x3015 0x301A
  0x301F 0x3035 0x3040 0x3041 0x3043, props 0x101F 0x104B 0x104C 0x1105 0x10E9 0x10EA 0x10EC–0x10F7
  0x108A 0x1133 0x1135 0x1150 0x1157 0x1187 0x118A 0x113C, chars 0x180A 0x184A 0x1861 (excerpts),
  0x1802 @0DC0, 0x1036 excerpts. Engine: all 9 `TSpellFX` methods, `FindSkill`, `RecalcFX`,
  `RecalcPartyLight`, `PostUse`, `NeedsTarget`, `MouseRoutine` (target-flag part), `UseOnCommand`
  ×2, `PerformMacro`, `ScheduleSkill`, `DefineFKey` (head), `DrawStatPart` (icon loop),
  `DoTicks` (PassTime call), `SetField` cases 0x1C–0x28, `GetGlobal` cases 9/0x13, `Ctor` (tail),
  DoExpr 0x4B–0x4D; builtins AC, C1–C4. Data: table `0x100D46D8` read from the unpacked PEF data
  section (`tools/pef.py`).
- **Method:** grep every C1–C4 call (90 = census 10 + 37 + 28 + 15), every literal skill id passed
  to `find_skill`/R0EAC/R0EAD/R0EAE/R0EAF, every `create_prop(28, …)`; follow each spell's
  `use` → R0EA1 → return value → native targeting → `use_on`/`sel11`.
- **Not read:** the hintbook PDFs, `Cythera.rsrc` STR# (no ability-name strings checked), the
  TAbilityList click path that sends selector 9 for a spell (§2.1), `TGameViewer::ShowMagic`
  internals, combat AI that consumes the status bits (ai-scripts.md owns it), the selector-28
  attack script (combat bank), most character conversations that teach skills.

---------------------------------------------------------------------------------------------
## 1. Where magic lives

| fact | evidence | conf |
|---|---|---|
| Page 0x1A = class 0x50 objects, segment `0x1A00 + prop type` (script-vm §2.1). Types **0x00–0x30 are 49 spells**, **0xC0–0xD6 are 23 skills**, **0xF1–0xFF are 15 "Do" commands** (Estimate Time … Pass); 87 segments total, every `name` method returns a literal (§3, §7) | `1a00 @000B return "Directed Nexus"`, `1ac0 … "Attack"`, `1af1 … "Estimate Time"` | HIGH |
| A known spell or a skill is **one prop of kind 0x1C** whose location low word = the owner character and type = spell/skill id. `FindSkill(char, id)` scans props from 0x100: `*(char *)puVar2 == '\x1c' && param_1 == (*puVar2 & 0xffff) && (*(ushort *)(puVar2 + 1) & 0x3ff) == param_2` | `FindSkill__Fss @ 10056100` | HIGH |
| Scripts create them with `create_prop(28, 0, owner, frame, type, 0, 0)` (x = 0, y = owner → location low word = owner) | `0F14 @0003 return create_prop(28, 0, A30, 0, A31, 0, 0)` | HIGH |
| The owner is read back as `.f0B:loc16`; every spell's `use` passes `A30.f0B:loc16` (the caster) to R0EA1 | `1a09 @0054 jf R0EA1(A30.f0B:loc16, 1, 2)` | HIGH |
| Skill prop **frame**: low 4 bits = level 0–15, bit 0x10 = "aptitude" (untrained). R0EAC returns 0 while bit 0x10 is set, else the frame | `0EAC @000F jf (L00.f03:frame & 16)` / `@0019 return 0` / `@001D return L00.f03:frame`; skill `search` texts print "aptitude" when `frame & 16` (`1ac4 @0027`) | HIGH |
| Spell property 51 = `[spell level, prerequisite type or Nil]`; property 54 = `[AI class]` (§3, §6) | `1a09 @0021 array[2] = [1, 212]`, `@0002 array[1] = [0]`; read by `301A @000A prop(A30, sel51, 1)` and `0981 @0021 prop(L00, sel54, 0)` | HIGH (storage) / MED (54 meaning) |

---------------------------------------------------------------------------------------------
## 2. How a spell is cast

### 2.1 Entry points
| path | what runs | conf |
|---|---|---|
| Player, character skill list / F-key macro | `PerformMacro` → `FindSkill(leader, macroType)` → `DoInterp(2, prop \| 0x40500000)` (name) → `ScheduleSkill(type, leader)` = `QueueTaskEvent(4, …)`; `DefineFKey` only binds objects answering selector 9 (`_HasProperty__7TInterpFs5VAddr(&local_58,9,local_54)`). The consumer of task event 4 that sends selector 9 was **not traced** | `PerformMacro @ 10036ab4`, `ScheduleSkill @ 1001d2a0`, `DefineFKey @ 10037798` | MED |
| Grimoire/tome texts: "To cast it, select it from the character skill list." | `104C @020B…0245`, `1105 @01F3` | HIGH (text) |
| Scroll (prop type 75, quality = spell type): builds a temporary spell with **no owner** and forwards `use`/`use_on`/`sel11`, then deletes itself | `104B @0081 L00 = create_prop(28, 0, 0, 0, A30.f06:quality, 0, 0)`, `@009B L01 = L00.sel9/use()`, `@00B5 delete_prop(A30)` | HIGH |
| NPC/AI: activity 75 (no target) / 76 (target) → routines 0x0C4B / 0x0C4C via the selector-33 default `3021 return R[0C00+A31](…)`; 0x0981 (`CastSpell`) chooses 75 for AI class 3/5, 76 otherwise, and skips class 1 when `R0E8C(caster,target) > 2` (squared distance) | `0981 @0028 jf ((L01 == 3) \|\| (L01 == 5))`, `@0035 queue_activity(A30, 75, A32, 0, 0)`, `@004A jf (R0E8C(A30, A31) > 2)`, `0C4C @002B L02 = L01.sel9/use()`, `@0037 send L01.sel10/use_on(L00)` | HIGH (bytecode) / MED (3021 = activity runner) |
| 0C4C provokes the target (`sel67`) only when AI class ≠ 0 | `0C4C @006D jf (L03 != 0) -> 007A`, `@0075 send L00.sel67(A30)` | HIGH |
| Companion "Cast..." command (type 0xF9, Timon 0x184A): menu of 8 spells, then **retypes the command prop** to the chosen spell and sends `use` | `184A @0179 pick_item("Cast which spell?", …)`, `@01A9 setfield A31.f0B:loc16 = A30`, `@01AF setfield A31.f04:type = L02[1]`, `@01B8 return A31.sel9/use()` | HIGH |

### 2.2 The cost check — R0EA1(caster, L, cost) (every spell's `use`)
```
0003 jf (A30 == 0) -> 0025          ; caster 0 (scroll): A30 = as_char(0)
0011 A30.f23:busy = ((A30.f23:busy + 5) + A31) ; return True
002B L00 = as_cls48(A30); jf has(L00, sel68) -> 003F ; return True
003F jf (A32 > A30.f1E:magic) -> 00AA ; "The spell requires more power…" / bark "I'm too weak" ; False
00AA magic = magic - A32 ; L01 = R0E85(A30) ; busy = busy + (10 + (2 * A31))
00CC jf ((random(0, L01) + random(0, L01)) < random(0, A31)) -> 012A  ; else "You failed…" ; False
```
- **Cost = magic (field 0x1E) by the literal `cost` argument**; no reagents, no fatigue. Magic
  and busy are charged **before** the success roll and before targeting. [HIGH — 0EA1 @003F/@00AA/@00BC]
- **Busy:** caster `busy += 10 + 2·L` (field 0x23 = CharEntry +0x12 byte, `SetField` stores
  `(char)` with no clamp). Scroll path: `busy(char 0) += 5 + L` — character **0**, not the reader.
  [HIGH — 0EA1 @0011/@00BC; `SetField case 0x23`]
- **Failure:** fail iff `random(0,C) + random(0,C) < random(0,L)`, C = R0E85(caster),
  L = spell level. `random(lo,hi)` = `lo + ((uint32)Random() mod (hi−lo))` for lo < hi, else lo
  (`Builtin_AC`: `(int)sVar3 + ((int)sVar4 - ((uint)(int)sVar4 / uVar2) * uVar2)`), so
  `random(0,n)` ∈ 0…n−1 and `random(0,0) = 0`. **Level-1 spells can never fail**
  (random(0,1) = 0). [HIGH]
- **Free casting:** a caster whose class-0x48 (monster-type) object has property 68 skips cost,
  busy and roll. Property 68 is the innate spell list read by `HasSpell` 0x0901. [HIGH bytecode /
  MED meaning]
- **Messages:** leader → text; any other caster gets a bark (`.f26 = "I'm too weak"` /
  `"Spell failed"`) only when G13 is True. [HIGH — 0EA1 @0048–@0090, @00E1–@0110]
- **Caster level C = R0E85:** `R0EAC(caster, 195)` (Casting skill frame, 0 while aptitude); if 0,
  `R0E96`: `switch ((A30.f20:ce1D >> 2) & 3)` → 0, `level / 2`, `level`, `level * 2`. [HIGH —
  0E85, 0E96]

### 2.3 Targeting (native) — the `use` return value
`PostUse @ 1005345c`: an integer ≠ 0 → `NeedsTarget(obj, value)`; otherwise
`RecalcPartyLight`. `MouseRoutine @ 1002706c` then accepts a click by these bits of the stored
value (`*(ushort *)PTR_DAT_100cdda4`): [HIGH for the tests; names MED]

| bit | accepted target | then | quoted test |
|---|---|---|---|
| 0x0001 | any prop | `UseOnCommand(obj, prop)` → selector 10, A31 = `prop \| 0x40000000` | `(*(ushort *)PTR_DAT_100cdda4 & 1) == 0) \|\| (local_60 == 0)` |
| 0x0002 | a map cell within ±15 of the leader | selector **11** (obj, x, y) | `& 2) == 0 \|\| (local_66 == '\0')`; `UseOnCommand…ss`: `-0x10 < sVar4 … < 0x10` |
| 0x0004 | a prop with an active monster (a creature) | selector 10 | `_GetCharacter__14TActiveMonsterFs((int)local_60), iVar11 == 0` |
| 0x0008 | a character < 0x100 with the party bit | selector 10 | `(0xff < local_60)) \|\| ((puVar5[local_60 * 0x20 + 8] & 0x40) == 0)` |
| 0x4000 | needs a straight line | `IsStraightAbs` | `if ((… & 0x4000) != 0)` |
| 0x8000 | "touch": target adjacent (path < 2), in an inventory window, or a party member; then `WalkToLocation` | | `(local_68 < 2)`; `_WalkToLocation__8TGameSysFssUc` |

Return values used by spells: 0 / Nil (immediate), **1** any object, **2** location, **4** creature
at range, **8** party member, **0x8001** touch object, **0x8004** touch creature. During the
`use_on`, `MakeActive` restores the caster saved at `NeedsTarget` time and `*_DAT_100cdcd4` is
incremented, which makes **G13 True** (`GetGlobal case 0x13`: True if the active character is the
leader or `0 < *_DAT_100cdcd4`). [HIGH]
`G09` (speaker) = the active monster's character; with no active monster the case **falls
through into 0x13** and returns True/False. [HIGH — `GetGlobal` case 9 has no `break`]

---------------------------------------------------------------------------------------------
## 3. Spell list (49 class segments 0x1A00–0x1A30)

Cols: **L/cost** = R0EA1 arguments (L always equals property 51[0] — checked for all 47 that
have it); **pre** = property 51[1]; **tgt** = `use` return (§2.3); **AI** = property 54[0];
C = caster level R0E85 (owner-less scroll casts take the literal "scroll" value). Every effect
row is HIGH from the cited `use`/`use_on`/`sel11` lines unless marked.

| type | name | L/cost | pre | tgt | effect as executed | AI |
|---|---|---|---|---|---|---|
| 00 | Directed Nexus | 1/1 | — | 0 | `teleport(1, 1, 0)` (`1a00 @00ED`); text: to LandKing Hall | 0 |
| 01 | Vision of the Night | 3/8 | — | 0 | `temp_ability(G09, 18, 1024 + ((C − 3) * 256))`, scroll 1024; `refresh_light()` (`1a01 @00C7/@00E8`) | 4 |
| 02 | Minor Embrightenment | 1/2 | — | 0 | `temp_ability(0, 0, 1024 + ((C − 1) * 256))`, scroll 1024 (`1a02 @00A3`) | 4 |
| 03 | Detect Concealment | 2/10 | (no prop 51) | 0 | props within r 5 of speaker (`d²≤25`), kind ≤ 3, type ∈ {356 wall, 51 secret door, 53/253 secret passage, 354 loose board, 357 fine wire} → `show_magic(prop, 244)`, "You detect …!" (`1a03 @0089–@017C`) | 4 |
| 04 | Detect Traps | 2/10 | (no prop 51) | 0 | same scan, types {352 poison trap, 353 blast trap, 355 small hole, 230 spikes} (`1a04 @00B8–@00FA`) | 4 |
| 05 | Remote Manipulation | 4/16 | — | 1 | `L00 = A31.sel9/use()`; non-Nil non-0 result → "It is too complex to use from here." (`1a05 @00CB/@00D2`) | 4 |
| 06 | Death Strike | 5/15 | — | 0x8001 | `A31.sel67(G09)`; `R0EB8(A31, 200, 68, G09)` (`1a06 @00B4/@00BA`) | 2 |
| 07 | Acertainment | 2/4 | — | 0 | `temp_ability(G09, 29, 500)` (`1a07 @0097`) | 4 |
| 08 | Alleviation | 3/6 | 212 | 0x8004 | `remove_ability(A31, 9)` (`1a08 @00A8`) | 0 |
| 09 | Lesser Healing | 1/2 | 212 | 0x8004 | `health = ((health + 5) + random(1, 5))` → +6…+9 (`1a09 @00A9`) | 0 |
| 0A | Healing | 2/4 | 09 | 0x8004 | `+ 10 + random(1, 10)` → +11…+19 (`1a0a @00A4`) | 0 |
| 0B | Greater Healing | 3/6 | 0A | 0x8004 | `+ 20 + random(1, 20)` → +21…+39 (`1a0b @00AA`) | 0 |
| 0C | Embrightenment | 2/4 | 02 | 0 | `temp_ability(0, 1, 2048 + ((C − 2) * 512))`, scroll 2048 (`1a0c @009C`) | 4 |
| 0D | Soporiferousness | 2/4 | — | 0x8004 | "^X falls asleep." `temp_ability(A31, 22, 4096)` (`1a0d @00C7`) | 1 |
| 0E | Terrorisation | 2/6 | — | 0x8004 | unless `has_ability(A31, 27)`: "screams in fear", `temp_ability(A31, 13, 1280)` (`1a0e @00B1/@00D1`) | 1 |
| 0F | Derangement | 3/6 | — | 0x8004 | `temp_ability(A31, 21, 1280)` (`1a0f @00CD`) | 1 |
| 10 | Major Embrightenment | 3/6 | 0C | 0 | `temp_ability(0, 2, 4096 + ((C − 3) * 1024))`, scroll 4096 (`1a10 @00A4`) | 4 |
| 11 | Nutrient | 1/4 | — | 4 | `jf (food < 100)`; `food = food + 10` (`1a11 @00CE/@00D8`) | 4 |
| 12 | Mystic Arrow | 1/4 | — | 1 | `missile_burst(sx, sy, tx, ty, 433, 0, 0)` (7 args); `A31.sel67(G09)`; `R0EB8(A31, 10 + random(0, 10), 66, G09)` → 10…19 (`1a12 @00D6–@00F5`) | 2 |
| 13 | Awaken | 1/1 | — | 0x8004 | `remove_ability(A31, 22)`; "is awoken."; if `activity == 145`: talk, "rolls over and goes back to sleep." (`1a13 @00AD–@0101`) | 0 |
| 14 | Detect Rune | 1/2 | 211 | 2 | sel11: first prop at (x,y) with `kind & 2` and type 245…248 → "You discover a rune…", `kind &= -3`, `set_arrival_byte(1)` (`1a14 @00A1–@00F5`) | 4 |
| 15 | Resist Blows | 2/6 | — | 8 | `temp_ability(A31, 20, 256)`; no `show_magic` (`1a15 @00B0`) | 0 |
| 16 | Rune of Warding | 2/8 | 211 | 2 | sel11: `missile_burst(x,y,x,y,432,40,5,0)`; `create_prop(33, x, y, 0, 245, G09, 0)`; `kind \|= 2` (`1a16 @00DC–@0103`) | 4 |
| 17 | Rune of Flame | 2/8 | 211 | 2 | as 16 with type 246 (`1a17 @00FB`) | 4 |
| 18 | Dispel Rune | 2/6 | 211 | 1 | type 245…248 → "You remove the rune." `delete_prop` (`1a18 @0089/@00B1`) | 4 |
| 19 | Rally | 2/4 | — | 0 | every party member: `remove_ability(L00, 13)` (`1a19 @00AC`) | 5 |
| 1A | Rune of Blocking | 3/12 | 211 | 2 | `create_prop(33, x, y, 0, 248, G09, 0)` — **not** hidden, no tile animation; type 248 has no class segment (`1a1a @00D9`) | 4 |
| 1B | Mage Lock | 3/12 | — | 0x8001 | doors 3/7/11: `frame = ((frame & 3) \| 12)`; chest/coffer 141/142: `frame = 3`; trapdoor 43: `if frame > 2: x = x + 1`, `frame = 2`; else "Can't magically lock X." (`1a1b @00C8/@010A/@0146/@0151`) | 4 |
| 1C | Awaken All | 3/9 | 13 | 0 | party: `remove_ability(L00, 22)` (`1a1c @00B9`) | 5 |
| 1D | Lightning | 4/16 | — | 1 | `missile_burst(s→t, 433, 2, 0, 0)`; each path victim `R0EB8(v, 10 + random(0, 10), 32, G09)`; then `A31.sel67`, `R0EB8(A31, 20 + random(0, 20), 32, G09)` (`1a1d @00BE–@0119`) | 2 |
| 1E | Cure | 4/8 | 08 | 0x8004 | remove 9, 22, 14, 21 (`1a1e @00C5–@00D4`) | 0 |
| 1F | Resist Fire | 4/12 | — | 8 | `temp_ability(A31, 23, 500 + ((C − 4) * 100))`, scroll 500 (`1a1f @00C4/@00E1`) | 0 |
| 20 | Open | 4/12 | — | 0x8001 | `send A31.sel53()` — default 0x3035 returns 0, so only classes defining selector 53 react (`1a20 @00AF`) | 4 |
| 21 | Rune of Pain | 4/20 | 211 | 2 | as 16 with type 247 (`1a21 @00EB`) | 4 |
| 22 | Fireball | 5/20 | — | 2 | `missile_burst(sx, sy, x, y, 432, 16, 5)` (7 args); every burst victim: at (x,y) → `sel67`; `R0EB8(L00, 25 + random(0, 10), 8, G09)` → 25…34 (`1a22 @00CD–@0110`) | 2 |
| 23 | Paralyze | 5/15 | — | 0x8004 | `temp_ability(A31, 14, 500)` (`1a23 @00D8`) | 1 |
| 24 | Shake Down | 5/10 | — | 4 | count children n; `L04 = random(0, L00)`; second loop **never increments L00**, so only child 0 can drop (when L04 = 0, chance 1/n) → kind 1 at target x,y, "^X drops Y."; otherwise "Nothing seems to happen." (`1a24 @0105–@016D`) | 4 |
| 25 | Daylight | 5/10 | 10 | 0 | `temp_ability(0, 2, 8192 + ((C − 5) * 2048))`, scroll 8192 (`1a25 @0091`) | 4 |
| 26 | Mass Terrorisation | 6/12 | 0E | 0 | `iterate_enemies_of(G09)`: unless ability 27, `temp_ability(L00, 13, 500)` "shreaks in fear" (`1a26 @00A6/@00C6`) | 3 |
| 27 | Charm | 6/18 | — | 4 | in party → "They are already on your side..."; else `temp_ability(A31, 17, 500)` (`1a27 @00AB/@00EF`) | 1 |
| 28 | Fetch | 6/24 | — | 1 | kind 0 or 1 → `kind = 9`, `loc16 = G09` (into the caster, data-format §4.3 "inside a container"); else "It is too large and heavy." (`1a28 @00B2–@00CA`) | 4 |
| 29 | Mass Cure | 6/18 | 1E | 0 | party: remove 9, 22, 14, 21 (`1a29 @00A8–@00B7`) | 5 |
| 2A | Farsight | 7/14 | — | 0 | `screen_effect(2)` = magic map (`1a2a @0092`) | 4 |
| 2B | Replicate | 7/21 | — | 0x8001 | kind 0/1 and not `prop39[0] & 8` → `create_prop(kind, x, y, frame, type, quality, byte7)` — byte 7 lands in the **count** argument (`1a2b @00C2/@00F7`) | 4 |
| 2C | Mass Confusion | 7/28 | 0F | 0 | enemies: `temp_ability(L00, 21, 500)` (no immunity test) (`1a2c @00BC`) | 3 |
| 2D | Tremor | 8/16 | — | 0 | `screen_effect(0)`; enemies: `sel67`, `R0EB8(L00, 20 + random(1, 10) + random(1, 10), 4, G09)` → 22…38 (`1a2d @0092–@00B7`) | 3 |
| 2E | Restoration | 8/24 | 1E | 0x8004 | remove 9, 22, 14, 21; `health = health_max` (`1a2e @00C4–@00D8`) | 0 |
| 2F | Resurrection | 8/16 | 212 | 1 | corpse (type 78/283) → `L00 = as_char(quality)`; alive → "They aren't dead!"; else `status \|= 1`, `health = ((health_max / 4) + 1)`, every descendant → `loc16 = L00, kind = 16`, corpse deleted (`1a2f @00BA–@0148`) | 0 |
| 30 | Remove Mage Lock | 5/20 | — | 0x8001 | doors: `frame = ((frame & 3) \| 4)`; 141/142 with frame 3 → 1; trapdoor 43 → frame 0 ("…no no longer…"); else "There is no mage lock on X." (`1a30 @00D9/@0128/@0160`) | 4 |

Common to every spell: `use` starts with R0EA1; `search` prints a "This spell …" description;
visuals are `show_magic(G09 or as_prop(G09), 240)` (Detect: 244 on the found prop) and
`positional_sound(44…48, G09.x, G09.y)` — 44 mind, 45 attack, 46 healing, 47 light/sense,
48 misc/runes by observation. [HIGH bytes / LOW grouping]
Visible quirks (all HIGH as code): Resist Blows compares `as_char(A31) == as_char(A30)` with A30
the **spell** object (`1a15 @00BA`), so "You feel safer." vs "^X feels safer." does not test the
caster [MED on what `Ctor` returns]; Mystic Arrow and Fireball pass 7 of `missile_burst`'s 8
arguments (the 8th = stale slot, script-vm §8) — they are census §4's two `E2 7×2` calls.

### 3.1 Runes on the ground [HIGH]
Rune props are kind 33 (0x21); Warding/Flame/Pain add bit 2 (`kind | 2`), which Detect Rune tests
and clears — read here as "not yet discovered" (data-format §4.3 calls 0x22/0x23 "blocker", MED).
Stepping on a prop reaches its selector 10 through the default *moved* handler
(`301F @00AF set A31 = as_prop(A31)`, `@00B5 send A31.sel10/use_on(A30)`). Byte 6 = caster.
| type | segment | trigger effect |
|---|---|---|
| 245 Warding | 0x10F5 | `kind &= -3`, `show_tile_animate(1)`, message "Something has triggered one of your runes of warding." only `if quality == 32`, delete (`10F5 @0005–@0058`) |
| 246 Flame | 0x10F6 | `missile_burst(x,y,x,y,433,16,2,0)`; each victim `R0EB8(L00, ((random(0, 6) + random(0, 6)) + 2), 8, Nil)` → 2…12 fire, no XP |
| 247 Pain | 0x10F7 | `R0EB8(A31, ((10 + random(1, 11)) + random(1, 11)), 64, Nil)` → 12…30 |
| 248 Blocking | none | no class segment (inert prop) |

### 3.2 Damage path R0EB8(target, dmg, type, attacker) [HIGH bytecode; damage-type names MED]
`0EB8 @0003 set A31 = A30.sel64(A31, A32)` (resistance; default 0x3040), `@000C jf (A31 <= 0)`,
`@0030 send A30.sel65(A31, A32)` (apply; default 0x3041), then XP to the attacker:
`L02 = ((L01.f1B:level - L00.f1B:level) + 1)`; if L02 > 0 → `R0E8B(attacker, min(dmg, L02))`,
else if `dmg > (0 - L02)` → `R0E8B(attacker, 1)`. R0E8B adds to `exp` capped at 65535 and calls
the level-up R0E86 when `exp > ((1 << (level − 1)) * 100)`.
Type bits seen in 0x3040 (target = class-0x48 flags `.f32`/`.f33`): `& 8` fire — **0 damage if
`has_ability(A30, 23)`** (`3040 @0075`), immunity `.f32 & 128`, double `.f32 & 512`; `& 32`
lightning (immune `.f32 & 32768`); `& 64` magic (halved `.f32 & 2048`); 0x3041: `& 256` poisons
(`add_ability(A30, 9)`) and every hit `remove_ability(L00, 22)` (wakes), paralysis may break:
`jf (random((A31 + 20)) < A31)` — a one-argument `random` (stale `hi`, script-vm §8). Spells use
68 (Death Strike), 66 (Mystic Arrow), 64 (Pain), 32 (Lightning), 8 (Fireball, Flame), 4 (Tremor).
Armour/defence terms (`R0E81`, Defense skill 193) belong to the combat bank.

---------------------------------------------------------------------------------------------
## 4. What `TSpellFX` does natively — state only [HIGH unless marked]
`TSpellFX` holds **no visuals**: a `std::map<(char, ability), u16>` (`_DAT_100cea28`), the status
bits in `CharEntry`, `RedoStat` on the status window, and `RecalcFX` (= viewer +0xC := 1,
`RecalcPartyLight`, `DoTicks(0,0)`). Spell visuals are the separate builtins E1–E4 / E7.
- **Bit storage** (Add/Temp/Remove/Has, same code in all): ability `< 8` → CharEntry byte **+8**
  bit n; `< 0x18` → u16 **+6** bit n−8 (the status word, rules §4); `< 0x20` → byte **+0x1A**
  bit n−24; ≥ 0x20 → map only. `if (param_2 < 8) … else if (param_2 < 0x18) … else if (param_2 < 0x20)`.
- **AddAbility(c,a)**: set bit; new entry → value **0xF000**; existing < 0xF000 → 0xF000; else
  `+1` (a stack count). Then `RecalcFX` only on the existing-entry path.
- **TempAbility(c,a,d)**: set bit; new entry → d; existing → `max(existing, d)` (`if (… < param_3)`),
  so a permanent (≥ 0xF000) entry is never shortened.
- **RemoveAbility(c,a)**: entry `< 0xF001` → erased; else `−1`. Then the bit is cleared **whenever
  it is set**, even if a stack remains (`if (!bVar6) { … bVar6 = bit set … }` then clear). After
  removing one of two stacked sources the map still says 0xF000 (HasAbility True) while the
  status bit is clear. `RecalcFX` does not rebuild bits.
- **RemoveStackedAbility(c,a)**: erases the entry outright and clears the bit (used by
  `DeathRites` for 0xD 0xE 0x16 0x15, rules §1).
- **HasAbility(c,a)**: `a == 0x7000` → `(byte)CharEntry[c][+0x1B] < 4` (food < 4 = **Hungry**);
  map entry → its value; else the bit → 0xF000. Builtin C4: 0 → Nil, ≥ 0xF000 → True, else the
  remaining duration.
- **PassTime(units)** from `DoTicks(n, abs)`: `local_44 = (short)param_2` capped `-0x1001`
  (0xEFFF) → `_PassTime__8TSpellFXFUs(local_44)`. Entries ≥ 0xF000 never tick; `value > units` →
  `value − units`; else expire: id high nibble 0 → clear bit + `RedoStat`; **0x5000|n** → send
  selector 21 (signal) with arg n to the character's zone object (`VAddr(4,0x20, CharEntry word0
  >> 24)`) and to the character; **0x4000|n** → plain timer (kept while value 0). Removed with
  the erase loop. No shipped script passes a literal ≥ 0x20.
- **RemoveAllAbility(c)** (from `TActiveMonster::__dt`): same expiry actions for that character.
- **Duration unit = clock unit = 1/4096 hour** (engine-classes §3.1): 256 = 3¾ min, 500 ≈ 7.3 min,
  1024 = 15 min, 1280 = 18¾ min, 2048 = 30 min, 4096 = 1 h, 8192 = 2 h. Builtin C3 passes
  `& 0xffff`; a negative scaled duration (C below the spell level, e.g. Daylight with C = 0 →
  −2048 → 0xF800) becomes **permanent** because ≥ 0xF000 never ticks. [HIGH arithmetic / MED
  reachability]
- **Save:** `WriteFXQueue` tag `0x46585120` 'FXQ ', then (char, ability, value) per entry.
- **Who:** builtins untag `who` to a short; a class-0 prop object yields its prop index, a
  class-0x40 object its character index. Character bodies are props 0–0xFF (rules §2), so a
  clicked party member's prop index = its character index. [MED]
- **Party light:** `RecalcPartyLight` takes max |prop50·10| over equipped light items, then
  `if ((puVar2[8] & 1) != 0)` → ≥ 400, `& 2` → ≥ 800, `& 4` → ≥ 0x640 (1600) — **CharEntry[0]
  byte +8 bits 0–2 = abilities 0/1/2 of character 0**, which is why the light spells pass `who = 0`.

### 4.1 Ability-id table (every literal in the corpus)
"window" = shown as an icon by `DrawStatPart`, whose table at 0x100D46D8 reads
`(9, 13, 14, 21, 19, 20, 22, 28672, -1, …)`. Status names = AI ObjectFlags (rules §4).

| id | storage | name (code evidence) | set by | cleared by | conf |
|---|---|---|---|---|---|
| 0, 1, 2 | char 0, byte +8 b0–2 | party light ≥ 400 / 800 / 1600 | spells 02, 0C, 10/25 | timer | HIGH |
| 8 | +6 b0 | IsAlive (Resurrection sets `status \| 1` directly) | — | — | HIGH |
| 9 | +6 b1 | **Poisoned** (window) | 0x3041 on `& 256` hits, 301F swamp bite, fountain "tastes poisonous" (`1036 @0130`), poison trap 0x1160 | spells 08/1E/29/2E, potion 4, staff, unguent (1 in 6 per use: `random(1, 6) == 1`), Alaric (`1802 @0DC0`) | HIGH |
| 13 | +6 b5 | **Afraid** / IsFear (window) | 0E, 26, staff | 19 Rally, Alaric, DeathRites | HIGH |
| 14 | +6 b6 | **Paralyzed** (window) | 23, staff | 1E/29/2E, potion 3, hits (`random(dmg+20) < dmg`), DeathRites | HIGH |
| 17 | +6 b9 | **Charmed** | 27 | Alaric | HIGH |
| 18 | +6 b10 | IsNightVision | 01 | timer | HIGH |
| 19 | +6 b11 | IsCursed (window) | no literal setter | Alaric | MED |
| 20 | +6 b12 | IsBlessed (window); R0E81 adds `(1 + random(0, 4))` armour when set | 15 Resist Blows | timer | HIGH |
| 21 | +6 b13 | **Confused** (window) | 0F, 2C, staff, moss spores (`1150 @0103`), 0x0EA2 (`temp_ability(L00, 21, ((A30 + 2) * 3))` when `random(0,6) + 3·A30 > body + level`) | 1E/29/2E, potion 5, DeathRites | HIGH |
| 22 | +6 b14 | **Asleep** (window) | 0D, staff | 13, 1C, 1E/29/2E, potion 3, every hit (0x3041), DeathRites | HIGH |
| 23 | +6 b15 | IsLavaProof = fire immunity: 0x3040 zeroes `& 8` damage; 301F skips "Ouch! That's hot!" (terrain −221) | 1F, potion 6 (`100 + (10 * random(1, 10))`), gator boots 0x1135, char 0x1827 | timer / unequip | HIGH |
| 27 | +0x1A b3 | immune to fear spells (0E/26 test it) | odd helmet 0x1187 wield | unequip | HIGH |
| 28 | +0x1A b4 | sees through the shimmering building (`1001 @0018`, zone `1424 @0005`) | no literal setter (ring 0x1133 adds `byte7`) | — | MED |
| 29 | +0x1A b5 | Acertainment: talk scripts read it (`180A @0005 L00 = has_ability(G05:leader, 29)`, also 0x180B/0x180C) | 07 | timer | HIGH |
| 31 | +0x1A b7 | dry feet: 301F skips the 1-in-9 "Ouch! Something bit me!" poison on terrain −5…−2 | boots 0x108A, gator boots 0x1135 | unequip | HIGH |
| 0x7000 | pseudo | Hungry (window) | food < 4 | — | HIGH |
| ring | byte 7 | any id stored in the ring's byte 7 | wield 0x1133 | unequip | HIGH |

---------------------------------------------------------------------------------------------
## 5. Learning spells; magic points

| rule | evidence | conf |
|---|---|---|
| Spells are learned from a **scroll** (type 75, quality = spell) by using a **grimoire** (type 76) on it, or by using a **tome** (type 261, quality = spell). Both need Casting > 0: "You have not learned even the fundamentals of magic…" | `104C @0089 L00 = R0EAC(G05:leader, 195)`, `@012D jf (A31.f04:type != 75)`; `1105 @00A0` | HIGH |
| Already known → "You already know that spell."; then `L00.sel26(leader)` must be True; on success the new prop's owner := leader, the **scroll is deleted** (grimoire path), the tome is kept; prints "giving you N of M spells possible" | `104C @0169`, `@01B5 jf L00.sel26(L01)`, `@01BE setfield L00.f0B:loc16`, `@0208 delete_prop(A31)` | HIGH |
| Learning costs **no training point** on these paths (no write to field 0x21) | 104C/1105 bodies | HIGH |
| `sel26` default 0x301A: prerequisite `prop51[1]` not known → "You haven't mastered the prerequisites (<name>)" → False; type < 192 → `R0E8A(learner, prop51[0])` | `301A @000A–@0084` | HIGH |
| R0E8A: count known spells (types 0–127); `count >= R0EB5` → "You can't learn another spell."; `level > R0E85` → "That spell is beyond your current skills to learn." | `0E8A @0008–@00D6` | HIGH |
| **Spell capacity** R0EB5 = `((mind / 2) + level) + (4 * C')`, C' = Casting level, or R0E96 when 0 | `0EB5 @001E` | HIGH |
| **Magic max** R0E83 = `mind + M`, M = Mana skill (194) level, or R0E96 when 0; **0 when M = 0**. Mana skill `init` sets `magic_max = R0E83`, `magic = magic_max` | `0E83 @0003–@002A`; `1AC2 @0011–@0026` | HIGH |
| Regeneration: +1 magic per crossing while fed (rules §4); `SetField` clamps magic to magic_max (+0x11) and health to health_max (+0xF; ≤ 0 → `DeathRites`) | `SetField case 0x1e`, `case 0x1c` | HIGH |
| Spells 03/04 have no property 51; whether 0x301A then accepts them (`R0E8A(A31, Nil)`) is not settled | `1a03` dict has no 51 | LOW |
| `HasSpell` 0x0901: known prop → True; else scan property 68 (character, then class 0x48) taking **every second element** (`L02` toggles, compares `L03 == A32` on odd positions) | `0901 @0037–@0077` | HIGH bytecode / MED list layout |

---------------------------------------------------------------------------------------------
## 6. Skills (types 0xC0–0xD6)

| id | name | literal readers (find_skill / R0EAC / R0EAD) | conf |
|---|---|---|---|
| 192 C0 | Attack | 0E84 | HIGH ids |
| 193 C1 | Defense | 0E82 (health max), 0E84, 3040 (damage roll) | HIGH |
| 194 C2 | Mana | 0E83, trainers 184E 1850 1852 1853 | HIGH |
| 195 C3 | Casting | 0E85, 0EB5, 104C, 1105, 1802, 1850 | HIGH |
| 196–201 | Sword, Axe, Mace, Barehand, Missile, Shield | 1145 (196), 0E88 (199), 0E89/113D (200) | HIGH ids / combat bank |
| 202 CA | Traps | 1838, 1AF2 Deactivate Trap, 1AF3 | HIGH |
| 203 CB | Persuasion | 181E 1820 1838 183E 1857 | HIGH |
| 204 CC | Haggling | 0EA5, 1822, 1838 | HIGH |
| 205 CD | Awareness | 1822, 1AF1, 1AF3 (detect radius 2 → 5), 300F | HIGH |
| 206–209 | Fishing, Gambling, Cooking, Weaving | 1091; 0812/1838; 0E0A/10A3/10A9/1805; 1096/10A2 | HIGH |
| 210 D2 | Alchemy | 0E0A, 10E9, 10EA, 184F, 1852 | HIGH |
| 211 D3 | Runic Magic | prerequisite of spells 14, 16–18, 1A, 21; trainer 1853 | HIGH |
| 212 D4 | Healing Magic | prerequisite of 08, 09, 2F; trainer 184E | HIGH |
| 213 D5 | Lock Picking | 1109, 1838; `use_on` queues activities 162/68/79 with a lockpick (type 265) | HIGH |
| 214 D6 | Thievery | 300F | HIGH |

Training [HIGH bytecode]:
- **R0EAF(char, skill, graded)**: skill with aptitude bit → `frame & 15`, `init`, `R0E86(A30, 0)`,
  **no point spent**; otherwise needs `training > 0` → `training − 1`, then `frame + 1` (existing)
  or `create_prop(28, 0, A30, graded ? 1 : 0, skill, 0, 0)`; "You already know it" (ungraded) /
  "complete mastery" at frame 15 (`0EAF @000F–@00F5`).
- **R0EB1(char, trainerName, skill, graded)** wraps it with "You need some more experience before
  you can train." when `training == 0` and the skill's property-54 speech table (5 entries, index
  `((frame − 1) / 5) + 1` for graded levels; `0EB1 @0130`). Trainers seen: Hadrian 1804, Emesa
  (208) 1805, Ake (209) 1820, Neoptolemus 1821, Meleager (205, 199) 1822, Tlepolemus (206) 1837,
  Eteocles 1838, Lindus 1850, Thersites 1865, Aethon (200) 1861; R0EAF directly for 210/211/212 at
  1852/1853/184E.
- **Training points:** level-up R0E86 adds `(6 - G11) * A31` (`0E86 @004E`); `GetGlobal__Fs @
  1009376c` has no case 0x11 (`default: *param_1 = *(uint *)PTR_DAT_100cdbb0;` = Nil), and
  `DoExpr__7TInterpFRPUc @ 1007ddfc` case 0x4b with a non-integer operand pushes the left operand
  (`*(uint *)(iVar8 + sVar18 * 4) = uVar17;`), so **+6 per level** (combat.md §13.2). Char 0x1801
  sets `training = 4` (`@00B9`). [HIGH — one label for the whole rule, ⚑ corrected (wave 1 2026-10-03)]
- Quirk: 1853 @047C, 1852 @039D, 184E @043C call `R0EAE(G05:leader, id)` with **2** of its 3 args;
  A32 then aliases local L00 (the found skill) — behaviour differs from passing False only when the
  skill already exists. [MED]
- 0x1AC0/C1/C2/C3/CE/CF/D1 carry property 54 (trainer speech); the rest are name + description.

---------------------------------------------------------------------------------------------
## 7. Alchemy and potions

### 7.1 The distiller [HIGH]
| step | evidence |
|---|---|
| Distiller **233** (empty) `use`: Alchemy (210) known → "You need to fill it with water."; else "You don't know how to use it." | `10E9 @0046–@0074` |
| Water: R0E0A (from pail 1078/1079, pitcher 10A0, urn 10DA) on type 233 with Alchemy → "You fill the Distiller with water.", `type = 234`; without → "You aren't sure how to pour water into it." | `0E0A @019B–@01E6` |
| Distiller **234** `use`: needs Alchemy, prompts "Distill what element?", returns 0x8001 | `10EA @0058–@0079` |
| `use_on` (quality ≠ 1): leader `magic < 10` → "You concentrate, but end up feeling drained…", `magic = 0`, type 233; else `magic − 10`, type 233; target with property 48 → consume one (`count − 1` or delete), `R0E8B(leader, 1)` (1 XP), `create_prop(1, x + 1, y, prop48[0], 31, 0, 0)` = potion of frame prop48[0] beside the distiller, "It worked!"; no property 48 → "Hm, nothing seemed to happen." | `10EA @0569–@0637` |
| Quality-1 distiller is a quest object: an item `6181` (type 37 glowing crystal, frame 6) → +50 XP, Omen vision, distiller → 233 | `10EA @00A8–@0543` |
| The mortar and pestle (type 316) has **no methods** (description + weight only) | `113C` dict `{36, 51}` |

### 7.2 Recipes (ingredient property 48 → potion frame) and potion effects
Potion = prop type 31 (0x101F); `use` returns 8 (party member), `use_on` runs
`callx R[0A00+A30.f03:frame](as_char(A31))` then deletes the potion. [HIGH]

| frame | ingredient (segment) | potion name (`101F` table) | effect routine | formula / text | conf |
|---|---|---|---|---|---|
| 0 | seedpod (10EC) | Sustenance Potion | 0A00 | `food = 24` "You feel fully sated…" | HIGH |
| 1 | sulfur (10ED) | Healing Potion | 0A01 | `health = ((health + 10) + random(1, 10))` → +11…+19 | HIGH |
| 2 | obsidian (10EE) | Mage's Friend Potion | 0A02 | x = `10 + random(1, 10)`; magic full → nothing; `x = min(x, magic_max − magic)`; `if x > health: x = health − 1`; x > 0 → `magic + x`, `health − x` ("brief pain") | HIGH |
| 3 | bean (10EF) | Free Motion Potion | 0A03 | remove 22, 14 | HIGH |
| 4 | spider web (10F0) | Antidote Potion | 0A04 | remove 9 | HIGH |
| 5 | peppermint (10F1) | Clear Mind Potion | 0A05 | remove 21 | HIGH |
| 6 | ruby (10F2) | Smith's Friend Potion | 0A06 | `temp_ability(A30, 23, (100 + (10 * random(1, 10))))` → 110…190 units, "You feel cooler." | HIGH |
| 7 | diamond (10F3) | Far Sight Potion | 0A07 | `screen_effect(2)` | HIGH |

---------------------------------------------------------------------------------------------
## 8. Other magic items that touch abilities [HIGH]
| item | behaviour |
|---|---|
| staff 343 (0x1157) | `use` returns 0x8004 unless frame 3; charges in quality, first use `4 + random(0, 4) + random(0, 4)` (4…10); frame 0 heal `+10 + random(1, 10)`; frame 1 remove 9/22/14/21; frame 2 random hex: `random(0,4)` 0 sleep 4096, 1 fear 1280, 2 confusion 1280, 3 paralysis 500; `quality − 1`, at 0 → frame 3 |
| unguent 394 (0x118A) | 10 doses; `health + random(1, 4)`; poison removed when `has_ability(L00, 9) && (random(1, 6) == 1)` |
| boots 138 / gator boots 309 / odd helmet 391 / ring 307 | wield → `add_ability` 31 / 31+23 / 27 / byte 7; drop (selector 14) → `remove_ability` (see §4 stacking quirk) |
| moss 336 (0x1150) | spore charges `1 + random(0, 20)`; on the last one: "A cloud of spores erupts!!", confusion 1280 |
| fountain 54 (0x1036) | variant 3 "Ack!  The water tastes poisonous!" → add 9 (`@0130`); variant 8 `health + random(1, 5)`, remove 9, 22, 14, 21 (`@0FCC–@0FEA`) |

---------------------------------------------------------------------------------------------
## 9. Worked example — Lesser Healing, end to end
Leader: Casting skill prop frame 2 (no aptitude bit), magic 10/14, busy 0. Target: a party
member at health 20 / health_max 30, two tiles away.
1. Selection from the skill list reaches selector 9 of the class-0x50 object (§2.1, path MED).
2. `1a09 @0054` R0EA1(leader, 1, 2): A30 ≠ 0; no property 68; `2 > 10` false → magic = 10 − 2 =
   **8**; C = R0EAC(leader, 195) = 2; busy = 0 + (10 + 2·1) = **12**; roll:
   `(random(0,2) + random(0,2)) < random(0,1)` → right side `0 + (r mod 1)` = 0 → never true →
   return True.
3. G13 True (leader) → "Cast 'Lesser Healing' on whom?"; `return 32772` (0x8004).
4. `PostUse` → `NeedsTarget(spell, 0x8004)`. The click on the party member passes: bit 4 (has an
   active monster) and bit 0x8000 (party bit 0x40 sets `local_6c = 1`, so no adjacency or walk).
   `UseOnCommand(spell, prop)` → selector 10 with A31 = prop index | 0x40000000.
5. `1a09 @008E` `show_magic(G09, 240)`, `positional_sound(46, …)`; `@00A9` health =
   `(20 + 5) + random(1, 5)` = 25 + (1…4) = **26…29**; `SetField case 0x1c` would clamp at 30.
6. Cost already paid at step 2: cancelling the target in step 4 still leaves magic 8, busy 12.
Same cast from a scroll: R0EA1(0, 1, 2) adds 6 to character 0's busy, no magic, no roll; the scroll
is deleted after the `use_on` (`104B @00E4`).

---------------------------------------------------------------------------------------------
## 10. Open items
1. The native path from the character skill list / task event 4 to `DoInterp(9, …)` for a spell
   (who is G09 then; is prop 0 used as a scratch class-0x50 object as in `RedoDoPopUps`?).
2. `teleport(1, 1, 0)` (Directed Nexus) — the 3-argument form's meaning (rules §2 banks only −1).
3. `show_magic` codes 240/244, sound ids 44–48 — visuals not read.
4. Rune kind bit 2: "undiscovered" (scripts) vs "blocker" (data-format §4.3). Warding's message
   gate `quality == 32` (char 32?) unexplained.
5. Fetch's kind 9 with a character parent — does the item show in the inventory?
6. Ability 28's setter (only via a ring's byte 7?); ability 19 (Cursed) has no literal setter.
7. Spells 03/04 learnability (no property 51); hintbook not checked for the spell list.
8. Whether any 0x5000|n / 0x4000|n FX entries exist at run time (no literal in scripts; maybe
   from saved games or native code — `ReadFXQueue` only).
9. `Ctor` result of `as_char(spell)` (Resist Blows text test).
10. Mystic Arrow / Fireball's stale 8th `missile_burst` argument — which slot it reads.

---------------------------------------------------------------------------------------------
## 11. Missile and spell FX classes ⚑ wave 2 (2026-10-06)
Reader R1, census group G (13 bodies of `ghidra/Cythera_missing.decompiled.c`, list in
ui-play.md §0). Visual only: none of these bodies changes CharEntry or prop state except the
hit table of §11.2. `m:NNNN` = line of the missing dump. Vtables decoded with `toc.data_u32` +
`tb.py --at` (recipe ui-play.md §0).

### 11.1 Shape [HIGH]
- A missile is a `TBres` line walker (vtable slot +8 = `DoBresPixel(long)`, called once per
  pixel) with a `TTileShower` sub-object at +0xC (its vtable slot +8 = `Show(char*)`). Vtables:
  thrower 0x100D5F18 / shower 0x100D5F24, spinner 0x100D5EDC / 0x100D5EE8, stream 0x100D5E88 /
  0x100D5E94, plain `TBres` 0x100D640C, `TLineEffect` 0x100D76BC, `TStraightBres` 0x100D6058. The
  stream's shower slot +8 is the thunk `10061a90: addi r3,r3,-12 ; b 0x1005ef84` (→
  `TMissileStream::Show`).
- Built by `DoMissile__11TGameViewerFsssssssss @ 1005f234` (main dump, context) from builtin E2
  `cbMissileFX` (script-builtins.md): style = `flags & 7` — **0 thrower** (one rotated tile, sound
  tracker), **1 spinner** (8 rotations of the tile, `RotateTile` ×8), **2 stream**. The walk runs over
  pixel coordinates (cell × 32) clipped to the view; while it runs `viewer +0x20C44` points at the
  shower sub-object, and is 0 again afterwards.

### 11.2 Per-pixel callbacks [HIGH]
| body | every pixel | every Nth pixel |
|---|---|---|
| `TMissileThrower::DoBresPixel @ 1005ead0` | sound tracker follows the cell `pos / 32` (`MoveTo__13TSoundTrackerFss`) | N = 16 (static counter `PTR_DAT_100cea5c`, `… % 16`): store `pos` in shower +0xC and `DrawRoutine__11TGameViewerFs(viewer, 2)` |
| `TMissileSpinner::DoBresPixel @ 1005ecc8` | as thrower | N = 16: as thrower, plus frame `+0x20 = (+0x20 + 1) mod +0x22` and image `+0x14 = frames[+0x24][frame]` |
| `TMissileStream::DoBresPixel @ 1005eea4` | — | N = 12 (`PTR_DAT_100cea4c`, `/ 0xc`): `MaskAMissile(viewer, image, pos)` — stamped into the view buffer, no redraw, no sound |
| `TBres::DoBresPixel @ 10074a54` | `return 1` (continue) | — |
| `TStraightBres::DoBresPixel @ 1006bdbc` | stage cell *i* (8-byte cells): `if ((*(uint *)(*(int *)(param_1 + 0xc) + param_2 * 8) & 4) != 0) { **(undefined1 **)(param_1 + 0x10) = 0; return 0; }` — tile flag 4 stops the walk and clears the result | — |
| `TLineEffect::DoBresPixel @ 1009930c` | cell within ±15 of the view centre → `GetBestProp(x·4, y·4)`; if that prop is an active monster's, `PTR_DAT_100cee00[charIndex] = 1` (m:19361–19368); always continues | — |

All return 1 except the blocked `TStraightBres` case; **no body waits on the clock**
(no `TickCount`/`Delay` in any of them) — a thrown or spinning missile advances one redraw per 16
px (half a cell), at whatever speed `DrawRoutine(…, 2)` runs.
- `Show` bodies: `TTileShower::Show @ 1005e9a0` → `MaskAMissile(viewer +4, image +8, pos +0xC)`;
  `TMissileStream::Show @ 1005ef84` → `DrawBres` again with the stored line (+0x18…+0x30), i.e. the
  whole trail is re-stamped every frame; `TCircleShower::Show @ 1005f8cc` → `ShowCircle`;
  `TBurstShower::Show @ 1005f920` → `ShowCircle` at radii `r & 1, (r & 1) + 2, …, r` (`for (uVar2 =
  uVar1 & 1; (short)uVar2 <= *(short *)(param_1 + 8); uVar2 = uVar2 + 2)`), then restores `r` —
  concentric rings.
- **Hit table** `PTR_DAT_100cee00` (0x200 bytes, one per CharEntry): E2 clears it, then — unless
  `flags & 8` — walks a `TLineEffect` from (x0,y0) to (x1,y1) (cell steps, `0x10000`) and clears the
  caster's own byte (`puVar3[*(short *)puVar1] = 0;`, builtins dump); builtin CF `cbAreaOfEffect`
  iterates the set bytes (script-builtins.md). So **a line missile marks every creature on the
  cells it crosses**, not only the target.
- `TStraightBres` is the straight-line test: `IsStraightRel__7TViewerFss @ 1006b904` (target within
  `±viewer+2` and its view-cell byte at +0xC0C8 `& 3` non-zero, then the walk from the stage centre
  +0x150EC with row stride 0x1F cells) and `IsStraightAbs__7TViewerFssss @ 1006bafc` (both ends in
  view, walk from the source cell). Its users: target bit 0x4000 (§2.3) and throws (ui-play.md §5.2).

### 11.3 `TGameViewer::RenderMissiles @ 1005e4f8` and draw order — INDEX 16 (narrowed) [HIGH]
- Body: if `viewer +0x20C44` is set → its slot +8 `Show(viewer +0xB0)` (`ppcdis.py --func
  RenderMissiles__11TGameViewer`: `lwz r12,8(r12)`), and if the monster being ticked
  (`*PTR_DAT_100cdd98 + 8`) is not the leader → `PTR_DAT_100cdc40[leader] = 1` (the array of
  schedules-npcs.md §4.3); then `PostProcessSounds`, `ResetAmbient`, every ambient entry (count
  `+0x1DC14`, 8 bytes from `+0x1D814`: dx, dy, sound, flag) → `Ambient(sound, dx, dy)` (flag 0) or
  `PlayAmbientSound(sound, dx, dy, 0)`, then `CalcAmbient` — despite its name it is also the
  per-frame ambient-sound placement. `TViewer::RenderMissiles @ 100693b0` is empty.
- **Where it runs**: slot +0x10 of the `TGameViewer` vtable (0x100D5F64 + 0x10 →
  `RenderMissiles__11TGameViewerFv`), called once, from `Render__7TViewerFssss @ 10066ac0` inside
  its pass loop: `100676ec: lha r13,162(r1)` / `cmpwi r13,5` / `bne` / `lwz r12,16(r12)` / `bl
  0x100c50e8`, loop end `10068788: cmpwi r13,6 ; blt 0x100676ec` (pass counter at 162(r1) from 0).
  The tile copies (`CopyTile`, `CopyCompoTile`, `MaskAnyTile(…ll)`) come before the loop
  (10067054–10067654) and twelve `MaskAnyTile(…lls)` prop draws inside it. So: **ground tiles →
  passes 0–4 → in-flight FX → pass 5**; whatever pass 5 draws covers a missile. What each pass
  holds (the priority mapping of engine-classes §5) is still NOT RESOLVED. [HIGH for the call site
  and loop bounds; MED for "pass 5 draws props"]
- `TGameViewer` dtor @ 10061a04 resets the sub-object vtable at +0x10 and calls `TViewer`'s dtor.
