Ambrosia's **Bubble Trouble X 1.1**, rebuilt natively for today's Macs, with the original game data inside. Download **BubbleTroubleX-1.0.dmg** below.

## Install
1. Open **BubbleTroubleX-1.0.dmg**.
2. Drag **Bubble Trouble X** to **Applications**.
3. Double-click Bubble Trouble X in Applications. It's signed and notarized by Apple: macOS asks once to confirm you want to open an app downloaded from the internet — no "unidentified developer" block.

Needs macOS 15 or later. Universal app (Apple Silicon and Intel); tested on Apple Silicon, macOS 27 — the Intel build and macOS 15/26 are untested.

The About box says 1.1.0 (1.0): 1.1.0 is the version of Bubble Trouble X this rebuilds, 1.0 is this release.

Every picture, sound, level and piece of music comes from the original 1.1 data, unmodified. Every sound effect and each level set's music has been checked against the original game's code.

## What's not in 1.0
- The **BT Level Editor**. In 2008 it was a separate app, not part of the game, and it isn't rebuilt yet. Without it there are no custom levels to play, so custom-level play isn't in either.
- **Registration** and **Check for Updates**: it behaves as registered, and those servers are long gone.

## Differences from the 2008 original
- A macOS 26+ style app icon: the original goldfish on a light tile.
- The About box is the standard macOS About panel (with the original credits).
- Full screen doesn't switch your display to 640×480; the game is scaled to fill the screen instead.
- The dialogs (Preferences, high scores and the rest) are today's Mac controls, laid out where the original put them.
- In the attract-mode demos, demos 2, 3 and 4 end with the hero caught partway through. The demo recordings were made with an earlier version of the game and replay differently under 1.1's rules.

## Windows
There's also a Windows 10/11 (64-bit) test build, cross-compiled from the same Swift code: [Bubble Trouble X for Windows — test build 1](https://github.com/andiyar/Ambrosia-Classics/releases/tag/btx-windows-test-1). It stays a test build for now: it isn't signed, so Windows asks before running it.

## Where it keeps things
Preferences, key sets and high scores live in the preferences domain `com.ambrosiaclassics.bubbletroublex`, in the original game's own format. A Bubble Trouble X 1.1 prefs file (`~/Library/Preferences/Bubble Trouble X Prefs`) is picked up on first launch; it is only read, never changed. As in the original, the high scores from your very first session are reset to the factory table the next time the game starts; after that they stay. To start over as a first launch, run `defaults delete com.ambrosiaclassics.bubbletroublex` in Terminal (and delete `~/Library/Preferences/Bubble Trouble X Prefs` if you have one from the original — it would be imported again).

## Feedback
Something wrong or different from how you remember it? [Open an issue](https://github.com/andiyar/Ambrosia-Classics/issues).

---

<sub><em>Bubble Trouble X © Ambrosia Software & its authors. Unofficial, non-commercial preservation, not affiliated with or endorsed by any rights holder.</em></sub>

SHA-256 (BubbleTroubleX-1.0.dmg): `8eb541c7dfd2ff2025a27dd9f24cfcec8fbc5dec651274e6231f1f07e5d5c2b3` · size 12.6 MB
