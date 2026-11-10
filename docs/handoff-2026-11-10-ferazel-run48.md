# Handoff — Ferazel's Wand, attended run 48 (2026-11-10, Fable 5.2 seat)

**Phase 5 "Enemies" is closed on the machine side; Ben's gate is Q18.** Live state: the Ferazel block of
`docs/STATE.md`. The plan's A5 "As executed" note and D44's run-48 "As built" paragraph hold the detail.

## What happened
- A5: the relabel sweep, the smoke script reading its reference hashes from the test file, the gate card (two files),
  the ledger note; two Opus review legs; one fix round.
- The Phase 5 Fable cross-check (a Fable `fk-reviewer`, the whole phase diff): no divergence from the dump in what it
  sampled; one fix round, with one new test by the seat's ruling (Core 620).
- The seat's gates: all green (numbers in STATE). Both builds staged at e9183ce, on the Desktop.

## Owed (the next daytime session, before anything else that launches)
1. LAUNCH GUARD; stage both builds afresh from the head (`tools/stage-ferazel.sh`,
   `tools/windows/stage-ferazel-win.sh`) — the smoke refuses a stage older than the head.
2. G9M (the Mac app boots muted), GW6 (the smoke script), GWB (Proof B: expect 617 / 0 / 3 / 0 of 620), GW4R
   (`smoke-ferazel-win.sh --mac-only`) — commands in the plan's "Machine gates".
3. Replace the "boot check owed (night rule)" lines in both cards and the "owed by day" sentence in the suites line
   with the results; commit; stage again; note it under Q18 and in STATE.
The smoke script's new hash-reading has never been run end to end (only its parse and compare blocks): GW6 / GW4R are
its first real run.

## Lessons
- The plan's gate card was wrong against the level data in six places. A card is checked against the data (what is
  placed where, what is reachable before a locked gate), not copied from the plan.
- A background shell that runs the sweep and then the bot carries on to the bot when the sweep is killed: stop the
  outer shell as well. A background command's time limit is real: give long gates hours, not the 10-minute default.
- The cross-check reviewer and a fix round shared the worktree; it worked because the reviewer was read-only and built
  in its own copy.

## Open for Ben
Q18 (the gate). Nothing blocks run 49.
