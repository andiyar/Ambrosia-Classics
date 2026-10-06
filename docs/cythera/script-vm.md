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
  read. ⚑ corrected (wave 1 2026-10-03): settled by §8 — both are stored plaintext; 0x0101 is a
  renumbered compiler symbol table; no script references either.
- **Object class segments**: `ObjIDToSegmentID(class, id) = 0x1000 + class·0x20 + id`, where for
  classes 0 and 0x50 the id is first replaced by the **type** of prop `id` (`props[id].u16@4 &
  0x3FF`), and class 0x40 ids > 0x100 map to 0. [HIGH]

| class | segment | who sends it (examples) | data pages | conf |
|---|---|---|---|---|
| 0x00 | 0x1000 + prop type | `VAddr(4,0,prop)` from TakeCommand, DoUse, LoadLevelProps, FillIntfCache | 0x10–0x13 (0x10: 180, 0x11: 88 segs) | HIGH |
| 0x20 | 0x1400 + zone | `ChangeZone`, `HeartBeat`, `OnEnter` (zone = `FindCurZone`) | 0x14 (42 segs; 0x1400 has a "Map" string) | HIGH formula / MED meaning |
| 0x28 | 0x1500 + id | — ⚑ corrected (wave 1 2026-10-03): **no producer** (`Ctor__Fsss` handles source classes 0/0x20/0x40/0x48/0x50 only; no `cls28` literal in the corpus); 0x1500–0x1502 are **class-0x20 zone ids 0x100–0x102** (`0x1000 + 0x20·0x20 + 0x100` = 0x1500; the 'B' frame-4 zone props carry types 0x100–0x102) — open-items-2026-10-03.md §12 | 0x15 (3 segs, zone scripts: "Underground City" / "Crypts" / "Cave") | HIGH |
| 0x40 | 0x1800 + character | `VAddr(4,0x40,char)` from TalkCommand, DoAttack, HatchEgg, DeathRites | 0x18 (121 segs) | HIGH |
| 0x48 | 0x1900 + id | `Ctor__Fsss` builds `|0x40480000` — ⚑ corrected (wave 1 2026-10-03): **monster-species records of 0xF008** (`(ObjToMonst(type) − table) / 16 | 0x40480000`; `GetField` class 0x48 reads the record) — combat.md §4, open-items §12 | 0x19 (29 segs) | HIGH |
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
| 0x9B | class, args… | create system object. ⚑ corrected (review 2026-10-03): with **class byte 0** no object is created — it evaluates one expression and pushes it if integer, else pushes its low 16 bits (object → id) [HIGH]. ⚑ corrected (fix pass 2026-10-03): the class-0 path is **expression form only** — the statement form always calls `CreateSysObj` (§8) |
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

