# notes — dialogue reader (2026-10-03)

**Read**: script-census, script-vm, script-builtins, rules §5, data-format §6.2; listings of all
127 talk methods (scratch analyser) plus 0801/0809/0816/0F00–0F15/300C; native TalkCommand,
CanTalk, Begin/EndTalking, TConversation (ctor, answers, ShowPortrait/Talking/Message), GetResponse,
HowMany, WhoWill, TTextContext, HandleMapping, GetGlobStr, Get/SetField, TBark, ShowBarks; raw PPC
for nine undecompiled methods named via traceback tables (mygets, mygetch, ForceOut, myprintstr,
mode Key/Mouse routines, `FUN_100b6dc8`).

**Counts**: 127 talk methods, 108 `input`, 1 325 `match` (1 551 words), 95 prompts (77 `yn`, 18 `*`).

**Top findings**: `FUN_100b6dc8` = strncmp — a keyword matches as a prefix of the whole
lower-cased input; empty input = `bye`; 0x8F = free-text (`*`) or single-key choice (`yn` → Yes/No
chips); keyword chips = STR# 128 + `@hint` words + `add_answer`, deduplicated on 4 letters, removed
once asked; quotes split speech/narration panes, `*` pauses (Esc skips); CharEntry+8 bit 7 =
name known; how_many(min, max, start=max); pick_item buttons return −(k+1); who_will_prompt only
in dead code; barks via field 0x26 (4 balloons, 4 s, dropped if unseen); seven blank-prefixed
keyword aliases unreachable by chip.

**Open**: dialogue.md §15 (Where-Is rows, style codes, journal clicks, two on-screen checks).
