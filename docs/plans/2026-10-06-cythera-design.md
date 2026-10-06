# Design — Cythera 1.0.4, native Apple Silicon (and Windows) replica — 2026-10-06

> Status: **DRAFT, awaiting Ben's approval** (orchestrator Claude Opus 5.5; brainstorm 2026-10-06). Ben's answers are
> the rulings in §11 (recorded as DECISIONS D28). Everything else here is the seat's design under the standing ruling:
> replicate the original 100 %, no modern affordances, no per-element commissioning questions (CLAUDE.md).
> **Spec:** the RE bank `docs/cythera/` (`INDEX.md` provenance + Files table; three waves, Fable-reviewed; ~13k lines).
> Every bank fact below cites `file.md §N` and keeps the bank's label (HIGH / MED / LOW / NOT RESOLVED).
> **This document is the architecture; plans carry contracts, not code** (Ben, 2026-10-03).

## 1. What "done" means (Ben, 2026-10-06)

The whole game, Mac and Windows: every town, dungeon and level of the scenario, both endings, the start screen,
new character, save/load, preferences, the party-AI strategy editor and its debugger, the cheat/debug keys the code
carries, and the separate **Cythera Documentation** viewer. Mac on HectorShell; Windows on the SDL shell Bubble
Trouble X proved. Built in gates Ben plays, in his order (§9). Out until he names it: registration screens and the
`Register Cythera` app, InputSprocket, CD audio, AppleEvents beyond launch/open, `TSanity`, `Audt`, desktop-comment
copying (the bank's out-of-scope list, INDEX "Out of scope"; Ben ticked cheats and the doc viewer back IN), iPad,
a Remaster art mode, the scenario editor resources.

## 2. Oracles and the honesty line

| oracle | what it settles |
|---|---|
| The RE bank `docs/cythera/` | the rules, as **code readings only** ("nothing here is behaviour-verified", INDEX header). |
| The original data (`Resources/Cythera/`, §4) | every map, prop, script, tile, portrait, sound, tune and dialog — loaded, never re-authored. |
| The decompiles (three git-ignored dumps, 1,994/1,994 functions; INDEX provenance) | tie-breaker when a bank sentence and a test disagree. Never edit an expectation to match the code under test. |
| `scriptdis.py` listings (958 segments, 0 unknown opcodes; script-census.md §2, HIGH mechanical) | the Swift decoder's parity oracle (Phase 0). |
| **The five 1999 screenshots** in the installed folder (Catamarca, Land King Hall, Odemia, Pnyx, Unicorn `.pict`) | real frames from a real Mac: the look oracle for the map, the windows and the frames. |
| **YouTube longplays + Ben's play recall + his eyes at each gate** (Ben, §11 #4) | timing, feel, sound. |

Label rule (Ferazel D26 shape): **HIGH → built exactly and pinned by a test to the bank's number; MED → built as read
and named on the phase's gate card; LOW / NOT RESOLVED → the seat picks the documented rule, records it in DECISIONS,
and the gate card says "check this".** Completion claims say "machine gates green; Ben's gate pending" until he says it.

## 3. The game in one page (what the bank says the replica must be)

- **A multi-window desktop game.** A full-screen backdrop (`TBackdropWind`, pattern or black, clicks do nothing) covers
  the union of all screens and the game's own windows float on it (ui-play.md §6.2, HIGH): the square, growable Map
  window (WIND 129, TBorderWDEF var 4; 128..448 px, odd cell counts 5..15; ui-play.md §5.3, engine-classes.md §5,
  HIGH), the Status panel along the bottom (144 px, widened by `k = (screen width − 640)/3`; ui-play.md §4.1, HIGH),
  one Character window per character (220×272, three panes; ui-play.md §2.1–§2.2, HIGH), script-built containers and
  signs (scripted-windows.md §2, HIGH), the Conversation window (dialogue-ui.md §1–§2, HIGH), the Journal, the To-Do
  drawer, Text/Spellbook picture windows (ui-toolkit.md §1 frame table, HIGH). The menu bar is hidden and appears when
  the pointer reaches the top (app-shell.md §2.2–§2.3, HIGH).
- **8-bit indexed everywhere.** One 256-entry palette (`clut`, `GetCTable(0x100)`), 32×32 tiles, pixel 0 transparent
  (engine-classes.md §5, ui-toolkit.md §0, HIGH). The window frames and controls are drawn from the game's own UI tiles
  0x19C–0x1AF through custom WDEF 1000–1003 / CDEF 1000–1002 classes (ui-toolkit.md §0–§1, HIGH).
- **The data is one segment file.** `Cythera Data` = a `TSegFile`, 34 TOC pages / 1,558 segments, id-keyed XOR on
  script segments, a custom LZ on pixels (data-format.md §1–§2, HIGH). Tiles, portraits, sky, icons, backdrops and
  status art live there, not in PICTs (data-format.md §1.5, HIGH); only the splash, start screen and paper doll are PICTs
  (app-shell.md §1.1/§5.1, ui-play.md §2.2, HIGH).
- **Most of the rules are script.** Native code sends selectors to per-object bytecode (script-vm.md intro, HIGH):
  918 code segments / 424,209 B, 95 builtins, 2,542 builtin calls (script-census.md §1–§4, script-vm.md §6, HIGH).
  Combat arithmetic (selector 28 → 0x301C → 0x3042…), dialogue (127 talk methods), magic (49 spell classes) and trade
  (R0EA5/R0EA9) are bytecode (combat.md §1, dialogue.md §14, magic.md §1–§4, trade-economy.md §3–§5, HIGH). Native:
  movement and pathfinding, schedules and `EvalCondition`, the `.ai` combat-AI language, the clock, rendering, UI,
  save/load (engine-classes.md §2.3, schedules-npcs.md §1–§4, ai-scripts.md §3–§4, HIGH).
- **Turn-driven, drawn at ≤ 10 frames/s.** `MoveAll` runs `DoTick` round-robin until the leader is free for input
  (schedules-npcs.md §4.1, HIGH); the map is drawn by its own thread at most once every F = 6 ticks (engine-classes.md
  §3.4, HIGH arithmetic; "menu 0x88 never inserted" MED). Option-Space (key 0xCA, MED name) toggles real-time mode:
  an idle space turn every 20 ticks (app-shell.md §2.3, HIGH).
- **Three cooperative threads** (Thread Manager + `MyScheduler`): the application thread (events), `TaskThread`
  (game commands from a 16-byte event queue), the map `AnimThread` (app-shell.md §3.1–§3.3, ui-play.md §5.3, HIGH).
  Modal windows are nested event loops (app-shell.md §2.4, HIGH); scripts block mid-routine on `input` 0x8E, prompts
  0x8F, MORE paging, how-many and pick lists (dialogue.md §3–§7, dialogue-ui.md §4–§9, HIGH), and `cbPlaySoundSync`
  waits for its voice to end (script-builtins.md §2.1 D4, HIGH loop / MED end).

## 4. Data in git

`Resources/Cythera/` holds the installed game's files byte-identical to the archive copy (INDEX provenance;
`~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md` row "Cythera 1.0.4", VISE-extracted, CRC-verified), per Ben's standing
ruling (memory `feedback-shareware-data-goes-in-git`; Deimos D24 is the precedent and the `.gitignore` shape:
`!/Resources/Cythera/`, `Resources/Cythera/** binary`). Resource forks are already sibling `.rsrc` files in the
archive (digest of INDEX resource census; `rsrc.py` parses them).

