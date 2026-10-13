# LOOP-LOG — one line per unattended run (appended by the run itself at CLOSE; D34)

> Line format (the kit's standing prompt):
> `<date> | run <N> | <what landed> | gates: <results> | boots: <count/result> | merged <SHA or "none">`
> "gates" names the numbers (Ferazel/Core N/0, census, G5, HK floor); "boots" is the G9 count on phase-end runs (else
> `n/a`). The looper's own ledger (`.looper/logs/looper.log`, git-ignored) records exit codes and worktree state per run;
> this file is the project-side history a cold reader can trust. A run that merged nothing still writes its line (why).

2026-10-13 | run 0 | looper set up (D34; not a loop run — the setup session; first loop run = P1a P1b) | gates: Ferazel/Core 154/0, census 1,108/0, Ferazel BUILD SUCCEEDED, HK 0c65dcb clean floor 328, G9 1/1 | boots: 1/ok | merged (setup commits on main)
