# Deimos Rising — what to expect (Phase 2 gate build)

<!-- ORCHESTRATOR: build stamp -->

This is the second build of the Deimos Rising 1.0.6 replica. Gate 1 settled the look; this one is about play:
**level 1, Mariner Valley, plays from start to finish.** Enemies come down the map, you fly and shoot, you can die,
the score counts, the level ends with its tally, and there is sound and music. Every picture and sound comes from the
original game files, unchanged.

The question for you is one line: **does it play like Deimos?**

## What this build is — and is not
- **It is** level 1, whole: the enemy waves and ground targets, the Ion Cannon and the Plasma Bomb, hits, death and
  lives, coins, the score multiplier, extra lives, the two scroll stops, the "Sector Secured" tally, the effects and
  the level music, Caps Lock pause, F6, the `~` console with its cheats, and the four demo films that shipped with the
  game.
- **It is not** the rest of the game yet. When level 1 ends — by finishing it, by game over, or by Esc — the game
  simply starts level 1 again. No level 2 onward and no two-player game (Phase 3); no menus, high scores or saved
  settings (Phase 4); no Windows build (Phase 5).
- **Leave it alone and it dies.** With no keys pressed the ship sits in the line of fire: all three lives are gone in
  about 17 seconds and the game starts again. That is the original's behaviour, not a bug.

### Stand-ins (marked ◇)
A stand-in is something this build does in place of a part of the game that isn't built yet. Each one is marked ◇
here and on the card, and each goes away in the phase named.
1. ◇ **Level complete** starts level 1 again (Phase 3 fades to black and moves on to sector 2).
2. ◇ **Game over** starts level 1 again (Phase 4 adds the high scores and the menu).
3. ◇ **Esc** starts level 1 again (Phase 4: Esc goes back to the menu).
4. ◇ **Level-start music.** The original came to level 1 from its level-select screen, whose music stopped as the
   level loaded. There is no level-select screen yet, so the level opens in silence; the level's own track starts as
   the screen fades in, as in the original.
5. ◇ **Demo films from the command line.** `-film de01` (see Opening it) plays a shipped demo inside the game, by the
   original's film rules (the `REPLAY` banner, no level music). In the original the menu music kept playing under a
   demo; there is no menu yet, so a demo plays without music. Phase 4's attract mode (the demos cycling on the title
   screen) replaces this.
6. ◇ **Settings last until you quit.** F6 (interlacing), the FPS counter, `supermunki` and the volume carry over when
   level 1 starts again, but are forgotten when you quit (Phase 4 writes the settings file).
7. ◇ **One player.** Two-player games come in Phase 3 (the machine already tests the rules for both players).
8. ◇ **The mouse doesn't stop a demo.** In the original, clicking the mouse was the only way besides Esc to skip a
   demo. Mouse input isn't wired in yet (Phase 4).

## Opening it
- Double-click `Deimos Rising.app` on your Desktop.
- If macOS says it can't check the app: right-click it, choose Open, then Open again.
- If the window opens but stays black, click it once — the game pauses whenever it isn't the front app.
- **To watch a demo film** (◇ 5), type this in Terminal:

  ```sh
  open -a "Deimos Rising" --args -film de01
  ```

  `de01` is level 1 and is the one this gate is about. `de02`, `de03` and `de04` play later levels (level files 06,
  02 and 08); they run, but only level 1 is being judged now.
  - A demo ends when it runs out, on Esc, on level complete or on game over. **Other keys do not end it** — as in the
    original.
  - When a demo ends, or you press Esc during it, **the same demo starts again** (◇ — the original went back to its
    menu). Quit with ⌘Q.
  - During a demo Caps Lock does not pause (as in the original); the `~` console and F6 still work.

