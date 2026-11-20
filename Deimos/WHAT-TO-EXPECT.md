# Deimos Rising — what to expect (Phase 4 gate build: the front end)

*Built 2026-11-21 from local main. **This one app serves three gates.** Gate 4 (the front end) is new and comes
first. Gates 2 ("does level 1 play like Deimos") and 3 ("does the campaign play like Deimos") you have not judged
yet: their cards are kept further down, trimmed only where the front end made them untrue.*

# Gate 4 — cold start → game → scores → quit

Phase 4 puts the original's screens around the game: the start-up with its two logos and loading screen, the main
menu, the level select, the high scores and name entry, the demos and your last game's replay, the credits, the
settings window and the controls window, the controller, and quitting with everything saved. Until now the app opened
straight into a game; now it starts as 1.0.6 does. Nothing in this build is a stand-in any more: the Phase 3
build's stand-ins are all replaced (listed in the gates 2 and 3 part below).

LAUNCH STATUS: nobody has launched this app yet, not even a muted check. Your first launch is its first launch ever.

So faults that only show on a real launch are expected, and they are not your fault: a click landing in the wrong
place, full screen misbehaving, a screen that hangs. Note what you saw and where; that is exactly what this gate is for.

## What to try

Each step: what you should see or hear, then what "wrong" would look like.

1. **Starting up.** Double-click the app.
   - **The very first launch** (no settings file yet) **opens full screen**: a new settings file has Full Screen
     ticked, as the original's did. The settings window comes first, with its Cancel button greyed out; click Save.
     Then the publisher's logo with its sound (it stays until the sound ends), the developer's logo as the menu music
     starts, then the loading screen, where the names of several hundred units flash past, then the menu.
   - **To play in a window instead:** press Control-Command-F to leave full screen now. To open in a window every
     time, untick "Full Screen" in the settings window (PREFERENCES on the menu) and Save; that takes effect from the
     next launch.
   - **Every later launch:** the same, without the settings window. The loading screen shows four lines (images,
     sounds, weapons, players); in each, that kind's names flash past before it reads "Done". The unit names, the long
     part, are left out, so it starts sooner.
   - Hold **Option** while it opens: the settings window comes first, again with Cancel greyed out. Hold **Command**:
     the original's quiet start, with no logo sound and no menu music at first.
   - Wrong: a game starting by itself; silence; a logo cut short; the publisher's logo never going away; unit names on
     a later launch.
