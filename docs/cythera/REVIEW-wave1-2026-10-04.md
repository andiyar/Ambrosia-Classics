# REVIEW — Cythera wave-1 rules banks after the fix pass (commit 6f216e8), Fable reviewer, 2026-10-04

**Verdict: ACCEPT_WITH_FIXES.** Counts: **Critical 1 · Major 2 · Minor 6 · Notes 7.**
Scope: the eight banks (`combat.md`, `magic.md`, `dialogue.md`, `trade-economy.md`, `schedules-npcs.md`,
`quests-flags.md`, `script-library.md`, `open-items-2026-10-03.md`) at 6f216e8, read whole; `FIXPASS-wave1-2026-10-04.md`
(four fixer reports, every "reviewer, please check" item below), `notes-critic.md`, `notes-tools.md`, `INDEX.md`,
`data-format.md` §6.1, `script-census.md` as context. Method as briefed: every claim below was re-derived with a command I ran
(banked tools only; nothing from memory). Evidence regenerated: `scriptdis.py` re-run into a fresh dir → **958 listings,
`diff -rq` against `ghidra/cythera-scripts` empty, census byte-identical** except the output-path line; whole code section
disassembled once (`ppcdis.py 10000000 100cd280` → 212,074 lines) and grepped for every banked scan.

| file | claims sampled | pass | fail | partial |
|---|---|---|---|---|
| combat.md | 20 | 20 | 0 | 0 |
| magic.md | 13 | 13 | 0 | 0 |
| trade-economy.md | 17 | 17 | 0 | 0 |
| schedules-npcs.md | 22 | 22 | 0 | 0 |
| quests-flags.md | 15 | 14 | 1 (m12) | 0 |
| dialogue.md | 22 | 21 | 1 (§3.3 slots) | 0 |
| script-library.md | 15 | 15 | 0 | 0 |
| open-items-2026-10-03.md | 18 | 17 | 0 | 1 (§5 scan wording) |
| **total** | **142** | **139** | **2** | **1** |

Cross-file checks run: 22 (§3). Critic findings: B1, M1–M7, m1–m11, m13–m19, m21–m23 applied correctly and marked; **m12 not
applied by any fixer** (none of the four reports lists it). notes-tools forced edits: all three applied. Register sweep
(`replica|should|omit|recommend|must` over the eight files): 7 hits, every one a code fact ("ammo kind must equal launcher [0]",
"start must be within ±15") or quoted game text ("These should be open") — **clean**. Orchestrator's extra checks are all
answered in §1–§3 (un-rerun scans re-run by me: two hold, one needs wording; INDEX 14 stale → M2; 0xF0xx raw confirmed; vtable
base step 13/13; Die, mygetch, KeyRoutine, UpdateCharName, show_portrait, §0 analyser all confirmed; no padding in dialogue.md).

---------------------------------------------------------------------------------------------
## 1. Findings (ranked)

**C1 · dialogue.md §3.3 l.200–201 · Critical (narrow) · HIGH** — wrong code fact: "`TConvResponseMode` (vtable 0x100d50d4 … slot
+0xC → 0x1003e378, +0x18 → 0x1003e8ec by the §0 one-liner)". Evidence: the §0 one-liner itself over 0x100d50d4 gives **+0xC →
0x1003e17c = `DrawRoutine__17TConvResponseModeFv`, +0x10 → 0x1003e378 = `MouseRoutine__17TConvResponseModeF5Points`, +0x18 →
0x1003e778 = `CursorRoutine__17TConvResponseModeF5Points`, +0x1C → 0x1003e8ec = `KeyRoutine__17TConvResponseModeFs`**
(`python3 -c "…toc.data_u32(0x100d50d4+s)…"` for s in 0xC/0x10/0x18/0x1C, then `tb.py --at`). The two routines the section
reads (Key/MouseRoutine) are correctly named and addressed — only the slot numbers are wrong, so the behaviour claims stand.
Edit: "+0x10 → 0x1003e378 MouseRoutine, +0x1C → 0x1003e8ec KeyRoutine (+0xC DrawRoutine, +0x18 CursorRoutine, both unread)".
Graded Critical by the brief's rule 6 (wrong about the code); impact is confined to this derivation note.

**M1 · quests-flags.md §8 l.424 · Major · HIGH** — critic **m12 not applied**: "spell type 246 `leave_party(G09:speaker)` 1AF6@005D".
`ghidra/cythera-scripts/1af6.txt` `0005: return "Wait"`; 0x1AF6 is the class-0x50 "Do" command type 0xF6 (magic.md §1: 0xF1–0xFF
are the 15 commands), not a spell. `@005D leave_party(G09:speaker)` is right. No fixer report lists m12; no marker on the line.
Edit: "the 'Wait' command 0x1AF6 (`1af6 @0005 return "Wait"`) `leave_party(G09:speaker)` @005D" + `⚑ corrected (wave 1 2026-10-03)`.

**M2 · INDEX.md l.117 and l.132 · Major · HIGH** — INDEX NOT RESOLVED 14 still ends "Open: **`CompileAIFile` caller**" and l.132
lists "`CompileAIFile` caller (14)" among open sub-points, while schedules-npcs.md §9/§10.2 (marked) resolve the one direct call:
`100b1854: 4bfff6a5  bl 0x100b0ef8  ; .CompileAIFile__FR6FSSpecs` inside `.DialogItemRoutine__17TEditUserBehaviorFs` (entry
0x100B1780, `tb.py --at 100b1854`), the only `bl 0x100b0ef8` in the whole code section (verified over `ppcdis.py 10000000
100cd280`). Fixer D's synthesis did not carry the fix. Edit: INDEX 14 → "direct caller `TEditUserBehavior::DialogItemRoutine`
(schedules §9, HIGH); open only: indirect TVector callers (not searched, MED)"; drop it from l.132.

