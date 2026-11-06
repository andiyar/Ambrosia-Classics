# Ferazel's Wand — design for the rest of the game (Phase 5 second half, Phase 6, release)

*Written 2026-11-04 by Claude Fable 5.1 in the seat, as the re-planning pass of `~/Developer/Toolkits/fable-kit/replan.md`
§5 (a looper project). Read-only on the code: nothing was built, the loop stays stopped. Companion documents:
the plan `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` and the audit
`docs/superpowers/audits/2026-11-04-ferazel-audit.md`. The standing rules it sits under: `CLAUDE.md`, the design
`docs/plans/2026-10-06-ferazel-design.md` (D26), the loop rulings D34 and D42, the Phase 5 plan
`docs/plans/2026-10-30-ferazel-phase5.md` (D44).*

## 0. The game in one paragraph

Ferazel's Wand (Ambrosia, 1999) is a side-scrolling platform adventure: Ferazel, a Habnabit, crosses a world map of 24
levels, each a tile map with placed sprites, picking up spells, items and keys, talking to NPCs, saving at save
points, fighting goblins, crawlers, bats and the rest, and beating five bosses on the way to Xichra's lair and the
victory screen. The replica loads the original's own data (levels, sheets, palettes, sounds, music, dialogs) and
transcribes every rule from the decompiled binary ("follow the binary"). It runs on the Mac (HectorShell) and on
Windows (HectorSDL), one Core, one Render, two thin shells. The rule for everything in this document is the Classics
rule: 100 % the original, no additions, no modern affordances; where the platform forces a departure it is named.

## 1. Where the port stands (the review, 2026-11-04)

### 1.1 Phase table

| phase (design §8) | state | evidence |
|---|---|---|
| 0 Data + decoders | done | census 1,108 items / 0 failures (G3, every wave end) |
| 1 Level 1 look | passed by Ben (D32, 2026-10-10) | — |
| 2 Ferazel moves | passed with notes (D39, 2026-10-25) | notes built (text smoothing; speed kept, Q9) |
| 3 Front end + saves | passed with notes (D39) | controller support added (D37) |
| 4 Spells + items | machine-closed run 30; **Ben's gate Q11 unanswered** | staged 4bca4bd, card in `Ferazel/WHAT-TO-EXPECT.md` |
| W Windows twin | machine-closed run 35; **Ben's gate Q14 unanswered**; Andrew (Windows tester) confirmed save, restore, level 1 → map → level 2 on a real PC | four Windows test builds published 2026-10-27…30 |
| 5 Enemies | **half built**: waves 5.0–5.2 merged (runs 37–41); wave 5.3's Bat class built and reviewed in run 42, unmerged (the run was stopped mid fix round) | 11 of 22 tasks merged; the loop's own gates green at every run |
| 6 Bosses + the rest of the levels | **not planned** — one row in design §8 | — |
| 7 Release | not planned | BTX's release recipe exists (`tools/package-btx-release.sh`, D25) |

### 1.2 Numbers from this session's own runs (main at 07bc11d, HectorKit at ef2c341 — see §1.4)

| check | result |
|---|---|
| `Ferazel/Core` suite (`swift test`) | **560 cases = 558 passed + 2 opt-in skips** (`VisitSweepTests.testVisitEveryObject`, `RandomPlayTests.testRandomPlay`), 0 failed — equals run 41's record; ~45 min wall beside three audit builds |
| `Ferazel/Windows` package suite (`swift test`, macOS-hosted) | **81 cases = 79 passed + 2 opt-in skips** (`WinVisitSweepTests`, `WinRandomPlayTests`), 0 failed — equals run 41's record |
| Mac app (`xcodegen generate && xcodebuild -scheme Ferazel build`) | BUILD SUCCEEDED, 0 errors, 5 warnings (none in Ferazel code) |
| worktrees | `loop-42-20261031-162344` kept, one unmerged commit 005058f (the Bat class, 9 tests, 2,272 lines over 15 files); `inspiring-cannon-e97ccd` (Deimos, Ben's); `gamepad-wt` (merged, Ben's) |
| loop | stopped (STOP file 2026-10-31 21:00); no looper process; run 42 ended exit 143 (killed by the stop), `progress=no` |

The counts the loop recorded at run 41's close were Core 560 (558 + 2 opt-in skips) and WinKit 81 (79 + 2).

