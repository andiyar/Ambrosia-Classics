# Bubble Trouble X — playable build with the front end

Double-click **Bubble Trouble X.app**. It opens a 640×480 window: the Ambrosia logo, the loading screen with its
progress bar, then the title screen (main menu), as the original did.

## Title screen
- Buttons highlight while the mouse is held on them and act when released inside; keys **N** / Return / Enter
  New Game, **D** Demo, **S** Scores, **P** Prefs, **C** Credits, **Q** Quit, **L** level select.
- Moving the mouse leaves a trail of stars; the box at the bottom cycles its messages every 3 s.
- Leave it alone for 20 s: a demo plays (any key or click ends it); the next 20 s idle shows the scores, then a
  demo again, and so on.
- The pointer is the original's hand cursor (`crsr 200`).
- Known differences: during the logo the original showed the system's watch cursor; macOS offers no such cursor
  to apps, so the arrow shows. The original also carried a spinning cursor it never used; it is not built.
- **Not yet:** the dialogs (level select, Preferences, the high-score name entry, the erase-scores question, the
  poem / quote pictures) — they close at once for now; the Scores and Credits screens are still empty (they
  return straight to the menu). Both come next.

## Keys (the original's default key set)
- **← → ↑ ↓** move, **Space** push
- **Caps Lock** pauses while it is engaged (as the original: it reads the lock state); release it to go on
- **Esc** ends the game (back to the title screen)
- **⌘Q** quits: in play the music fades out first, as the original did; quitting while playing does
  not save prefs, quitting while paused does — again as the original

## Menu bar (transcribed from the original's `main.nib`)
- **Bubble Trouble X**: About (the standard panel with the original credits), Preferences… (greyed until the
  Preferences window lands), Services, Hide, Hide Others, Show All, Quit. No Register / Check for Updates.
- **Edit**: the standard items (for the dialogs' text fields later).
- **Options**: **Full Screen ⌘F** (fills the screen, black border, no resolution switch; remembered across launches),
  **Sound Effects ⇧⌘A**, **Music ⌘M** (both ticked = on; they stick), **Key Sets ▸** (Default, then the
  built-in sets — the choice takes effect at once, even mid-level).
- **Window**: Minimize and Zoom (greyed — the game window has no minimize or zoom box, as the original's),
  Bring All to Front; hold ⌥ for Minimize All / Arrange in Front. ⌘M is Music, not Minimize.
- In play, About, Preferences… and Full Screen are greyed; pausing re-enables Preferences… and Full Screen
  (About stays greyed while paused; after you resume, About is enabled for the rest of that game — the
  original's own quirk: its resume path re-enables About).

## What this build is — and is not — yet
- **No sound or music yet.** The sound mixer is waiting on a HectorKit fix (this Mac's CoreAudio was hung
  when it was built); every sound cue is already routed, so sound arrives without changing the game.
- **The screen is drawn from the original's own art**: maze, bubbles, hero, enemies, bonuses, the score bar
  (lives, score, EXTRA, time bonus, multiplier) and the notices (LEVEL n, GET READY!, HURRY UP!, PAUSED, FIN!).
- The mouse pointer hides and is captured while you play (as the original did); pausing shows it.
- Prefs and the level-select high-water mark are saved at every level start, under
  `com.ambrosiaclassics.bubbletroublex`.

- Info-box and FPS text is drawn antialiased, as OS X's QuickDraw smoothed text of 9 pt and up in 2008 —
  tell us if it looks too soft or too crisp next to your memory.

## What to tell us (once drawing and sound are in)
- Do the arrow keys + Space feel right (push, turning around mid-cell)? Is the speed the original's (≈ 30 fps)?
- Are the sounds the right ones at the right moments, and the music right per level set?
