# notes — wave 3 reader: Render layer order + recipes A–D (2026-10-06)

Status: DONE. Task A = this commit; Task B = the next commit ("bank open-items recipes A–D").

Pass table (render.md §2.4): pre-pass (+0xB8): clear + 'B' frame-10 backdrops, sext6(E) < 0 ·
ground: unseen → tile 0xFF, flag 0x10000000 masked · P0 objects (kinds 0/1/0x20/0x21/0x40), tile
flag 0x100000 · P1 objects, 0x200 without 0x100000/0x10 · P2 never draws (constant `(1 & A) == B`)
· P3 objects, none of the three · P4 creatures (kinds 4/0x24), any tile · FX, then P5 objects with
0x10 · post-pass backdrops E ≥ 0 · then ApplyRoof, filter, light in DrawRoutine.

HIGH: order, tables, 12 call sites, offsets, FX byte, Render ignores the stage, ladder = targeting,
0xC0 mismatch. MED: kind 4 = placed character, quarter grid = occupant grid, backdrop formulas,
flag meanings (names LOW).

Item 16: CLOSED; THood order (overlap within a pass) NOT RESOLVED.

Tools match heredocs: A yes, B yes, C yes, D yes (diff empty; C/D also with built-in listing).

Hit hardest: pass-2 dead test (`10067a4c`/`10067a74`); SetStage 0xC0 up/left vs Render
left/up; Render never touching +0x141EC.
Follow-ups: data-format §3.2 (0x2000 = transposed), §4.2 mirror bit, §4.3 kind 4/0x24 not "roof".
