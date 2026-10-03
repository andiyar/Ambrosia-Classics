# Cythera 1.0.4 — script-VM builtin opcodes 0xA0–0xFE

Register: **code reading only** (decompiled bodies; nothing behaviour-verified). Written by the
review fix pass of 2026-10-03; closes INDEX NOT RESOLVED 11.

## 0. Provenance and recipe
- Table: DoExpr disasm 0x100806d0 `addi r8,r2,0x1ff0; lwzx r12,r8,(op−0xA0)*4; bl 0x100c50e8` →
  96 TVector pointers at **TOC + 0x1FF0 = 0x100D7270** (r2 = 0x100D5280). Each TVector's first word
  is the code address. Re-derived independently from the unpacked data section (`tools/pef.py`):
  table words are section-relative (0xA0 → 0x3348 → TVector 0x100D05C8 → code 0x10083CA8; …) and
  match the review's list for all 96 entries; **0xFF is null**. [HIGH]
- Decompile: copy the analysed project, then
  ```sh
  cp -R <ghidra-proj>/Cythera_pef.{gpr,rep} <scratch>/cythera-fix-proj/
  analyzeHeadless <scratch>/cythera-fix-proj Cythera_pef -process Cythera_pef -noanalysis \
    -scriptPath docs/cythera/tools -postScript CyDecompBuiltins.java \
    $PWD/ghidra/Cythera_builtins.decompiled.c
  ```
  `tools/CyDecompBuiltins.java` reads the table from program memory, creates `Builtin_XX` functions
  at the 95 entries, pins r2 = TOC over their bodies and decompiles them. Log: "CyDecompBuiltins:
  wrote **95/95**"; output 3,294 lines (`wc -l`), git-ignored under `ghidra/`.
- Calling convention (script-vm.md §6): `builtin(VAddr *result, VAddr *a)`; `a[0..]` are the
  arguments pushed by one RPN expression; the stack top is reset to `a` afterwards; expressions push
  `*result`, statements drop it. **No argument count is passed** — each builtin reads a fixed set.
- Notation: `int(x)` = the 28-bit integer of a tag-0 VAddr (`(v<<4|v>>28)>>4`, the code untags
  without checking the tag unless stated); `char(n)` = tag-4 class-0x40 object `0x4040_0000|n`;
  `prop(n)` = class-0 object `0x4000_0000|n`; **item** = `type | frame<<10` (the PropItem u16 @4
  fields); Nil/True/False = 0x5000FFFF/0x50000001/0x50000000 (`PTR_DAT_100cdbb0/cddec/cde70`).
- Globals used below (named from `LoadGlobals`/`RebuildParty`/`CreateGlobals`): `cdc44` props
  array, `cdc3c` prop count (high-water), `cdbf0` CharEntry[], `cdbec` party leader index, `cdbe4`
  party list (u16), `cdb9c` party size, `cdbe8` party mode, `cdbb8` → TGameViewer, `cdb98` →
  TStatusWindow, `cdcc8` → current TConversation (0 when not talking), `cdcd0` → TGameSys, `cdd24`
  → TAudio, `cdcdc` → TMapWindow, `cdbc0` 256 global flags (EvalCondition 2/3), `cdbbc` 32 byte
  variables (EvalCondition 0x80–0xFF).
- Labels: **HIGH** = whole body read and every callee is a named function (or the effect is plain
  arithmetic/stores); **MED** = body read but a callee is unnamed glue, or an argument's meaning is
  inferred; **LOW** = meaning from names only.

## 1. Iterator protocol (0xA0, 0xA1, 0xC7–0xD1)
Fourteen builtins share one shape: `a[0]` is a **tag-1 stack-slot VAddr** of a 2-word state block
(`VAddrToPtr`), `a[1]` the mode: **0 = init** (extra args follow) → first element (Nil if none);
**1 = done?** → True/False; **2 = next** → next element (Nil at end); any other mode → Nil. Element
scans over props run to the prop count `cdc3c`; over characters to 0x1FF. The compiled `for`
loop that drives them was not traced (how scripts order modes 0/1/2 is inferred from the shape).
[HIGH per body; loop shape MED]

