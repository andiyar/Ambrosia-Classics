# Design — Deimos Rising 1.0.6, native Apple Silicon (and Windows) replica — 2026-10-06

> Status: **DRAFT for Ben** (planner: Claude Opus 5.5, 2026-10-06). Ben's four rulings are DECISIONS **D27** and are
> not re-asked here; §11 lists the only genuine forks left, each with the phase that needs it and a proposed default
> the build proceeds on until he answers. Everything else is the seat's design under the standing ruling: replicate
> the original 100 %, no modern affordances, no per-element commissioning questions (CLAUDE.md, D30/D67 carried).
> **Spec:** the RE bank `docs/deimos/` (INDEX.md + 30 topical files; 938 role rows = 716 HIGH / 222 MED / 0 LOW; 100 %
> of game code read). **Plans carry contracts, not code** (Ben, 2026-10-03). Phase 1's executable plan is
> `docs/plans/2026-10-06-deimos-phase1.md`.

## 1. What "done" means (D27.1)

The whole game, Mac and Windows: all twelve sectors in the original play order (Mariner Valley → … → Carthage), every
unit, weapon, power-up, bomb, set piece and composite boss (the bank found no boss code — bosses are units, bosses.md
§1), the end-of-level tallies and bonuses, the all-levels finale, lives/extra lives, one- and two-player games, the
publisher/developer logos, main menu, level select, high scores and name entry, credits, the pause screen, the attract
mode replaying the four shipped demo films, `Last Film`, the configuration dialog (DITL 190) and controls, the console
with the commands 1.0.6 actually registers (FPS, VERSION, SUPERMUNKI and the six cheats — messages-notices-console.md
§5). Mac on HectorShell, Windows on the SDL shell Bubble Trouble X proved. Built in gated phases (§8).

**Out of scope until Ben names it** (the bank's "Out of scope" list): the level editor, Registration (the replica is the
registered game — no nag, no four-sector demo limit, no `Register Deimos Rising` app), the website link, the OS X
HID.bundle path, the debug-only console commands (never registered in 1.0.6, so not player-facing), iPad, a Remaster
art mode.

## 2. Oracles and the honesty line

| oracle | what it settles |
|---|---|
| The RE bank (`docs/deimos/`) | the rules, as **code readings only** ("nothing here is behaviour-verified", INDEX header). Labels HIGH (read from the listing, constants resolved) / MED (one inferred link). |
| The original data (`Resources/Deimos/`, D24) | every level, unit, weapon, sprite, sound, text format and film — loaded through the Phase 0 decoders, never re-authored. |
| The raw listing `~/Developer/Ambrosia-Classics/ghidra/deimos-proj/disasm-review3-all.txt` + memory images `mem/10000000.bin` (code) / `mem/100de330.bin` (data; r2 = `0x100e6330`) | the tie-breaker when a bank sentence and a test disagree. `ghidra/Deimos_pef.decompiled.c` does **not** exist on this machine (Phase 0 "As built"); every citation is a listing address. |
| **The four shipped demo films** (`film` de01–de04) | the strongest machine oracle for game logic (§9.4): each records a seed, a level and every input byte, and stores the score at its last recorded tick. |
| **YouTube longplays + Ben's eyes** (D27.4) | look, timing, feel. Compressed video settles "does the jungle look like that", never a 5-bit channel. |

Label rule (Ferazel D26 shape): **HIGH → frame-exact, pinned by a test to the bank's number. MED → built as read and
named on the phase's gate card. Anything the bank leaves open → the seat picks the documented rule, records it in
DECISIONS, and the gate card says "check this against the video".** Completion claims read "machine gates green;
Ben's gate pending" until he says it looks/plays like Deimos.

## 3. Architecture — the BTX/Ferazel three layers, plus a shared host so Windows is not a port

