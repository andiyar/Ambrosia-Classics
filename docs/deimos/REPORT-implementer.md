# Deimos Rising RE bank — implementer report (2026-10-03, Opus implementer; saved by the orchestrator)

Status: DONE_WITH_CONCERNS. The data formats are solid. The gameplay code that actually runs movement,
spawn sets, weapons and damage is still unread and is listed in INDEX. Files: INDEX 107, pak-format 342,
data-tags 188, sprite-sound-containers 236, engine-loop 326, waves-and-enemies 369, function-roles 461
lines; 9 scripts in tools/ incl. list_paks.py and three Ghidra headless scripts (run against a copy of the
Ghidra project).

Claim labels in the five topical files (`grep -o '\[HIGH\|\[MED\|\[LOW'`): 94 HIGH, 33 MED, 5 LOW. Role
table: 279 hand-read functions (130 HIGH, 138 MED, 11 LOW); with data-key and source-module attribution,
609 of the 2133 unnamed functions have a role or module. INDEX lists 27 NOT-RESOLVED items.

Corrections to the prompt: classic Mac OS 8/9 app (imports InterfaceLib, no CarbonLib; carries a `carb`
resource), not Carbon; no CPU-side compression — the paks are plain ZIPs with every entry stored (zlib is
linked; the pak reader accepts only stored entries, so it is not reached through the paks — [MED], the
inflate callers were not traced; ⚑ corrected (review 2026-10-03) #17: was stated flatly as "never reached").

Main findings: all text data is obfuscated `#key <value>` text, each byte nibble-swapped then inverted
(`FUN_10046470`); the play order of the 12 levels comes from an encoded table in the binary, not the file
numbers (game data and player guide agree); the game ticks once per frame on TickCount, capped at 30 fps,
cap on by default; enemy waves live inside unit state machines, not in the level files.

Least sure: (1) which input byte is up vs down (assumed InputSprocket axis direction); (2) sprite alpha
plate meaning (white = transparent) and the colour-key pixel — drawing code not read; (3) scroll start row
(3120 inferred) and the x−32 shift on ground objects.

Attack first: the float list read by position (r2 arithmetic in the accessor), the level-order table
decode, and the unit-state and rule offset tables — most other readings depend on them.
