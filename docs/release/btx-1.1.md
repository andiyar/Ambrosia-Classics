Ambrosia's **Bubble Trouble X 1.1**, rebuilt natively for today's Macs, with the original game data inside. Download **BubbleTroubleX-1.1.dmg** below.

## Install
1. Open **BubbleTroubleX-1.1.dmg**.
2. Drag **Bubble Trouble X** to **Applications**.
3. Double-click Bubble Trouble X in Applications. It's signed and notarized by Apple: macOS asks once to confirm you want to open an app downloaded from the internet — no "unidentified developer" block.

Needs macOS 15 or later. Universal app (Apple Silicon and Intel); tested on Apple Silicon, macOS 27 — the Intel build and macOS 15/26 are untested.

The About box says 1.1.0 (1.1): 1.1.0 is the version of Bubble Trouble X this rebuilds, 1.1 is this release.

Every picture, sound, level and piece of music comes from the original 1.1 data, unmodified. Every sound effect and each level set's music has been checked against the original game's code.

## New in 1.1: play with a controller
A game controller now works out of the box: a Nintendo Switch Pro Controller, Joy-Cons, an Xbox or a PlayStation pad. The controller simply presses the game's own keys for you, so the game plays exactly as the original. Nothing to set up inside the game.

| What it does | Switch | Xbox | PlayStation |
|---|---|---|---|
| **Move** | d-pad or left stick | d-pad or left stick | d-pad or left stick |
| **Push** | A, B, X or Y | A, B, X or Y | ✕, ○, □ or △ |
| **Pause / un-pause** | **+** | Menu | Options |
| **End the game** (hold 1 second) | **−** | View | Create / Share |
| **Start / OK** (title, scores, dialogs) | any face button or **+** | any face button or Menu | any face button or Options |
| **Cancel** (dialogs) | **−** | View | Create / Share |

Every face button pushes, so it never matters which one is "A". Remapping a key in **Preferences ▸ Keys** remaps the button too. You can't type a high-score name with a controller: a face button accepts the name already in the box, and the keyboard types a new one. The keyboard works exactly as before.

To pair a Switch Pro Controller: open **System Settings ▸ Bluetooth**, hold the small sync button on the controller's top edge until the lights run back and forth, then click **Connect** next to "Pro Controller".

Tested on a Mac with a Switch Pro Controller. The Windows controller support is built and its tests pass, but it hasn't been tried with a real controller on a Windows PC yet.

## What's not in 1.1
- The **BT Level Editor**. In 2008 it was a separate app, not part of the game, and it isn't rebuilt yet. Without it there are no custom levels to play, so custom-level play isn't in either.
- **Registration** and **Check for Updates**: it behaves as registered, and those servers are long gone.

## Differences from the 2008 original
- A macOS 26+ style app icon: the original goldfish on a light tile.
- The About box is the standard macOS About panel (with the original credits).
- Full screen doesn't switch your display to 640×480; the game is scaled to fill the screen instead.
- The dialogs (Preferences, high scores and the rest) are today's Mac controls, laid out where the original put them.
- In the attract-mode demos, demos 2, 3 and 4 end with the hero caught partway through. The demo recordings were made with an earlier version of the game and replay differently under 1.1's rules.

## Windows
The same game for Windows 10/11 (64-bit), cross-compiled from the same Swift code: download **BubbleTroubleX-1.1-Windows.zip** below (37.1 MB).
1. Right-click the zip, **Extract All**, then open the folder and double-click **Bubble Trouble X.exe** (don't run it from inside the zip; keep the Data folder and the .dll files beside it).
2. It isn't code-signed for Windows, so Windows says **"Windows protected your PC"**: click **More info**, then **Run anyway** (once).

The window is just the game (no menu bar); the Mac's ⌘ shortcuts are **Ctrl** (Ctrl+F full screen, Ctrl+M music, Ctrl+Shift+A sound effects, Ctrl+Q quit). Preferences and high scores live in `%APPDATA%\Ambrosia Classics\Bubble Trouble X\`. Played on a real Windows PC to level 20, with sound. `WHAT-TO-EXPECT.txt` in the folder has the rest.

SHA-256 (BubbleTroubleX-1.1-Windows.zip): `cd83afb9c3c65e37f9bc16fb77a0c3b1f1e616d6ddee6d26b55c28499cbe54aa`

## Where it keeps things
Preferences, key sets and high scores live in the preferences domain `com.ambrosiaclassics.bubbletroublex`, in the original game's own format. A Bubble Trouble X 1.1 prefs file (`~/Library/Preferences/Bubble Trouble X Prefs`) is picked up on first launch; it is only read, never changed. As in the original, the high scores from your very first session are reset to the factory table the next time the game starts; after that they stay. To start over as a first launch, run `defaults delete com.ambrosiaclassics.bubbletroublex` in Terminal (and delete `~/Library/Preferences/Bubble Trouble X Prefs` if you have one from the original — it would be imported again).

## Feedback
Something wrong or different from how you remember it? [Open an issue](https://github.com/andiyar/Ambrosia-Classics/issues).

---

<sub><em>Bubble Trouble X © Ambrosia Software & its authors. Unofficial, non-commercial preservation, not affiliated with or endorsed by any rights holder.</em></sub>

SHA-256 (BubbleTroubleX-1.1.dmg): `81c20fa36e8e388531ea97fab7fefa6c8b270c846ed63f03638ee563b3519f97` · size 12.8 MB
