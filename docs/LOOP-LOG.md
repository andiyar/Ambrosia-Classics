# LOOP-LOG — one line per unattended run (appended by the run itself at CLOSE; D34)

> Line format (the kit's standing prompt):
> `<date> | run <N> | <what landed> | gates: <results> | boots: <count/result> | merged <SHA or "none">`
> "gates" names the numbers (Ferazel/Core N/0, census, G5, HK floor); "boots" is the G9 count on phase-end runs (else
> `n/a`). The looper's own ledger (`.looper/logs/looper.log`, git-ignored) records exit codes and worktree state per run;
> this file is the project-side history a cold reader can trust. A run that merged nothing still writes its line (why).

2026-10-13 | run 0 | looper set up (D34; not a loop run — the setup session; first loop run = P1a P1b) | gates: Ferazel/Core 154/0, census 1,108/0, Ferazel BUILD SUCCEEDED, HK 0c65dcb clean floor 328, G9 1/1 | boots: 1/ok | merged (setup commits on main)
2026-10-13 | (interactive) | not a loop run — an interactive Opus orchestrator session built P1a P1b P2 P3 (two Opus legs each + fix rounds + one re-review), merged a40fc96; looper setup merged into local main; NEXT.md → P4 P5 | gates: Ferazel/Core 185/0, census 1,108/0, Ferazel BUILD SUCCEEDED, HK 0c65dcb clean floor 328 | boots: n/a | merged a40fc96 + merge of 4887c9f
2026-10-13 | run 2 | P4 (liquids, hazards, breath, death, underwater light) + P5 (.PlayerScroll replaces the focus driver) — wave 2.2 done; one Opus leg each + fix rounds (P5's re-reviewed MERGEABLE); P3 fix round reviewed + confirmed; Invariant-10 STOP ruled (crunch test re-measured 18 → 17 under the real camera); ◈ pan goldens moved; run 1 merged nothing (ended turn with a background agent; its dirty worktree kept) | gates: Ferazel/Core 203/0, census 1,108/0, Ferazel BUILD SUCCEEDED, G7/G10 empty, HK 0c65dcb clean floor 328 | boots: n/a | merged 46a6984 + docs close
