# Cythera 1.0.4 — the scenario script VM (`TInterp`, "DSInterp2")

Register: **code reading only**. This file exists because most game *rules* (conversation, combat
resolution, spells, item use, quests) are not in native code: native code sends **selectors** to
per-object **bytecode** stored in encrypted segments of `Cythera Data`. Implementing Cythera means
implementing this VM. Functions: `DoExpr__7TInterpFRPUc @ 1007ddfc` (expressions),
`DoInterpAt__7TInterpFsP5VAddr @ 10080c98` (statements), `DoInterp0 @ 10082b34`, `Dispatch @
10082edc`, `VAddrToPtr @ 1008301c`, `At @ 10083798`, `Len @ 100835ac`, `IsTrue @ 10080964`,
`ObjIDToSegmentID__FsUs @ 100917a0`, `GetGlobal__Fs @ 1009376c`, `GetField/SetField__Fsss`,
`CreateSysObj/DispatchSysObj`, `THeap`/`THeapObj`/`THeapList`/`THeapDict` (persistent heap).
The 1.0.4 notes call the persistent heap "persistent storage" (64K → 256K in 1.0.2) — matches
`InitHeap(…, 0x1000, 0x40000)` in `CreateGlobals`. [HIGH]

---------------------------------------------------------------------------------------------
## 1. Values (`VAddr`, 32 bits)
`__ct__5VAddrFcUsUs @ 100077ec`: tag in bits 28–31, `hi` 12 bits at 16–27, `lo` 16 bits at 0–15;
tag −1 (`0xFF`) instead sets bit 31 with a 15-bit segment in bits 16–30. Tag decode everywhere:
`(int)v < 0 ? -1 : v >> 28`. [HIGH]

| tag | meaning | evidence |
|---|---|---|
| 0 | **integer**, 28-bit signed (`(v<<4|v>>28)>>4`), results masked `& 0xFFFFFFF` | DoExpr arithmetic |
| 1 | stack slot (frame-relative; `0x43` push rebases it) | DoExpr 0x43, VAddrToPtr case 1 |
| 2 | built-in global string `GetGlobStr(lo)`: 1 = time-of-day word, 2 = player name, 10 = last input | `GetGlobStr__Fs @ 10093ce0` |
| 3 | string #`hi` in the string table at the start of segment `lo` (u16 count & 0xFFF, then u32 entries whose low 16 bits are offsets). ⚑ corrected (review 2026-10-03): an index `hi ≥ count` is **clamped to entry `count−1`**, not rejected [HIGH] | VAddrToPtr case 3 |
| 4 | **object**: class `hi & 0xFFF`, id `lo`; bit 24 set = system object (window/widget…) | `DoInterp0`, `DispatchSysObj` |
| 5 | constants: **Nil 0x5000FFFF, True 0x50000001, False 0x50000000**, unset 0x5000FFFE | `__sinit_THeap_cp @ 100ac1a4` |
| 6 | routine handle (segment `lo`) | DoExpr 0x9C, DoInterp0 |
| 7 | persistent-heap object (THeapObj ref `lo`; types: 2 = frame/dict, 3 = string, list…) | `GetType__8THeapObj`, `DispatchHeapObj` |
| −1 | code pointer: segment `(v>>16)&0x7FFF`, byte offset `lo` | VAddrToPtr default case |

`IsTrue`: True → true; False/Nil → false; integer ≠ 0; tags 2, 3, 4, −1 → true; others false. [HIGH]

In-segment literals pointed at by code pointers are typed by their first byte (`At`/`Len`):
`< 0x80` C string; `0x80–0x8F` code; `0x90–0x9F` **array** (u16 header, count = `& 0xFFF`, then
u32 VAddrs at +2); `0xA0–0xAF` **dictionary** (u16 header, n = `& 0xFFF` slots of {u32 value, u16
key}; open addressing: start = key mod n, step = the first non-zero `(key·3+1 …) mod n`; empty slot
value = Nil). [HIGH — `At__7TInterpF5VAddrs` cases 2 and 3]
⚑ corrected (review 2026-10-03): the dictionary header range is **0xA0–0xAF only**. `At @ 10083798` computes class =
`(b>>4) − 7`; only class 3 (0xA0–0xAF) takes the dictionary path; a block starting 0xB0–0xBF is
returned **unchanged** (the operand itself), and `Len` of a dictionary is **0**. [HIGH]

---------------------------------------------------------------------------------------------
## 2. Segments, classes and selectors

