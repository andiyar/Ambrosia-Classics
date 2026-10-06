# Handoff — 2026-10-03 (night) — Cythera RE deepening, wave 1 (cut short by usage limit)

Orchestrator: Claude Fable 5.1. Branch `claude/dazzling-ramanujan-8d8f23`, pushed to origin (NOT merged to main
beyond Wave 0). Ben lifted the 250k cap mid-session ("ignore cap"); the session ended on the account usage limit.

## Landed on main (reviewed)
- Wave 0, commits dd44f2c + 5b651e5 (merged as de14336): `docs/cythera/tools/scriptdis.py` — decrypts and
  disassembles all 958 script-band segments of `Cythera Data` (918 code, 424,209 bytes, **0 unknown opcodes**),
  listings git-ignored under `ghidra/cythera-scripts/`; `script-census.md`; `script-vm.md` §8 (eight VM
  corrections, all confirmed by the Fable review); `REVIEW-scriptdis-2026-10-03.md` (ACCEPT_WITH_FIXES, 0 Critical,
  2 Major both fixed: 0x45 inline tables now rendered, cross-segment shared methods detected).
  Key facts: selector 28 `attack` has no script method — combat goes native (`DoAttack`) with script hooks;
  0x0101 is a renumbered compiler symbol table naming the 0x0E/0x0F helper routines; `DoInterpRoutine` enters
  page 0x09 from `EvaluateCondition`/`PerformAction`; `DoInterp0` falls back to `0x3000+selector`.

## On the branch only (UNREVIEWED — Fable review + fix pass still owed)
- f8870fc: eight reader banks — `combat.md` 504, `magic.md` 396, `dialogue.md` 621, `trade-economy.md` 508,
  `schedules-npcs.md` 491, `quests-flags.md` 433, `script-library.md` 501 (199/199 routines), 
  `open-items-2026-10-03.md` 468 (INDEX items: 9 resolved, 3 partial, 0 open) + `notes-*.md`.
- c0d8a50: banked the scratch tools the readers used (`tools/tb.py`, `tools/ppcdis.py`, `tools/CyDecompAt.java`,
  `tools/extra-addrs.txt`, `tools/README.md`); regenerated 37 missing function bodies into git-ignored
  `ghidra/Cythera_extra.decompiled.c` (DoMove, Die @100469C0, activities 164–167 = DoMove switch cases);
  `notes-tools.md` lists quoted lines verified (DoMove 8/9, traceback 8/9, rest all) and the three bank edits it
  forces; `notes-critic.md` = completeness critic: **1 Blocker / 7 Major / 23 Minor**, 47 HIGH sampled, 6 failed.
  The Blocker (schedules HIGH rows resting on unbanked tools) is now answerable: tools are banked, the rows need
  re-citation, the two misquotes corrected (§0 bytes at 0x1004D6D4 word 3 = 80120000; §2.1 missing `(ushort)` cast).

## Still owed (next session, in order)
1. Opus fix pass over `notes-critic.md` + `notes-tools.md`: every finding; INDEX Files rows + NOT RESOLVED
   annotations `⚑ corrected (wave 1 2026-10-03)`; `rules.md` cross-reference lines; `data-format.md` (0xF008 first
   0x800 bytes = 128×16 creature table; CharEntry +0x1D/+0x1F); `script-vm.md` §2.1 class 0x28 row (0x1500–0x1502
   are zone scripts under class 0x20; 0x48 = monster-species records); TStream entry addresses in open-items §8;
   "not decompiled" claims now false (AddSound, Die, activities 164–167).
2. ONE Fable-grade reviewer over the six rule files + script-library + open-items: re-disassemble a sample of the
   cited segments independently, demand bytecode/decompile evidence per HIGH claim, report everything.
3. Opus fix pass on the review; then merge the branch to main, push, STATE/INDEX ledger, memory file.
4. Open after that: `tb.py --missing` lists 877 named functions absent from the main dump (re-run CyDecompAt over
   all of them); crystal-quality trigger for the bad ending; prop kind 0x11; globals 0xF005/0xF007 contents;
   `Render` layer order; PORT resource; hintbook PDFs are not in the installed folder (only a link file).

## Hazards learned this session
- Every "not in the dump" function so far decompiled fine via `CyDecompAt.java` at its traceback address.
- Readers quoting scratch tools is the recurring reproducibility leak — the prompt must name the banked tools.
- `pef.py --help` writes a file named `--help` (no argparse); the magic reader removed it.
