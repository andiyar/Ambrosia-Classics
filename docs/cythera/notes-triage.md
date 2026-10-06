# notes — wave 2 triage reader (2026-10-06)

**Status:** DONE. Wrote `missing-census.md` (252 lines). No bank file touched.

**Read:** all 840 missing-dump names, grouped by class and family with byte totals (840 / 158,680 B —
matches the orchestrator); the two largest bodies of every group of three or more skimmed; whole
bodies read for TTaskMaster (TaskThread, MyScheduler), TDelverApp (DefaultMenu, MyGetEvent), TApp::MEL,
cmpprops/cmpskills; one main-dump body (`PlaySound__6TAudio`) for the D4 lead.

**Count correction:** nested `TScriptedWindow::TWidget` = 17 rows, not 16 (its own dtor). The 178 free
functions = 95 builtins + 41 std + 17 TWidget + 2 nested ctors + 23 true free functions.

**Items:** 14 closable (no TVector or vtable word for PerformAI/CompileAIFile; all callers are direct
`bl`s; new caller chain via TCharacterWindow). 16 and 19 have strong leads (scheduler tick spacing from
the prefs byte; PlaySoundSync waits for the channel). 23 has a MED lead (TWMusicBox selector 10).
N3 is reproducible and liftable. 5, 6, 10, 21, 22, 24, 25 and N2: no new body touches them (greps in §2).

**Doubts:** roles are MED (skimmed); the music-box → signal link is unproven.

Proposed INDEX line (Files table):
| missing-census.md | ⚑ wave 2 (2026-10-06): census of the 840 missing-dump bodies — families, byte totals, roles, bank owner per group, per-item leads (14 closable, 16/19/23 leads), reader split R1–R4, builtin opcode → traceback-name table |
