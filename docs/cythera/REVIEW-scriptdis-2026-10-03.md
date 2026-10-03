# Review — Cythera Wave 0: `scriptdis.py`, script-census.md, script-vm.md §8 (commit dd44f2c)

**VERDICT: ACCEPT_WITH_FIXES** — the decoder is byte-exact against the engine on everything I
hand-decoded and the eight §8 corrections hold against `DoInterpAt`/`DoExpr`/`GetString`/`SetGlobal`;
but the listings hide the contents of every `0x45` inline block (26,569 bytes, the pick lists /
option tables the readers need) and seven shared signal methods are labelled "properties". Neither
poisons the *bytes*; both poison what a reader concludes from the listings.

Method (every byte/line below came from a command run in this session): re-ran
`scriptdis.py --census … --out …` into the scratchpad — census identical to the committed file
except the out-dir path line, all 958 listings identical (`diff -rq`); decrypted 0x1802, 0x1809,
0x0803, 0x0814, 0x0806 with `seg.py dec()` and hand-decoded them before opening the listings
(appendix); read `DoInterpAt @ 10080c98` whole, `DoExpr @ 1007ddfc` cases 0x41–0x46, 0x60–0x64,
default, 0x9B–0x9F, `GetString @ 10082fb0`, `SetGlobal @ 10093a5c`, `GetGlobal @ 1009376c`,
`DoInterp0 @ 10082b34`, `Dispatch @ 10082edc`, `GetEncryptedSegment @ 1007d148`, `FUN_100b6ce8`,
`Builtin_A8/AC/F0`; measured the tool's structures by importing it (0x45 coverage, dictionary
value kinds, dead runs, 0x0101 keys, string/name resolution).

## Findings (most severe first)

1. **Major / HIGH — 0x45 inline-block contents are absent from the listings.** 176 sites in 80
   listings (173 arrays, 3 dictionaries, 26,569 declared bytes = 6.3 % of code bytes), each shown only
   as `blk@XXXX`. `Dis.listing()` prints a block only `if self.owner.get(o) is None`, and a 0x45 block
   always lies inside its instruction's byte range, so the array, its nested strings and dictionaries
   are never emitted. Evidence: `0EA7 @0025: 82 02 c0 44 … → set L02 = pick_item("Haggle", "%s",
   blk@0037)` — the listing's next line is `00A0`; the 111-byte list of haggle strings is invisible.
   `0801 @0AE7: 9f 08 16 30 45 01 4a 90 06 88 01 0b … → call R0816(A30, blk@0AEE, 10)` — a 330-byte
   table (`90 06` array of six `8801_0Bxx` code pointers to inline strings), next listing line `0C3B`.
   Coverage is *not* at fault (my measurement: 0 bytes inside any 0x45 range are uncovered by a
   nested block), but the census books these 26,569 bytes under "statements reached … 379721", not
   under "literal blocks". Fix: in `listing()` emit nested `.array/.dict/.string` lines for blocks
   whose owner is an instruction (indented under the `blk@` line, or inline-render the array), and
   move 0x45 bytes to the literal-block bucket in `coverage()`.

2. **Major / HIGH — cross-segment method pointers classified as properties.** Seven class
   dictionaries carry, under selector 21 (signal), the value `0x8D070000` = code pointer to
   `0D07:0000`: classes 0x102E, 0x1846, 0x1847, 0x1848, 0x1849, 0x1864, 0x1865 (e.g. `102E
   dict@00F7: a0 07 8d 07 00 00 00 15 …` → header `properties: sel21/signal, sel55/p37`). `Dis.run()`
   accepts a method only if the pointer is *same-segment* and targets 0x80–0x8F; everything else is
   `props`. The engine has no such rule: `DoInterp0` → `Dispatch` → `___ct__7TInterpFs(auStack_38,
   local_28[0]._0_2_ & 0x7fff); _DoInterpAt__7TInterpFsP5VAddr(param_1,auStack_38,(int)(short)
   local_28[0],…)` runs any non-Nil dictionary value as code at seg:off; 0x9D in `DoInterpAt` does the
   same (`___ct__7TInterpFs(auStack_c4,local_58._0_2_ & 0x7fff)`). 0D07 is a real handler (`81 02 01`,
   `jf (A31 == 256) → R0D06(A30, A31)`, `(A31 == 320) || (A31 == 321)` …). Consequences: census §5
   "21 signal: methods 28, properties 7" is wrong (35 methods), census §7 "calls in" for page 0x0D
   omits these 7 (the tool counts them in `xref_ptr`, not `xref_call`), and a reader banking signal
   handling from the headers misses seven characters. Fix: treat any tag −1 pointer whose target byte
   is 0x80–0x8F (any segment) as a method, count cross-segment ones as calls-in, and state in the
   header that "method" is a first-byte heuristic (the engine's rule is usage: sent → code,
   0x60/0x61 → property).