| committed (11,570,723 B — planner probe, phase0 plan) | not committed |
|---|---|
| `Cythera Data` (5,608,688 B) · `Cythera Data.rsrc` · `Cythera.rsrc` (app fork: menus, dialogs, WIND/CNTL, `Lite`, `clut`, `snd `, `STR#`, cursors) · the 8 `*.ai` sources · `AI Scripting Document` (TEXT) · `Cythera Documentation.rsrc` (the doc viewer's content, Phase 8) · the 5 `* screenshot.pict` (oracles) · `Cythera 1.0.4 Notes.text`, `Cythera License.text` | the PEF binary `Cythera` (the game itself; stays in `ghidra/`, git-ignored), `Register Cythera`, 17 InputSprocket drivers + `USBHIDUniversalModule`, the `*.ai.rsrc` editor-state forks (ai-scripts.md §7, HIGH), `Icon_*`, web-link and FAQ files |

Tests read the committed data directly and never skip; `CYTHERA_DATA` overrides the folder (D24 item 3 shape). The
staged `.app` and the Windows zip carry the same folder (D10).

## 5. Architecture — three layers, a Windows twin, a docs viewer

```
HectorKit (generic, no game words)         Classics: Cythera/Core (SwiftPM package)
┌──────────────────────────────┐           ┌───────────────────────────────────────────────────────┐
│ HectorResources  rsrc maps,   │◄──────────│ CytheraCore (Foundation + HectorResources only)        │
│   Pref/STR#/DLOG/DITL/WIND    │           │  segment file · LZ · XOR · maps/props/globals/chars ·  │
│ HectorGraphics   PICT (+pixels│           │  script VM + 95 builtins + THeap · world, clock, stage, │
│   as stored, Ferazel K1)      │◄──┐       │  schedules, pathfinding, combat-AI language · party ·   │
│ HectorAudio      snd → PCM    │   │       │  conversation/interaction state · window-system model · │
│ HectorShell      Mac canvas   │   │       │  saves + prefs (original layouts) · the thread model    │
│   + NEW resizable canvas      │   │       ├───────────────────────────────────────────────────────┤
│ HectorSDL        Windows      │   └───────│ CytheraRender (+ HectorGraphics/HectorAudio)           │
└──────────────────────────────┘           │  tiles/portraits/sky/pix → 8-bit · map Render passes ·  │
                                           │  roofs · light · filters · displacement · transitions · │
                                           │  WDEF/CDEF frames from UI tiles · text · backdrop ·     │
                                           │  the whole desktop → one indexed screen → RGBA ·        │
                                           │  asnd/snd → PCM · mixer rules · QTMA → note events      │
                                           │ cythera-census (exe) · tests · frame goldens            │
                                           └───────────────────────────────────────────────────────┘
        Cythera/App (AppKit + HectorShell + Apple's GM synth)     Cythera/Windows (SDL twin, Phase 8)
        Cythera Documentation (viewer app, Phase 8; Mac + Windows)
```

**Layer rules (HectorKit D6, Classics D12, Ferazel D26):**
- `CytheraCore` imports Foundation and HectorResources only. No pixels, no PCM, no AppKit. It owns every rule, the
  VM, the world, the window-system *model* (which windows exist, their rects, layers, z-order, drag/grow/close, drawer
  state, `ForceOnGDevice`; ui-toolkit.md §1 TWindow row, HIGH code / MED layer names) and the saves.
- `CytheraRender` imports CytheraCore, HectorGraphics, HectorAudio. It owns every byte of the 8-bit screen: the Map
  window's offscreen ((N+1)·32 px square, render.md §1, HIGH), every window frame and control, text, the backdrop, the
  composition of the whole desktop in z-order, and one routine that turns the indexed screen + current palette into
  RGBA for whichever shell. It owns PCM decode, the `TAudio` mixer rules and the QuickTime-music event decoder.
- The shells (`Cythera/App`, later `Cythera/Windows`) present a finished RGBA desktop, play PCM, drive the music
  synth, map mouse/keys to desktop coordinates, show the menu bar and the host's file dialogs. Nothing else imports
  AppKit, AVFoundation or SDL.
- **Seam types are LOCKED once Phase 1 lands** (cases may be added, never renamed): the desktop frame, draw-op and
  sound/music cue types, the input event type (mouse, key, modifiers — the original's `TaskEvent` kinds 1–5,
  app-shell.md §3.2, HIGH), the shell-request type (menu bar show/hide, file dialogs, quit), and the prefs record.

**Why one composited desktop and not real Mac windows:** Ben ruled "like the original" (§11 #3): the game drew its
own frames from its own tiles, and Windows must not need a second window system. **Why not a general Mac Toolbox
emulation:** the bank reads Glenn Andreas' own framework (`TApp`/`TWindow`/`TDroppableWindow`, custom CDEF/WDEF,
engine-classes.md §2.1, HIGH/MED); the replica transcribes that framework's behaviour, not Apple's Window Manager.

### 5.1 The thread model (seat's ruling)

The original's three cooperative threads are reproduced as **real threads that take strict turns** (only one runs at
a time; a hand-off is an explicit yield), scheduled by a transcription of `MyScheduler`'s priority rules (app-shell.md
§3.3, HIGH as code). This keeps every blocking point where the original has it — script `input`/prompts/paging,
`cbPlaySoundSync`, nested modal loops (`MoveableModal`, app-shell.md §2.4), the `TAIDebug` single-step loop
(ai-scripts.md §9.3, HIGH) — without rewriting the VM or the native call graph as state machines. Foundation `Thread`
and semaphores are portable (the Windows Foundation build carries them). Determinism: the hand-off order is the
schedule; tests drive it with a fake clock. **Rejected:** a re-entrant VM with every wait turned into a resumable state
(drift risk across 2,542 builtin call sites and nested native ↔ script calls); Swift `async` (actor hops re-order work).

