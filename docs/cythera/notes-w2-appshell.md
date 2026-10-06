# notes — wave 2 reader R3 (app shell, census group C) — ⚑ wave 2 (2026-10-06)

**Status:** done. Group C re-derived from the census classifier: 125 rows / 30,876 B (agrees);
**125/125 bodies read whole**, plus main-dump context (main, RunStart, DoItemHit, NewGame,
CreatePlayer, DoPrefs, TPrefs, TTaskMaster, MoveAll, DoTick, PerformAI, EvaluateAI) and
`AnimThread` (group D).

**Files:** NEW `app-shell.md` (490 lines); `engine-classes.md` 175 → 230; `ai-scripts.md`
312 → 378; `data-format.md` 508 → 559.

**Items:** 14 CLOSED (TVector scan re-run: only the RangeIter control; 8 sites, all `bl`).
16 wall-clock half CLOSED: the scheduler paces the anim thread at F = prefs byte 0 bits 2–5 ticks
(4/6/8); all defaults F = 6; menu 0x88 is never inserted, so 10 frames/s in practice; only
transitions wait inside DrawRoutine. 16 layer order still open (Render outline only, LOW).

**Doubts for the reviewer:** "menus 0x83/0x88 never inserted" rests on an absence scan (MED);
leader sub-steps per tile (1/2/4) depend on HandleMove's starting phase (not traced);
`main` catch-handler types are inferred from messages; TRunStart::CloseRoutine and
TMemoryStream::ReadTo bugs are disasm-checked.

## Proposed INDEX lines
- `app-shell.md` — startup (InitMac/PostInitMac), MEL + event dispatch, threads + MyScheduler +
  TaskThread, menus/CMNU 129 commands, start screen, NewGame/CreatePlayer, open/save/quit, prefs window.
- NOT RESOLVED 14 → CLOSED (ai-scripts.md §9.1). 16 → wall-clock half CLOSED (engine-classes.md
  §3.4); remaining: `Render__7TViewer` layer order.
- data-format.md §8 — prefs file keys + "UI Prefs" bit table + CPU defaults.
