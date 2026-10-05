# Plan — Aki Remaster mode (AI-upscaled art, toggle) — 2026-10-04

> Design + plan in one; contracts, not code (house rule). Brainstormed with Ben during his P2 gate evening; rulings in
> DECISIONS D11. Samples Ben judged: `out/upscale-samples/` (git-ignored; regenerate with the U1 tool). Sequenced AFTER the
> iPad session (D7) merges — U2/U3 touch HectorShell and Aki/App, which that session is rewriting.

## 1. Rulings (Ben, D11)
- **Remaster mode = AI-upscaled art, model `remacri-4x`** (Upscayl 2.15.0's bundled Real-ESRGAN engine, local, offline;
  installed via `brew install --cask upscayl`, CLI `/Applications/Upscayl.app/Contents/Resources/bin/upscayl-bin`).
  Ben chose remacri over upscayl-standard / ultrasharp / digital-art / high-fidelity after seeing the samples.
- **A toggle, both modes shipped.** Fresh install = **Original** (exactly today's build). Toggle in **both** a checkable
  menu item ("Remastered Art") and a Preferences checkbox. Switches live.
- Remaster changes pixels only: geometry, timing, rules, every drawn rect and the original prefs blob are untouched.

## 2. Contracts

- **C1 — Art sets.** Original = the 1.2.0 PNGs as now (k = 1). Remaster = `hd-4x/` with the same file names at 4× pixel
  size (k = 4). Generated from the originals by the U1 tool into `Resources/Aki/hd-4x/` (git-ignored, invariant 3 / D10);
  staging copies it into the app beside the originals (`Contents/Resources/hd-4x/` on Mac, `hd-4x/` in the iPad bundle).
- **C2 — Region map.** `tools/aki-art-regions.json` (committed) lists, per PNG, every sprite rectangle the game draws from
  (from `AkiGameArt` / `AkiMap` / screen code rects), each tagged `picture` or `mask`; whole-file pictures (backgrounds,
  previews, map, welcome, …) are one region. Masks = mask rows/halves (e.g. `plate.png` right half, `misc.png` mask rows,
  `tiles.png` fade-mask frames + overlay masks) and any alpha channel.
- **C3 — Upscale rules.** `picture` regions: cut out individually with 8 px edge-replicate padding, remacri 4×, crop back,
  paste at 4× position (no bleeding across sprites). `mask` regions and alpha: nearest-neighbour 4× (bit-exact: a 4×4
  box-downsample of the result equals the original). Backgrounds additionally get a variant `hd-4x-dedither/` (light
  de-dither — e.g. a small median/bilateral pass — before remacri) for Ben to compare against the diagonal hatching remacri
  shows on the dithered photos; Ben picks at U4, the loser is dropped from the tool.
- **C4 — Runtime scale (HectorShell, via a HectorKit branch merged back as in D7 R6).** `ShellBitmap` gains a scale factor
  `k`: backing pixels = logical size × k; every copy/mask/draw API keeps LOGICAL coordinates and multiplies by k
  internally (nearest-neighbour stays the copy rule — at k = 4 the art is already 4×). Text drawing scales its CTM by k.
  `present` downsamples the k× image to the view smoothly (high-quality filter) when the view has fewer pixels than the
  canvas; k = 1 behaviour is byte-identical to today (macOS M3 floor unchanged).
- **C5 — Aki wiring.** One app-wide `artScale` (1 or 4) chosen from a NEW UserDefaults key (e.g. `RemasteredArt`, Bool,
  default false — NOT inside the 143-byte `GameSettings` blob). Switching: rebuild every GWorld/art bitmap at the new k
  from the matching set, then run the current screen's full redraw (`redrawMapScreen` / `redrawCustomGameScreen(tiles:
  true)` / splash redraw). Menus and the Preferences control are disabled under modals and are not reachable inside the
  busy loops, so no mid-animation switch exists.
- **C6 — The two toggles.** Menu: a checkable "Remastered Art" item injected after the nib-built menu (in the menu that
  holds Preferences — verify in the nib; on iPad the same item in the iPadOS 26 menu bar). Preferences: one checkbox
  "Remastered art" appended below the nib's controls (the dialog grows by one row; nothing else in the nib layout moves).
  Both read/write the same key and stay in sync.
- **C7 — Size/perf budget.** Measure: bundle growth (expect ~150–300 MB of PNG at 4×; opaque whole-file pictures may be
  stored as HEIC or JPEG q ≥ 90 if the total exceeds ~150 MB — masks and alpha sheets stay PNG); memory (~300 MB of 4×
  bitmaps); slide/fade smoothness. If 4× stutters on the Mac or iPad, ship k = 3 (the tool downsamples 4× → 3× with a
  high-quality filter; masks nearest from the originals at 3×).

## 3. Tasks (Opus implementer + Opus review each; ⚑ = MAJOR, two legs)

| Task | Content | Acceptance |
|---|---|---|
| **U1** asset tool | `tools/upscale-aki-art.py` (+ `tools/aki-art-regions.json`): C2, C3; idempotent, caches by input hash; prints per-file timings and totals. Classics only — can run in parallel with the iPad session. | A coverage check (script or AkiCore test reading the JSON) proves every rect the game draws from lies inside a declared region; every mask region round-trips bit-exact; the full set generates; the seat eyeballs `hd-4x/` contact sheets. |
| **U2** HectorShell scale factor | C4 on HectorKit branch `remaster` (worktree inside the Classics worktree's `.build/`), reviewed, ff-merged to HectorKit main. **Starts only after the iPad session's HectorKit merge.** | M3 floor (167 or the iPad session's new floor) unchanged at k = 1; new tests for k = 4 rect math, mask alignment, text CTM. |
| **U3** ⚑ Aki wiring | C5, C6 on Mac and iPad; staging scripts copy `hd-4x/`; WHAT-TO-EXPECT notes. **After the iPad session merges to Classics main.** | M1/M2 (+ AkiPad build); Original mode identical (review leg diffs against main); remaster screenshots at 4× read by the seat (map, a level, fade frames, pause/no-pairs sheets, time-bar stones, proverb). |
| **U4** Ben's eyes | Staged Mac app on ~/Desktop (ask before replacing) + iPad install; Ben toggles both ways, picks dedither vs plain backgrounds. | Ben only; verdict in STATE + DECISIONS. |

## 4. Risks
1. Remacri's diagonal hatching on the dithered background photos (seen in the samples) — C3's de-dither variant; Ben decides.
2. A sprite whose mask comes from a DIFFERENT sheet region than its picture must stay aligned at 4× — the coverage check
   pairs every masked draw's src and mask rects.
3. Programmatic pixel art (greyed tiles, any QD pattern fills) must scale nearest at k, not smooth.
4. HectorKit concurrency — U2 waits for the iPad session's merge; `git worktree list` in HectorKit first.
5. Other Classics games: the same C4 runtime serves them later; each needs its own region map (BTX/Ferazel sprite sheets).
