# Aki — what to expect (Phase 1 gate build, 2026-10-04)

This is the Phase 1 build of the Aki — Mahjong Solitaire 1.2.0 replica: splash, map screen, menus,
Preferences, dialogs and fullscreen. The game itself is Phase 2. The app loads every picture, sound,
string and nib from its own bundle under the original file names.

## Opening it
- Double-click `Aki.app`. For about half a second nothing happens, then an 800×600 window "Aki -
  Mahjong Solitaire" appears centred, showing the map with the Fukuyama lantern (level 1) blinking.
- If Music is on (the shipped default), Theme 3 starts at once. First launch also shows the welcome
  splash centred over the window; click it or press a key to dismiss.
- To see the first launch again: `defaults delete com.ambrosiaclassics.aki` in Terminal, then relaunch.

## What to try
- Hover each lantern: the Level Preview frame shows that level's picture and Preview.aiff plays once per
  new lantern. Levels 2–12 show the LOCKED banner over the preview.
- Click a locked lantern: the "Level Unavailable" dialog (parchment, OK). Option-click a locked lantern:
  no dialog, the level opens.
- Click Fukuyama: the guide splash (click to dismiss), then the Level Description window (Fukuyama,
  preview picture, "Display Level Description" box, Continue / Cancel). Continue returns you to the
  map — the level itself is Phase 2.
- The arrows beside Skill Level cycle Hard / Medium / Easy / Practice with a click sound; the pressed
  arrow stays pressed until the next map tick.
- Practice + a locked next level: the Practice alert comes before the description (never on level 12).
- Preferences (the map button or ⌘,): a sheet with the five boxes. Music off stops Theme 3 at OK; Sound
  off silences the preview sound; the settings survive a relaunch.
- ⌘F or the Fullscreen box: fade to black, the canvas fills the screen, fade back. Preferences in
  fullscreen is a modal window, not a sheet. Closing the window quits; switching apps stops the music and
  coming back resumes it.
- Menus from the shipped nib. Help ▸ Aki Handbook opens the PDF in Preview; Help ▸ Release Notes shows the
  notes in Osaka-Mono; About shows the shipped credits.

## Known differences from the 1.2.0 original (deliberate)
- No registration: the replica behaves as registered. "Register Aki…", "Check for Updates…" and
  "Download Levels…" are gone from the menus (the servers are dead).
- Fullscreen does not switch the display to 800×600: the picture fills your screen, pixel-crisp at an
  exact multiple, smoothly scaled otherwise.
- Clicking an unlocked lantern runs the whole pre-level sequence and then stays on the map.
- Preferences live under the replica's own identifier, so an old Aki 1.2 prefs file is not read; an Aki
  1.1 "Aki Prefs" file is migrated.
- The About box is the standard macOS panel with the shipped credits, not the ASW framework window.

## The question for you
**Is that Aki's splash and map screen?** Say yes or no in plain words; everything below is detail.

## Please look at (readings we could not settle from the code alone)
- Q1/Q2 edges of the hover preview, lit lanterns, difficulty word and LOCKED banner (QuickDraw stretch and masks).
- Q3/Q4 fullscreen: smooth fill acceptable, or a crisp letterbox? And the fade feel both ways.
- Q5 the Level Description box starts UNticked. Q13 Practice never alerts on level 12. Q14 the guide on every pick.
- Q6/Q7/Q8 the dialogs: parchment look, placement (they centre on your main display, as the Carbon code did),
  the rebuilt "Level Unavailable".
- Q9/Q52 splash position and its slightly soft look over the crisp map (you said fine).
- Q10 About and Release Notes as standard panels. Q55 Release Notes in the bundled Osaka-Mono.
- Q11 Aki and File menus without the three dead items. Q53 macOS's ⌥ alternates and Window tiling items.
- Q54 "Clear Current Layer" shows no ⌘X (AppKit strips the duplicate; matters in Phase 3).
- Q12 should the replica read the old `com.ambrosiasw.aki` prefs instead of its own?
- Q15/Q18 music volume after Preferences and re-activation; loudness of music versus effects.
- Q16 hover and preview freeze while the Preferences sheet is up. Q17 Lucida Grande 13 in the dialogs.
- Q51 Option-click on a locked lantern bypasses the lock. Q56 always light (Aqua) even in dark mode.
