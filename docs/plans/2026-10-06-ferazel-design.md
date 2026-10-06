# Design — Ferazel's Wand 1.0.3, native Apple Silicon (and Windows) replica — 2026-10-06

> Status: **APPROVED by Ben in the brainstorm of 2026-10-06** (orchestrator: Claude Fable 5.1). His five answers
> are the rulings in §10 (recorded as DECISIONS D25). Everything else here is the seat's design under the standing
> ruling: replicate the original 100 %, no modern affordances, no per-element commissioning questions (CLAUDE.md).
> **Spec:** the RE bank `docs/ferazel/` (INDEX.md provenance + topical table; ~14.7k lines, Fable-reviewed in three
> waves). **This document is the architecture; plans carry contracts, not code** (Ben, 2026-10-03).

## 1. What "done" means (Ben, 2026-10-06)

The whole game, Windows included: all 24 levels, the world map and its unlock rule, chapter screens, save points
and Continue, every enemy and boss, Xichra's lair and the victory screen — on the Mac (HectorShell) **and** on
Windows (the SDL shell Bubble Trouble X proved). Built in gates Ben plays, in his order (§8). Not in scope until
he names them: iPad, a Remaster art mode, a level editor, the Documentation app, resolution switching, the CD check,
InputSprocket configuration, the debug/cheat keys, AppleEvents, movie capture (the bank's "Out of scope" list).

## 2. Oracles and the honesty line

| oracle | what it settles |
|---|---|
| The RE bank (`docs/ferazel/`) | the rules, as **code readings only** — "nothing in this bank is behaviour-verified" (INDEX header). Labels: HIGH = read directly, every constant resolved; MED = one inferred link; LOW = guesswork. |
| The original data (`Resources/Ferazel/`, §4) | every level, sheet, palette, sound, conversation and map — loaded, never re-authored. |
| The decompiles (`ghidra/Ferazel_pef.decompiled.c`, the handlers dump, the raw disasm; git-ignored, recipe in INDEX provenance) | the tie-breaker when a bank sentence and a test disagree. Never edit an expectation to match the code under test. |
| **YouTube longplays + a Let's Play of part one Ben will link** | timing, look, feel. Compressed video: good for "does the water look like that", useless for a palette index. |
| **Ben's eyes and hands** | the only behaviour oracle. Every phase ends with a staged build and a gate card. |

Rule for every label: **HIGH → frame-exact, pinned by a test to the bank's number. MED → built as read, named on the
phase's gate card so Ben looks at it. LOW → the seat picks the documented rule, says so in DECISIONS, and the gate card
says "check this against the video".** Completion claims say "machine gates green; Ben's gate pending", never "plays
like Ferazel", until he says it.

## 3. Architecture — the Bubble Trouble shape, three layers plus a Windows twin

```
HectorKit (generic, no game words)          Classics: Ferazel/Core (SwiftPM package)
┌──────────────────────────────┐            ┌────────────────────────────────────────────────────┐
│ HectorResources  resource maps│◄───────────│ FerazelCore   (Foundation + HectorResources only)   │
│ HectorGraphics   PICT→RGBA,   │            │   formats · sprite system · player · physics ·      │
│   + NEW PICT indexed pixels + │            │   every class handler · camera · particles (state) │
│     embedded ColorTable       │◄──┐        │   · tables (byte arithmetic) · saves · prefs ·      │
│ HectorAudio      snd→PCM, IMA4│   │        │   per-frame FrameOps (what the original drew)       │
│   + AIFFAudio (Deimos K2)     │◄──┼────────│ FerazelRender (Foundation + HectorGraphics/Audio)   │
│ HectorShell      Mac canvas   │   │        │   faces (PICT→indexed→RLE) · tilesets · CLUTs ·     │
│ HectorSDL        Windows      │   │        │   frame/mask ports · blitters · parallax · flame ·  │
└──────────────────────────────┘   │        │   OmniPx · CLUT animation · indexed→RGBA · PCM bank │
                                   │        │ ferazel-census (executable) · FerazelCoreTests ·     │
                                   │        │ FerazelRenderTests (frame goldens)                   │
                                   │        └────────────────────────────────────────────────────┘
                                   │        ┌──────────────────────┐  ┌───────────────────────────┐
                                   └────────│ Ferazel/App (AppKit +│  │ Ferazel/Windows (SDL twin,│
                                            │ HectorShell): window,│  │ Phase 7): same Core+Render│
                                            │ menus/dialogs, keys, │  │ + BTXWinKit-style drawn UI│
                                            │ mixer, music, prefs  │  └───────────────────────────┘
                                            └──────────────────────┘
```

**Layer rules (HectorKit D6, Classics D12):**
- `FerazelCore` imports Foundation and HectorResources only. No pixels, no PCM, no AppKit. It is deterministic and
  value-typed where the original's data is value-like; the sprite pool, the particle pool and the game globals are
  modelled at the original's capacities and slot order (the active-list order rule, platforms-ropes-radial-2 §8, is
  behaviour).
