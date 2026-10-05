# Aki — what to expect (Phase 2 gate build, 2026-10-04)

This is the Phase 2 build of the Aki — Mahjong Solitaire 1.2.0 replica: everything from Phase 1 plus the game
itself. Every picture, sound, string and dialog still comes from the original files, under their original names.

## Opening it
- Double-click `Aki.app`. The map appears as in Phase 1 (Theme 3 if Music is on).
- To start over as a first launch (all levels locked again, stats cleared): run
  `defaults delete com.ambrosiaclassics.aki` in Terminal, then relaunch.

## The question for you
**Play a level start to finish on each difficulty — does it play like Aki?** Plain yes or no; detail below.
Pick the difficulty with the arrows under Skill Level on the map, then click a lit lantern.

1. **Hard.** Each pair matched adds 3 s. A Tip (⌘T or the left button) costs half the time left; a reshuffle
   costs three quarters. No Undo.
2. **Medium.** A match adds 6 s. A Tip costs a quarter of the time left, a reshuffle half. No Undo.
3. **Easy.** A match adds 12 s. Tip costs an eighth, reshuffle a quarter. **Undo** (⌘Z) takes back the last pair
   for 12 s.
4. **Practice.** The stone bar never runs down, nothing costs time, Undo works, and winning does not unlock the
   next lantern (but the win still counts in Level Statistics).

## What to try along the way
- The slide: clicking a lantern slides the map apart onto the level's own background, with LevelStart and the
  game theme. Winning or giving up slides back to the map, with the lanterns you have lit.
- Click a tile: red selection and the tile-hit click. Click it again: deselects. A non-matching tile: the cancel
  sound. A match: TileMatch, the pair fades away (please watch this closely — see "fade" below).
- ⌘T twice in a row (the second Tip moves on to the next pair); ⌘R and the Reshuffle button; ⌘P and the Pause
  button (the board hides, the Pause button glows); Give Up with Esc or ⌘N ("Are you sure…?").
- Leave the mouse alone for 30 seconds: the Tip button starts to flash.
- Let the clock run out on Hard: the stones run out, then the proverb screen on the way back to the map.
- Run out of moves: "no more pairs" — the panel appears, the board greys and the Reshuffle button flashes.
- Win a level: LevelComplete, back to the map, the next lantern lit.
- ⌘L Level Statistics, both from the map and in the middle of a level (the game pauses under it).
- Preferences ▸ untick Tile Animation: matched pairs vanish in one step instead of fading.
- Switch to another app mid-level (windowed): the game pauses; coming back resumes it.

## Remastered Art (new, D11)
- A second look for the same game: every picture redrawn 4× sharper (AI-upscaled). Nothing else changes —
  same layout, timing and rules.
- Your picks from the last look: the backgrounds are the smooth (de-dithered) set, and the tile body is a plain
  smooth enlargement (no grain) with the AI-upscaled pictures on top.
- Turn it on or off with **⌘G** — works in fullscreen too, where the menu bar is hidden — or **Aki ▸ Remastered
  Art** (a check mark shows it is on), or the **Remastered art** checkbox at the bottom of Preferences (applies on OK).
- A fresh install starts in Original. It switches live — on the map or mid-level (also paused or in "no more
  pairs"); the game carries on where it was.
- If the menu item and the checkbox are greyed out, this build was staged without the Remaster art.

## Known differences from the 1.2.0 original (deliberate)
- No registration: the replica behaves as registered. "Register Aki…", "Check for Updates…" and
  "Download Levels…" are gone (the servers are dead), and so is the demo's "levels available" alert.
- Fullscreen does not switch the display to 800×600: the picture fills your screen, crisp at an exact multiple,
  smoothly scaled otherwise.
- Preferences live under the replica's own identifier, so an old Aki 1.2 prefs file is not read; an Aki 1.1
  "Aki Prefs" file is migrated.
- The About box is the standard macOS panel with the shipped credits, not the ASW framework window.
- Level Editor, Play Custom Level and Replay are Phase 3 (their menu items stay disabled).

## Please look at (readings we could not settle from the code alone)
- **Fade (fixed after your first play):** a matched pair should now visibly fade, about a third of a second. Like
  the 2008 Mac, each of the 11 steps waits for the screen refresh (the two tiles step one refresh apart). Does
  it look like the original's fade?
- The stone bar at the start, and after bonuses push it past 2½ minutes — do grey stones appear over black ones?
- The eight Season tiles all match each other, and nothing else cross-matches.
- Level Statistics, row 2: the Wins box stays blank (the original's OK button shares its control number).
- Clicking a wrong tile on a stack: upper-layer mismatch clears the selection, bottom-layer keeps it.
- In "no more pairs": the Reshuffle button restores the frozen time; ⌘R charges from the clock as it kept running.
- Leave the Give Up dialog open for 10 s: the clock, low-time tick and flashes keep going behind it. Did the
  original's clock really keep running under that dialog? If so, letting the time run out under it, then clicking
  OK, stops the map music and makes the next level end straight away — we copied that; tell us if you remember
  otherwise.
- The pressed look of the Tip and Reshuffle buttons.
- Easy, reach "no more pairs", then ⌘Z: the board stays grey with the panel until the next full redraw.
- Under 15 s with bonuses: the low-time tick plays once each time you drop below 16 s.
- Fast clicks on two different tiles (the double-click guard is half your system double-click time).
- Levels 3, 4, 8, 11 while a tile is selected: a small patch may flash at an unshifted spot.
- The stacked ending: music stops, Reshuffle sound, the no-more-pairs panel, then "Tile Stacked".
- Esc mid-level asks "Are you sure…?" first; quitting mid-level asks the same.
- ⌘Tab out windowed (pauses) and fullscreen (only the music stops).
- The tile-select click is `tilehit.mp3`.
