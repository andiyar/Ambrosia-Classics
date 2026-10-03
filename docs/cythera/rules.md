# Cythera 1.0.4 — rules readable from native code

Register: **code reading only**. Headline finding: Cythera's rules are mostly **scenario
bytecode**, not native code. Native code owns movement, schedules, regeneration/poison ticks,
alignment relations, encumbrance and the command plumbing; combat resolution, spells, trade and
conversation content are sent to scripts (`script-vm.md`) whose builtins (opcodes ≥ 0xA0) are in
an undisassembled code block. Rows marked NOT RESOLVED are expected.
⚑ corrected (review 2026-10-03): the builtin table is now resolved and decompiled — `script-builtins.md` (inventory,
party, abilities, flags/vars, teleport, time, sound, effects, iterators). None of the 95 builtins
computes to-hit/damage, so combat arithmetic stays in script bytecode.

---------------------------------------------------------------------------------------------
## 1. Combat

| rule | reading | evidence | conf |
|---|---|---|---|
| Attack command | `AttackCommand__8TGameSysFs @ 10055288`: refuses target 0 ("There is nothing to attack") and self ("It isn't worth killing yourself"); if the target has an active monster, sets its status bit 3 (`|= 8`, **IsAngry**) and sends selector **28** to the *attacker's* character script with the target; the integer result is the time cost passed to `HeartBeat`; a non-integer result prints "It is too far away to attack" (or "nothing to attack" for props) | code | HIGH |
| Monster attacks | `TActiveMonster::DoAttack @ 10047e6c`: with a target, sends selector 28 (self, target); integer result → busy ticks (CharEntry +0x12); otherwise busy 8 and `GoTowards(target)`; with no target, party members set activity 1/2, others `DoRoam` | code | HIGH |
| To-hit, damage, armour, criticals, experience award | inside the selector-28 script / builtins | — | **NOT RESOLVED** |
| Alignment relations | `GetEnemyStatus__14TActiveMonster @ 100487d8`: table of 16 u32 at data address 0x100D55D4 (copied to the stack each call; values read from the unpacked data section with `tools/pef.py`) indexed `[attacker.align*4 + target.align]` (align = CharEntry +0x19: 0 neutral, 1 evil, 2 good, 3 feral). Result 0 = enemy, 1 = ally, 2 = bystander. Rows: neutral → all 2; evil → {2,1,0,0}; good → {2,0,1,0}; feral → {2,0,0,2}. If global byte `PTR_DAT_100cde4c` ≠ 0 everything is ally (1). | code + data | HIGH (table) / NOT RESOLVED (what sets the override byte) |
| Health categories | `HealthIs/AtLeast/LessThan` (AI): cat = cur·5/max (0..5), Dead..Complete; character window: "Critical" if cur ≤ max/4, "Wounded" if ≤ max/2, "Hurt"…, "Fine" (the ladder in `DrawStatPart__16TCharacterWindow`). ⚑ corrected (review 2026-10-03): **"Hurt" is unreachable** — `DrawStatPart @ 1002caa4` tests `max>>1 < cur` twice in a row (disasm 0x1002CC9C `srawi r0,r4,1; bgt` then 0x1002CCD8 `srawi r0,r0,1; bgt`), so the inner else selecting "Hurt" (TOC 100ce654) never runs. Ladder as shipped: Dead / Poisoned / Paralyzed / Confused / Afraid / Charmed, then Critical (cur ≤ max/4), Wounded (cur ≤ max/2), else Fine (or Hungry) | code + disasm | HIGH |
| Death | `CharEntry::DeathRites @ 1004fc50`: HP := 0; if no active monster, sends selector **29** (death) to the character; if the script leaves HP at 0 → clear alive bit, drop from party (`RebuildParty`); if the script revived it → remove stacked abilities 0xD, 0xE, 0x16, 0x15 and keep alive | code | HIGH |
| Combat AI | pointer row → ai-scripts.md | — | n/a (pointer; ⚑ corrected (review 2026-10-03): label added) |

## 2. Movement, party, levels

