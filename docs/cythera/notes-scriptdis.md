# scriptdis notes (2026-10-03)

**Built** `tools/scriptdis.py` (stdlib): decrypts, classifies, disassembles every script-band
segment → 958 git-ignored listings in `ghidra/cythera-scripts/` + `script-census.md`. 918 code
segments (700 class, 218 routine), 424,209 B; **0 unknown opcodes**, 0 anomalies, 0 undecoded
bytes. §5 worked decode (0x1802 @0292) reproduced.

**VM corrections** in script-vm.md §8.

**Fix pass** (REVIEW-scriptdis-2026-10-03.md): 176 `0x45` inline blocks (26,569 B, 80 listings) are
now listed under their instruction and booked as literal bytes (statements 353,152, literal
68,803). Cross-segment dictionary code pointers are shared methods: 1,030 methods (7 shared, all
signal → 0x0D07; signal 35/0), 643 properties; 0x0D calls-in 97. 33 page-0x0E/0x0F routines
named from the renumbered 0x0101 symtab. §8: stale-slot builtins, 0xFF = null TVector, 0x9C leak
[MED]. INDEX pointers added.

**Unresolved:** fields ≥0x29, 0x9B classes, 0x1E20's class, 0x0A/0x0C families.

**Ghidra:** `GHIDRA_PROJ=/tmp/ghidra-proj-cythera ghidra/decompile.sh Cythera_pef -processor
PowerPC:BE:32:default -cspec macosx` → "wrote 1955/1955", 73,652 lines; builtins recipe → "wrote
95/95", 3,294 lines. Both git-ignored.
