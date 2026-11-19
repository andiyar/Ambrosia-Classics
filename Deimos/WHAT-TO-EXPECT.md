# Deimos Rising — what to expect (Phase 3 gate build: the campaign)

*Built 2026-11-20 from local main. **This one app serves two gates.** It replaces the Phase 2 build that was on your
Desktop, which you had not yet judged: everything in that build is in this one, so the Phase 2 card ("does level 1
play like Deimos") is kept below, unchanged, as Part B. The build session has not launched this app: the first run is
yours, or a muted boot check on your say-so.*

This is the third build of the Deimos Rising 1.0.6 replica. Gate 1 settled the look. Gate 2 asks whether level 1
plays. This one adds **the campaign: all twelve sectors, one after another, in one game, through to the finale** —
and a two-player game. Every picture and sound comes from the original game files, unchanged.

Two questions for you, one line each:
- **Part A — does the campaign play like Deimos?** (new)
- **Part B — does level 1 play like Deimos?** (the Phase 2 question, still open)

## What this build is — and is not
- **It is** the whole campaign. A finished level fades to black and the next sector starts in the same game, with
  your lives, score and multiplier carried over. All twelve sectors are there with their enemies, set pieces and
  weapons. After sector 12 — in a game that began at sector 1 — comes the finale. Two players can play together.
- **It is not** the front end yet: no title screen, menu, level select, high scores, name entry, credits, saved
  settings or controls window (all Phase 4), and no Windows build (Phase 5).
- **Leave it alone and it dies.** With no keys pressed the ship sits in the line of fire. The game runs 30 frames a
  second, and in sector 1 with no input:

  | What happens | About |
  |---|---|
  | the last life is lost | 34 seconds in |
  | the ship is out of the game | 36 seconds in |
  | the game starts again | 40 seconds in |

  That is the original's behaviour, not a bug.

### Stand-ins (marked ◇)
A stand-in is something this build does in place of a part of the game that isn't built yet. Each one goes away in
Phase 4, when the menu and the high scores exist.
1. ◇ **Game over** starts a new game (the original went to the high scores and the menu).
2. ◇ **Esc** starts a new game (the original went back to the menu).
3. ◇ **The end of the campaign** — after the finale — starts a new game (the original went to the high-score check
   and the menu; there is no credits screen after the finale in 1.0.6).
4. ◇ **Where a new game starts.** Sector 1 — unless you opened the game with `-sector N` (below), in which case every
   new game in that run starts at sector N again, with the same number of players.
5. ◇ **Two players from the command line.** `-players 2` stands in for the menu's 2 PLAYER button.
6. ◇ **Starting at a later sector from the command line.** `-sector N` stands in for the level select. As in the
   original's level select, a start above sector 1 gives you **one life** — and **no finale**: the original only
   runs the finale when all twelve sectors were played in one game. Started at a later sector, sector 12 ends with
   its ordinary tally and then a new game starts.
7. ◇ **Level-start music.** The original came to a new game from its level-select screen, whose music stopped as the
   level loaded. There is no such screen yet, so the first level opens in silence; its own track starts as the
   screen fades in, as in the original.
8. ◇ **Demo films from the command line.** `-film de01` plays a shipped demo inside the game, by the original's film
   rules (the `REPLAY` banner, no level music). In the original the menu music kept playing under a demo; there is
   no menu yet, so a demo plays without music.
9. ◇ **Settings last until you quit.** F6 (interlacing), the FPS counter, `supermunki` and the volume carry over
   into a new game, but are forgotten when you quit.
10. ◇ **The mouse doesn't stop a demo.** In the original a mouse click skipped a demo. Mouse input isn't wired in yet.

## Opening it
- Double-click `Deimos Rising.app` on your Desktop.
- It was built on this Mac, so it normally opens with a plain double-click. If macOS ever refuses to open it, open
  System Settings → Privacy & Security, scroll down, and click Open Anyway.
- If the window opens but stays black, click it once — the game stops whenever it isn't the front app.
- **In the background.** When the game isn't the front app, or its window is minimised, it stops: its music pauses,
  and any effect already sounding plays to its end. Come back and both carry on. The original did the same.

### Starting it other ways (Terminal)
First quit the game with ⌘Q if it is running — if it is already open, these commands do nothing. Naming the copy on
your Desktop makes sure this build is the one that opens.

| To do this | Type this |
|---|---|
| two players | `open ~/Desktop/"Deimos Rising.app" --args -players 2` |
| start at sector 7 (any of 1 to 12) | `open ~/Desktop/"Deimos Rising.app" --args -sector 7` |
| both | `open ~/Desktop/"Deimos Rising.app" --args -players 2 -sector 7` |
| watch a demo film | `open ~/Desktop/"Deimos Rising.app" --args -film de01` |

- **A mistyped value quits the game straight away with no message** — a film name the game doesn't have (the demos
  are `de01` to `de04`), a player count that isn't 1 or 2, a sector that isn't 1 to 12. (Only a debug build made from Xcode shows an alert
  first.) If nothing opens, check the spelling.
