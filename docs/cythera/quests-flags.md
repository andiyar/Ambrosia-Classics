# Cythera 1.0.4 — quest flags and persistent game state

Register: **code reading**. Every claim carries HIGH (quoted bytecode or decompiled lines prove
it), MED (inferred) or LOW (conjecture). Sites are `segid@offset` in the `scriptdis.py` listings
(`ghidra/cythera-scripts/<segid>.txt`); native code is `function @ addr` in
`ghidra/Cythera_pef.decompiled.c` / `ghidra/Cythera_builtins.decompiled.c`. Character names come
from the 0x0201 string table (`ghidra/cythera-scripts/0201.txt`). Game text is quoted at most one
short line per entry, as evidence only.

---------------------------------------------------------------------------------------------
## 0. Scope, method, not read
- **Scope**: every store a script can change that outlives the call — the per-character bit
  byte (setbit/clrbit/tstbit), the 256 global flags, the 32 byte variables, globals 0x0C/0x0E,
  data-page words written by 0x85, the to-do list, the journal — plus the four `end_game` sites,
  the main chain, side-quest clusters, party join/leave, story teleports and time passing.
- **Method**: a stdlib Python pass over all 958 listings (this session) extracting every
  `R0F00/R0F01/R0F02/R0F13` call, every builtin DC/DD/DE/DF/F1/F2/F3/A2/BD/BF/B9/BA, every
  0x85/0x87 statement and every 0x49 read, with segment, enclosing method and offset; then
  reading the sites by hand, plus the native bodies of `GetField/SetField__Fsss`,
  `GetGlobal/SetGlobal`, `Builtin_DC..DF/F1`, `TToDo::*`, `TJournal::*`,
  `SaveEncryptedSegment`, the 0x85 path of `DoInterpAt`, `SaveToFile`'s 'Char' stream,
  `TeleportTo`, `RemoveAllAbility`. Data read with `tools/seg.py`: 0xF009 (initial CharEntry
  byte +8), 0xF00B (schedule conditions), 0xF00C (teleport targets), 0x8100+L (crystal props).
- **Not read**: the Cythera hintbook — **not present** in the installed folder (only a
  "Stuck_ Get the Cythera Hintbook" link file), so quest order below comes from code, not from
  the hintbook; the native activity interpreter (activities 164–167 — the `TActiveMonster`
  code between `QueueActivity @ 1004b824` and `GetCharacter @ 1004d704` is not decompiled);
  `TJournalList`/`TToDoList` drawing; heap per-instance frames (prop +0xC); the 0x10xx prop
  scripts beyond the sites named here; the 0x30xx fallback routines except where cited.
- Cited, not duplicated: `script-vm.md` (VM, §7 heap, §8 0x0101 helper names, globals),
  `script-builtins.md` (builtin bodies), `data-format.md` §5 / §6 / §7, `rules.md` §3
  (`EvalCondition`), `engine-classes.md` (`TJournal`, `TToDo` rows), `engine-classmap-2.md`
  (`TJournal` 6, `TJournalSegment` 7, `TToDo` 5 methods).

---------------------------------------------------------------------------------------------
## 1. The persistent stores at a glance

| store | where | script access | saved as | conf |
|---|---|---|---|---|
| per-character bit byte | CharEntry +8 (`PTR_DAT_100cdbf0[c*0x20+8]`), 512 chars | field 0x13 via setbit/clrbit/tstbit (0x0F00–02), inparty (0x0F13), direct `.f13` | 0xF009 (CharEntry table, `SaveGlobals`) | HIGH |
| 256 global flags | 8 u32 at `PTR_DAT_100cdbc0` | builtins DE test_flag, DF set_flag, F1 wait_for_flag | 'Char' stream 0x0400, 8 × "l" | HIGH |
| 32 byte variables | `PTR_DAT_100cdbbc` | builtins DC get_variable, DD set_variable | 'Char' stream, 32 × "b" | HIGH |
| global 0x0C (karma, 0..100) | `_DAT_100d73f0` | `48 0C` read / `87 0C` write, helpers 0F11/0F12 | 'Char' stream, 1st "h" | HIGH |
| global 0x0E (bit word) | `*(short*)PTR_DAT_100cdcf4` | `48 0E` / `87 0E` | 'Char' stream, 2nd "h" | HIGH |
| data-page words | segments 0x0301, 0x0500 (and 0x0501 read-only) | 0x49 read, 0x85 write | the segment itself, re-saved into the scratch overlay | HIGH |
| to-do list | `PTR_DAT_100cdf24`, 256 × 8 B | builtins F2 add_to_do, F3 done_to_do | segment 0x0401 (0x800 B) | HIGH |
| journal | `TJournalSegment` stream | **none** (no builtin reaches `TJournal`) | segments 0xE000+k | HIGH (no script path) |
| room visited bits | 0xF00E u16 per room, bit 0 | none (native `HeartBeat`) | 0xF00E | HIGH (data-format §5) |
| prop fields (frame, quality, kind, …) | prop table | `.fNN` 0x62/0x86 | level props 0x8100+L / 0xF306 | HIGH (data-format §4, §7) |

Evidence for the 'Char' stream order — `SaveToFile @ 10012f6c` writes, in order:
```
FUN_100c50e8(local_64,PTR_DAT_100ce360,(int)_DAT_100d73f0,(int)*(short *)PTR_DAT_100cdcf4,
             (int)_DAT_100d73f2,(int)_DAT_100d73f4);
for (sVar10 = 0; sVar10 < 0x20; sVar10 = sVar10 + 1) { FUN_100c50e8(local_64,puVar7,puVar1[sVar10]); }
for (sVar10 = 0; sVar10 < 8; sVar10 = sVar10 + 1) { FUN_100c50e8(local_64,puVar6,*(undefined4 *)(puVar2 + sVar10 * 4)); }
```
with `puVar1 = PTR_DAT_100cdbbc`, `puVar2 = PTR_DAT_100cdbc0`. So the first two of the four
`hhhh` values data-format §7 left unresolved are **karma (G0C)** and **G0E**; the fourth,
`_DAT_100d73f4`, is the next-serial counter of builtin F9 (script-builtins.md). [HIGH]
(`GetGlobal__Fs` case 0xc: `*param_1 = (int)_DAT_100d73f0 & 0xfffffff;` case 0xe:
`*param_1 = (int)*(short *)PTR_DAT_100cdcf4 & 0xfffffff;`.)

---------------------------------------------------------------------------------------------
## 2. The bit helpers 0x0F00–0x0F02 (setbit / clrbit / tstbit)