| rule | reading | evidence | conf |
|---|---|---|---|
| Step directions | `MoveCommand__8TGameSys @ 10050460`: directions 0..7 = N, NE, E, SE, S, SW, W, NW (dx,dy: 0 → (0,−1), 1 → (+1,−1), 2 → (+1,0), 3 → (+1,+1), 4 → (0,+1), 5 → (−1,+1), 6 → (−1,0), 7 → (−1,−1)); facing 0..3 = N,E,S,W | code | HIGH |
| Blocked orthogonal step | if `CanPMove` fails and preference bit `bRam100d3e21 & 0x40` is set, tries the two 45°-rotated diagonals (`CanMove(−dy,dx)` & `CanMove(dx−dy,dx+dy)`, else the mirror) — "wall sliding" | code | HIGH (preference meaning MED) |
| Diagonal step | needs `CanMove(dx,dy)`, `CanMove(dx,0)` **and** `CanMove(0,dy)`; otherwise falls back to the single axis that is free | code | HIGH |
| Push-through objects | `CanPMove__Fssssl @ 10050fa0`: if the cell is blocked by a prop with type flag 0x40 standing exactly there, send it selector 9 (use/step); if that changed its frame and its tile flags, re-test | code | HIGH |
| Time cost | success: leader busy = 10, fail: 4; then `HeartBeat(1)` | code | HIGH (see engine-classes §3.2 for clock coupling, MED) |
| Party follow | in "party mode 2" (`PTR_DAT_100cdbe8 == 2`) all party members are snapped to the leader's cell each step (CharEntry and prop) | code | MED (mode naming) |
| Map edges / auto-use on step | ⚑ corrected (review 2026-10-03): an **auto-use rule**, not merely a suppression. `MoveCommand @ 10050460` lines 788–887: on **every** successful step, if `GetBestPropRel(0,0)` yields a prop whose type flag 0x1000000 is set and `GetProperty(0x3A) & 2 == 0`, the code calls **`DoUse(prop)`** (auto-use on stepping, e.g. stairs/teleport pads) and the edge test is skipped; otherwise the edge test runs: stepping onto row/column 0 or ≥ W/H triggers the header exit teleports (data-format.md §3.1, incl. the half-edge fallback) | code | HIGH |
| Teleport | `TeleportTo(-1, index, follower)`: location from 0xF00C[index], arrival byte from 0xF00F[index] (→ viewer +0x20C28), then redraw, clear targeting, `HeartBeat(0)` | code | HIGH |
| `MovePartyBetweenLevels(from, to, x, y)` @ 10007e78 | for every alive (`+6&1`) **party** (`+8&0x40`) character currently on level `from`: prop kind := 0x42, location := (to, x, y), type/frame copied to the prop, prop bytes 6–7 cleared; party members on other levels have their prop freed (0xFF) | code | HIGH |
| `CueCharacters(level)` @ 10008058 | for every alive character: if on `level`, (re)place its prop (kind 0x42, location, type/frame); else free its prop | code | HIGH |
| `RebuildParty` @ 10008194 | party = first ≤ 8 characters with `+8 & 0x40`, in index order; any of them whose prop is still an unhatched 'B' egg gets activity 2 (if it is the leader) or 1 and is hatched; rebuilds the "party" menu (MENU 200 items 3..10) | code | HIGH |
| Encumbrance | inventory limit Body×20, equipped Body×10; weights per type (data-format.md §4.4) | code | HIGH; what exceeding does is NOT RESOLVED |

## 3. Schedules (`ScheduleTime`, `ScheduleOne`, `EvalCondition`, `RepositionChar`)

### 3.1 When [HIGH]
`ScheduleTime(hour, force)` runs at every hour change, on new game, and on big time jumps (> 100
units) — `DoTicks`. It visits characters 0..255 with `+6 & 1` (alive), not in the party (`+8 &
0x40` clear), activity ≠ 'p' (0x70), and not currently fighting (no active monster or monster
`+0x1C` target == 0), and calls `ScheduleOne(char, hour, force)`.

### 3.2 Choosing the entry (`ScheduleOne__FssUc @ 10006a28`) [HIGH — every branch read]
```
entries = schedule[char]      # 8-byte entries, see data-format.md §6.3
if count == 0: return
if count == 1: pick = entries[0]                    # unconditional, any hour
else:
  best = none
  for e in entries (in order), stopping when e.cond == 1 and best != none:
     ok = EvalCondition(e.cond, e.arg)
     if ok and e.loc != 0:
         if best == none or e.hour <= hour: best = e
         elif hour < best.hour: best = e            # wrap-around: before the first entry → latest
     if not ok and e.loc == 0 and e.cond != 1:       # failed block header: skip its block
         depth = 1; skip entries: cond==1 → depth−1, loc==0 → depth+1, until depth 0
  pick = best
if pick: RepositionChar(char, prop[char], pick.loc, pick.activity, force)
```
Cond 1 ("false") doubles as **end-of-block marker**: once something has been chosen, reaching a
marker ends the scan — so `cond-entry … 01-marker` reads "if cond holds, this entry applies all
day". Character 2's data (data-format.md §6.3) is exactly that pattern on global flag 0.

### 3.3 `EvalCondition(cond, arg)` @ 10006194 [HIGH]
| cond | true when |
|---|---|
| 0x00 | always |
| 0x01 | never (end marker) |
| 0x02 / 0x03 | global flag `arg` (0..255, bitfield `PTR_DAT_100cdbc0`, 8 u32 saved in 'Char') is set / clear |
| 0x20–0x3F | random: r = Random() & (2^(n+1) − 1), n = cond & 7 (n = 0 → r = 0); compare by cond & 0x38: 0x20 r == arg, 0x28 r ≥ arg, 0x30 r ≠ arg, 0x38 r < arg |
| 0x40–0x5F | CharEntry[`arg`] condition bit b = cond & 0x1F (b < 8 → byte +8 bit b; else u16 +6 bit b−8) is set |
| 0x60–0x7F | same bit is clear |
| 0x80–0x9F | byte variable v = `PTR_DAT_100cdbbc[cond & 0x1F]` (32 vars, saved in 'Char') == arg |
| 0xA0–0xBF | v ≥ arg |
| 0xC0–0xDF | v ≠ arg |
| 0xE0–0xFF | v < arg |
Note the byte-variable index is `cond & 0x1F` regardless of the comparison group.