- With `-film`, the other two are ignored: a film carries its own level and player count.
- The demo films: `de01` is level 1; `de02`, `de03` and `de04` play sector 2 Cydonia Plateau, sector 3 Darius and
  sector 4 Neo Kowloon.
  - A demo ends when it runs out, on Esc, on level complete or on game over. **Other keys do not end it** — as in the
    original.
  - When a demo ends, or you press Esc during it, **the same demo starts again** (◇ — the original went back to its
    menu). Quit with ⌘Q.
  - During a demo Caps Lock does not pause (as in the original); the `~` console and F6 still work.

## Keys
| Key | What it does |
|---|---|
| ↑ ← → ↓ | fly the ship (it speeds up and drifts to a stop) and bank |
| left ⌘ | fire the air weapon: tap, or hold to charge |
| left ⌥ | fire the ground weapon (Plasma Bomb) |
| Space | select the next air weapon the current sector allows (nothing to select in sector 1) |
| Caps Lock | pause while Caps Lock is on (its light lit); if it is already on when you open the game, the game pauses at once |
| F6 | interlacing on and off, with a message |
| `~` | open the console |
| `-` / `=` | the original's volume keys — on Mac OS X they do nothing you can hear (Part B line 9) |
| Esc | start a new game (◇ 2) |
| ⌃⌘F | full screen on and off |
| ⌘Q | quit |

Only the **left** ⌘ and ⌥ keys fire. The right-hand ⌘ and ⌥ are different keys to the game and do nothing.

**Player 2** (only with `-players 2`) uses the original's default keys, which are all on the number pad and the
block above the arrows:

| Key | What it does |
|---|---|
| keypad 8 / 4 / 6 / 5 | up / left / right / down |
| End | fire the air weapon |
| Forward Delete | fire the ground weapon |
| Page Down | select |

A laptop keyboard has no number pad, so player 2 could not steer. Changing the keys needs the controls window,
which is Phase 4 — so a two-player game needs a full-size keyboard for now.

**Careful:** holding ⌘ to fire and then pressing Space opens Spotlight, which sends the game to the background (it
stops until you click back on it). From sector 2 on, Space is useful — let go of ⌘ before you press it.

**Careful:** holding fire too long overloads the weapon and destroys your ship (Part B line 4) — **even at the
times when nothing else can hurt you** (the two seconds after you re-enter, and the level-end tally). That is the
original's rule, read from its code. If you remember being safe from your own overload then, say so.

Letters you type reach the console exactly as the original Mac handed them over, so console commands are read just
as the original read them.

## Things that differ from the original on purpose
1. **Whole frames, no tearing.** The original could tear. It runs in a window (or full screen) instead of switching
   your screen to 640×480.