## Keys
| Key | What it does |
|---|---|
| ↑ ← → ↓ | fly the ship (it speeds up and drifts to a stop) and bank |
| ⌘ | fire the air weapon (Ion Cannon): tap, or hold to charge |
| ⌥ | fire the ground weapon (Plasma Bomb) |
| Space | select the next air weapon (nothing to select in sector 1) |
| Caps Lock | pause while it is down |
| F6 | interlacing on and off, with a message |
| `~` | open the console |
| `-` / `=` | the original's volume keys — on Mac OS X they do nothing you can hear (card line 9) |
| Esc | start level 1 again (◇ 3) |
| ⌃⌘F | full screen on and off |
| ⌘Q | quit |

Typed letters reach the console as the original's classic Mac character codes, so console commands are read exactly
as the original read them.

## Things that differ from the original on purpose
1. **Whole frames, no tearing.** The original could tear. It runs in a window (or full screen) instead of switching
   your screen to 640×480.
2. **No InputSprocket.** Keys come straight from the original's own key table: Player 1 is ↑ ← → ↓, then ⌘ ⌥ Space.
3. **It's the registered game.** The original's copy-protection checks are not built.
4. **No system volume changes.** The game never touches your Mac's volume; it plays at full level.
5. **Files go in their own places.** The settings file (Phase 4) will live in the game's own folder under
   Application Support, and the "Last Film" recording in your own user folder for the game, not inside the app.
   A missing game file shows an alert only in a developer build.
6. **Sound freezes in the background.** When the game isn't the front app, or the window is minimised, all sound —
   effects and music — stops until you come back. The original stopped only the music there and let effects play on.
   **Say if you want effects to play on.**
7. **A few rare cases where the original read leftover memory.** In a handful of corner cases (an enemy told to flee
   when no player is alive, a refused spawn, and a couple of others like them) the original read whatever
   happened to be in memory. The replica uses a fixed value (zero or −1) there. You should never see the difference.
8. **Timing of a frame or so.** A sound may start up to one frame early (cues are sent at the start of a frame, not
   mid-way), and after a Caps Lock pause the music picks up one frame after the game does.
9. **Speed** stays as you chose at gate 1: 30 frames a second, Mac OS X's tick. The picture scales by whole numbers
   with black around it.

## The machine replay — what was proven before you open it
A demo film is a recording of the original's key presses plus the score it reached. This build's game rules were fed
each shipped film, and the score they reached was compared with the score the original recorded. If any rule that
touches the score were even slightly off — an enemy appearing a row late, a hit missed, the random numbers drawn in
a different order — the scores would drift apart.

All four films end on exactly the original's score:

| Demo | Recorded score | This build |
|---|---|---|
| de01 (level 1, Mariner Valley) | 25,050 | 25,050 |
| de02 | 116,180 | 116,180 |
| de03 | 57,520 | 57,520 |
| de04 | 24,670 | 24,670 |

The replay tool's own line for de01:

```
de01 le07 seed 0x469c2: score 25050 at read 4809 (end: filmEnd) PASS
```

**What that does not prove:** a matching score proves the rules behind the score — when enemies appear, hits, kills,
coins, the tallies and the order of the random numbers. It does not prove how anything sounds, what colour it is or
how it feels to fly. That is the card below.

**Not checked by any machine before you open it:** that sound actually comes out of your speakers. An offline check
of the sound path passed, but the app itself has not been launched by the build session.

## The gate card — does it play like Deimos

Open `~/Desktop/Deimos Rising.app`; play Mariner Valley; compare with a longplay. Each line: what you'll see or hear,
and what would be wrong.
1. **Enemies and ground targets** appear as the map scrolls: Buzzsaw waves, **five Bonus Stations**, four laser
   platforms, a pulse tank, geysers, a secret. Wrong: things popping in on screen (they enter 64 px above the top),
   ground units sliding against the map (they ride it).
2. **Two scroll stops.** About 61 s in, the map stops for ~27 s while Buzzsaw groups come down from the top; near the
   end it stops again ("Level 1 - Bridge") until you destroy every ground target on screen or ~27 s pass.
3. **Your ship** accelerates and drifts to a stop, banks, slides 32 px under the side borders, can't go above the top
   13 px.