- `FerazelRender` imports FerazelCore, HectorGraphics, HectorAudio. It owns every byte of the 8-bit screen: the
  640×416 ring-buffered frame port and the mask port (rendering-omnipx-titles §1), the 608×384 view copied to (16,8),
  the 640×88 status bar, the lookup-table blitters (draw-effects §1–§2), parallax (rendering-omnipx-titles §1.2–§1.3),
  flame (lighting-tables §9), OmniPx (§3), `.AnimateCLUT` (lighting-tables §1.5), gamma fades (§10). Its output is
  one indexed 640×480 frame plus the current CLUT; a single routine turns that into RGBA for whichever shell.
- The shells (`Ferazel/App`, later `Ferazel/Windows`) only present a finished 640×480 RGBA buffer, play PCM, and
  translate keys and menu/dialog events. They import AppKit/HectorShell or HectorSDL; nothing else does.
- **Seam types are LOCKED once Phase 1 lands** (cases may be added, never renamed): `FrameOps`, `DrawOp`,
  `SoundCue`, `MusicCue`, `InputActions`, `ShellRequest`, `FerazelPrefs`.

**Why this and not the Aki shape** (pixels in the app): Ferazel's screen is palette-index arithmetic through
256-entry and 256×256 tables; it needs headless, golden-tested pixels, and Windows must not carry a second compositor.
**Why not one engine target**: it would put the kit's PICT decoder inside the rules code (D6) and lose the seam the
tests hang off.

### 3.1 What is data-driven from the originals, what is transcribed from the bank

