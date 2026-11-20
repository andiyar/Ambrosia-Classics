# STATE — Ambrosia Classics — 2026-11-11

Settled history lives in docs/STATE-history.md.

> Live state only, one dated block per game. This file is the one live state for every game, Ferazel's included (the
> chip `docs/NEXT.md` holds only the next run's instructions). Each close **replaces** its game's block with today's
> numbers and open items and moves anything settled to the top of `docs/STATE-history.md`; it never appends a run story
> here. Forks go in `docs/DECISIONS.md`, narrative in the handoff. Re-verify before acting.

## Ferazel's Wand — 2026-11-20 (attended run 55 closed: the conversations and chapter cards of levels 10–22 proven; run 56 next)

- **Where it stands:** Phase 5 "Enemies" is closed on the machine side — **Ben's gate pending (Q18)**. Phase 6A
  "through the Goblin Chief" is being built (the plan: "Wave 5 — Phase 6A" in the one plan file; rulings D46–D49, D51,
  D53). **Wave 6A.1 is built**: on level 5 the Warrior is a real boss, beaten by pushing crates onto him. **Wave 6A.2
  so far:** the test-only level fixture, the horizon strip, wind, rotating cannons, trees, the river ripple, the
  scenery, teleporters, furniture and talking characters of levels 10–22, and in run 55 **6A-MC**: the six
  conversations of levels 10–22 run to their end with the right portraits, and the two chapter cards (before level 10
  and before level 22) draw — proven by tests, no game code needed changing. None of this is visible to a player yet:
  no level past 5 opens until 6A-L10L11, which is next.
- **Launch checks: none owed.** Run 53 ran both by day, muted (2026-11-15, 09:14–09:27): Proof B 690 / 0 / 3 / 0 of
  693 (at 44cb75a, trees in) and the Mac SDL smoke (main menu identical, exit 0). The next Proof B is wave 6A.2's end.
- **Run 55 (2026-11-20) built one task** (6A-MC) and stopped there on purpose: the account's weekly usage limit stood
  at 92% mid-run (resets 2026-11-23), and opening levels 10 and 11 is one large task that must not be split from its
  long checks. It goes whole to run 56.
- **Windows test build 5 is with Andrew** (Ben asked, 2026-11-18): GitHub pre-release `ferazel-windows-test-5`, staged
  from 02717f8 (run 53's game code; the Windows card gained a "test build 5" section: the Warrior is real, levels past
  5 closed). Before it went up: WinKit 82 / 0 / 2, visit sweep 3,488 x 2 rows 0, bot 108,000 x 2 failures 0, the zip's
  boot check (GW6) three screens identical. The zip and its checksum are in `releases/ferazel-windows-test-5/`. His
  report is the Windows half of Q18; Ben's Mac verdict is still open. The Desktop builds were not replaced.
- **Staged builds on the Desktop are old** (game code as e9183ce, run 50): they still show the stand-in Warrior. The
  next stage is the 6A phase end unless Ben asks for one.
- **Next:** run 56 = 6A-L10L11 ⚑ (levels 10 and 11 open — the first new levels a player can see) with the wave 6A.2
  end: Core 716 → 722, WinKit 82 → 84. It does not wait for Ben's verdict. Wave 6A.2's end owes a Proof B by day,
  muted. **Best started after the weekly limit resets (2026-11-23)** — it is the largest task of the wave.