## 2. Table
| op | code | name (ours) | args → result | reading | conf |
|---|---|---|---|---|---|
| A0 | 10083CA8 | iterate range | (slot, mode, start, end) | init: state = {start, end}, returns start; done: cur ≥ end; next: ++cur, returns it (no bound check) | HIGH |
| A1 | 10083DB0 | iterate list | (slot, mode, list) | init: state = {Nil, 0}; an integer `list` is returned as-is (state stays Nil ⇒ done at once); `Len == 0` → Nil; else state = {list, 0}, returns `At(list,0)`; done: state[0] == Nil; next: ++idx, idx ≥ Len → state[0] = Nil, Nil; else `At(list, idx)` | HIGH |
| A2 | 10093F90 | end game | (string) | `GammaFadeOut(200)`, hide cursor, black full-screen `NewCWindow`, string centred in colour 0x1E, `GammaFadeIn(300)`, wait 600 ticks or a click, fade out, clear conversation, two unnamed glue calls, `ExitToShell` | HIGH (glue calls unnamed) |
| A3 | 100941F4 | add leader busy | (n) → Nil | CharEntry[leader] +0x12 (busy byte) += n | HIGH |
| A4 | 10094258 | show portrait | (a, b) → Nil | `TConversation::ShowPortrait(conv, a, b)` | HIGH call / MED args |
| A5 | 1009430C | set tile animation | (tile, first, frames) → Nil | for f in 0..7: `tilePix[f][tile & 0x9FF] = pixBase + ((first + ((frames−1) & f)) & 0x9FF)·0x400` — the same tables `LoadGlobals` builds from 0xF001 (`cdc28`, base `cdc64`) | HIGH |
| A6 | 100943FC | show tile animate | (n) → Nil | n < 2: virtual call (vtable +0x40) on the status window (unnamed); else watch cursor + `TMapWindow::ShowTileAnimate(map, n)` | MED |
| A7 | 10094678 | delete prop | (prop) → Nil | parent = `GetPropParent`; `DeleteProp` (recursive); `TInventoryWindow::Invalidate(parent, 2)` | HIGH |
| A8 | 10094730 | give item | (char, item, quality, count) → prop / Nil | `NewProp`; kind 0x10 (inventory), parent = char, type/frame = item, byte 6 = quality, byte 7 = 0, `SetItemCount(count)`; if count < 2 or the type stacks (`GetItemCount` > 1) → `ConjoinProp` (merge into an existing stack), else **count−1 further copies** of the record are created; invalidates the char's inventory; returns `prop(new)` (Nil if `NewProp` < 1) | HIGH |
| A9 | 10094954 | map cell | (x, y) → int | current level's map cell u16 at `x + y·W` (`cdc5c`, W/H from viewer +0x20C1C/+0x20C1E); out of bounds → 0xFF | HIGH |
| AA | 1009491C | (stub) | → Nil | returns Nil | HIGH |
| AB | 10094A24 | transfer item | (item, quality, fromChar, toChar) → Nil | first prop ≥ 0x100 with type/frame = item, `GetItemQuality` = quality and `GetPropUltimateParent` = fromChar: kind := 0x10, parent := toChar (the whole stack moves; no count); invalidates both inventories | HIGH |
| AC | 10094BBC | random | (lo, hi) → int | lo < hi: `lo + Random() mod (hi−lo)` (unsigned mod of the signed 16-bit `Random()`); else lo | HIGH |
| AD | 10094C80 | create prop | (kind, x, y, frame, type, byte6, count) → prop | `NewProp`; byte 0 = kind, location = x<<12 \| y, frame, type, byte 6, byte 7 = 0, `SetItemCount`; viewer +0xC := 1; invalidates the parent's inventory (flags 0x202 for kind 0x1C skills, else 2); returns `0x4000_0000 \| index` **even when `NewProp` failed** (index 0xFFFF) | HIGH |
| AE | 10094E44 | who in party has | (item, quality or 0) → char / Nil | first prop ≥ 0x100 of that type/frame (and byte 6 = quality unless 0) whose ultimate parent (< 0x100) has the party bit (CharEntry +8 & 0x40) → `char(owner)` | HIGH |
| AF | 10094FB4 | find item | (char, item, quality) → prop / Nil | first prop ≥ 0x100 with type/frame = item, byte 6 = quality, ultimate parent = char (parents > 0xFF read as 0) | HIGH |
| B0 | 10095118 | count items | (char, item) → int | Σ `GetItemCount` over props of that type/frame ultimately held by char (any quality) | HIGH |
| B1 | 10095244 | remove items | (char, item, quality, count; 0 → 1) → Nil | walks matching props (type/frame, quality, ultimate parent): stack > remaining → reduce count, done; else subtract its count and `DeleteProp`; invalidates the char's inventory | HIGH |
| B2 | 1009541C | party member | (n, mode) → char / Nil | mode 1: `char(party[n])` unchecked; else the n-th **alive** (CharEntry +6 & 1) party member | HIGH |
| B3 | 10095544 | who will (built-in prompt) | (includeDead) → char / Nil | `TInteraction::WhoWill(s_Who_Will…, flag & 0xFF)`: candidates = party members (alive only unless flag); 0 → Nil, 1 → that one, else a selection dialog (or the conversation's) | HIGH |
| B4 | 100955FC | how many | (prompt or Nil, a, b) → int | `TInteraction::HowMany(prompt, a, b)` — ⚑ corrected (wave 1 2026-10-03): a = minimum, b = maximum, slider starts at b (§4, dialogue.md §7.1) | HIGH |
| B5 | 100956B4 | ask digit | () → int | unnamed glue on the conversation with "0123456789" (single-key choice), echoes it with `TConversation::myprintf`, returns key − '0' | MED |
| B6 | 10095770 | (stub) | → Nil | returns Nil | HIGH |
| B7 | 100957A8 | free capacity | (char) → int | `GetMaxInvEncumb − GetCurInvEncumb`, floored at 0 | HIGH |
| B8 | 10095868 | weight if added | (x, count) → int | `GetCurInvEncumb(x) + GetObjectWeight(x & 0x3FF, x >> 10, count)` — the **same argument** is used as character index and as item — raw disasm 0x10095880–0x100958c4: r31 = int(a[0]) is passed to `bl 0x10055a58` (GetCurInvEncumb) and, as `rlwinm r3,r31,0,22,31` / `srawi r0,r0,0xa`, to `bl 0x100554e4` (GetObjectWeight). Reads like an original bug; replicate literally | HIGH |
| B9 | 10095918 | join party | (char) → int | party mode 2 → 1; party size 8 → 2; else CharEntry +8 \|= 0x40, `RebuildParty`, status `Rebuild`, `TActiveMonster::JoinParty`; → 0 | HIGH |
| BA | 10095A10 | leave party | (char) → int | party mode 2 → 1; else clear +8 bit 0x40, `RebuildParty`, `Rebuild`, `LeaveParty`; → 0 | HIGH |
| BB | 10095AF0 | who will (prompt) | (string) → char / Nil | `WhoWill(string, 0)` — alive members only | HIGH |
| BC | 10095BC0 | leader can see | (obj or int) → True/False/Nil | characters (class-0x40 object, or integer < 0x100): same level as the leader (location byte 3), \|dx\|,\|dy\| ≤ viewer +2, viewer visibility grid (+0xC0C8, row width viewer +4) `& 3` ≠ 0, and not asleep (activity ≠ 0x91, status bit 0x4000 clear) → True; props (class-0 object, or integer ≥ 0x100): window/visibility test only; other values → Nil | HIGH code / MED grid meaning |
| BD | 10096058 | pass time | (n) → Nil | `TGameViewer::DoTicks(n, 0)`, `DoTicks(0, 1)`, `DrawRoutine(1)` | HIGH |
| BE | 100991B8 | refresh light | () → Nil | `TStatusWindow::RecalcPartyLight`, `DoTicks(0, 0)` | HIGH |
| BF | 10098E60 | teleport | (a, b, c) → Nil | `TGameSys::TeleportTo(a, b, c)` verbatim (rules.md §2: −1 = teleport-table index form) | HIGH |
| C0 | 10096798 | pick item | (prompt or Nil, title or Nil, items ≤ 20, strings) → int | builds a `vector<TPickItemDrawer*>` from list `a[2]` and a C-string array from list `a[3]`, `TInteraction::PickItem` → chosen index | MED |
| C1 | 10096DEC | add ability | (who, ability) → Nil | `TSpellFX::AddAbility(a, b)` | HIGH call |
| C2 | 10096E80 | remove ability | (who, ability) → Nil | `TSpellFX::RemoveAbility(a, b)` | HIGH call |
| C3 | 10096F14 | temp ability | (who, ability, duration u16) → Nil | `TSpellFX::TempAbility(a, b, c & 0xFFFF)` | HIGH call |
| C4 | 10096FB8 | has ability | (who, ability) → int / True / Nil | `HasAbility`: 0 → Nil; ≥ 0xF000 → True; else the value | HIGH |
| C5 | 10098418 | send signal | (n) → Nil | `TGameSys::SendSignal(n)` (selector 21 broadcast, script-vm.md §2.3) | HIGH |
| C6 | 100984A0 | short name | (obj) → Nil | `TGameSys::ShortName(low16(a0))` | MED (ShortName not read) |
| C7 | 10097080 | iterate all props | (slot, mode) | init: state = {0, count}, returns **`prop(0x100)`**; next: ++cur → `prop(cur)`; done: cur ≥ count. Raw disasm 0x100970d0–0x10097114 (`li r0,0` → state[0]; `lis r3,0x4000; addi r3,r3,0x100`) confirms: the sequence is 0x100, 1, 2, … — an original quirk, recorded literally | HIGH |
| C8 | 100971E0 | iterate children | (slot, mode, parent) | props from 0x100 whose `GetPropParent` == parent; a class-0x40 parent is first replaced by its active monster's +8 word (its body prop) — no monster → empty | HIGH (monster +8 meaning MED) |
| C9 | 100973BC | iterate descendants | (slot, mode, parent) | as C8 but any ancestor (parent chain) == parent | HIGH |
| CA | 100975B8 | iterate party | (slot, mode) | `char(party[i])` for i < party size | HIGH |
| CB | 100976FC | iterate props at | (slot, mode, x, y) | props from **1** with `kind & 0x1A == 0` (on-map kinds) at exactly (x, y) | HIGH |
| CC | 10097CE8 | iterate equipped | (slot, mode, char) | as C8 restricted to kind 0x18 (equipped) | HIGH |
| CD | 10097B58 | iterate props of type | (slot, mode, type) | props from 0x100 with `u16@4 & 0x3FF == a[2]` (compared with the raw VAddr — integers only) | HIGH |
| CE | 10098028 | iterate enemies of | (slot, mode, char) | characters 1..0x1FF with an active monster and `GetEnemyStatus(monster(char), it) == 0` → `char(i)`; ends when the source has no monster | HIGH |
| CF | 10097EDC | iterate last-burst victims | (slot, mode) | characters 0..0x1FF whose byte in table `cee00` is non-zero — the table builtin 0xE2 fills | HIGH |
| D0 | 10098204 | iterate same-group | (slot, mode, who) | props whose `TActiveMonster::GetCharacter` exists and whose monster word 0 equals `who`'s monster word 0 | MED (word 0 meaning LOW) |
| D1 | 100978F0 | iterate props near | (slot, mode, x, y, r) | props from 1, kind `& 0x1A == 0` or kind 2, with dx² + dy² ≤ r² (r signed byte) | HIGH |
| D2 | 1009851C | play note | (a, b, c) → Nil | `TAudio::PlayNote(a, b, c)` | HIGH call |
| D3 | 100985C0 | positional sound | (id, x, y) → Nil | integer id only: `TAudio::PlaySound(id, x−leaderX, y−leaderY, 0, far)`, far = 1 when (x, y) is outside the view radius or hidden in the visibility grid | HIGH |
| D4 | 1009874C | positional sound (variant) | (id, x, y) → Nil | as D3 with 4th argument 1 | HIGH code / MED flag meaning |
| D5 | 100988DC | play music | (n or Nil) → Nil | `TAudio::PlayMusic(n, 1)`; Nil → `PlayMusic(−1, 1)` (stop) | HIGH call |
| D6 | 10098994 | play music (variant) | (n or Nil) → Nil | as D5 with flag 0 | HIGH call |
| D7 | 10098A54 | ambient sound | (id, x, y) → Nil | only when (x, y) is visible: `PlayAmbientSound(id, dx, dy, 0)` | HIGH |
| D8 | 10098BE4 | set zone light minimum | (n) → Nil | integer only: `PTR_DAT_100cdea4 = n` (engine-classes §3.3 zone minimum), then `DoTicks(0, 0)` if a viewer exists | HIGH |
| D9 | 10098CA0 | set outdoor sky | (n) → Nil | integer only: `cddf0 = |n|`; `TStatusWindow::ChangeOutdoor(n ≥ 0, hour)` | MED |
| DA | 10098D78 | set map title | (string) → Nil | copies the string to a Pascal string; `SetWTitle` on the map window | MED |
| DB | 10098F08 | scripted window shown? | (obj) → True/False | `TScriptedWindow::FindScriptedWindow(obj)`: found → unnamed glue on it (likely select/bring-to-front), True; else False | MED |
| DC | 10098FB0 | get variable | (i) → int | byte variable `cdbbc[i]` | HIGH |
| DD | 10098FF8 | set variable | (i, v) → Nil | `cdbbc[i] = v` (byte) | HIGH |
| DE | 1009904C | test flag | (n) → True/False | bit n of the 256-flag array `cdbc0` | HIGH |
| DF | 100990CC | set flag | (n, v) → Nil | set/clear bit n by `IsTrue(v)` | HIGH |
| E0 | 1009ABD4 | reschedule | () → Nil | `ScheduleTime(hour, 0)` (rules.md §3) | HIGH |
| E1 | 10099720 | show magic | (obj, n) → Nil | `TGameViewer::ShowMagic(low16(a0), n, 1)` | HIGH call |
| E2 | 10099434 | missile / burst | (x0, y0, x1, y1, tile, flags, radius, a7) → Nil | clears `cee00`; unless `flags & 0xF == 0xF`: `DoMissile` leader-relative from (x0,y0) to (x1,y1), style `flags & 7`, a7; unless flags & 8, a `TBres::DrawBres` line walk from (x0,y0) to (x1,y1) with callback object `PTR_PTR_100d76bc` (not read — presumably marks characters on the path), then the leader's mark is cleared; if radius ≠ 0: `DoBurst` at (x1,y1) and every character with a monster within radius (squared distance) gets `cee00[i] = 1` (read back by CF) | MED (TBres subclass not read) |
| E3 | 100997B8 | show hit | (a, b, c) → Nil | `TGameViewer::ShowHit(a, b, c, 1)` | HIGH call |
| E4 | 10099860 | show attack | (a, b, c, d, list or int) → Nil | up to 16 ints from the list (or the single int) → `ShowAttack(a, b, c, d, n, ints, 1)` | HIGH call |
| E5 | 100999B0 | next sibling | (prop) → prop / Nil | class-0 objects only: next non-free prop index with the same `GetPropParent` | HIGH |
| E6 | 10099AB0 | set arrival byte | (n) → Nil | viewer +0x20C28 = n (the byte 0xF00F supplies on teleport; meaning NOT RESOLVED) | HIGH |
| E7 | 10099B08 | screen effect | (n) → Nil | 0 `Tremor(4, 20)`; 1 flash (`DoGammaFade(0x639C)`, 10 ticks, `DoGammaFade(100)`); 2 magic map (`MakeZone` + `MagicMap(leader, 4)`, wait for key/click via glue); 3 `GammaFadeOut(200)`; 4 `GammaFadeIn(200)` | HIGH |
| E8 | 1009A12C | begin talking | () → Nil | `TStatusWindow::BeginTalking` unless already talking | HIGH |
| E9 | 1009A1B0 | end talking | () → Nil | `EndTalking` if talking | HIGH |
| EA | 1009A090 | conversation cue 2 | () → Nil | while talking: unnamed glue + `PlayIFSound(2)` | LOW |
| EB | 10099FF4 | conversation cue 1 | () → Nil | while talking: unnamed glue + `PlayIFSound(1)` | LOW |
| EC | 1009A234 | open curtain | () → Nil | once: black full-screen window (`cedfc`), abort flag `cedf8` = 0, hide cursor | MED |
| ED | 1009A354 | close curtain | () → Nil | hide + dispose the curtain window, glue call, show cursor | MED |
| EE | 1009A40C | curtain picture | (PICT id, text or Nil) → Nil/False/True | no curtain or aborted → True; draws `PICT id` centred (0x220×0x110 work area); Nil text → False at once; else fades in the text (`TStringFadeInTextImageObject`) until click / Return / Enter / Space, **Esc sets the abort flag** → True, else Nil | MED |
| EF | 10099CD4 | set waypoint | (char, x, y) → Nil | `TActiveMonster::SetWaypoint(x, y)` on the char's monster (if any) | HIGH |
| F0 | 10099D9C | queue activity | (char, act, x, y, value) → Nil | `TActiveMonster::QueueActivity(act & 0xFF, x, y, value)` | HIGH call |
| F1 | 10099E78 | wait for flag | (n) → Nil | clears flag n; locks UI (`TTaskMaster::LockOutUI`), loops `TActiveMonster::Guide()` (world keeps moving) until flag n is set, unlocks, clears it again | HIGH |
| F2 | 1009AA14 | add to-do | (n, v) → Nil | `TToDo::AddToDo(n, v)` | HIGH call |
| F3 | 1009AA98 | done to-do | (n) → Nil | `TToDo::DoneToDo(n)` | HIGH call |
| F4 | 10096D54 | add answer | (string) → Nil | while talking: `TConversation::AddAnswer(string)` (learnt keyword, rules.md §5) | HIGH |
| F5 | 1009AB14 | find skill | (char, skill) → class-0x50 object / Nil | `FindSkill(char, skill)` → `0x4050_0000 \| prop` (the kind-0x1C skill prop, dispatched to segment 0x1A00 + type) | HIGH |
| F6 | 100944D8 | view at | (x, y) → Nil / False | out of map bounds or not `InZone` → False; else prop 0 location := (x, y), byte 6 := 0, CharEntry[0] word 0 := that location with level byte 0; leader temporarily 0, `DrawRoutine(1)`, `ShowTileAnimate(1)`, leader restored | MED |
| F7 | 10099240 | straight line? | (x0, y0, x1, y1) → True/False | `TViewer::IsStraightAbs(x0, y0, x1, y1)` | HIGH call / MED meaning |
| F8 | 1009AEC0 | CD audio | (op, v) → … | when `cdd0c == 0`: ops 0–10 on the CD-player object (`cdd08`), all unnamed `FUN_100bf…`; 3 → a status short, 4 → bool, 5 → a u16, 6 → a short or Nil, 7 clamps v to 0..255 | LOW |
| F9 | 1009AD40 | next serial | () → int | returns `DAT_100d73f4` then increments it (the counter saved in the 'Char' stream, data-format §7) | HIGH |
| FA | 1009AC8C | find unique prop | (n) → prop / Nil | first prop (from 0) whose u16 +8 (unique-object index) == n | HIGH |
| FB | 1009AC50 | (stub) | → Nil | returns Nil | HIGH |
| FC | 1009AD94 | set viewer flag 0xD | (bool) → True/False | viewer +0xD := `IsTrue(a0)`; returns the previous value | MED (flag meaning LOW) |
| FD | 1009AE38 | set erase colour | (n) → Nil | `TViewer::SetEraseColor(n)` | HIGH call |
| FE | 1009B12C | (stub) | → Nil | 4-instruction "return Nil" | HIGH |
| FF | — | — | — | table entry null; executing it would call through a null TVector | HIGH (null) |

Counts: 95 bodies read; **HIGH 77** (5 of them — A4, BC, C8, D4, F7 — carry a MED qualifier on an argument's meaning; the stubs AA, B6, FB, FE are included) · **MED 15** · **LOW 3**.

## 3. What the table settles
- **Inventory** scripting is native-assisted: give (A8), create (AD), delete (A7), transfer (AB),
  find/count/remove (AE, AF, B0, B1), capacity (B7, B8). Item identity in scripts = `type | frame<<10`
  + quality byte.
- **Party**: join/leave (B9/BA) with the 8-member cap and the party-mode-2 refusal; selection
  prompts (B3, BB); party enumeration (B2, CA).
- **Spells/abilities**: `TSpellFX` add/remove/temp/has (C1–C4), effects (E1–E4, E2's area marking +
  CF's victim iterator), skills as class-0x50 objects (F5).
- **World state**: global flags (DE/DF), byte variables (DC/DD) — the same stores `EvalCondition`
  reads for schedules; reschedule (E0); time (BD); teleport (BF); zone light (D8); sky (D9).
- **Not here**: no builtin computes to-hit, damage or experience, or reads/writes HP; combat
  arithmetic is script bytecode (selector 28) using `GetField/SetField`. No builtin calls
  `PerformAI` or `CompileAIFile`.

## 4. NOT RESOLVED (builtins)
- ~~Unnamed glue callees in A2, A6, B5, DB, E7(2), EA, EB, ED, EE, F8~~ — ⚑ corrected (wave 1 2026-10-03):
  resolved except F8 by `open-items-2026-10-03.md` §19 (`FUN_100c50e8` = `__ptr_glue`; vtable slots read
  from the unpacked data section): A2 → app `DoQuit` (+124) and `ShowMenuBar` (+100); A6 → status window
  `IdleRoutine` (+64); B5 → conversation `mygetch("0123456789")` (+280), `ForceOut` (+260); DB → found
  window `Select` (+104); E7 case 2 → app `MyGetEvent(8, &ev, 1)` (+68, waits on keyDown); EA →
  conversation `Hide` (+112); EB → conversation `Show` (+108); ED → app `RedrawAllNow` (+64); EE →
  `TStringFadeInTextImageObject` `Tick` (+8) / `Apply` (+12) [HIGH per open-items §19 disasm sites].
  F8 is CD audio (out of scope).
- ⚑ corrected (wave 1 2026-10-03): **D0's monster word 0** = the `TActiveMonster`'s `CharEntry*`; D0
  iterates the props whose monster shares *who*'s CharEntry (the body props of one multi-prop creature)
  [HIGH code; MED "body segments"] — open-items §19. **FC's viewer +0xD** = auto-mapping on (only reader
  `Render`, sets the 0x8000 "seen" bit on each drawn cell; saved in the `'Char'` chunk) [HIGH] — open-items
  §19. **E2's `TBres` subclass** = `TLineEffect` (vtable 0x100D76BC, +8 `DoBresPixel` @ 0x1009930C): marks
  every character on the missile path in the byte set E2 clears first [HIGH] — open-items §19.
- ⚑ corrected (wave 1 2026-10-03): **B4's two integer arguments** = (minimum, maximum); the slider starts
  at the maximum (`__ct__12THowManyMode… @ 100412c0`: `*(short *)param_1[5] = (short)param_5;` and
  `NewControl(…, (int)*(short *)param_1[5], param_4, param_5, 0x3e91, …)`) [HIGH] — dialogue.md §7.1.
  **BB** `WhoWill(string, 0) @ 10041114`: 0 alive party members → 0; exactly 1 → that member without
  asking; else the name menu plus a `None` chip mapped to 0; all four BB call sites are in never-called
  routines [HIGH] — dialogue.md §7.2.
- D4's flag (4th argument 1 to the D3 path) — meaning still open.
- ~~How compiled `for` loops sequence the iterator modes~~ — ⚑ corrected (wave 1 2026-10-03): mode 0
  init → first, mode 1 done-test (`jt … -> exit`), body, mode 2 next, `goto` the test (listing `0ea5`
  0x001A–0x006E; `1802` 0x0746–0x078D for `iterate_range`) [HIGH] — open-items §19.
