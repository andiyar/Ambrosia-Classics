# Cythera RE bank — implementer report (2026-10-03, Opus implementer; saved by the orchestrator)

Status: DONE_WITH_CONCERNS. Files: INDEX 114, data-format 467, script-vm 220, ai-scripts 303, rules 130,
engine-classes 162, engine-classmap-1/2/3 558/533/275 lines; tools/: seg.py, lz.py, pef.py, toc.py, rsrc.py,
demangle.py, gen_classmap.py. Label counts (`cat data-format.md script-vm.md ai-scripts.md rules.md
engine-classes.md | grep -o LABEL | wc -l`): HIGH 196, MED 56, LOW 9, NOT RESOLVED 36; INDEX consolidates
18 open items.

Main finding: most game rules are not in native code. Combat, spells, talk and trade run as encrypted
bytecode in `Cythera Data`. Documented: the segment-file format, the XOR encryption keyed on each
segment's id, how a save game layers over the data file, the script VM's opcodes and dispatch, the AI
compiler and evaluator, the schedules. Open: the builtin opcodes (0xA0 and up) call into ~29.5 KB of code
after `IsString__7TInterp @ 10093e14` that Ghidra never turned into functions.

Least sure: (1) clock ↔ turns — each tick of the party leader adds one clock unit, so a step costs ~10
units; (2) which map-header fields are the N/E/S/W exits; (3) CharEntry +0x1B is food and gates healing,
+0x1E is combat behaviour.

Attack first: every xxd block (one in ai-scripts.md was first typed from memory and was wrong; replaced
with real output — re-run all of them); the script-VM opcode tables; the overlapping class ranges (0x50 and
0x58).
