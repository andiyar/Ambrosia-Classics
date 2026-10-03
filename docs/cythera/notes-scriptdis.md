# scriptdis notes (2026-10-03)

**Built** `tools/scriptdis.py` (stdlib): decrypts, classifies and disassembles every script-band
segment; listings in git-ignored `ghidra/cythera-scripts/` (958 files); census
`script-census.md`.

**Counts:** 918 code segments (700 class, 218 routine), 424,209 bytes; **0 unknown opcodes**,
0 anomalies, 0 undecoded bytes; 2,254 dead-code bytes (mostly `return 0` epilogues).

**Validated:** §5 worked decode (0x1802 @0292) reproduced; routine 0x0F02 and class 0x1001's
`use` method hand-checked byte by byte.

**VM corrections** (script-vm.md §8): text ends at NUL *or* ≥0x80; absolute branches; call
encodings; 0x9B statement form; only globals 0x0C/0x0E writable (0x11 writes dead); iterator
loop shape; 0x0101 is a plaintext symbol table; Nil string entries.

**Unresolved:** names of fields ≥0x29 and 0x9B classes; 0x1E20's class; native callers of
0x0B00, 0x0F03–0x0F10, eleven 0x0E routines; builtins called with fewer args than banked (read
stale stack). INDEX.md pointer not added (outside commit list).

**Ghidra:** `GHIDRA_PROJ=/tmp/ghidra-proj-cythera ghidra/decompile.sh Cythera_pef -processor
PowerPC:BE:32:default -cspec macosx` → "wrote 1955/1955", Import succeeded, 73,652 lines;
builtins recipe (project copy in scratchpad) → "wrote 95/95", 3,294 lines. Both git-ignored.