### 2.1 Where code lives
- Every script segment is encrypted with the id-keyed XOR LCG (data-format.md §1.3); the
  interpreter always reads through `GetEncryptedSegment`. Decrypting with `tools/seg.py` `dec()`
  yields readable text, e.g. 0x0203 contains "Explorer", 0x0801 "House Attis is the former ruling
  House…", 0x1001 "As you approach the building, it shimmers and then fades." [HIGH]
  Exceptions: 0x0210 is stored **plaintext** in the file (raw bytes `9001 8210 0006 'Return'`) and
  0x0101 does not decrypt to anything recognisable with its id key — NOT RESOLVED how/if these are
  read.
- **Object class segments**: `ObjIDToSegmentID(class, id) = 0x1000 + class·0x20 + id`, where for
  classes 0 and 0x50 the id is first replaced by the **type** of prop `id` (`props[id].u16@4 &
  0x3FF`), and class 0x40 ids > 0x100 map to 0. [HIGH]

| class | segment | who sends it (examples) | data pages | conf |
|---|---|---|---|---|
| 0x00 | 0x1000 + prop type | `VAddr(4,0,prop)` from TakeCommand, DoUse, LoadLevelProps, FillIntfCache | 0x10–0x13 (0x10: 180, 0x11: 88 segs) | HIGH |
| 0x20 | 0x1400 + zone | `ChangeZone`, `HeartBeat`, `OnEnter` (zone = `FindCurZone`) | 0x14 (42 segs; 0x1400 has a "Map" string) | HIGH formula / MED meaning |
| 0x28 | 0x1500 + id | — | 0x15 (3 segs; 0x1500 contains "Underground City") | LOW |
| 0x40 | 0x1800 + character | `VAddr(4,0x40,char)` from TalkCommand, DoAttack, HatchEgg, DeathRites | 0x18 (121 segs) | HIGH |
| 0x48 | 0x1900 + id | `Ctor__Fsss` builds `|0x40480000` | 0x19 (29 segs) | LOW |
| 0x50 | 0x1A00 + prop type | `PerformMacro`, status window (`|0x40500000`); builtin **0xF5** `FindSkill(char, skill)` returns the skill prop (kind 0x1C) as a class-0x50 object (script-builtins.md) | 0x1A (87 segs; 0x1A00 = "Directed Nexus") | ⚑ corrected (review 2026-10-03): **spell / ability classes keyed by prop type** — decrypted 0x1A00/0x1A01 are spell objects ("Directed Nexus", "Vision of the Night", "This spell creates…", selectors 2/8/9/51/54). HIGH |
| 0x58 | 0x1B00 + room | **rooms**: `HeartBeat__8TGameSysFs` sends 20 (enter) to the new room (`PTR_DAT_100cde74`) and to every non-party character whose `CharEntry::GetRoom` is that room, and 7 (first visit) once per room | 0x1B (111), 0x1C (38) | HIGH formula / MED meaning |
| 0x78 | 0x1F00 + id | `TGremlin::OnEnter/OnSignal` (`|0x40780000`) | none in data | MED |
| sys 4 / 5 | — | scripted windows / widgets (`|0x41040000`, `|0x41050000`) | — | HIGH |

(0x50 and 0x58 ranges overlap for type ≥ 0x100 — read literally; not reconciled.)
⚑ corrected (review 2026-10-03): raw disasm of `ObjIDToSegmentID` confirms `0x1000 + class·0x20 + id` with the 0x50 type
substitution, so a 0x50 type ≥ 0x100 would land in the room range (0x1B01/0x1C2D answer 7/20 = rooms;
0x1400/0x1500 answer 20 = zones). This is a **data invariant** (spell/skill types < 0x100), not a
code bug. [HIGH]

- **Routine segments**: `0x3000 + selector` is the default handler when an object's dictionary
  lacks the selector (`DoInterp0`: `if (!Dispatch) TInterp(param_2 + 0x3000)`); `0x0900 + k` /
  `0x0980 + k` are the combat-AI scenario tests/actions (ai-scripts.md §5); routine calls 0x9C/0x9F
  name any segment directly (e.g. 0x0F02 in the sample below).

### 2.2 Object segment layout and dispatch
Segment = `u16 dictOffset` + code + dictionary. `Dispatch(seg, sel)` = `At(codeptr(seg,
dictOffset), sel)`; Nil ⇒ not handled. The dictionary value is a code pointer (method) or any
VAddr (property; `GetProperty` = `At(value, index)` to pick an element of a list property). [HIGH]

Worked decode (decrypted with `tools/seg.py`):
```
1001 len 141 dict@0x79 hdr a003 n=3        key 9 -> 90010008, key 58 -> 90010002
1802 len 10426 dict@0x288e hdr a007 n=7    key 12 -> 98020292, key 32 -> 9802002a, key 68 -> 98020002
```
Prop type 1 (segment 0x1001) answers selector 9 (stepped on/used, code at +8) and property 0x3A;
character 2 (0x1802) answers 12 (talk, code at +0x292), 32 (hatch) and 68. [HIGH]

