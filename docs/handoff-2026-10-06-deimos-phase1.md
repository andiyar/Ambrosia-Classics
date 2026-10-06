# Handoff — 2026-10-06 — Deimos Rising: Phase 0 done, Phase 1 planned (level 1 look)

**TL;DR.** Deimos RE bank closed (938 rows 716/222/0). Phase 0 (data + decoders + census) merged to main f447609;
HectorKit main 33d4dee (floor 301). Ben's build rulings = **D27** (whole game Mac + Windows; first gate = level 1
look, no gameplay; 640×480 whole-number scale + black border; feel oracle = YouTube longplays + his eyes).
The whole-game design + Phase 1 plan are written and pushed on branch **`deimos-phase1`** (5106149, worktree
`.claude/worktrees/deimos-phase1`), **not yet reviewed, not yet executed.**

## Read first
- `docs/plans/2026-10-06-deimos-design.md` (layers: DeimosCore / DeimosRender RGB555 / DeimosHost driver shared by
  both shells / Deimos/App on HectorShell; phases 1 look → 2 level 1 plays (de01 film gate) → 3 campaign (de02–04)
  → 4 front end → 5 Windows + release).
- `docs/plans/2026-10-06-deimos-phase1.md` (tasks K1, C1–C6, R1–R3, H1, A1, A2; Deimos/Core 104 → 177; kit 301 → 304;
  gate card; research probes p01–p10; three queued bank corrections).
- `docs/plans/2026-10-06-deimos-phase0-data.md` "As built" (every plan-literal correction).

## Next session, in order
1. Fable review of the two plan docs (contracts vs bank + listings), one fix pass, merge main into the branch.
2. Execute Phase 1 in waves: Opus implementers in parallel on disjoint files in the one worktree, Fable review per
   wave, one consolidated fix pass; land K1 on HectorKit main before Classics consumes it (shared symlink → main
   checkout). TaskStop any agent whose notice says background work is still running.
3. Stage `~/Desktop/Deimos Rising.app` + WHAT-TO-EXPECT; Ben's gate 1.

## Machine hazards
- **No Deimos decompile on this machine** (`ghidra/Deimos_pef.decompiled.c` absent). Oracle = `~/ghidra-proj-deimos/
  disasm-review3-all.txt` + `mem/10000000.bin` / `mem/100de330.bin` (r2 0x100e6330). Tell every reviewer.
- **Ferazel build is running in parallel** (session "Ferazel Phase 0: K1 + C0 + C1"). Its A1 also wants integer full
  screen; told it Deimos K1 (`ShellView.scalingPolicy`) is the one implementation — whoever lands first, the other
  reuses. Check HectorKit main before writing K1. Don't touch Ferazel files.
- D-numbers collide across sessions — `git fetch` and read origin/main's DECISIONS before numbering (plan proposes D28).

## Questions for Ben (defaults let work proceed)
Phase 1 needs only Q1. Q1 tick rate 60.15 (OS 9) vs 60 Hz — default 60.15. Q2 pitch direction (P2) — as read.
Q3 music full scale 255/256 (P2) — 255. Q4 volume keys (P2/4) — OS 9 behaviour as app gain. Q5 invulnerability at
level start 2–12 (P3) — as read (~61 ticks). Q6 title upright (P4) — upright; Phase 1's map is first evidence.
Q7 gate order P2–4 — play first (Ferazel went front-end early). Q8 Set Controls (P4) — build DITL 191 dialog.