2. **No InputSprocket** (the old Mac OS game-controller layer the original could use). Keys come straight from the
   original's own key table.
3. **It's the registered game.** The original's copy-protection checks are not built.
4. **No system volume changes.** The game never touches your Mac's volume; it plays at full level.
5. **Files go in their own places.** The settings file (Phase 4) will live in the game's own folder under
   Application Support, and the "Last Film" recording in your own user folder for the game, not inside the app.
   A missing game file shows an alert only in a debug build made from Xcode; this staged build just quits.
6. **A few rare cases where the original read leftover memory.** In a handful of corner cases (an enemy told to flee
   when no player is alive, a new enemy the game could not create, and a couple of others like them) the original
   read whatever happened to be in memory. The replica uses a fixed value (zero or −1) there. You should never see
   the difference.
7. **Timing of a frame or so.** A sound may start up to one frame early (cues are sent at the start of a frame, not
   mid-way), and after a Caps Lock pause the music picks up one frame after the game does. At a level change the
   sounds are sent around the fade as the original does: the transition sound plays through the fade to black, and
   the next level's sounds wait until the fade has finished.
8. **Speed** stays as you chose at gate 1: 30 frames a second, Mac OS X's tick. The picture scales by whole numbers
   with black around it.
9. **"Is that sound still playing?" is always "no".** The original has a rule that would let a game decision depend
   on whether a particular sound is still playing. The replica always treats that sound as not playing. No enemy or
   object in the shipped game uses that rule, so nothing you can see or hear changes.
10. **Two rules that could only differ with game files nobody shipped.** The check that decides whether an effect may
    play, and what the music does when a track is missing, are written slightly differently from the original. They
    behave the same for every file in the game; they would differ only for kinds of data no shipped file contains.

## What the machine proved before you open it

**The demo films.** A demo film is a recording of the original's key presses plus the score it reached. This build's
game rules were fed each shipped film, and the score they reached was compared with the score the original recorded.
If any rule that touches the score were even slightly off — an enemy appearing a row late, a hit missed, the random
numbers drawn in a different order — the scores would drift apart. All four films end on exactly the original's
score (re-run 2026-11-20):

| Demo | Recorded score | This build |
|---|---|---|
| de01 (level 1, Mariner Valley) | 25,050 | 25,050 |
| de02 (sector 2, Cydonia Plateau) | 116,180 | 116,180 |
| de03 (sector 3, Darius) | 57,520 | 57,520 |
| de04 (sector 4, Neo Kowloon) | 24,670 | 24,670 |

**The level change, what carries over, two players and the finale.** No film covers any of these, so each was
written as tests read line by line from the original's code: 28 tests, all passing, inside a suite of 372.

**The sweep.** The machine also played the game itself, with a ship that cannot be hit and a scripted pilot that
steers and fires:

| What it played | Result |
|---|---|
| each of the twelve sectors from a direct start, twice | every one reaches its end; sectors 1 to 11 hand over to the next, sector 12 ends the game |
| one whole campaign, sector 1 to the end of the finale | completes: 128,469 game steps, about 71 minutes of play |
| a two-player start through the first level change | completes |

The longest level is sector 11, at about 9½ minutes: it has five long holds, each as long as the original's data
says.

**What all that does not prove.**
- A matching film score proves the rules behind the score in sectors 1 to 4, one player. It does not prove how
  anything sounds, what colour it is or how it feels to fly.
- No film crosses a level change, plays sectors 5 to 12, fires the Photon Beam, has two players or reaches the
  finale. Those rest on the tests, the sweep and you.
- The sweep shows nothing gets stuck. Its ship cannot die and its pilot is a script, so it says nothing about
  whether sectors 5 to 12 are as hard, as fair or as lively as you remember.
- **Sector 12's last fight.** No machine run wins it by destroying the Beamer. As the game's data reads, the fight
  ends on a timer and destroying the Beamer only ends it sooner; the sweep simply outlasts it, with the Beamer still
  alive when the finale begins. **Do you remember the level ending with the Beamer still alive?**
