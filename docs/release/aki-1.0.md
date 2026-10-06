Ambrosia's **Aki — Mahjong Solitaire 1.2.0**, rebuilt natively for today's Macs, with the original game data inside. Download **Aki-1.0.dmg** below.

## Install
1. Open **Aki-1.0.dmg**.
2. Drag **Aki** to **Applications**.
3. Double-click Aki in Applications. It's signed and notarized by Apple: macOS asks once to confirm you want to open an app downloaded from the internet — no "unidentified developer" block.

Needs macOS 15 or later. Universal app (Apple Silicon and Intel); tested on Apple Silicon, macOS 27 — the Intel build and macOS 15/26 are untested.

The About box says 1.2.0 (1.0): 1.2.0 is the version of Aki this rebuilds, 1.0 is this release.

## Remastered Art
Every picture redrawn 4× sharper: smooth backgrounds, grain-free tiles, sharp tile faces. Same game, same timing.
- Turn it on or off with **Aki ▸ Remastered Art** in the menu bar, or **⌘G** (works in fullscreen too, where the menu bar is hidden).
- Or tick **Remastered art** at the bottom of **Aki ▸ Preferences…** (applies on OK).
- It starts off. Off is the original 2008 pixels.

## What's not in 1.0
- The **Level Editor**, custom `.aki` levels, **Play Custom Level** and **Replay**. They're coming; their menu items stay greyed out for now.
- The **Release Notes** window shows its text in Menlo, unless your Mac already has Osaka-Mono installed (Apple's font isn't included).
- If your Mac is set to Japanese, the **Remastered Art** menu item and checkbox are still in English.

## Differences from the 2008 original
- No registration, Check for Updates or Download Levels: it behaves as registered, and those servers are long gone.
- A macOS 26+ style app icon: the original tiles on a green squircle.
- The About box is the standard macOS About panel (with the original credits).
- Fullscreen doesn't switch your display to 800×600; the game is scaled to fill the screen instead.
- The Level Editor isn't in yet (see above).

## iPad
There's an iPad version in the source (the `AkiPad` target). It isn't in this download; build it yourself from the repo (set your own development team in `project.yml` first).

## Where it keeps things
Preferences, unlocked levels and statistics live in the preferences domain `com.ambrosiaclassics.aki`, in the original game's own format. An Aki 1.1 `Aki Prefs` file is picked up on first launch; an Aki 1.2 prefs file isn't read. To start over as a first launch, run `defaults delete com.ambrosiaclassics.aki` in Terminal (and delete `~/Library/Preferences/Aki Prefs` if you have one from Aki 1.1 — it would be imported again).

## Feedback
Something wrong or different from how you remember it? [Open an issue](https://github.com/andiyar/Ambrosia-Classics/issues).

---

<sub><em>Aki — Mahjong Solitaire © Ambrosia Software & its authors. Unofficial, non-commercial preservation, not affiliated with or endorsed by any rights holder.</em></sub>

SHA-256 (Aki-1.0.dmg): `bd12e9d4f15c50ba77af6cb74928e4cb9f4d8cf6fabc75ffee4409ea3d92a6b5`
