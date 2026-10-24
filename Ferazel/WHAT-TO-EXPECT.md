# Ferazel's Wand — what to expect (Phase 3 gate build: title → level 2 and back)

**Status: machine gates green; Ben's gate pending.**

This build of our Ferazel's Wand 1.0.3 replica is **the whole game around the levels.** It starts like the original:
the Ambrosia logo and title music, the loading bar, the main menu. From there you can start a New Game, play level 1,
save at a save point, pause, finish the level, see the stage-complete panel, walk the world map to level 2, die and
get the death screen, abort back to the menu, and resume your saved game later. Options, Credits and the menu bar work
where the original's did. A game controller now works too. Every picture, sound and dialog still comes from the
original game files, unchanged.

The question for you: **does the trip from the title screen to level 2 and back feel like the original?** Play it
side by side with your Let's Play (https://www.youtube.com/watch?v=ESuyxMUEzDw) and the longplays.

## What this build is, and what it is not
- **It is** the title and loading screens, the main menu and its five buttons, Options (with key setup), Credits, New
  Game with the chapter card, the conversations and signs, the save points and saved-game files, the pause, the
  "abort?" and "quit?" questions, the stage-complete panel, the world map, the death screen, Resume, the menu bar, and
  controller support. Phase 2's movement and Phase 1's look are unchanged underneath.
- **It is not** the rest of the game yet. Only levels 1 and 2 can be entered. Enemies stand still and do no harm
  (Phase 5). Coins, potions, chests, doors and teleporters can't be picked up or used, and the item bar at the bottom
  always shows the starting items (Phase 4). Crates and the boulder can't be pushed (Phase 4).

## Opening it
- Double-click `Ferazel's Wand.app` on your Desktop. It opens on the title screen, then the main menu.
- If macOS says it can't check the app: right-click it, choose Open, then Open again.
- The window is the game's 640×480 screen scaled ×3 if that whole window (title bar included) fits your screen's free
  area, menu bar and Dock left out; else ×2 if that fits; else ×1. ⌃⌘F gives full screen.
