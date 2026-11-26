# Ferazel's Wand for Windows — what to expect (Phase 6A gate build — through the Goblin Chief; levels 1–5, 10, 11, 15, 18, 20, 21, 22)

**Status: machine gates green; Ben's and Andrew's gate pending.**

Ferazel's Wand 1.0.3 for Windows: Ambrosia's Ferazel's Wand (2000), rebuilt to run on Windows 10 and 11 (64-bit) from
the original game's own data. Unofficial, non-commercial preservation. It is the same game as the Mac Phase 6A build —
both boss fights so far (the Manditraki Warrior on level 5, the Goblin Chief on level 18) and seven new levels (10,
11, 15, 18, 20, 21, 22) — in lockstep with it: the Mac card (`Ferazel/WHAT-TO-EXPECT.md`, its 9 steps, its stand-ins
and its known differences) holds here too.

**The project pauses here.** Ferazel's original author is selling an official remaster
(https://mixedmetaphor.itch.io/ferazels-wand), so this is the last build for now (Ben's ruling, 26 November 2026).
Of the game's 24 levels, 12 can be played:

1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21, 22

Levels 25 and later say "Level 25 is not built yet (Phase 6)." (with their own number) and leave you on the map. If
the work ever resumes, the next phase would open levels 25 to 52.

The question for you: **do the levels through the Goblin Chief play on Windows as they do on the Mac — the pictures
by eye, the sound by ear?**

**What nobody has seen or heard yet:**
- **Levels 20, 21 and 22** have only been checked by machine: each was started and stayed running, and the sweep
  visited every object on them. Nobody has looked at them on either system.
- **This is the first time the real Windows program opens a level after 5.** Until now the Windows checks opened
  those levels only inside the test build. Listen for the new music tracks, and for the rain loop on level 15.

## Starting it
Unzip and start it exactly as in the Phase W card below (Extract All, then "Ferazel's Wand.exe"; SmartScreen: More
info, then Run anyway). Saved games from the Phase 5 build still open.

**The level chooser (new; the L key).** On the main menu, press **L**. A message box says:

"New Game will start at level 2, Central Caverns. Press L again for the next level."

Close the box (Enter, or click OK) and press L again to step on. The order is 1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21,
22, then back to 1 (the names are in the Mac card's table). Then start New Game as usual: it opens the level you
chose. The choice lasts until you quit; a fresh launch starts at level 1 again. Continue (a saved game) ignores it. A
game controller cannot press L, so use the keyboard for this. It is an addition of ours (the original has no such
key): in normal play you still go from level to level on the map, finishing a level takes you to the map, and a
level that is not built says so and leaves you on the map.

**The hidden test switch still works.** To make New Game start on a chosen level, open a command prompt in the game's
folder and run (here for level 18):

`"Ferazel's Wand.exe" -FerazelLevel 18`

New Game then goes straight to that level, for that one launch. Any number that is not one of the 12 built levels
means level 1.

**Keys:** as in the Phase W card below (Shift / Alt / Ctrl act as the Mac's Shift / Option / ⌘). The one new key is
**L** on the main menu.

## The gate card: what to check (a Windows 10/11 PC, or CrossOver)
Play **the same 9 steps as the Mac card** (`Ferazel/WHAT-TO-EXPECT.md`, "The gate card: what to check"): the Warrior
fight on level 5; level 10's mountain strip, wind, turning cannons and trees; level 11's river and Nimbo; level 15's
rain, thunder and push; the Goblin Chief on level 18; level 20's clouds, blades, maces, wind and hang glider; level
21's speaking graves, pipes and teleporters; level 22's teleporters, Dimbo, magic carpet, blades and maces; and the
things only your eye and ear can judge. Please look at levels 20, 21 and 22 first.

**Note anything that differs from the Mac** — a picture, a sound, a timing, a dialog.

## Machine checks run for this card
Run on the final code, 26–27 November 2026.

| check | result |
|---|---|
| The game's test suite | 823 tests: 821 passed, 0 failed, 2 skipped on purpose (the sweep and the bot below, which run on their own) |
| The Windows package's test suite | 91 tests: 89 passed, 0 failed, 2 skipped on purpose (the same two) |
| The data census | 1,108 items decoded, 0 failures |
| Builds | the Mac app and both Windows builds: pass |
| **Visit sweep** (every object on every level, taken to and drawn), 12 levels | Windows game path: 11,864 visits, 0 problems. Mac game path: 11,864 visits, 0 problems |
| **Random-play bot** (random keys on every level), 12 levels, 4 runs each, 259,200 steps a path | Windows game path: 43 deaths, 385 level exits, 33 conversations, 3 saves, 0 failures. Mac game path: 44 deaths, 387 level exits, 33 conversations, 3 saves, 0 failures |
| The game's suite run under CrossOver | <<SEAT: Windows test run inside CrossOver — expected 820 passed / 0 failed / 3 skipped of 823>> |
| Start-up check of the staged Mac app (muted) | <<SEAT: Mac start-up check of the staged app, muted>> |
| Start-up check of the staged Windows zip in CrossOver | <<SEAT: start-up check of the staged Windows zip in CrossOver>> |

The two game paths' bot counts differ slightly (one death, two exits); this is not explained yet, and neither path
had a failure.

<<SEAT: where the staged builds are, and the commit they were built from>>

## Known stand-ins on Windows (Phase 6A)
- **The table's row "Every Mac stand-in of Phase 4" now reads:** every Mac stand-in of Phase 6A — the Wizard, the
  Fire Guardians and the last boss and their levels, levels 25 and later, and the ending and credits sequence after
  the last boss — none of them built while the project is paused. Every other row of the Phase W card's stand-ins
  table below still holds.

## Known differences
The Mac card's numbered list (1 to 9) holds here too. The new ones in this build: the thunder's darkening is done on
the picture (5); a new object is skipped safely when all 700 object slots are in use (6); some lit blades and maces on
level 20 are drawn unlit (7); no alert when the light table is full (8); and the level chooser (9). The Phase W card's
"Small differences found while building" below still hold.

## What to tell me
Your answer goes in `docs/QUESTIONS.md` under the Phase 6A gate item (the Windows part): yes or no to "do the levels
through the Goblin Chief play on Windows as they do on the Mac?", then anything that felt, sounded or looked
different, by the Mac card's step number if you can. Please start with:
- **levels 20, 21 and 22** (the Mac card's steps 6–8), which nobody has seen yet;
- **the two boss fights' feel** (steps 1 and 5);
- **the eye-and-ear list** (step 9), and the new music and level 15's rain loop.

---

## The Phase 5 card (gate build: the enemies, levels 1–5 through the first boss door) — kept as written

Kept as it was written for the Phase 5 gate, with its test build 5 note. Where it says the Warrior stands still or
level 10 and later are closed, the Phase 6A card above replaces it.

### Test build 5 (18 November 2026): the Warrior is now a real boss
This build is the Phase 5 build below plus the first boss fight. Where the card below says the Warrior stands still,
never dies and the gate stays shut, **that is no longer true in this build**:
- **When he dies** the screen shakes and flashes, the gate opens and the music changes.
- **Levels after 5 are still closed.** Choosing one on the map shows "Level n is not built yet (Phase 6)." and returns
  to the map. That message is expected.

**Machine checks re-run on this build's code (18 November 2026):** the visit sweep on levels 1–5, 3,488 visits, 0
problems, through the Windows game path and again through the Mac game path (15 of 15 teleports arrived; 37 of 37 level
exits reached the map); the random-play bot on levels 1–5, 108,000 steps, 0 failures, through each path (16 deaths, 112
level exits, 22 conversations, 1 save); the Windows package's suite, 82 tests, 0 failed (2 skipped by design); the
game's suite, 693 tests, 0 failed (2 skipped by design), and the same suite under CrossOver on 15 November: 690 passed,
0 failed, 3 skipped, 0 crashed. The boot check of this zip is on its download page.

**Status: machine gates green; Ben's and Andrew's gate pending.**

Ferazel's Wand 1.0.3 for Windows: Ambrosia's Ferazel's Wand (2000), rebuilt to run on Windows 10 and 11 (64-bit) from
the original game's own data. Unofficial, non-commercial preservation. It is the same game as the Mac Phase 5 build —
the enemies alive on levels 1 to 4, and level 5 open up to the Warrior's arena — in lockstep with it: the Mac card
(`Ferazel/WHAT-TO-EXPECT.md`, its 12 steps, its stand-ins and its known differences) holds here too.

The question for you: **do levels 1 to 5 play on Windows as they do on the Mac — the enemies by eye, the sound by
ear?**

**Boot results (muted):** done by day on 2026-11-11 (run 50), on a build staged from efeb66f — game code identical to this build. The Mac app booted muted and quit cleanly with no crash report; the Windows zip booted in a clean CrossOver bottle with the main menu, the new game and level 1's text identical to the references; the game's suite under CrossOver: 617 passed, 0 failed, 3 skipped, 0 crashed, of 620; the Mac development build's headless main menu matched its reference

### Starting it
Unzip and start it exactly as in the Phase W card below (Extract All, then "Ferazel's Wand.exe"; SmartScreen: More
info, then Run anyway). Saved games from the Phase W build still open.

**To make New Game start on any level from 1 to 5** (the hidden test switch), open a command prompt in the game's
folder and run (here for level 5):

`"Ferazel's Wand.exe" -FerazelLevel 5`

New Game then goes straight to that level, for that one launch. Any number other than 1 to 5 means level 1.

### The gate card: what to check (a Windows 10/11 PC, or CrossOver)
Play **the same 12 steps as the Mac card** (`Ferazel/WHAT-TO-EXPECT.md`, "The gate card: what to check"): the goblins,
crawlers and roaches, bats, frogs and blobs; getting hurt and hurting them; the Statue spell on an enemy; the shields
(nothing to test yet: no shield can be reached in this build); level 4's boulder spouts; the underwater tint; level 5
up to the Warrior's arena; and the things you may only feel.
On Windows, Shift / Alt / Ctrl act as the Mac's Shift / Option / ⌘, and Esc leaves level 5's locked arena (abort).

**Note anything that differs from the Mac** — a picture, a sound, a timing, a dialog. In the first Phase 5 build the
Warrior stood still and never died, no spell, weapon or the Ring of Smiting harmed it, and the gate stayed shut (test
build 5 replaces this: see the top of this card). Before the arena locks, walking back right leaves level 5 through its own exit to the map
(0 of 1 enemies on the stage-complete panel), and a save point can be reached before the lock. Level 10 and later
can't be reached in normal play (only an original saved game from a later level would show "not built yet").

### Machine checks run for this card
- **Visit sweep** (every object on every level, taken to and drawn) on levels 1–5, through the Windows game path:
  3,488 visits, 0 problems (15 of 15 teleports arrived; 37 of 37 level exits reached the map), 10 November 2026; through
  the Mac game path: 3,488 visits, 0 problems (15 of 15 teleports arrived; 37 of 37 level exits reached the map), 10
  November 2026
- **Random-play bot** (random keys, several runs of a few minutes per level) on levels 1–5, through the Windows game
  path: 5 levels, 4 runs each, 108,000 steps in all (14 deaths, 106 level exits, 22 conversations, 1 save), 0 failures,
  10 November 2026; through the Mac game path: 5 levels, 4 runs each, 108,000 steps in all (14 deaths, 106 level exits,
  22 conversations, 1 save), 0 failures, 10 November 2026
- **The test suites**, including the Windows package's own and the game's suite run under CrossOver: the game's suite
  620 tests, 0 failed (2 skipped by design: the sweep and the bot, run on their own above); the Windows package's suite
  82 tests, 0 failed (the same 2 skipped by design); the data census 1,108 items decoded, 0 failures; the Mac app and
  the Windows game both build. The game's suite under CrossOver (a launch check, run by day on 2026-11-11): 617 passed, 0 failed, 3 skipped, 0 crashed, of 620

### Known stand-ins on Windows (Phase 5)
- **The table's row "Every Mac stand-in of Phase 4" now reads:** every Mac stand-in of Phase 5 — the Warrior, level 10
  and later, the enemies first placed after level 5, the other bosses and the later levels' drawing features —
  replaced in Phase 6, in lockstep with the Mac. Every other row of the Phase W card's stand-ins table below still holds.

### What to tell me
Your answer goes in `docs/QUESTIONS.md` under the Phase 5 gate item (the Windows part): yes or no to "do levels 1 to 5
play on Windows as they do on the Mac?", then anything that felt, sounded or looked different, by the Mac card's step
number if you can.

---

## The Phase W card (gate build: the Phase 4 game on Windows) — kept as written

Kept as it was written for the Phase W gate, as history. Where it says the enemies stand still or level 5 is refused,
the Phase 5 card above replaces it; its starting steps, small differences and stand-ins table still hold. Its boot
results and the test counts in "On this Mac first" are October's: this build's are in the Phase 5 card's machine checks.

**Status: machine gates green; Ben's and Andrew's gate pending.**

Ferazel's Wand 1.0.3 for Windows: Ambrosia's Ferazel's Wand (1997), rebuilt to run on Windows 10 and 11 (64-bit) from
the original game's own data. Unofficial, non-commercial preservation. It is the same game as the Mac Phase 4 build —
levels 1 to 4, the spells and items, enemies that stand still — in lockstep with it: the Mac card
(`Ferazel/WHAT-TO-EXPECT.md`) and its list of stand-ins hold here too.

The question for you: **does the Windows build behave like the Mac build — sound by ear, dialogs by eye?**

**Boot results (loop run 35, 2026-10-27, by day, all muted):** the Mac staged app started and quit cleanly with no crash
report; the staged Windows zip, in a clean CrossOver bottle, drew the main menu, level 1's first frame and level 1 at
full brightness with its status-bar text exactly as the Mac development build does; the game's own test suite run under
CrossOver: 489 passed, 0 failed, 1 skipped (the CrossOver-only skip), 0 crashed.

Nobody has heard it yet: every run the loop made was muted, and in CrossOver on this Mac, never on a real PC.

### Starting it
1. Unzip "Ferazel's Wand (Windows).zip" anywhere (the Desktop is fine): right-click it, Extract All. Do not run the
   game from inside the zip; it needs the whole folder.
2. Open the folder "Ferazel's Wand (Windows)" and double-click **Ferazel's Wand.exe**. Keep the "Data" folder and the
   .dll files next to it.
3. Windows will probably say **"Windows protected your PC"** (this build is not code-signed for Windows). Click
   **More info**, then **Run anyway**. Once is enough.

Your saved games and the settings file live in `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` (paste that into
Explorer's address bar). A log of the last launch, "Ferazel's Wand.log", sits there too; if the game will not start, a
message box says why and the log has the details.

### On this Mac first (optional, daytime; October's numbers, kept as history) — for Ben on the Mac where it was built;
skip this on a PC
Both scripts force the no-sound driver and refuse to run between 21:00 and 09:00.
1. `tools/windows/proof-b-ferazel.sh` → last line `proof-b: 489 passed / 0 failed / 1 skipped / 0 crashed (of 490)`
   (the one skip is a test that cannot run under CrossOver; about 5 minutes).
2. `tools/windows/smoke-ferazel-win.sh` → `main menu: identical`, `new game: identical`, `level 1 text: identical`,
   exit 0 (the staged zip's game, in a clean CrossOver bottle, draws the same pictures as the Mac's development
   build: the main menu, level 1's first frame, and level 1 at full brightness with its status bar text). It needs a
   fresh stage first: `tools/windows/stage-ferazel-win.sh --no-desktop`, which refuses while the checkout has
   uncommitted changes; the smoke refuses a stage made before the latest commit.

### The gate card: what to check (a Windows 10/11 PC, or CrossOver)
3. **First launch** (SmartScreen: More info → Run anyway): logo, title music, main menu — no console window, no error
   box.
4. **Keyboard:** keypad 4 / 6 / 8 / 5 move with Num Lock on **and** off; Shift / Alt / Ctrl act as the Mac's Shift /
   Option / ⌘; Caps Lock pauses; Esc asks to abort; Ctrl+P opens Options (drawn inside the window); Alt+Enter full
   screen and back.
5. **New Game** → level 1 plays as on the Mac: music, effects, the status bar text, a sign's text smoothed like the
   Mac's.
6. **A real save and restore — please do this one.** The Windows Save and Open dialogs have been built but **never
   run anywhere yet** (the loop's runs answer them from a script). At a save point the Windows Save dialog should open
   in `%APPDATA%\Ambrosia Classics\Ferazel's Wand\` with the game's name filled in; save. Then Restore Game (Ctrl+O at
   the main menu, or Continue) should open that file again and the level should resume where you saved. Tell me if
   either dialog fails to appear, opens somewhere odd, or the restored game is wrong.
7. **Options:** remap a key, toggle music (it acts at once), OK; quit and relaunch — the settings held.
8. **A controller** (Xbox / Switch Pro / PlayStation): the Mac's layout (Ferazel/GAMEPAD.md); + pauses, − held one
   second = Esc.
9. **The close button** (new on Windows — the Mac window has none) while a level runs → "Are you sure you want to
   quit?" (Cancel plays on); at the main menu it quits. Log off with the game running: Windows is not held up for
   long.
10. `"Ferazel's Wand.exe" -FerazelLevel 3` from a command prompt in the folder → New Game starts at level 3.

Pass looks like: the Mac build's behaviour on Windows, sound by ear, dialogs by eye. Notes become a named wave.

### Small differences found while building (expected, not bugs)
- **The Open dialog may open in the folder Windows last used** for this program, not the saves folder (Windows
  remembers it). The Save dialog is told the full path, so it should open in the saves folder.
- **The Save dialog shows no message line** (the Mac's panel shows the original's prompt; Windows' dialog has no place
  for it).
- **Dialog text under 14 points is drawn with two levels of smoothing**, like the game's own text; on the Mac the
  dialogs are separate windows with fully smoothed text.
- **The popup menus in Options** (Sound panel) are drawn inside the window in a classic Mac style; the Mac shows a
  system menu.
- **A right-click outside a dialog does not beep** (the Mac beeps on any click outside; here only the left button is
  seen).
- **Esc does nothing on the "Are you sure?" confirm dialog** — as the original (it takes only Return / Enter).
- **Alt+Return cannot be set as a key in Options** — it is Windows' full-screen key here.
- **Ctrl shortcuts follow the US key positions** on other keyboard layouts (e.g. Ctrl+Q is the key where Q sits on a US
  keyboard), and Options shows US key names.

### Known stand-ins on Windows
| | What Windows lacks | Why / who replaces it |
|---|---|---|
| ◇W1 | Options' key names are the US layout's, not your PC's layout | the window library cannot ask Windows for the layout; a later task if wanted |
| ◇W2 | The window is resizable (the game scales in whole steps, on black); the Mac's is fixed | the window library always opens resizable |
| ◇W3 | Windows' own Open / Save dialogs where the original had its 1997 ones | the Mac build does the same with macOS's |
| ◇W4 | No About item (Credits is on the main menu); no menu check marks | there is no menu bar on Windows |
| ◇W5 | Nobody has heard it or run it on a real PC yet; the loop ran it muted in CrossOver only | Ben's ears, Andrew's PC |
| ◇W6 | Every Mac stand-in of Phase 4: enemies stand still, levels 5 and on refused, no underwater tint, the shield crouch | Phases 5–6, in lockstep with the Mac |
| ◇W7 | No installer, no signing, no file association; SmartScreen's "Run anyway" | publishing is Ben's |
| ◇W9 | The Save dialog shows no message line | Windows' dialog has no message area |
| ◇W10 | Dialogs drawn inside the game picture and scaled with it (enlarged 1× text); the Mac's are separate sharp windows | as Bubble Trouble X on Windows |
| ◇W11 | The window has a close button (the Mac's has none); a Windows log-off ends the game without the quit question | nothing is lost: quitting writes nothing |
| ◇W12 | No single-instance guard: a second launch is a second game (the Mac opens the save in the running game) | — |
| ◇W14 | Ctrl shortcut letters are matched by US key position, not the typed letter | the same cause as ◇W1 |

(◇W8 and ◇W13 were not needed: the item counts and the dialog font came out exact.)

### What to tell me
Your answer goes in `docs/QUESTIONS.md` under the Windows gate item: yes or no to "does the Windows build behave like
the Mac build?", then anything that felt, sounded or looked wrong, by card number if you can — and especially how the
save and restore (step 6) went.
