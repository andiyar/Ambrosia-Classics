# Notes — tools banking (2026-10-03)

**Banked** (`tools/`, recipes in headers + `tools/README.md`): `tb.py` (traceback names), `ppcdis.py`
(PPC decoder), `CyDecompAt.java` + `extra-addrs.txt` (create + decompile listed addresses).

**Regenerated** (ignored): `ghidra/Cythera_pef.tb.txt` (1,994 tables; `--cxx-only` = 1,952, identical to
the scratch run); `ghidra/Cythera_extra.decompiled.c`: **37/37 decompiled**, none failed, each body =
its traceback extent. Activities 164–167 are DoMove switch cases (table 0x100D5A1C → 0x1004BD8C,
BE24, BEB4, BF78), inside the DoMove block.

**schedules-npcs.md:** DoMove matches scratch except its name. Decompile quotes 8/9; DoMove disasm 7/7;
traceback claims 8/9. Also KeyRoutine 11/11, MoveAll 4/4, TOC scans 2/2, vtable 13/13.
**open-items:** `ppcdis.py` confirms KeyRoutine 0x10043C58–FEC 9/9, WriteData dispatch
0x10017D50–DC0 10/10 compares, `__ptr_glue` 5/5, cheat test 2/2.

**Fix pass must change:**
- schedules §0: tb word 3 is `80120000`, not `80010000`; §2.1 quote lacks `(ushort)`; replace
  *(scratch)* by the banked tools; §10.1 done.
- open-items §8: TStream addresses are name fields; entries are ReadData 0x10017990, WriteData
  0x10017CFC, BeginChunk 0x10018134, EndChunk 0x100181E0, ReadChunk 0x100182A4, IsEOChunk 0x1001837C.
- "Not decompiled" is now false for AddSound (open-items), Die (combat), activities 164–167 (quests).