```
HectorKit (generic, game-agnostic)                Classics: Deimos/Core (one SwiftPM package)
┌────────────────────────────────┐                ┌──────────────────────────────────────────────────────┐
│ HectorResources StoredZip, Mac  │◄───────────────│ DeimosCore   Foundation + HectorResources/HectorAudio │
│   resource maps, MacRoman       │                │   Phase 0: tag index, text/token parsers, unde/plde/  │
│ HectorAudio  AIFF/AIFC, IMA4,   │◄───────────────│   wede/leve, TGA, GIF + plates → SpriteGroup, film    │
│   PCMMixer                      │                │   Phase 1+: RNG, frame controller, scroll, player,    │
│ HectorGraphics PICT/DITL (app   │◄──┐            │   units/spawn/collision/weapons/scoring (the rules),  │
│   fork: alerts, config dialog)  │   │            │   text layout, score bar, draw-command builders,       │
│ HectorShell  Mac window/present │   │            │   DeimosSession.pass → PassOutput (seam types)        │
│   keys, ShellMixer              │   │            │ DeimosRender Foundation + DeimosCore (+HectorAudio)    │
│ HectorSDL    Windows twin       │   │            │   persistent RGB555 buffers (back/terrain/score/screen)│
└────────────────────────────────┘   │            │   CopyBits, presents, fades, the 30 sprite blit leaves,│
                                      │            │   COST rects, render lists; the game's own mixer (Ph 2)│
                                      │            │ DeimosHost   Foundation + Core + Render                │
                                      │            │   the shell-neutral driver: Mac-tick clock, FPS limiter│
                                      │            │   fade/blocking sequences, key table, prefs/film files │
                                      │            │ deimos-census (exe, Phase 0) · tests per library       │
                                      │            └──────────────────────────────────────────────────────┘
                                      │            ┌───────────────────────────┐  ┌─────────────────────────┐
                                      └────────────│ Deimos/App  AppKit +      │  │ Deimos/Windows  HectorSDL│
                                                   │ HectorShell: window, keys,│  │ (Phase 5): same three    │
                                                   │ present, audio device,    │  │ libraries; drawn DITL    │
                                                   │ config dialog (Ph 4)      │  │ dialog (BTX D15 shape)   │
                                                   └───────────────────────────┘  └─────────────────────────┘
```

**Layer rules (HectorKit D6, Classics D12/D26):**
- `DeimosCore` imports Foundation, HectorResources, HectorAudio only (as Phase 0 left it). It owns every rule and
  every decision about *what* is drawn and heard, recorded at the original's call sites as seam values. It never
  reads a clock: game time is the logic-tick counter; real-time waits are requests to the host.
- `DeimosRender` imports Foundation + DeimosCore (+ HectorAudio from Phase 2 for the mixer). It owns every pixel and
  every PCM sample: the 640×480×16 back buffer `D+0x68`, the terrain buffer `D+0x6c` (the level map), the 160×480
  score-bar save buffer `D+0x70`, the 30 sprite-blit leaves, CopyBits/blend/fade arithmetic, and (Phase 2) the game's
  own software mixer and music streamer. Its output is a 640×480 RGB555 "screen" (the DrawSprocket window) and a PCM
  stream. **No HectorGraphics in Phase 1** — every in-game pixel comes from DeimosCore's own TGA/GIF decoders.
- `DeimosHost` (new, Foundation-only) is the driver both shells call: it turns a monotonic seconds clock into Mac
  ticks, runs one `DeimosSession.pass` when the original would, waits where the original spun on `TickCount` (FPS
  limiter, fades, logo waits), and maps held Mac virtual key codes through the original key table. **Why:** BTX's
  Windows port had to re-port the AppKit controller (D15, `BTXWinKit`); putting the controller logic below the shells
  from day one makes `Deimos/Windows` a thin SDL window + audio device + drawn dialog.
- `Deimos/App` (AppKit + HectorShell) and later `Deimos/Windows` (HectorSDL) only show the screen, play the PCM
  stream, deliver key state, and host the one OS-level dialog (configuration, Phase 4).
- **Seam types are LOCKED once Phase 1 lands** (cases may be added, never renamed): `HeldKeys`, `PlayerInput`,
  `DrawCommand`, `RenderOp`, `BufferID`, `PresentKind`, `FadeKind`, `PassOutput`, `SoundCue`, `MusicCue`,
  `ShellRequest`, `DeimosPrefs`.

**Rejected:** the Aki two-layer shape (no headless pixel tests; Windows would re-draw); one engine target with pixels in
Core (breaks D6 and loses the seam the tests hang off); a per-shell controller (the BTX Windows cost, D15).

### 3.1 Data-driven vs transcribed

