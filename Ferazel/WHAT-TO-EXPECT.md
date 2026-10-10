# Ferazel's Wand — what to expect (Phase 1 gate build)

This is the first build of the Ferazel's Wand 1.0.3 replica. It shows one thing: **how level 1 looks.** The level is
drawn, the background scrolls behind it, Ferazel stands at the start and breathes, the placed sprites sit where the
level puts them, the status bar is drawn, and track 1 of the music plays. Every picture and sound comes from the
original game files, unchanged.

The question for you is one line: **does it look like Ferazel?**

## What this build is — and is not
- **It is** the look: the tiles and their colours, the grass and edge blending, water and acid, the darkness of each
  cell, the lights, the parallax background, the placed sprites, Ferazel standing at the start, the status bar, the
  frame around the play view, the music, the speed.
- **It is not** the game yet. Ferazel does not really move — no running, jumping, falling or magic, and nothing touches
  anything. No title screen, no menus, no sound effects. The chapter-1 screen that comes before the level is skipped;
  the build drops you straight into level 1. Real movement is Phase 2; menus and the rest come later.

## Opening it
- Double-click `Ferazel's Wand.app` on your Desktop.
- If macOS says it can't check the app: right-click it, choose Open, then Open again.
- The window is the game's 640×480 screen scaled ×2 or ×3 (whichever fits your screen whole). ⌃⌘F gives full screen.
- This is a Release build, so it holds the original's speed (about 30 frames a second).