| data-driven (loaded, never re-authored) | transcribed (code written from the bank's readings) |
|---|---|
| `Mlvl` 1..70 (header 0xb29c B + PxBack/PxMid/BG/FG/overlay maps; world-data-format §3), `Mwld 0`, `Mmap 200` (graph + unlock), `Mcnv` 200..401 (conversations-mcnv §2) | the sprite type → class table and every Setup/Handle/Hit/HitTile/Kill routine (coverage.md §1: 141 covered targets) |
| the 584 Sprites / 113 Backgrounds / 67 Titles PICTs, cut into faces with the original loaders' cell arguments (sprites-backgrounds-sounds §2, §3, §5) | the face RLE encoder and the ~60 blitters' semantics (draw-effects §1–§2; the token format §2.2) |
| 79 `clut`s (6 app + 57 Backgrounds + 16 Titles) | `.SetScreenClut`, `.ChangeBlitPortClut`, `.AltClutMod`, `.AnimateCLUT`, the Color2Index model (§6) |
| 172 `snd ` (format 1, 8-bit, 22050/11025 Hz) | the Sound Tool mixer rules: 16 voices, priority displacement, 0x80 unity, positional ears (§6.2–§6.3) |
| 28 AIFC music files `01`..`30` (21, 27 absent — the player falls back to n−1, rendering-omnipx-titles §6.4) | `.SetAIFFMusic` + fades, boss-arena track 30 rule (engine §4) |
| `MBAR`/`MENU`/`DLOG`/`DITL`/`ALRT`/`STR#` from the app's resource fork | menu/dialog behaviour, the Esc dialog (save-continue §6), pause (engine §7.2), prefs record (engine §8), save file (save-continue §3) |
| the lighting/tint/water/redden/pair tables are **computed at run time from the CLUT** exactly as the builders do (lighting-tables §3–§7) — not shipped | the builders themselves |

### 3.2 Time base and frame order

One game step per iteration of `.GameLoop` (engine §4): fixed step, no delta time, **capped at 2 Mac ticks**
(≈30.08 Hz at 60.15 ticks/s); "Reduce frame rate" (prefs[0]) alternates draw/skip with a 4-tick cap. The shell
owns the clock and calls `session.step(keys:)` on that cadence; Core never reads a clock. Front-end sequences that
spin on `TickCount` (fades, the pause loop, chapter screens, the world map) take ticks explicitly, as Bubble
Trouble's D12 item 3 did. The per-frame order is `.PaintFrameWrap`'s: draw (if drawing this iteration) **then**
sprite logic (idle sprites, `MTHandleSprites` in active-list order, collide passes, the player's special pass,
particles), then events/keys, dynamic sounds, `UpdateSprites`, status bar, music/gamma fades. `FrameOps` records the
draw calls at the original's call sites (`RedrawScrollGrid` → lights → water → `WrapDrawSprites` → rain → CLUT step
→ flame → particles → OmniPx → copy to screen with parallax); Render executes them.

### 3.3 Input

The nine actions and their default keys (engine §7.1; keypad 4/6/8/5, Shift, Option, ⌘, keypad 7/9) through the
`GetKeys` path; InputSprocket is not built (bank out-of-scope). Caps Lock = pause, Esc = abort dialog, ⌘Q/⌘W/⌘P as the
original. Key remapping is the original's Options dialog, from its DITL. **Windows:** the BTX precedent (D15/D16/D21)
maps Option→Alt, ⌘→Ctrl; recorded when Phase 7 is planned.

## 4. Data in git

`Resources/Ferazel/` holds the installed game's data files byte-identical to the archive copy at `$FW` (INDEX
provenance), per Ben's standing ruling (memory `feedback-shareware-data-goes-in-git`; Deimos D24 is the precedent and
the `.gitignore` shape: `/Resources/*` + `!/Resources/Ferazel/`, `Resources/Ferazel/** binary`):

