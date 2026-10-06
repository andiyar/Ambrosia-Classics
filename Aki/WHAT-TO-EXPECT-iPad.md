# Aki on iPad — what to expect (first iPad build, 2026-10-04)

The same Aki — Mahjong Solitaire 1.2.0 replica as on the Mac, running on your iPad mini. Every picture, sound,
string and dialog still comes from the original files. The game itself is the Mac build's game; only the
host around it is new, shaped by your rulings (D7).

## First launch
- If iPadOS says **"Untrusted Developer"**: Settings ▸ General ▸ VPN & Device Management ▸ tap the developer
  entry ▸ Trust. Then open Aki again.
- **Developer Mode** must be on (Settings ▸ Privacy & Security ▸ Developer Mode). If it is off, iPadOS will ask
  you to turn it on and restart.

## What is different on the iPad (your rulings)
- **The picture:** the original 800×600 screen scaled to fill the height (about 2.5× on the mini, smoothed), with black bars at the left and right. On a 4:3 iPad (13" Pro) it fills the whole screen.
- **Give Up = the X** at the top left, in the black bar on the left. It only shows during a game, and asks
  "Are you sure…?" as the Mac's Give Up does.
- **No on-screen Undo.** Undo is ⌘Z on a hardware keyboard, or Edit in the menu bar — on Easy and Practice only,
  exactly as the original.
- **Menus** are the iPadOS menu bar: swipe down from the top of the screen, or hold ⌘ on a hardware keyboard to
  see the shortcuts. Same menus as the Mac, from the original menu file.
- **Lanterns:** tap a lantern once to preview it (the hover look and its sound); tap the same lantern again to
  enter. Tapping another lantern moves the preview.
- **Quit** is drawn on the map but does nothing (iPad apps don't quit themselves).
- **Sound** obeys the silent switch, and starting Aki stops other music playing on the iPad.

## The question for you
**Play a level start to finish on Hard, Medium, Easy and Practice — does it play like Aki?** Plain yes or no.
Pick the difficulty with the arrows under Skill Level on the map, then tap a lantern twice.
- **Hard / Medium:** match pairs until you win, or let the clock run out once. No Undo anywhere.
- **Easy:** try ⌘Z (or the menu bar) — it takes back the last pair for 12 s.
- **Practice:** the stones never run down; winning does not light the next lantern.

## Look at along the way
- **The match fade:** a matched pair should fade away, about a third of a second, like on the Mac.
- **The X:** in a game it gives up (after "Are you sure…?"); on the map it is not there.
- **Tap-preview:** first tap previews, second enters; a tap elsewhere doesn't enter by accident.
- **Picture:** fills the height, black bars only at the sides, nothing of the game cut off.
- **Dialogs:** the iPad has no Aqua, so Aki's dialogs (Give Up, no more pairs, Level Statistics, Preferences)
  are drawn to look close to the Mac's. Do they read right?
- Tip, Reshuffle and Pause on screen; ⌘T / ⌘R / ⌘P on a keyboard.
- Switch to another app mid-level: the game pauses; coming back resumes it.

## Remastered Art (new, D11)
- Every picture redrawn 4× sharper (AI-upscaled); layout, timing and rules unchanged. Smooth (de-dithered)
  backgrounds; the tile body is a plain smooth enlargement (no added grain) under the AI-upscaled pictures.
- With a keyboard: **⌘G**, or **Aki ▸ Remastered Art** in the menu bar (check mark = on). Without one: the **Remastered
  art** checkbox at the bottom of Preferences (Preferences on the map's bottom bar), applied on OK.
- A fresh install starts in Original. It switches live, on the map or mid-level.
- Greyed out = this build has no Remaster art in it.

## Known differences (deliberate or iPad-only)
- No key auto-repeat on a hardware keyboard.
- About, Release Notes and the Handbook open as sheets over the game.
- The iPadOS window controls (the small dots at the top) are the system's, not Aki's.
- Everything listed under "Known differences" in the Mac WHAT-TO-EXPECT still applies (no registration,
  Level Editor / Custom Level / Replay still to come).
