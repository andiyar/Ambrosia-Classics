# Handoff — 2026-10-03 — bootstrap session (Aki recon → archive mirror → HectorKit + Classics)

**What happened.** Reconnaissance of Aki 1.1.0 (PPC Carbon C++, unstripped; Ghidra dump at
`~/Developer/Ambrosia/ghidra/Aki_ppc.decompiled.c`). Mirrored ambrosiaarchive.com/mac (709 MiB) and
opened every container; recovered complete Bubble Trouble X 1.1 UB, Ferazel's Wand 1.0.3 (full CD,
NDIF → ndif2raw → VISE 3 → installer-vise), Deimos Rising 1.0.6, Cythera 1.0.4, Aki 1.2 UB (Cocoa
rewrite). Map: `~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md`. Tooling lessons in project memory
(`classic-mac-archive-tooling`).

**Decisions with Ben (all in the design doc, not yet a DECISIONS ledger — seed it at the first fork
closed in a build session):** separate repos (this + HectorKit) instead of renaming inside EV;
HectorKit name (Hector D. Byrd); Aki first, Bubble Trouble X second; level editors in scope but last
per game; display scaling = integer-crisp default + fit-smooth + optional offline HD packs; RE-bank
lane for the whole hit list as its own session.

**State of the repos.** Doors + design + STATE + RESUME + ghidra scripts committed; **zero code**.

**Next.** Two chips issued (RESUME.md Triggers A and B). Ben's written review of the design doc gates
Trigger B; Trigger A can start now. Nothing is blocked on Claude.

**Resume phrase:** "Ambrosia Classics — pick up from the 2026-10-03 bootstrap handoff."