### 2.1 Exact arithmetic [HIGH]
```
0F00@0003: 82 00 30 63 40 40         set       L00 = as_char(A30)
0F00@0009: 86 13 00 40 00 62 13 …    setfield  L00.f13:flags = (L00.f13:flags | (1 << A31))
0F01@0009: 86 13 00 40 00 62 13 …    setfield  L00.f13:flags = (L00.f13:flags & ~(1 << A31))
0F02@0009: 8b 00 62 13 41 01 31 5a … return    ((L00.f13:flags & (1 << A31)) != 0)
0F13@0009: 8b 00 62 13 41 40 56 40   return    (L00.f13:flags & 64)
```
- Arg 0 is cast to a class-0x40 (character) object (`63 40`); arg 1 is the bit number k; the
  mask is `1 << k` — **bit k = value 2^k, LSB = bit 0**. tstbit returns True/False (0x53 `!=`).
- Field 0x13 of a character is **CharEntry byte +8**: `GetField__Fsss @ 100921b4`
  `case 0x13: *param_1 = (uint)(byte)PTR_DAT_100cdbf0[sVar4 * 0x20 + 8];` (class 0x40, index
  ≤ 0x200, else Nil). `SetField__Fsss5VAddr @ 10092bd4` `case 0x13: if (sVar11 == 0) return;
  *(char *)(puVar12 + 2) = (char)(…param_4…); … _RedoStat… _UpdateCharName…` — the write
  stores the low 8 bits, is **ignored for character 0**, and refreshes the status window and the
  conversation's displayed name.
- So the "flag array" is **one byte per character, 8 bits**, inside the CharEntry table — not a
  data page, not a global, not the heap. It is saved with CharEntry (0xF009, data-format §7
  step 1). A bit number ≥ 8 shifts out of the byte and is lost (no shipped call uses k > 7:
  bit census 0:53 1:154 2:84 3:36 4:21 5:6 6:1 7:205 over 560 calls). [HIGH]
- Call counts (all listings): setbit 246, clrbit 17, tstbit 297, inparty 64. [HIGH]

### 2.2 Bits with an engine meaning
| bit | mask | meaning | evidence | conf |
|---|---|---|---|---|
| 6 | 0x40 | **party member** | `RebuildParty` / `GetField` readers (data-format §6.1); 0F13 `inparty` = `flags & 64`; setbit never targets bit 6 (only 0C80@001D tests it) — joining goes through B9/BA, which also call `RebuildParty` | HIGH |
| 7 | 0x80 | **name known** (scripted name shown) | `GetCharacterName @ 10007d40` `(PTR_DAT_100cdbf0[(short)param_1 * 0x20 + 8] & 0x80) != 0`; scripts set it on the "name" keyword, e.g. 184A@0A4E `match name,timo` → 0A75 `R0F00(A30, 7)`; `setbit(A30, 7)` occurs 114× | HIGH |
| 0–7 | — | **schedule condition bits**: `EvalCondition` cond 0x40–0x5F / 0x60–0x7F tests "byte +8 bit b" for b < 8 (rules.md §3.3) — schedules read the same bits scripts set (§2.4) | HIGH |
| 0–7 | — | **ability ids 0–7 alias these bits**: `RemoveAllAbility__8TSpellFXFs @ 10057080` `if (*(short *)(local_88 + 0xe) < 8) { puVar4[*psVar5 * 0x20 + 8] = … & ~(byte)(1 << …); }` — an ability with id < 8 clears the same byte. Shipped scripts use ids 0–2 only on character 0 (`temp_ability(0, 0|1|2, …)` in 0x1A02/0x1A0C/0x1A10/0x1A25), which no story site reads | HIGH code / MED "no collision" |

### 2.3 Bits 4 and 5 — ambient-behaviour latch [MED]
0C84 and 0C85 do `R0F00(A30, 4)` / `R0F00(A30, 5)` then
`queue_activity(A30, 166, A30, 4|5, False)`. They are called only from the selector-32
(`spawned`) methods of 1834 Ascalon, 1837 Tlepolemus and 1865 Thersites, behind
`jf ((random(0, 40) == 1) && !R0F02(A30, 4))` (1834@0012) or `jf ((random(0, 10) == 1) &&
!R0F02(A30, 5))` (1834@008E, 1837@0012, 1865@0018). Activity 166 with operands (char, bit, False)
reads as "clear that bit when the queued chatter completes" — a busy latch for idle chatter.
For other characters bits 4/5 are ordinary story bits (Crito 4, Apis 4/5, Halos 4, Sacas 4).
The native handler for activities 164–167 is **not traced**.

### 2.4 Schedules that read story state (0xF00B, all 617 entries scanned)
| cond, arg | reading (rules.md §3.3) | characters gated | conf |
|---|---|---|---|
| 0x03, 0 | global flag 0 clear | 2 Alaric, 3 Magpie | HIGH |
| 0x40, 13 | char 13 bit 0 set | 13 Pelagon | HIGH |
| 0x41, 75 | char 75 bit 1 set | 75 Prusa (bit set by Itanos 1849@0A24) | HIGH |
| 0x42 / 0x62, 32 | char 32 bit 2 set / clear | 32 Ake | HIGH |
| 0x81, 0/1/3 | var 1 == 0 / 1 / 3 | 53 Ariadne / 92 Eudoxus / 50 Philinus | HIGH |
| 0x82, 10 | var 2 == 10 | 71 Metopes | HIGH |
| 0x83, 0/1/3 | var 3 == 0 / 1 / 3 | 51 Opheltius (7 entries) / 62 Halos, 98 Dryas / 13 Pelagon | HIGH |
| 0x84, 0/5 | var 4 == 0 / 5 | 109 Demodocus | HIGH |
| 0x87, 0 | var 7 == 0 | 9 Ruins Guard | HIGH |
| 0x89, 0/1/2 | var 9 == … | 34 Meleager, 109 Demodocus | HIGH |
| 0xA1, 7 / 0xA3, 2 | var 1 ≥ 7 / var 3 ≥ 2 | 94 Antiphus / 10 Myus, 11 Naxos, 12 Darius | HIGH |
| 0xE1, 3/7 · 0xE2, 10/11 · 0xE7, 3 | var 1 < 3 or < 7 · var 2 < 10 or < 11 · var 7 < 3 | 50, 53, 94 · 60, 61, 74 · 9, 90, 91 | HIGH |
So NPC placement is driven by the same variables and bits as dialogue: a replica must evaluate
schedules against live script state, not a snapshot. [MED]

### 2.5 Initial values (0xF009 byte +8, shipped data)
Only three characters start non-zero: 1 Hero = 0xC0 (party + name known), 94 Antiphus = 0x01,
190 "Door" = 0x80. [HIGH — `tools/seg.py` scan this session] Antiphus bit 0 is tested by Sacas
(1846@0127) and never set by any script, so it is data-seeded state. [HIGH]

---------------------------------------------------------------------------------------------
## 3. Flag catalogue — character bits 0–5