| data-driven (loaded, never re-authored) | transcribed (code written from the bank) |
|---|---|
| 12 `leve` (565 placements), 386 `unde` (1,167 states), 2 `plde`, 5 `wede`, 220 `flli`, 5 `stli`, 6 `idli`, 54 `tefo`, `reli`, `coli` | the unit state machine, 17 rule conditions, spawn sets, motion controller, collision, damage, scoring, tallies (units-movement, spawn-and-waves, damage-health-death, scoring-bonuses) |
| 45 TGA (12 maps 480×3600, 12 media masks, menus, score bar), 125 sprite groups / 2,554 frames | the draw-command builders, render lists, 30 blit leaves, presents, fades (sprite-geometry-draw, blit-pixel-rules, display-window-present) |
| 96 effects + 3 music tracks (AIFC ima4) | the 16-voice / 8-audible mixer with its continuous-nibble IMA decode, the music level/fade arithmetic (sound-music) |
| 4 demo films + `Last Film` | film record/replay per tick (engine-loop §7, timing-frame §7) |
| the **level order** is NOT data: 12 obfuscated identifiers in the code image (`0x100d6470`) | transcribed as the 12 decoded identifiers (Lucena … Yamato, engine-loop §6, HIGH) matched against `#indentifier_STR` |
| app resource fork (D24 addendum): DITL 190–193, PICT 190–197, `icns 128` | the configuration dialog's behaviour (`FUN_10010fc0`), drawn from its DITL |

## 4. Timing model (engine-loop §3–§4, timing-frame §1–§4, all HIGH)

- **One loop pass = one logic tick = one presented frame.** The speed divider is never written in 1.0.6, so every pass
  ticks (timing-frame §3). There is no accumulator and no catch-up.
- **The FPS limiter** (byte pref 10, ON in fresh prefs and unchangeable in a stock build) spins until
  `TickCount ≥ lastPresent + 2`, then stamps `lastPresent = TickCount` and presents: **2 Mac ticks per frame**, i.e.
  30.07 fps at 60.15 Hz (or 30.00 at 60 Hz — Q1). After a blocking sequence the target is already past, so one frame
  goes out unpaced (timing-frame §4).
- **Real-time sequences** (fades: 9 steps from black / 33 to black, each "present, then wait until TickCount moves";
  logo waits 130/240 ticks; menu idle; music fade at quit) are TickCount-paced in the original and are host waits in the
  replica, expressed by Core as `RenderOp`s / `PassOutput` requests the driver schedules. Core never sees seconds.
- **The host clock:** `DeimosHost` converts a monotonic seconds clock (`ProcessInfo.systemUptime` on the Mac,
  `SDLClock.now` on Windows) into Mac ticks at the ruled rate (Q1; default 60.15 Hz) and is polled by a fast idle timer
  (1/240 s) so a 2-tick target is met within ~4 ms, never a whole extra tick.
- **Game time** (`game+0x1c`) resets to 0 at each level start; all data durations are ticks of it.

## 5. Render model

- **16-bit QuickDraw RGB555 throughout** (x1R5G5B5, bit 15 clear), exactly the original's GWorld depth (F56 = 16). No
  palette problem (unlike Ferazel): the maps are native 16-bit TGAs; sprite plates are 24-bit GIF colours truncated
  `c >> 3` (Phase 0 note 15, MED — on every gate card while it matters).
- **Persistent buffers, transcribed draws** (BTX D12.2): Core records the original's draw calls in order; Render
  executes them on buffers that persist between passes, artefacts included (the score bar is drawn as dirty rects into
  the back buffer and survives because the terrain blit only covers x 0..415).
- **Frame order** (end frame `FUN_10030bc0`, listing-confirmed): draw world queues/draws (`FUN_10007070`: entity groups
  → motion blurs → players → accuracy tally → notices → score bar) → messages/FPS/console text → flush layers 0–1
  (terrain stamps, into the terrain buffer) → terrain window → back buffer (two identical CopyBits, or one interlaced)
  → flush layers 2–5 → particles → flush layers 6–15 → limiter → present (`FUN_1000beb0`: paint the 32-px borders
  black, CopyBits the game area to screen x 32..447 and the bar to 448..607).
- **Screen = the DrawSprocket window**: a persistent 640×480 RGB555 buffer receiving presents, fade steps and the
  score bar's direct dirty-rect blits. The shell shows it after every change.
- **To the display:** RGB555 → 8-bit per channel by bit replication `(c << 3) | (c >> 2)` (the kit's own PICT rule,
  HectorGraphics `PICT.swift`), presented at **640×480 × the largest whole multiple** that fits, black border (D27.3),
  nearest-neighbour. Window: the largest k whose 640k × 480k points fit the visible frame; full screen ⌃⌘F.
- **Tearing** is part of the original (no VBL wait, one CopyBits pair per frame, display-window-present §8.2); the
  replica presents whole frames. Disclosed deviation (§7.1), not reproduced.

## 6. Audio model (Phase 2; sound-music.md, HIGH unless marked)