- **The plan:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` (self-contained); the design:
  `docs/superpowers/specs/2026-11-04-ferazel-remainder-design.md`.
- **Ben's gates:** Phase 1 passed; Phases 2 and 3 passed with notes; Phase 4 passed (Fireball note) and the Windows
  twin passed on Andrew's word (2026-11-07); **Phase 5 waiting (Q18)**. Then three gated Phase 6 parts (6A to the Goblin
  Chief, 6B to the Wizard and the fire, 6C the whole game), then one release `ferazel-1.0`.
- **Current numbers** (Core suite: the seat's own run at 988a1e1, 2026-11-20, in four foreground parts; G5 / GW1 / GW3 /
  GW4: the implementer's at b999329; Proof B and the Mac SDL smoke: run 53 at 44cb75a; WinKit and the census: run 52
  at 4134bbc — no Shared, Windows, Resources or decoder change since; the full sweep and bot: run 48, older code):

| gate | value |
|---|---|
| Ferazel/Core suite (G2) | **716** = 551 rules + 165 render; 714 passed, 0 failed, 2 opt-in skips by name: `FerazelRenderTests.VisitSweepTests testVisitEveryObject`, `FerazelRenderTests.RandomPlayTests testRandomPlay` |
| FerazelWinKit (GW2) | **82**; 80 passed, 0 failed, 2 opt-in skips (`WinVisitSweepTests testVisitEveryObjectThroughWinGame`, `WinRandomPlayTests testRandomPlayThroughWinGame`) |
| census (G3) | items 1,108 decoded, failures 0 (run 52) |
| level 5 quick checks (run 52, core) | bot: levels 1, seeds 4, steps 7200, deaths 1, exits 17, failures 0; visit sweep: 128 visits, rows 0, exit 0 |
| visit sweep (GE, levels 1–5, both shells) | core 3,488 visits, windows 3,488 visits, rows 0 on both — run 48, older code |
| random-play bot (GE, levels 1–5, both shells) | core and windows each: steps 108,000, failures 0 — run 48, older code |
| Proof B in CrossOver, muted (GWB) | **690 / 0 / 3 / 0 of 693** (run 53, at 44cb75a) |
| Mac SDL smoke (GW4R) | main menu identical, exit 0, `video=dummy audio=none` (run 53); GW6 and G9M last passed in run 50 |
| GW1 / GW3 / GW4 / G5 | 0 then 2 / 0 then 1 / Build complete! / BUILD SUCCEEDED |
| HectorKit (G1) | main **ef2c341**, clean; zero-skip executed **370**; Ferazel follows HectorKit main |
| ladder from here | 716 → L10L11 722 (run 56) … 814 at the 6A end; WinKit 82 → 90 |

- **Goldens (◈):** level 5's pins moved in 6A-W1 for the three crates — init 46 / `0xb039da66a884cb8a` (held), f30 58 /
  `0x1142f7a252aecfcd`, f120 58 / `0x9806297cea4531f2`; nothing else moved. The Warrior's scripted fight is pinned:
  HP 0 at game frame 4966, Kill at 5051. New fixture goldens (run 52): level 21's fixture first frame
  `fb80e30a68e4efb7`; level 10's strip, two frames, `e471fa3eeca627d3` (tick 1612) and `e8fc9d1805afb1d5` (tick 1658);
  level 10's wind `c9ad94cdb8b2d287` (trace `20b0a649c605b4d0`); level 10's cannons `1f159e3178d4733` (traces
  `a94f59ac15d64d04`, `2970c03ffb33c302`); level 10's tree `d7ba88433f138e72` (run 53; planting stubbed
  `707aa87324dfbee3`). All other values as the plan's "Goldens" paragraph.
  New in run 54: level 11's ripple `c92fbe9fb87250c3` (fixture, player started at (16299, 600), tick 143; the fill
  stubbed `974417c1b079fa29`; the submerged flag forced off `7c7042ee30a1f6d3`). Level 22's load-bar count moved for
  one more cached picture: [33, 168, 336, 33] → [34, 169, 338, 34] (the card named it).
  New in run 55: chapter card 2 (level 10) `f33072b0df2cab4d`; chapter card 5 (level 22) `517ec825dbca68cc`.
- **Waiting on Ben (QUESTIONS.md "Open"; nothing blocks; none answered at run 55's start):** **Q18 (the Phase 5
  gate)**, Q19 (three small choices in the 6A plan), Q17, Q16 (defaults stand), Q15's follow-ups, Q13.
- **Worktrees:** run 55's `sharp-yonath-db4807` was removed at its close. `compassionate-leavitt-7ca958` is run 53's (merged; it was run 49's before). `gallant-brahmagupta-56ed81`
  (run 52), `eager-fermat-db9ed9` (run 51), `hungry-bun-395f55` (run 50; `out/` holds the latest stages), `nifty-mendel-0ad40e` (run 48),
  `ferazel-run-47-e0431c` and `ferazel-run-44-7428b3` are finished and merged — Ben or their sessions remove them.
  The others belong to other sessions.
- **The sweep and the bot are guarded (2026-11-10):** both scripts kill any worker past `MAX_WORKER_MB` (4096) and
  brake below `MIN_RUNNING_FREE_PCT` (15) free memory, with a failure row. Stop a background run with a plain
  `kill <script pid>` — never `kill -9` / `pkill -9`. A `memory` row is a leak to fix, never a limit to raise. A
  background shell that chains the sweep and then the bot starts the bot when the sweep is killed: stop the outer
  shell too.
- **Known deviation of muted launches (D44 As built run 48 (d)):** a muted run draws the random stream differently
  from an audible one; boot checks only.
- **Open carries** [LOW unless marked]:
  - From run 55: the record a level-21 conversation arms (283) is proven as a save write only — its appearing on a
    revisit is the level-21 task's to check; the conversation test counts a portrait as loaded when it is drawn and
    its picture exists (nothing decodes it there); three small decoders of a picture's size exist (one in the game,
    one in each test target).
  - From run 54: mirrored decorations with no touchable area keep an all-zero rectangle where the original stores a
    mirrored (still empty) one, which puts that object's centre one picture-width to the left of the original's;
    nothing reads it, and matching it would move two pinned level 1–5 values (`BoxRopeTests`, the hot-rect hash in
    `BootFacesTests`) — D53.2, a marked task if ever wanted; five records of the Box scenery types on levels 50 and 70
    and the teleporter / furniture / character records on levels 30, 31, 40 and 70 set up but have no level test yet;
    level 40's nine teleporters all point at record 89, which points at itself — check when level 40 opens; the
    teleporter sheet test copies a rule that lives in the Render target (can drift); the ripple's wrapped-phase refusal
    is proven by arithmetic only (unreachable: 2^23 frames in one level); the ripple's every-call add runs one step
    earlier than the original's (nothing can observe it); level 11's own first frame will not show the ripple (the
    camera never gets low enough from the level's start) — the fixture picture is the ripple's only picture.
  - From run 53: no test takes a tree off screen and back (idle, re-spawn, re-plant) — the level-10 task's sweep is
    the first to; the audit's tree-mirror rows cannot fail until a tree level runs in the audit; a tree branch at
    the wrong layer is held by one unit test only, not by the golden; the ledger's `--check` proves line anchors,
    not the script's model (a task that builds a refused type must give the script a built arm).
  - From run 52: the staged builds on the Desktop are older than main and now differ visibly (the Warrior fights); rope
    segments check the 700-record cap outside `newSprite`, so `refusedSpawns` does not count them; no other enemy's
    hit row has the Warrior's "face bounds handed to the Hit" pin; two `preconditionFailure`s in `CachedFaces`
    (`set` / `single`, programmer errors only) are outside the trap census; the Chief's starting fight script (boss
    contract §3.9) is unproven — 6A-CH2 first finds how that fight is won (D49.1); the blitters have no bounds check
    (a policy for all of them); `WaterEffects.swift:40` still says "wind on levels 10, 20 and 52" (52 has dust, not
    wind); the engine contract's `SpriteSlot.swift:443` anchor is now :449; levels 1–5 are guarded against stray wind
    by the wind tests and the cell census, not by their pictures (level 1 has 20 odd overlay cells, level 3 two).
  - From run 51: the ledger script's own notes and the ledger's §8(b) still say "0x5d0" and "not in CachedFaces" in
    places (hand-written text); the first task that marks a 0x46a record has five named follow-ups (6A-CF's As
    executed); a bot run with no `FERAZEL_BOT_LEVELS` has no self-test row; 6A-CF's review item 10 (a citation
    comment) was left.
  - From run 48's cross-check: a force-kill by pattern (`pkill -9`) of the sweep or bot leaves its test process
    unwatched — never force-kill, plain `kill <script pid>` only; sweep workers have no time limit (the bot has one);
    the two scripts' release builds run outside the memory watch; parent/child sprite links across idling for the classes first placed after level 5 are unreviewed (look when 6A
    places them); the smoke script's three wake counts are still a second copy (a drift fails loudly); the older
    sections of both cards still say "1997" (the data says © 2000 for 1.0.3).
  - From the watchdog's last review (2026-11-10; all over-cautious or unlikely, none lets a worker run unguarded on a
    real Mac): when the wait before a worker start gives up it pulls the whole brake, killing healthy running workers
    (should-fix); if both `ps` and `top` give no reading a worker measures 0 MB and is never killed; the bot takes
    defaults for bot settings that are set but empty; `FERAZEL_VISIT_LIMIT` is not validated; huge limit values are
    accepted; the sweep does not clear a reused `OUT`; a worker-exit comment in `tools/ferazel-worker-watchdog.sh`
    overstates when the cleanup runs; the release test covers the sweep's game wrapper only (the bot's has the same shape).
  - From run 47: the second camera bound and the 0x7f60 right-opening bound are unreachable on level 5 (untested); `try!` at
    `GremlinFloater.swift:298` (safe: Bonus setup throws only for 0xc25 / out-of-table) is outside the census; the
    `setupPipe` p2 write-back is pinned on the helper's return only (level 21's task asserts it in `w.records`).
  - From run 46: a census row marked "trap: unreachable" is not checked to point at a trap
    (`DrawModeAuditTests.swift`); the failure message says "throw" for traps; `try!` ×3 and `assert`
    (`FrameRenderer.swift`) are not counted by the census. `setupPipe` is not wired into level spawn — level 21's task.
  - From runs 38–41: the ceiling Crawler keeps the stand-in face 0x6b0 from Setup; both Crawler/Roach Hits read the
    shot-kill light slot before `.KillPlayerShot`'s cleanup; the `+0x160` audit row excludes `AxGoblin.swift` by file;
    the Walker Hit's shot-kill light recolour may belong to the Walker's own light; the egg's 0.9 / −0.15 constants are
    unchecked against the data section; the Setup-face fallback width for 0x6a5/0x6a6 is the whole picture; the airborne
    face's `onSprite` term is unpinned; the Dillo coin count is asserted as a range; the bot saves once per 16 runs;
    `try!` at `PlayerStates.swift:291`; the orb argument check
    covers `Shots/` only.
  - Readings the machine cannot prove [MED]: voice eviction is not modelled in Core's `SoundVoices`; the underwater tint
    is applied as screen gamma; the OmniPx backdrop's look; the text smoothing mix is linear and its 14 pt threshold
    read from the Let's Play; the tint tables' colours [LOW].
  - Older small carries from Phases 2–4: listed in the history file's Snapshot B; each closes when a task next touches
    its file.

## Deimos Rising — 2026-11-20 (Phase 3 staged; Ben's gates 2 and 3 both wait on the one app)

- **Where it stands:** Phase 1 "level 1 look" gate passed 2026-10-07. Phase 2 "level 1 plays" and **Phase 3 "the
  campaign" are both built, merged to local main (not pushed) and staged as ONE app**: `~/Desktop/Deimos Rising.app`
  with `~/Desktop/Deimos Rising — WHAT-TO-EXPECT.md` beside it (also `out/Deimos/` in the main checkout). The card's
  Part A is the gate-3 card (the campaign, two players, the finale); Part B is the Phase 2 card, kept because Ben has
  not ruled on it. The game plays all twelve sectors in one game, carries lives, score and multiplier across, runs
  the finale after sector 12 in a game begun at sector 1, and takes `-players 2` and `-sector N` until the menu
  exists. **A muted boot check passed on 2026-11-20 at 09:01** (Ben: "of course"): the app opened, ran eight
  seconds, quit cleanly, no crash report. Nobody has seen or heard it play.
- **Numbers (the wave 3.4 seat's own runs at main c47416e, 2026-11-20, HectorKit ef2c341 clean):**

| check | value |
|---|---|
| `Deimos/Core` (without the replay and campaign bundles) | **372 / 0 / 0** |
| `DeimosReplayTests`, and `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 |
| `DeimosCampaignTests` (the sweep; run one test at a time, about 13 minutes in all) | **3 / 0** |
| app builds | Deimos Debug and Release, Aki, BubbleTroubleX: all succeeded |
| layering grep; census file | empty; unchanged |
| HectorKit zero-skip | 366 passed + 4 Aki 1.1 skips (the known four) |

