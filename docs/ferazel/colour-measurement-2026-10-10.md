# Ferazel level-1 colour measured against Ben's Let's Play (2026-10-10)

The replica's level-1 frames (Classics main 5c22225, Ferazel/Core 102/0) scored against Ben's own Let's Play video, to settle the Color2Index
LOW (design §6, D26). Opus measurement leg, orchestrated by an Opus 5.5 session. `$S` = `docs/ferazel/colour-measurement-2026-10-10/`
(tool in `tool/`, scripts in `scripts/`; the run's intermediates — LP frames, 48×7 renders, JSON — are not committed, rerun to regenerate).

## Ben's rulings on these results (2026-10-10)

- **Default colour model → `.exactNearest`** (was `.ruled`). Applied in `Ferazel/App/FerazelController.swift`; G2 102/0, Ferazel scheme BUILD SUCCEEDED.
  Tie-break `highest`, dither `.errorDiffusion` and Effects 1 already match and stay.
- **Mac display gamma → a hidden toggle, off by default** (like `ColorTieBreak`): presenting through the classic Mac's ~1.8 gamma
  (the measured γ ≈ 0.76) is its own small shell task, not built here.
- **Closed (2026-10-10, see "Q3 resolved" below):** the table under light 24 (the potion's light) was too bright (Q3). The sprite light
  pass was right; the potion's light face twinkles (`.HandleBonusSprite`), and the replica held its brightest face.

## Verdicts

| Q | Answer | Confidence |
|---|---|---|
| Q1 tie-break | **highest.** It wins under every model. Where the lowest and highest renders differ (outside sprites, HUD-γ, 3×3 blur), highest is closer on 85 % of pixels for exactNearest (ΔE 3.7 vs 10.0), 60 % for ruled (6.1 vs 9.8), and 97–99 % for inverseTable 4/5, where lowest paints every backdrop black light yellow (ΔE ~95). Video FG edges: mean b* is 3.4–4.4, which is closer to highest. | HIGH (that it isn't lowest); MED for highest specifically, vs some other duplicate |
| Q1 model | **exactNearest, or inverseTable 5, over ruled / inverseTable 4.** exactNearest is best on fitted block ΔE in **all 7 frames** (1.00–1.46 vs ruled 1.90–2.62). With the fixed, model-independent HUD gamma, inv5/highest is best overall (2.12), then exact/highest (2.38), then ruled (3.04) and inv4 (4.47). ruled is worse than exact in 7/7 frames on both metrics. The difference comes ONLY from the lighting-table lookups: at Effects 3 (no tables) all models score within 0.2. Visually, ruled/inv4 give speckled, too-dark lit rock (sbs_462). exact and inv5 can't be separated reliably: exact is better on block structure, inv5 on region means. | MED (ruled/inv4 are worse); LOW (exact vs inv5) |
| Q2 darker | **It is capture/display gamma, not the model.** The PICT 129 HUD frame is 4-bit art and converts the same under every model, yet it is brighter in the video by a pure gamma **γ ≈ 0.76** (render→video; median residual 5.4 vs 26 with identity; the implied γ runs 0.71–0.90 across levels). Blacks decode to 0 (border 0,0,0), so TV→PC range handling is correct and the cause isn't range. 0.76 is close to the classic Mac 1.8 → 2.2 display gamma (0.82). After that same γ, our **Effects-1** frame matches the brightness (rock dL −2.9 for exact, +2.2 for ruled). Effects 3 becomes far too bright (rock −10, FG edges −24). So the per-cell ambient darkness is right. The free per-combo fit for exact gives G/B γ 0.79–0.81, which agrees with the HUD. | HIGH |
| Q3 glow | **It isn't the Effects pref.** The video is Effects 1 (or 2): the torch/Xichron tile glows are present (578.5 blob, 310 floor glow), and the per-region "lit" ΔE is 2–5 at E1 vs ~30 at E3. The glow comes from **light 24**: item **0xc84 (the potion) at (291,123)**, light PICT 810 (0x32a, 72×72) at (307,135), colour 99, ungated by Effects. On the **wall tiles** around the table, the video matches E1 WITH that light (region dE 2.9 ruled; dropping it gives dE 12, too dark). On the **table sprite** pixels, our sprite light pass (`.DrawLightOverFace` via `.WrapLightFace`) is far too bright: on the pixels light 24 changes, dL −17 / dE 23. Without the light it is too dark (+6.8 / dE 18). The plain unlit table (E3) is closest (dE 6.9). The other 10 matched sprite blobs in 7 frames ARE darkened like our E1 path (E1 dE 6.0 vs plain 18.4). So the general sprite lighting is right, and the error is specific to how light 24 (an item light, colour 99) lights neighbouring sprites. It is a real model error in the sprite light overlay: its strength, its colour/table, or whether an item's light applies to other sprites. | HIGH (not the pref); MED (it is the sprite light overlay of light 24) |
| Q4 dither | **Error-diffused.** In the video's own 1440×1080 domain, the energy at original-pixel periods 2–3 px (a*, b*) on static 32-bit sprites matches our Floyd–Steinberg render pushed through a simulated LP pipeline. It is 2–5× higher than the undithered one: table top a* 0.47 video vs 0.17–0.38 fs vs 0.03–0.09 none; chair 0.15 vs 0.17 vs 0.06; books 0.57 vs 0.40–1.27 vs 0.17–0.28. It is obvious by eye (out/q4_table_fullres.png): undithered posterises the table into orange bands, which the video doesn't show. After the 640×480 area downscale the two are NOT distinguishable (HF std and high-pass correlation equal within noise), so this must be judged at full resolution. Whether it is Floyd–Steinberg *specifically* (vs another diffusion or pattern dither) can't be resolved at this bitrate. | HIGH (dithered); LOW (FS specifically) |

**Recommended settings that match the LP:** model exactNearest (or inverseTable 5) for the lighting tables, tieBreak highest, dither errorDiffusion, Effects 1. Plus a sprite-light-overlay item for light 24 (Q3).
The current app default (ruled / highest / FS / E1) is right on the tie-break, dither and Effects. On the model it is measurably worse.
The darker look Ben saw is mostly display gamma: the original ran under Mac gamma 1.8. That is a shell-presentation question for Ben, not a model one.

## Method

**Video.** `~/Let's Play Ferazel's Wand! Part 1： A Scent of Peril [ESuyxMUEzDw].mkv`. ffprobe: h264 High, yuv420p, `color_range=tv`, `color_space/transfer/primaries=bt709`, 30 fps, 1920×1080, ~2.17 Mb/s.
Extraction (vid.py): `ffmpeg -ss T -i V -frames:v 15 -vf "crop=1440:1080:240:0,scale=640:480:flags=area:in_range=tv:out_range=pc:in_color_matrix=bt709:out_color_matrix=bt709,format=rgb24"`. Each analysed frame is the per-pixel **median of frames 5–9** (5 consecutive frames, T+0.167…T+0.300 s), to cut compression noise.
Frame choice: a 4 fps grayscale scan of 120–960 s, looking for runs of ≥1.5 s with mean frame difference <1.2 and no dialog (bright-pixel test), then checked by eye (v/contact.png).
Play view = screen (16,8) 608×384. Verified: screen(16+x, 8+y) = world(h+x, v+y), and render pairs agree on 92 % of pixels (the remainder is parallax and lights).

**Renders.** The tool is `tool/` (SwiftPM, path dependency on `Ferazel/Core`, its own `.build`). It drives the public `FrameRenderer` with the ops the session would issue: `setScreenClut`, `drawPicture 129`, then per scroll `redrawEntireScrollGrid(h,v)`, `redrawScrollGrid(h,v)`, `drawLightsOntoTiles` (unless Effects 3), `wrapDrawSprites`, `copyToScreen(h,v,graphics 1,backdrop)`, `wrapEraseSprites`. The pass is applied twice per scroll, so the lights are no longer "new". Sprites come from `SetupFaces.spawnLevelSprites` plus `IdleSprites.handle(h,v)` with no player (the player isn't drawn).
Camera: `Camera` has no public setter. Rather than step the session, the tool issues the scroll ops directly. That is legitimate through the public seam (DrawOp), and needs no core change. Text uses a null rasterizer, so the HUD has no text.
Effects 2 = "Normal": tiles are lit as at E1, but there are no Xichron / money-bag lights (`SetupFaces` gates those on Effects == 1). 4 models × 2 tie-breaks × 2 dithers × Effects {1,2,3} = 48 combos × 7 frames.

**Scroll match.** A 6400×1600 world mosaic (Effects 3, no sprites), searched with edge-magnitude NCC: FFT at half resolution, then ±6 px at full resolution, then ±2 px against real Effects-1 renders with sprites. Every frame has a sharp peak (the ±1 px neighbour is 0.39–0.58 vs 0.74–0.87 at the peak).

**Masks.** (1) Sprite coverage: render with sprites ≠ render without, at E1 or E3, dilated 6 px. (2) Outlier 8×8 blocks: per frame, blocks whose combo-median fitted ΔE is above the frame's 92nd percentile. That removes the player, enemies, coins and dialog leftovers in a combo-neutral way (~8 %). (3) Blocks with <75 % valid pixels. The HUD is excluded by scoring the view only.

**Metrics.** CIE76 ΔE in CIELAB (sRGB D65), computed on 8×8 block means of the valid pixels.
- *raw*: the render as is.
- *fitted*: one global fit per combo, across all 7 frames, per channel `v = o + g·255·(r/255)^γ` (soft-L1 least squares).
- *HUD-γ*: a single fixed γ = 0.76 measured on the HUD frame (hudtone.py), the same for every combo, so it can't favour any model.
- Regions are defined on the reference render ruled/highest/none/E3: backdrop L*<8; rock chroma<12 and 8≤L*<45; FG edge chroma<12 and L*≥45; warm chroma≥12, b*>0, a*>−5; lit = E1 luminance > E3 + 12. Too few blue/water pixels survived to score.
- Region score = ΔE between region-mean colours (HUD-γ), with dL = video − render.
- Q1, Q3 and Q4 have their own scripts and metrics (q1.py, q3.py + spritelight.py, q4.py + q4full.py), described in the verdicts.
- Dither: fs and none give **identical** scores outside sprites, because tiles are not 32-bit art. Dither is only measurable on sprites (Q4).

## Frames

| time (s) | median of frames | scroll (h,v) | edge NCC (2nd-best ±1px) | valid 8×8 blocks | outlier blocks | sprite px masked |
|---|---|---|---|---|---|---|
| 132 | 132.167–132.300 (5 frames) | (0,0) | 0.869 (0.495) | 2808 | 291 | 16084 |
| 310 | 310.167–310.300 (5 frames) | (720,324) | 0.754 (0.566) | 3051 | 293 | 580 |
| 408.5 | 408.667–408.800 (5 frames) | (1264,0) | 0.770 (0.433) | 2942 | 347 | 4395 |
| 462 | 462.167–462.300 (5 frames) | (4096,24) | 0.831 (0.583) | 2972 | 296 | 5523 |
| 578.5 | 578.667–578.800 (5 frames) | (5184,502) | 0.830 (0.473) | 2823 | 297 | 14476 |
| 765 | 765.167–765.300 (5 frames) | (848,1190) | 0.823 (0.543) | 2864 | 298 | 11597 |
| 907.5 | 907.667–907.800 (5 frames) | (1252,699) | 0.744 (0.394) | 2790 | 406 | 10514 |


## Results — all combos, ranked by fitted ΔE (dither collapsed: fs ≡ none outside sprites)

Region columns: HUD-γ ΔE of region means (dL video − render).

|---|---|---|---|---|---|---|---|---|---|---|
| 1 | exact/highest/e1 | 5.68 | 1.21 | 2.38 | 1.3 (+0.5) | 3.0 (-2.9) | 5.4 (-5.2) | 3.8 (-3.1) | 5.0 (-2.6) | – |
| 2 | exact/highest/e2 | 5.68 | 1.22 | 2.38 | 1.4 (+0.5) | 3.0 (-2.9) | 5.4 (-5.2) | 3.8 (-3.1) | 5.9 (-1.4) | – |
| 3 | exact/lowest/e1 | 5.55 | 1.35 | 2.58 | 1.2 (+0.2) | 3.0 (-2.9) | 5.4 (-5.2) | 3.8 (-3.1) | 5.1 (-2.9) | – |
| 4 | exact/lowest/e2 | 5.55 | 1.36 | 2.58 | 1.2 (+0.2) | 3.0 (-2.9) | 5.4 (-5.2) | 3.8 (-3.1) | 5.9 (-1.6) | – |
| 5 | inv5/highest/e1 | 7.08 | 1.46 | 2.12 | 3.5 (+2.7) | 0.9 (-0.7) | 4.7 (-4.5) | 2.9 (-1.3) | 2.4 (-1.2) | – |
| 6 | inv5/highest/e2 | 7.09 | 1.47 | 2.13 | 3.5 (+2.8) | 0.9 (-0.7) | 4.7 (-4.5) | 2.9 (-1.3) | 3.4 (+0.1) | – |
| 7 | inv4/highest/e1 | 8.68 | 2.13 | 4.47 | 5.5 (+4.8) | 4.1 (+4.1) | 4.6 (-4.2) | 4.1 (+0.1) | 2.6 (+1.4) | – |
| 8 | inv4/highest/e2 | 8.69 | 2.14 | 4.48 | 5.5 (+4.8) | 4.2 (+4.1) | 4.6 (-4.1) | 4.0 (+0.1) | 3.1 (+2.8) | – |
| 9 | ruled/highest/e1 | 7.87 | 2.19 | 3.04 | 4.2 (+3.9) | 2.3 (+2.2) | 4.6 (-4.2) | 4.1 (-0.2) | 0.9 (-0.6) | – |
| 10 | ruled/highest/e2 | 7.88 | 2.20 | 3.05 | 4.2 (+3.9) | 2.3 (+2.2) | 4.6 (-4.1) | 4.1 (-0.2) | 1.8 (+0.9) | – |
| 11 | ruled/lowest/e1 | 7.75 | 2.27 | 3.00 | 3.9 (+3.7) | 2.2 (+2.2) | 4.6 (-4.2) | 4.2 (-0.2) | 1.1 (-0.8) | – |
| 12 | ruled/lowest/e2 | 7.75 | 2.28 | 3.01 | 3.9 (+3.7) | 2.3 (+2.2) | 4.6 (-4.1) | 4.2 (-0.2) | 1.6 (+0.7) | – |
| 13 | ruled/highest/e3 | 3.90 | 3.12 | 7.12 | 1.6 (-1.2) | 10.2 (-10.2) | 24.4 (-24.4) | 15.3 (-12.7) | 29.7 (+12.1) | – |
| 14 | exact/highest/e3 | 3.89 | 3.14 | 7.36 | 1.8 (-1.5) | 10.5 (-10.4) | 24.0 (-24.0) | 15.1 (-12.8) | 29.7 (+11.8) | – |
| 15 | inv5/highest/e3 | 4.12 | 3.18 | 7.87 | 2.5 (-1.0) | 10.5 (-10.4) | 24.0 (-24.0) | 15.0 (-12.8) | 29.7 (+11.8) | – |
| 16 | ruled/lowest/e3 | 4.05 | 3.22 | 7.45 | 1.8 (-1.7) | 10.2 (-10.2) | 24.4 (-24.4) | 15.3 (-12.7) | 29.4 (+11.7) | – |
| 17 | exact/lowest/e3 | 4.07 | 3.24 | 7.69 | 2.1 (-2.0) | 10.5 (-10.5) | 24.0 (-24.0) | 15.1 (-12.9) | 29.4 (+11.4) | – |
| 18 | inv4/highest/e3 | 4.61 | 3.30 | 6.66 | 2.8 (+1.4) | 8.8 (-8.7) | 24.4 (-24.4) | 15.0 (-12.4) | 30.7 (+14.6) | – |
| 19 | inv5/lowest/e1 | 19.37 | 5.74 | 15.11 | 24.1 (-19.7) | 0.9 (-0.7) | 4.7 (-4.5) | 2.9 (-1.4) | 2.5 (-1.5) | – |
| 20 | inv5/lowest/e2 | 19.38 | 5.74 | 15.12 | 24.1 (-19.7) | 0.9 (-0.7) | 4.7 (-4.5) | 2.9 (-1.4) | 3.3 (-0.2) | – |
| 21 | inv5/lowest/e3 | 16.81 | 5.96 | 21.02 | 27.8 (-24.4) | 10.5 (-10.5) | 24.0 (-24.0) | 15.1 (-12.8) | 29.4 (+11.5) | – |
| 22 | inv4/lowest/e1 | 23.90 | 6.02 | 20.37 | 28.2 (-22.8) | 4.1 (+4.0) | 4.6 (-4.2) | 4.1 (+0.1) | 2.3 (+0.5) | – |
| 23 | inv4/lowest/e2 | 23.91 | 6.02 | 20.38 | 28.2 (-22.8) | 4.1 (+4.0) | 4.6 (-4.1) | 4.1 (+0.1) | 2.3 (+2.0) | – |
| 24 | inv4/lowest/e3 | 20.56 | 7.15 | 23.15 | 32.6 (-28.3) | 8.9 (-8.8) | 24.4 (-24.4) | 15.1 (-12.4) | 29.6 (+13.3) | – |

Per-frame fitted ΔE (HUD-γ ΔE) for selected combos:

| frame | exact_highest/e1 | inv5_highest/e1 | exact_lowest/e1 | ruled_highest/e1 | ruled_lowest/e1 | inv4_highest/e1 | ruled_highest/e3 |
|---|---|---|---|---|---|---|---|
| 132 | 1.24 (2.92) | 1.31 (1.59) | 1.43 (3.18) | 1.90 (2.94) | 1.99 (2.89) | 2.03 (4.37) | 2.87 (5.82) |
| 310 | 1.00 (1.75) | 1.55 (3.03) | 1.12 (1.92) | 2.52 (2.92) | 2.54 (2.84) | 2.16 (4.84) | 3.21 (8.40) |
| 408.5 | 1.18 (2.39) | 1.41 (1.80) | 1.24 (2.47) | 1.92 (3.57) | 1.98 (3.51) | 1.90 (4.53) | 2.69 (8.59) |
| 462 | 1.18 (2.20) | 1.54 (2.57) | 1.42 (2.56) | 2.62 (2.52) | 2.71 (2.54) | 2.47 (4.77) | 2.54 (4.36) |
| 578.5 | 1.46 (3.10) | 1.50 (1.78) | 1.58 (3.26) | 2.01 (3.12) | 2.15 (3.05) | 2.23 (4.43) | 3.42 (7.08) |
| 765 | 1.28 (2.55) | 1.47 (2.17) | 1.49 (2.79) | 2.41 (2.47) | 2.50 (2.54) | 2.37 (4.18) | 3.18 (4.35) |
| 907.5 | 1.11 (1.71) | 1.44 (1.91) | 1.20 (1.84) | 1.95 (3.71) | 1.99 (3.65) | 1.76 (4.20) | 3.98 (11.23) |

Global per-combo tone fits (per channel: offset, gain, gamma):

- exact_highest_fs_e1: R o+11.6 g1.33 γ1.10; G o+1.1 g0.92 γ0.79; B o+1.3 g0.92 γ0.81
- inv5_highest_fs_e1: R o+17.5 g1.47 γ1.18; G o+1.1 g0.80 γ0.68; B o+5.4 g0.84 γ0.76
- exact_lowest_fs_e1: R o+11.4 g1.22 γ1.07; G o+1.0 g0.86 γ0.77; B o+1.3 g0.89 γ0.80
- ruled_highest_fs_e1: R o+16.6 g1.12 γ0.98; G o+2.1 g0.62 γ0.55; B o+4.9 g0.70 γ0.64
- ruled_lowest_fs_e1: R o+16.3 g1.05 γ0.96; G o+2.0 g0.60 γ0.55; B o+4.5 g0.68 γ0.64
- inv4_highest_fs_e1: R o+18.8 g0.98 γ0.91; G o+3.9 g0.56 γ0.51; B o+7.5 g0.58 γ0.58
- ruled_highest_fs_e3: R o+15.0 g0.68 γ1.04; G o+1.1 g0.50 γ0.65; B o+0.5 g0.49 γ0.64

Inverse-table models with tie-break lowest score ΔE 15–23 (HUD-γ), because every pure black lands on light yellow.

## Q3 detail (02:12, scroll 0,0; q3.py)

| region | render | region-mean dE (HUD-γ) | dL |
|---|---|---|---|
| wall tiles touched by light 24 (1,129 px) | ruled E1 all lights | 2.9 | −2.2 |
| | ruled E1 without light 24 | 12.1 | +12.0 |
| | ruled E3 | 4.2 | +3.3 |
| table sprite px changed by light 24 (1,014 px) | ruled E1 all lights | 23.4 | −17.0 |
| | ruled E1 without light 24 | 18.4 | +6.8 |
| | ruled E3 (plain sprite) | 6.9 | −1.0 |
| torch light 0 wall region | ruled E1 all lights | 2.1 | +0.9 |
| | ruled E1 without light 0 | 30.3 | +21.7 |

The sprite-blob survey (spritelight.py) covers the 11 structurally matched blobs (edge NCC > 0.5). E1 is closer on 10. The exception is the table under the potion light (E1 dE 16.0 vs plain 7.2).

## Q3 resolved — the item light twinkles (2026-10-10, D26 "As built (light-24 table glow)")

The follow-the-binary read found `.WrapLightFace`, `.DrawLightOverFace`, its blitters and the table's `+0x88` (= 1) all transcribed
right. The difference is `.HandleBonusSprite` (LAB_1005f808, raw `1005f808..1005f914`). Every frame it steps an item's light through faces
0x32a → 0x32b → 0x32c → 0x32d → 0x32c → 0x32b, four frames each. The replica held 0x32a, the brightest face (sums of k: 19,936 / 13,039 /
7,992 / 3,812). It is fixed in Core (`BonusHandle`, `DrawOp.changeLightFace`). The tool takes `--twinkle k` (k 0…3): every item light
shows face 0x32a + k, as its Handle leaves it.

Re-scored on the 02:12 frame (exactNearest/highest/FS/E1, HUD-γ region means, q3.py's masks):

| light 24 face | table px lit by light 24 (1,015) | light-24 wall px (1,272) |
|---|---|---|
| 0x32a held (before) | ΔE 21.6, dL −17.7 | ΔE 5.0, dL −4.5 |
| 0x32b | 13.4, −11.0 | 2.8, −0.3 |
| **0x32c** | **6.9, −4.3** | 3.7, +2.4 |
| 0x32d | 9.6, +1.1 | 5.4, +4.5 |
| mean over the 24-frame cycle | 11.2, −8.0 | 2.8, +0.6 |
| without light 24 | 18.8, +5.4 | 6.9, +6.1 |
| Effects 3 (plain table) | 6.6, −1.5 | 3.5, +2.3 |

The LP's 5-frame median sits on the 0x32c phase. The start phase is the Setup's `FastRand(0x10)`, which is not modelled. The other six
frames render byte-identically at every k, so nothing else regresses. In the whole view of the 02:12 frame, the mean 8×8-block ΔE drops
from 2.885 to 2.838–2.865.

## Caveats
- The LP is 2.25× upscaled, 4:2:0 h264 at ~2.2 Mb/s. Fine dither patterns survive only at full resolution. Chroma bleed lifts the dark-red backdrop in the video, which shows up as the red-channel offset (+11 to +17) in the free fits.
- Animation and state differ: our sprites are at frame 0, and video sprites are animated. Coins taken or enemies killed differ. The player isn't drawn by us. All of these are masked, but residual blocks remain.
- Torch flicker / light animation isn't modelled. `FastRand` Setups aren't modelled.
- The HUD γ comes from blurred 4×4 blocks of a mostly mid-grey panel. Its level dependence (0.71 dark → 0.90 light) means the capture curve isn't a perfect power law, which leaves a small brightness residual for every model.
- exact vs inv5 rests on 0.1–0.3 ΔE margins and opposite metric preferences, so it isn't decided. ruled vs exact is consistent in every frame, but the absolute margin is ~1 ΔE.
- Q4: the energy test can't tell Floyd–Steinberg from other diffusion dithers. Our sim uses x264, not the original encoder.

## Files
- Side-by-sides (top: raw; bottom: renders with HUD γ 0.76): committed: `sbs_132.png`, `sbs_462.png`; regenerated by a rerun: `out/sbs_{132,310,408.5,462,578.5,765,907.5}.png`. Panels are LP | best (exactNearest/highest/FS/E1) | current (ruled/highest/FS/E1).
- 02:12 table zoom ×3: `zoom132_table_x3.png` (committed) (LP | best | current | current without light 24 | Effects 3; second row with γ).
- Q4 full resolution: `q4_table_fullres.png` (committed) (LP | fs bilinear | none bilinear | fs nearest | none nearest, through simulated x264).
- Data: `match.json`, `scores.json`, `masks.json`, `q4.json`, `q4full.json`, `score_out.txt`, `tables.md`.

## Rerun
```sh
cd $S/tool && swift build -c release --scratch-path $S/tool/.build      # tool: render | lights <eff> | info
cd $S   # needs python3 + numpy + PIL, ffmpeg in /opt/homebrew/bin
python3 scripts/vid.py 132 310 408.5 462 578.5 765 907.5   # LP medians -> v/c*.png
python3 scripts/match.py && python3 scripts/refine.py              # scrolls -> match.json (needs mosaic/: fzcolour render ruled highest fs 3 0 mosaic h,v ...)
python3 scripts/renderall.py                               # 48 combos -> combos/
python3 scripts/hudtone.py; python3 scripts/score.py               # HUD gamma; scores.json + ranking
python3 scripts/q1.py; python3 scripts/q3.py; python3 scripts/spritelight.py; python3 scripts/q4.py; python3 scripts/q4full.py
python3 scripts/sidebyside.py                              # out/*.png
```
Direct render: `tool/.build/release/fzcolour render <exact|ruled|inv4|inv5> <lowest|highest> <fs|none> <effects> <sprites 0|1> <outdir> h,v [...] [--drop i,j] [--only i,j] [--twinkle k]` writes 640×480 RGB24 `.rgb` files.
