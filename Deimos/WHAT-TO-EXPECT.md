# Deimos Rising — what to expect (Phase 1 gate build)

<!-- ORCHESTRATOR: build stamp -->

This is the first build of the Deimos Rising 1.0.6 replica. It shows one thing: **the opening of level 1, Mariner
Valley.** The map scrolls, the ship fades in, the score bar is drawn. Every picture comes from the original game files,
unchanged.

The question for you is one line: **does it look like Deimos?**

## What this build is — and is not
- **It is** the look: the scrolling map, the ship in its place, its shadow, the crosshair, the score bar, the frame
  around the playfield, the speed.
- **It is not** the game yet. No enemies, no shooting, no ground objects, no level-name title, no sound or music.
  The ship banks but does not fly around. All of that is Phase 2.
- The map stops after about 104 seconds. That is the end of the level. Nothing comes next yet.

## Opening it
- Double-click `Deimos Rising.app` on your Desktop.
- If macOS says it can't check the app: right-click it, choose Open, then Open again.

## Keys
- **← / →** — the ship banks and the whole map pans sideways.
- **Esc** — starts level 1 again (a stand-in for the main menu, which comes later).
- **⌃⌘F** — full screen on and off.
- **⌘Q** — quit.
- Nothing else does anything yet.

## Things that differ from the original on purpose
1. **Whole frames, no tearing.** The original could tear. It runs in a window (or full screen) instead of switching
   your screen to 640×480.
2. **No InputSprocket.** Keys come straight from the original's own key table: Player 1 is ↑ ← → ↓, then ⌘ ⌥ Space;
   Player 2 is keypad 8 4 6 5, then End, Forward-Delete, Page Down.
3. **It's the registered game.** The original's copy-protection checks are not built.
4. **No system volume changes** (sound comes in Phase 2 anyway).
5. **Settings and films** will live in their own folder under Application Support (later phases).

Things that are missing on purpose for now (they come in Phase 2):
- **The ship stays where it is**, at the bottom centre. Left/right bank it and pan the map; it does not move, speed up
  or shoot. Up, down, fire and select do nothing.
- **No enemies or objects.** Nothing is spawned — not the entry wave, not the score multiplier.
- **No sound or music.**

## The gate card — what to check

Open `~/Desktop/Deimos Rising.app`; compare with a longplay of Mariner Valley's opening. Each line names what you'll see
and what would be wrong.
1. **The opening** — black for a moment, a quick fade up (~0.15 s) straight into the jungle map, already scrolling.
   Wrong: a pan-in, a slow fade, or the score bar fading separately from the map.
2. **The map** (sector 1, Mariner Valley, `jum2`) — scrolls down the screen 1 pixel per frame, smooth, about 30 px a
   second; nothing else on it yet (no enemies, ground objects or level-name title — Phase 2). Wrong: upside down (would
   also mean the title screen is — INDEX #10), mirrored, or the wrong speed. *(Which way up the map pictures are stored
   is not fully certain from the code — see "Not yet certain" below.)*
3. **The frame** — 32-px black bars left and right of the playfield, the score bar on the right; a whole-number scale with
   black around it in the window and in full screen (⌃⌘F).
4. **The score bar** — `0000000` in pale cyan monospaced digits, reserve lives "2", the ship symbol, the Ion Cannon icon
   (no second/third icon — at sector 1 the Ion Cannon is the only air weapon), both meters dark; the shield meter fills
   from empty in about 1.7 s once the ship is in; Player 2's block below is drawn dimmed and never changes. Wrong: digits
   spaced unevenly (the original uses a 6-px cell even though most digits are 7 px — a quirk we copy), wrong colours.
5. **The ship** — nothing for about 1.9 s, then the orange ship fades in (~1.7 s) at the bottom-centre, with a half-size
   dark shadow down and to the left (ground under it at 62.5 % brightness). Wrong: a hard pop-in, a full-size shadow, a
   shadow on the wrong side.
6. **The crosshair** — the plasma-bomb target fades in ~121 px ahead of the ship, 0 → 100 at 6 per tick from the ship's
   first active tick (~0.6 s) — a quick fade, not a pop. It is drawn on the player-interface layer (`plui`, 13), it
   pans sideways with the map when you bank, and it **casts no shadow**. All three were read from the original code
   this phase. Wrong: a pop-in, a shadow under it, or it staying put while the map pans.
7. **Left / right** — the ship banks (3 frames each way, one step every 2 frames) and the whole map pans up to 32 px;
   **the ship itself does not move** (that is Phase 2). Up/down, fire and select do nothing yet.
8. **Colours of the sprites** (ship, shadow, HUD art) — the plates are 24-bit GIFs the game drew into 16-bit, which keeps
   the top 5 bits of each channel (not fully certain). If the ship or HUD look a shade dark or off against the video,
   this is the suspect.
9. **Speed** — 30.07 frames a second (Mac OS 9's 60.15 Hz tick, Q1). If you ran it on OS X, it would be 30.00.
   **If you played Deimos on OS X, just say "60"** and we switch it — it's a one-line change.
10. **After ~104 s** the map reaches its top and stops (the level end, tallies and next sector come with Phase 2).
11. **Keys** — Esc starts level 1 again (stand-in for the main menu); ⌘Q quits. Caps Lock, `-`/`=`, F6 and `~` do nothing yet.
12. **Silence** — no sound or music yet (Phase 2).
13. **The icon** — the original OS X icon (`icns 128`), unchanged.
Known by design: whole frames, no tearing (the original could tear); a window instead of a screen switch.

## Not yet certain — where your eyes help most
The code didn't fully settle these four. If something looks off, it is probably one of them.
- **Sprite colours** (card item 8): how the 24-bit pictures were cut down to 16-bit. A shade too dark → this.
- **Which way up the map is stored** (card item 2): the map pictures are TGA files, which can be stored either way up.
  Upside-down or mirrored terrain → this.
- **The score digit widths** (card item 4): measured from the font picture, not read from the code. Digits that look
  cramped, uneven or overlapping → this.
- **Which button is which** (Phase 2, no effect now): we assume ⌘ fires air weapons, ⌥ fires ground weapons, and Space
  is select, as the guide says. Nothing in this build uses them — just tell us if you remember it differently.

## What to tell us
Plain yes or no to "does it look like Deimos?" — then anything that looked wrong, by card number if you can.
And "60" if you played it on OS X.