- **Waiting on Ben:** (1) his first real play of the staged app; (2) his verdict on Part B, "does level 1 play like
  Deimos"; (3) his verdict on Part A, "does the campaign play like Deimos", with four short questions the card asks
  by name: flip pitch; can sector 12 end with the Beamer alive; should your own overload kill you while
  invulnerable; are player 2's keys the ones he remembers.
- **The plan:** `docs/superpowers/plans/2026-11-14-deimos-phase3.md` (D50) — all seven tasks done. The close is in
  `docs/handoff-2026-11-15-deimos-phase3-wave34.md`. **Next, after gate 3:** Phase 4, the front end (menu, high
  scores, level select, settings on disk, the controls window). It has cards in the remainder plan
  (`docs/superpowers/plans/2026-11-05-deimos-remainder.md`) but no plan of its own; nothing of it is started. Ben's
  notes from either gate become a fix wave first.
- **Phase 4 is planned (2026-11-20, D52), nothing built:** `docs/superpowers/plans/2026-11-20-deimos-phase4.md`, twelve
  sections S0–S8b with four grounding appendices; running order, eight questions for Ben and the first brief are in
  `docs/handoff-2026-11-20-deimos-phase4-plan.md`. The app file holds an OS 9 and an OS X build; the research read the
  OS 9 one. **S0 closed 2026-11-20** (`docs/handoff-deimos-phase4-s0.md`): the OS X build is on file (`ghidra/deimos/Deimos_osx.*`,
  `ghidra/regen-deimos-osx.sh`), its front end is compared with the OS 9 one in `docs/deimos/osx-build.md` (14 differences
  change what Phase 4 builds; rulings 12 and 17 and the fade timings in grounding A §5.2 / B §1a are wrong for X), and the bank
  corrections are in (INDEX #14 and #62 closed). No Swift or test changed.
  **S1a closed 2026-11-20** (`docs/handoff-deimos-phase4-s1a.md`): the joins between the game's parts are widened for the
  front end (mouse, key and menu events in; waits, a session result, new shell requests and two draw steps out) and the
  shared element list with its fades is built; nothing a player would notice yet. `Deimos/Core` is now **385 / 0 / 0**
  (one above the plan's 384: a draw-once test; the phase now ends at 478); replay 4 / 0 unchanged. The element fades
  follow the OS X build (16 passes).
  **S1b closed 2026-11-20** (`docs/handoff-deimos-phase4-s1b.md`): the game now runs inside a new front end with an
  empty placeholder for every screen (boot, menu, level select, scores, name entry, credits, films, the two settings
  windows); the app behaves exactly as before. `Deimos/Core` is **392 / 0 / 0**; replay 4 / 0 and the campaign sweep
  3 / 0 unchanged; Debug and Release build. Each screen's entry is frozen and listed in the handoff.
  **S4 closed 2026-11-20** (`docs/handoff-deimos-phase4-s4.md`): the settings file (read and written byte for byte as
  the original), the high-score table, name entry and the scores screen are built but not yet reachable from the menu
  (S2/S3a wire them). `Deimos/Core` is **406 / 0 / 0** with S4 alone (S2's tests add on top); replay 4 / 0; Debug and
  Release build. The erase-scores question moved to the menu's SCORES action (seat ruling, in the handoff).
  **S2 closed 2026-11-20** (`docs/handoff-deimos-phase4-s2.md`): the main menu and the credits screen are the
  original's, proved by tests (`Deimos/Core` **416 / 0 / 0** with S2 and S4 both in); the app still opens straight into a game
  until S8a connects mouse and keys to the front end. Found: the credits have ten pages, no blank eleventh (ruling 15).
  **Next: S3a (starting a game and coming back) and S5 (Last Film, demos)**, started by the Coordinator.
  **S3a closed 2026-11-20** (`docs/handoff-deimos-phase4-s3a.md`): choosing a game on the menu now runs the original's
  start (fades, transition sound, level-select music, the level select — still a placeholder) and a game's end runs
  the original's way back (fades, high-score entry when a score places, the menu and its music). Nothing a player
  would notice until S8a. `Deimos/Core` is **423 / 0 / 0**; replay 4 / 0; Debug and Release build. Left for S8a,
  waiting on Ben: deleting `-players` / `-sector`, and the menu's "erase high scores?" question.
- **Data:** `Resources/Deimos/` in git; `deimos-census` 872 entries, 0 failures.
- **Open:** RE bank `docs/deimos/INDEX.md` #13, #59 residue, #63 and 134 cross-file label mismatches (#64 closed 2026-11-20); Ben's
  ear/eye items (on the gate card). Not modelled until Phase 4: the mouse button ending a film; the quit flag
  inside the Caps Lock wait; a film that ends restarts the same film (the original returned to its menu). Not
  proved by any test: winning sector 12's end fight by destroying the Beamer (the sweep outlasts it on the
  controller's timer, as the data allows); the feel of sectors 5–12 (no film covers them). A game started with
  `-sector N` has no finale (the original's rule). A bad launch value quits silently in a Release build. Small follow-ups: four
  private film lookups remain inside the core test bundle; the app's argument parser has no test target; the
  DEBUG-only `-debugCapsLock` swallows a following flag; the app's two data alerts do not use the shared refusal
  helper; a failed `--frames` write can hide a film's result line; `HeadlessRunner` traps on an end no rule
  explains; stale comments (`ScrollState.step` "Phase 2", `Removal.swift:59`); `MotionBlurPool.emit` copies +0x90.
  Not independently confirmed: sound actually reaching the speakers (an offline probe of the same audio graph
  passed); frame checks under translucent or scaled draws.

## Cythera — 2026-11-15 (wave 1 session A closed: C8 + C9 merged; session B next)

- **Where it stands:** C8 + C9 (script decoder; segment model, reachability, canonical parity for all 958 segments) merged 2026-11-15, Fable cross-check passed with fixes (done) — `Cythera/Core` **57/0/0** on HectorKit ef2c341 (370); next = session B (C6, C7, C10; 57 → 80), brief in `docs/handoff-2026-11-15-cythera-wave1-A2.md`.
- **The plan:** `docs/superpowers/plans/2026-11-05-cythera-remainder.md` (self-contained since 2026-11-08). Next = wave 1
  session B (C6 ∥ C7 ∥ C10, suite 57 → 80), then C (C13 → C11 → C12). The brief is in
  the newest `docs/handoff-*-cythera-*.md`, "The brief for the next session".
- **Open:** HectorKit's gate script has a stale default Aki path (one-line kit fix; until then set
  `HECTORKIT_DATA_AKI11`); the PICT opcode-walk kit carry (an error naming the first bits opcode); small RE items (THood
  order within a pass, QTMA music events, over-encumbrance, the 0x03/0x05 words, 0x0210).

## Bubble Trouble X — 2026-10-23 (1.1 with controller support: release drafted)

- **Where it stands:** 1.0 released 2026-10-06 (GitHub `btx-1.0`: notarized universal DMG + Windows zip); the Windows
  build played to level 20 on a real PC by Ben's brother. **1.1 (game controllers, Mac and Windows):** main and
  HectorKit pushed; GitHub release `btx-1.1` is a **draft** (notarized DMG + Windows zip; copies in `releases/btx-1.1/`;
  notes `docs/release/btx-1.1.md`). Ben's controller check passed `BubbleTroubleX/GAMEPAD.md` steps 1–5 (step 6 untried).
- **Numbers:** BTX core 261/0/0; Windows package 126/0/0; HectorKit 35a85ba at the release.
- **Waiting on Ben:** try the browser-downloaded 1.1 DMG → publish → then point README's BTX link and badge at 1.1.
  The Windows controller path is untested on hardware. His longer playtest (cheat memories and the rest if he notices).
- **Carries:** core `musicPlaying` flag vs channel status; deactivation during a carried-over pause; an event during the
  very first wipe acts one frame early; app activate/deactivate during dialogs (`docs/bubble-trouble/review-carries-2026-10-04.md`).
  Never clear the prefs domain `com.ambrosiaclassics.bubbletroublex` (Ben's play since 2026-10-05).
- **Next release:** bump `CFBundleVersion` in `BubbleTroubleX/App/Info.plist`, then `tools/package-btx-release.sh
  --version X.Y --sign "Developer ID Application: Benjamin Thomas (5W72UJL332)" --notarize oniarm64-notarize`.

## Aki — Mahjong Solitaire — 2026-10-06 (1.0 released)

- **Where it stands:** 1.0 public (GitHub `aki-1.0`, notarized + stapled universal DMG, Remaster art in); Mac, iPad
  (`AkiPad`) and Remaster mode on main; AkiCore **123/0/0**. Ben verified the notarized DMG (sound, music, ⌘G). Untested:
  Intel, macOS 15/26. **Next: Phase 3** (the editor, `.aki` files) — not scheduled.
- **Working notes:** Remastered Art needs `Resources/Aki/hd-4x/` regenerated per worktree (`python3
  tools/upscale-aki-art.py`, then `--check`; git-ignored). Never delete the prefs domain `com.ambrosiaclassics.aki`.
  Next release: bump `CFBundleVersion` in `Aki/App/Mac/Info.plist`, then `tools/package-aki-release.sh --version X.Y
  --sign "Developer ID Application: Benjamin Thomas (5W72UJL332)" --notarize oniarm64-notarize`.
- **Carries:** for HectorShell — a track started at its end replays from 0; quitting from fullscreen re-shows the
  windowed window (needs an order-out-only exit); `ShellFullscreenWindow.canBecomeMain`. For Aki — the replica's own
  release notes at the very end (with the licence); faithful About/text-viewer windows after Phase 3; the Carbon dialog
  centres on the main display; one `fullscreen` accessor; the Osaka-Mono guard's Menlo branch is provable only offline.

## Shared — HectorKit and the repository — 2026-11-08

- **HectorKit** `~/Developer/HectorKit`: main ef2c341, zero-skip executed 370 (4 Aki 1.1 skips because the original
  moved on Ben's Mac — run the gate with `HECTORKIT_DATA_AKI11="$REPO/Resources/Aki/1.1.0.app/Contents/Resources"`).
  Local-path dependency: a worktree needs the untracked symlink `.claude/worktrees/HectorKit → ~/Developer/HectorKit`.
- **Originals:** Aki 1.1.0 + 1.2.0 (git-ignored symlinks under `Resources/Aki/`), Bubble Trouble X 1.1, Ferazel's Wand
  1.0.3, Deimos Rising 1.0.6, Cythera 1.0.4; archive map `~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md`. Decompiles in
  `ghidra/<game>/`.
- **Carries:** the design doc says 70 QuickTime / 12 raw PICTs where the data says 71 / 11 (fix when next edited);
  HectorKit keeps EV-engine arithmetic in `SndSound` (trim only with a ruling); `quickTimeBands` returns a tuple; no
  dimension cap on codec images; Ambrosia's 1996 installer format unreversed; HD-art packs and the licence at the very end.
