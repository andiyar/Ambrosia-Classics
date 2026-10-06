# Handoff — Ferazel's Wand design + Phase 0/1 plan — 2026-10-06 (CLOSED: design approved, plan reviewed; nothing implemented)

Orchestrator: Claude Fable 5.1. Ben's brainstorm answers → DECISIONS D26. Outputs on `main`:
- `docs/plans/2026-10-06-ferazel-design.md` — APPROVED architecture (three layers + Windows twin), oracles, phases 0–7.
- `docs/plans/2026-10-06-ferazel-phase1.md` — Phases 0 + 1, 15 tasks, contracts not code; Opus planner (552k tokens,
  21 probes over `$FW`), Fable review ACCEPT_WITH_FIXES (3 Important / 12 Minor), Opus fix pass; ledger at the end.
- `docs/STATE.md` bullet; DECISIONS D26.

**What the next session does:** execute Phase 0 tasks **K1 (HectorKit, ⚑ MAJOR), C0 (data into git), C1 (package
skeleton)** — the chip carries the trigger. Sized at 3 tasks because C0 and C1 are small.

**Receipts the successor would otherwise re-derive (planner probes, 2026-10-06):** 770 PICTs (v2 765: 8-bit 427,
4-bit 11, 2-bit 1, 32-bit 326 all mode 64; v1 1-bit 5), 79 cluts (24 "+ base" with 0x00..0x9f == clut 200), 172 `snd `
(138 × 22050, 33 × 11025, 1 × 22254.5 Hz), 28 AIFC (SSND = packets × 68), level 1: 162 active placement records, 42
distinct types; CLUT 202 disagreement 4-bit vs exact = 75,461 / 211,731 table entries. The probe scripts lived in the
session scratchpad (not committed); the plan's Research notes carry every number.

**Open for Ben:** the Let's Play link for part one (design §2). Nothing else.

**Hazards carried:** D-numbers collide across parallel sessions (D25 was taken while this ran); decompiles are
git-ignored and absent in fresh worktrees (`ghidra/regen-ferazel.sh`, ~6 min); the Deimos session may move the
HectorKit floor — re-read `tools/check-zero-skip.sh` FLOOR when K1 starts.
