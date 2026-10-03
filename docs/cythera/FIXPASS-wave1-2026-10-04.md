# FIXPASS — Cythera wave 1 rules banks (2026-10-04, four Opus fixers, Fable orchestrator)

Work order: `notes-critic.md` (1 Blocker / 7 Major / 23 Minor + §3 synthesis plan) and `notes-tools.md` (three forced edits). Evidence regenerated this session before dispatch: main dump 1955/1955, `Cythera_extra.decompiled.c` 37/37 (CyDecompAt.java), builtins 95/95, `tb.py` 1,994 tables, `scriptdis.py` 958 listings / 0 unknown opcodes (census byte-identical to `script-census.md`). Every edit is marked `⚑ corrected (wave 1 2026-10-03)`. Orchestrator rulings on fixer deviations: Fixer B/C cite expression 0x4B in `DoExpr` (main dump) rather than a builtin — correct; magic l.161 "Replicate" is spell 2B's name, kept; `ppcdis.py` cannot read the data section, so the vtable at 0x100D5BAC is read with `toc.py` + `tb.py --at`; `1823 @0474` is an R0EA9 call (two literal-10 buys, one literal-10 sell). Fixer reports follow verbatim.

## Fixer A

# Fixer A report

**Status: DONE_WITH_CONCERNS**

**Applied:** B1, M2, M4, M5, M6, M7 (my part), the notes-tools forced edits (TStream entry addresses, AddSound now decompiled), m2, m3, m5, m6, m13, m15, m16, m17, m18, m22, m23, and item 20. Also the coordinator's recount: the +0x1E census is 0:11 over the 131 non-empty entries. The +0x16 line had the same off-by-one and now reads 0x00 ×17. All scratch quotes re-run with banked tools; every edit marked.

**Found while re-running:**
- CompileAIFile has one direct caller, TEditUserBehavior::DialogItemRoutine.
- Activity 167, queued by routine 0C80, is the only thing that clears the 4/5 latch bits.
- Other register fixes: "replicate" removed in four places in quests, and one sentence of advice reworded in the schedules 0x71 row.

**Label changes:** six MED→HIGH (theft signal 256 in both files, the flag 253–255 row, quests §2.3, CompileAIFile caller, AddSound store); one LOW→MED and one HIGH→MED (the "difficulty" name). Nothing had to drop to MED as unreproducible.

**Not re-run:** three older open-items scans (§4 TOC words, §5 displacements, §10 4CCs).

**Reviewer:** the 0C80 "wait until served" reading (MED); the toc.py vtable recipe wording in schedules §4.2.

**wc -l:** schedules-npcs 545, quests-flags 454, open-items 523.

## Fixer B

# Fixer B — combat / magic / trade-economy

**Status: DONE_WITH_CONCERNS** (not committed, not staged)

**Applied** (each edit marked): M1, M7 (combat), m4, m5, m6, m7, m8, m9, m14, m16, m19, m23.

**Not applied, and why:**
- m16 magic l.161: "Replicate" there is spell 2B's in-game name (`1a2b @000B`), not advice, so it is unchanged.
- M7 `ppcdis.py --hex` cannot read 0x100D5BAC ("outside the code section"). I read the vtable with `toc.py` `data_u32` and named each target with `tb.py --at`.
- m14: DoExpr is not a builtin. I cited the main dump instead (DoExpr case 0x4b, GetGlobal default → Nil).

**Labels:** 6 MED→HIGH (Die §12.2; difficulty writers; ability 21; activity 6; durability; magic training). 1 LOW→HIGH (ability 21). No HIGH→MED. The name "difficulty" is now MED.

**Reviewer, please check:**
- Census: 0xF0xx is read raw, not decrypted. Value 0: 115 characters (101 reach R0D06). Value 1: chars 14/92/94. Value 2: chars 1–3. No character has value 3.
- The vtable section-base step, which was applied by hand.
- Two new Die facts: the leader's index is rewritten to 1, and `param_1[5]` has no null test.

**wc -l:** combat 580, magic 398, trade-economy 538.

## Fixer C

# Fixer C report — dialogue.md, script-library.md

Status: DONE_WITH_CONCERNS

Applied: M3, M7 (dialogue part), m1, m9/M5 cross-check, m10, m11, m14, m16, m22, library calls-in command. Every edit carries the wave-1 marker.

Not applied as briefed: DoExpr case 0x4b is in the main dump (`.DoExpr__7TInterpFRPUc @ 1007ddfc`), not in the builtins file; I cite the main dump. Also, 1823 @0474 is an R0EA9 (sell) call. R0EA5 has only two literal-10 callers (1869, 186A), and the text now says so.

Labels: 7 raised (6 MED→HIGH, 1 LOW→HIGH; 0F15 had both MED and LOW). None lowered. Every ppcdis quote reproduced.

Reviewer, please check:
- New code facts I found: mygetch's per-character branch stores one pointer (sp+64) in every chip slot, though no shipped prompt reaches it. The KeyRoutine filtering claim is corrected. UpdateCharName runs with no null check outside a conversation.
- A new corpus analyser is embedded in dialogue §0. It reproduces every catalogue column and total.
- I fixed show_portrait 236 to 238/244.
- Library §0/§9 native-sender scan is still unbanked (stays MED).

wc -l: dialogue.md 657 (just over ~650), script-library.md 519.

## Fixer D

# Fixer D (synthesis) — report

Status: DONE_WITH_CONCERNS

Applied: critic §3 synthesis plan item by item (INDEX Files rows ×8 + notes row; provenance tools/extra-dump/traceback rows; NOT RESOLVED 1–19 annotations; new items 20–25; review ledger + m21 rename note), m20, rules.md six cross-refs, data-format §1/§1.5/§3.1/§3.3/§4.2/§4.3/§5/§6.1/§7, script-vm §2.1 0x28/0x48 + §8 FFFF note, script-builtins §4, tools/README recipes, STATE line (task wording).

Verified this session: extra dump 37 blocks; tb.txt 1,994 lines (C++ 1,952); --missing 877, 840 after the extra dump; 0xF008 2048 B, 50 used, tail 0; 0816/0EA5 callx sites; 9 WhereIs tables = 114 entries; LoadLevelMap rlwinm via ppcdis; DoMove's six PerformAI calls.

Labels: MED→HIGH 4 (script-vm 0x28, 0x48; data-format +0x18 LOW→HIGH, +0x1E MED→HIGH; B4 row MED→HIGH); NOT RESOLVED→HIGH on ~14 data-format rows.

Not applied: gen_classmap row (accurate as is). D4 flag left open.

Reviewer: schedules §2.3 census says +0x1E 0:10, data-format's 0:11 recounts correct (131 entries). ARCHIVE-INDEX claims hintbook PDFs in the installed folder; only a link file there — a copy is in ambrosiaarchive-mac/RPG/Cythera.

wc -l: INDEX 177, rules 147, data-format 508, script-vm 269, script-builtins 187, tools/README 41, STATE 55.

