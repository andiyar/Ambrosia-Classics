# Handoff — Aki Remaster mode (D11 → D17) — 2026-10-06

Opus 5.5 orchestrator (Fable 5.1 trailer kept, invariant 16). Plan `docs/plans/2026-10-04-aki-remaster-art.md`, U1–U4 all done;
**Ben's gate PASSED (D17).** One step left: merge branch `aki-remaster` to main once the iPad branch `aki-ipad` is on main.

## Where things are
- **Main (Classics):** U1 — `tools/upscale-aki-art.py`, `tools/aki-art-regions.json`, `Aki/Core/Tests/AkiCoreTests/ArtRegionsTests.swift`.
  Regenerate the art with `python3 tools/upscale-aki-art.py` (cached; `--check`, `--sheets`, `--prune-cache`); output
  `Resources/Aki/hd-4x/` (git-ignored, 207 MB; D10 keeps generated data out of git).
- **HectorKit main 465200a** (since moved on with BTX work): `ShellBitmap` scale factor k, `ShellScaling.contentsFilters`,
  `ShellSurfacePresenter` (k > 1 presents via IOSurfaces). HectorKit D8.
- **Branch `aki-remaster` (pushed, head after 2163877 + this close):** = `aki-ipad` + U3 (RemasterSetting in AkiCore; hd-4x
  GWorlds at k = 4; live switch with draw-only redraw; menu item ⌘G + Preferences checkbox on Mac and iPad; staging copies
  hd-4x) + merge of main 07e6ff3 (project.yml keeps AkiPad + BubbleTroubleX) + Ben's U4 rulings. Gates on the branch:
  AkiCore 123/0/0; Aki, AkiPad (sim), BubbleTroubleX BUILD SUCCEEDED, 0 our warnings.
- **Staged:** ~/Desktop/Aki.app (Ben's prefs exported first to the session scratchpad; never `defaults delete`), iPad mini via
  `tools/stage-aki-ipad.sh`.

## To merge (the next session)
1. Confirm `aki-ipad` is on `origin/main` (`git branch -r --contains aki-ipad` lists origin/main, or STATE says so).
2. In a fresh worktree: `git merge origin/aki-remaster` into a branch from origin/main (expect conflicts only where the iPad
   merge resolved project.yml/docs differently); gates from the merge head: M1 AkiCore all passed/0/0, M2 `xcodegen generate`
   + Aki + AkiPad (+ BubbleTroubleX) BUILD SUCCEEDED, M3 HectorKit check-zero-skip at its floor; push to main; delete
   `aki-remaster` (local + origin).

## Carried (not blockers)
- English "Remastered Art"/"Remastered art" labels in the Japanese build (accepted).
- The Preferences paper stretches to the one-row-taller window in Original too (accepted).
- Whether CoreAnimation mipmaps IOSurface contents (trilinear) is unverified — falls back to linear; looked fine to Ben.
- Unverified on device: tearing under heavy load (triple buffer + in-use skip guards it).
- The iPad Simulator here only captures portrait, so the seat could not enter a level on it; Ben's device play covered it.
