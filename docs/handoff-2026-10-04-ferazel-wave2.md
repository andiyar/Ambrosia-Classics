# Handoff — 2026-10-04 — Ferazel's Wand RE bank wave 2 (cut off by usage limit mid-review)

**TL;DR.** Ben asked for the bank "decompiled to 100%": every NOT-RESOLVED item in `docs/ferazel/INDEX.md`
closed or declared undeterminable with evidence. Ten Opus reader lanes ran in parallel and ALL TEN
landed on branch `worktree-ferazel-wave2` (worktree `.claude/worktrees/ferazel-wave2`), 11 new files +
17 files edited in place (marker `⚑ wave 2 (2026-10-04)`), ~97 "Corrections to the existing bank" rows
waiting for a synthesis pass. Eight Fable review legs were dispatched; **six reported (A–F — saved
verbatim in `docs/ferazel/REVIEW-2026-10-04-wave2.md`), two (G, H) were still running when the
session was cut off and their reports are LOST — re-run them.** Nothing from the wave is merged to main.
INDEX.md and coverage.md are NOT yet updated (synthesis owed).

## Lane commits (all on the branch, each touching only its owned files)
| lane | commit | files | INDEX items claimed |
|---|---|---|---|
| L5 conversations | 69b773a | `conversations-mcnv.md` (new) | 3 closed; 29 conv-half closed |
| L2 draw effects | f5d57fb | `draw-effects.md` (new) | 15 draw part closed |
| L3 particles | 5f626f7 | `particles.md` (new) | 15 particle part; 28 NR 1 |
| L6 bosses | 22211f6 | `bosses-3.md` (new), bosses.md, bosses-2.md | 19 closed |
| L7 enemies | 83f4554 | `enemies-ground-2.md` (new), enemies-ground/flyers/water-cave | 16, 17, 18 closed |
| L1 lighting | 90210bb | `lighting-tables.md` (new) | 10 closed; 15 colour narrowed |
| L4 rendering/titles | cf29995 | `rendering-omnipx-titles.md` (new) | 2, 12, 13, 26-loader closed; 4 undeterminable |
| L9 triggers/spells | 32bef32 | `spells-detail-2.md` (new), triggers-background(-2), spells-detail | 22, 23 closed |
| L10 save/platform/player | 0de6265 | `platforms-ropes-radial-2.md` (new), save-continue, platforms, player-states(-2), held-item-melee, physics-sprites | 25, 29, 5-rest, 26-rest closed; 24 part |
| L8 shots/pickups | 104c48e | `enemy-shots-and-damage-2.md`, `pickups-boxes-2.md` (new), enemy-shots, pickups-boxes | 20, 21, 1-rest closed |

Also e372d67 `ghidra/regen-ferazel.sh` (rebuilds the three dumps from `~/Developer/ghidra-proj/ferazel-rhodes`,
no re-import; ~6 min). Dumps are git-ignored in this worktree's `ghidra/` (main 1236/1239 — includes the 154
handlers now saved in the project —, handlers 154/154, disasm 163k lines). Binary copy `ghidra/Ferazel_pef`.

## Review legs
- **Reported (in `REVIEW-2026-10-04-wave2.md`):** A (draw-effects/particles/conversations: all ACCEPT_WITH_FIXES,
  0 Critical, 2 Important label downgrades), B (bosses ×3: ACCEPT / ACCEPT_WITH_FIXES, 41/41 re-derived,
  one synthesis rule: W3 duplicates L9's type-90 closure — merge not apply), C (lighting-tables:
  ACCEPT_WITH_FIXES, **2 Critical**: water-tint loops are `ble` so entry 0xff IS written → black not white;
  draw mode 0xa IS a vertical squash — L2 right, L1 must defer), D (enemies ×4: ACCEPT, minors only).
- **LOST — re-run with the same prompts (reconstruct from this table):** E = `rendering-omnipx-titles.md`
  (attack: PxMid row-above/−1 claim; parallax drawn in copy-to-screen; PxBack/PxMid exclusivity 1001793c/1001891c;
  logical shift 10018a24; Titles use-site grep; tracks 21/27; Installer Data RTF). F = L9's four files (attack:
  same-frame new-shot rule = next sprite layer ≤ 11; orphaned followers; 1303 `+0xb0`; third Button consumer =
  spouts 1450..1453, 24/24 census; no-spawner effects 1202..1205/1251/−1; wind o1 = 9 up; passage-global
  timeline). G = L10's seven files (attack: **hit callbacks run twice per frame** `.MTCollideSprites` 10032714ff
  + player pass; dispatch key far-y/near-x; save point 15th landing frame; held-item depth sign 1004c060;
  `.SafeReportStr` 100359cc; `.CrunchTile` returns kind at strength 0; BG 400..495 no reader). H = L8's four
  files (attack: `.HitPlayerSprite` only from `.MTCollideSpecialSprite`, player `+0x5c` = 0, bombs 0x6e1/0x6e2 no
  direct contact damage; **cross-lane: L8 "farthest partner first" vs L10 "twice per frame"**; **cross-lane: L8
  "Mcnv 205 grants Platinum Key" vs L5 "action 3 = RemoveItem"**; renames 1080/1081 magic carpet, 2932/2933
  stalactites). Review brief used: method = spec per INDEX item → ≥ 25 raw re-derivations → labels →
  consistency incl. Corrections rows → structure; ≤ 350 words; Fable-grade (omit `model`).

## Next session (in order)
1. Re-run legs G and H only (read-only, parallel; A–F are saved). 2. ONE Opus fix+synthesis agent: apply all eight legs' findings
(markers `⚑ corrected (review 2a..2h, 2026-10-04) #n`), rule the two cross-lane conflicts from raw, merge the
~97 Corrections rows into their target files (dedupe W3/§8.1; L1 row 6 = L6 W1/W2 on 0x2730..36), rewrite INDEX
NOT-RESOLVED (items 2,3,4,5,10,12,13,15–29 → closed / undeterminable / narrowed with pointers; add the new files
to the topical table), coverage.md rows for the 11 new files, `FIXPASS-2026-10-04-wave2.md`, label counts.
3. Fable spot-review of that diff. 4. STATE bullet, merge to main (main has moved — `--no-ff`), push, remove
worktree + branch, memory → closed, closing message in plain English.