**m1 · script-library.md §10.5 l.415 · Minor · HIGH** — "Activity 6 = attack target [MED]" contradicts schedules-npcs.md §2.1/§2.3
(0x06 Beserk → `PerformAI(m, 0xD3)`, radio value 6 "Beserk" from STR# 502, HIGH) and trade-economy.md §11 ("Activity 6 =
**Beserk** … [HIGH ⚑]"). Evidence: `Cythera_extra.decompiled.c` DoMove `case 6: cVar11 = .debug::_PerformAI__FP14TActiveMonsters
(param_1,0xd3);`; data 0x100D4784 u16 = (3, 4, 5, 6, 7, 8, 13, 176). Edit: "Activity 6 = Beserk (schedules §2.1) [HIGH]".

**m2 · open-items-2026-10-03.md §5 l.106–108 · Minor · HIGH** — the displacement scan was not re-run (Fixer A) and its wording is
stale: "the PPC scan of every `lbz/lhz/lha/stb/sth` with displacement 10/11/14/15 in functions named `*Prop*`/`*Item*`/`*Stage*`
hits only `TViewer` members". Re-run over the whole-section listing with `tb.py` function names: hits in 7 `TViewer` members
(`BuildStageEntry` ×2, `InteractProps`, `GetBestProp`, `SetStage`, `Set/ClearMonstStage`) **and** `TMapWindow::KeyTargetToProp`,
`TMapWindow::PropToPoint`, `TCreatePlayerDialog::DialogItemRoutine` (the last matches "Item" by name only). The conclusion (+0xA..
+0xB and +0xF have no prop-table reader; +0xE only `Render`/`GetField`) is unaffected. Edit: list the three extra functions
(none touches the prop table), and cite the command (`ppcdis.py 10000000 100cd280` + `tb.py` map), as the register requires.

**m3 · open-items-2026-10-03.md §4 l.71–77 and §10 l.342–345 · Minor · MED** — the TOC-word scan and the 4CC scan were not re-run
either and name no command. I reproduced both: every data-section word in [0x1882C−0x10, 0x1882C+0x30) → exactly
`0x100cdbd4 → 0x1882c`, `0x100cdbfc → 0x1884c`; every `lis`/`addis rD,0` + completing `ori`/`addi` pair → `FILT`
(`LoadDisplacementFilters`), `Lite` ×3 (`AmbientLight` ×2, `CalcLighting`), `Char`/`Mons`/`FXQ `/`Wind`/`Grem`/`DelP`/`Delv`/
`asnd` found, **none of PORT/LINF/MSta/eBRS/eSTM/RMAP**. Labels HIGH are honest. Edit: add the two commands (one line each).

**m4 · all banks that quote `Cythera_builtins.decompiled.c` (combat §2.3, trade §0/§1.2, quests §4.1/§4.2/§5, dialogue §7.3, magic
§2.2) · Minor (tooling) · HIGH** — `ghidra/find_func.py` cannot read that dump: its header regex `^// ==== (.+?) @ ([0-9A-Fa-fx]+)
====$` does not match `// ==== Builtin_AC @ 10094bbc (Builtin_AC) ====` (`python3 ghidra/find_func.py 'Builtin_AC' --file
ghidra/Cythera_builtins.decompiled.c` → "0 function(s) matched"); its default `--file` is `ghidra/Aki12_i386.decompiled.c`, so the
brief's bare recipe fails too. Every builtin quote I checked is right (AC, AE, C0, CA, DD, DF, F9 via `awk` block extraction),
but not reproducible by the named tool. Edit: fix the regex (allow an optional ` (name)` before ` ====`) or state `awk`/`grep` in
`tools/README.md` and the bank §0 lines.

**m5 · schedules-npcs.md §5 l.359–361 · Minor · HIGH** — formation tables 0x100D565C/0x100D56DC quoted as "(read with `tools/pef.py`)"
with no command and no element width. DoMove indexes them as 32-bit words (`*(int *)(&DAT_100d565c + (rank + facing*8) * 4)`,
extra dump l.463/465); as i32 the first row is dx (−1, 1, 0, −2, 2, −1, 1, 0), dy (1, 1, 2, 2, 2, 3, 3, 4) — **the bank's values are
right** — but read as i16/i8 they are not. Edit: "i32 words; `toc.data_u32(0x100d565c, 8)`".

**m6 · schedules-npcs.md §4.2 l.319–321 · Minor · MED** — orchestrator's query on the toc.py recipe wording: "`toc.py 100d5bb4 …
100d5be4` gives each slot's TVector data offset (e.g. `100d5bbc 0x2eb8`), `toc.py 0x100cd280+off` its code offset" — `toc.py`
takes literal hex addresses, so `0x100cd280+off` must be added by the reader (0x100D0138); the exact recipe is combat.md §12.1's
Python one-liner. The numbers are right (13/13 recomputed, §2 S7). Edit: point at the one-liner or spell the sum out.

### Notes (no edit required unless stated)
- **N1** dialogue.md is 657 lines; the 17 extra lines are the §0 corpus analyser (evidence the orchestrator asked for), not padding.
- **N2** quests §2.3 "wait until served" reading stays MED, as Fixer A labelled: the latch mechanics (bit set by 0C84/0C85, 166 with
  False waits for clear, 167 queued by 0C80 is the only clearer, no `R0F01` names bit 4/5 — clrbit census: bits 0,1,2,3,7 only) are
  HIGH; the "patron/served" meaning is a reading of 0C80's text, which I did not re-read in full.
- **N3** library §0/§9 native-sender scan stays MED (heuristic), as Fixer C said; it is now reproducible with the banked tools
  (`ppcdis.py 10000000 100cd280 | grep 'bl 0x1008…'` + nearest `li r4`), so a later pass can lift it.
- **N4** combat §12.2 "indirect call through `FUN_100c50e8` (its target — closing the window — is MED)": the slot is in the Die
  listing (`lwz r12,<slot>(r12)` after `FindInventory`), so the §0 one-liner would make it HIGH; left as is.
- **N5** 0xF0xx raw read (Fixer B's census; orchestrator check): `LoadGlobals__Fv` loads every 0xF0xx table with
  `_LoadSegment__8TSegFileFUsPv…` (e.g. `(…,0xf009,PTR_DAT_100cdbf0)`, `(…,0xf008,…)` via `0xf000`-relative ids), never through
  `GetEncryptedSegment` (which is the one path that calls `_Decrypt__8TSegFileFPvlUsl`); raw 0xF009 entry 1 reads +8 = 0xC0 (Hero:
  party + name known) and 0xF008 record 0 has key 0x20 = the Hero's type — **raw is right**; the census reproduces exactly (§2 T7).
- **N6** schedules §1 shipped-use census of page-0x09 tests/actions reproduced from the 0x04xx `entry` lines: tests (byte0 0x65/0x66)
  0x81 ×6, 0x82 ×6, 0x83 ×4, 0x85 ×4, 0x86 ×2; actions 0x81 ×6, 0x82 ×22, 0x83 ×4, 0x84 ×4, 0x88 ×4, 0x89 ×4, 0x8A ×2, 0x8B ×22,
  0x8C ×10 — all exact. The bank does not say how test/action entries are told apart (byte 0 class); one clause would make it HIGH.
- **N7** Both literal-10 buy calls and the one literal-10 sell call agree across open-items §7, trade §3/§5/§7, library §10.2
  (1869 @0215, 186A @0447 `R0EA5(…, 10, Nil)`; 1823 @0474 `R0EA9("Flax", blk@0480, 10)`), and the orchestrator's ruling is right.

---------------------------------------------------------------------------------------------
## 2. Per-claim evidence table (compact; every command run from the worktree root)

Legend: P = PASS, F = FAIL, ~ = partial. `L` = `ghidra/cythera-scripts/<seg>.txt`; `all` = `ppcdis.py 10000000 100cd280` output;
`M` = main dump via block extraction; `X` = `Cythera_extra.decompiled.c`; `B` = builtins dump (awk block).

**combat.md**
| # | § | claim | evidence | r |
|---|---|---|---|---|
| C1 | 2.3 | Builtin_AC body (Random, `uVar2 = sVar1 - sVar3`, `*param_1 = sVar3 + (sVar4 - sVar4/uVar2*uVar2)`) | B `Builtin_AC` l.14–16 | P |
| C2 | 4 | `ObjToMonst` 128×16 keyed +0xC (`0x7f < sVar1`, `+0xc == param_1`, `+0x10`); `Ctor` `+0x14 & 0x3ff` | M l.12/15/16/19; Ctor l.30 | P |
| C3 | 4 | 50 records, rec 0/1/3/20 bytes, f33 bit-8 on 5, tail after 0x800 empty | `seg.toc()` python: nonzero recs 50, first zero key 50, bytes identical, bit-8 5, tail all 0 | P |
| C4 | 4.1 | ctor stores (+0x1F, +9, +0xE, +0x13), 3 r2-relative refs to 0x100d73f2 | M ctor l.41–69; `grep 'r2,8562' all` → 100130f4, 10014180, 10044ba8 | P |
| C5 | 4.1 | `toc.D[0xA170:0xA174]` = `00 37 00 02` | `toc.D` → `00 37 00 02`; 0x100d73f0.. = `0037 0002 0800 0000` | P |
| C6 | 6.1 | 0E88 @002A/0036/0040/0046/0051/005E/006B | L 0e88 lines identical | P |
| C7 | 7.3 | 0E87 @0081 bytes `82 33 33 9f 0e ac 30 02 61 2a 03 40`, @008F reads L02 | L 0e87 l.24–25 | P |
| C8 | 7.3 | only `.f06` access in combat routines is 0E87 @0075 read; setfields at 0E0A @0113, 0E0B @00AD, 0E0C @0048/@0055 | `grep -n f06 L/0e*.txt L/30*.txt` (also 0E43 reads) | P |
| C9 | 12.1 | `ppcdis.py 1004fc78 +8` (lwz r12,72(r28); lwz r12,24(r12); bl 0x100c50e8); vtable words 0x2fb0/2fa8/2eb8/2f88/2f68/2eb0 → the six names | ppcdis + `toc.data_u32(0x100d5bac,16)` + `tb.py --at` ×6 | P |
| C10 | 12.2 | Die: `== *PTR_DAT_100cdbec → = 1`; no null test on `param_1[5]`; `0x1d` DoInterp; corpse word `param_1[1]+0xe` | X Die l.26–27, 38, 95–96, 106–109 (`else {` straight into `param_1[5] + 4`) | P |
| C11 | 13.1 | 48 `R0E8B(` calls, 38 constant to leader/Hero | `grep -h 'R0E8B(' L/*.txt` 48; filtered 38 | P |
| C12 | 13.2 | `GetGlobal` no case 0x11 → default Nil; DoExpr 0x4b pushes left operand on non-int | M GetGlobal cases 0–0x13 (no 0x11; `default` l.46); DoExpr case 0x4b `else` branch | P |
| C13 | 3/6.1 | Barehand 199 at 0E88 @0051/@005E; `0E90 = (A30-12)/4`; 0E8C dx²+dy²; 0E95 switch `ce1D & 3` | L 0e88/0e90/0e8c/0e95 | P |
| C14 | 9–11, 2.2, 5 | 3040 @0009…@00FD; 3041 @000E…@008E; 3043 @0009/@006F/@0096; 301C @0003…@009A; 3042 @0009…@0282 | L lines identical | P |
| C15 | 13.2 | 0E8B @0009/@002D/@0041; 0E86 @0003…@004E; 0E82/0E83 formulas | L lines identical | P |
| C16 | 13.2/15 | char 2 = `… 90 90 24 24 00 08 …`, +0x1D 15, exp 9600 | 0xF009 entry 2 bytes `… 25 80 90 90 24 24 00 08 … 0f …` | P |
| C17 | 12.1/10 | `DeathRites` (health 0, `DoInterp(0x1d)`, `RemoveStackedAbility` ×4, `RebuildParty`); SetField 0x1C → `DeathRites` when < 1; AddAbility `< 8 / < 0x18 / < 0x20`, 0xF000 | M DeathRites l.13–43; SetField l.135–144; AddAbility l.28–65 | P |
| C18 | 12.3 | 301D whole body; 0E8D @0016 type 77 `create_prop(33…77…)`, @00C9 karma `L05[f35]`, 1801 @017A/@020C/@0296/@036C | L lines identical; `104D` header tile-name "blood" | P |
**magic.md**
| # | § | claim | evidence | r |
|---|---|---|---|---|
| M1 | 2.2 | 0EA1 @0003/0011/002B/003F/00AA/00B4/00BC/00CC | L 0ea1 identical | P |
| M2 | 3 | 1a00 @000B/@00ED; 1a09 @0021 [1,212]/@0054/@008E/@00A9; 1a24 @0105; 1a2b @000B "Replicate"/@00C2/@00F7; 1a0d @00C7; 1a23 @00D8; 1a15 @00B0/@00BA | L identical | P |
| M3 | 1 | 87 page-0x1A segments; `1ac0`/`1ac2`/`1ac9`/`1ad6` names | `ls L/1a*.txt | wc -l` 87; @0005 returns | P |
| M4 | 4.1 | DrawStatPart table 0x100D46D8 = (9, 13, 14, 21, 19, 20, 22, 28672, −1) | `toc.D` i16×9 identical | P |
| M5 | 6 | 0EAF @000F/@0098/@00A8/@00F5; 1801 @00B9 training 4; 1802 @0F11/@0F9A | L identical | P |
| M6 | 7.2 | 0A00/0A01/0A02 @00A0,@00AA/0A06 formulas | L identical | P |
| M7 | 1/5 | 0EAC @000F/@0019/@001D; 0EB5 @001E; 0E85 body; 104C @0089…@0208; 101F @00FE/@0109 | L identical | P |
| M8 | 1/2.1 | FindSkill `(puVar2+1 & 0x3ff) == param_2`; 0981 @0028/@0035/@004A; 0C4C @002B/@0037/@006D/@0075 | M l.16; L identical | P |
| M9 | 2.3/4/5 | GetGlobal case 9 falls into 0x13; ScheduleSkill → `QueueTaskEvent`; SetField 0x1E/0x1C clamps | M: case 9 l.49 → 0x13 l.56 no `break`; l.6; cases 0x1c/0x1e | P |
| M10 | 6 | +6 training = combat §13.2 / library 0E86 (one label) | all three HIGH, same DoExpr/GetGlobal quotes | P |

**trade-economy.md**
| # | § | claim | evidence | r |
|---|---|---|---|---|
| T1 | 0/3/5 | 23 `R0EA5(` in 22 segments; 1869 @0215 / 186A @0447 literal 10; R0EA9 at 1810 @02BC, 1823 @0474 | `grep -l`/`grep -c` over L; lines identical | P |
| T2 | 3.1 | 0EA5 @0003/@000B; GetField/SetField case 0x27 | L; M | P |
| T3 | 3.2–3.4 | 0EA5 @0034/@003B/@00A2/@00C4/@00CD/@00D7/@0103/@0234/@02A1/@0830–@087D/@0A11–@0A23 | L identical | P |
| T4 | 4 | haggle @08ED/@08FF/@090A/@0915/@0935/@0947/@097A/@0981/@098E/@09C4/@09E6/@09EF | L identical | P |
| T5 | 5 | 0EA9 @0014/@001C/@008F/@00D5/@011C/@0285/@028E/@02EC/@0350/@0373/@0376/@0385/@0388 | L identical | P |
| T6 | 3.1/7 | 21 non-zero +0x17 bytes; Thoas 0, Dymas 16, Atreus 15, Dares/Diomede 18 … | `seg.py` census: 21, values as tabled | P |
| T7 | 11 | byte-6 species census {0:115, 1:3, 2:3, None:10}, v1 = 14/92/94, v2 = 1/2/3, 19 species, 14 own-method chars → 101 | the bank's own command re-run; identical | P |
| T8 | 7 | every stock list / base price / haggle table for all 23 calls (+ Atreus/Hebe wants) | parsed all `blk@` arrays: identical to §7 | P |
| T9 | 8 | 1828 @05A7/@05FC/@0604/@06BD/@04A7/@04BE/@023B/@0249/@066B; 1822 @07FA/@0853/@0866/@093D; 1838 @042F/@044A/@04C5/@057C/@05CD/@06A9; 1824 @035E/@0407; 0812 @0488/@052F/@056D; 100E @000A/@0014/@0079/@00AF/@0390/@039D; 0E93 @00C1/@01E7/@01FA/@0203/@0214/@023A/@0243; 0301 @0000/@0012/@0016 | L identical | P |
| T10 | 1.2 | R0D01 @0029; R0D02 @0034/@003B/@004F/@0055; R0D05 @0029/@0030/@0045/@004B; R0D09 @0003/@0014/@003E/@0053; R0D0A @0003/@000A/@0036/@0049; 1AFC @0039/@0040/@0045; 1AFD @003D/@0044/@0049 | L identical | P |
| T11 | 11 | TakeCommand `puVar3 = PTR_DAT_100cdbb0`, False early return, `SendSignal(…,0x100)`; `HowMany("Move how many?",0,count)`; room test | M l.40/82/95/103–109 | P |
| T12 | 2.1/1.2/4 | `GetMaxInvEncumb` `[+9] * 0x14`, property 0x16 path; `DrawWeightPart (w+5)/10`; `ConjoinProp` `uVar8 == 0 → 1`; `Builtin_CA` writes `piVar3[1]`, no reader; `IsEqual` `return param_2 == param_1` | M; B CA l.24; M l.20 | P |
| T13 | 3.2 | stock `units` 71×1, 1×12 (also library §10.2) | parsed `[3]` of all 23 blocks: {1: 71, 12: 1} | P |
| T14 | 8/11 | 0E93 compares/clamps magic against health_max; Hero signal 256 → `G0C − 1` (1801 @18B4/@18D1) | L 0e93 @0214/@0243; L 1801 | P |

**schedules-npcs.md**
| # | § | claim | evidence | r |
|---|---|---|---|---|
| S1 | 0 | `ppcdis.py --hex 1004d6d4 +5` words; `tb.py --tb --grep DoMove` → 1004b8e8 1dec tb@1004d6d4 name@1004d6e4 | identical | P |
| S2 | 1 | 098A @0040, 0989 @00A1, 0987 @0034, 0C55 @0003/@0009 bytes; shipped-use census (tests 22, actions 78 by index) | L bytes identical; 0x04xx entry census identical (N6) | P |
| S3 | 2.1/2.2 | `uStack_78 = (ushort)*(byte *)(*param_1 + 0x16)`; `case 6: PerformAI(…,0xd3)`; pre-emption `& 0x20` line; case 0x88 `li r4,1 … li r5,2 … lwz r12,48(r12)` | X DoMove l.115/359/565–566; `ppcdis.py 1004d02c 1004d060` | P |
| S4 | 2.1/2.3 | +0x16 census 0x91 ×87, 0x00 ×17, 0x92 ×6, 0x88 ×4; +0x1E {0:11, 2:1, 3:7, 4:7, 5:1, 6:5, 7:8, 8:91}, zeros at 0,15,43,44,47,99,126–129,190 (131 entries) | `seg.py` census identical; data-format §6.1 l.431 agrees | P |
| S5 | 2.3 | 0x100D4784 = (3, 4, 5, 6, 7, 8, 13, 0xB0); `RecalcUserAIMenu` `< 0xb0`, `− 0xad` | `toc.D` u16×8; M l.21/28 | P |
| S6 | 3.2 | `1004bb20: addi r3,r2,1948 = 0x100d5a1c`; 11 words → BB34 BBA0 BC40 BCFC **BD8C BE24 BEB4 BF78** C01C C054 C0B4 | ppcdis + `toc.data_u32(0x100d5a1c,11)` | P |
| S7 | 4.2 | 13/13 vtable slots named | recomputed; +0x24 CanMove 0x10049d60, +0x28 HandleMove 0x100488e4, +0x2C HandleSubMove 0x10048fb0, +0x34/+0x38 Clear/SetMonstStage | P |
| S8 | 4.3 | `-27112(r2)` only in MoveAll: 1004e4f4, 1004e538, 1004e55c; `ppcdis.py 1004e544 1004e568` | `grep all` 3 hits; `tb.py --at 1004e4b4` → MoveAll 0x1004e334 len 0x414 | P |
| S9 | 6.4 | `10043c58 cmpwi r0,250 … 10043fec stb`; `10043828 addis r0,r4,22169`, `1004382c cmplwi r0,0x7261`; `100437d4 lwz r28,-29744(r2)`; `-29748(r2)` 3 hits | ppcdis lines identical; cheat strings at 100ce85c/858 | P |
| S10 | 9 | six `bl 0x100b0ba4` at 1004c51c/c57c/c5a8/c608/c688/d5bc; one `bl 0x100b0ef8` at 100b1854 in DialogItemRoutine (entry 100b1780) | `grep all`; `tb.py --at` | P |
| S11 | 3.2 | 0xA4 wait flag (+clear when y==0); 0xA6 True → pop when bit set, else pop when clear; 0xA7 set/clear by `== True` | X DoMove l.206–263 | P |
| S12 | 5 | formation dx/dy row 0 | i32 read of 0x100D565C/56DC (see m5) | P |
| S13 | 2.1 | 0x71: party → 1; else `param_1[5]+4 & 0x3ff == param_1[4]+4 & 0x3ff` → activity := template byte 6, else `ScheduleOne`; falls into 0x93 | X l. `case 0x71` … `case 0x93` | P |
| S14 | 3.1/6.1/4.2 | `QueueActivity` `_insert(…, param_1 + 0x2c, local_24 = param_1 + 0x30, …)`; `SendSignal` `kind & 0x5d ∈ {0,1}`, flag 0x10000, room 0x58; DoTick busy −1 + `DoTicks(…,1,0)`, `return 3` unless 0x20/0x40/0x4000/0x2000, `GotAway`, `-0xe < s < 0xe` | M; M DoTick l.27–100 | P |
| S15 | 2.3/8.1 | HatchEgg: `byte7 < (Random & 0x7fff) % 100`; gates 0x6000/0x12000; `byte7 := 0x65`; behaviour 3–8 same, 9→3, 10→4, 11→5, 0xC/0xF/0x10→6, else 7; ctor difficulty ranges, `+0x1f = (char)sVar6` | M l.58–65, 164–186; ctor l.41–69 | P |
| S16 | 6.3 | 0D07 @0003/@000E/@0014/@002D/@0034; 0D06 @0077/@0081; 3015 whole body; 7 dictionary users 102E 1846–1849 1864 1865 | L identical; `grep -l '@0D07:'` | P |
| S17 | 3.3/7.3 | queue_activity census 0xA0 ×41, 0x42 ×19, 0x44 ×16, 0xA2 ×10, 0xA5 ×10, 0x47 ×8, 0x52 ×4, 0xA4 ×4, 0xA3 ×3, rest ≤ 2; 56 create_prop: 28 ×17, 9 ×15, 24 ×11, 33 ×5, 1 ×3, 16 ×2, 66 ×1, 2 computed | `grep -o` censuses identical | P |
| S18 | 3.2/2.2 | sel 33 sender `1004d538 li r4,33 … 1004d554 bl 0x100828c4`; sel 32 at 1004c3e4 (DoMove) and 1004fa70 (HatchEgg) | `ppcdis.py 1004d530 1004d558`; `tb.py --at` | P |
| S19 | 0 | `tb.py --missing` 877 / 840 with extra dump; 1,994 tables; extra 37, main 1955, builtins 95 | commands re-run, identical | P |

**quests-flags.md**
| # | § | claim | evidence | r |
|---|---|---|---|---|
| Q1 | 2.1 | 0F00/0F01/0F02/0F13 @0003/@0009 bytes | L identical | P |
| Q2 | 2.1 | bit census 0:53 1:154 2:84 3:36 4:21 5:6 6:1 7:205 over 560; setbit 246, clrbit 17, tstbit 297, inparty 64 | `grep -o` over statement lines: identical | P |
| Q3 | 2.3 | 0C84/0C85 @0003/@0010/@0017/@0027/@0038; 0C80 @001D/@007F/@00B1/@01B6; callers 1829@0147, 182D@00F7; 1834@0012/@008E, 1837@0012, 1865@0018 | L identical | P |
| Q4 | 2.5 | initial +8: 1 = 0xC0, 94 = 0x01, 190 = 0x80, nothing else | `seg.py` scan identical | P |
| Q5 | 4.1 | activity 165 ×10 (253/254/255), 164 ×4, `wait_for_flag` 6 sites | `grep -o` census identical | P |
| Q6 | 5 | 184A @0748 `== -1`, @0755 text; 1850 @02E5; `Builtin_AE` → `PTR_DAT_100cdbb0` Nil, frame-matched | L; B AE l.23/26; IsEqual l.20 | P |
| Q7 | 4.1/4.2 | `Builtin_DF` `(n>>5)*4`, `1 << (n & 0x1f)`; `Builtin_DD` `PTR_DAT_100cdbbc[int(a0)]` no bounds | B DF l.15–17; DD l.9 | P |
| Q8 | 7.4 | 41 add / 32 done; slot 17 added (182A) never done | census identical (done slots 0–16, 18, 29–37) | P |
| Q9 | 5 | 1025 @0083/@0095/@0122/@012A/@013A/@01D6/@01DF/@01F2/@0441/@044F/@0458/@045E/@0591/@059A/@066B | L identical | P |
| Q10 | 4.3/6 | 1801 @000A/@0011/@0062/@00CD/@03A6/@09D1/@09DC/@11FE/@1376/@18B4/@18D1; 1878 @0E2F | L identical | P |
| Q11 | 1 | `SaveToFile` `FUN_100c50e8(local_64,PTR_DAT_100ce360,_DAT_100d73f0,…cdcf4,…d73f2,…d73f4)`, 0x20 `b`, 8 `l`; `Builtin_F9` post-increment | M l.65–70; B F9 l.10–11 | P |
| Q12 | 2.3 | no `R0F01` names bit 4/5; 166 with False = wait until bit **clear** | clrbit census: (120,1) (121,1) (79,3) (95,7) (A30,0)×6 (A30,1) (A30,2)×6; X DoMove case 0xa6 `else` → `== 0 → cStack_64 = 1` | P |
| Q13 | 2.2 | `GetCharacterName` `& 0x80`; SetField 0x13 `if (sVar11 == 0) return`, RedoStat guarded, UpdateCharName unguarded | M GetCharacterName l.22; SetField l.63–71 | P |
| Q14 | 8 | "spell type 246 … 1AF6@005D" | `1af6 @0005 return "Wait"` — it is the Wait command (critic m12, unapplied) | **F** |

**dialogue.md**
| # | § | claim | evidence | r |
|---|---|---|---|---|
| D1 | 0/14 | analyser prints 127, 108, 1325, 1551, 88 | run verbatim: `{'methods': 127, 'input': 108, 'match': 1325, 'words': 1551, 'prompt': 88}` | P |
| D2 | 1.1 | TalkCommand lines (`-0x6f`, `& 0x4000`, portraits 2/0, `0xc`, `& 0xfff7`, `HeartBeat(…,1)`); CanTalk `0x1e == 2` | M l.26–48; CanTalk l.16–30 | P |
| D3 | 2.3/2.4 | myprintstr 1003d0a0/0b4/0c0/100/114/134/140/144/148/15c/160/178/18c/190/194; ConvMore 1003ced0/cf08/cf38/cf78; MoreMode 1003ce50/ce60 | `ppcdis.py --func` lines identical | P |
| D4 | 3.1 | 0x8E listing 10081a04…10081a44; TConversation vtable +0x104/+0x114/+0x118/+0x11C → ForceOut/mygets/mygetch/mygetnum; +0xF4/+0xF8 IsJournalable/WriteJournal | ppcdis identical; one-liner + `tb.py --at` identical | P |
| D5 | 4.1 | `FUN_100b6dc8` in main dump = strncmp loop; `100b6dd8 lbzu`, `100b6de8 subf` | M block; ppcdis | P |
| D6 | 4.2 | 7 blank-prefixed aliases (1818 @009E, 1828 @03A0, 1829 @05F3, 182A @0596, 186D @155F, 1878 @0975, 080F @00C6); 0 upper-case keywords; 1 556 total, 1 325 talk, 231 elsewhere (08: 215, 10xx: 5, 11xx: 11 + 1121's 7) | python census identical | P |
| D7 | 6 | mygetch 1003f524 SysBeep, 1003f538 strcmp `yn`, 1003f56c/578 one pointer sp+64 per slot (r3 = sp+56 loop-invariant), 1003f608 lbzx; TOC `yn`/`Yes`/`No`/`0123456789`/`None`/`bye`/`%d`/`true`/`false`/`None`/`<%x>` | `ppcdis.py 1003f540 1003f598`; `toc.py` ×12 | P |
| D8 | 3.3/6 | KeyRoutine 1003e924 table 0x100d8a86, 1003e970 lha 44, 1003e98c/990; choice string +0x24 (`lwz r0,36(r31)`), strchr `bl 0x100b6e38`, Backspace `cmpwi r0,8`, 13/3 | ppcdis identical | P |
| D9 | 9.1 | UpdateCharName reads +0xa4e/+0xa48 with no `param_1` test; dtor zeroes TOC 0x100cdcc8 (1003b28c/298) | M l.9–17; ppcdis | P |
| D10 | 10 | show_portrait 286 calls: 238 in talk bodies, 244 in talk regions; b = 0/1/2 | python census: 286 / 238 / 244 | P |
| D11 | 6 | 95 prompts = 77 `"yn"` + 18 `"*"` | `grep -o` census identical | P |
| D12 | 8/14 | 97 all-four, 7 lack name, 1 lacks job, 22 none (17 no keyword); 2 inputs in 183C/183E/1864; rows 1810 (1,9,10,0,0; 0801 080D), 1802 (1,25,28,0,3), 186D (1,37,58,0,0) | region-set census identical | P |
| D13 | 1.3/5 | begin_talking 22, end_talking 24, add_answer 18 | `grep -o` identical | P |
| D14 | 1.2 | ctor `*param_1 = &PTR_PTR_100d5298`, 100 slots at `0x22e`, `GetIndString(…,0x80,…)` + `AddAnswer`, `*_DAT_100cdcc8 = param_1` | M l.14–42 | P |
| D15 | 9.4 | ShowPortrait colour `< 0 → 0x21`, `< 0x60 → -(0x1f - g/6)`, else 0x1e | M l.85–91 | P |
| D16 | 7.1 | THowManyMode ctor `param_1[5] = param_3; *(short *)param_1[5] = (short)param_5; NewControl` | M l.26–36 | P |
| D17 | 7.3/6 | Builtin_C0 items capped `sVar8 < 0x14`; TPickMode `addi r0,r26,1; neg; sth`; 0x8F listing 10081a5c/a70/a94/a9c/ad0/b00/b04 | B C0 l.81; ppcdis identical | P |
| D18 | 5/13/3.1 | `FindAnswer` → `EqualNStr(…,4)`; vtables 0x100d50d4/510c/509c/4e98 stored by the ctors; TOC 0x100cecdc = `bye` | M l.16; M `PTR_PTR_100d5…` stores; `toc.py` | P |
| D19 | 3.3 | `TConvResponseMode` slots +0xC / +0x18 → Mouse/KeyRoutine | one-liner: +0xC DrawRoutine, +0x10 MouseRoutine, +0x18 CursorRoutine, +0x1C KeyRoutine | **F** |

**script-library.md**
| # | § | claim | evidence | r |
|---|---|---|---|---|
| L1 | 0 | page call totals 08: 269, 0C: 15, 0D: 90 + 7, 0E: 367, 0F: 636, 30: 20 | bank's grep re-run identical | P |
| L2 | 5 | sel 33 sender in DoMove; head erased only on True (`iStack_b4 == *PTR_DAT_100cddec`) | ppcdis; X l.648–651 | P |
| L3 | 8 | 0F15: 8 sites, all `(1, k, d, 0)` as listed | `grep -n 'R0F15('` identical | P |
| L4 | 10.1 | 9 Where-Is tables (0801, 0809, 080A, 080B, 080C ×2, 080D, 080E, 0811); 0816 "9 (8)" | `grep -n 'R0816('` | P |
| L5 | 10.2 | counts 71×1, 1×12 over 23 tables | parsed blocks | P |
| L6 | 10.5 | 0D07/0D06/3015 lines; 7 dictionary users + 3015 | L; grep | P |
| L7 | 7b | 0E86 @004E `(6 - G11) * A31`; GetGlobal default; DoExpr 0x4b | L; M | P |
| L8 | 9 | 32 senders 0x1004fa70 (HatchEgg), 0x1004c3e4 (DoMove); 33 at 0x1004d554 | `tb.py --at` | P |
| L9 | 11 | 36 dead = 16 + 14 (0F03–0F10) + 0F14 + 5 | arithmetic over the list | P |
| L10 | 10.4/10.6/9 | 3021/0C00/0C43 bytes; 0E87 @009D/@011B/@0148/@030C/@0360, L02 quirk @0081/@008F; 300F @000A/@0018; 0E93 @0214/@0243 | L identical | P |
| L11 | 5 | queue codes 64×2 65×2 66×19 68×16 70 71×8 73 75 76×2 78 79 81×2 82×4 83 84×2 85; 67/69/72/74/77/80 never | census identical | P |
| L12 | 10.12 | 0F02/0F00/0F13 607 calls; bit literals; single bit-6 use 0C80 @001D | census identical | P |

**open-items-2026-10-03.md**
| # | § | claim | evidence | r |
|---|---|---|---|---|
| O1 | 1 | `xxd -l 0x80` header bytes | identical | P |
| O2 | 4 | LoadLevelMap 10005dd4/dec/df0 (`rlwinm r6,r7,7,0,24`), 10005e9c/eac/eb0 (`rlwinm r6,r8,6,0,25`); `tb.py --at 10005dd4` → LoadLevelMap | identical | P |
| O3 | 5 | AddSound `0x7f < +0x1dc14`, records at +0x1d814; `toc.py 100d6074` → 0x3060 → code 0x66790 | X; toc | P |
| O4 | 6 | `xxd -s 0x5079bc -l 0x20` records 0/1 | identical | P |
| O5 | 7 | 23 R0EA5 + 2 R0EA9; three literal-10 calls | identical | P |
| O6 | 8 | TStream entries 10017990/17cfc/18134/181e0/182a4/1837c (old values = name fields); `10017e6c stb r0,70(r1)`, `10017e74 li r5,1`; 10 compares in 10017d50–dc4; initial `0037 0002 0800 0000` | `tb.py --tb --grep TStream`; ppcdis; `toc.D` | P |
| O7 | 16 | `-27(100|104|108|112)(r2)` → 8 hits 1004e4b4–e55c all in MoveAll | `grep all`; `tb.py --at 1004e4b4` | P |
| O8 | 18 | KeyRoutine cheat listing (as S9); `0x100d3e23` gate | identical | P |
| O9 | 19 | A2 `lwz r4,-30460(r2)`, `lwz r12,124(r12)`, `lwz r12,100(r12)` | `ppcdis.py 10094140 10094170` | P |
| O10 | 4 | TOC-word scan → only 0x100cdbd4/0x100cdbfc | reproduced over the whole data section | P |
| O11 | 10 | 4CC scan: none of the six; controls FILT, Lite ×3 | reproduced (m3) | P |
| O12 | 5 | displacement scan "only TViewer members" | reproduced: + 3 non-TViewer names (m2) | ~ |
| O13 | 6 | segment-id immediates: 0xF003/5/6/7/A/14/15/17 zero uses | reproduced: hits only F000/1/4/8/9/B/C/D/E/F/10/13/16 | P |
| O14 | 19 | FC `10066acc mr r31,r3`, `100672dc lbz r14,13(r31)` | ppcdis identical | P |
| O15 | 0/7/8 | 877 / 840 missing, 1,994 tables; `10005d58 lwz r3,-30292(r2)` ⇒ r2 = 0x100D5280; `__ptr_glue` 5 instructions; +0x1F ctor ranges; `Builtin_F9` serial counter | commands re-run; ppcdis; M ctor; B | P |

---------------------------------------------------------------------------------------------
## 3. Cross-file consistency (22 checks)
1. R0EA5 = player buys / R0EA9 = sells: trade §3/§5, library §10.2 ("Shop"/"SellToMerchant"), open-items §7 — **consistent**.
2. 23/22 call count: trade §0/§3/§13.5, library §10.2, open-items §7 — consistent, verified.
3. Literal-10 callers (two R0EA5 + one R0EA9): open-items §7, trade §3/§5, library §10.2 — consistent (N7).
4. 0x4000 = Asleep (ability 22): combat §10, magic §4.1, schedules §2.2/§4.1, open-items §16 — consistent.
5. G11/+6 training: combat §13.2, magic §6, library 0E86 — one label (HIGH), same two quotes — consistent.
6. 0F15 args `(1, k, d, 0)`: library §8, quests §6, schedules §7.1 — consistent.
7. 0xF008 = species records, census by species: combat §4, trade §11, open-items §6/§12 — consistent.
8. `DAT_100d73f2` "difficulty" MED, writers HIGH (restore only): combat §4.1/§16.3, schedules §8.1/§10.6, open-items §7/§8 — consistent.
9. Signal 256 sender (`TakeCommand`, `puVar3` = Nil, False early return): trade §11, schedules §6.2, library §9 300F / §10.5, quests §4.3/§10.3 — consistent.
10. Signal 321 receivers (3015 → 0D06/0D07 by record byte 6; 0D07 shared by 102E, 1846–1849, 1864, 1865 = chars 70–73, 100, 101): combat §11, trade §11, schedules §6.3, library §10.5 — consistent.
11. DoMove head codes 0xA4–0xA7 vs quests activities 164–167: schedules §3.2 and quests §2.3/§4.1/§10.1 agree with the extra dump — consistent.
12. Activity 6: schedules "Beserk" HIGH, trade "Beserk" HIGH, **library §10.5 "attack target [MED]"** — inconsistent (m1).
13. +0x1E census 0:11 (131 entries): schedules §2.3 vs data-format §6.1 l.431 — consistent; +0x16 0x00 ×17 — schedules §2.1 only, verified.
14. R0E84 = to-hit attack/defence bonus: combat §6.3, library 0E84, open-items §7 (+0x1D row) — consistent (m6 applied).
15. Karma table `[1, 4, -10, 0][f35]`: combat §12.3, quests §4.3, library 0E8D — consistent.
16. Sleep bonus bug (magic vs health_max): trade §8, quests §6, library 0E93 — consistent.
17. TStream entry addresses: open-items §8 only (name-field slip corrected); FIXPASS text agrees — consistent.
18. 3043 senders = 8 (3042, 0EA3, 1A06/1A12/1A1D/1A22/1A2D, 0C4C): schedules §6.3, trade §11, library 3043 "script 8" — consistent.
19. Die/LeaveLevel: combat §12.2 read from the extra dump; schedules §0 says Die/LeaveLevel not read for that bank — consistent division.
20. 0x1AF6: magic §1 (0xF1–0xFF are "Do" commands) vs **quests §8 "spell type 246"** — inconsistent (M1).
21. CompileAIFile: schedules §9/§10.2 resolved vs **INDEX 14 "Open"** — inconsistent (M2).
22. show_portrait 238/244: dialogue §10 vs §14 sp column (sums to 244) — consistent.

## 4. Label audit (12 rows sampled)
MED kept rightly: combat §4 byte-7 "no reader anywhere"; trade §3.1 Dymas; schedules §2.1 0x71 low-memory read, §4.4 "nothing restores
prop byte 7"; quests §2.3 "served" reading (N2); dialogue §3.2 reverse chip order; open-items §5 frame-3 byte-6 timing; magic §2.1
PerformMacro path. Could be lifted with the banked tools (no defect): library §9 native-sender scan (N3); combat §12.2 glue target (N4);
schedules §1 test/action distinction (N6). HIGH resting on an un-cited command (register): open-items §4/§10 scans (m3), schedules §5
tables (m5) — the facts hold, the commands are missing. No HIGH was found to rest on unreproducible evidence; no HIGH was found wrong
except C1 and M1.
