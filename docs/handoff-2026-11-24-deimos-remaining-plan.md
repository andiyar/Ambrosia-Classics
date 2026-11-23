# Handoff — Deimos Rising: the plan from today to the release (2026-11-24)

Seat: Claude Fable 5.2, planner. Nothing was built, launched or staged. No file under `Deimos/`, `project.yml` or
HectorKit changed.

## What was done

| Thing | Where |
|---|---|
| The plan for everything left, four phases through the release | `docs/superpowers/plans/2026-11-24-deimos-to-release.md` (the one authority) |
| The seat's rulings | `docs/DECISIONS.md` D66 |
| Eleven questions for Ben, each with what it blocks | `docs/QUESTIONS.md`, "Deimos Rising — open", DQ1–DQ11 |
| STATE's Deimos block points at the plan | `docs/STATE.md` |
| The two earlier plans marked superseded | the 2026-11-05 remainder plan, the 2026-11-20 Phase 4 plan |
| The two review legs' full findings (outside the repo) | the session group's notes folder: `deimos-plan-review-leg1-spec.md`, `deimos-plan-review-leg2-quality.md` |

No grounding appendix was needed: every fact the plan uses is in the research bank (`docs/deimos/osx-build.md`,
`INDEX.md`) or the Phase 4 closing review; the facts still missing are the comparison's own job (task 6-CMP).

## The phases

| Phase | What | Size | Waits on Ben for |
|---|---|---|---|
| 5 Loose ends on the Mac | eight known faults; small follow-ups; the OS X build's pause on leaving the app, cursor, Preferences… and Edit menu; the end boss beaten by a test; records put right; then the fixes from his play notes | 3 sessions plus his notes' fixes | gates 2, 3, 4 and the keyboard replay |
| 6 The two builds compared | every function that differs between the OS 9 and OS X builds read and classed; play differences built to follow OS X if the demo films still pass; the research notes closed | 2 sessions, plus 1–2 if play differs | nothing to start |
| 7 Windows | cross-build proof, the shared half, the game on SDL, the Windows-only edges, stage and smoke | 4 sessions | a tester on a real PC |
| 8 Release | icon, package script and notes, closing review, draft release, publish, close out | 2 sessions | the icon pick; trying the download; "publish" |

## Review

- Spec leg (Opus 5.5): pass with fixes — 1 blocker, 20 should-fix, 14 minor, 9 overflow. The blocker: the draft said
  the game stays paused when you come back to the app; the OS X build ends the pause on return unless Caps Lock is on.
- Quality leg (Opus 5.5): pass with fixes — 12 should-fix, 8 minor; it confirmed the first leg's pause findings
  against the research and found four of its rows half applied.
- All folded in. The seat's cross-check: the method's self-check searches (no line pointers into documents, no
  ruling-number pointers, one authority line), every count against its named tests, the order paragraph against
  each section. **Honest limit:** the seat's context was at its cap by then (see below), so the cross-check was
  those checks and a read of every changed passage, not a fresh end-to-end read of the final text.

## Left open, on purpose

- Two task slots have no content yet: the fixes from Ben's play notes (5-GN) and the fixes from the comparison
  (6-FX). The plan says who writes their cards, where, and what review they get before any dispatch.
- Not done here, listed for whoever picks it up: other games' Ghidra logs also carry home-folder paths (a
  repo-wide chore); the older October Deimos plans get their "superseded" line in task 5-DOC.
- The seat's context: 278k at the second review dispatch, 299k of the 300k cap at the close. The plan was the one task
  in flight; nothing else was started.

## The brief for the next session (only after Ben says go)

Read `CLAUDE.md`, the Deimos block of `docs/STATE.md`, and in the plan: "Verification model (read first)" and the
section you are running. Run Phase 5 in the order the plan's "Order" paragraph gives, starting with task 5-QF. Say
which model you are in your first message. Do not start before DQ1 is answered.
