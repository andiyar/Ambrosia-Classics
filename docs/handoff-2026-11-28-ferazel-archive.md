# Archive note — Ferazel's Wand, run 72 part 2 (2026-11-27 night and 2026-11-28 morning)

**Seat:** Fable 5.2, started by another session; foreground only (the Windows test run detached, as allowed).
**Times:** night half 2026-11-27 01:04 → 02:45 (nothing launched); day half 2026-11-28 09:06 → about 10:00.
**Weekly limit:** 93% (all models), 75% Fable at the night half's end. Ben: do not stop for it.

## What is now true
- **Ferazel's Wand is paused** (D72.1). `docs/NEXT.md` says `STATUS: PAUSED` and how to resume. No next session.
- **Both builds are staged from 5d1c966.** Mac: `Ferazel's Wand.app` on the Desktop, and `out/Ferazel/` in the
  main checkout. Windows: `Ferazel's Wand (Windows).zip` on the Desktop; the zip and its `.sha256` are in
  `releases/ferazel-6a-archive/` in the main checkout. Nothing was uploaded and no tag was pushed.
- **The gate is Q22** in `docs/QUESTIONS.md` (Mac and Windows). Q19 and Q21 are closed as "paused". Q18 stays open.

## The checks

| check | result |
|---|---|
| Game-side suite (part 1, b7be967) | 823: 821 passed, 0 failed, 2 named skips |
| Windows-side suite (part 1) | 91: 89 passed, 0 failed, 2 named skips |
| The game's suite under CrossOver (28 Nov, muted) | 820 passed, 0 failed, 3 skipped, 0 crashed (of 823) |
| Mac smoke of the Windows-style build | main menu identical |
| Every-object sweep, 12 levels | 11,864 visits on each path, 0 problems (Core path re-run 27 Nov) |
| Random-play bot, 12 levels | 259,200 steps on each path, 43 deaths, 385 exits, 0 failures (the same on both) |
| Staged Windows zip in a clean CrossOver bottle, muted | main menu, New Game, level 1 text: all identical |
| Staged Mac app, muted | started, ran 8 s, quit; no crash report |

## The phase review (Fable, the whole 6A diff from e9183ce)
- Read by area; one spot-check against the dump matched (the Chief's boulder-distance test).
- **The bot's two paths differed on level 22 — explained and fixed, tests only (a6d448c).** The Core suite's
  stand-in shell never passed the list of playing sounds, so eleven wall spikes each drew a random number the
  Windows path did not. Both real shells pass the list; no player sees a difference.
- Four stale level lists in comments fixed (d157967). Both cards' bot line corrected (1abe4f5).
- One unverified note (the looping sound's re-insert) is in `docs/NEXT.md` under "Open carries".

## Rulings this run: D74
Ben's "go" overrides the launch-hours rule; the card's start-up lines were filled before the checks and held.

## Left behind
- Removed: the Ferazel worktrees `gracious-volhard-286877`, `compassionate-leavitt-7ca958`,
  `vigilant-williamson-6f3017`, `ferazel-run-44-7428b3`. None had an Xcode build cache of its own. If the app
  refused a delete, the closing message says which.
- Still by hand: about 560 MB of run 67's `exciting-panini-fdb834` under `Aki/.claude/worktrees/` (the app
  refused that delete in an earlier run).
- Scratch copies, logs and smoke folders made by this session are deleted. The cross-build work folder under
  `~/Developer/Toolchains/windows-cross/work/proof-b-ferazel` is the script's own cache and was left.
