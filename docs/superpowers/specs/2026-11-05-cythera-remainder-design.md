# Cythera — design for the rest of the port (Phase 0 second half, Phases 1–8)

*Written 2026-11-05 by Claude Fable 5.1 in the seat, as the re-planning pass of `~/Developer/Toolkits/fable-kit/replan.md`
(the lighter case: a stall, not churn). Read-only on the code: nothing was built. Companion documents: the plan
`docs/superpowers/plans/2026-11-05-cythera-remainder.md` and the audit
`docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md`. It sits under `CLAUDE.md`, the approved design
`docs/plans/2026-10-06-cythera-design.md` (DECISIONS D28, its rulings §11) and the Phase 0 plan
`docs/plans/2026-10-06-cythera-phase0.md` (its two correction blocks). Where this document and the design differ,
this document says so in §5 and the difference is a ruling for Ben in §9.*

## 0. The game in one paragraph

Cythera (Ambrosia, 1999; Glenn Andreas' "Delver" engine) is an Ultima-style role-playing game: a stranger is
summoned to the island of Cythera to find what ails its ruler Alaric, and walks a tile map of towns, caves and
ruins, talking to people by typed keywords, trading, fighting, casting spells and following a story to one of two
endings. The screen is a Mac desktop of the game's own windows (a growable map, a status panel, a character
window per party member, conversation and scripted windows) floating on a full-screen backdrop, all drawn from the
game's own 8-bit tiles. Most of the rules are not in the binary: native code sends numbered messages
("selectors") to bytecode scripts stored with the data, so the replica is above all a script machine with a
transcribed engine around it. One `CytheraCore` (rules, scripts, world, the window model, saves), one
`CytheraRender` (every pixel and sample), two thin shells (Mac now, Windows in Phase 8). The rule for everything
here is the Classics rule: 100 % the original, no additions; where the platform forces a departure it is named.

## 1. Where the port stands (the review, 2026-11-05)

### 1.1 Phase table (design §9)

| phase | state | evidence |
|---|---|---|
| 0 Data + decoders + census | **half built**: K1, C0–C5 landed 2026-10-07; C6–C12 never started; nothing since | `Cythera/Core` 44 tests; `Resources/Cythera/` 20 files; D28 as-built ×2; handoffs t1, t2 |
| 1 Walking Catamarca | not planned (one row in design §9) | — |
| 2–7 | not planned | — |
| 8 Windows + docs viewer + release | not planned | BTX's Windows shell and release recipe exist as precedents |

### 1.2 Numbers from this session's own runs