3. **Minor / HIGH — 0x0101 is a renumbered symbol table for the shipped helper pages, not just an
   "older build" relic.** 39 of its 55 keys name segments absent from the data (0200, 0202, 1000,
   1640–1648, 1664–1667, 1700–1713, 3022, 3026, 3028) — a stronger staleness argument than the
   3006/"Talk" one — but the absent keys map 1:1 onto pages 0x0E/0x0F: 0x1700+k ↔ 0x0F00+k (`0F00:
   86 13 … L00.flags = flags | (1 << A31)` = **setbit**; 0F01 `& ~(1 << A31)` = clrbit; 0F02 = tstbit —
   the `R0F02(A30, 1)` calls in every talk method; 0F03 `activity = A31` = setworktype; 0F05 `health =
   health_max` = heal; 0F07 `status |= 1; health = max` = raisedead; 0F0A `reflex += A31` = adjdex;
   0F0F `status & 2` = ishorsed), 0x1640+k ↔ 0x0E40+k (0E44 prints "It is now unlocked" =
   DoToggleLock; 0E46 leader health vs max = DoFood), 0x1664+k ↔ 0x0E64+k (0E64/65/67 build
   `sysnew_window` = DisplaySign/DisplayScroll/DisplayInstrument). The 0x30 keys do *not* map (shipped
   3006 is a 2-arg `return 0` stub where the table says Talk; 300C prints "You are met with stony
   silence"), so the table predates the selector renumbering. Fix: bank the 0x16→0x0E / 0x17→0x0F
   mapping (MED) in census §7 and use the 33 names as page-0x0E/0x0F labels; this also explains the
   15 "never called" 0x0F routines (setworktype … inparty: a helper library, mostly unused in 1.0.4).

4. **Minor / HIGH — replica constraint missing from §8: under-supplied builtins read the slot above
   the stack top, which still holds the last value popped there.** Confirmed at three sites, tool and
   bank both right, scripts short: `3041 @0029: 8d ac 31 41 14 4a 40 31 4f 40 00 3a` = `jf
   (random(A31 + 20) < A31)`, one arg; `Builtin_AC` reads `param_2[1]` unconditionally (`sVar1 =
   (short)(param_2[1] << 4 | …)`). `1832 @0D70: a8 42 00 01 42 00 99 41 01 40` = `give_item(1, 153,
   1)`; `Builtin_A8` passes `param_2[3]` to `SetItemCount`, tests it `< 2`, else clones `param_2[3]−1`
   records — a stale large value multiplies the item. `0C86 @005F: f0 30 41 42 41 05 40` =
   `queue_activity(A30, 66, 5)`; `Builtin_F0` passes `param_2[3]`, `param_2[4]` to `QueueActivity`
   unconditionally. Nothing in the interpreter clears popped slots (`*psVar7 = sVar14 + -1` only), so
   a replica must keep the 0x400-slot array semantics (no zeroing, no growable vector) to reproduce
   these six sites. Fix: add one §8 line.

5. **Minor / HIGH — §8 wording: "expression bytes 0x65–0x9A and 0xFF are the invalid-opcode
   error".** 0xFF is not: DoExpr default is `if (local_58 < 0xa0) { … FUN_100bdef4(_DAT_100ced08,…) }
   else { … FUN_100c50e8(&local_44,iVar20); }` — 0xFF indexes the builtin table (entry null,
   script-builtins.md) and calls through a null TVector. The tool counts 0xFF as unknown either way
   (harmless); fix the sentence.

6. **Minor / HIGH — census coverage buckets.** "statements reached … 379721" includes the 26,569
   bytes of 0x45 literal data (finding 1), because `coverage()` takes `set(r.owner)` first and
   `blk_owner − ins` second. The "0 undecoded" total is correct. Fix with finding 1.

7. **Note / MED — 0x9C FFFF with a non-routine target leaks a stack slot.** Both forms end with
   `*psVar7 = *psVar7 + (short)((int)uVar16 >> 2) + (…) + 1;` (DoInterpAt: `local_124 = iVar8 +
   *psVar7 * 4; _DoExpr…; … + 1; uVar16 = local_54;`), and DoExpr then *also* pushes `local_44`, so
   the statement form leaves one stale slot and the expression form grows the stack by two — unlike
   0x9D's non-object path, where only the expression form has the `+ 1` (it keeps the receiver as
   the result) and the statement form pops cleanly. §8 says "the args are popped and the target value
   itself is the result" — close for the expression form, silent on the leak. Unexercised by the five
   shipped computed calls. Decompiler-level evidence only (no PPC disassembler on this machine);
   verify from raw disasm before banking as engine behaviour.

8. **Note / HIGH — script-vm.md §4 row 0x9B** still reads "with class byte 0 no object is created …"
   with no pointer to §8's "expression form only"; a §4-only reader will mis-decode the ten statement
   sites (all classes 6/7/0A/0B/0F/10, confirmed by grep of the listings). Add a cross-reference.

9. **Note / HIGH — census §7 "never called statically"** mixes three cases: page 0x30 (native
   fallback `0x3000+sel` in `DoInterp0`) and page 0x09 (`EvaluateCondition`/`PerformAction`) are
   native-called; 0x0F03–0x0F10/0x0F14, 0x0E45–47/67/80/8E/91/92/94/A4/A7, 0x0D08, 0x0A00–07,
   0x0B00, 0x0814, 0x0C40–55 have no native literal `TInterp` constructor either (grep of
   `__ct__7TInterpFs(…,0x…)` finds none; the only literal `DoInterp` second arguments are selectors
   0x15/0x1C/…), so apart from the `R[0A00+…]`/`R[0C00+…]` computed bases they are dead in 1.0.4.
   Say so in the table.

10. **Note / HIGH — INDEX.md** has no pointer to scriptdis.py / script-census.md / §8 (the notes admit
    it). Add on the fix pass.

## Verified OK (do not re-check)
- **Reproducibility**: census and 958 listings regenerate byte-identically (0.28 s).
- **Hand decodes** (appendix) match the listings line for line: 0x1802 @0292–0303 and the iterator
  loop @04C3–050A, @0710–0730; 0x1809 whole (dictionary `a0 03 | 98 09 00 02 00 0c | Nil 02 3b | Nil
  00 00` → one method, sel 12 @0002; 10 distinct builtins, `jf`, `setfield f15`); 0x0803/0x0814 whole;
  0x0806 @0000–01B6 (keyword-response routine: `90 6e 69 63 61 00 00 3b` = match "nica" else →003B).
- **Classification**: every page-0x08/0x0A–0x0F segment starts `81`; 0x08 has 269 static 0x9F
  callers (`R0806(A30)` from 1832/1833/1834), 0x0D 90, 0x0E 367, 0x0F 636; 0x0A/0x0C reached through
  `R[0A00+A30.f03]` (101F) and `R[0C00+A31]` (3021). `PAGE_CLASS` agrees with `0x1000+class·0x20+id`
  for every page; labels 0x1802 "Alaric", 0x1809 "Ruins Guard", 0x1C2D room 301, 0x1A00 spell type 0;
  tile names: F000 type 1 → tile 0x011A ∈ F004 (0x0116,0x011E] "large city", type 5 → 0x040E ∈
  (0x040D,0x040F] "mousehole".
- **§8 corrections against the decompile**: (1) `GetString`: `for (; (*param_3 != 0 && (*param_3 <
  0x80)); …) return param_3;` and DoInterpAt `local_50[0] = (ushort *)_GetString…(param_2,pcVar9,
  puVar20)` — pc left on the terminator; 0 then hits `if (local_88 == 0) goto LAB_10080d6c`. (2) 0x8F
  `local_50[0] = (ushort *)(iVar19 + 1)`; 0x44 `uStack_50 = FUN_100b6ce8(*param_2)` (strlen to NUL:
  `do … while (*pcVar1 != '\0')`), `*param_2 = (int)(short)uStack_50 + *param_2 + 1`. (3) 0x88/0x8C/
  0x8D/0x90/0x89 all `(ushort *)(param_2[2] + (int)(short)local_64)`; 0x89 fall-through `local_50[0]
  + (short)local_64 + 1`; 0x9E `_DoInterpAt…(auStack_178,param_2,(int)(short)local_64,local_e4)` with
  `*param_2`/`param_2[1]` saved and restored. (4) 0x9B statement always `_CreateSysObj__FssP5VAddr
  (&local_54,(int)(short)local_64,nargs,local_b4)`; DoExpr `if (uStack_50 == 0) { _DoExpr…; int →
  push; else push low 16 }`. 0x9C seg≠FFFF: `local_64 = local_64 + (short)(int(pop))` then args;
  FFFF: tag 6 → `___ct__7TInterpFs(auStack_10c,(int)(short)local_54)`, tag −1 → `(…,local_54._0_2_ &
  0x7fff)` + `(int)(short)local_54`. 0x9D: `puVar21 = (uint *)(iVar8 + *psVar7 * 4); _DoExpr…; uVar16 =
  *puVar21;` receiver = first pushed; non-object statement form pops without `+1`. (5) 0x82: `if
  (local_88 < 0x30) … param_2[1] + slot*4` / `if ((0x2f < local_88) && (local_88 < 0x40)) … *param_2 +
  (slot−0x30)*4`, no else. 0x43 tag 1: `uVar17 = param_1[1] - iVar8; … + sVar18`. (6) `SetGlobal`: `if
  (param_1 != 0xd) { if (param_1 < 0xd) { if (0xb < param_1) → _DAT_100d73f0 clamped 0..100 } else if
  (param_1 < 0xf) → *(short *)PTR_DAT_100cdcf4 }` — only 0x0C/0x0E; `GetGlobal` has no case 0x11 →
  `default: *param_1 = *(uint *)PTR_DAT_100cdbb0` (Nil). (7) iterator bytes at 0x1802 @04C3/04D3/04F5
  reproduce exactly. (8) raw 0x0101 @0x880: `a0 7f 50 00 ff ff 00 00 50 00 ff ff ff ff 50 00 ff ff 00 00
  81 01 02 fc 30 22` (slot 3: value 810102FC "ToggleLock", key 3022); raw 0x0210: `90 01 82 10 00 06
  52 65 74 75 72 6e 00`; `GetEncryptedSegment` always `_LoadSegment… ; _Decrypt__8TSegFileFPvlUsl
  (*piVar3,uVar2,param_2,0)`. (9) 0x021A n=1141, 1055 Nil; 0x0221 entry 0 = 0x5000FFFF; 0x10C5 @003E
  `8a 43 30 00 02 21 30 62 07 4a 40`.
- **Operand sizes** 0x41 signed byte (`(int)cStack_57 & 0xfffffff`), 0x42 signed short, 0x60/0x62/
  0x63/0x64 one byte, 0x61 two bytes (DoExpr `case 99:`/`case 100:` are 0x63/0x64 — not missing).
- **Strings** (six non-empty refs, table bytes vs listing): 021B[0] @5A "Exploration of Seldane
  Ruins…", 021E[0] "zero", 0240[0] "It was another hot summer evening…", 0241[0] "Your body collapses
  …", 0242[0] "Your will is not left in your body…", 0243[0] "You awake, with a start…" — all match.
- **Unknown-opcode sweep**: no `??`, no `.odd`, no ANOMALY lines, 0 `undecoded` bytes in any code
  listing (the `??` hits in 0201.txt are the "???" character-name strings); the four "longer" dead
  runs are `8b 43 50 00 00 01 40`, two `return 0; goto`, and an orphan text `"Please come back later"`
  (1846 @1935). Every DisErr/IndexError path records an `unknown` entry and an anomaly; nothing is
  silently skipped except finding 1's rendering gap.

## Appendix — hand decodes (bytes from `seg.py dec()` this session)
**(a) 0x1802 @0292** `81 01 11` frame 1/17 · `42…6e` text "Before you stands an older, dignified
gentleman" (0295–02C3, ends at 0x82) · `82 00 9f 0f 02 30 41 01 40 40` L00 = R0F02(A30, 1) · `8d 00 5e
40 02 f8` jf !L00 → 02F8 · `2c…2e` ", but with a look of desperation." · `88 07 1c` goto 071C · 02F8
`8d dc 41 00 40 41 02 54 40 05 39` jf get_variable(0) == 2 → 0539. 071C `2a` "*" · `82 04 43 50 00 00
00 40` L04 = False · `8d 9f 0f 02 30 41 07 40 5e 40 0c 46` jf !R0F02(A30, 7) → 0C46. Loop 04C3 `82 01 a0
43 10 00 00 02 41 00 41 04 41 07 40 40` L01 = iterate_range(&L02, 0, 4, 7); 04D3 `8c a0 43 10 00 00 02
41 01 40 40 05 04` jt done → 0504; 04E0 `8d ee 43 00 00 02 00 43 30 00 02 42 01 4a 40 40 04 f5` jf
curtain_picture(512, str[0242:0] + L01) → 04F5; `88 05 04`; 04F5 next; `88 04 d3`; 0504 `e7 41 03 40`
screen_effect(3); `ed 40`; `a2 44 "You have damned Cythera to darkness." 00 40` end_game. **Matches.**

**(b) 0x1809** (char 9, dict @038C → sel 12 @0002): `81 01 02` · `8d dc 41 07 40 41 00 54 40 03 79` jf
get_variable(7)==0 → 0379 · `8d 48 00 41 08 4f 48 00 41 12 51 5d 40 01 0e` jf (hour<8 || hour>18) →
010E · "\"Excuse me, " · `8d 49 05 00 00 10 40 00 3c` jf seg0500[0010] → 003C · "ma'am" · `88 00 3f`
goto 003F (into the tail of "sir, but none are permitted…\"*") · `8d 48 00 41 08 4f 40 00 c9` · texts ·
`88 01 01` · 0101 `e9 40` end_talking · `bf 41 0e 41 1d 41 00 40` teleport(14,29,0) · `88 03 75` · 010E
text · `8d bc 42 00 4a 40 40 03 6b` jf leader_can_see(74) → 036B · `a4 42 00 4a 41 01 40` show_portrait
(74,1) · text · `a4 30 41 00 40` · text · `ea 40` · `82 00 30 62 01 40` L00 = A30.x · `82 01 30 62 02 40`
· `86 15 30 40 43 00 00 00 87 40` A30.activity = 135 · seven `f0 42 00 09 …` queue_activity(9, …) with
inline `44` strings · `f1 43 00 00 00 ff 40` wait_for_flag(255) · `eb 40` · text · `dd 41 07 41 01 40`
set_variable(7,1) · `8b 41 00 40` · dead `88 03 75` · 036B `e9 40`, teleport, 0375 return · 0379 "\"Good "
· `8a 43 20 00 00 01 40` print globstr(1) · ".\"" · return. **Matches, including the dead goto.**

**(c) 0x0803** `81 01 00 | 8b 43 50 00 00 00 40 | 8b 41 00 40` → return False (+dead return 0). **0x0814**
`81 01 00 | 8b 41 00 40 | 8b 41 00 40`. **0x0806** `81 01 00` · `90 6e 69 63 61 00 00 3b` match "nica"
else → 003B · "\"Watch your words about our noble House.\"" · `8b 43 50 00 00 01 40` return True ·
003B `90 61 74 74 69 00 00 73` "atti" → 0073 · … "thur" → 00B2 · "coma" → 00FA · "dodo" → 012A · "stry"
→ 018C · "atus" → 01B6 · 01B6 return False. A routine (frame, no dictionary) called `R0806(A30)` from
the House-member talk methods — "routine" classification confirmed. **Matches.**