### 3.4 Moving the character (`RepositionChar @ 100064a0`) [HIGH as code, MED as behaviour]
Let *old visible* = old location on the leader's level and on-screen (`IsVisibleAbs`), *new
visible* likewise (both forced false if the prop's bit 31 is set).
- `force` set: snap: prop location := new; prop freed (0xFF) if neither monster nor new-visible.
- neither visible: snap silently (kill the active monster), prop kind 0x42 if the new location is
  on the current level else 0xFF.
- new visible, old not, no active monster: compute the furthest reachable point toward the new
  location (`TPathFinder::FurthestPoint`), place the prop there, add to hood, `HatchEgg`, set the
  monster's waypoint to the destination (walks in from off-screen).
- old visible (monster exists): keep position, set waypoint (walks there); activity → 0x80
  ("walking") with the target activity stored in prop byte 7.

## 4. Status effects and regeneration (native) [HIGH unless marked]
From `DoTicks` (engine-classes.md §3.1) and the status ladder:
- Status word +6 bits = the 16 `ObjectFlags` of the AI language: 0 IsAlive, 1 IsPoisoned, 2
  IsEnhorsed, 3 IsAngry, 4 IsRegen, 5 IsFear, 6 IsParalyse, 7 IsInvisible, 8 IsXray, 9 IsCharmed,
  10 IsNightVision, 11 IsCursed, 12 IsBlessed, 13 IsConfused, 14 IsSleep, 15 IsLavaProof
  (`TestFlag` = bit n−1; cross-checked: window strings Poisoned=0x2, Afraid=0x20, Paralyzed=0x40,
  Charmed=0x200, Confused=0x2000; Talk refuses when 0x4000 "They are asleep"; Attack sets 0x8).
- Poison: per 1/10 hour crossing, −1 HP; at HP < 2 → `DeathRites`. IsRegen (0x10) without poison:
  +1 HP per crossing up to max; with both, a coin flip each crossing (`Random() & 1`).
- Natural regeneration needs food (+0x1B ≠ 0): +1 HP and +1 Magic per crossing of rate
  `min(Level>>1, 4)` (1 h, ½ h, ⅓ h, ¼ h, ⅕ h). Food −1 per hour.
- "Hungry" status shown when ability 0x7000 is present on a party member (`HasAbility`). [MED]
- Spell/ability durations: `TSpellFX::PassTime(units)` each `DoTicks` — internals NOT RESOLVED.

## 5. Conversation [MED overall]
- `TalkCommand__8TGameSysFs @ 100524b0`: prints "> Talk to <name>"; refuses sleepers (activity
  0x91 or IsSleep); opens the talk UI (`BeginTalking`, both portraits), sends selector **12** to
  the character (VAddr class 0x40) or, for non-characters, to the prop (class 0); closes; clears
  IsAngry on the partner's monster; `HeartBeat(1)`. [HIGH]
- `CanTalk`: characters < 0x100 always; other props need script property 0x1E == 2. [HIGH]
- The dialogue itself is **bytecode**: text literals, `0x8E` read input, `0x8F` prompt, `0x90`
  keyword lists with `*` wildcard (script-vm.md §4). Default topic words in `Cythera Data.rsrc
  STR# 128`: Bye, Name, Job, Where Is…. Keyword answers learnt during play are kept by
  `TConversation::AddAnswer/FindAnswer`; `ScanForHints` marks hint words. [MED]
- Where the text is: in the encrypted character segments 0x18xx (decrypting 0x1802 shows the
  narration "Before you stands an older, dignified gentleman…"). [HIGH]
- Journal: `TJournal::SaidToJournal/AddToJournal/MakeEntry` append to 0xE000+ pages. [MED]

## 6. Magic, alchemy, skills, trading
| topic | reading | conf |
|---|---|---|
| Spells | `CastSpell(@,#)` and `HasSpell(#)` are script routines 0x0981 / 0x0901; abilities live in `TSpellFX` (`HasAbility`, `RemoveStackedAbility`, FX queue saved in the 'Char' stream); the "Spells" source module's internals are not read | NOT RESOLVED |
| Skills | a skill is a prop of kind 0x1C parented to the character, type = skill id (`FindSkill__Fss`); "Training" points at CharEntry +0x1C; `AdjustSkillControls` checks property 9 | MED |
| Alchemy | strings in decrypted 0x0Exx segments ("You added water to the …") show it is scripted | LOW |
| Trading / shops | no native trade code found (no `Buy`/`Sell` symbols); the 1.0.3 notes mention buying counted objects — scripted | NOT RESOLVED |
| Item use | `UseCommand/DoUse` send selector 9, `UseOnCommand` selector 10; take/drop/wield selectors 13–17, 24–27 | HIGH (ids) |