### 2.3 Selector numbers used by native code
(command: grep of every `DoInterp/HasProperty/GetProperty` call with a literal selector, listed in
INDEX provenance)

| sel | sent by | reading |
|---|---|---|
| 0 | CreatePlayer, HatchEgg, LoadLevelProps (merge) | create/init |
| 2 | status window, PerformMacro, VAddrToPtr, PrintObj | name/describe (object → string) |
| 3 | `Len` on objects | length |
| 4 | `At` on objects, PerformDoKey | index |
| 7 | HeartBeat | room first visit (guarded by room flag bit 0, segment 0xF00E) |
| 8 | SearchCommand | search |
| 9 | CanPMove, CanMove, DoUse | use / step onto |
| 10 | UseOnCommand | use on |
| 12 | TalkCommand | **talk** |
| 13, 27 | WieldCommand (27 also SlideItem) | wield / slide |
| 14–17, 24, 25 | Take/Drop | take/drop hooks |
| 20 | ChangeZone, HeartBeat, Gremlin OnEnter | enter zone |
| 21 | DoTicks, SendSignal, PassTime, RemoveAllAbility | timer/signal (arg 0x101 hourly, 0x104 countdown expiry) |
| 28 | AttackCommand, `TActiveMonster::DoAttack` | **attack** (returns delay ticks) |
| 29 | `CharEntry::DeathRites` | death |
| 31 | HandleMove | moved |
| 32 | HatchEgg | spawned |
| props 22, 34–41, 50, 54, 55, 58, 59 | FillIntfCache, GetMaxInvEncumb, Wield, ScheduleTime, RecalcPartyLight, monster ctors | type properties (data-format.md §4.4) |
All selector *names* above are inferred from the sending function [MED]; the numbers are literal [HIGH].

---------------------------------------------------------------------------------------------
## 3. Frames and the stack
Value stack: global array `_DAT_100cdf80` (0x400 × 4 B, `__sinit_DSInterp2_cp`), top index
`*_DAT_100cdf7c`. A `TInterp` (`__ct__7TInterpFs @ 100833bc`) holds {args base, locals base,
segment data ptr, segment id}. Method bodies begin with **`0x81 nArgs nLocals`** which reserves
`nLocals` stack slots. **Locals are slots 0x00–0x2F (`TInterp[1]`), args 0x30–0x3F (`TInterp[0]`).**
⚑ corrected (review 2026-10-03): the original text had args and locals the other way round. `DoInterpAt @ 10080c98`
prologue: `stw r0,0x0(r28)` with r0 = param_4 (the pushed-argument pointer — `DoInterpRoutine`
passes `top*4 − 0xC` after pushing 3 args) and `stw r0,0x4(r28)` with r0 = the current stack top;
`0x81 a b` then reserves `b` slots at that top (`a` = arg count). DoExpr default case (disasm
0x10080610): op < 0x30 → `lwz r5,0x4(r28)` (the reserved local area); 0x30–0x3F → `lwz
r10,0x0(r28)` (the pushed args). [HIGH]
A non-local exit (statement 0x92) stores an exception object in `PTR_DAT_100cdf84`; every
interpreter loop stops while it is non-zero. [HIGH]