- **Effects:** the game's own mixer, transcribed in `DeimosRender`: a ranked list of up to 16 voices, the top
  `SoundNumChannels` = 8 audible, the rest advancing silently; insertion by (priority, gain) with newest-first among
  equals; per-voice continuous-nibble IMA decode (packet preambles stripped at load — Phase 0 note 21, MED), linear
  interpolation by `step = pitch` (speed 1/p — Q2), gain `sample·g >> 7`, saturating ±32767 mix into one stereo
  44.1 kHz stream. Pitch draws consume the shared RNG on every play call whose ID ≠ `none` (replay-relevant).
- **Music:** a second stream: the level's `#music_ID` (`mu03` in all twelve), `ammu`, `inmu`, decoded by the kit
  (`AIFFAudio`/`IMA4` = Apple's decoder = what the Sound Manager played), looped seamlessly over the whole SSND,
  restarted from 0 every level, level `amp = min(255, m·fade >> 8)` with `m = 128·v/100` (Q3 decides what 255 means).
- **Master volume:** the original set the Mac's output volume; the replica applies an app gain (sound-music §8 lists
  this as implementation detail), quantised as the original (boot 100 → 90, ±10 on `-`/`=`) — Q4.
- **Kit addition in Phase 2 (K2):** a pull-PCM source the shells can play — `ShellMixer` gains a stream voice (an
  `AVAudioSourceNode` pulling from a `Sendable` render closure) and `SDLAudioOut` an init over the same pull protocol.
  `PCMMixer` already exists in HectorAudio; the Deimos mixer is game logic and stays in Classics.

## 7. Known deviations, disclosed up front

1. **Whole-frame presents, no tearing** (§5). No DrawSprocket context switch, no display-depth change: the game is a
   640×480 canvas in a window or full screen (D27.3).
2. **No OS volume writes** — an app gain with the original's arithmetic (§6); the user's device volume is untouched.
3. **No InputSprocket.** Keys come from the original prefs key table (`+0x14b8`: P1 ↑ ← → ↓ ⌘ ⌥ Space, P2 kp8 kp4 kp6
   kp5 End Fwd-Del PgDn — timing-frame §6; slot order up, left, right, down, then three buttons whose exact mapping to
   fire air / fire ground / select is LOW in the bank and is pinned against the guide — ⌘ fire air, ⌥ fire ground,
   Space select — in Phase 2), which agrees with the guide for P1. Controls dialog: Q8.
