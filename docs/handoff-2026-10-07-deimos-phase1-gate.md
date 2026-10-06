# Handoff — 2026-10-07 — Deimos Rising Phase 1 (level 1 look): built, merged, staged for Ben's gate 1

**TL;DR.** The Fable review of the design and Phase 1 plan (ACCEPT_WITH_FIXES, 0/4/9, fixed) and then all of Phase 1
(K1, C1–C6, R1–R3, H1, A1, A2) are done. Every task was Fable-reviewed (MAJOR tasks got two legs) and three fix passes
were each spot-reviewed. Merged to main **c3b4e95** (fast-forward of branch `deimos-phase1`). HectorKit main **522feb8**
(K1 = HectorKit D13, floor **316**). `Deimos/Core` **189/0/0**, census unchanged, Deimos + Aki + BubbleTroubleX BUILD
SUCCEEDED. **Staged `~/Desktop/Deimos Rising.app` + `Deimos Rising — WHAT-TO-EXPECT.md` (the gate card). Ben's gate 1
is pending: "does it look like Deimos".** Rulings: DECISIONS D29 + its as-built addendum.

## What happened, briefly
- The plan review found 4 Important issues: K1 had already landed (floor 316, D13); D28 was taken, so this lane uses D29;
  `testFloatRange` assumed a fresh seed per call; the level start's black fill was missing, so a `RenderOp.fill` case was
  added to the LOCKED seams.
- Waves ran in parallel in the one worktree (C2 ∥ C1; C3 ∥ R1; C4 ∥ R2; C5; C6; R3 ∥ A2; H1 ∥ A1). The listing beat the
  plan three times, and the plan was corrected each time: `COST` clipping, input outside state 4, and the
  `updatePhase1(scoreBar:)` signature.
- The H1 review found a **Critical**: holding Esc for 35 ms or more hung `idle` forever (a restart loop), and the same
  hang happened at tick wrap. Fixed with an Esc latch and bounded work per `idle`, plus regression tests proven to fail
  before the fix. The fix was independently verified: a 2-second hold gives exactly 1 restart.
- The R3 frame goldens (FNV-1a) were re-derived by a reviewer's own Python compositor, and every one matched exactly.
- The app suspends while in the background or miniaturised (the original suspended on collapse). Live screenshots
  weren't possible: Ben declined computer-use access and `screencapture` is refused. Headless frame dumps (pass 200
  looked right to the orchestrator) and boot checks stand in for them.

## Next session
1. **Ben's verdict on gate 1.** If anything is wrong, find the card item. The MED suspects (card "Not yet certain"):
   the 24→16 colour cut, TGA orientation, the `tesm` digit widths. Q1: if he says "60", switch `TickRate` to `.osx` in
   `Deimos/App/DeimosController.swift` (one line), restage, and record it in DECISIONS.
2. Then write the **Phase 2 plan** (level 1 plays; the machine gate is a de01 film replay reaching 25,050 at tick 4,809).
   Same method: Opus planner → Fable review → waves. Carries: a `DeimosAudio` target (design-review M6), K2 pull-PCM
   stream voice in the kit, `HeadlessRun` taking film/start params, `playerOps` return type, Phase-4 prefs-file widening
   (C1 review m3), the latch-eats-sub-pass-release note (final review), the P1 button mapping (bank LOW).
3. Housekeeping: HectorKit worktree `~/Developer/HectorKit-worktrees/deimos-k1` and remote branch `deimos-k1` are merged
   (same commit as main) and can be removed. Branch `deimos-phase1` = main and can be deleted once Ben passes the gate.
   The Classics main checkout (`~/Developer/Ambrosia-Classics`) has not been fast-forwarded locally.

## Machine notes
- The Deimos listing + memory images now live in `~/Developer/Ghidra/deimos/proj/` (Ben, 2026-10-06; the repo's
  `ghidra/deimos-proj` is a symlink). The 31 reader project copies are zipped there (`project-copies-backup.zip`).
- `Deimos/DeimosCore → Core` symlink: project.yml points at it (SwiftPM identity clash with `Aki/Core`).
- Parallel implementers in one worktree: each used its own `swift test --scratch-path`; commit with explicit paths.
  It worked, but one implementer's unguarded test hung another's xctest run once.