### 1.3 Why the loop stopped — and what it was not

This pass was asked for because Castles had churned. Ferazel's record says something different: **the loop was
working.** Runs 36–41 each merged their two tasks with two Opus review legs and one fix round per MAJOR task; the
fix rounds were mutation-driven (the reviewers' mutation tables found 20–40 unpinned behaviours per class task,
every time, because implementers overstate their own kill counts) and no task was redone. Run 42 was killed at
21:00 by the STOP file while its Bat fix round was in flight — a stop, not a stall. There is no sub-task suffix
growth, no re-asked question, no `progress=no` before run 42.

What the loop cannot fix for itself, and what this pass is for:

1. **Nothing beyond Phase 5 has a plan.** Design §8 gives Phase 6 one row ("Warrior, Wizard, Chief, Fire Guardians,
   Xichra's lair, victory — gate: the whole game") and Phase 7 one row. Measured against the data, "the rest" is
   19 more levels carrying about 140 sprite types never placed on levels 1–5 and a dozen engine features whose header
   switches are all zero on levels 1–5 (§3). A loop planning run writes one phase plan from one design row; this
   pass gives it the whole remainder, split into gates Ben can play.
2. **HectorKit moved under the pin** (§1.4). The loop's first gate (G1: HectorKit clean at 35a85ba) now fails at
   reconcile, and the chip says "STOP, reconcile, record" for that. A ruling is needed before any run.
3. **Three of Ben's gates are queued unanswered** (Q11 Phase 4, Q14 Windows, Q16 Phase 5 choices). The loop carries
   on by D34, but every further phase builds on a base he has not played since Phase 3. This presentation asks for
   them together (§6).
4. **The suite is slow and will get slower.** The Core suite takes about 15 minutes warm, 25 cold, at 560 tests; the
   remainder adds roughly 350 more. Each run re-runs it several times (G2 per task, per reviewer, at reconcile). §5.4
   sets the rule for it.

### 1.4 HectorKit has moved past the Ferazel pin

`~/Developer/HectorKit` main is at **ef2c341** ("K1: ShellScalingPolicy.aspectFitNearest", 2026-11-02, the Castles
work, D6 there), one commit after **35a85ba**, the SHA every Ferazel gate pins (D44 Ruling 13: "no HectorKit change,
HK 35a85ba, floor 361"). 35a85ba is its ancestor; the tree is clean; HectorKit's own floor moved 361 → **370**. The
commit touches only `HectorShell` (scaling policy, three files) and its tests; `FerazelCore` imports
HectorResources and HectorInput only, so the Core suite is untouched; the Mac app links the new Shell and builds. The
Classics project uses HectorKit by local path, so every build on this machine already uses ef2c341 — this session's
numbers in §1.2 are against it. Ruling asked in §6 (Q-B); recommendation: Ferazel follows HectorKit main, each run
records the SHA and floor it built against at reconcile, and the "no HectorKit change" rule becomes "no HectorKit
change *by a Ferazel task*".

## 2. The shape of the program (built; the remainder fits it, nothing is reshaped)

Design §3 holds as built and is **not** reopened: `FerazelCore` (Foundation + HectorResources + HectorInput: rules,
sprite pool, player, physics, every class Handle, camera, particles' state, tables, saves, prefs, per-frame
`FrameOps`), `FerazelRender` (every byte of the 8-bit screen, the frame goldens, the Sound Tool), `Ferazel/Shared`
(the neutral driver both shells use), `Ferazel/App` (AppKit) and `Ferazel/Windows` (FerazelWinKit + FerazelWin on
HectorSDL). Seam types are locked (`FrameOps`, `DrawOp`, `SoundCue`, `MusicCue`, `InputActions`, `ShellRequest`,
`FerazelPrefs`, `SpriteHandler`); cases may be added, never renamed (Phase 5 Invariant 9).

Everything the remainder adds lands in the slots the Phase 5 plan's "Shared architecture" already named:

| what | where it goes | already there |
|---|---|---|
| each remaining enemy class | `Sources/FerazelCore/World/Enemies/<Class>.swift`, a `SpriteHandler` case, a `forClass` row | `.bat` … `.warrior` cases exist as named no-ops (EC); Walker, Crawler/Roach, AxGoblin, EnemyShot built |
| each boss | `World/Enemies/<Boss>.swift`; `BossArena` (LV5) for the lock, pan, gate and music | the Warrior's Setup is LV5's; the four others are `.inert` until Phase 6 |
| later-level engine features | the module that owns the original routine: OmniPx (`World/OmniPx.swift`, OX), fire/flame and ripple (`FerazelRender/Frame/ParallaxBlitter`), auto-scroll and side push (`Camera/`), CLUT animation (`FerazelRender/Color`), the horizon strip's draw mode 8 (`FerazelRender/Frame/SpriteBlitter`) | the refusal list in `SpriteBlitter.swift:43–50` and `DrawModeAuditTests` name every one of them as "unreachable in levels 1–4" |
| new Box / Background / Bonus / Platform / Rope types | the arms of the existing class files (`World/Movers/BoxSprite.swift`, `BackgroundSprite.swift`, `BonusSprite.swift`, `PlatformSprite.swift`, `RopeSprite.swift`) | each has `notTranscribed` / `later:` arms for the types not placed on levels 1–5 |
| a level opening | `Front/BuiltLevels.swift` (`range`), `LevelRun.swift`'s picture-cache marks, `Tests/FerazelCoreTests/Level<N>Tests.swift` | the "level N is not built yet" report; LV3/LV4 are the exemplar tasks |
| victory | `Front/GameFlow.swift` (a new flow state) + `FerazelRender/Screens/` | the stage screens and the death screen are the exemplars |
| release | `tools/package-ferazel-release.sh` (new, from BTX's), `docs/release/ferazel-1.0.md`, `releases/ferazel-1.0/` | BTX 1.0/1.1 recipe (D25) |

No new target, no `Package.swift` change, no HectorKit change by a Ferazel task.

## 3. What remains, measured against the data

### 3.1 The 24 levels

| id | name | state | what is new on it (types never placed on levels 1–5, from `gap-ledger/placements-all.tsv`) and the engine switches in its header |
|---|---|---|---|
| 1–4 | A Scent Of Peril, Central Caverns, Western Reaches, Eastern Reaches | built; enemies alive (Phase 5 waves 5.1–5.2); Bats, Frogs, Blobs pending | — |
| 5 | Manditraki Warrior | LV5 (Phase 5 wave 5.5): arena, OmniPx mode 2, the Warrior stand-in | boss |
| 10 | Unemployed In Greenland | not built | 23 types (10 Background, 7 Box, Walker 1750, swarm 1869, geyser 1440, Rope 3020, Platform 1407); horizon strip (draw mode 8), wind cells |
| 11 | River of Fears | not built | 22 types (bats 1851, Box ×10); parallax ripple; "submerged tiles tinted" flag |
| 15 | Storm Valley | not built | 21 types (Gremlin 1770, Dillo 1870, Background ×12); OmniPx rain (mode 1); constant side push −320 |
| 18 | Goblin Chief | not built | **boss** Chief 1910; ripple; second arena bound |
| 20 | Hangnabit | not built | 17 types (Bonus ×7, Gremlin) |
| 21 | Obfuscation & Edification | not built | 23 types (pipes 1490–1493, Box ×13, bats 1742/1860) |
| 22 | The Labyrinth | not built | 26 types (Dillo 1871, Blob 1732, Box ×4, Background ×10) |
| 25 | Manditraki Wizard | not built | **boss** Wizard 1830; OmniPx; arena bounds 592 / 1384 |
| 30 | Flash Freeze | not built | 21 types; level-wide "in liquid" flag; ice friction 220 |
| 31 | Iceconoclasm | not built | 26 types; the same flag |
| 40 | Parched Earth | not built | 17 types; the countdown timer 2907 (digits) |
| 45 | The Dig | not built | 12 types |
| 50 | Fire In The Hole | not built | 23 types (Salamander 1810, geyser 1442); CLUT animation (mode 1, 48 entries, period 180) |
| 51 | If You Can't Stand The Heat… | not built | 19 types; auto-scroll x 768; CLUT animation (period 56) |
| 52 | Out of the Frying Pan | not built | 17 types; fire backdrop mode 1; auto-scroll y 640 |
| 55 | Fire Guardians | not built | **boss** Demon 1920 (two guardians); fire backdrop mode 2; never locks its arena (bosses-3 §11) |
| 62 | Ends of the Earth | not built | 36 types (Crab 1892, Floater/Wraith 1780, Background ×16, Box ×8) |
| 67 | Xichra's Lair | not built | **Xichra** 1990; three cannons, minions, lair gates; CLUT animation; music 28 |
| 70 | Purple Haze | not built | 15 types; OmniPx mode 6 (interlace) |

(Names from `STR# 1000`, INDEX l. 115–119.)

### 3.2 The engine features whose switch is zero on every built level

From `gap-ledger/routines-classified.tsv` (27 "later-level" routines) and `world-data-format.md` §3.2:

| feature | header / type | first level | original routines | port today |
|---|---|---|---|---|
| OmniPx modes 2/4/5 (moving backdrop) | `0x26c7` | 5, 25 | `.SetupOmniPx` … `.KillOmniPx` | Phase 5 task OX |
| OmniPx rain (mode 1) and interlace (mode 6) | `0x26c7` | 15, 70 | `.GenerateRain`, `.InterlaceBlit128` | ⚑ audit: **not** refused — level 15 or 70 would open silently with no rain / no interlace; only the draw-mode audit's header check (`DrawModeAuditTests.swift:1079`) knows; task PT makes it a refusal at level open until 6A builds it |
| horizon strip, draw mode 8 | `0x2716` | 10 | `.BlitEncFaceBehindTiles*` | refused only once a strip sprite is set up; ⚑ audit: the draw-mode audit has no header check for `0x2716` (level 10 could open with no strip and pass) — task PT adds it |
| wind cells | overlay cells | 10 | `.LookupModedImpulse` | not built |
| parallax ripple | `0x26ca` | 11, 18 | `.RipplePxBackOffsets` | not built |
| constant side push | `0x272c` | 15 | in `.HandlePlayerSprite` | not built |
| auto-scroll (x, y, marker sprites) | `0x2726`–`0x272a` | 51, 52 | `.SetupLevelSprites`' marker arm, `.FindUpperLeftCorner` | not built |
| fire backdrop + flame buffer | `0x2722` | 52, 55 | `.LoadCoolingMap`, `.Flame*`, `.DoubleBlitPPCParallaxOneLayerFire`, `.MyRandom` | refused |
| CLUT animation | `0x2730`–`0x2736` | 50, 51, 67 | `.AnimateCLUT` | not built (bosses-3 §9 reads it in full) |
| level-wide liquid flag, tinted submerged tiles | `0x26cd`, `0x26c6` | 30/31, 11 | in the player and tile draws | not built |
| countdown digits | type 2907 | 40 | `.UpdateDigits`, Effect ids | not built |
| programmed paths for cannons / maces | cannon p1 ≠ 0, mace modes 1–2 | later | `.SetupProgrammedPath`, `.HandleProgrammedPath` | **built by BA** (run 42, unmerged) for the path bats — the cannon/mace arms remain |
| rope bridge, trees, clouds, rotating blade, falling rocks, spiked balls, carpet, snowball, table | 1466, 0xc08…, 0xb4a…, 0xbf4, 0x433/0x434, 0x5c3/0x5c4, 0x438/0x439, 0xbfe, 0xb71 | 10–62 | arms of the Box / Background Handles, `.SectLineSegs` | `notTranscribed` arms |
| water kinds 206–209 | tile kinds | later | water tables | refused |
| victory | after Xichra | 67 | `.Victory`, `.CopyVictoryStitch`, `.CreditScreen` | not built |

### 3.3 The bosses (bank: bosses.md, -2, -3 — all HIGH)

| boss | level | HP (p4 = 1) | what it does, in short | kill |
|---|---|---|---|---|
| Manditraki Warrior | 5 | 2000 | walks the arena, lays eggs, random attacks, drops three falling crates on its first frames | death frames, burn-away, thunder, shake, flash, gate opens, track 30 |
| Goblin Chief | 18 | 2000 | state machine, random cries, the boss grab (`PlayerStates.swift:371`) | same sequence |
| Manditraki Wizard | 25 | 1000 | state machine (eleven states), projectiles | same |
| Fire Guardians (Demon) | 55 | 2000 ×2 | two guardians (partner at x − p3·32), segments, fire shots; the arena never locks | same, +1000 score each |
| Xichra | 67 | 5000 | floats, wings, phases, three cannons launching Fire seeds, minions, lair gates (p1 = 0) | ends the game → victory |

The arena framework (lock, pan, camera bounds, the p1 −1 gate, the boss-music rule) is LV5's and is reused by 18, 25
and 55; the kill sequence is common (`.HandleBurn` → Kill proc). `BossArena.noBossAlive` and the save write-back
(`+0xea` clears the placement flag: a killed boss is gone for good, bosses §1.4) already have their slots.

### 3.4 What remains of Phase 5 (plan D44, unchanged except as the audit rules)

| task | status | notes |
|---|---|---|
| BA Bat class | built + two review legs in run 42 (MERGEABLE / MERGEABLE WITH FIXES: 40 unpinned behaviours — ⚑ audit C: about 28 real, five on a type bound the class never sees; three minor findings, one of them wrong); fix round never ran | resume: cherry-pick 005058f, run the fix round as a tests-only round, re-review, merge |
| FR Frog + Salamander, BL Blob + Crab | planned, bite-sized in the Phase 5 plan | wave 5.3 end: GE on levels 1–4 |
| GF Gremlin + Wraith, DL Dillo, GY geysers, PI pipes | planned | all unreachable until Phase 6 opens their levels (Q16 (5), default yes) |
| OX OmniPx 2/4/5, LV5 level 5 | planned | wave 5.5 end: GE on levels 1–5 both shells |
| A5 phase end | planned | gate card "through the first boss door" → Ben's Q17 |

### 3.5 Sizes

| piece | tasks | runs (2 tasks a run, 3 when at most one is MAJOR) | tests added (ladder) |
|---|---|---|---|
| Phase 5 second half (§3.4) | 10 (+ BA's fix round) | 6 | Core 560 → ~618, WinKit 81 |
| Phase 6A — the engine features of levels 10–22 and those levels enterable, the Goblin Chief | ~14 | ~8 | ~+90 |
| Phase 6B — levels 25–52 (the Wizard, ice, timer, CLUT animation, auto-scroll, fire) | ~12 | ~7 | ~+80 |
| Phase 6C — levels 55–70 (the Fire Guardians, the Crab's level, Xichra's lair, victory) | ~10 | ~6 | ~+70 |
| release (Mac DMG notarized + Windows zip, README) | 1 attended session | — | — |
| **total** | **~47** | **~27 loop runs** | Core ~860 |

The Phase 6 counts are estimates from the type and routine census; the plan's research wave (R1–R3) replaces them
with measured task lists before any 6A build task is dispatched.

## 4. Faithful, ruled, or a platform departure

**Faithful (the default, every rule from the binary):** every enemy and boss routine, every later-level feature in
§3.2, the arena and music rules, the victory sequence, the 24 levels' data as shipped — all transcribed from the
dump with the bank as the map and the dump as the authority. The existing rulings stand verbatim: D26 (design), D33,
D35, D38, D43, D44 (phase plans), D39–D42 (Ben's gates and launch rule).

**Ruled by the seat under the 100 % rule (recorded in D45 on Ben's go, each one "as read" unless he says otherwise):**

| # | ruling | why |
|---|---|---|
| R1 | Phase 6 is three gated phases 6A / 6B / 6C (§3.5), each ending in a staged build and a card, not one "whole game" gate | a 27-run phase with one gate would run for weeks on a base Ben has not played; §8's gate order ("front end early") argues for more, smaller gates |
| R2 | the Dillo stays a Phase 5 task (DL), as D44 plans it; the gap ledger's "phase 6 (boss)" label is wrong (the Dillo is an enemy class placed on 15 and 22, enemies-ground §6) | plan authority (D44) and the bank |
| R3 | OmniPx rain / interlace, the fire backdrop, ripple, CLUT animation and the horizon strip are **engine tasks of their own**, each proven by a frame golden on the first level that uses it, built before that level's "enterable" task | a level task that also builds an engine feature is what blew up LV3's review (run 29: the cache never extended) |
| R4 | "level N enterable" tasks stay the unit for opening levels (LV3/LV4/LV5 shape: every record set up, the picture cache marked, the load bar counted, a `Level<N>Tests` file, the visit sweep and the bot extended to it) — one task may open two adjacent levels when neither adds a class or an engine feature | measured: LV3 + LV4 each fit one run |
| R5 | the Bat's `ProgrammedPath` (BA) is the one implementation; the cannon p1 ≠ 0 and mace mode 1–2 arms are added to it by the task that first needs them, never a second copy. ⚑ audit: BAf moves it to `World/Movers/ProgrammedPath.swift` and adds the mode 10/11 body and the "no radius" flag for p1 110/111 (M l. 39307–39309, 39446–39466) | one routine in the original, called by four classes | **⚑ run 43 (BAf, built 60d92f7): the mode-10/11 Handle body and the 1xx flag landed; the flag zeroes the swing speed, not the radius.**
| R6 | the Warrior's Phase 6 task replaces the LV5 stand-in in place (same file, the ◇ markers removed), and the switch-off check of ◈ applies: with its Handle stubbed back, LV5's goldens return. ⚑ audit (ruling 1): **the switch-off check is "stub the class's Handle body with one local patch"** — never "set the `forClass` row to `.inert`", which switches nothing off because every class Setup stores its own handler | the ◈ discipline |
| R7 | every Phase 6 level task runs `tools/ferazel-random-play.sh core` on its level (quick mode) and the visit sweep covers it; a phase end runs both on both shells over every built level (Ruling 6 of D44 extended) | the one check that has caught real quits (the sparkle, run 29's cache) |
| R8 | victory is one task: the `.Victory` sequence, the stitch copy and the credit screen, as a `GameFlow` state, with a frame golden per screen | front-end shape of Phase 3 |

**Platform departures (already disclosed, design §7, none new):** no display switching, no CD check, no
InputSprocket, the menu bar and the Windows window (D21/D43), prefs and saves under Application Support, the kit's
mixer and music player, the DEBUG-only data alert. Known deviations carried: voice eviction (D44 KD1), the tint
colours through the replica's colour search (LOW), the tint's gamma (MED), the 30-step cap (D39 Q9).

## 5. How each part is proven

| part | machine proof (the loop closes these alone) | Ben's proof |
|---|---|---|
| an enemy or boss class | its `<Class>Tests` (Setup rows pinned to the dump's writes, the state machine, hits, kill, coins/score), the mutation-table review leg (two Opus legs per ⚑ task), the switch-off check for any golden it moves (◈), the quick bot on its level | the gate card names what he should see it do |
| an engine feature (§3.2) | a frame golden on its first level (both shells' references), a `DrawModeAuditTests` row moved from "refused" to "drawn", a test per rule the bank states | "does the sky move / the fire burn like the video" |
| a level enterable | `Level<N>Tests.testLevel<N>SetsUpEveryRecord` (no `notTranscribed` record), the load-bar count, the face-load tests (`BootFacesTests`, `FaceTests.testEverySpawnableTypeHasSheet`), the visit sweep and the bot on it | he walks it |
| a boss fight | the class tests + `BossArena` tests (lock, pan, gate, music) + a scripted-keys kill test (`LevelRun` with a key script that beats it under a pinned seed; the kill's four writes and track 30) | he beats it |
| a phase (6A/6B/6C) | GE: visit sweep both shells, bot both shells over every built level, face-load tests, the draw-mode audit; Proof B (the whole suite in CrossOver, muted, by day); the FABLE-GRADE phase review over the phase diff + the card; both builds staged | the gate card, Mac and Windows |
| the release | notarize + staple, the DMG and zip re-downloaded and hash-checked, `releases/ferazel-1.0/` in the main checkout (memory rule) | he tries the downloaded DMG and says "publish" (as BTX 1.0) |

### 5.4 The suite's growth (seat rule, not a question)

The Core suite is at ~560 tests / ~15 min warm; the remainder takes it to ~860. Rules for every brief from now on,
already in the chip in part: subagents batch `swift test --filter` by class and never end a turn while anything runs;
the seat runs the whole suite once per task at merge in a background shell with a long timeout, from a `git
archive` copy with its own `WIN_BUILD_ROOT`; two heavy suites never run at once (Ben's RAM rule, 8f7746f). ⚑ audit (ruling 11): the render
tests are already their own target and are the slow part (128 tests, 716 s, led by the draw-mode audit at 147 s; the
432 rules tests take 61 s) — so G2 is run as **two commands in every brief**, `swift test --filter FerazelCoreTests`
first (a rules failure shows in a minute), then `--filter FerazelRenderTests`; the totals are the same. No split task.

## 6. Questions for Ben (one round; each with a recommendation; none blocks the plan being written)

| # | question | options | recommendation |
|---|---|---|---|
| Q-A | The three gates waiting on you: Q11 (Phase 4 spells + items), Q14 (Windows), Q16 (Phase 5's five defaults). | (a) pass / pass with notes / fail for each, now; (b) leave them queued, the loop carries on (D34) | (a) — the next phases build on them; notes become a small named wave first, as D39's did |
| Q-B | HectorKit moved one commit past Ferazel's pin (Castles' scaling change, Shell only; §1.4). | (a) Ferazel follows HectorKit main from now on: each run records the SHA and floor at reconcile; "no HK change" means "by a Ferazel task"; (b) pin Ferazel to 35a85ba through a HectorKit worktree | (a) — one shared kit, one truth; the change is Shell-only and builds |
| Q-C | Run 42's Bat class (built, two legs passed, fix round unfinished). | (a) resume it: cherry-pick, finish the fix round, re-review, merge — the plan's wave 1; (b) rebuild it | (a) |
| Q-D | Phase 6 as three gated phases (6A levels 10–22 + the Chief; 6B 25–52 + the Wizard; 6C 55–70 + the Guardians, Xichra, victory) instead of one "whole game" gate. | (a) three gates; (b) one gate at the end; (c) a different cut (say which) | (a) — each is 6–8 runs and ends in something you can play |
| Q-E | Release shape at the end: a notarized Mac DMG + Windows zip as one GitHub release `ferazel-1.0`, BTX's recipe. | (a) yes; (b) a different name / only Mac first | (a) |

Answering Q-A with notes changes the next wave (the notes go first); the others change nothing in the plan's next
wave. **None of these answers restarts the loop** (replan.md §2) — that is a separate "go".

## 7. The audit of the built work (the plan's wave 0) — what it asks

Five read-only reviewers (Opus 5.5, `fk-reviewer`), each with this spec, one area, five to eight questions, two or
three rules re-derived by hand from the dump:

| area | files | the questions, in short |
|---|---|---|
| A enemy foundation + shots | `World/Enemies/EnemyCommon.swift`, `EnemyShot.swift`, `Particles/Burn.swift`, `Smite.swift`; their tests | the counting window, the Kill idiom, the shield block, the burn's Kill timing, the coin-drop set — re-derived; are the `.inert` cases still dormant for the unbuilt classes |
| B the ground enemies | `Walker.swift`, `AxGoblin.swift`, `CrawlerRoach.swift`, `SetupFaces.swift`; tests | tier table, the 1760 boulder arm, the Crawler leap cooldown, the Roach `+0x154` — re-derived; do the carried LOW items matter |
| C the Bat branch (unmerged) | worktree `loop-42-20261031-162344`, `Bat.swift`, `ProgrammedPath`; the two review reports in `.looper/logs/run-42.log` | does the branch rebase clean on main; which of the 40 survivors are real; is `ProgrammedPath` shaped for the cannon/mace arms (R5) |
| D the loop's own gates and tools | `tools/ferazel-random-play.sh`, `tools/ferazel-visit-sweep.sh`, `tools/windows/proof-b-ferazel.sh`, `smoke-ferazel-win.sh`, `DrawModeAuditTests`, `BootFacesTests`, the golden tests, `.looper/config.sh`, `docs/NEXT.md` | would each check catch a quit on a level 10 feature; what does the HK drift break; the suite's timing per class; the plan's ladder arithmetic |
| E the front end against 24 levels | `Front/GameFlow.swift`, `WorldMapRun.swift`, `BuiltLevels.swift`, `StageScreens.swift`, `Saves/`, `MapRenderer.swift` | do the map graph, unlock rule, chapter cards, stage stats and the save block already carry every node and level; what in them is keyed on `1...5` |

Their findings and the seat's rulings are in the audit file; the spec and the plan's wave 1 are corrected from it
(the corrections are marked ⚑ audit in both). **Done 2026-11-04:** 22 rulings; every re-derived rule matched the
binary; no built code is redone; one small design seam is (the built-level list, ruling 8).

## 8. Out of scope (unchanged from design §1)

iPad, a Remaster art mode, a level editor, the Documentation app, resolution switching, the CD check, InputSprocket
configuration, the debug/cheat keys, AppleEvents, movie capture, a third-party world file. Nothing else the original
has is out.