- **The launch options** (`-players`, `-sector`) were checked by reading and building, not by starting the app.
- **Sound out of your speakers.** An offline check of the sound path passed, but the app itself has not been
  launched by the build session.

## Part A — the gate-3 card: does the campaign play like Deimos

Open `~/Desktop/Deimos Rising.app`; play from Mariner Valley. The console's cheats are there if you want to get
through quickly (`~`, then `supermunki`, then `life`, `shields` and the rest). Each line: what you'll see or hear,
and what would be wrong.
1. **Between levels:** when the tallies finish, the music stops, a transition sound plays through a fade to black of
   about half a second, and the next sector fades in with its level notice and the level music. Wrong: a pause, a
   flash of the old level, sound cut off, or the game starting again at sector 1.
2. **What you keep:** lives, score, the next-extra-life mark and your multiplier carry over. Wrong: any of them reset.
3. **What resets:** coins go back to zero (after their bonus was paid), the shield is full again, power-ups are idle.
4. **Weapons:** entering sector 2 gives you the Bacta Gun, sector 3 the Rear Gun, sector 5 the Photon Beam; elsewhere
   you keep the one you last selected. There is one air-weapon slot: Select (Space) cycles the air weapons the
   current sector allows. The weapon and item icons in the side panel follow the sector.
5. **Invulnerable at the start of a new level:** after the first level you re-enter each level unable to be hit for
   about two seconds (carried from the level end, as the original's code reads). On level 1 you do not. If your
   memory says otherwise, say so. (Your own weapon overload still kills you in those two seconds — see Keys.)
6. **A player who is out stays out** in a two-player game; the other plays on.
7. **Caps Lock exactly as a new level starts** shows the new level at once, not faded in, until you release it — the
   original does the same.
8. **Two players** (`-players 2`; see "Starting it other ways" and the player 2 keys). Both ships start side by
   side; steering the same way slides the view twice as fast, opposite ways cancel. Player 2's panel sits below
   player 1's. Questions for you: are those the keys you remember? Does player 2 still respond while player 1 holds
   Command?
9. **Sectors 5–12:** new enemies and set pieces, the Photon Beam, and in sectors 7 and 12 a hospital that costs
   10,000 × your multiplier if you destroy it. No demo film covers these sectors: your eyes are the check.
   `-sector N` takes you straight to one (with one life; the cheats help).
10. **The finale** (sector 12, reached from a sector-1 start — **not** with `-sector`, which has no finale; the
    cheats will carry you through the twelve sectors): the "all levels" notice flashes fifteen times with a sound
    each; about ten seconds of explosions; four irises open twice with storms of coins and bonuses until about half
    a minute in; the tallies begin about forty seconds after the notice. If every one of the twelve levels was at
    100 % ground accuracy, a mission bonus follows: ten payments of 100,000. Then the transition sound, black, and a
    new game starts at sector 1 (◇ 3).
11. **Not yet certain:** the feel of the eight uncovered sectors; the mix during the finale's explosions; player 2's
    real keys on Mac OS X; whether sector 12 should be able to end with the Beamer alive; anything in Part B you
    have not yet ruled on.

**Six choices this build makes that are yours to overturn:**
1. `-players 2` and `-sector N` stand in for the menu, and a new game returns to the sector you launched at.
2. Player 2's keys are the defaults read from the original's settings code. Where Mac OS X 1.0.6 actually took
   player 2's keys from is not yet read.
3. After the finale a new game starts; no credits screen follows the finale.
4. Every level after the first runs one game step (a thirtieth of a second) later than level 1 does. That is the
   original's own behaviour, copied, not a bug.
5. A build-internal choice with nothing to see: the level start's rules and its drawing are kept in separate places.
6. Two original quirks are copied, not fixed: the multiplier indicator can carry a stale marker into the next
   level, and a player caught dying exactly as the level changes is revived without losing the life.

## Part B — the Phase 2 card: does level 1 play like Deimos

*The Phase 2 card, with three small edits: "the game starts again" now means a new game (◇ 1–4); a finished level 1
now moves on to sector 2 (line 7); and line 13 points at the commands above instead of repeating one. Its old last
line, about invulnerability carrying into level 2, is now Part A line 5. You have not yet ruled on this card; every
line still applies.*

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
   invulnerable for 2 s. Game over after the last life → a new game starts (◇).
6. **Score / coins / multiplier:** kills × multiplier; coins and pickups; extra life at 10,000 / 40,000 / 80,000.
7. **Level end:** "Sector Secured", ground-accuracy tally with ticking count, coin bonus, the defence bonus if you
   were never hit; then the fade to sector 2 (Part A line 1). Wrecked platforms and tanks stay painted into the map.
8. **Sound:** effects from the game's own mixer (at most 8 at once); the level music starts as the screen fades in.
   **Pitch question:** bullet impacts `exsl` play short and high (speed = 1/pitch, as the code). If the longplay's
   impacts are deep and slow, say "flip pitch". **Music-level question:** music sits about half as loud as a
   full-volume effect (full scale 255). Too quiet? Say so.
9. **Volume keys `-`/`=` (your ruling, 2026-10-07):** as on Mac OS X — they do nothing you can hear and show no
   message; the game plays at full level and your Mac's own volume controls set the loudness.
10. **Caps Lock** pauses ("Press Caps Lock" notice; sound cut, the pause click, music frozen) until released. **F6**
    toggles interlacing with a message. **`~`** opens the console: `FPS`, `VERSION`, `supermunki` then the cheats
    (`life`, `score`, `funds`, `shields`, `mult`, `accuracy`). **Esc** starts a new game (◇).
11. **Particles, wrecks and trails:** debris bursts in the unit's colours (each 3 px right/below of centre — a quirk we
    copy), stopped tanks become obstacles, bullet trails on some units.