---------------------------------------------------------------------------------------------
## 8. Decoder findings from `tools/scriptdis.py` (full-corpus disassembly)
`python3 docs/cythera/tools/scriptdis.py --census docs/cythera/script-census.md` decodes all 918
code segments (424,209 B) with **0 unknown opcodes**; the operand rules below were read from this
session's dump (`DoExpr @ 1007ddfc`, `DoInterpAt @ 10080c98`) where the rows above are silent.
⚑ corrected (scriptdis 2026-10-03): **literal text (0x01–0x7F) is not NUL-terminated** — it runs to the first byte that is 0 *or ≥ 0x80*, and the pc is left **on** that byte, which then executes (0 = no-op, else the next opcode). `GetString__7TInterpFPUcPUc @ 10082fb0`: `for (; (*param_3 != 0 && (*param_3 < 0x80)); param_3 = param_3 + 1)` … `return param_3;`; DoInterpAt: `local_50[0] = (ushort *)_GetString__7TInterpFPUcPUc(param_2,pcVar9,puVar20);`. Example 0x1802 @02D4: `2c 20 62 75 74 … 6e 2e 88 07 1c` = text ", but with a look of desperation." then `goto 071C`. A jump may enter a text in the middle (106 sites — the compiler shares tails; the tail prints to the same terminator). Consequence: script text cannot contain Mac-Roman bytes ≥ 0x80. [HIGH]
⚑ corrected (scriptdis 2026-10-03): 0x8F prompt reads its string with the same `GetString` and then **skips the terminator byte** (`iVar19 = _GetString__7TInterpFPUcPUc(param_2,pcVar9,puVar17); local_50[0] = (ushort *)(iVar19 + 1);`); expression 0x44 instead uses `FUN_100b6ce8` (strlen to NUL only) and `*param_2 = (int)(short)uStack_50 + *param_2 + 1`, so an inline string may hold bytes ≥ 0x80. [HIGH]
⚑ corrected (scriptdis 2026-10-03): all branch operands (0x88, 0x89 table, 0x8C, 0x8D, 0x90) and 0x9E's target are **absolute offsets in the current segment** (`puVar17 = (ushort *)(param_2[2] + (int)(short)local_64)`, `param_2[2]` = segment data). 0x89 falls through to the byte after its table when the value is out of range (`puVar17 = local_50[0] + (short)local_64 + 1`). [HIGH]
⚑ corrected (scriptdis 2026-10-03): call encodings — every call form takes **one** argument expression (all values pushed, ended by 0x40): `9B cls8 <args>`, `9D sel8 <recv, args…>` (the receiver is the *first* value that expression pushes: `puVar21 = (uint *)(iVar8 + *psVar7 * 4); _DoExpr…; uVar16 = *puVar21;`), `9E off16 <args>`, `9F seg16 <args>`, `9C FFFF <target> <args>` and `9C seg16 <int> <args>` (§4). For 0x9C FFFF the target value decides: tag 6 → routine segment `lo`; tag −1 → code at seg:off (`___ct__7TInterpFs(auStack_120,local_54._0_2_ & 0x7fff); _DoInterpAt…(…,(int)(short)local_54,…)`); any other value → the args are popped and the target value itself is the result. Builtins (0xA0–0xFE) likewise take one argument expression. [HIGH]
⚑ corrected (scriptdis 2026-10-03): the 0x9B **class-0 "id_of" path exists only in the expression form** (DoExpr: `if (uStack_50 == 0) { _DoExpr__7TInterpFRPUc(param_1,param_2); …`); the statement form always calls `_CreateSysObj__FssP5VAddr(&local_54,(int)(short)local_64,…)`. No shipped statement uses class 0 (the 10 statement-form 0x9B use classes 6, 7, 0x0A, 0x0B, 0x0F, 0x10). [HIGH]
⚑ corrected (scriptdis 2026-10-03): 0x82 with a slot byte ≥ 0x40 consumes only the slot byte and evaluates nothing (`if ((0x2f < local_88) && (local_88 < 0x40)) {…}` has no else); expression bytes 0x65–0x9A are the invalid-opcode error (`if (local_58 < 0xa0) { … FUN_100bdef4(_DAT_100ced08,…` in DoExpr's default case); ⚑ corrected (fix pass 2026-10-03): **0xFF is not** — it takes the `else` branch (`FUN_100c50e8(&local_44,iVar20)`), indexes the builtin table whose 0xFF entry is null (script-builtins.md) and calls through a null TVector; DoInterpAt's statement form does the same (`else if (local_88 < 0xa0) { … FUN_100bdef4 … } else { … FUN_100c50e8(auStack_190,local_13c); }`). Neither occurs in the shipped data. 0x43 with a tag-1 value yields the address of local slot `lo` (rebased on `param_1[1]`, the locals base). [HIGH]
⚑ corrected (scriptdis 2026-10-03): **globals are mostly read-only**. `SetGlobal__Fs5VAddr @ 10093a5c` stores only g = 0x0C (clamped 0..100: `if (_DAT_100d73f0 < 0) _DAT_100d73f0 = 0; if (100 < _DAT_100d73f0) _DAT_100d73f0 = 100;`) and g = 0x0E (`*(short *)PTR_DAT_100cdcf4 = …`); every other 0x87 is a no-op, and `GetGlobal__Fs` has no case 0x11 (→ Nil). The shipped scripts write g 0x11 six times (e.g. `87 11 41 02 40`) — dead stores in 1.0.4. [HIGH]
⚑ corrected (scriptdis 2026-10-03): **compiled iterator loop shape** (closes script-builtins.md §4 last item): init `82 L <iter> 43 1000000s 41 00 <init args> 40 40` → `L = iter(&Ls, 0, …)`; test `8C <iter> 43 1000000s 41 01 40 40 <exit>` → `jt iter(&Ls, 1) -> exit`; body; next `82 L <iter> 43 1000000s 41 02 40 40` then `88 <test>`. Example 0x1802 @04C3/@04D3/@04F5: `82 01 a0 43 10 00 00 02 41 00 41 04 41 07 40 40`, `8c a0 43 10 00 00 02 41 01 40 40 05 04`, `82 01 a0 43 10 00 00 02 41 02 40 40 88 04 d3` (iterate_range over 4..7 with state in L02/L03, element in L01). [HIGH for the bytes; MED that every iterator site follows it — see the listings]
⚑ corrected (scriptdis 2026-10-03): **0x0101 is stored plaintext, not undecryptable**: raw bytes `a0 7f 50 00 ff ff 00 00 50 00 ff ff ff ff …` are a 127-slot dictionary whose 55 keys are segment ids and whose values point at identifier strings in the same segment (0x0200 "gTileNames", 0x0201 "gCharNames", 0x3000 "__init__", 0x3006 "Talk", …) — a compiler symbol table from an older build (its 0x3006 "Talk" disagrees with native talk = selector 12). No script references it; `GetEncryptedSegment` would garble it (it always decrypts). Same for 0x0210 (raw `90 01 82 10 00 06 'Return'`). [HIGH for the bytes, MED for "older build" — superseded by the fix-pass line below: a *renumbered* table]
⚑ corrected (scriptdis 2026-10-03): string tables (page 0x02) may hold **Nil entries** (0x021A: 1055 of 1141); code uses a Nil entry 0 as an index base, `str[seg:0] + int` (0x4A adds to the tag-3 index), e.g. 0x10C5 @003E `8a 43 30 00 02 21 30 62 07 4a 40` = print(str[0221:0] + A30.f07). 0x0201's entries carry high half 0x9165 (not 0x8201); only the low 16 bits are used. [HIGH]
⚑ corrected (fix pass 2026-10-03): **0x0101 is a renumbered symbol table naming the shipped helper routines.** 39 of its 55 keys name segments absent from the data (0200, 0202, 1000, 1640–1648, 1664–1667, 1700–1713, 3022, 3026, 3028), but the helper keys map 1:1 onto pages 0x0E/0x0F: **0x1700+k ↔ 0x0F00+k** (0F00 `L00.f13:flags = (L00.f13:flags | (1 << A31))` = setbit, 0F01 clrbit, 0F02 tstbit — the `R0F02(A30, 1)` of every talk method, 0F03 `activity = A31` = setworktype, 0F04 getworktype, 0F05 `health = health_max` = heal, 0F06 `status & -3` = curepoison, 0F07 `status | 1; health = health_max` = raisedead, 0F08 enhorse, 0F09–0F0D adjint/adjdex/adjstr/adjexp/adjlevel on mind/reflex/body/exp/level, 0F0E getinjury, 0F0F `status & 2` = ispoisoned, 0F10 `status & 4` = ishorsed, 0F11/0F12 `G0C ∓ A30` = deckarma/inckarma, 0F13 inparty), **0x1640+k ↔ 0x0E40+k** (DoDoor, DoToggle, DoLockable, DoKey, 0E44 "It is now unlocked" = DoToggleLock, DoVolumeCheck, 0E46 "You aren't hungry." = DoFood, 0E47 sundial = DoClock, SpillOut) and **0x1664+k ↔ 0x0E64+k** (DisplaySign, DisplayScroll, DisplayContainer, DisplayInstrument — 0E64/65/66/67 each build `sysnew_window`). The 0x30 keys do not map (it has 0x3006 "Talk"; native talk is selector 12 → 0x300C), so the table predates the selector renumbering. `scriptdis.py` labels these 33 routines `[from 0x0101 symtab]` (listing headers and call-site comments); the 15 never-called 0x0F routines (census §7) are an unused helper library. (The review's "0F0F = ishorsed" was a slip: by the mapping and the bodies 0F0F = ispoisoned, 0F10 = ishorsed.) [HIGH for the bodies, MED for the mapping]
⚑ corrected (fix pass 2026-10-03): **under-supplied builtin calls read the stale slot above the stack top** — a replica must keep the fixed 0x400-slot array and **must not clear popped slots** (the interpreter only moves the top: `*psVar7 = sVar14 + -1`; no zeroing, no growable vector). Builtins index their argument base unconditionally. Three settled sites: 0x3041 @0029 `8d ac 31 41 14 4a 40 31 4f 40 00 3a` = `jf (random((A31 + 20)) < A31)`, one argument, while `Builtin_AC` reads `param_2[1]` (`sVar1 = (short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4)`); 0x1832 @0D70 `a8 42 00 01 42 00 99 41 01 40` = `give_item(1, 153, 1)`, while `Builtin_A8` passes `param_2[3]` to `SetItemCount` and clones `param_2[3]−1` more records when it is ≥ 2 (a large stale value multiplies the item); 0x0C86 @005F `f0 30 41 42 41 05 40` = `queue_activity(A30, 66, 5)`, while `Builtin_F0` passes `param_2[3]`, `param_2[4]` to `QueueActivity`. The full list of short calls is census §4 (nine calls). [HIGH]
⚑ corrected (fix pass 2026-10-03): **a class dictionary value may point into another segment's code.** Seven classes (0x102E, 0x1846, 0x1847, 0x1848, 0x1849, 0x1864, 0x1865) map selector 21 (signal) to `0x8D070000` = routine 0x0D07 offset 0; `DoInterp0` runs any non-Nil value found by `Dispatch` as code at seg:off (`___ct__7TInterpFs(auStack_38,local_28[0]._0_2_ & 0x7fff); _DoInterpAt…(param_1,auStack_38,(int)(short)local_28[0],…)`), so these are shared methods, not properties. "Method" vs "property" in a dictionary is decided by use (sent → code; 0x60/0x61 → property), not by storage. Census §5 now counts 35 signal methods (was 28 + 7 "properties"). [HIGH]
⚑ corrected (fix pass 2026-10-03): **0x9C FFFF with a non-routine target probably leaks a stack slot** (review note 7): both forms end with `*psVar7 = *psVar7 + (short)((int)uVar16 >> 2) + (…) + 1;` and DoExpr then also pushes `local_44`, so the statement form would leave one stale slot and the expression form grow the stack by two (unlike 0x9D's non-object path, whose statement form pops cleanly). Whether any of the four shipped `callx` (seg FFFF) sites — 0x0816 @007E, 0x0C00 @0011, 0x0C43 @0004, 0x0EA5 @003D (census §7) — ever receives a non-routine value is not settled statically. Decompiler-level reading only — verify from raw PPC disassembly before banking as engine behaviour. [MED]
⚑ corrected (wave 1 2026-10-03): the non-routine path is **live** in shipped data — 0816 @007C `set L08 = callx[L08](A30)` receives a non-routine entry value in 113 of its 114 table entries (one code pointer, `080e` `[0] @0006 (code)`), and 0EA5 @003B `set L05 = callx[L05](L02)` in every stock entry (integer counts) — script-library.md §10.1/§10.2. The stack-slot effect itself stays [MED] (INDEX NOT RESOLVED 21).
⚑ wave 2 (2026-10-06): **INDEX 21 closed [HIGH, disasm].** The non-routine 0x9C FFFF path pops the target, then resets the top to `args base + 1` (`1007ee54: subf ; srawi ; addze ; 1007ee60: addi r5,r3,1`) and pushes the target again. So the expression form ends at t+2 (result on top, one stale slot under it) and the statement form at t+1 (`100822a0: addi r4,r3,1`, no push). The leak lives only until the frame ends: `return` and end of code reset the top to the frame's args base (`10081794: lwz r0,0(r28)`). The four shipped sites get the right value. 0816/0EA5 leak one slot per loop pass, and no read sees it — open-items-2026-10-06.md §1.
