# Notes — shared routine library reader (2026-10-03)

Read: census, script-vm, script-builtins; all 199 listings on pages 0x08, 0x0A–0x0F, 0x30; caller
lines across all 958 listings (scratch xref; page totals match census §7); TakeCommand, the
DoInterp wrappers, and a raw-PEF `bl`/`li r4` scan for native selector senders.

Output: `script-library.md` (501 lines), 199/199 routines, rows 171 HIGH / 27 MED / 1 LOW.

Top findings:
- Selector 33 is sent natively with 5 args (0x1004d554, undumped function) → 0x3021 →
  0x0C40–0x0C55 = queued-activity opcodes 64–85; six opcodes are never queued.
- 0x0816 and 0x0EA5 hand non-routine values to 0x9C FFFF in shipped data (113/114 and all entries),
  making the script-vm §8 stack-slot question live.
- 0x0D07 = guard reaction to signals 256 (native theft) / 320 / 321.
- Dead: 36 routines; corrections to census: 0D03 and 0EA6 transitively dead; only 5 of 37
  "uncalled" 0x30 handlers are actually unreached.
- Quirks banked: 0E87 skill bonus reads the wrong local, 0E93 caps magic at health_max, 0E0D never
  fills the pitcher, 0D02 mixes value/count units, 0EA9 uses a list after release, 0E81 `& 0`.

Open: dump 0x1004b824–0x1004d704; settle the callx stack slot; 0F15 location; G11 arithmetic.