12. **Not yet certain (MED):** the 24→16 sprite colour cut (gate 1, unchanged), particle colour shades, the "Press
    Caps Lock" notice placement, tally waits, the FPS counter showing 31, the crosshair "locked" frame timing.
13. **Demo replay (fallback oracle):** `-film de01` (see "Starting it other ways") plays the shipped demo (no music —
    ◇ 8). Machine result: PASS — the demo ends on 25,050, exactly the score the original recorded (all four shipped
    demos match).

## Not yet certain — where your eyes and ears help most
The code didn't fully settle these. If something looks or sounds off, it is probably one of them.
- **Pitch** (Part B line 8): whether bullet impacts should be short and high, or deep and slow.
- **Music loudness** (Part B line 8): music sits at about half a full-volume effect.
- **Sprite colours** (Part B line 12, unchanged from gate 1): how the 24-bit pictures were cut down to 16-bit. A
  shade too dark → this. Particle colours are the same kind of question.
- **Which way up the map is stored** (gate 1): upside-down or mirrored terrain → this.
- **Which button is which:** we follow the guide — ⌘ fires air weapons, ⌥ fires ground weapons, Space selects. Tell
  us if you remember it differently.
- **Sectors 5 to 12, the finale's sound mix, player 2's keys, the Beamer** (Part A line 11).
- **Sound out of the speakers:** no machine has heard it yet.

## What to tell us
Two plain answers, yes or no: **"does the campaign play like Deimos?"** and **"does level 1 play like Deimos?"** —
then anything that looked or sounded wrong, by part and line number if you can. Short answers asked for by name:
- "flip pitch" (Part B line 8) if impacts should be deep and slow;
- whether sector 12 can end with the Beamer alive;
- whether your own overload should kill you while you are invulnerable;
- whether player 2's keys are the ones you remember.
