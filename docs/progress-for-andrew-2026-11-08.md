# Ferazel's Wand — progress note for Andrew (8 November 2026)

Hi Andrew — a plain-English update on where the Windows rewrite of Ferazel's Wand stands since test build 4, and what
the next build will have. There is no new build to try today; the next one comes at the end of the current phase.

## What has been built since your last test build

**Every enemy on levels 1–4 is now alive.** Test build 4 had the levels drawn and walkable but most enemies were stand-ins.
Since then the enemies have been rebuilt from the original program one class at a time, so they move, attack, take hits
and die the way the 1999 game does:

- goblins of every kind (walkers, axe-throwers, archers and the rest), crawlers, roaches, bats, frogs and blobs on
  levels 1–4;
- enemies that first appear later in the game (salamanders, crabs, gremlins, wraiths, the armoured dillo, geysers and
  the pipes that spawn enemies) are built and machine-tested, ready for when those levels open;
- enemy shots, damage, shields, and the underwater tint.

**Level 5 now opens.** This is the first boss level (the Manditraki Warrior). You can enter it from level 4, walk through
it, and reach the Warrior's arena. When you walk into the arena the camera pans and the walls lock behind you, exactly as
the original does, and the level plays its own music. The sky behind level 5 is the original's moving backdrop, which was
rebuilt this week from the original's drawing code.

**The Warrior himself is not fought yet.** He stands in the arena and hurts you if you touch him, but he has no attacks,
does not throw his rocks, and cannot be killed. The gate out of the arena stays shut. That fight is the next phase's
first job. To leave the arena, use the Escape key or close the window.

## How it is being checked

Two automated players run through every built level on both the Mac and the Windows builds after each step: one visits
every object on every level, the other plays randomly for several minutes per level and fails on any crash, freeze, error
box or picture the game cannot draw. The Windows build also runs its whole test suite inside CrossOver (a Wine-based
Windows layer) after every wave. All of these were green today on levels 1–5. The one thing a machine cannot judge is how
the enemies *feel* — that is what your play on real Windows is for.

## What the next build will have

- Levels 1–5, every enemy on levels 1–4 alive, the Warrior's arena reachable but the fight not yet in.
- Both the Mac and Windows builds staged together with one checklist of things to look at.

The build after that opens the rest of the game in three parts: up to the Goblin Chief, then up to the Wizard, then the
whole game, each with a test build for you.

## Things worth watching for when the build arrives

- Enemies behaving oddly compared with your memory of the original (speed, aim, how many hits they take).
- Anything that looks wrong rather than crashes — the machine checks catch crashes, not wrong pictures. Your teleporter
  find in October was exactly this kind of bug.
- Level 5's moving sky: it should scroll smoothly behind the level with no seams or flicker.
- Saving and restoring on real Windows (restore is still unconfirmed from your side).

Thank you again for the testing so far — the teleporter report and the status-bar colour catch both led straight to fixes.
