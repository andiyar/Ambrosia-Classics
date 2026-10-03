# Aki RE bank — implementer report (2026-10-03, Opus implementer; saved by the orchestrator)

Status: DONE_WITH_CONCERNS (14 NOT RESOLVED items, consolidated in INDEX.md). Files: INDEX 63, rules 301,
levels 136, levels-layouts 327, file-formats 136, method-map-1.2 221, delta-1.1-vs-1.2 75, assets-census 100
lines; tools diff_layouts.py 218, rsrc_census.py 41. Label counts, from grep -o of "[HIGH", "[MED", "[LOW"
and "NOT RESOLVED" across docs/aki/*.md: HIGH 81, MED 10, LOW 16, NOT RESOLVED 13 mentions (14 consolidated
items); the delta tables add 46 HIGH and 5 MED cells. Key results: the 12 layouts are identical in 1.1 and
1.2. "Levels 13–17" are random decorations for custom files, not layouts. Difficulty 0 is Hard and 3 is
Practice. All eight season tiles match each other. The rule changes from 1.1 to 1.2 are UX plumbing only.
Least sure: (1) after a mismatch, the old selection is cleared if the clicked tile is on an upper layer but
kept if it is on the bottom layer; (2) the time bar's black versus grey "overtime" stones; (3) 1.1 corrupting
best times when quitting a custom level (PowerPC decompile only). Attack first: the PowerPC emulator in
diff_layouts.py, because "identical layouts" rests on it; then the visibility rule (only the layer directly
above covers a tile) and the open rule.
