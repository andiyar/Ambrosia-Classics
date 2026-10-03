# Ferazel's Wand RE bank — implementer report (2026-10-03, Opus implementer; saved by the orchestrator)

Register: code readings only; nothing behaviour-verified (meta file of the RE bank).

Status: DONE_WITH_CONCERNS. Files: INDEX 130, engine 264, world-data-format 394,
sprites-backgrounds-sounds 236, physics 261, spells-items 158 lines; tools/: pef.py, const.py, tocrefs.py,
rsrc_census.py, gensprite_map.py, FzDecompTargets.java, FzDisasm.java, targets.txt, fer_names.txt (scripts
only, no game data). Label counts (`grep -o "\[HIGH"` etc. over the five topical files): HIGH 182, MED 58,
LOW 12, NOT RESOLVED mentions 20; INDEX consolidates 12 open items.

Key findings: the main dump is missing 154 functions reached only through function-pointer tables (all
sprite Setup/Handle/Hit callbacks, including the whole player handler) — recovered with a Ghidra
post-script (154/154 decompiled; the supplementary dump is ~22k lines, outside git; recipe in INDEX). The
numbered files 01..30 are AIFC music, not levels (no code path asks for tracks 21 or 27); levels are the
`Mlvl` resources in World Data: a fixed 45,724-byte (0xb29c) header then six tile maps. The per-level
physics table is loaded but never read (only the loader takes its address). Engine is Ben Spees' own,
codename "Mascot". Fixed step, at most 30 fps, no delta time.

Least sure: (1) spell-id→name mapping (Statue 1, Ice Wall 3, Tree Trunk 4, Boomerang 5, V Blade 6) — from
behaviour in code, not strings; (2) which liquid kind is water/acid/lava — from the power-up sphere name
order; (3) enemy HP values — variant-selection conditions not traced.

Attack first: 8-byte copy-loop offsets (the decompiler hides a +8; it already broke the save-file layout
once, corrected against raw disasm; other offsets from the same idiom in `.SetupLevel`/`.ContinueGame` not
re-checked); the type→sprite-class table (hand transcription of `.GenerateSprite`); the "physics table
never read" claim (rests on a scan for direct loads).