## Keys
- **← → ↑ ↓** (or **keypad 4 / 6 / 8 / 5**, the original's default keys) — move the camera's focus around the level so
  you can look at it; holding **Shift** (the original's run key) moves it faster. Left/right also make Ferazel turn and
  walk or run **in place** — he doesn't go anywhere yet.
- **⌃⌘F** — full screen on and off.
- **⌘Q** — quit.
- **Caps Lock** (pause) and **Esc** (the "abort game?" dialog) do nothing until Phase 3. Nothing else does anything yet.

## Things that differ from the original on purpose
1. **No screen switching.** The original switched your monitor to 640×480 in 256 colours. This build runs in a window
   (or full screen) and does the 256-colour palette itself.
2. **No CD check, no installer check, no birthday dialog.**
3. **No InputSprocket.** Keys come straight from the original's own key table.
4. **The menu bar** hides during play, as the original did.
5. **Settings and saves** will live in their own folder under Application Support (later phases).
6. **Music** is played by our own player from the original music files; the loop point may sound a hair different from
   QuickTime's.

Things that are missing on purpose for now:
- **Ferazel doesn't move** (Phase 2). The arrows move the camera instead, and he walks or runs on the spot. This is a
  stand-in, as is the way the camera follows the keys.
- **The placed sprites only show their first picture** — see "First face only" below. They don't move or do anything
  (Phases 4–5).
- **No sound effects, no title screen, no menus, no chapter-1 screen.**
- **The music starts at full volume.** The original fades it in at the start of the level; that fade isn't built yet
  (LOW).
- **The picture looks a little darker than your Let's Play.** Measured against the video, that is mostly display gamma:
  the original ran on a classic Mac screen (gamma about 1.8), modern screens use 2.2. You ruled (2026-10-10) a hidden
  gamma switch, off by default, like the tie-break one — it is **not built yet**.
- **The table next to the potion is too bright.** The potion's light (light 24) lights the table sprite far more
  than in the video, which looks like a glow behind the table. How the original lights neighbouring sprites with an
  item's light is still to be read from its code (an open item).

### First face only
- 22 kinds of placed sprite show the first picture of the sheet their own code uses. Their real starting picture comes
  with their own code in a later phase.
- Ten kinds — 1485, 2710, 2713, 2714, 3002, 2842, 1700, 1705, 1760 and 1720 — start out in the original with a
  placeholder picture (PICT 150) and something we haven't read yet gives them their real one. This build simply draws
  the picture they load.
- Platforms are not arranged in their circles, their partner pieces are not spawned, and the spokes of 1485 are missing.
- The Crawler (1712) shows its sheet's picture, because the picture its setup asks for (PICT 1500) isn't in the game
  files.

## The gate card — what to check

Compare with the longplays and your Let's Play link. Each line names what you'll see, how sure we are (LOW = least sure,
MED = fairly sure), and what would be wrong.
1. **Colours of every tile and sprite** — every picture is converted through the colour search (the Color2Index
   model). The build uses the **exact nearest-colour** model: you ruled it on 2026-10-10 after it measured best against
   your Let's Play in all 7 frames compared (`docs/ferazel/colour-measurement-2026-10-10.md`). Exact versus the 5-bit inverse table is still
   LOW — the two measured too close to separate; the other models are a one-line switch.
2. **Dithered 32-bit art** — LOW: barrel 2922, chair 2924, table 2927, Geroditus 2951, merchant 2952, book pile 2842,
   sign 2902, moss 2713, Walker 1700, Roach 1720, the HUD piece 133 are 32-bit pictures the original dithered into
   256 colours. Your Let's Play shows they were dithered with error diffusion (HIGH, `docs/ferazel/colour-measurement-2026-10-10.md`); ours uses
   Floyd–Steinberg, and that this is the exact method is LOW. Look for dot patterns on those sprites.
3. **Grass/edge blending** (the foreground's blended edges, 1,335 cells in level 1) — this is where the two colour
   models disagree most (35 % of entries).
4. **Water** — water in level 1 spans x 128..6208, y 608..1600; **acid**: 24 cells at x 6016..6272, y 544..640. Wrong
   would look like: the water or acid the wrong colour, or the ground at the water's edge cut off with a hard square
   edge / the far background showing through where solid ground should be (colour LOW, edges MED).
5. **Darkness per cell** (every cell in level 1 has its own light level) — MED for tiles.
6. **Parallax** — the far background scrolls slower than the level, and one horizontal band of it moves even slower
   sideways than the rest (as the original does). Wrong would look like: the background hills jumping, tearing or
   repeating a strip while you scroll, or the background showing through things it shouldn't.
7. **Status bar** — the bars at their starting values; the magic bar sits at x 419, about two-thirds of the way across
   (read from the original's code). The text is
   Times bold, white — MED: the game asks for font 20, which is Times, and the game files carry no font of their own.
   Wrong would look like: the text in a different typeface, size or colour, or a bar in the wrong place.
8. **Camera** — the level opens at the top-left corner of the map and **pans in** to Ferazel: its vertical scroll first
   reaches v 10 on the 24th frame, about 0.8 s at 30 frames a second. That is the original's own behaviour (read from its code), not a bug. His exact height in the view is a reading
   (MED). Arrows or keypad move the camera; this is Phase 1 only (Phase 2 brings the original keys and real movement).
9. **Ferazel** — stands at the start, breathes, turns, walks/runs in place on left/right (stand-in; Phase 2 makes him
   move). On the very first frame he isn't drawn at all — a one-frame blink at the start is the original.
10. **Placed sprites** — every sprite in its starting picture; anything listed under "First face only" above is
    deferred.
11. **Ground and wall tile colours** (MED: which palette the original used for them is assumed). Wrong would look
    like: the ground tiles' colours off or banded compared with the longplays, while the background looks right.
12. **Music** — track 1 loops. It starts at full volume (the original fades it in — not built yet, LOW).
13. **Icon** — previews of the original 32×32 icon scaled up to a modern icon are in the folder
    **"Ferazel icon previews"** on your Desktop (light, dark, tinted and clear). Pick one.
14. **The black border** around the play view — that is the original's own screen picture (the 608×384 view sits
    inside it, 16 px from the left and 8 px from the top), not a bug. Your Let's Play shows the same frame.
15. **The duplicate-black tie-break — decided: highest.** The palette has black in more than one slot. You ruled on
    2026-10-10, from your Let's Play (at 02:12 the foreground rock edges are clean light grey, no yellow specks), that
    the original matches **highest**, so the build starts on highest. The colour measurement against the video
    confirms it (`docs/ferazel/colour-measurement-2026-10-10.md`). The other choice, **lowest**, shows yellow
    specks along the foreground edges. To look at lowest anyway, quit the game, open Terminal and paste:

    `defaults write com.ambrosiaclassics.ferazel ColorTieBreak lowest`

    then open the game again. To go back to highest, quit, paste:

    `defaults delete com.ambrosiaclassics.ferazel ColorTieBreak`

    and open it again.
16. **Brightness and the glow behind the table — known deviations** (`docs/ferazel/colour-measurement-2026-10-10.md`). Next to your Let's Play,
    our picture looks darker overall: that is mostly display gamma (the original ran at classic Mac gamma, about
    1.8); your hidden gamma switch, off by default, is not built yet. The glow behind the table is the table sprite
    lit too brightly by the potion's light (light 24); how the original does that is an open item still to be read
    from its code.

Known by design: no chapter-1 screen, no menus or title screen, no sound effects, the window scaled ×2 or ×3; Caps Lock
(pause) and Esc (abort dialog) do nothing until Phase 3 — ⌘Q quits.

## What to tell us
Plain yes or no to "does it look like Ferazel?" — then anything that looked wrong, by card number if you can, and your
pick for line 13 (icon).
