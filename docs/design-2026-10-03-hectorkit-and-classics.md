# Design — HectorKit + Ambrosia Classics, with Aki as the first game (2026-10-03)

Status: **APPROVED by Ben 2026-10-03** ("it looks good"); both the RE-bank and Phase 0 sessions were launched
from it the same day. Supersedes the "rename EVResources → AmbrosiaResources inside the EV repo"
idea from earlier the same day (dropped: it entangled new games with EV's process and open lanes).

## 1. Decision summary

1. **New games do not live in the EV repo.** They get their own repo, `Ambrosia-Classics`, with
   fresh fable-kit docs per game. EV keeps its own lanes, gates and release plan untouched.
2. **The game-independent format layer becomes a package, `HectorKit`** (named for Hector D. Byrd,
   Ambrosia's parrot), its own repo, zero dependencies, lifted from EV code that already imports
   only Foundation. Not called "Ambrosia*": nothing in it is Ambrosia's technology, and not called
   "ClassicMac*": too generic for Ben's taste. The heritage lives in the games repo's name.
3. **EV adopts HectorKit later** via a one-line re-export shim (`EVResources` → `@_exported import
   HectorResources`), so its 111 import sites and the two open PRs (#17, #26) never conflict. Own
   machine-gated PR, after those lanes merge.
4. **Aki first, Bubble Trouble X second.** Aki proves the shell and the kit with the least logic at
   risk; Bubble Trouble inherits both and adds the sprite/cicn decoders plus the FILM replay oracle.

## 2. HectorKit

| module | contents | lifted from (`~/Developer/Ambrosia/engine/EVCore/Sources`) | tests |
|---|---|---|---|
| `HectorResources` | classic resource map (fork or data-fork), BRGR container, container backend, byte reader, MacRoman, `Resource` value | `EVResources/*` — 479 lines, Foundation only | `EVResourcesTests` (688 lines) as-is |
| `HectorGraphics` | `PICT` v2 raster decoder (PackBits 8/4-bit, DirectBits 16/32-bit) + `compressedQuickTimePayload` (JPEG/TIFF in 0x8200); `Ditl` dialog-item-list reader | `EVGraphics/PICT.swift`, `EVGraphics/Ditl.swift` | opcode-level PICT tests move; EV-data census tests stay in EV |
| `HectorAudio` | `snd` resource decoder → PCM | `EVCore/SndSound.swift` (221 lines) | `SndSoundTests`; the codec census stays in EV |
| `HectorShell` | **new**: fixed logical canvas (any WxH) presented in an AppKit window at integer-or-fit scale on Retina; fullscreen toggle; mouse/keys mapped to canvas coords; a per-frame RGBA/`CGImage` present path (Metal or CALayer, decided in the plan); AIFF/MP3 playback via AVFoundation | — | unit tests for coordinate mapping + scale rules; render smoke |

Growth path (on first need, each game-driven): `cicn` colour icons and `PPAT` patterns (Bubble
Trouble), the `TMPL`-described `btSP` sprite reader (Bubble Trouble; TMPL is in its data file),
Ambrosia 2008 framework quirks if any build depends on them.

Rules: no game knowledge in the kit; a decoder is "general" only after a census against ≥2 games'
real data (lesson: EV's PICT decoder covered 6 opcodes until Aki's 70 QuickTime PICTs arrived);
real-data tests read sibling checkouts via env paths and **count** skips, never hide them.

## 3. Ambrosia-Classics

```
Ambrosia-Classics/
  CLAUDE.md  docs/{STATE,DECISIONS,RESUME}.md  docs/<game>/   # RE banks, per game, topical files
  project.yml                 # xcodegen; one app target per game; never hand-edit the pbxproj
  Aki/   Core/ (SwiftPM: AkiCore, depends on HectorKit)   App/ (AppKit shell target)
  BubbleTrouble/ Core/ App/   # later
  Resources/<Game>/           # git-ignored originals: the game folder exactly as shipped
  ghidra/                     # DumpDecompile.java + find_func/read_const scripts; binaries + dumps ignored
  out/<Game>/                 # staged .app for Ben's play gates (ignored)
```

HectorKit is a **local path dependency** during build-out (`../HectorKit`), pinned to a tag only
once a game ships.

## 4. Aki — scope and posture

**Replica target:** Aki — Mahjong Solitaire as shipped. Two originals in hand, and they are
different programs: **1.1.0 (2004)** is Liquid Metal's Carbon C++ build on Matt Slot's toolkit,
PPC-only, art in an 82-PICT resource file; **1.2.0 (2008)** is a **Cocoa/Objective-C rewrite**
(classes `Controller`, `AkiView`, `AkiSplashWindow`, `LevelDescriptionWindowController`), i386+ppc,
art as loose PNGs at the **same native sizes** (800x600 backgrounds, 237x181 previews, strip sheets),
ASW frameworks + Sparkle, 17 levels, plain-text `.aki` custom levels (tile count, then `x y layer`
per line) and a 36-level community pack. Both decompiles are oracles; where they disagree on a rule,
1.1.0 is the game Ben remembers and 1.2.0 is the last word — bank the delta and let Ben arbitrate.

In scope, 100%: splash; map screen with the twelve lanterns and progression; level-description
dialogs (text lives in the Carbon nibs); the game screen (144 tiles, open-tile rule, red
highlight, match removal, 2.5-min limit with per-pair bonus, hint/reshuffle/undo with penalties,
grey overtime stones, "no more pairs" state, pause); the four difficulties incl. Practice;
Level Statistics; Preferences (music, sound, tile animation, level description, fullscreen 800x600,
no update check); the **Level Editor** and `.aki` (`LVLE`) custom-level files incl. "Play Custom
Level…", layer buttons, nudge arrows, undo, 144-tile validation; three MP3 themes, AIFF effects,
`tick.mp3`; English + Japanese `.lproj` strings where the data carries them.

Level editors are in scope for every game (whole-game ports) but are the **last phase within each
game**; Ben does not play them (ruling 2026-10-03).

Out of scope, by preservation posture (one-line note, no hedging): the RT3 registration layer
(game behaves as registered), the online version check, "Download Levels…" (dead server; the
add-ons pack is loaded as plain files instead), the Reggie tracker.

**Data loading:** the shipped bundle layout is the format — `Aki - Mahjong Solitaire.rsrc` (82 PICT:
70 QuickTime-JPEG, 12 raw 16/32-bit), the AIFF/MP3 files, the two nibs' strings, `.aki` level
documents. Board layouts 1–12 are **code** in the original (`Layout1..12` = ordered `AddTile(x, y,
layer)` calls); they are transcribed to data tables with the decompile as source and a test that
each table reproduces the exact call sequence and tile count.

**Logic oracle:** `ghidra/Aki_ppc.decompiled.c` (3503 functions, every game function named) and
the 1.2 Intel dump once fetched. Rules oracle: the Aki Handbook. Feel oracle: Ben.

## 4a. Display scaling and upscaling (ruling 2026-10-03, applies to every game in this repo)

No higher-resolution art exists for any of these games (Aki 1.2's PNGs match the 2004 PICT sizes),
so scaling is a shell concern plus an optional offline pass:

1. **HectorShell native mode: integer scaling, crisp pixels** — the faithful default (800x600 → 3x =
   2400x1800 on a 5K display, letterboxed). Every original pixel survives.
2. **Fit-to-window with smooth filtering** when the window is not an integer multiple (fullscreen 3.6x).
3. **Optional per-game "HD art" pack**, generated offline (ML upscaler such as Real-ESRGAN for
   photographic backgrounds; xBRZ/hqx pixel-art scaler for glyph/tile strips), loaded through a
   HectorKit asset-overlay lookup that falls back to the original file, behind a preference, **outside
   the replica gate**. Per game, after it plays — but **Ben expects this for every game** ("we will end
   up doing a proper ML upscale for everything", 2026-10-03), so the overlay lookup and a reusable
   offline upscale script belong in HectorKit tooling, planned once, not re-invented per game. Never a
   runtime ML/shader path; the faithful integer-scaled originals remain the default.

## 5. Verification model

Machine gates (every plan's top section):
- HectorKit `swift test` at a recorded zero-skip floor; PICT census: all 82 Aki PICTs decode to
  their declared frame sizes; `snd`/AIFF loaders open every shipped sound.
- Aki core `swift test`: layout tables vs decompile (count + sequence), open-tile rule, match/undo
  state machine, timer arithmetic incl. the three difficulty multipliers and penalties, `.aki`
  round-trip (editor save → loader → identical tile set), stats persistence.
- Boot smoke of the staged `.app` without stealing focus more than once per batch (standing rule).

Honesty gates (Ben only, feel): does it look and play like Aki — splash, map, a full level, the
editor. Unreachable defects are carries, not gates (EV D67 carried over).

## 6. Sequencing (each a plan of its own)

**Parallel lane (own session, ruling 2026-10-03): RE-bank the whole hit list up front** — Aki 1.2
(Intel), Bubble Trouble X (dump exists), Ferazel's Wand (PEF), Deimos Rising (PEF), Cythera (PEF) —
Ben's list exactly, nothing added (pop-pop and Maelstrom were never on it; removed 2026-10-03). Output: `docs/<game>/` topical banks + `INDEX.md` per game, same discipline as
EV's `docs/ghidra/` (confidence-labelled code readings; nothing is behaviour-verified until Ben's
eyes). Trigger in `docs/RESUME.md`.

0. **Kit lift** — create HectorKit from the EV files + tests; green at floor. Fetch Aki 1.2 +
   add-ons; census + Ghidra on the Intel slice; diff vs 1.1.0; bank findings in `docs/aki/`.
1. **Shell + static screens** — HectorShell 800x600 window, splash and map screens from the real
   PICTs, prefs dialog. First staged `.app` for Ben (gate: "that is Aki's map screen").
2. **The game** — tiles, rules, timer, difficulties, hints/shuffle/undo, level flow 1→12, sounds,
   music, stats. Gate: play a level.
3. **Editor + custom levels + add-ons** — `.aki` read/write, editor screen, Play Custom Level.
4. **Bubble Trouble X** — new brainstorm on the same structure; adds cicn/btSP/PPAT to the kit and
   the FILM replay oracle.

## 7. Open questions carried (not blockers)

- Metal vs CALayer present path in HectorShell: decide in the phase-1 plan by measuring.
- Aki's dialogs are Carbon nibs (XML), not DITLs, so Aki reads the nib XML directly; `Ditl` still
  belongs in the kit because Bubble Trouble X carries 42 DITL / 11 DLOG resources.
- Licence for the new repos: decided at the very end, not raised before (EV D65 carried over).