### 5.2 Time base

The shell owns the clock and feeds ticks (1/60 s) to Core; Core never reads a wall clock. Game time is the bank's
1/4096-hour clock (24 h = 0x18000; engine-classes.md §3.1, HIGH), advanced only by `DoTick`; map frames ≥ F ticks
apart (F = 6, engine-classes.md §3.4, HIGH); screen transitions 5 ticks per step (engine-classes.md §3.4, HIGH);
real-time mode's 20-tick idle turn (app-shell.md §2.3, HIGH). Key auto-repeat is dropped (app-shell.md §2.2, HIGH).

### 5.3 Input

Mouse gestures as `GetGesture` reads them — click = Look, double-click = default command, ±3 px drag = drag-and-drop,
hold or control-click = the Commands popup (ui-play.md §1.1, HIGH; consumer MED); drag targets and reach rules
(ui-play.md §1.2, §2.3–§2.4, §4.4, §5.2, HIGH). Keys: directions → `XDirection` → `MoveCommand`, space = pass a turn,
F1–F10 and ⌘1–⌘0 = macros (ui-play.md §5.3, app-shell.md §2.3, engine-classes.md §3.4, HIGH); dialog key maps from
DLOG title strings, off-by-one included (ui-toolkit.md §3.2, HIGH); list-box keys (ui-toolkit.md §3.1, HIGH).
**Not in the bank:** the full `TMapWindow::KeyRoutine` table and the `CreateWindows` default layout (`@ 10013c04`,
not read) — Phase 1's plan reads both before they are built. **Windows:** ⌘ → Ctrl, Option → Alt (BTX D15/D16/D21
precedent), ruled when Phase 8 is planned.

