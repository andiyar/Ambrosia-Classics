# Handoff — 2026-10-03 — Ferazel's Wand RE deepening (cut off by usage limit)

**TL;DR.** The Ferazel bank went from 5 topical files to 22. Eleven parallel Opus readers (one per
handler family) plus two gap readers (geysers, held item/melee) read every sprite Setup/Handle/Hit/
Kill handler in the 154-function supplementary dump; an Opus synthesis critic produced
`coverage.md` (154/154 handlers accounted for; 13 uncovered are system callbacks), split physics.md
(§8 → `physics-sprites.md`), and rewrote INDEX's NOT-RESOLVED list (items 1–14 closed or narrowed,
new 15–27). Three Fable 5.1 review legs re-derived every replica-bearing HIGH constant from the raw
PowerPC listing: all ACCEPT_WITH_FIXES. Fix passes 1a and 1b are applied. **The consolidated fix
pass (review 1c + deferred existing-file touches + INDEX/coverage rows for the gap files +
`FIXPASS-2026-10-03-deepening.md`) was still running when the session hit its usage limit.** Branch
`claude/recursing-rhodes-932ac0` carries a WIP commit; the worktree
`.claude/worktrees/recursing-rhodes-932ac0` was left in place. Nothing is merged to main yet.

## Where everything is
- Reviews: `docs/ferazel/REVIEW-2026-10-03-deepening.md` (legs 1a/1b/1c + contradiction ledger).
- Reader/fix/synthesis reports (≤200 words each) were in the session scratchpad; their substance is
  in the files' own `## NOT RESOLVED` / `## Corrections` sections.
- Dumps regenerated this session (git-ignored, in the worktree's `ghidra/`): main 1082/1085,
  handlers 154/154 (23,917 lines), full disasm `Ferazel_pef.disasm.txt` (163,345 lines, FzDisasm
  over 10000000:1009f83c); Ghidra project `~/Developer/ghidra-proj/ferazel-rhodes`.

## What the reviewers caught (highest first)
- Critical (1b): the "launch latch `_DAT_100a0718` never clears" claim was wrong — it is the player's
  air-animation counter, zeroed every grounded frame (r27 stores at 100500c4/10050250/100505d4/
  1005073c); the platforms file would have disabled slope-hugging after the first jump.
- Important: dead attackers never hurt (HurtPlayer HP gate 10054768–98); `+0x11c` is zeroed by
  `.StandardSpriteHandles` each frame, so the water-gravity branch needs the call order (Frog only);
  save point 1065 is handled in the Box arm after a landing, not a Bonus gate; 2941 is a destructible
  gate (any 300-damage shot), not a switch gate; wall-jump net vy −3637 not −3610; boss music track
  30 also needs `hdr+0x2724 ≠ 0`; a Magical-Shield-reflected shot burns away (`+0x1a2` is one field).
- Naming settled from PICT 700/702 captions: spell 2 "Ice Crystals", 3 "Ice Wall", 7 second Ice-Wall
  icon (never granted); item 1 "Steel Key", 8 Hammer, 0x12 Ice Pick, 0x14 Light Orb.

## Still open (see INDEX items 15–27 and each file's NOT RESOLVED)
Draw-effect `+0xb8` modes; tint/remap colours; NewParticle argument semantics; Xichra cannon detail;
OmniPx composition / PxMid −1 drawing; Mcnv encoding (item 3), lighting tables (10), Titles use
sites (12) untouched this wave. A reader concern needs Ben's eyes: none — the only play-check
request (0718) was withdrawn by review 1b.

## Next session
1. In the worktree: confirm the consolidated fix pass finished (`FIXPASS-2026-10-03-deepening.md`
   present; INDEX ledger verdicts filled; `grep -c '⚑ corrected (review 1c' docs/ferazel/*.md`).
   If not, re-run it from `notes-fix-final` scope: review-1c findings + adjudications, deferred
   touches listed in the two FIXPASS notes, A2/A4, gap-file INDEX/coverage rows.
2. Verify, commit `docs/ferazel/` + STATE + handoff to the branch, merge to main (ff), push, remove
   the worktree, delete the branch.
