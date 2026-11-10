# Handoff — Ferazel's Wand, attended run 47 (2026-11-08, Fable 5.1 seat)

**What landed (main bc31efa (the code head; the close documents sit on top), pushed):** the wave 5.4 Fable cross-check that runs 44–46 never had (clean; one tests-only
fix round), OX (level 5's moving sky), LV5 (level 5 enterable up to the Warrior's arena). Core 607 → **619**. Full
account: the As-executed notes under `#### OX` and `#### LV5` in the plan, the run 47 As-built paragraph in D44, the
LOOP-LOG line, STATE's Ferazel block.

**What is next:** run 48 = A5 + the Phase 5 Fable cross-check (the Phase 5 machine end, both builds staged, the gate card
for Ben). Ben held the chain for quota on 2026-11-08 and released it on 2026-11-10; this run's close started run 48
("read docs/NEXT.md and run it", fresh context, same seat model). The wave-end sweep kernel-panicked the Mac on 2026-11-08 and
again on 2026-11-10: a per-visit leak on the Windows game path (a finished game was never freed) and no memory limit in
the scripts. A second seat session fixed both on 2026-11-10 (36e9a58, fafc00f, 33f52b8, bc31efa), proved one worker flat
(928 visits, 295 MB peak), then ran the sweep, the bot and Proof B green. The story: `docs/handoff-2026-11-10-ferazel-run47-resume.md`.

**Things the next seat should know:**
- The sweep and the bot now kill a worker past 4 GB and write a `memory` row (exit 1). Never raise the limit to get a run
  through: a memory row is a leak to fix. Stop a background run with `kill <script pid>`. WinKit ladder is **82**.
- The ladder runs +1 over the plan's October numbers since this run (the cross-check's geyser test): A5 → 619, Proof B
  616 / 0 / 3 / 0 of 619.
- A fix round that adds or removes a source line moves `DrawModeAuditTests`' line-pinned writer rows; its leg must run
  that class. This bit twice in run 47 (the Crab comment; the Gremlin cache-list pin was a different cause — the
  Warrior's three sets now registered at the original's position).
- The seat's own full suite found what the implementer's filtered classes missed (the Gremlin pin). Keep running it in a
  `git archive` copy at every head.
- The app refused `git worktree remove` for the finished run-44/45 worktrees (classified as destructive). Ben removes
  them, or the next seat tries once and moves on.
- Phase 6 stand-ins named for the gate card: the Warrior's pre-lock rocks (type 1075) and wounded glow, its
  shot-absorbing Hit; the Warrior's AI, shot and Kill (track 30, the gate opening) — all tested through a synthetic
  "boss dead" flag, unreachable in play this phase.