| check | result |
|---|---|
| `Cythera/Core` suite (`swift test`, against HectorKit main ef2c341 — the package resolves HectorKit by local path, so it already builds on today's main) | **44 passed, 0 failed, 0 skipped** (CytheraCoreTests 34, CytheraRenderTests 10) |
| HectorKit zero-skip gate at **ef2c341** (today's main) | **PASS, 370 executed = floor 370**, 0 failures |
| HectorKit zero-skip gate at **4ca2e18** (Cythera's pin, in a throw-away worktree) | **PASS, 322 executed = floor 322**, 0 failures |
| the gate script's default Aki data path | stale (the Aki 1.1 app moved to `~/Developer/Ambrosia/Resources/`): without `HECTORKIT_DATA_AKI11` overridden, both runs skip 4 Aki tests and the gate fails — a one-line HectorKit follow-up, not a kit fault |
| branches and worktrees | no Cythera branch or worktree; the three worktrees present are Deimos (Ben's), Ferazel's stopped loop run 42, the merged gamepad work |
| the decompile | committed at `ghidra/cythera/` since 2026-10-07 (four dumps, 1,994 functions, the 958 script listings); the Phase 0 plan's "dumps absent" hazard no longer holds |

### 1.3 Diagnosis: a stall, and three stale facts — not churn

The Phase 0 record is clean. The plan was measured (every number a probe), the two STOPs under Invariant 10 (direct
PICT modes in K1; map chunk 0 and the 0xF001 tail in C4) were data facts the seat re-measured and ruled in the same
session, every task was mergeable first pass or after one fix round, nothing was redone. The port stopped because
**no session was chipped after tranche 2** (the seat's attention went to Ferazel's loop, the gamepad work and
Castles) and because **nothing beyond Phase 0 was planned** — an orchestrator picking the chip up would reach C12 and
have no next row to pull on. Three facts in the Phase 0 plan have gone stale and would trip a fresh orchestrator:

1. Its task legend says "Fable reviewers"; Ben ruled on 2026-10-07 that every implementer and reviewer leg is Opus
   5.5 (D28 as-built, `CLAUDE.md`). The all-Opus policy stands.
2. Its test ladder assumes the canonical order C6 → C7 → C8 → C9 → C10; the handoff says C8 → C9 come first. §6.1
   fixes the order and the numbers.
3. HectorKit has moved past the pin (§8); the plan's K1 fallback, D-number and `$HKWT` paths are history.

One slip in the approved design needs a word from Ben (§9 Q4): D28 ruling 2 says "Alaric walks". Alaric is character
2, the dignified old ruler the player is summoned by (segment 0x1802); the player is character 1, default name
"Bellerophon" (`NewGame`, app-shell.md §5.2). The first gate is the **player** walking Catamarca.

## 2. The shape of the whole program

The design's three layers stand (design §5, D28). This section fixes the modules inside them so that every later
plan puts a file in a known place and nothing is designed twice.

```
CytheraCore (Foundation + HectorResources only)
  Data/        CytheraData, CytheraResources                          built (C1)
  Segments/    SegmentFile, SegmentCipher, SegmentOverlay             built (C2); file-backed writable store: Phase 4
  Codec/       LZ                                                     built (C3)
  World/       maps, props, globals, CharEntry, schedules (records)   built (C4); the live tables: Phase 1
  Art/         clut, pltt, Lite, FILT records                         built (C5)
  UI/          DLOG/DITL/WIND/CNTL/ALRT/MENU/STR#/TxSt/FOND/nrct/Pref C10
  Script/      opcodes, instruction decoder, listing, parity          C8, C9 → the VM, builtins, THeap: Phase 2
  State/       GameState — the one state model (§3)                   Phase 1 (the slice Phase 1 needs), grown per phase
  Engine/      clock, DoTicks, MoveAll/DoTick, TGameSys commands,     Phase 1 (movement, stage, LOS, light) → Phase 2
               TActiveMonster, pathfinder, schedules, signals,
               THood, SetStage, LOS, light map, the thread model
  Windows/     the window-system MODEL: desktop, TWindow layers,     Phase 1
               rects, z-order, drag/grow/close, drawers, the Map
               window's view size, dialogs as models, menus
  Saves/       'Char' stream, chunks, SaveToFile/RestoreModel, prefs  Phase 4
CytheraRender (CytheraCore + HectorGraphics + HectorAudio)
  Pixels/      tiles, portraits, sky, pix, icons, palette, PICTs      built (C5)
  Audio/       SoundSegment ('asnd'), TuneSequence (QTMA events)      C6, C7 → mixer (TAudio rules), music cues: Phase 2
  Text/        BitmapFont (NFNT), glyph sheets, TextOut rules         C10 → Phase 1
  Map/         the (N+1)·32 offscreen, Render passes, roofs, filter,  Phase 1
               light, transitions, barks
  Desktop/     window frames and controls from tiles 0x19C–0x1AF      Phase 1
               (WDEF/CDEF transcriptions), the backdrop, the
               composition of every window in z-order → one indexed
               screen → RGBA through the palette and gamma
  Census/      cythera-census, --render                               C11
Cythera/App (AppKit + HectorShell + Apple's GM synth)                  Phase 1
Cythera/Windows (SDL twin)                                             Phase 8
Cythera Documentation (viewer)                                         Phase 8
```

**Seam types, locked when Phase 1 lands** (design §5): `DesktopFrame` (indexed screen + palette + gamma level),
`InputEvent` (the original's TaskEvent kinds 1–5 plus the raw key/mouse the event loop sees), `ShellRequest` (menu
bar show/hide, file dialogs, quit, cursor), `SoundCue` / `MusicCue`, `PrefsRecord`. Cases may be added, never renamed.

**One instruction walker.** The C8 decoder's operand walk *is* the Phase 2 interpreter's fetch: the VM executes
`ScriptInstruction`s the decoder produced, never a second byte-walker. Parity with `scriptdis.py` (C9) then proves
the fetch of every one of the 22,166 shipped instructions before a single one is executed.

## 3. The one state model

**Rule:** a part of the program may hold game state only if that state is in the save. Everything else is derived
and must be rebuildable from the saved state at any moment. This is what makes "saves in the original format,
both ways" (D28 ruling 7) a property of the design rather than a Phase 4 feat.

| state | original holder | saved as (data-format §7, §1.4) | replica owner | phase |
|---|---|---|---|---|
| the scenario and its overlays | `TCachedSegFiles` slots: data file, patch, player file, `'Temp'` scratch | the player file is itself a sparse segment file | `SegmentOverlay` (built; made a readable store with a decrypted read in C13 — ⚑ audit 1) + a file-backed writable store (`RefindSegment` bottom-most; an empty save masks lower copies — ⚑ audit 11) | Phase 4 |
| props of the current level (≥ 0x100) | the prop table, `cdc44`, high-water `cdc3c` | 0x8100+L | `PropTable` | Phase 1 |
| the 256 character props | same table, indices 0..255 | 0xF306 | `PropTable` | Phase 1 |
| the characters | `CharEntry[512]` | 0xF009 (0x4000 B) | `CharacterTable` | Phase 1 |
| seen cells (automap) | the map words' bit 0x8000 | 0x8200+L | `LevelMap` seen bits | Phase 1 |
| clock and day | `DAT_100d3e18/1c` | `'Char'` l + h | `GameClock` | Phase 1 (fixed) / Phase 2 (runs) |
| karma, global 0x0E, difficulty, serial counter | the four `hhhh` | `'Char'` | `GameState` scalars | Phase 2 |
| 32 byte variables, 256 global flags | `cdbbc`, `cdbc0` | `'Char'` 32 b + 8 l | `GameState` | Phase 2 |
| viewer byte +0xD (automap enabled), play seconds | — | `'Char'` | `GameState` | Phase 2 / 4 |
| active monsters | `TActiveMonster` list | `'Mons'` chunk | `MonsterList` | Phase 2 |
| the persistent script heap and the unique-object table | `THeap` 0x40000, 0xF308 | 0xF307, 0xF308 | `ScriptHeap` | Phase 2 |
| timed abilities / spell effects | `TSpellFX` queue | `'FXQ '` | `EffectQueue` | Phase 6 |
| gremlins (script agents) | `TGremlin[256]` | `'Grem'` 0x400 B | `GremlinTable` | Phase 2 |
| open inventory windows | `TInventoryWindow` list | `'Wind'` chunk (class id + Marshal) | the window model | Phase 5 |
| journal, to-do, status macros | `TJournal`, `TToDo`, `TStatusWindow` | 0xE000+k, 0x0401, 0x0404 | `Journal`, `ToDoList`, `Macros` | Phase 3 / 3 / 1 |
| preferences | `TPrefs` named `'Pref'` resources + the UI-prefs word | the prefs file (data-format §8) | `PrefsRecord` | Phase 1 reads defaults; Phase 4 reads/writes the file |

**Derived, never saved:** the hood, the 31×31 stage and its quarter grid, the LOS grid, the light map, the Render
staged list, the per-animation-frame tile pointer tables, the window pixels, the conversation's chips (rebuilt
from the script's `add_answer` calls), the party light. Each has one builder and no second copy.

## 4. How the parts fit — the turn and the frame

The original is turn-driven and frame-paced separately (engine-classes.md §3.4, app-shell.md §3). The replica keeps
both loops and the three cooperative threads as real threads taking strict turns (D28 seat ruling; §5 below):

```
shell → InputEvent ──► event loop (app thread): menu bar, window hit, TaskEvent queue
                              │ kinds 1 mouse / 2 key / 3 turn / 4 skill
                              ▼
                        task thread: TDroppableWindow Mouse/KeyRoutine → TGameSys command
                              │ → HeartBeat(n) → MoveAll: DoTick round-robin until the leader is free
                              │     DoTick → DoMove (schedules, AI, pathfinding) → selectors → the script VM
                              │     leader ticks → DoTicks → clock, schedules, regeneration
                              ▼ (state changes only: GameState, PropTable, CharacterTable, heap, windows model)
                        anim thread, at most every F ticks: SetStage → LOS/NoLOS → light → Render passes →
                              roofs → filter → light → barks → the Map window's pixels
                              ▼
                        desktop compositor: every window in z-order → one indexed screen → DesktopFrame → shell
```

Scripts block mid-routine on `input` (0x8E), prompts (0x8F), MORE paging, how-many, pick lists, `cbPlaySoundSync`
and `wait_for_flag`; each is a nested modal loop or a busy wait in the original (dialogue-ui.md, script-builtins.md
F1). In the replica each is a point where the task thread yields to the app thread with a **wait reason**; the
headless driver (tests) answers the reason from a script of inputs, the shell answers it from the user. The VM is
never re-entrant and never a state machine (rejected in D28); the wait reasons are the only seam.

## 5. Faithful, ruled, or a platform departure

Everything is faithful unless listed. The design's §8 deviations stand unchanged. The seat's rulings below are
under the standing 100 % rule and recorded in DECISIONS when Ben has seen them (§9); none changes a HIGH bank rule.

| item | class | ruling |
|---|---|---|
| Which `clut 256` (data file vs app; four entries differ: 0 white vs grey, 16 two greys, 252/253 dark blues vs black — ⚑ audit 4) | ruled (MED in the bank) | data file's, by the resource chain's order (built, `Palette.origin`); the Phase 1 gate card shows both and Ben's eyes decide |
| Duplicate-black tie-break under the palette | ruled | the lowest and highest selectable indices are both built; Phase 1 gate card (D28) |
| Direct-colour PICTs (paper doll 16-bit, start-screen frames 32-bit) into the 8-bit screen | ruled (LOW) | nearest palette entry by plain RGB distance, computed once per picture; Phase 1 (paper doll) / Phase 4 (start screen) gate cards |
| Text: the Font Manager's rasterisation of the game's fonts at the requested sizes (TxSt: ArgosANouveau 14/18/22/24 TrueType; Seldane NFNT 12/18 strikes asked at 10/12/18; Geneva 9/10 and Chicago 12 system fonts) | **Ben's (Q2)** | recommended: **glyph sheets baked once on the Mac** from the shipped `sfnt`/`NFNT` and the system fonts at exactly the requested sizes and styles, committed as data beside the port with a census test; the anti-aliased path (`AADrawText`) read in Phase 1's research; the 1999 screenshots are the check. Rejected: an own TrueType rasteriser (weeks, and it would not reproduce the Font Manager either) |
| THood insertion order within a pass | ruled (NOT RESOLVED) | read `AddToHood`/`MoveHood` in Phase 1's research task; until then the as-read list walk |
| The 0xC0 multi-tile disagreement between SetStage and Render (render.md §5) | faithful | both copied as read; it is behaviour |
| Pass 2 never draws | faithful | copied (a constant kills it) |
| Compo tiles built from frame 0's tile table (they never animate; tile 1275 shows as 1274 — ⚑ audit 3) | faithful | copied; Phase 1 passes the frame-0 table, never the raw store |
| QTMA value-1 end markers + `TuneDifference` events (168 pairs) | ruled (NOT RESOLVED) | C7 decodes and counts; Phase 2 plays through Apple's synth and Ben's ear decides |
| `cbPlaySoundSync`'s busy wait stalls the whole program | faithful, with a platform note | the task thread waits for the mixer's voice-end; the app thread keeps presenting the last frame (the original froze the screen too; nothing is drawn while it waits) |
| Real-time mode's fabricated space key every 20 idle ticks | faithful | — |
| Key auto-repeat dropped | faithful | design §5.2 |
| The three cooperative threads as real threads taking strict turns | ruled (D28) | unchanged; the wait reasons of §4 are the seam |
| Windowed mode | switch (D28 ruling 3) | the window's content is the monitor; no other switch is added |
| NFNT owTable one entry short; FOND 128 names a missing NFNT | faithful | stored as shipped (C10) |
| The combat-AI band stored plaintext | faithful | read with `segment(_:)`, never decrypted (C8/C9 route it) |

## 6. What remains, phase by phase (design §9 order; sizes are task counts)

### 6.1 Phase 0b — the second half of Phase 0 (the next wave; the plan's wave 1)

The Phase 0 plan's contracts C6–C12 stand as written, with these corrections applied by this pass:

| task | what | ladder (`Cythera/Core` total, cumulative in **this** order) |
|---|---|---|
| C8 ⚑ | script instruction decoder (statements, expressions, operand lengths, the 95 builtin names) | 44 → **50** |
| C9 ⚑ | script segment model + canonical parity with `scriptdis.py` for all 958 segments; `script_canon.py`; the committed hash list; the combat-AI band read as stored through `scriptSegment` (⚑ audit 2) | **57** |
| C6 | `'asnd'` + 13 `snd ` → PCM | **63** |
| C7 ⚑ | QTMA MusicDescription + event decoder for the 11 tunes (closes INDEX NOT RESOLVED 9) | **71** |
| C10 | UI resource records + `BitmapFont` | **80** |
| C13 | **new (⚑ audit 1, 3, 5–9):** the overlay becomes a segment store with a decrypted read, a store-based map initialiser, the carried minors, the compo-tile and palette comments, two pinning tests | **86** |
| C11 | `cythera-census` + `docs/cythera/data-census.md` + `--render` | **91** |
| C12 | final gates + D28 as-built; records the HectorKit re-base (§8) and the three S2 deviations (⚑ audit 9) | 91 |

The legend's "Fable reviewers" is replaced by the standing policy: one Opus 5.5 implementer and one Opus 5.5
reviewer per task, two reviewer legs per ⚑ task. The dumps are committed; cite `ghidra/cythera/…` lines.

### 6.2 Phase 1 — the player walking Catamarca (first gate; design §9 row 1)

The largest unplanned step, because it builds the frame loop end to end. **Research first** (one task, fully
specified in the plan: R1): the unread bodies Phase 1 needs — `CreateWindows @ 10013c04` (the default window
layout), the full `TMapWindow::KeyRoutine` key table, `CalcLighting`, `DimOffLevel`, `InteractProps`, `AddToHood`/
`MoveHood`, the post-light vtable hook, `AADrawText`/`TDisableAntiAliasText`, `HandleMove`/`HandleSubMove`, the `LOS`
shadow walk, `NewModel`'s start placement of character 1 (where a new game begins and which level is Catamarca),
`PutInALayer` and the layer names, `DrawRoutine`'s eight transition kinds, the WDEF/CDEF draw routines for the
Border, ThinBorder, Pixs and Drawer frames. R1 ends with a research note in the bank and the measured numbers
the Phase 1 plan pins. **Then the build**, in two halves Ben can gate separately (§9 Q5):

- **1a — the still picture**: the window model; the backdrop; the Map window's offscreen with every Render step
  (ground, passes 0/1/3, creatures, pass 5, backdrops, roofs, filter, light for the clock's hour); the Status
  panel with the sky strip and portraits; the Roster and Text windows; the frames and controls from tiles;
  text; the desktop composited to one screen; the HectorShell resizable 1:1 canvas (kit task); the app target;
  a new game's world loaded with no scripts run (shipped globals, character 1 at its shipped location). Gate:
  side by side with the Catamarca screenshot.
- **1b — walking**: keys and mouse through the TaskEvent queue; `MoveCommand`/`CanMove`/`TryMove`/`CanSlide`,
  sub-tile movement by the graphics-quality bits, `HeartBeat` → `MoveAll` with only the leader ticking (no
  schedules, no AI); the clock advancing per leader tick; SetStage/LOS per move; roofs lifting; the map window's
  grow box; the menu bar's show/hide. Gate: the player walks Catamarca, roofs lift.

Size: R1 + about 14 build tasks (1a ≈ 9, 1b ≈ 5) + one kit task.

### 6.3 Phase 2 — the world runs (design §9 row 2)

The script VM (`TInterp`: values, frames, the 0x400-slot stack that never clears popped slots, every statement and
expression of script-vm.md §4–§5, the dispatch rules of §2, `GetField`/`SetField`, `GetGlobal`), the 95 builtins
(script-builtins.md §2, one file per family), the persistent heap, the thread model with wait reasons; then the
clock's periodic rates, schedules and `EvalCondition`, `RepositionChar`, `DoMove` and the activity byte, the
activity queue, pathfinding, the hood, eggs and spawning, doors and object scripts (selector 9), signals; the
mixer (`TAudio` rules: 16 voices, priority, pitch spread, stereo), ambient emitters, the music cues through
Apple's synth. Gate: walk around Catamarca across a day. Size: research R2 (VM edge cases from the dump: `At`,
`Len`, `IsEqual`, `Ctor`, `VAddrToPtr`, `DispatchSysObj`; the mixer's voice table and end-of-sample path) + about
16 build tasks. **How the VM is proven** is §7's most important row.

### 6.4 Phases 3–7

| phase | lands | size (tasks) | research first |
|---|---|---|---|
| 3 Talk | `TConversation`, the five conversation modes, chips, prompts, MORE, barks, Journal, To-Do, books/signs/scripted windows (the `sysnew` class map, scripted-windows.md §2) | ≈ 10 | dialogue-ui §4–§10 bodies not yet read at instruction level |
| 4 Start + saves | splash, start screen (`TRunStart`), credits, Create Player, Open/Save/Save As/Backup/Revert, the file-backed overlay store, the `'Char'` stream and chunks, the prefs file, quit | ≈ 10 | the stream subclass extras (MED), the `'PICT'` preview and `'SCEN'` alias |
| 5 Items + shops | Character windows (three panes, paper doll, slots, `CanDrop`), containers, drag and drop, give/take/drop/throw, weight, shops and haggling, services, training, theft | ≈ 10 | ui-play §2 list slots (MED) |
| 6 Fights + magic | combat (selector 28 chain), status, death, XP; spells, runes, alchemy, missiles/FX; party AI (`.ai` compiler, evaluator, strategy editor, `TAIDebug`); the cheat keys | ≈ 14 | magic.md §11 FX pixel callbacks; `TSpellFX::PassTime` |
| 7 The whole story | every remaining scripted window, teleport/transition, cut scenes, both endings; a scripted play-through harness | ≈ 8 + the play-through | quests-flags.md §5–§7 as the harness's checklist |
| 8 Windows + docs + release | SDL twin (BTX W-plan shape), music rendered once, the DOCMaker viewer (format read first), notarized DMG | ≈ 10 | the DOCMaker `Dk@P` format |

Each phase gets its own plan when its turn comes, written against what landed and after its research task; this
document gives each a card in the plan, not contracts.

## 7. How each part is proven

| part | machine proof | Ben's proof |
|---|---|---|
| decoders (Phase 0) | the census: 1,558 segments, 198 resources, 0 failures; every number pre-measured by probe; hostile-input tests; `lz.py`/`seg.py`/`rsrc.py` differentials | none (design §9) |
| script decoder | **parity**: `ScriptCanonical.text` of all 958 segments hashes equal to the committed list made by `script_canon.py` from `scriptdis.py`'s listings (22,166 lines, 34 mnemonics, flag histogram) | none |
| the VM (Phase 2) | (1) the decoder parity above proves the fetch; (2) **shape runs**: every class segment's selector-0 and selector-2 (name) methods run headless with a recording builtin table — no invalid opcode, the stack balanced at every return, the 0x400 slots never overflow, every character's name equals the 0x0201 string; (3) the nine under-supplied builtin calls read the stale slot the bank documents; (4) **the bank's worked examples become goldens**: combat.md §15 (one sword blow), magic.md §9 (Lesser Healing end to end), trade-economy.md §12 (buying a ruby from Atreus), dialogue.md §3.4 (1810's talk loop), quests-flags.md §5 (the crystal quality → the ending) — each a test that drives the real scripts with scripted input and asserts the state the bank derived; (5) a random-walk bot over Catamarca for a game day, asserting no VM error, no trap, the clock's hourly schedule passes | the Phase 2 gate: a day in Catamarca |
| the engine (movement, schedules, AI, pathfinding) | rules re-derived from the dump pinned by tests to the bank's numbers (busy 10/4, ±13 cells, 20-tick idle, F = 6, the schedule picker's wrap rule); the bot | Phase 1b and 2 gates |
| rendering | frame goldens of the Map window's offscreen for a fixed state (hash + PNG), one per Render step; the Catamarca screenshot's pixels compared on the map area (indexed, after palette match) with a counted mismatch budget the seat sets at 1a | Phase 1a gate, side by side |
| the desktop and windows | goldens of the composited screen at 640×480 and one large size (the `k` widening); the frame table (ui-toolkit §1) pinned | Phase 1a |
| sound and music | sample-exact PCM vs the stored samples; the mixer's rules pinned (16 voices, 0.875–1.125 pitch, `CalcStereo`); music: the 11 tunes' event lists pinned; what the synth does is Ben's ear | Phase 2 gate |
| saves | a 1999 save (if Ben has one) opens; a replica save re-opens byte-equal after a round trip; the original's `RestoreModel` order | Phase 4 gate |
| Windows | the BTX smoke-test shape; his brother's report | Phase 8 |

Suite growth: Phase 0b ends at 91; Phase 1 adds about 60; Phase 2 about 120 (the VM's shape runs are one test per
family, not per segment). The render goldens run in their own test target so a rules failure shows in seconds
(the Ferazel lesson, its audit ruling 11).

## 8. The HectorKit re-base — from 4ca2e18 to today's main

| fact | measured |
|---|---|
| Cythera's pin | 4ca2e18 (K1, D14, floor 322) |
| today's main | ef2c341, 9 commits later: D15 (`PCMPullSource`, `ShellMixer` stream voices, `SDLAudioOut(source:)`; HectorShell now depends on HectorAudio), D16 (`HectorInput` translator, `ShellGamepad`, `ShellView.padMapping`, HectorSDL gamepads), D17 (`ShellScalingPolicy.aspectFitNearest`); floor 370 |
| what Cythera imports | CytheraCore: HectorResources; CytheraRender: HectorGraphics, HectorAudio. D15 touched HectorAudio additively; the suite is green on ef2c341 (44/0/0, this session) |
| what Phase 1 will want | D15's mixer stream voice (the `TAudio` mixer runs as a pull source), D17's scaling policy as the shape for the new **resizable 1:1 canvas** mode, D16 is irrelevant until Ben asks for a pad |

**Ruling (Q1):** re-base now — C12 records `ef2c341`/floor 370 as the pin; every later Cythera gate accepts a
later clean HectorKit main at ≥ the recorded floor and records the new SHA (the Ferazel pass's rule, 2026-11-04),
so the kit never again drifts silently under a pin.

## 9. Questions for Ben (one round; a recommendation each; none blocks the plan being written)

| # | question | recommendation |
|---|---|---|
| Q1 | Re-base Cythera to HectorKit main ef2c341 now (floor 370), with the "later clean main accepted at ≥ floor" rule? | **Yes.** The suite is already green on it; Phase 1 needs D15 and D17. |
| Q2 | Text rendering: bake glyph sheets once on the Mac from the shipped fonts at the requested sizes (committed data, screenshot-checked), or write a TrueType/NFNT rasteriser? | **Bake.** The Font Manager's output is the target and neither route reproduces it exactly; baking is a day, a rasteriser is weeks; the screenshots judge the result. |
| Q3 | The next wave's shape: three Opus 5.5 orchestrator sessions — C8 + C9; C6 + C7 + C10; C11 + C12 + the re-base record — each closing with a chip; Fable only if a session hits a contraindication and asks you first? | **Yes.** The Phase 0 plan's tasks are small (two ⚑ tasks fit one session under the cap); this is the standing policy. |
| Q4 | D28 ruling 2 reads "Alaric walks"; the player (default name Bellerophon) is the one who walks. Record the correction? | **Yes**, as a wording fix in DECISIONS, nothing else changes. |
| Q5 | Split the first gate in two: 1a the still picture against the Catamarca screenshot, 1b walking with roofs lifting — two gates instead of one? | **Yes.** 1a is the design's own gate statement; it lets you judge the look before the movement code exists, and a wrong palette or frame costs one wave, not two. |

## 10. The audit of the built work (the plan's wave 0) — what it asked

Two read-only Opus 5.5 reviewers, in parallel: **A** data and world records (`CytheraCore` Data/Segments/Codec/World,
34 tests) — re-derive the cipher, the map body offset and side cap, the prop x/y extraction; check the locked
surface, the combat-AI routing trap, hostile prefixes, the overlay model against `AddFile`, the carried minors;
**B** render and pictures (`CytheraRender` Pixels + `CytheraCore` Art, 10 tests) — re-derive the compo-tile rule,
the sheet range and zero fill, the pix row padding, the FILT layout; check the palette's origin and transparency,
the 21 PICT outcomes and the opcode-walk duplicate, readiness for Phase 1, layering. Reports and the seat's
rulings: `docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md`.

## 11. Out of scope (unchanged from design §1)

Registration screens and the `Register Cythera` app, InputSprocket, CD audio, AppleEvents beyond launch/open,
`TSanity`, `Audt`, desktop-comment copying, iPad, a Remaster art mode, the scenario editor resources. In: the
cheat/debug keys and the Cythera Documentation viewer (D28 ruling 6).
