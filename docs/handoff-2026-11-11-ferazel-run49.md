# Handoff — Ferazel's Wand, attended run 49 (2026-11-11, Fable 5.2 seat)

**The Phase 6 research is done and reviewed; the Phase 6A plan was not started.** Live state: the Ferazel block of
`docs/STATE.md`. Rulings: D46. Detail: the "As executed" notes under the plan's LL, BOS and ENG cards.

## What happened
- LL, BOS, ENG: one Opus researcher each, two Opus review legs each, a fix round each (BOS also a re-review of its
  large fix round). All three PASS WITH FIXES, fixes merged. No game code, no suite run.
- The research found the plan's Wave 5 cards wrong against the data in about twenty places. Each document ends with
  "Corrections to the plan's cards (for the 6A planner)" — the planner starts there.
- The engine document ends with one ordered list of every 6A task with test counts: the planner's skeleton.

## Owed (run 50, by day, before the plan work)
The four muted launch checks of run 48's handoff ("Owed" 1–3 in `docs/handoff-2026-11-10-ferazel-run48.md`): fresh
stage, G9M, GW6, GWB (expect 617 / 0 / 3 / 0 of 620), GW4R, the cards updated, stage again.

## Lessons
- Three research tasks with two review legs each fill a 300k seat: the plan needs its own run.
- Have reviewers write their full findings to a file and hand back a verdict; the fix round reads the file. The seat's
  context then holds only the verdicts. (Used for ENG and the BOS re-review; BOS and LL legs reported in full and cost
  about three times as much.)
- Two researchers disagreed on two facts (the fireball picture's cuts, the overlay water tint); a reviewer told to
  settle it from the dump did, in one pass. Name such conflicts in the review brief.
- A checker that compares a generator with itself cannot fail; the review caught three such checks.
- `docs/ferazel/tools/__pycache__/` appears when the bank tools run without `-B`; it is untracked — never commit it.

## Open for Ben
Q18 (the Phase 5 gate). Nothing blocks run 50.