4. **Ion Cannon:** tap = a pair of bullets + flash (max ~6 shots/s, each needs a fresh press); hold ~0.5 s =
   power-up charging (meter fills in 2 s), release = a stream of power shots; hold ~6.5 s = overload flashes and the
   ship blows up at ~8.3 s. **Plasma Bomb** (Option) flies 114 px up toward the crosshair 121 px ahead, then bursts;
   down at the bottom edge pulls the crosshair in. **Select** (Space) does nothing in sector 1 (only one air weapon).
5. **Hits and death:** 7 full hits kill; the ship explodes, coins spill, 2.7 s (last life 1.3 s) then you re-enter
   invulnerable for 2 s. Game over after the last life → the game starts again (◇).
6. **Score / coins / multiplier:** kills × multiplier; coins and pickups; extra life at 10,000 / 40,000 / 80,000.
7. **Level end:** "Sector Secured", ground-accuracy tally with ticking count, coin bonus, the defence bonus if you
   were never hit; then the game starts again at sector 1 (◇ — the campaign is Phase 3). Wrecked platforms and tanks
   stay painted into the map.
8. **Sound:** effects from the game's own mixer (at most 8 at once); the level music starts as the screen fades in.
   **Pitch question:** bullet impacts `exsl` play short and high (speed = 1/pitch, as the code). If the longplay's
   impacts are deep and slow, say "flip pitch". **Music-level question:** music sits about half as loud as a
   full-volume effect (full scale 255). Too quiet? Say so.
9. **Volume keys `-`/`=` (your ruling, 2026-10-07):** as on Mac OS X — they do nothing you can hear and show no
   message; the game plays at full level and your Mac's own volume controls set the loudness.
10. **Caps Lock** pauses ("Press Caps Lock" notice; sound cut, the pause click, music frozen) until released. **F6**
    toggles interlacing with a message. **`~`** opens the console: `FPS`, `VERSION`, `supermunki` then the cheats
    (`life`, `score`, `funds`, `shields`, `mult`, `accuracy`). **Esc** starts level 1 again (◇).
11. **Particles, wrecks and trails:** debris bursts in the unit's colours (each 3 px right/below of centre — a quirk we
    copy), stopped tanks become obstacles, bullet trails on some units.
12. **Not yet certain (MED):** the 24→16 sprite colour cut (gate 1, unchanged), particle colour shades, the "Press
    Caps Lock" notice placement, tally waits, the FPS counter showing 31, the crosshair "locked" frame timing.
13. **Demo replay (fallback oracle):** `open -a "Deimos Rising" --args -film de01` plays the shipped demo (no music —
    ◇ the menu music is Phase 4). Machine result: PASS — the demo ends on 25,050, exactly the score the original
    recorded (all four shipped demos match; see "The machine replay" above).
Invulnerability carry-over between levels is not reachable until level 2 (Phase 3).

## Not yet certain — where your eyes and ears help most
The code didn't fully settle these. If something looks or sounds off, it is probably one of them.
- **Pitch** (card line 8): whether bullet impacts should be short and high, or deep and slow.
- **Music loudness** (card line 8): music sits at about half a full-volume effect.
- **Sprite colours** (card line 12, unchanged from gate 1): how the 24-bit pictures were cut down to 16-bit. A shade
  too dark → this. Particle colours are the same kind of question.
- **Which way up the map is stored** (gate 1): upside-down or mirrored terrain → this.
- **Which button is which:** we follow the guide — ⌘ fires air weapons, ⌥ fires ground weapons, Space selects. Tell
  us if you remember it differently.
- **Sound out of the speakers:** no machine has heard it yet (see the machine replay section).

## What to tell us
Plain yes or no to "does it play like Deimos?" — then anything that looked or sounded wrong, by card number if you
can. Two short answers are asked for by name: "flip pitch" (card line 8) if impacts should be deep and slow, and
whether effects should keep playing when the game is in the background (difference 6).