2. **The menu.** Buttons light up and click under the mouse: 1 PLAYER, 2 PLAYER, PREFERENCES, SCORES, DEMOS, QUIT.
   Keys do the same jobs, each with a click and a short flash of its button:

   | Key | Does |
   |---|---|
   | 1, N or Return | 1 PLAYER |
   | 2 | 2 PLAYER |
   | P | PREFERENCES |
   | H or S | SCORES |
   | D | DEMOS |
   | F | replay your last game (the click sound; it has no button to flash) |
   | Q | QUIT |

   The menu's two volume keys are not − and =. They are the typed letters ù (quieter) and ä (louder); on a US
   keyboard that is Option-` then U, and Option-U then A (not yet tried on a real keyboard). They change the stored
   sound volume by a tenth, with no click and no flash, and, like the game's own volume keys, you should hear no
   difference. Which keys made those letters on a 2004 Mac is not known.

   The bottom line changes from the copyright line to "THIS COPY IS REGISTERED TO AMBROSIA CLASSICS" after four
   seconds; a click or a key starts that clock again. The website line lights up and does nothing. Wrong: anything
   starting by itself if you leave the menu alone; a button lighting up away from the mouse; a click that misses.
3. **Level select** (1 PLAYER or 2 PLAYER). Three previews: the sector before, the chosen one, the one after,
   wrapping 12 to 1. Left and right move with a sound. START under a sector you have reached, NO ACCESS under one you
   have not. The fire or select keys, or a click on the middle preview, accept it (Return does not): a green flash and
   zoom, a fade to black, the game. On a NO ACCESS sector: a red flash and "Sector Not Reached". Esc goes back to the
   menu. Caps Lock pauses; paused, Command-Q quits at once. Wrong: no outline under the mouse; START on a sector you
   never reached; Return starting a game.
   - On a fresh install only sector 1 is open. The level select opens sectors up to one below the best one you
     reached in a game **begun at sector 1** (all twelve after the finale). **Any console cheat** (life, shields,
     score, funds, mult or accuracy) marks that game as cheated, and a cheated game opens no sectors and makes no high
     score.
4. **Coming back.** After game over, Esc or the finale: black, the background, the high-score table if you earned a
   place, then the menu fades back in with its music. Type your name (a blinking cursor; the longest name is in the
   table below). An empty name becomes "Jar Jar Must Die", a joke from the original. In a two-player game where
   both place, player 1 types first, then player 2. A game begun above sector 1 gives no high score. Wrong: the menu
   coming back silent; your score missing from the table; a name you typed changed.

   | Name entry | Characters |
   |---|---|
   | the longest name you can type | 20 |
   | the original's longest joke name (decision 25) | 23 |
5. **Demos and your last game.** DEMOS (or D) plays the four demo films in turn, one per press, 1 to 4 and round
   again; the menu music plays on underneath. A click or Esc ends a film; other keys do nothing; Caps Lock does not
   pause it. F replays your last game, even after you quit and reopen. Wrong: a demo starting by itself; a key other
   than Esc ending a film.
6. **Credits:** "About Deimos Rising…" in the app menu, page by page, about a minute in all, ten pages ending on the
   testers. A click leaves (with a click sound), N starts a one-player game, any other key leaves. In the middle of a
   game "About" does nothing. Wrong: a blank page at the end; credits opening over a running game.
7. **Settings.** The PREFERENCES button (or Option held at launch) opens the settings window, drawn by the game in the
   classic grey Mac look. Its "Set Controls…" button opens the controls window: a Player 1 / Player 2 tab and seven
   key boxes; click a box and press the key you want. Save keeps it; Cancel forgets it. Try changing a key for each
   player and play with it. Wrong: a box taking a key that the other player already uses (it should beep and refuse);
   a key change that does not stick.
8. **A controller.** See the "Controller" part below and the controller guide, `Deimos Rising — GAMEPAD.md`, beside
   the app on your Desktop.
9. **Quitting, and opening again.**
   - On the menu: QUIT, Q, Command-Q, the app menu's Quit or the window's close button. Each saves and quits.
   - In the middle of a game: Command-Q does nothing (your answer: as the original). Pause with Caps Lock, then
     Command-Q quits at once. It saves your settings and the high-score table as it stood, but **the game you were
     in the middle of earns no high score and opens no new sector**. That is what the OS X original does; say if you
     want it otherwise.
   - Paused on the level select, Command-Q also quits at once.
   - Open the game again: your high scores, best sector, both players' keys, the volume and the settings are still
     there, and F still replays your last game.
   - Wrong: anything forgotten after a quit; a quit from the pause going through the high-score screen.
10. **Not certain, and only you can judge:** how every screen looks against your memory (no picture of the original's
    screens exists anywhere); the feel of the fades and waits; the look of the two settings windows; anything where
    the OS X build you played differs from the OS 9 build the research read. More in "What only your eyes can prove".

## Your answers, as built

| Question | Your answer | What the game does now |
|---|---|---|
| Compare the OS 9 and OS X builds over the whole game? | "Yes, after Phase 4" | Not started; it comes after this gate |
| Whose name does "this copy is registered to …" show? | "AMBROSIA CLASSICS" | The menu's bottom line shows THIS COPY IS REGISTERED TO AMBROSIA CLASSICS |
| The website line on the menu | "Light up, do nothing" | It lights under the mouse; a click does nothing |
| Command-Q in the middle of a game | "Ignore it, as the original" (this overturned the plan's "quit at once") | In play nothing happens; on the menu and the level select it quits (see the last two rows for the pause and for macOS's own quit) |
| The controller's buttons; one controller or two; the original's gamepad windows; 2 PLAYER from the pad | "yes to the design. we may need to work on button mapping" | Bottom = fire air, left = fire ground, top and right = select; one controller, player 1; the original's gamepad windows not built; 2 PLAYER needs the keyboard or the mouse. The buttons sit in one small table, so a remap is a one-line change |
| How the two settings windows look | "Classic grey Mac look" | Drawn by the game in grey, with plain sliders, centred on the game's 640×480 picture |
| Loading screen: every unit name, or only the lines? | "Every name, as the original" — then replaced by your later answer (four rows down) | See below |
| The "erase all scores?" question and the two alerts for missing or damaged game data | "Normal macOS alert" | All three are normal macOS alerts |
| Who builds the "erase high scores?" question | "The app-wiring section" | Built: hold Option and click SCORES (mouse only, left Option only; the H and S keys never ask). "Erase" resets the table and both players' names, then the scores show |
| When should the `-players` and `-sector` launch switches go? | "Delete at app-wiring" | Deleted. Two players = 2 PLAYER; a later sector = the level select |
| Unit names on every launch, or the first only? | "First launch only" | On the very first launch (no settings file yet) the names flash past; afterwards four lines and a quicker start |
| Command-Q while the game is paused | "Quit from the pause" | Paused with Caps Lock, Command-Q quits at once. It saves your settings and the high-score table as it stood; the game you were in the middle of earns no high score and opens no new sector (as the OS X original; yours to overturn). A Command-Q pressed during play is not remembered for a later pause. A demo cannot be paused, so in a demo Command-Q does nothing. The level select's own Caps Lock pause also quits at once (decision 20) |
| macOS asking the game to quit (Dock, log out, shut down) on a screen that is not the menu | "Remember it, quit at the menu" | Remembered; the game quits, saving, as soon as the menu is next up. One exception: during a Caps Lock pause it quits at once, as Command-Q does there |

## Decisions made for you — say if any is wrong

**Everywhere**
1. Where the OS 9 and OS X builds differ, the game follows the OS X build, the one you played.
2. It is the registered game: no REGISTER button, no advertisement screen, no cut-off for unregistered copies.
3. The menu's fades follow the OS X build, which runs them twice as quick as the OS 9 build. Starting a game from
   the menu has about one second of dead time.
4. The settings file keeps the original's layout and scrambling. It is read at start-up, written once when first
   made, and otherwise **only when you quit** — so a crash loses that session's scores and settings.
5. A settings file that is too short but has the right version is accepted; the missing part reads as zeros, as in
   the original. An existing file that cannot be read is never overwritten. A failed write gives no message.
6. The two settings windows are drawn by the game itself, not by macOS controls, so the Windows version can reuse them.

**Starting up**
7. The original lists the unit names only when its units cache file is missing. The replica keeps no such file, so
   "first launch" means "no settings file yet". Delete the settings file to see the names again.
8. The publisher's logo stays until its sound ends, with no time limit, as the original. With no sound (or with the
   `-mute` switch) the original's own timed hold is used instead. How long the whole start-up takes is the
   replica's own timing; only its lower limit comes from the original.
9. The settings window's text is Apple's own Geneva 9 bitmap font (your 2026-10-25 ruling allows Apple's classic
   fonts). The OS X build set no special font there and so used the system's; Geneva 9 goes with the classic grey
   look you chose.
10. The settings window's "Full Screen (Takes Effect on Relaunch)" works as the OS X build: ticked, the next launch
    is full screen; unticked, a 640×480 window. If full screen cannot be entered, the window still opens.

**The menu**
11. The menu's volume keys are the original's: the letters ù and ä, not the game's − and = (see step 2). They make no
    click sound and no flash (read from both builds).
12. The QUIT button leaves at once; Q, Command-Q, the menu bar's Quit and macOS's own quit flash QUIT for a moment
    first.
13. No hover sounds in the strip at the top of the screen where the menu bar sits, taken as the OS X menu bar's
    height (not certain).
14. Keys you type during the fades on the way back to the menu are dropped when no score made the table; the
    original's menu would read them afterwards.
15. The pointer appears or hides a moment early: on the way back it shows with the menu's fade-in, and around the
    level select before its fades; the original does each just after.

**Level select**
16. The right-hand preview **does** show its outline under the mouse. The plan said it never did; the original's
    code says it does, and all three previews show it.
17. Only the sector's name is drawn under the previews, no description text: the original draws the name only.
18. START / NO ACCESS changes one frame after you move, as the original.
19. During the green accept flash the edges of the name and number brighten, as the original. The flash's last step
    is never shown, as the original.
20. Command-Q, the menu bar's Quit or macOS's quit on the level select are taken, but act only when you leave: Esc
    back to the menu quits; pausing with Caps Lock leaves as Esc does, then quits; choosing a sector still starts the
    level, as the OS X build does. **Paused on the level select, Command-Q quits at once**, as it does in a game's
    pause; until this build it waited until you released Caps Lock. That is the seat's choice, so that both pauses
    act alike under your answer.
21. Console cheats typed on the level select act on an empty game of its own, not on your last game.
22. A game begun above sector 1 has one life, no finale, saves no best sector and makes no high score: the
    original's rules.

**Coming back, high scores and name entry**
23. Esc out of a game still goes to the high-score table, as the original.
24. Two quirks of the original's table in a two-player game are copied: if player 2 places above player 1 in a
    different row, the row just below player 1's is lost and the next row is listed twice; if both scores fall
    between the same two rows, player 1 is listed first even when lower. A tie ranks below the older score.
25. The original's joke names are kept, including the over-long one (see the table in step 4) that spills "00" into
    the next row and sets player 2's remembered name to "00". Three rare cases of it differ: where the original would
    crash or spill further, the replica does something defined; after a relaunch such a name reads back cut to the
    longest length you can type.
26. Accented letters count toward a name's length but are drawn invisibly, as the original's character table. Only
    keys that change the name hide the cursor. A character the settings file cannot store is saved as "?".
27. The scores screen drops keys you typed after the one that left it; the original passed them to the next screen.
28. On the scores, name entry and credits screens the OS X build reads Command-Q as a plain "q" (it closes the screen,
    or types a q in a name). The replica ignores it there.

**Demos and your last game**
29. No demo starts by itself: there is no attract mode in the original. DEMOS / D play demo 1, 2, 3, 4 and round
    again, and the order lasts until you quit. F replays your last game.
30. Your last game is recorded and saved after every game that is not a film, even one you left before your ship
    appeared (its replay then ends at once). F plays the copy in memory, else the one saved on disk; from the next
    launch on, the saved copy replaces the shipped one.
31. The mouse button is read at the start of each step, so a click can end a film one step late.
32. The pointer stays visible during a film, as the OS X build.
33. A demo started with a click makes the menu's bottom line flip at once when you come back, as the original.

**Credits**
34. "About Deimos Rising…" is never greyed out, as the OS X build (the plan said it would be greyed in a game);
    chosen in the middle of a game it does nothing.
35. There are ten pages, not eleven. The plan expected a blank eleventh page; in both builds the last page (the
    testers) simply stays up as long as page nine.
36. Each page can start a hair late:

    | Late by | At most |
    |---|---|
    | one page | a sixtieth of a second |
    | the whole run | about a sixth of a second |
37. A click and N arriving together during a page change start a game, where the original would leave.

**The settings window**
38. Greyed items follow the OS X build: "Bypass System Volume" and the sound slider are greyed; Full Screen stays live.
39. Cancel is greyed out, so cannot be used, when the settings window opens before the start-up: on the very first
    launch and when you hold Option at launch. Defaults resets the settings and both players' keys; Revert stays grey
    until you change something; Cancel puts everything back, keys included.
40. The music level is applied again when you let go of its slider, on Revert and on closing, not on Defaults (OS X).
41. The two sliders' range is the replica's own: the original's slider definitions are missing from the shipped
    file, so they use the same scale as the volume keys, which step by a tenth of it.

    | Each slider | Steps from nothing to full |
    |---|---|
    | sound and music | 100 |
42. "Set Gamepad Controls…" is hidden. The OS X build always shows it (it refused to start without its own gamepad
    layer); the replica's controller needs no setup window.
43. "Set Controls…" opens the game's own controls window, as the OS X build, not Apple's panel.
44. Not built, as uncertain or minor: the button flash when Return or Esc presses a button; a slider thumb snapping
    back when released far from the slider; the window redraws whole while a slider is dragged.

**The controls window**
45. The tab control's look is invented (no picture of it exists): tabs on the left, with the focus ring and
    highlight colours of "Platinum", the grey look of Mac OS 8 and 9.
46. Clicking a box that already has the focus keeps it highlighted; the OS X build shows a text cursor there.
47. A modifier key pressed on its own is remembered for one opening of the window; the OS X build remembers it for
    the whole run, so a modifier held while the window opens binds here and not there.
48. Every key press binds, so Return, Esc, Tab and the arrows become keys and never press Save or Cancel. On their
    own, only the left Control, Shift, Option and Command bind; Caps Lock and the right-hand modifiers never do. A
    key either player already uses is refused with a beep. Keys the original had no name for show "??".
49. A doubt to check from memory: the OS X build may have pulled the focus back to the last box you clicked after
    each key press.
50. The controller is switched off while this window is up, so a pad press can never become a player's key.

**The controller**
51. One controller, player 1; with several connected, all act as player 1. Player 2 uses the keyboard.
52. Plus pauses the level select too, as Caps Lock does. Plus does nothing in a demo, as Caps Lock; whether it should
    is unknown.
53. Minus is Esc: held one second in play, at once elsewhere. "Hold Escape" in the settings still applies, so with it
    on a tap of minus does nothing on the level select or in a demo. On the menu minus is Esc, which the menu ignores.
54. A button held from one screen into the next does not fire, and a held button makes no repeats.

**Quitting and switching apps**
55. The window has a close button, which acts as Command-Q. The original's window had none.
56. Every way of quitting saves the settings and the high-score table once. A quit from a Caps Lock pause saves the
    table as it stood: the game you were in the middle of earns no high score and opens no new sector, as the OS X
    original.
57. When macOS asks to log out or shut down, the game answers "not now" and quits by itself once the menu is up;
    macOS may need you to ask again. During a Caps Lock pause, a quit asked by macOS (the Dock, a log-out) quits at
    once instead.
58. In play, a Command-Q is ignored and forgotten: pausing afterwards does not act on it. In a demo Command-Q does
    nothing, because a demo cannot be paused.
59. Leaving the app holds a running game still until you come back. A quit asked of the game by macOS during play
    waits until you return (the original's pause screen on leaving is not built; see the gaps).
60. Coming back from another app shows the held picture at once; the OS X build did not redraw straight away.

Engineering choices with nothing to see: the front end lives in the game's core so Windows gets it too; the joins
between the game's parts only grew; the app decodes the original's pictures and hands them in; the level select runs
on an empty game of its own; the tests stay in the existing groups; the replica stores blank bytes where the original
kept invisible filler in a reset name.

## Known gaps and faults

1. **Fault.** With the "erase all scores?" question up, switch to another app and back, then quit from the menu:
   QUIT can flash before the menu notices you came back, leaving the game thinking it is still in the background.
2. **Not built.** The original's pause screen when you leave the app (effects stop, the Paused sound, the pause
   picture, the pointer shown). The game is only held still. Because of it, a quit asked by macOS during play waits
   until you return, where the original would end the game and quit.
3. **Not built.** The OS X build's "Preferences…" item in the app menu, and its (greyed) Edit menu.
4. **Fault.** After a click on 1 PLAYER or 2 PLAYER, the pressed button stays lit a step or two too long on the way
   back to the menu.
5. **Fault, unchecked.** After a game, the menu's background picture is loaded into a piece of memory still laid out
   for the game's scrolling map, not for a menu screen. No crash or wrong picture was found; it has not been checked
   against the original.
6. **Fault, unchecked.** Some steps between screens draw nothing (a short wait, a hand-over). A key or click that
   arrives at the very moment one of those ends goes to that step instead of reaching the menu.
7. **Fault, small.** A key that types no character still reaches the game as a key press, carrying an empty
   character.
8. **Fault, possible.** Quitting while the game is in the background assumes macOS does not slow the game's clock
   there.
9. **Fault.** A quit asked by macOS during the start-up can play the logo's sound in the background.
10. **Not tested.** An unreadable settings file; choosing a sector after a Quit on the level select.
11. **Faults, small, in the settings windows.** If a press is still being held from a moment before, a new click made
    straight after it, before the window catches up, is ignored; a click dragged off a button and released at once
    still counts; Return and Esc do not check whether the button they press is greyed.
12. **Fault, small.** Switching apps while the menu's music fades out on Quit cuts that wait short.
13. **Fault, hand-made files only.** An empty file named "Last Film[last].film" in the game's folder hides the shipped
    copy and then your last game goes missing.
14. **Not built yet.** The whole-game comparison of the OS 9 and OS X builds (your "yes, after Phase 4").
15. **Not built.** The OS X original shows the mouse pointer while a game is paused with Caps Lock. The replica keeps
    it hidden.

## What only your eyes can prove

- How every screen looks. No picture of the original's screens exists anywhere; the machine's frame checks pin the
  replica's own frames, so they catch change, not error.
- The feel of the fades and waits; the mix of the menu music and the effects; sound out of the speakers.
- Typing a name.
- That the pointer shows over the settings window on the very first launch.
- Clicks landing where you point, at any window size and in full screen; full screen at launch; the erase question's
  alert over full screen.
- A real controller in your hand.
- In the controls window, pressing a key and a modifier (Shift, Option, Command, Control) very close together: the
  replica looks at the modifiers only after that moment's other key presses, where the OS X build looked between
  them, so the wrong one could be bound.
- Esc on a settings window that has a Cancel button: it should press Cancel; no test covers it.
- A quit from the Dock or a log-out while the game is in the background.
- The settings file against one the original wrote (none exists on this Mac or in the archive).
- Anything where the OS X build differs from the OS 9 build beyond the front-end parts that were compared.

## Controller

The full guide is copied beside the app on your Desktop as `Deimos Rising — GAMEPAD.md` (pairing, every button, a
six-step check for you). In short:
- The d-pad or left stick moves; bottom fires the air weapon, left the ground weapon, top or right selects.
- **+** pauses (in play and on the level select); **−** is Esc (hold it a second in play).
- One controller, player 1; outside play any face button is Return, and so is **+** on the menu and the screens
  outside play (except the level select, where it pauses); it is switched off in the controls window.

## Hidden switches

| To do this | Type this in Terminal (quit the game first) |
|---|---|
| start with no sound at all | `open ~/Desktop/"Deimos Rising.app" --args -mute` |
| play a demo film after the start-up, then the menu | `open ~/Desktop/"Deimos Rising.app" --args -film de01` (de01 to de04) |

- `-mute` opens no sound output and takes the original's own no-sound path: no logo sound, a timed logo hold, no
  system beep, and the loading screen's sound line reads "Sound System Not Available" instead of listing the sounds
  (the same number of lines). It is not quite the start-up you would normally see. (A Terminal setting,
  `DEIMOS_MUTE=1`, does the same for anyone launching the game from a script.)
- A mistyped film name shows an alert saying so; when you dismiss it, the app quits.
- The settings file:
  `~/Library/Application Support/Ambrosia Classics/Deimos Rising/Deimos Rising Preferences`
- Your last game:
  `~/Library/Application Support/Ambrosia Classics/Deimos Rising/Local/film/Last Film[last].film`
- **To get a "first launch" again** (the settings window first, then the unit names): quit the game and delete the
  settings file. That also resets your scores, best sector and keys.

---

# Gates 2 and 3 — the Phase 3 build's card (kept; you have not judged these yet)

*This was the card for the Phase 3 build (gate 3, the campaign) with the Phase 2 card (gate 2, level 1) kept inside
it. Both questions are still open, and the game they describe is unchanged. Edited only where the front end made
them untrue: the stand-ins are gone, `-players` and `-sector` no longer exist, Esc and game over go back to the menu,
and keys can now be changed.*

This is the Deimos Rising 1.0.6 replica. Gate 1 settled the look. Gate 2 asks whether level 1 plays. Gate 3 asks
about **the campaign: all twelve sectors, one after another, in one game, through to the finale** — and a two-player
game. Every picture and sound comes from the original game files, unchanged.

Two questions for you, one line each:
- **Part A — does the campaign play like Deimos?**
- **Part B — does level 1 play like Deimos?**

## What the game is
- The whole campaign. A finished level fades to black and the next sector starts in the same game, with your lives,
  score and multiplier carried over. All twelve sectors are there with their enemies, set pieces and weapons. After
  sector 12 — in a game that began at sector 1 — comes the finale. Two players can play together.
- No Windows build yet (Phase 5).
- **Leave it alone and it dies.** With no keys pressed the ship sits in the line of fire. The game runs 30 frames a
  second, and in sector 1 with no input:

  | What happens | About |
  |---|---|
  | the last life is lost | 34 seconds in |
  | the ship is out of the game | 36 seconds in |
  | back to the high scores and the menu | about 40 seconds in |

  That is the original's behaviour, not a bug.

### The stand-ins (◇) of the Phase 3 build are all gone
1. Game over → now the high scores (if you placed) and the menu.
2. Esc → the same way back; Esc still reaches the high-score table, as the original.
3. The end of the campaign → after the finale, the high-score check and the menu (still no credits after the finale
   in 1.0.6).
4. Where a new game starts → the level select.
5. `-players 2` → the 2 PLAYER button (or the 2 key).
6. `-sector N` → the level select, which offers only sectors you have reached. Above sector 1: one life and no
   finale, as before.
7. Level-start music → you now reach a level from the level select, with its music, as in the original; the silent
   first-level start is gone. How the music hands over is for your ears.
8. Demo films from the command line → the DEMOS button and the D key; the menu music plays on under a demo.
   `-film deNN` still works as a hidden switch and returns to the menu.
9. Settings forgotten at quit → now kept in the settings file.
10. The mouse not stopping a demo → a click now ends a demo.

## Opening it
- Double-click `Deimos Rising.app` on your Desktop.
- It was built on this Mac, so it normally opens with a plain double-click. If macOS ever refuses to open it, open
  System Settings → Privacy & Security, scroll down, and click Open Anyway.
- If the window opens but stays black, click it once — the game stops whenever it isn't the front app.
- **In the background.** When the game isn't the front app, or its window is minimised, it stops: its music pauses,
  and any effect already sounding plays to its end. Come back and both carry on.
- The demo films: `de01` is level 1; `de02`, `de03` and `de04` play sector 2 Cydonia Plateau, sector 3 Darius and
  sector 4 Neo Kowloon. A demo ends when it runs out, on Esc, on a click, on level complete or on game over. **Other
  keys do not end it** — as in the original. During a demo Caps Lock does not pause; the `~` console and F6 still
  work.

## Keys
| Key | What it does |
|---|---|
| ↑ ← → ↓ | fly the ship (it speeds up and drifts to a stop) and bank |
| left ⌘ | fire the air weapon: tap, or hold to charge |
| left ⌥ | fire the ground weapon (Plasma Bomb) |
| Space | select the next air weapon the current sector allows (nothing to select in sector 1) |
| Caps Lock | pause while Caps Lock is on (its light lit); if it is already on when a game starts, the game pauses at once |
| F6 | interlacing on and off, with a message |
| `~` | open the console |
| `-` / `=` | the original's volume keys — on Mac OS X they do nothing you can hear (Part B line 9) |
| Esc | leave the game: the high scores (if you placed), then the menu |
| ⌃⌘F | full screen on and off |
| ⌘Q | nothing in play; quits from the Caps Lock pause (that game then makes no high score) and from the menu |

These are player 1's default keys; the controls window (PREFERENCES, then Set Controls…) changes them. Only the
**left** ⌘ and ⌥ keys fire by default. The right-hand ⌘ and ⌥ are different keys to the game.

**Player 2** (2 PLAYER on the menu) uses the original's default keys, all on the number pad and the block above the
arrows:

| Key | What it does |
|---|---|
| keypad 8 / 4 / 6 / 5 | up / left / right / down |
| End | fire the air weapon |
| Forward Delete | fire the ground weapon |
| Page Down | select |

A laptop keyboard has no number pad; change player 2's keys in the controls window (its Player 2 tab).

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
   original's own key table; a controller presses those keys for you.
3. **It's the registered game.** The original's copy-protection checks are not built.
4. **No system volume changes.** The game never touches your Mac's volume; it plays at full level.
5. **Files go in their own places.** The settings file and the "Last Film" recording live in the game's own folder
   under Application Support (see "Hidden switches"), not inside the app. A missing game file shows an alert.
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

## What the machine proved (for gates 2 and 3)

**The demo films.** A demo film is a recording of the original's key presses plus the score it reached. This build's
game rules were fed each shipped film, and the score they reached was compared with the score the original recorded.
If any rule that touches the score were even slightly off — an enemy appearing a row late, a hit missed, the random
numbers drawn in a different order — the scores would drift apart. All four films end on exactly the original's
score:

| Demo | Recorded score | This build |
|---|---|---|
| de01 (level 1, Mariner Valley) | 25,050 | 25,050 |
| de02 (sector 2, Cydonia Plateau) | 116,180 | 116,180 |
| de03 (sector 3, Darius) | 57,520 | 57,520 |
| de04 (sector 4, Neo Kowloon) | 24,670 | 24,670 |

**The level change, what carries over, two players and the finale.** No film covers any of these, so each was
written as tests read line by line from the original's code: 28 tests, all passing.

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
- **Sound out of your speakers.** An offline check of the sound path passed; no one has heard it.

## Part A — the gate-3 card: does the campaign play like Deimos

Open `~/Desktop/Deimos Rising.app`; choose 1 PLAYER and start at Mariner Valley. The console's cheats are there if
you want to get through quickly (`~`, then `supermunki`, then `life`, `shields` and the rest) — but **any cheat
marks that game as cheated: it opens no later sectors in the level select and makes no high score**. Each line: what
you'll see or hear, and what would be wrong.
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
8. **Two players** (2 PLAYER on the menu; see the player 2 keys). Both ships start side by side; steering the same
   way slides the view twice as fast, opposite ways cancel. Player 2's panel sits below player 1's. Questions for
   you: are those the keys you remember? Does player 2 still respond while player 1 holds Command?
9. **Sectors 5–12:** new enemies and set pieces, the Photon Beam, and in sectors 7 and 12 a hospital that costs
   10,000 × your multiplier if you destroy it. No demo film covers these sectors: your eyes are the check. The level
   select reaches a sector once you have got past it in a game begun at sector 1 with no cheats (a game begun above
   sector 1 has one life).
10. **The finale** (sector 12, reached in a game begun at sector 1; a later start has no finale; the life and shield
    cheats will carry you through the twelve sectors, though that game then opens no sectors and makes no high
    score): the "all levels" notice flashes fifteen times with a sound
    each; about ten seconds of explosions; four irises open twice with storms of coins and bonuses until about half
    a minute in; the tallies begin about forty seconds after the notice. If every one of the twelve levels was at
    100 % ground accuracy, a mission bonus follows: ten payments of 100,000. Then the transition sound, black, and the
    way back to the high scores and the menu.
11. **Not yet certain:** the feel of the eight uncovered sectors; the mix during the finale's explosions; player 2's
    real keys on Mac OS X; whether sector 12 should be able to end with the Beamer alive; anything in Part B you
    have not yet ruled on.

**Five choices this build makes that are yours to overturn:**
1. Player 2's keys are the defaults read from the original's settings code. Where Mac OS X 1.0.6 actually took
   player 2's keys from is not yet read.
2. After the finale come the high scores and the menu; no credits screen follows the finale.
3. Every level after the first runs one game step (a thirtieth of a second) later than level 1 does. That is the
   original's own behaviour, copied, not a bug.
4. A build-internal choice with nothing to see: the level start's rules and its drawing are kept in separate places.
5. Two original quirks are copied, not fixed: the multiplier indicator can carry a stale marker into the next
   level, and a player caught dying exactly as the level changes is revived without losing the life.

(The Phase 3 card's sixth choice — `-players 2` and `-sector N` standing in for the menu — is gone with the switches.)

## Part B — the Phase 2 card: does level 1 play like Deimos

*The Phase 2 card. You have not yet ruled on it; every line still applies. Only lines 5, 10 and 13 changed, where
the front end replaced a stand-in.*

Open `~/Desktop/Deimos Rising.app`; choose 1 PLAYER, start Mariner Valley; compare with a longplay. Each line: what
you'll see or hear, and what would be wrong.
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
   invulnerable for 2 s. Game over after the last life → the high scores (if you placed) and the menu.
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
    (`life`, `score`, `funds`, `shields`, `mult`, `accuracy`). **Esc** leaves the game: the high scores, then the menu.
11. **Particles, wrecks and trails:** debris bursts in the unit's colours (each 3 px right/below of centre — a quirk we
    copy), stopped tanks become obstacles, bullet trails on some units.
12. **Not yet certain (MED):** the 24→16 sprite colour cut (gate 1, unchanged), particle colour shades, the "Press
    Caps Lock" notice placement, tally waits, the FPS counter showing 31, the crosshair "locked" frame timing.
13. **Demo replay (fallback check):** DEMOS on the menu plays demo 1 first (or `-film de01`, see "Hidden switches"),
    with the menu music underneath. Machine result: PASS — the demo ends on 25,050, exactly the score the original
    recorded (all four shipped demos match).

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
Three plain answers, yes or no: **"does the front end work like Deimos?"** (gate 4), **"does the campaign play like
Deimos?"** and **"does level 1 play like Deimos?"** — then anything that looked or sounded wrong, by part and line
or step number if you can, and any decision in the gate-4 list you want changed (by its number). Short answers asked
for by name:
- "flip pitch" (Part B line 8) if impacts should be deep and slow;
- whether sector 12 can end with the Beamer alive;
- whether your own overload should kill you while you are invulnerable;
- whether player 2's keys are the ones you remember.