- This is a Release build, so it holds the original's speed (about 30 frames a second).
- **Your saved games and the game's settings file** live in `~/Library/Application Support/Ambrosia Classics/Ferazel's
  Wand/`. To start completely fresh, quit and delete that folder.
- **To make New Game start on level 2** (a hidden test switch), quit the game, open Terminal and paste:

  `cd ~/Desktop && open -n "Ferazel's Wand.app" --args -FerazelLevel 2`

  The game still opens on the title and menu; New Game then goes straight to level 2. That counts for that one launch.
  To make it stick, paste `defaults write com.ambrosiaclassics.ferazel FerazelLevel 2` instead, and
  `defaults delete com.ambrosiaclassics.ferazel FerazelLevel` to go back. Any number other than 1 or 2 means level 1.
- The hidden picture settings below also live in the `com.ambrosiaclassics.ferazel` preferences domain.

## Keys (the original's defaults; change them in Options ▸ Controls)
- **keypad 4 / 6** — walk left / right. **Shift** — run. **keypad 8** — up. **keypad 5** — down.
- **Option** — jump. **⌘** — use an item. **keypad 7 / 9** — previous / next item (nothing to choose from yet).
- **Caps Lock** — pause: the game is paused while the Caps Lock light is on.
- **Esc** or **⌘W** in a level — "Are you sure you want to abort this game?". **⌘Q** — "Are you sure you want to
  quit?". **⌘P** — Options. These are read by the game itself, as in the original, so they don't act during a fade.
- At the main menu the letters act: **N** New Game, **O** or **R** Resume, **I** or **P** Options, **C** Credits,
  **Q** Quit, and **X** for a joke. ⌘ with those letters does the same thing.
- **⌃⌘F** — full screen on and off.

## The gate card: what to check

Each line says what the build does, read from the original's code. **MED** = fairly sure. Unmarked lines are read
straight from the code.

1. **Title.** Black, then the Ambrosia logo fades in with the title music and stays while the game loads; then the
   loading screen, whose 3-D progress bar at the bottom left fills; then a fade to the main menu. No timed wait and no
   skip, as in the original.
2. **Main menu.** Five picture buttons light up while you press them (click and hold; slide off and back on), with
   their click sounds. The letter keys above do the same. **X** shows the "Coming soon" joke. In full screen, moving
   the mouse to the very top shows the menu bar.
3. **Options (I).** Three panels from the popup: Game Options, Controls, and Sound & Music.
   - Controls: click a key box, then press a key. A key already in use is refused with a message; Up and Jump may
     share a key. The **A** key is always refused as "already used" — the original does that too.
   - Sound & Music: the volume popups (1–9) act at once.
   - "Default Settings" on Game Options seems to do nothing until you press Cancel. That is the original's bug, kept.
   - Your settings survive a relaunch.
4. **Credits (C).** The scrolling credits window. Click inside it to close it; a click outside beeps.
5. **New Game (N).** The loading panel appears and its bar fills; the screen goes dark and the level's music fades
   up over about 1½ seconds. Then the chapter card fades in slowly (any key skips it; otherwise it waits about 20
   seconds) and fades out, and level 1 fades in. The chapter card shows only on a level's first visit.
6. **Talk.** Geroditus on level 1 talks to you: the text types at about 30 letters a second. Signs read themselves
   the first time you touch them, and again when you press keypad 8 at them. Esc ends a conversation. The merchant
   (Rojinko) on level 1 offers potions. Buying needs coins, and coins can't be picked up until Phase 4, so you likely
   can't buy anything yet; anything you do buy won't show in the item bar until Phase 4.
7. **Save point.** Level 1 has two: a pedestal with a green check about 3½ screens right of the start, and another
   about 8 screens right. Stand on one for about half a second and macOS's own save window opens (see the deviations
   below), suggesting "Ferazel Saved Game". Save → a white flash, and the pedestal turns into a stone statue facing
   your way; it won't fire again. Cancel → the pedestal stays usable, and fires again after about 2 more seconds of
   standing on it.
8. **Pause (Caps Lock).** The pause banner, a sound, and the music fades out. File ▸ Abort Game, Quit and
   Preferences… work here, as do Music and Sound Effects. In full screen the menu bar appears; in a window it is
   always there, and its items wake up only now. Caps Lock off → the game resumes after a moment and the music fades
   back in.
9. **Finishing level 1.** The stage-complete panel unfolds and three bars fill (enemies, Xichrons, secrets) with a
   ticking sound and a chime per bar, then a fade. Enemies can't die until Phase 5, so expect a low first bar.
10. **World map.** It fades in with its own music. The new path to the next place flashes in random colours and your
    marker walks there by itself. The arrow keys or the keypad move you along open paths only. Return, Enter, Option
    or ⌘ enters the level. The bar at the bottom shows the level's name. Esc or ⌘W asks to abort, ⌘Q asks to quit.
11. **Level 2.** It starts like level 1, but with no chapter card (level 2 has none). Its two exits open new places on
    the map; choosing one shows a stand-in message, "Level 3 is not built yet (Phases 4-6)." (or 4), and leaves you on
    the map.
12. **"…and back".** Esc or ⌘W in a level → "Are you sure you want to abort this game?" → OK → the main menu with its
    music. The question has no Cancel on Esc (the original's dialog has no cancel key), so click Cancel to carry on.
    ⌘Q in a level asks "Are you sure you want to quit?" first. File ▸ Quit from the pause or Q at the main menu quits
    without asking, as the original.
13. **Resume (O).** Pick your saved game in macOS's open window: level 1 at the save point, the statue still there, no
    chapter card. Double-clicking a saved game in Finder opens it the same way at the main menu; during a game it waits
    until that game ends.
14. **Death.** Die (stay under water, or wade into the acid pool at the far right end of level 1, almost 10 screens
    right of the start). You see the dying animation and the border wipe. Then:
    - if you saved or resumed a saved game since New Game: the death screen with Continue and Abort. Continue (or
      Return) → the wand glows and you're back at your last save. Abort (or Esc) → the screen turns gray, then black,
      then back to the main menu.
    - if you haven't: straight back to the main menu. The original has no death screen then.
15. **Controller (new).** A Switch Pro Controller, Joy-Cons, an Xbox or a PlayStation pad works with no setup. It
    simply presses the original's keys, so the game plays exactly the same. Buttons go by position, so the Switch's and
    Xbox's swapped labels don't matter. Pairing steps are in `Ferazel/GAMEPAD.md`.

    | where | d-pad or left stick | bottom / right button | left button | top button | L / R | ZL / ZR | + | − |
    |---|---|---|---|---|---|---|---|---|
    | in a level | walk, up, down | jump | run | use item | previous / next item | run | pause / unpause | held 1 s: the abort question |
    | paused | — | — | — | — | — | — | unpause | — |
    | main menu | — | New Game | — | — | — | — | New Game | — |
    | world map, death screen | arrow keys | Return | Return | Return | — | — | Return | held 1 s: Esc |
    | conversation | moves the choice | Return | Return | Return | — | — | Return | Esc at once |
    | everything else | arrow keys | Return | Return | Return | — | — | Return | Esc at once |

    - In a level the pad follows the keys set in Options, so remapping a key there remaps the button too.
    - **What it can't do:** there is no pointer, so Continue, Options and Credits on the main menu, the Options window
      and the save/open windows need the mouse or keyboard.
    - The abort question's OK is on a face button; to carry on, click Cancel (− can't cancel it, as Esc can't).
    - Pass looks like: **a kid can play levels 1 and 2 with only the pad, and a stray tap of − never aborts.**
16. **Things you can't see but may feel (MED).** All read from the code but not provable on screen:
    - fade speeds (the original's timings, rounded to 60ths of a second);
    - on the map, holding ⌘ alone enters the level (it is also the use key), so ⌘Q there only works if Q goes down at
      the same moment — the original's quirk;
    - the stage-complete panel's stretched rows;
    - the logo's colours at boot;
    - the conversation and dialog text drawn with macOS's Times, not the 1997 bitmap font.

## Still true from Phases 1 and 2
- **The feel card from Phase 2** still describes the movement: walking, jumping, spins, walls, water, platforms,
  cannons, passages. Nothing there has changed.
- **Colours** go through the exact nearest-colour search (your ruling, 2026-10-10). The duplicate-black tie-break is
  **highest**. To look at **lowest**, quit and paste
  `defaults write com.ambrosiaclassics.ferazel ColorTieBreak lowest`, then open the game again;
  `defaults delete com.ambrosiaclassics.ferazel ColorTieBreak` goes back.
- **The hidden Mac gamma switch**, off by default. The picture looks a little darker than your Let's Play because the
  original ran on a classic Mac screen (gamma 1.8) and modern screens use 2.2. To see it as a classic Mac showed it,
  quit and paste `defaults write com.ambrosiaclassics.ferazel MacGamma -bool true` (or launch with
  `--args -MacGamma YES` for one run), then open the game again; `defaults delete com.ambrosiaclassics.ferazel MacGamma`
  turns it off.
- **Item lights** twinkle, but all in step (**MED**: the original starts each at a random point). The torch flicker
  isn't built yet.
- **The black border** around the play view is the original's own screen picture, not a bug.
- **Every run is different.** Random numbers start from the clock at launch, as the original's did.

## Known stand-ins and differences
- **Only levels 1 and 2 can be entered.** The map opens and draws every place as the original; choosing level 3 or
  beyond shows a stand-in message (the only text in the game we wrote ourselves).
- **The item bar** always shows the starting items, whatever you own (Phase 4). Potions bought don't show (Phase 4).
- **Enemies** stand still and do no harm (Phase 5). **Pickups, chests, doors and teleporters** are only solid
  (Phase 4). **Crates and the boulder** can't be pushed (Phase 4).
- **Save and open windows** are macOS's own, not the 1997 ones; the original's prompt text is carried into them.
- **Saved games** are written so they survive zip, git and Windows. An original 1997 saved game opens here, but a save
  made here won't open in the original game on a classic Mac.
- **The settings file** lives in Application Support (above), not the classic System Folder.
- **The menu bar.** In a window the macOS menu bar stays visible; its items are greyed out during play and work only at
  the main menu and in the pause, where the original listened. In full screen it stays hidden, as the original: it shows during the
  pause, and at the main menu when the mouse is at the very top.
- **Quitting from the Dock or at logout during a level waits** until you pause or get back to the main menu; then the
  game quits. That is the original's behaviour (it only listened for "quit" there); macOS may report that the game
  cancelled the logout. QUESTIONS asks whether you want that kept (Q5).
- **The "set system volume" option** is remembered but never changes your Mac's volume.
- **Fonts:** the game ships no bitmap fonts, so Times comes from macOS.
- **No screen switching, no CD check, no installer check, no birthday dialog, no InputSprocket.**

## What to tell me
A pass looks like: you go from the title to level 2 and back to the menu, save and resume, die and continue, pause
and abort, and it all feels like the original, and the kids can play with the pad.

Your answer goes in `docs/QUESTIONS.md`, under the Phase 3 gate item: a plain yes or no to "does the trip from the
title screen to level 2 and back feel like the original?", then anything that felt or looked wrong, by card number if
you can.
