# Handoff — Ferazel's Wand, attended run 53 (2026-11-15)

**What happened.** One task merged and both owed launch checks passed. Ben closed the run after the first task
("finish this task and close", in chat); the river ripple (6A-RP) and the Box scenery (6A-BX1a) were not started and
head run 54.

| item | what it is | result |
|---|---|---|
| Proof B (owed since wave 6A.1) | the whole Core suite under CrossOver, muted, by day | 690 / 0 / 3 / 0 of 693, at 44cb75a |
| Mac SDL smoke (owed) | the SDL build boots to the main menu, no window, no sound | main menu identical, exit 0 |
| 6A-TR | trees on levels 10, 11 and 15 grow their branches, mirrored with the tree; Ferazel can stand on them | 771b62c, ledger 44cb75a, fix ad309c9 |

Nothing is visible to a player yet: no level past 5 opens until levels 10 and 11 do.

**How the task went.** One implementer, two Opus review legs, one fix round. Both legs: mergeable after fixes, no
blockers. The port matches the original line by line (setup, the per-frame handler, all 17 branch rectangles). The
second leg planted 176 bugs: 158 caught, 14 harmless by construction, 4 slipped through — all four caught after the
fix round. No existing picture or pinned value moved; no object on levels 1–5 is a tree.

**Rulings (D51).** The tree picture starts Ferazel above a tree so he lands on a branch (the level's own start shows
no tree doing anything). A review's extra checks go inside the task's named tests, so the test count stays the
plan's. The original's own numbers beat the research note on one branch size. One audit check's stated reason ("no
picture is wider than 256") was corrected now, because a tree picture is 264 wide and it would have failed when
level 10 opens.

**Numbers (the seat's own runs).** Core suite 682 at the start (main bf8b9e0), 693 at the merge (ad309c9); 0 failed;
the two opt-in skips by name. WinKit and the census were not re-run (nothing they cover changed): see `docs/STATE.md`.

**Timing lesson.** The run started at 08:19, before launch hours. The headless suite and the implementer went first;
the launch checks ran at 09:14 in the quiet gap between the implementer's report and the first review, with the
reviewer told to read until they finished. Proof B therefore ran on the branch with the trees in (693 tests), not on
run 52's head (D51.5).

**Context.** Reading the chip, STATE and the three cards brought the seat to 140k before the first dispatch; the one
task and the close took it to about 200k. Two tasks a run is the realistic size under the 300k cap.

**Next.** Run 54: 6A-RP ⚑, 6A-BX1a, then 6A-BX1b if the context allows (`docs/NEXT.md`). No launch check is owed.