Sites: `S` set, `C` cleared, `T` tested. A bare site is in the character's own segment
(0x1800+id) with `A30` = the receiver; `[x]` names the foreign segment or character making the
call; `?` = inside a local subroutine (A30 = the sub's own arg, MED). Meaning is MED unless a
quoted line or a to-do/variable op at the same offset proves it (then the evidence is named).
Bit 7 (name known) and bit 6 (party) are in §2.2 and not repeated. 4 calls pass a non-constant
character (0C80@001D/00B1 `L00`, 0C84/0C85 `A30`) — §2.3.

| char | bit | S / C | T | reading (evidence) | conf |
|---|---|---|---|---|---|
| 1 Hero | 0 | — | 1801@017A (death: → `R301D(A30)`) | never set: the 301D death path is dead in shipped data | HIGH |
| 2 Alaric | 1 | S [1025 crystal]@045E | 1802@02C4 | **cured** — set beside `done_to_do(0)` 1025@0441; gates the ending (§5) | HIGH |
| 2 Alaric | 2 | S 1802@262B | 1802@1F33/23F7/25EA/2705, [Anisa]184D@10BE | topic told (Anisa's "Alaric's mother" quest) | MED |
| 3 Magpie | 1 | — | 1803@078B/0907/0B46/0BE5 | never set by data or script — those branches always take the clear path | HIGH |
| 3 Magpie | 2 | S 1803@1003 | 1803@0D4F | conversation step | MED |
| 4 Hadrian | 0,1 | S 1804@0572, [Hector]1806@0D33 (0); [Hector]1806@0C79 (1) | 1804@0412/04BF, [Hector]1806@0C15 | Hector's departure with Hadrian's leave (set beside `join_party(6)` 1806@0D3C) | MED |
| 4 Hadrian | 2,3 | S 1804@0406, 1804@0964 | 1804@0195, 1804@079A | flowers-for-the-grave thread (to-do 33 added 1804@090D) | MED |
| 6 Hector | 0 | S 1806@0D2A/0DBA | [Hadrian]1804@024F, 1806@0D4A | has joined once (beside `join_party(6)`) | HIGH |
| 13 Pelagon | 0 | S 180D@01B5 | 180D@01A1; schedule 0x40/13 | **confrontation done** — `jf ((get_variable(3) == 3) && !R0F02(A30, 0))` then set | HIGH |
| 13 Pelagon | 1 | S 180D@0C2B/0C8F | 180D@0B88, [zone 1]1401@002B | told Stentor's "you are dead" story (needs Stentor bit 2) — one input to var 3 := 1 | HIGH |
| 17 Ennomus | 1 | S 1811@0445 | 1811@0028 | conversation step (same method calls deckarma/inckarma 1811@0262/02B2) | MED |
| 20 Thuria | 1 | S 1814@0B0B | 1814@00BF/07FC, [Amphidamas]1817@0300, [Atymnius]181D@0086, [Demodocus]186D@01EA/0337 | **iron-mine quest given** (beside `add_to_do(14)` 1814@0AFF) | HIGH |
| 20 Thuria | 2 | S 1814@02F1 | 1814@00BF | iron mine resolved (beside `done_to_do(14)` 1814@02ED) | HIGH |
| 23 Amphidamas | 1 | S 1817@06A1 | 1817@030D/068D, [Thuria]1814@03FD/07AF | mine-haunting thread | MED |
| 29 Atymnius | 1 | S 181D@0314 | 181D@0262, [Thuria]1814@04CF, [gossip]0813@0153 | mine-haunting thread | MED |
| 30 Milcom | 1 | S 181E@0503 | 181E@0492 | "Find Eioneus" step (to-do 30 added 181E@0654) | MED |
| 32 Ake | 1 | S 1820@0041/06E9 | 1820@0503/0588, [Halos]183E@0AFC/0CCE | told the Comana rumour (beside `add_to_do(10, …)` 1820@0101/07D9) | HIGH |
| 32 Ake | 2 | S 1820@0677; C 1820@003A/06E2 | 1820@0025; schedule 0x42/0x62 | moves Ake (schedule) | HIGH |
| 33 Neoptolemus | 0 | S 1821@0EEC | 1821@0455/0531/05F0/0F03 | conversation step | MED |
| 34 Meleager | 0 | S 1822@0A1D | 1822@06E7/0BE1 | **hired** (beside `join_party(34)` 1822@0A18, after a pay step `R0D05(50|35)`) | HIGH |
| 34 Meleager | 1 | S [Sabinate]1878@00BD, [Jhiaxus]1879@00BD | 1822@0121/0C94 | met the Seldane while in the party (`jf R0F13(34)` just before) | HIGH |
| 35 Hebe | 1,2,3 | S 1823@00D5 / 02C1 / 0199 | 1823@0063/01C5, [Antenor]1824@01C5, [Crito]1829@0483 | Hebe–Antenor–Crito thread | MED |
| 36 Antenor | 1,2 | S 1824@0269 / 050D | 1824@0169/0280, [Hebe]1823@01C5 | same thread | MED |
| 37 Alastor | 1,2 | S 1825@070A/0786 (1), 0711 (2); C 1825@0314 (2) | 1825@043D (1), 02A7/0802 (2) | **gator-skin quest** given (to-do 31 added 1825@0718) / delivered (`done_to_do(31)` 1825@031B beside the clear) | HIGH |
| 39 Eioneus | 1 | S 1827@067B; C 1827@0148 | 1827@08EA | cleared beside `done_to_do(30)` 1827@0144 ("Find Eioneus") | HIGH |
| 40 Parium | 0,1 | S 1828@01C9 (0), 027E (1); C 1828@0285 (0) | 1828@00B7/01D0 | inn talk state | MED |
| 40 Parium | 2 | S 1828@05F5; C 1828@00A9? | 1828@02DD/066B | **room paid** — next op 1828@05FC `gstore seg0301[0016] = 2` (§4) | HIGH |
| 41 Crito | 0,1,3,4 | S 1829@02EC (0), 03A1 (1), 079D (3), 0525 (4); C 1829@03A8 (0) | 1829@01F4/02F3/044F/06B2/06BD, [Hebe]1823@011E | inn talk / Hebe thread | MED |
| 41 Crito | 2 | S 1829@0945; C 1829@00A8? | 1829@0400/09BB | room paid (1829@094C `gstore seg0301[0016] = 1`) | HIGH |
| 42 Apis | 2 | S 182A@03D2/07DB; C 182A@00A7? | 182A@00B5/0851 | room paid (182A@07E2 `gstore seg0301[0016] = 3`) | HIGH |
| 42 Apis | 3,4,5 | S 182A@04E0 (3), 02C8 (4), 02D8 (5) | 182A@01BF/0490/0104, [Periphas]1841@0151 | flour / wine-contract steps (to-do 16/17, 182A@0542/0376) | MED |
| 50 Philinus | 0,1 | S 1832@0D69 (0), 0EF9 (1) | 1832@0C5D, [Tlepolemus]1837@058B | Philinus–Tlepolemus thread | MED |
| 51 Opheltius | 1 | S 1833@030C/03B4 | 1833@0093/00ED/0202/03D0 | conversation step (combined with flag 3 at 1833@0093) | MED |
| 52 Ascalon | 4,5 | — | 1834@0012, 008E | ambient latch (§2.3) | MED |
| 55 Tlepolemus | 1,2 | S 1837@071F (1), 068C (2) | 1837@053F, [Philinus]1832@0E1F/0D85 | Philinus–Tlepolemus thread | MED |
| 55 Tlepolemus | 0,5 | — | 1837@07AD (0), 0012 (5) | 0 never set (open); 5 ambient latch | MED |
| 60 Propontis | 1 | S 183C@05F3 | [Halos]183E@0AFC/0D61/0E34 | sent to Halos (beside `add_to_do(10, title 113)` 183C@05E7) | HIGH |
| 61 Mantinea | 1 | S 183D@02A2 | [Halos]183E@15A8, [gossip]0813@00CB | conversation step | MED |
| 62 Halos | 1,2,4 | S 183E@0D42 (1), 0DED/0EC0 (2), 102C (4) | 183E@09BE/0AFC/0CDB/0D6E/0E41/0EEF/103E/1385/1408, [zone 1]1401@002B | **Comana question answered**, three variants — each beside `done_to_do(10)` (183E@0D3E/0DE9/0EBC/1028); any of them + Pelagon bit 1 lets zone 1 set var 3 := 1 | HIGH |
| 62 Halos | 3 | S 183E@1793/17A7 | 183E@17E3, [Aethon]1861@039E | Kesh/Aethon thread (Aethon's join gate, §8) | MED |
| 65 Periphas | 1 | S 1841@01FF | 1841@0151 | flour handed over (beside `add_to_do(16, title 116)` 1841@01F3) | HIGH |
| 69 Dymas | 1 | S 1845@0238 | 1845@01D1 | conversation step | MED |
| 70 Sacas | 0 | S 1846@1349; C 1846@0608 | 1846@011C/0AF5/1037/14D1/1567, [Thersites]1865@092E | **interrogation assigned** (beside `add_to_do(4)` 1846@1350; cleared beside `done_to_do(4)` 1846@0616) | HIGH |
| 70 Sacas | 1 | S 1846@060F | 1846@0AD3/0BF9/0FC7, [zone 1]1401@005C, [Lindus]1850@0EAC, [Palaestra]1852@0958, [Thersites]1865@0A14 | **bandit interrogated** (beside `done_to_do(4)` / `add_to_do(36)` 1846@05F4); gates var 1 := 6 | HIGH |
| 70 Sacas | 2,3,4 | S 1846@084C (2), 0D63 (3), 0F52 (4) | [Lindus]1850@0F54 (2), 1846@0C81 (3), 0D6A (4) | Kesh investigation steps; bit 4 beside `done_to_do(36)` 1846@0F4E | HIGH (4) / MED (2,3) |
| 72 Berossus | 1 | S 1848@1471 | 1848@1635/16A2/1746, [Eteocles]1838@0A9B | murder-weapon step (Eteocles then sends you to Dryas) | MED |
| 73 Itanos | 1,2 | S 1849@06F8 (1), 0BC2 (2) | 1849@05AB, [Stentor]186C@0267 (1); 1849@0A3D (2) | net-for-Stentor / Prusa steps (to-do 35 1849@0684, 15 1849@0A18) | MED |
| 74 Timon | 1 | S [Sabinate]1878@0041, [Jhiaxus]1879@0041 | 184A@048D, 1878@002D, 1879@002D | **has met a living Seldane** (1878@0051 text) | HIGH |
| 74 Timon | 2,3 | S [room 301]1C2D@0124 and 1C2D@01A0 (both bit 2) | 1C2D@008E (2), 1C2D@0130 (3) | one-shot remarks in room 301; the second branch tests bit 3 but sets bit 2 (`1C2D@0130 jf (… !R0F02(74, 3))`, `1C2D@01A0 call R0F00(74, 2)`), so bit 3 is never set and the second remark repeats on every entry — original data bug, replicate | HIGH bytes / MED "bug" |
| 75 Prusa | 1 | S [Itanos]1849@0A24 | schedule 0x41/75 | **Prusa placed** (beside `add_to_do(15)` 1849@0A18) | HIGH |
| 75 Prusa | 2 | S 184B@069B | 184B@05DA | conversation step | MED |
| 77 Anisa | 1,2 | S 184D@199D (1), 1646 (2) | 184D@107E, 102C | mother quest given (beside `add_to_do(32)` 184D@1991) | HIGH (1) / MED (2) |
| 78 Pheres | 1,2 | S 184E@09C5 (1), 0226 (2) | 184E@0162/07D5, 0162/07AF | harpy egg asked (`add_to_do(29)` 184E@09CC) / delivered (`done_to_do(29)` 184E@0245) | HIGH |
| 79 Charax | 1–4 | S 184F@01BC, 0A6F, 0C2C, 04C1; C 184F@04CA (3) | 184F@01CC/08FE/0360/089C | timeflux book / kelp steps (to-do 12/13) | MED |
| 81 Selinus | 2 | S 1851@05A7 | 1851@021B/05B1 | books quest given (beside `add_to_do(18)` 1851@059B) | HIGH |
| 82 Palaestra | 0 | S 1852@0874/0944 | [Charax]184F@0D2A | conversation step | MED |
| 89 Niobe · 95 Polydamas · 97 Aethon · 103 Borus · 109 Demodocus · 122 Unhayt | 1 · 1 · 1 · 1 · 0 · 1 | S 1859@00F1 · 185F@0737 · 1861@0454 · 1867@04D2 · 186D@09A1 · 187A@02BA | own segment | conversation steps; Aethon's is the join gate (§8) | MED |
| 94 Antiphus | 0 | data-seeded (§2.5) | [Sacas]1846@0127 | unknown seed meaning | MED |
| 94 Antiphus | 1 | S 185E@02AC | [Sacas]1846@016E | told his story (beside `set_variable(1, 5)` 185E@02B3) | HIGH |
| 98 Dryas | 0,1 | C 1862@00B3/0448/0916 (0); S 1862@0125/0988 (1) | 1862@004A (1) | 0 cleared each time he joins (beside `join_party(A30)`); bit 0 is never set — dead clears | HIGH |
| 101 Thersites | 0 | S 1865@0A0A, [Sacas]1846@120D | 1865@00A7/03C5/093B, [Sacas]1846@1567 | Thersites–Sacas link | MED |
| 101 Thersites | 1,2 | S 1865@0526 (1), 02D9/0622 (2) | 1865@01C2/03C5 | ring quest given (`add_to_do(34)` 1865@052D) / ring returned (`done_to_do(34)` 1865@02D5/061E) | HIGH |
| 104 Briseis | 1 | S [Borus]1867@034F | 1868@0166/02D0 | Borus–Briseis link | MED |
| 108 Stentor | 1,2,3 | S 186C@02DE (1), 0A62 (2), 01B9 (3) | 186C@03DB/0633, [Pelagon]180D@0B7B/0C42 (2), [Berossus]1848@0E3D/0EF8 + 186C@003E/05E5 (3) | bit 2 = told the Pelagon story; bit 3 = interviewed (Berossus's to-do 37) | MED |
| 120 Sabinate | 1 | S 1878@0FA2; C 1878@0178 | 1878@0161/0B6F, [crystal]1025@013A | **Maayti quest active** (beside `add_to_do(7)`/`add_to_do(8)` 1878@0FAB/0FB7) | HIGH |
| 120 Sabinate | 2 | S [crystal]1025@01D6 | 1878@0161/02F6/05F4/0983/0A19/0B01, 1025@013A | **Maayti freed** — set when the frame-3 crystal is picked up with bit 1 set, beside `done_to_do(7)` 1025@01F2 | HIGH |
| 120 Sabinate | 3,4 | S 1878@0589/0AE5 (3); 4 never set | [Magpie]1803@0AA5/0C8B (3), 1878@0847 (4) | Magpie comments on it; bit 4 open | MED |
| 121 Jhiaxus | 1 | S 1879@084A; C 1879@028D | 1879@01AD/02ED, [prop 0x10E7]@00B3 | Jinrai task active; cleared beside `done_to_do(9)` 1879@0280 | HIGH |
| 121 Jhiaxus | 2 | S [prop 0x10E7]@00EC | 1879@0212, 10E7@00C0 | the Jinrai honour act done (prop deleted, exp 50) | MED |
| 121 Jhiaxus | 3,4 | S 1879@0284 (3), 0511 (4) | 1879@031C/044E/04DD/0809 (3), [Magpie]1803@0CC6 (4) | bit 3 = Jinrai honoured (beside `done_to_do(9)`) | HIGH (3) / MED (4) |

---------------------------------------------------------------------------------------------
## 4. Other persistent state

### 4.1 Global flags (DE/DF/F1) — bit layout [HIGH]
`Builtin_DF @ 100990cc`: word `(n >> 5)`, bit `1 << (n & 0x1f)` of `PTR_DAT_100cdbc0`
(`*(uint *)(PTR_DAT_100cdbc0 + iVar1) | 1 << ((int)sVar3 & 0x1fU)`), set/clear by `IsTrue(v)`;
`Builtin_DE` the same test. Flag n = bit n&31 (LSB first) of big-endian u32 word n>>5 — the
layout `EvalCondition` cond 2/3 reads and the 'Char' stream saves.

| flag | set | tested | reading | conf |
|---|---|---|---|---|
| 0 | 1802@0790 `set_flag(0, True)` (Alaric's opening audience, right after the 1802@0756–078D loop of `create_prop(28, …)` — kind 0x1C skill props given to the leader) | schedule cond 0x03/0 of Alaric and Magpie | **intro over** — moves Alaric and Magpie | HIGH |
| 1 | 1850@01EF (Lindus, beside `done_to_do(2)` 1850@01F8) | 1850@00D2/0E0A | **magic learnt at the Magisterium** (to-do 2) | HIGH |
| 2 | **never set** | 184A@0F93 (Timon's Metic topic) | dead branch: the "we've met them" line never plays | HIGH |
| 3 | 1864@05EB (Gate Guard, after the "slain in battle" exchange; `set_variable(1, 4)` 05E5) | 1832/1833/1834/1846/185E/1864/1865 (16 sites) | **Ariadne died** (corpse item 3150, quality 53, tested 1864@0527) | HIGH |
| 4 | 1838@05CD (Eteocles, after `give_item(1, 2114, 0, 0)` "key to the sewers") | 1838@02DC/06A9/07C6/0C65/0D2F | **joined the sewer guild** | HIGH |
| 15 / 16 / 17 | zone 0x17 @0031 / class 0x28 #2 (0x1502) @002A / zone 0x1D @0038 | same sites | one-shot "first entry" guards (16 and 17 also queue visions 6 and 7, §6) | HIGH |
| 64 / 65 | crystal 1025@066B / 1025@0591 (=1) and 059A (=0) | not tested by script | crystal opened a hole (64); toggled a cave entrance (65) — read natively? not traced | MED |
| 66 | Itanos 1849@0241 (topic "idom") | room 454 (0x1CC6@0005) | Idomeneus told — unlocks room 454's event | MED |
| 253 / 254 / 255 | activity 165 only: `queue_activity(c, 165, 253|254|255, 1, Nil)` ×10 | `wait_for_flag` 1802@1502/1599/1711, 1809@02F3, 184F@056C, 1AFE@012B | **cut-scene sync**: the script queues a walk then activity 165 (flag, 1), and `wait_for_flag` spins `TActiveMonster::Guide` until it is set (script-builtins F1; it clears the flag before and after). Activity 164 (flag, 0) appears beside them (wait-for-flag inside the actor queue?) | HIGH bytes / MED activity semantics |

### 4.2 Byte variables (DC/DD) [HIGH layout]
`Builtin_DD @ 10098ff8`: `PTR_DAT_100cdbbc[int(a0)] = (char)int(a1)` — no bounds check, the value
is truncated to a byte (`set_variable(12, True)` stores 1; a Nil would store 0xFF). Variables
used: 0–16 (17 of 32). Chains in §5–§7.

| var | writers (value) | readers | reading | conf |
|---|---|---|---|---|
| 0 | crystal 1025@0458 (1), 1025@044F (2) | Alaric 1802@02F8 `== 2` | **ending**: 1 = good, 2 = damned (§5) | HIGH |
| 1 | 1864@010F (1), 185C@0010 (2), 1835@0096 (3), 1832@00E0 / 1864@051A / 1864@05E5 (4), 185E@02B3 (5), zone 1 1401@0071 (6), zone 2 1402@006A (7) | 23 sites + schedules | **Ariadne chain** (§7.1) | HIGH |
| 2 | crystal 1025@0095 (10), Metopes 1847@043E (11), Lindus 1850@07EE/0A2B (12), Timon 184A@09F6 (13) | 17 sites + schedules | **crystal chain** stage (§5) | HIGH |
| 3 | zone 1 1401@0056 (1), Berossus 1848@0A1C (2), Berossus sub 1848@01DD (3) | 62 sites + schedules | **Opheltius murder / House Comana chain** (§7.2) | HIGH |
| 4 | 080A@0016 (1), 1829@0B73 (1), 080B@00F5 / 1828@0823 (2), 080E@0C85 (3), 080D@0601 (4), 1401@008D (5), 080C@0084 / 184C@059F (6), 1401@009E / 186D@0B69 (7) | 27 sites, schedule 0x84 | **where is Demodocus** — town gossip routines 080A–080E (topic `demo`) pass the bard's trail along (§7.3) | MED |
| 5, 6 | Selinus 1851@036A (`var5 + 1`), 1851@03C2 (`var6 + 1`) | 1851, metal door 0x1114@0149–01B9 (`var6 >= 1..5`) | books returned (to-do 18 + var 5 picks titles 18–28); var 6 = Degree-Hall passwords given — the door accepts password k only when `var6 >= k` | HIGH |
| 7 | Ruins Guard 1809@035E (1), Larisa 185A@047A (2), Timon 184A@0690 (3) | 1809, 184A, 185A, room 301 | **Seldane-ruins / Larisa chain** | HIGH |
| 8 | Alastor 1825@0387 `= (G0F:day + 1) + random(1, 3)`, 1825@01FF (0) | 1825@004A `get_variable(8) > G0F:day` | gator-boots ready day; stored in a **byte**, so from day ≈ 252 on the comparison wraps — replicate | HIGH code / MED consequence |
| 9 | bridge zone 0x26 @0049 (1), @0067 (2), @0070 (99) | schedules 0x89 (Meleager, Demodocus) | bridge encounter state with Meleager (`R0F02(34, 7)`, `R0F13(34)`, odd day) | MED |
| 10 | brazier 0x113F@00AA (quality), @00B4 / @00DC (0) | 0x113F@0025 | brazier lighting order puzzle: correct when `quality == var10 + 1`; 10 reached prints the riddle | HIGH |
| 11 | zone 1 1401@00BC (1), Cademia 1408@0038 (1), Hero signal 1801@11FE (2), 1801@1376 (4) | 1401@00A4 `== 0`, 1408@0020 `== 2` | **vision sequencer** (§6) | HIGH |
| 12–16 | liquid 0x112A@0075/009F/00B5/00DF/0109 (True per quality 1–5), staff 0x1136@01D8 (14) | Sacas 1846@061A/0671/0730/07E8/0C81/0D6A/0DE2 | Kesh samples analysed (one per liquid quality) | MED |

### 4.3 Globals 0x0C and 0x0E [HIGH]
`SetGlobal__Fs5VAddr @ 10093a5c` stores only g 0x0C (clamped `if (_DAT_100d73f0 < 0) … = 0; if
(100 < _DAT_100d73f0) … = 100;`) and g 0x0E; every other 0x87 is a no-op (the six `87 11` writes
in 1801/1802 are dead — script-vm §8).
- **G0C = karma, 0..100** (helpers 0F11 deckarma / 0F12 inckarma, script-vm §8). Init 55
  (1801@00CD `setglobal G0C = 55`). Raised by quests: crystal +10 (1025@0122, 01DF), flowers +5
  (103C@0067), Philinus +10 (1832@0036), Thersites +5 (1865@02B8), Stentor +5 (186C@0345);
  Ennomus 1811@0262 `R0F11(1)` / 02B2 `R0F12(L01 / 10)` and Eumelus 185D@008D/00DD the same.
  On a kill by the Hero, 0E8D@00C9 adds `[1, 4, -10, 0][victim.f35]` (inline block 0E8D@00B6;
  read as alignment neutral/evil/good/feral — MED). Hero's signal with `A31 == 256` lowers it by
  1 in a zone lacking property 36 (1801@18B4–18D1; what sends 256 not traced, MED). Read:
  `> 45` lets the amulet revive the Hero (1801@020C), `> 50` at Alaric 1802@0D3E, `< 40` makes the
  Seldane refuse you (1878@0109, 187A@00C5, 187B@00C2, 187C@00C4).
- **G0E bit 0** = Sabinate's blessing: set 1878@0E2F `setglobal G0E = (G0E | 1)`; tested by
  Jhiaxus 1879@00C6, Unhayt 187A@002D, Seqedher 187B@002D, Uset 187C@002D (`(G0E & 1) == 0`).
  No other bit used. [HIGH bytes / MED meaning]

### 4.4 Data-page words (0x49 read / 0x85 write) [HIGH]
0x85 writes into the segment and re-saves it: `DoInterpAt` `*(uint *)(local_8c + local_68) =
local_54; … _SaveEncryptedSegment__15TCachedSegFilesFUsPvl(*_DAT_100cdbc4,local_64,local_8c,
uVar12);` and `SaveEncryptedSegment @ 1007d898` → `_SaveSegment__8TSegFileFUsPvl(*(… param_1 + 4)
…)` — the top overlay (the scratch file), which `SaveToFile` copies into the save. So these
words persist like save data.
| word | writes | reads | reading |
|---|---|---|---|
| 0500:0010 | Hero init 1801@000A `gstore seg0500[0010] = A31` (the creation arg) | 30× `jf seg0500[0010]` in NPC talk, e.g. 1809@002B → text "ma'am" | **player is female** (also picks hero tile 33 vs 32, 1801@0011–0045) | HIGH |
| 0301:0016 | inns: Crito 1829@094C (1), Parium 1828@05FC (2), Apis 182A@07E2 (3); bed 100E@039D (0) | bed 100E@0079/0390 `A30.f06:quality != seg0301[0016]` → "You need to pay the innkeeper first." | **rented inn bed id**, cleared after sleeping | HIGH |
| 0301:0012 | none | bed 100E@00AF `seg0301[0012][seg0301[0016]]` | pointer to the array @0000 `[2, 3, 1, 1]`, a per-inn sleep parameter passed to 0E93 | MED |
| 0501:0110 | none | 1801@0062, 1802@0731 | archetype stat table (read-only, not story state) | MED |

---------------------------------------------------------------------------------------------
## 5. Main quest chain (Alaric / the crystal) and the end_game sites

Order read from the variable writers and to-do slots (no hintbook available — §0). [MED order /
HIGH per step]
| step | site | state change |
|---|---|---|
| 1 | Alaric 1802@0790 / 0C3A / 1430 | flag 0 set; `add_to_do(0)` "Cure Alaric"; `add_to_do(2)` (learn magic) |
| 2 | Lindus 1850@01EF | flag 1; `done_to_do(2)` |
| 3 | pick up crystal frame 0 (1025@0083) | `(A30.f03:frame == 0) && (get_variable(2) < 10)` → var 2 := 10, exp 50, karma +10, vision 1 |
| 4 | Metopes 1847@043E–0448 | var 2 := 11; `done_to_do(3)` (plague), `add_to_do(5)` "Show Crystal to Lindus" |
| 5 | Lindus 1850@07EE / 0A2B | var 2 := 12; `done_to_do(5)`, `add_to_do(6)` "Take Crystal to Timon" |
| 6 | Timon 184A@0743–09F6 (needs `get_variable(2) >= 12`; the crystal check never fires, see below) | `done_to_do(6)`; `give_item(1, 1061, 0, 0)` = crystal frame 1; var 2 := 13 |
| 7 | Sabinate 1878@0FA2–0FB7 | bit 120.1; to-do 7 "Free Maayti", 8 |
| 8 | Jhiaxus 1879@0280–028D | `done_to_do(9)`; bit 121.3 |
| 9 | pick up crystal frame 3 (1025@013A) with 120.1 set and 120.2 clear | bit 120.2; `done_to_do(7)`; karma +10 |
| 10 | Pelagon 180D@0A4D (var 3 == 3, fight path) | `give_item(1, 2085, 0, 0)` = crystal frame 2 |
| 11 | combine (1025 use_on @0223): frames 0+1 → 4 (vision 8), 4+2 → 5, 5+3 → 6 (vision 3) | `setfield A30.f03:frame = 4/5/6`, `delete_prop(A31)` |
| 12 | use the frame-6 crystal on prop type 34 (1025@0396–045E) | `done_to_do(0)`; var 0 := 2 if crystal quality ≠ 0 else 1; **setbit(2, 1)**; exp 100; Alaric's activity := 150 |
| 13 | talk to Alaric (1802@02C4–06E3) | bit 2.1 set → ending by var 0 |

**Dead crystal checks** [HIGH]: 184A@0748 `jf (who_in_party_has(37, 0) == -1) -> 07CD` and
1850@02E5 `set L05 = (who_in_party_has(37, 0) != -1)` compare with −1, but `Builtin_AE`
returns **Nil** when nothing matches (`*param_1 = *(uint *)PTR_DAT_100cdbb0;`) and `IsEqual @
10080adc` compares raw VAddrs (`return param_2 == param_1;`) — the pushed −1 is the tag-0 integer
`(int)cStack_57 & 0xfffffff` = 0x0FFFFFFF, never 0x5000FFFF. So Timon's "That's odd …" refusal
(184A@0755) is unreachable and Lindus's L05 is always True: replicate. (AE also matches the
frame — item 37 = frame 0 only.)

Item codes are `type | frame << 10` (script-builtins §0): 1061 = 0x425, 2085 = 0x825, 6181 =
0x1825 = type 37 frames 1, 2, 6. [HIGH] Type 34 is Alaric's CharEntry type (data-format §6.1
worked decode `0x2422 & 0x3FF = 34`). [HIGH]

**The four `end_game` (A2) sites** [HIGH bytes / MED readings]
| site | condition | evidence |
|---|---|---|
| 1802@06E3 good ending | Alaric talk, `R0F02(A30, 1)` true and `get_variable(0) != 2` | `02F8: jf (get_variable(0) == 2) -> 0539` … `06E3: end_game("You have saved the land of Cythera from darkness.")` |
| 1802@050A bad ending | Alaric talk, bit 1 set and var 0 == 2 (the scene then shows character 13 Pelagon's portrait) | `0370: show_portrait(13, 0)` … `050A: end_game(…)` |
| 180D@0162 Pelagon | sub 0002, called when var 3 == 3 and Pelagon bit 0 clear and either crystal piece 4133 (frame 4) / 3109 (frame 3) is not held by the Hero (180D@026F–029A), or on "y" in the 3-round surrender loop (180D@03FD–0402), or "n" at the last prompt (180D@05A6–05AB) | `0162: end_game("You gave the only hope to the enemy, who killed you.")` |
| 1801@036C Hero death | death method, Hero bit 0 clear, and no charged amulet (type 244 equipped, quality > 0) **or** karma ≤ 45 | `020C: jf (G0C:g0C_0to100 > 45) -> 02AD`; revival path `0296: teleport(1, 1, 0)` |
What gives the frame-6 crystal a non-zero quality (the damned ending) was **not found**: no
script writes `.f06` on a type-37 prop, all shipped type-37 map props (0x8107 #2, 0x8113 #23,
0x8108 #1226) have quality 0, and every `give_item` of a piece passes quality 0. [MED — open]

---------------------------------------------------------------------------------------------
## 6. Story beats: visions, teleports, time

- **Visions** [HIGH bytes / MED reading]: 0F15 `return create_prop(66, 0, A30, 9, A31, A32, A33)`
  makes a kind-66 (0x42) frame-9 prop of type k, location word = A30 (1), byte 6 = A32 (2, 5 or 1 — a delay, MED); the Hero's signal method
  (1801@03A6 `jf ((A31.f00:kind == 66) && (A31.f03:frame == 9))`) then plays vision `A31.type`
  with portrait 126 "Omen" and deletes the prop. Queued: k 0 Alaric 1802@199C; 1 first crystal
  1025@012A; 8 two pieces 1025@0290; 3 four pieces 1025@035C; 4 zone 1 1401@00AF (var 11 == 0);
  5 Cademia 1408@002B (var 11 == 2); 6 class-0x28 #2 1502@0033 (flag 16); 7 zone 0x1D 141D@0041
  (flag 17). Vision 4 sets var 11 := 2 (1801@11FE), vision 5 var 11 := 4 (1801@1376); vision 0
  ends with `teleport(1, 148, 0)` and a non-local `raise` (1801@09D1–09DC).
- **Teleport** (`TeleportTo__8TGameSysFsss @ 10050e98`: arg a = arrival byte, −1/65535 → 0xF00F
  table; b = 0xF00C index; c ≠ 0 → `FollowLeader(c)`) [HIGH]. Story targets (0xF00C, this
  session): 1 → level 3 (19,23) — the Hero's start cell (death revival 1801@0296, spell type 0
  1A00@00ED); 148 → level 40 (29,27) (vision 0); 141 → level 37 (16,32) (zone 0x24 1424@004E,
  large city 1001@005D when the leader lacks ability 28); 150 → level 3 (11,37) (room 451
  first visit 1CC3@043B); 146 → level 39 (12,14) (0x1E20@0005); 29 → level 1 (132,217)
  (Ruins Guard 1809@0103/036D). The other 15 `teleport` calls are doors/stairs using the prop's
  `.f08` index.
- **pass_time** (BD) only twice, both 1024 ticks: sleep loop 0E93@00C1 (runs `A30 * 4` times —
  so 1024 ticks = ¼ hour, MED) and fishing 1091@011D. No story beat passes time. [HIGH]
  Sleep side-note: 0E93@0214 compares `magic < health_max` and 0243 sets `magic =
  health_max` — copy-paste slips in the original; replicate. [HIGH bytes]

---------------------------------------------------------------------------------------------
## 7. Side chains as variable / bit clusters

### 7.1 Ariadne (var 1, flag 3, to-do 1) [HIGH per site]
0 → Gate Guard 1864@010F var := 1, `add_to_do(1)` 1864@03A5 → bandit Eudoxus dies while var == 1
(185C@0005–0010) → 2 → Ariadne asks to leave (1835@0005 `get_variable(1) < 3`), "y" →
`join_party(53)`, var := 3 → returned alive: Gate Guard 1864@049D (`R0F13(53)`) or Philinus
1832@0005 (`done_to_do(1)`, karma +10, `leave_party(53)`) → 4; returned dead (corpse 3150/53):
1864@0527–05EB → 4 + flag 3 → Antiphus 185E@02B3 → 5 → enter zone 1 with Sacas bit 1
(1401@005C) → 6 → enter Odemia (1402@001F) sets the prop with item 9223 to frame 7 → 7 →
Thersites/Sacas `>= 7` branches.

### 7.2 Opheltius / House Comana (var 3, to-do 10/11/37) [HIGH per site, MED order]
var 3 := 1 on entering zone 1 when var 3 == 0, Pelagon bit 1 and Halos bit 1|2|4 (1401@0020–
0056); Berossus `set_variable(3, 2)` 1848@0A1C (beside `done_to_do(11)` 1848@0A18 and
`leave_party(98)` 1848@0A08 — Dryas delivered), `set_variable(3, 3)` in sub 1848@01DD (beside
`done_to_do(37)` 1848@01E8). var 3 ≥ 2 moves the Comana brothers (schedule 0xA3); var 3 == 3
moves Pelagon (0x83/3) and opens his confrontation (§5). Dryas (98) joins with `add_to_do(11)`
(1862@00BA/044F/091D).

### 7.3 Demodocus trail (var 4, to-do 14) [MED]
Values 0–7 set by Crito/Parium/Bryaxis/Demodocus and by the town gossip routines 080A–080E
(topic `demo`), each advancing only from the expected previous value (e.g. 080A@000B `jf
(get_variable(4) == 6) -> 001C` then `set_variable(4, 1)`); entering zone 1 sets 5 (from 2, if
var 3 ≥ 2) or 7 (from 0). Demodocus `add_to_do(14, title 114)` 186D@03E4.

### 7.4 To-do slots seen as quest ids (F2/F3) — titles from 0x021A
Slot n = to-do index; `add_to_do(n, str[021A:0] + k)` stores title k (normally k = n).
0 Cure Alaric · 1 Rescue kidnapped Ariadne · 2 Learn Magic · 3 Cure Plague · 4 Interrogate
Bandit · 5 Show Crystal to Lindus · 6 Take Crystal to Timon · 7 Free Maayti · 8 Find Son of
Sabinate · 9 Honor Jinrai · 10 Ask Halos about Comana · 11 Take Dryas to Berossus · 12 Timeflux
book · 13 Kelp · 14 Iron Mine · 15 Seek out Prusa · 16 flour · 17 wine contract · 18 Books of
Wisdom (titles 18–28 = 0/10…10/10, `18 + get_variable(5)` at 1851@03DA) · 29 Harpy Egg · 30 Find
Eioneus · 31 Gator Skin · 32 Alaric's Mother · 33 flowers on the grave · 34 Thersites' Ring ·
35 net to Stentor · 36 source of Kesh · 37 Interview Stentor. Variant titles 111–116 reuse a slot
with a new wording (11 ← 111/112, 10 ← 113, 14 ← 114, 16 ← 116). 0x021A entries 1024+k hold the
long descriptions. [HIGH strings / LOW that the list shows 1024+k — drawing not traced]
Data slip: Ake 1820@0101 `add_to_do(10, … + 114)` files slot 10 under title 114 ("Ask Thuria
about Iron Mine") although the speech before it sends you to Halos; Ake's other path 1820@07D9
uses `+ 10`. [HIGH bytes / MED "slip"]
41 add / 32 done calls; every added slot has a `done_to_do` somewhere except **slot 17**
(wine contract, added 182A@0376) — it can never be completed. [HIGH census, MED reading]

---------------------------------------------------------------------------------------------
## 8. Party join / leave gating [HIGH bytes / MED meaning]
- Common pattern (Hector 1806, Meleager 1822, Timon 184A, Dryas 1862): keyword `wait` →
  `leave_party(c)` + `setfield A30.f15:activity = 112` (0x70 'p', which `ScheduleTime` skips —
  rules.md §3.1); `foll` → only if `activity == 112`, `join_party(c)`; `leav` → `leave_party`.
- Gates: Hector — `R0F02(4, 0)` Hadrian's leave (1806@0C15) then bits 6.0/4.0 and
  `join_party(6)` 1806@0D3C; Meleager — pay `R0D05(50)` (or 35 with skill 204) then
  `join_party(34)` + bit 34.0 (1822@07FA–0A1D); Aethon — needs own bit 1 (1861@04C9 `jf
  R0F02(A30, 1)`), set from the Halos topic when Halos bit 3 (1861@039E–0454); Ariadne / Dryas —
  quest joins (§7.1, §7.2); Timon — free once talking is unlocked (var 2 ≥ 12).
- Forced leaves: Philinus `leave_party(53)` 1832@0145; Berossus `leave_party(98)` 1848@0A08;
  spell type 246 `leave_party(G09:speaker)` 1AF6@005D.
- `join_party` returns 1 in party mode 2 and 2 at 8 members (script-builtins B9); no shipped call
  site reads the result, so a full party silently fails to take a quest companion. [HIGH]

---------------------------------------------------------------------------------------------
## 9. The journal [HIGH]
`TJournal::MakeEntry @ 10079240` writes a 6-byte header `{u16 len = strlen + 6, u8 day
(_DAT_100d3e1c), u8 kind, u8 speaker, u8 0}` then the text to a `TJournalSegment` (0xE000+k);
kind 0 = `SaidToJournal(speaker, text)`, 1 = `AddToJournal(text)`, 2 = `MakeNote` (player-typed
note, dialog 0x8A). No builtin and no other dump function calls `SaidToJournal` /
`AddToJournal` (grep: only their own bodies), so the journal is **not script-driven**; its
caller is presumably the conversation output path via pointer glue — **not traced**. Story state
never lives in the journal.

---------------------------------------------------------------------------------------------
## 10. Open items
1. The activity interpreter: semantics of activities 164/165/166/167 (flag sync, bit clear),
   66 (wait), 68 (bark), 160 (walk) — needed for every cut-scene; code not decompiled.
2. What makes the frame-6 crystal's quality non-zero (damned ending), §5.
3. Who sends the Hero signal `256` (karma −1, 1801@18B4) and the countdown that fires the
   vision props (byte 6 timer, data-format §4.2) — assumed `DoTicks`, not traced.
4. Bits tested but never set: Hero 0, Magpie 1, Tlepolemus 0, Sabinate 4, Timon 3 (bug),
   Dryas 0 (only cleared), flag 2; Glaucus (102) bit 7 tested 5× (0813, 184F, 1852, 1867) and
   never set — confirm none is set natively.
5. Flags 64/65 have no script reader — check the level/map code for a native reader.
6. To-do list rendering (title vs 1024+k description), `TToDoList::RebuildList` glue calls.
7. 0x0301:0012 array `[2, 3, 1, 1]` meaning inside 0E93 (`A33` = sleep quality?).
8. The 0x30xx fallbacks (e.g. 301D Hero-death alternative) were read only where cited.