| committed | not committed |
|---|---|
| `Ferazel's Wand.rsrc` (the app's resource fork: menus, dialogs, `PICT 7000`, `STR#`, `Tune`, cluts) · `Ferazel's Wand World Data.rsrc` · `… Backgrounds.rsrc` · `… Sprites.rsrc` · `… Sounds.rsrc` · `… Titles.rsrc` · music data forks `01`..`30` (28 files) — about 85 MB, largest file 15.8 MB | the PEF binary (the game itself), `Ferazel's Wand Documentation` (a DOCMaker app), the 28 SoundEdit-leftover `NN.rsrc` forks, `Ferazel's Wand 1.0.3 Notes`, `.DS_Store` |

Tests read the committed data directly (never skip); `FERAZEL_DATA` overrides the folder (D24 item 3 shape). The
staged `.app` and the Windows zip carry the same folder (D10).

## 5. The frame, exactly

Screen 640×480, 8-bit indexed; game view 608×384 at (16,8); status bar 640×88 below (engine §3). Replica canvas is
**640×480 at whole-number scale** (Ben's ruling §10 #4): windowed 2× (3× where the display allows), fullscreen the
largest whole multiple with a black border — HectorShell's crisp path (D3 item 1, D7 R3). The 8-bit frame becomes
RGBA through the **current screen CLUT** on every present (CLUT animation and gamma fades change the CLUT, not the
pixels — lighting-tables §1.5, §10). Graphics modes 1/2/3 and the parallax/effects levels of the prefs record are
honoured as read (rendering-omnipx-titles §1.1 gates).

## 6. The one LOW item: which palette slot a computed colour lands on

Every tint/water/redden/lighting table asks QuickDraw's `Color2Index` for the nearest CLUT entry to a computed RGB
(lighting-tables §1.2). The ROM search is not in the binary. Facts that bound the risk (lighting-tables §1.4, HIGH,
data): every "+ base" level CLUT's entries 0x00..0x9f equal `clut 200`, so **sprite source pixels copy through
exactly**; only the computed table outputs can differ, and their requested RGB is HIGH.

Seat's ruling for the build (to confirm in Phase 0 by measurement, record in D25): **exact match → that entry
(lowest index on ties); otherwise QuickDraw's documented inverse-table rule at the device's default resolution (4
bits per channel), implemented as `ColorSearch` in FerazelRender with both models selectable in tests.** Phase 0's
census prints, per shipped CLUT, how many requested colours the two models disagree on. Ben's gate card for Phase 1
names the tinted surfaces (water, lit areas) to compare against the Let's Play; if they look wrong, the 5-bit and
exact models are one line away. A SheepShaver capture was offered and declined (Ben: video + his eyes).

## 7. Known deviations, disclosed up front

1. **No display switching, no 8-bit screen** — the palette is applied in software (§5). The "Monitor Tool" code and
   `.ResSwitch` are not built.
2. **No CD / installer check, no birthday dialog, no machine hash in prefs** — bank out-of-scope; prefs field kept
   at its default.
3. **InputSprocket not built**; the keyboard path is the one transcribed.
4. **Menu bar:** the original hides it during play and shows it in pause/dialogs; HectorShell does the same thing
   on the Mac. Windows has no menu bar (D21 precedent, re-ruled for Ferazel in Phase 7).
5. **Prefs and saves** live in `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand/` with the original
   record layouts (engine §8, save-continue §3) — the Carbon `Preferences` folder has no modern equivalent. Save files
   are the original's layout so a Finder-opened save still resumes (`.DoOpenDocAE`, coverage §1 PARTIAL).
6. **Mixer output** is the kit's `PCMMixer` through the shell's audio device, voices and volume law as the Sound
   Tool (sprites-backgrounds-sounds §6.2: 16 voices, 0x80 unity — the BTX D14 lesson, don't halve twice).
7. **Music** is the AIFC files decoded by the kit (`AIFFAudio`, Deimos K2) and looped by the mixer, with the
   original's fade arithmetic; QuickTime's own looping seam is not reproduced beyond "play file NN looped".
8. **DEBUG-only** "data missing" alert, compiled out of Release (Aki/BTX precedent). Nothing else the original lacks.

## 8. Phases and gates (Ben's order, 2026-10-06)

| phase | lands | Ben's gate |
|---|---|---|
| **0 Data + decoders** | `Resources/Ferazel/` in git; kit: PICT indexed pixels + embedded ColorTable; AIFC via Deimos K2; `Ferazel/Core` skeleton; parsers for `Mlvl`/`Mwld`/`Mmap`/`Mcnv`/`snd `/clut; face loader + RLE; `ferazel-census` → `docs/ferazel/data-census.md` with 0 failures; the Color2Index measurement (§6) | none (machine-gated) |
| **1 Level 1 look-and-feel** | level 1 "A Scent Of Peril" drawn in `.PaintFrameWrap` order: tiles (FG/BG/overlay/pattern/blend), parallax strip and PxBack, lighting and darkness, water, every placed sprite in its Setup face, the status bar at the start values, the level CLUT; camera follows the keys; Ferazel at the start point, walk cycle on left/right, **no physics**; app target `Ferazel` on HectorShell, staged to `~/Desktop` | "does it look like Ferazel" |
| **2 Ferazel moves** | `.HandlePlayerSprite` in full (player-states, -2), tile collision and `.WallBounce` kinds, liquids, ropes, springs, platforms, hazards, health/breath, landing/splash particles, camera as read | feel on levels 1–2 |
| **3 Front end + saves** | title/menu/options/prefs, world map + unlock, chapter screens, save points, Resume/Continue, death, level complete + stats, conversations, Esc/pause | title → level 2 and back |
| **4 Spells + items** | casting, the spells and player shots, items/inventory/HUD, pickups, boxes (crates, chests, doors, keys, switches, teleporters), held weapon | first levels as the original allows |
| **5 Enemies** | ground, flyers, water/cave classes, enemy shots, damage, particles in full, effects | through the first boss door |
| **6 Bosses** | Warrior, Wizard, Chief, Fire Guardians, Xichra's lair, victory | the whole game |
| **7 Windows + release** | SDL twin (BTX W-plan shape), staged for his brother; then notarized Mac DMG (memory: notarize-kit) | his brother's report; the DMG |

Each phase gets its own plan when its turn comes, written against what landed. **This session's plan covers Phases 0
and 1 only** (`docs/plans/2026-10-06-ferazel-phase1.md`). Orchestrator sessions are sized at 2–3 tasks (fable-kit §5).

## 9. Open bank items and how the build treats them

| item (INDEX "Still genuinely open") | treatment |
|---|---|
| (a) `Color2Index` palette index [LOW] | §6: measured in Phase 0, ruled, on the Phase 1 gate card |
| (b) geysers NR 2–4 (Setup re-run on idle→active; kinds 3/4; inert p4) | Phase 5 builds the as-read rule; gate card names the geyser levels |
| (c) follower slot reuse frequency; enemy drops of items 8/21 | Phase 4/5: code permits it, replica copies it; no data change |
| (d) nil level handle in ContinueGame | not reachable with shipped data; the replica refuses with a dialog (a crash is not behaviour) — Phase 3, recorded |
| (e) intent-only questions (music 21/27, vestigial boss fields, 2940 p1 = 0, as-written oddities) | copied as written, no change |

## 10. Rulings from the brainstorm (→ DECISIONS D25)

1. **Done = the whole game, Windows included** (§1).
2. **First gate = level 1 look-and-feel**, no physics (§8 Phase 1).
3. **Gate order = front end early**: look → movement → front end/saves → spells/items → enemies → bosses → Windows.
4. **Screen = 640×480, whole-number scaling**, black-bordered fullscreen; palette, parallax and tables reproduced as
   computed. Widescreen and smooth-fit rejected.
5. **Feel oracle = YouTube longplays + Ben's Let's Play link for part one + his eyes at each gate**; SheepShaver and
   the demo build declined.
Seat's rulings under the standing 100 % rule (not Ben's; recorded so no session re-asks): the three-layer split
(§3), data in git by the D24 shape (§4), the Color2Index model (§6), the deviations list (§7), phase scoping (§8).

## 11. Risks the plan must carry as hazards

- **Bank line numbers** from wave 1 cite the 64,189-line dump; wave 2 cites raw addresses. Regenerate the dumps with
  `ghidra/regen-ferazel.sh` before trusting a line number (INDEX provenance).
- **Decompiler traps** listed in INDEX "Reviewer notes": `lwzu/stwu` copy loops hide +8; a TOC-load count is not a
  write count; `.StandardSpriteHandles` zeroes per-frame fields so handler reads depend on call order; the signed
  compare idiom.
- **PICT 257** (a PxBack sheet) is 768×708, short by half a row (sprites-backgrounds §3, MED) — the loader must
  tolerate a short last row the way QuickDraw did (undefined pixels → whatever the port held); census must flag it.
- **The frame port is a 640×416 ring buffer** (rendering-omnipx-titles §1.1): the two-call split at `v' − 32 ≥ 1`
  is behaviour; don't "simplify" to one blit.
- **Deimos K2 (`AIFFAudio`) is on a HectorKit branch** at the time of writing; Phase 0 depends on it being on HK main
  or re-does it (one small task, same contract). Check `git -C ~/Developer/HectorKit log` first.
- **D-numbers collide** across parallel sessions (D23 vs D24 did): read DECISIONS on main at merge time and renumber.
