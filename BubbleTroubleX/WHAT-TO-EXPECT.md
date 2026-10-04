# Bubble Trouble X — first playable build (M1)

Double-click **Bubble Trouble X.app**. It opens a 640×480 window and goes straight into a new game at
level 1 — there is no splash, title screen, menus, demo or high-score screen yet (they come next). When a
game ends (lives gone, or Esc), a new game starts at level 1.

## Keys (the original's default key set)
- **← → ↑ ↓** move, **Space** push
- **Caps Lock** pauses while it is engaged (as the original: it reads the lock state); release it to go on
- **Esc** ends the game (a new one starts)
- **⌘Q** quits: in play the music fades out first, as the original did; quitting while playing does
  not save prefs, quitting while paused does — again as the original

## What this build is — and is not — yet
- **No sound or music yet.** The sound mixer is waiting on a HectorKit fix (this Mac's CoreAudio was hung
  when it was built); every sound cue is already routed, so sound arrives without changing the game.
- **The play screen may draw little or nothing yet** (background, sprites, score bar, notices): the step that
  records the original's drawing calls is still in review. The game itself runs underneath — keys, timing,
  levels, lives and the time-bonus count-down are live.
- The mouse pointer hides and is captured while you play (as the original did); pausing shows it.
- Prefs and the level-select high-water mark are saved at every level start, under
  `com.ambrosiaclassics.bubbletroublex`.

- Info-box and FPS text is drawn antialiased, as OS X's QuickDraw smoothed text of 9 pt and up in 2008 —
  tell us if it looks too soft or too crisp next to your memory.

## What to tell us (once drawing and sound are in)
- Do the arrow keys + Space feel right (push, turning around mid-cell)? Is the speed the original's (≈ 30 fps)?
- Are the sounds the right ones at the right moments, and the music right per level set?