## 6. The screen, exactly (Ben, §11 #3)

- The replica's "monitor" is the display the game opens on, **one original pixel per macOS point** (crisp 2×2 on
  Retina, 1×1 on a standard display); the backdrop fills it, the windows float on it, the Map window grows in its
  64-px steps, the Status panel widens by `k` as it did on a big 1999 monitor (ui-play.md §4.1, HIGH). Minimum
  640×480 points (WIND 128 "Delver" is 640×480, ui-toolkit.md §1, HIGH; `k` assumes width ≥ 640).
- Opens full screen like the original; a windowed mode treats the window's content as the monitor (Ben accepted this
  in the screen question). One display only (the original's backdrop spanned all screens — deviation §8.9).
- The 8-bit desktop becomes RGBA through the current palette on every present. Gamma fades (startup
  `GammaFadeOut(200)` / `GammaFadeIn(10)`, app-shell.md §1.1/§1.4, HIGH) are applied to the presented image.
- **HectorShell needs a resizable-canvas mode** (today it presents a fixed logical canvas at integer-or-fit scale,
  design-2026-10-03 §2/§4a): canvas = window content size in points, 1:1, re-laid on resize/display change (the
  original's `HandleMonitorChanged`, ui-play.md §6.2, HIGH). Small kit task, Phase 1.

## 7. Sound and music (Ben, §11 #8)

- **Effects:** `'asnd'` segments 0x9100+n (46) and the 13 interface `snd ` resources (converted to the same form),
  big-endian i16 mono, mostly 22,050 Hz (open-items-2026-10-03.md §9, HIGH). Mixer rules as `TAudio`: up to 16 voices
  in priority order (MED), pitch randomised 0.875–1.125 per play, stereo from `CalcStereo(dx,dy)`; ambient emitters
  (330 'B' frame-3 props), positional/sync/ambient builtins D3/D4/D7 (open-items-2026-10-03.md §5/§9, script-builtins.md,
  HIGH/MED as marked). Sound volume 0..8, music 0..3, ambient on/off live from prefs (app-shell.md §7, HIGH). The BTX
  D14 lesson applies: one volume law, applied once.
- **Music:** 11 tunes 0x9000+n are a QuickTime MusicDescription + QTMA tune events, played by the Tune Player via
  `GMSTune`, started by builtin D6 (open-items-2026-10-03.md §9, HIGH layout / MED names; script-census.md §4, HIGH).
  **The events are not decoded (INDEX NOT RESOLVED 9)** — Phase 0 decodes them into note/controller events (the
  QTMA event format is Apple-documented; the census proves every tune parses to its end). **Mac:** played live through
  Apple's built-in General-MIDI synthesizer (the descendant of QuickTime's own instrument set). **Windows:** each tune is
  rendered once on the Mac through the same synth at build time and shipped as audio (§11 #8).
- **CD audio** (builtin F8, 12 script calls; script-builtins.md F8 row, LOW): out of scope; the replica takes the
  original's no-CD path, read and ruled in the phase that reaches it.

## 8. Known deviations, disclosed up front

1. **No monitor picking or depth switch** — always the 8-bit palette in software; `PickAMonitor` and DLOG 140
   ("Switch to 256 Colors" / "Run Slower") are not shown (app-shell.md §1.3 step 12, HIGH).
2. **Registration:** played as registered; no reminder, no `Register Cythera` app (Ben §11 #6). The start-screen
   footer's registered line (app-shell.md §5.1, HIGH) is settled in the Phase 4 plan.
3. **InputSprocket not built**; keyboard + mouse as transcribed.
4. **AppleEvents:** launch behaves as if `'oapp'` arrived (the `HandleCommand` gate opens; app-shell.md §1.4, HIGH);
   opening a save from the Finder is `'odoc'` (Mac). Nothing else.
5. **File dialogs** (Navigation Services `NavGetFile`/`NavPutFile`, app-shell.md §5.3, HIGH) are the host's open/save
   panels — they were the OS's, not the game's. Every game-drawn dialog (DLOG/DITL) is drawn by the replica.
6. **Saves keep the original format** (Ben §11 #7): the data fork is the original sparse `TSegFile` overlay with the
   `'Char'` stream and chunks (data-format.md §7, quests-flags.md §1, HIGH layout); a 1999 save opens in the replica
   and a replica save opens in the original. Type/creator `'DelP'`/`'Delv'` and the resource-fork `'PICT'` preview and
   `'SCEN'` alias (app-shell.md §5.2–§5.3, HIGH) are written on the Mac; the Phase 4 plan rules how much of the fork
   matters for opening and what Windows writes. Prefs keep the named-`'Pref'` resource layout (data-format.md §8,
   HIGH) in `~/Library/Application Support/Ambrosia Classics/Cythera/`, with the scratch `'Temp'` file beside them.
7. **Menu bar:** MBAR 128 (Apple: About Cythera…; File: CMNU 129 — Open Game ⌘O … Quit ⌘Q, app-shell.md §4.1–§4.2,
   HIGH) becomes the Mac's real menu bar, hidden in full screen and shown when the pointer reaches the top, as the
   original did. Windows: ruled in Phase 8 (BTX D21 has no bar; Cythera's commands live there, so it is a real fork).
8. **Text** uses the fonts the code asks for: the game's own `NFNT`/`sfnt` from `Cythera Data.rsrc` decoded by the
   replica; Apple system fonts (Geneva 10, font 3 size 9; ui-toolkit.md §1, ui-play.md §4.3, HIGH) through baked
   glyphs, the BTX precedent (D16.4 → D20, Ben's licence call). The ids/sizes come from the `TxSt` resources
   (ArgosANouveau 14/18/22/24, Geneva 9/10, Seldane 10/12/18) plus literal TextFont 0/1/3 / TextSize 0/9/10 sites
   (Phase 0 planner probe; both shipped NFNTs are one owTable entry short and the app's FOND 128 names a missing NFNT
   — the phase0 plan's bank corrections); the anti-aliased path (`AADrawText`, `TDisableAntiAliasText`) is read in
   Phase 1.
9. **One display**; the original's backdrop spanned all screens with device attribute 13 (ui-play.md §6.2, HIGH).
10. **DEBUG-only** "data missing" alert, compiled out of Release (Aki/BTX precedent). Nothing else the original lacks.

## 9. Phases and gates (Ben's order, §11 #2 and #5)

| phase | lands | Ben's gate |
|---|---|---|
| **0 Data + decoders + census** | `Resources/Cythera/` in git; `Cythera/Core` skeleton; segment file + XOR + LZ; resources; maps/props/globals/CharEntry; tiles/portraits/sky/icons/pix → indexed; `clut`; `Lite`/`FILT`; `'asnd'` + `snd ` → PCM; QTMA → events (closes NR 9); a Swift script decoder at parity with `scriptdis.py`; `cythera-census` → `docs/cythera/data-census.md`, 0 failures | none (machine-gated) |
| **1 Walking Catamarca** | the full desktop: backdrop, Map window drawing a new game's Catamarca in the bank's pass order (render.md §1–§2) with roofs, light for the time of day, people standing in their places; Roster/Status/Text windows drawn; Alaric walks (keys and mouse), roofs lift; HectorShell resizable canvas; app target `Cythera`, staged to `~/Desktop` | "does it look like Cythera" — side by side with the Catamarca screenshot |
| **2 The world runs** | the script VM + builtins + `THeap`; clock, day/night, schedules, NPC movement, pathfinding, doors and object scripts, eggs/spawns, sounds, ambient, music | walk around Catamarca across a day |
| **3 Talk** | Conversation window and modes, keyword chips, prompts, MORE, barks, Journal, To-Do, books/signs/scripted windows | talk to the town |
| **4 Start + saves** | splash, start screen, credits, Create Player, Open/Save/Save As/Backup/Revert, Preferences window, quit flow | new game → save → quit → resume |
| **5 Items + shops** | Character windows (panes, paper doll, slots), containers, drag-and-drop, give, take/drop/throw, weight, shops and haggling, services, training, theft | a shopping trip |
| **6 Fights + magic** | combat (selector 28 chain), status, death, XP; spells, runes, alchemy, missiles/FX; party AI tactics + `.ai` strategies, the strategy editor and `TAIDebug`; the cheat keys | first dungeon |
| **7 The whole story** | every remaining scripted window and teleport/transition, both endings | play it through |
| **8 Windows + docs viewer + release** | SDL twin (BTX W-plan shape), music rendered for Windows; the Cythera Documentation viewer (a DOCMaker app, creator `Dk@P` — its format read first); notarized Mac DMG (notarize-kit) | his brother's report; the DMG |

Each phase gets its own plan when its turn comes, written against what landed. **This session's plan covers Phase 0
only** (`docs/plans/2026-10-06-cythera-phase0.md`). Orchestrator sessions are sized at 2–3 plan tasks (fable-kit §5).

## 10. Open bank items and how the build treats them

| item | treatment |
|---|---|
| THood insertion order within a pass (NR 16 residue; render.md §6, NOT RESOLVED) | Phase 1 builds the as-read list walk (last-to-first); `AddToHood`/`MoveHood` read in Phase 1's plan; on the gate card |
| QTMA music events (NR 9) | decoded in Phase 0 (§7) |
| Over-encumbrance effect (NR 15, none found, MED) | copied as read: no effect beyond the capacity checks (combat.md §14) |
| 0x03/0x05 data words, 0x0210 "Return" (NR 2, 3) | data only; carried as bytes by the VM, no special meaning built |
| N2: 0C80 serves by bits 6/7 (MED intent) | bytecode — runs as shipped |
| Render: post-light hook, `CalcLighting`/`DimOffLevel`/`InteractProps` bodies unread, marker tile 0x186, the 0xC0 SetStage/Render disagreement (render.md §5, §7) | Phase 1's plan reads them; the 0xC0 disagreement is copied (it is behaviour) |
| UI: status command-button refcons, MENU 200 "Party" inserter, MDEF 128 user (ui-play.md §10, app-shell.md §9, ui-toolkit.md §1) | read by the phase that builds each window |
| All-ally cheat needs prefs byte 3 bit 0, which nothing writes (schedules-npcs.md §6.4, data-format.md §8.2, HIGH) | built exactly: reachable only as in the original (the bit also skips the splash wait) |

## 11. Rulings from the brainstorm (→ DECISIONS D28)

1. **Done = the whole game, Mac + Windows** (§1).
2. **First gate = walking Catamarca**: the full desktop, the Map window drawing a new game's Catamarca exactly,
   Alaric walking, roofs lifting; no talk, no scripts (§9 Phase 1).
3. **Screen = like the original**: backdrop fills the screen, the game's windows float on it, drawn by the replica,
   one original pixel per point; windowed mode treats the window as the monitor (§6). Rejected: a fixed 1999 monitor
   scaled by whole numbers; real macOS windows over the desktop.
4. **Feel oracle = longplays + Ben's memory + his eyes at each gate**, the 1999 screenshots for the look; the bank is
   the logic oracle. Rejected: running the original in an emulator.
5. **Gate order = world → talk → saves → items → fights**, then the whole story, then Windows (§9). Rejected: front end
   first; fights early.
6. **Extras IN: the cheat/debug keys and the Documentation viewer.** Out: registration screens, InputSprocket.
7. **Saves = the original format** both ways (§8.6).
8. **Music = Apple's General-MIDI synth live on the Mac; recorded once from it for Windows** (§7). Rejected: a bundled
   SoundFont on Windows; deciding later.
9. **Process (Ben):** the Phase 0 plan is written by a Fable agent directly from this design, with no separate review
   pass ("seems token silly" to have Opus write and Fable review).

Seat's rulings under the standing 100 % rule (not Ben's; recorded so no session re-asks): the three-layer split and
the composited desktop (§5), the turn-taking thread model (§5.1), data in git by the D24 shape (§4), the deviations
list (§8), phase scoping (§9), the open-item treatments (§10).

## 12. Risks the plans must carry as hazards

- **Regenerate the dumps before trusting a line number** (INDEX provenance recipes; the Ghidra project path must not
  contain a dot-prefixed element; copy the project before a postScript; `ghidra/find_func.py` defaults to Aki's dump —
  always pass `--file`; `docs/cythera/tools/pef.py --help` writes a stray file named `--help`).
- **The VM's stack must not clear popped slots** — shipped code reads stale slots (script-vm.md §3, §8, HIGH); the
  0x9C FFFF path leaves one stale slot per use, reclaimed at frame return (open-items-2026-10-06.md §1, HIGH).
- **Two wave-1 readings were overturned** (the ending branch, NR 22; rules.md §3.4's 0x80 condition) — cite the
  corrected sections, never the struck text.
- **Encryption covers script pages only** ("all of pages 0x01–0x30" is MED; data-format.md §1.3), and 0x0101/0x0210
  ship plaintext (NR 3) — the segment reader must not decrypt them.
- **Ferazel K1** (`PICT.decodePixels`, public 16-bit ColorTable) is on HectorKit main (d38a541, floor 313); Cythera's
  PICTs also need PackBitsRgn/DirectBitsRgn/16-bit DirectBits in that path — the phase0 plan's K1.
- **D-numbers collide** across parallel sessions: read DECISIONS on main at merge time and renumber.