4. **Registered build** (§1). The integrity/anti-tamper checks (`FUN_10028170` §9, `FUN_10001080`) are not built.
5. **Prefs** live in one file with the original 0x34f0 layout, obfuscation included, at
   `~/Library/Application Support/Ambrosia Classics/Deimos Rising/Deimos Rising Preferences` (Mac) and
   `%APPDATA%\Ambrosia Classics\Deimos Rising\` (Windows) — never `UserDefaults` (D16.3: crashes under Wine). The
   configuration dialog's first-launch rule (byte pref 2) is kept.
6. **`Last Film`** is written to `…/Deimos Rising/Local/film/`, which the tag index scans as the original's
   `Data:Local` override folder (app-pak-music-library §2.2) — the bundled `Data` stays read-only.
7. **DEBUG-only "data missing" alert** (Aki/BTX precedent); nothing else the original lacks.

## 8. Phases and gates (proposal; order is Q7)

| phase | lands | gate |
|---|---|---|
| **0 Data + decoders** — DONE (D24) | paks/rsrc in git, kit ZIP/AIFF/WAVE/PICT 0x009B, DeimosCore decoders, census 872/0 | machine |
| **1 Level 1 look** (D27.2) | Mariner Valley's map scrolling 1 px/tick from row 3120, the level-start sequence (two unpresented ticks, the 9-step fade from black, ship absent 55 ticks then fading in with its shadow and the bomb crosshair), the score bar at its start values (shield meter filling), borders, whole-number scale, the limiter; left/right bank the ship and pan the 480-wide map ±32 px (stub — the ship does not move); app on HectorShell staged to `~/Desktop` | **Ben: "does it look like Deimos"** |
| **2 Level 1 plays** | the unit system (states, 17 rules, spawn sets, motion, culling, groups/PERM, owner links), collision/damage/destruction, player physics + respawn + death, the five weapons + power-ups/overload + bombs + crosshair lock, pickups/coins/multiplier, particles/debris/motion blur, notices/messages, scroll pauses and level end with tallies, the effects mixer + music (K2), pause (Caps Lock), Esc, `-`/`=`/F6, console + cheats | machine: **de01 replay** (le07) reaches score 25,050 at tick 4,809; Ben plays level 1 |
| **3 The campaign** | all twelve sectors in order, level transitions + fades, defence/accuracy/coin bonuses, random bonuses, extra lives, game over, the all-levels finale, two-player games | machine: **de02–de04 replays** (116,180 @ 8,357 · 57,520 @ 10,058 · 24,670 @ 5,649); Ben plays through |
| **4 Front end** | logos, main menu (hover strip, idle), level select (preview, flash, starting bonus), scores + name entry + erase, credits, attract mode over the `Demo` films, `Last Film`, prefs file, the configuration dialog (DITL 190) + controls (Q8), alerts | Ben: cold start → game → scores → quit |
| **5 Windows + release** | `Deimos/Windows` on HectorSDL over the same three libraries (drawn DITL dialog; candidate kit lift of BTXWinKit's dialog renderer — BTX + Deimos = two games), staged for Ben's brother; notarized Mac DMG + Windows zip (BTX D25 shape) | brother's report; Ben's DMG check |

One plan per phase, written against what landed. Orchestrator sessions are 2–3 tasks (fable-kit §5). Each phase ends
with a staged `.app` on `~/Desktop` + WHAT-TO-EXPECT (CLAUDE.md, Aki/BTX precedent) and a gate card.

## 9. Test strategy

1. **Transcription tests** per routine, numbers from the bank with section + label (e.g. visibility → alpha
   `trunc(32 − 0.32·v)`; shadow α table at a = 20; scroll top 3120, level end on scroll tick 3,119; banking jump tables).
2. **Data tests** over the committed data (never skip; `DEIMOS_DATA` overrides): definitions, frames, formats.
3. **Frame goldens + independent pixel oracles** (Render): FNV-1a 64 of the 640×480 screen at named passes of a
   headless session (self-derived on first green run, reviewed by a second leg — Ferazel precedent), each paired with
   oracles that do not share the code under test: game-area pixels equal the map TGA at the scrolled window where no
   sprite lies; borders are 0; score-bar pixels outside element rects equal the `scor` TGA; shadowed pixels equal
   `⌊c·20/32⌋` of the map.
4. **Film replay — the determinism oracle (Phases 2–3).** A film stores its seed, level, every P1 input byte and the
   decoded score + 0xb3ac2 at its last recorded tick (engine-loop §7, HIGH). Replaying de01–de04 headless and reaching
   exactly 25,050 / 116,180 / 57,520 / 24,670 at 4,809 / 8,357 / 10,058 / 5,649 ticks exercises spawn order, every RNG
   draw (int and float RandomRange, per-entity order, particle and pitch draws), collision, damage and scoring at once.
   Hazard (BTX lesson, memory "FILMs predate 1.1"): the films carry version 0x2715 = the 1.0.6 loader's, but could have
   been recorded on earlier data; a divergence is investigated tick by tick (score trace) before it is called a bug,
   and Ben's eyes on the attract demo are the fallback oracle.
5. **Ben's eyes and hands** at every gate.

## 10. Kit work, and what is shared with Ferazel

- **Phase 1, K1:** `ShellView.scalingPolicy` on macOS (`.aspectFit` default — Aki/BTX unchanged; `.integerFit` =
  largest whole multiple, centred, black border, nearest) passed through `ShellWindowController`. Today only the iOS
  `ShellTouchView` has the policy; a Mac full screen falls back to smooth aspect fit, which D27.3 rejects. **Ferazel's
  A1 assumes the same behaviour** (its plan says `enterFullscreen()` gives the largest whole multiple) — this one kit
  change serves both; whichever session lands it first, the other reuses it (tell the Ferazel session).
- **Phase 2, K2:** the pull-PCM stream voice (§6).
- **Phase 5, K3 (candidate):** lift BTXWinKit's DITL dialog renderer into HectorSDL (two games).
- **Not needed:** Ferazel's K1 (PICT indexed pixels + public `ColorTable`) — Deimos has no 8-bit colour search in game.
  If a later Deimos phase needs a `ColorTable` (it should not: the app-fork PICTs are direct 16-bit), reuse Ferazel's.

## 11. Questions for Ben (genuine forks only; each with the phase that needs it and the default the build uses)

1. **TickCount rate (INDEX #42) — Phase 1.** Classic Mac OS ticks at 60.15 Hz (frames every 33.25 ms = 30.07 fps); Mac
   OS X's TickCount is exactly 60 Hz (30.00 fps; what Aki/BTX use). **Default: 60.15** — Deimos 1.0.6 is a classic
   (InterfaceLib, not Carbon) application, so it ran at Mac OS 9 / Classic speed. The difference is 0.25 % (a level
   lasts ≈ 0.26 s longer at 60). Say "60" if you played it on OS X.
2. **Pitch direction (INDEX #49) — Phase 2.** The mixer code plays a sound at speed 1/pitch (pitch > 1 = longer and
   lower), which inverts what the data's key names suggest. **Default: as the code** (a bullet impact `exsl` at 0.5 is a
   short, high pop). If impacts in the longplays sound deep and slow, flip it.
3. **Music loudness (INDEX #50) — Phase 2.** Music at pref 100 is sent at `ampCmd` 128; whether the Sound Manager's full
   scale is 255 or 256 decides only that music sits ≈ 6 dB under a full-volume effect. **Default: full scale 255**
   (Inside Macintosh: amplitude 0–255) → music at 128/255 of an effect's level. Tell us if music sounds too quiet.
4. **Volume keys (INDEX #44, #52) — Phase 2 (in game) / Phase 4 (menu).** Under Mac OS 9, `-`/`=` change the volume in
   steps of 10 with a click and an on-screen "Sound Volume 40%"; under Mac OS X the same keys silently do nothing
   audible. **Default: the OS 9 behaviour** (the game as designed), applied as an app gain; the menu's extra charCodes
   0x9D/0x8A (`ù`/`ä`) are accepted as typed.
5. **Invulnerability carry-over — Phase 3.** As read, a ship that finishes a level stays invulnerable for its first
   ~61 ticks (≈ 2 s) in every following level (player-physics §4.4, MED consequence). **Default: as read.** If you
   remember being hittable at once on level 2+, say so.
6. **Title screen upright (INDEX #10) — Phase 4, first evidence in Phase 1.** The TGAs are stored bottom-up and decoded
   by their header bit; Phase 1's level map uses the same rule, so if Mariner Valley looks right the title will too.
   **Default: upright** (as decoded). Phase 0's `deimos-census --render out/deimos-render` → `menu.png` shows it now.
7. **Gate order — Phases 2–4.** Proposed (§8): level 1 plays → the whole campaign → front end → Windows. Ferazel took the
   other order at your ruling (front end right after movement, D26.3). **Default: play first** — the film-replay oracle
   proves the logic phase by phase, and the front end is self-contained. Say "front end early" to swap Phases 3 and 4.
8. **"Set Controls…" — Phase 4.** The original's controls window is Apple's InputSprocket dialog, not the game's own,
   and the OS X keyboard path that used the game's own window is unreachable from this classic binary (INDEX #14).
   That window still ships: DITL 191 "Game - Controls" in the app fork — seven pictures (PICT 190–193 arrows, 195–197
   fire air / fire ground / select special) each beside an edit field — over the prefs key table. **Default:** build
   DITL 191 as the "Set Controls…" window, rebinding the two players' keys in the original key table. Alternative: no
   rebinding (fixed defaults).

Not questions (the bank or the seat settles them): the 24→16 colour rule and the 8-bit inverse-table frame scan (MED,
on gate cards), MathLib `atan` last-ulp (#45, film replay will expose it), the finale ±1 tick (#47 closed), int pref 2
(no reader — kept as data).

## 12. Risks carried as hazards into every plan

- **No decompile:** cite listing addresses; the copy-loop `lwzu/stwu` +8 trap (hud-scorebar §4: `0x100eb228`, not
  `…224`); static initialisers rewrite templates before `main` (INDEX #56: use runtime values, e.g. draw-template clip
  {0,0,480,416}); the signed-compare idiom (timing-frame §7).
- **Replay fragility:** any RNG draw out of order desynchronises a film silently — keep every draw site in the bank's
  order (engine-loop §9; spawn-and-waves §9) and trace score per tick when a replay misses.
- **Tests that decode all 2,554 frames or a music track** are slow and large — decode once per suite (static cache),
  one music track at a time (Phase 0 invariant 15).
- **D-numbers collide** across parallel sessions (D23/D24 did): read DECISIONS on `main` at commit time and renumber.
- **Sibling sessions:** Ferazel's build runs in its own worktree; Deimos tasks touch only `Deimos/`, `Resources/Deimos/`,
  `tools/*deimos*`, the `project.yml` Deimos block, docs, and (K-tasks) HectorKit in its own worktree.