---------------------------------------------------------------------------------------------
## 4. Statements (`DoInterpAt`)
| op | operands | semantics |
|---|---|---|
| 0x00 | — | no-op |
| 0x01–0x7F | C string | **literal text** → `HandleMapping` → `OutStr` (conversation/narration output) |
| 0x80 | — | ⚑ corrected (review 2026-10-03): **invalid opcode** (falls to the same error as 0x94–0x9A) [HIGH] |
| 0x81 | nArgs, nLocals | frame header |
| 0x82 | slot, expr | assign local (<0x30) or arg (0x30–0x3F) — ⚑ corrected (review 2026-10-03) (was reversed) |
| 0x83 | u16 off, expr | store u32 into the current segment at `off` (not persisted) |
| 0x84 | list, index, value | `AtPut` if 0 ≤ index < Len |
| 0x85 | u16 seg, u16 off, expr | store u32 into segment `seg` at `off` **and re-save it encrypted** (persistent script globals) |
| 0x86 | field, obj, value | `SetField(obj, field, value)` for tag-4 objects |
| 0x87 | byte g, expr | `SetGlobal(g)` |
| 0x88 | u16 target | goto |
| 0x89 | expr, u16 n, n×u16 | switch: integer 0 ≤ v < n → jump table[v], else skip table |
| 0x8A | expr | print value (ints `%d`, True/False/Nil words, objects via `PrintObj`, strings) |
| 0x8B | expr | return value |
| 0x8C | expr, u16 | jump if true |
| 0x8D | expr, u16 | jump if false |
| 0x8E | — | read a line of player input into the input buffer (64 chars); empty → default string |
| 0x8F | string | prompt: `*`-prefixed → line input, else single-key choice among the string's characters |
| 0x90 | `word[,word…]` text, u16 | **keyword match**: compare each comma-separated word with the input (prefix compare `FUN_100b6dc8`); `*` matches anything; no match → jump |
| 0x91 | — | no-op (falls through) |
| 0x92 | byte, expr | raise (non-local exit with code + value) |
| 0x93 | expr | release: heap object `DecRef`, system object `DeleteSysObj` |
| 0x94–0x9A | — | invalid opcode error |
| 0x9B | class, args… | create system object. ⚑ corrected (review 2026-10-03): with **class byte 0** no object is created — it evaluates one expression and pushes it if integer, else pushes its low 16 bits (object → id) [HIGH] |
| 0x9C | u16 seg (0xFFFF = computed), args | call routine. ⚑ corrected (review 2026-10-03): for seg ≠ 0xFFFF **one integer expression is evaluated first and added to seg** (`uStack_50 = seg + int(pop)`, DoExpr block lines 1001–1015, DoInterpAt 1814–1827), then the args are evaluated and routine `seg + n` is called — the encoding is `9C seg16 <int-expr 40> <args 40>` [HIGH] |
| 0x9D | sel, obj, args | **send** selector to object (dict → else routine 0x3000+sel; sys/heap objects dispatched natively). ⚑ corrected (review 2026-10-03): a **non-object receiver** pops the args and leaves the receiver itself as the result [HIGH] |
| 0x9E | u16 off, args | call local subroutine in the same segment |
| 0x9F | u16 seg, args | call routine segment |
| 0xA0–0xFF | args | **native builtin** via an indirect table — see §6 and `script-builtins.md` |
[HIGH for every listed op except: 0x8E/0x8F I/O routines are unnamed `FUN_100c50e8` calls (MED);
0x90's compare function `FUN_100b6dc8` assumed to be `strncmp`-like (MED).]

## 5. Expressions (`DoExpr`, RPN until 0x40)
| op | semantics |
|---|---|
| 0x00–0x2F | push **local** slot — ⚑ corrected (review 2026-10-03) (was "arg") |
| 0x30–0x3F | push **arg** slot — ⚑ corrected (review 2026-10-03) (was "local") |
| 0x40 | end of expression |
| 0x41 / 0x42 | push i8 / i16 |
| 0x43 | push literal u32 VAddr (tag-1 values rebased to the current frame) |
| 0x44 | push code pointer to the inline C string that follows |
| 0x45 | u16 len: push code pointer to the inline block that follows |
| 0x46 | index: `At(list, int)` (Nil if index not an integer) |
| 0x47 | u16 off: push u32 from the current segment |
| 0x48 | byte g: `GetGlobal(g)` (0 hour, 4 raw clock, 5/9 party leader/current speaker, 6/7 party size, 0xC/0xE save-stream values, 0xF day, 0x10 zone, 0x12, 0x13 …) |
| 0x49 | u16 seg, u16 off: push u32 from another segment |
| 0x4A | add (int+int; string-table index + int; object id + int) |
| 0x4B | sub (int; object id − int) |
| 0x4C / 0x4D / 0x4E | mul / div / mod (÷0 → 0) |
| 0x4F / 0x50 / 0x51 / 0x52 | < / ≤ / > / ≥ (ints only) |
| 0x53 / 0x54 | **!= / ==** (`IsEqual`) — ⚑ corrected (review 2026-10-03): swapped in the original text. `__sinit_THeap_cp @ 100ac1a4` sets `*PTR_DAT_100cddec = 0x50000001` (True), `*PTR_DAT_100cde70 = 0x50000000` (False). Case 0x53 (jump-table entry 0x13 at TOC+0x1474 → 0x1007FE68): `bl 0x10080adc (IsEqual); rlwinm. r4,r3,0,24,31; bne → lwz r5,0(r27)`, r27 = `lwz -0x7410(r2)` = 100cde70 = **False** when equal. Case 0x54 (0x1007FF14): `beq → lwz r7,0(r27)` (False) else `lwz r4,0(r26)` (True). [HIGH] |
| 0x55 / 0x59 | negate / bitwise not |
| 0x56 / 0x57 / 0x58 | bitwise and / or / xor |
| 0x5A / 0x5B | shift left / right (count & 0x3F) |
| 0x5C / 0x5D / 0x5E | logical and / or / not (`IsTrue`) |
| 0x5F | length (`Len`) |
| 0x60 sel | object handles selector? → True/False |
| 0x61 sel, idx | property `sel` element `idx` |
| 0x62 field | `GetField(obj, field)` |
| 0x63 class | cast: int → object of `class`; object of other class → `Ctor(obj, class)` |
| 0x64 class | is-instance-of class |
| 0x9B–0x9F | as the statements, leaving the result on the stack (0x9C: note the extra integer operand, §4 — ⚑ corrected (review 2026-10-03)) |
| 0xA0–0xFF | native builtin (§6, `script-builtins.md`) |
Non-integer operands to arithmetic generally return the left operand unchanged. [HIGH]

Worked decode (character 2's talk method, segment 0x1802 + 0x292, decrypted):
```
81 01 11                      frame: 1 arg, 17 locals
"Before you stands an older, dignified gentleman"          ← literal text (bytes < 0x80)
82 00 9F 0F02 30 41 01 40 40  local0 = Routine0F02(arg0 /*self*/, 1)
8D 00 5E 40 02F8              if !(not local0) … jump to 0x02F8
", but with a look of desperation."   88 071C                ← text, goto 0x071C
```
⚑ corrected (review 2026-10-03): the decode originally read `arg0 = call routine 0x0F02(local0, 1)`; slot 0x00 is local 0
and 0x30 is arg 0 (§3), so it is `local0 = Routine0F02(arg0, 1)` — 0x81's byte 0 (= 1) is the arg
count, matching the single pushed receiver. [HIGH]
(`*` characters inside text are presumably the conversation "pause" markers mentioned in the 1.0.2
notes — LOW.) [HIGH for the byte split, MED for the reading of 0x9F's argument list]

---------------------------------------------------------------------------------------------
## 6. The builtin table (opcodes ≥ 0xA0) — RESOLVED
⚑ corrected (review 2026-10-03): this section was "NOT RESOLVED — the callee is a table entry, not resolved in the dump;
next step: re-run Ghidra with aggressive function discovery". The table is in the data section:
DoExpr disasm at 0x100806d0: `addi r8,r2,0x1ff0; lwzx r12,r8,(op−0xA0)*4; bl 0x100c50e8` → **96
TVector pointers at TOC+0x1FF0 = 0x100D7270** (r2 = 0x100D5280); each TVector's first word is the
code address. `FUN_100c50e8` is the **cross-TOC pointer-call glue** (callers restore `lwz
r2,0x14(r1)` after it), not "a table entry". Opcode 0xFF's entry is null; 93 of the 95 bodies lie in
the 0x10093E14–0x1009B164 gap (never directly called, so never made into functions); 0xA0/0xA1 sit
in the undiscovered 0x678 bytes after `AtPut @ 10083ab4`. [HIGH]

Calling convention (DoExpr default case and DoInterpAt `≥ 0xA0`): remember `argsBase = &stack[top]`;
evaluate **one** expression (the RPN arg list, all args pushed, terminated by 0x40); call
`builtin(VAddr *result, VAddr *argsBase)`; reset the stack top to `argsBase` (pops every arg); the
expression form pushes `result`, the statement form discards it. The argument count is not passed —
each builtin reads a fixed number of `argsBase[i]`. [HIGH]

Full opcode → address → behaviour table, with the decompile recipe (`tools/CyDecompBuiltins.java`):
**`script-builtins.md`**. Everything game-rule-shaped that scripts do natively (inventory moves,
party join/leave, abilities, flags/variables, teleport, time passing, sound, visual effects,
iterators) passes through these builtins. **No builtin computes to-hit/damage or touches HP**
(all 95 bodies read) — combat arithmetic must be script bytecode reaching CharEntry fields through
`GetField/SetField` (0x62/0x86) [MED: inferred from absence].

## 7. Persistent heap (save state for scripts)
`THeap` (0x40000 bytes, 0x1000 refs) holds script-created strings/lists/dicts (`THeapObj` types),
reference-counted (`IncRef/DecRef`), compacted by `PerformGC`; saved as 0xF307, with the
unique-object table 0xF308 (0x2000 B, one u16 heap ref per prop `+8` index). Prop `+0xC` and
gremlin `+2` "frames" are heap dicts holding per-instance variables. [HIGH for sizes/ids; heap block
header layout (`HeapHeader`, 8 bytes: size, type bits in byte 6) MED]
