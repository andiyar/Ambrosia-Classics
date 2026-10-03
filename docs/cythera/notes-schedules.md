# Notes — schedules & NPC behaviour reader (2026-10-03)

**Read:** census, VM, builtins, rules, engine-classes, data-format §6, ai-scripts; all 19 page-0x09
routines, 0x0C40–55, 0x0D06/07, 0x30xx defaults; DoTick/MoveAll/Guide/HatchEgg/SendSignal/HeartBeat/
TPathFinder/PerformAI. A traceback-table parse (1,952 names) plus scratch Ghidra recovered
`TActiveMonster::DoMove` (0x1004B8E8, 7.9 KB), which the dump lacks.

**Bank:** `schedules-npcs.md`, 491 lines; labels HIGH 108 / MED 19 / LOW 3.

**Top findings:**
- DoMove dispatches all activity codes (full table). Queued codes it does not handle go to selector 33, then 0x3021, then 0x0C00+act.
- Selector 32 is a per-tick "think" hook.
- INDEX 14: +0x1E < 0xB0 holds activity codes 3–8 and 13. Five of these run the scenario AIs 0xD0–0xD4. DoMove calls PerformAI six times.
- INDEX 16: MoveAll is driven by player turns. It has no wall-clock throttle.
- INDEX 18: the all-ally byte is a debug cheat key (0xFA, after typing ©gra).
- Bytecode defects: RunToward walks toward (0,0). OutOfAmmo, EquipRanged and EquipMelee use A31 (char 0), so they do nothing. SetProtecting never leaves the queue.
- Theft and assault use signals 256/320/321. Guards are wired through 0x0D07.

**Open:** banking the scratch tools, the CompileAIFile caller, frame pacing in DrawRoutine, egg re-arming, the post-walk activity restore.
