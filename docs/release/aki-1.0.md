Ambrosia's **Aki — Mahjong Solitaire 1.2.0**, rebuilt natively for today's Macs, with the original game data inside. Download **Aki-1.0.dmg** below.

## Install
1. Open **Aki-1.0.dmg**.
2. Drag **Aki** to **Applications**.
3. Double-click Aki in Applications. It's signed and notarized, so it opens with no warnings.

Needs macOS 15 or later. <!-- ARCH -->

## Remastered Art
Every picture redrawn 4× sharper: smooth backgrounds, grain-free tiles, sharp tile faces. Same game, same timing.
- Turn it on or off with **Aki ▸ Remastered Art** in the menu bar, or **⌘G** (works in fullscreen too, where the menu bar is hidden).
- Or tick **Remastered art** at the bottom of **Aki ▸ Preferences…** (applies on OK).
- It starts off. Off is the original 2008 pixels.

## What's not in 1.0
- The **Level Editor**, custom `.aki` levels, **Play Custom Level** and **Replay**. They're coming; their menu items stay greyed out for now.
- The **Release Notes** window shows its text in Menlo, not Osaka-Mono (Apple's font isn't included).
- If your Mac is set to Japanese, the **Remastered Art** menu item and checkbox are still in English.
- No registration, Check for Updates or Download Levels: it behaves as registered, and those servers are long gone.

## iPad
There's an iPad version in the source (the `AkiPad` target). It isn't in this download; build it yourself from the repo.

## Where it keeps things
Preferences, unlocked levels and statistics live in the preferences domain `com.ambrosiaclassics.aki`, in the original game's own format. An Aki 1.1 `Aki Prefs` file is picked up on first launch; an Aki 1.2 prefs file isn't read. To start over as a first launch, run `defaults delete com.ambrosiaclassics.aki` in Terminal.

## Feedback
Something wrong or different from how you remember it? [Open an issue](https://github.com/andiyar/Ambrosia-Classics/issues).

---

<sub><em>Aki — Mahjong Solitaire © Ambrosia Software & its authors. Unofficial, non-commercial preservation, not affiliated with or endorsed by any rights holder.</em></sub>

SHA-256: <!-- SHA256 -->
