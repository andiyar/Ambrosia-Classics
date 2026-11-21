# STATE — Ambrosia Classics — 2026-11-11

Settled history lives in docs/STATE-history.md.

> Live state only, one dated block per game. This file is the one live state for every game, Ferazel's included (the
> chip `docs/NEXT.md` holds only the next run's instructions). Each close **replaces** its game's block with today's
> numbers and open items and moves anything settled to the top of `docs/STATE-history.md`; it never appends a run story
> here. Forks go in `docs/DECISIONS.md`, narrative in the handoff. Re-verify before acting.

## Ferazel's Wand — 2026-11-22 (attended run 62 closed at night: the Goblin Chief jumps, lands and throws; his being hit and killed heads run 63)

- **Where it stands:** Phase 5 "Enemies" is closed on the machine side — **Ben's gate pending (Q18)**. Phase 6A
  "through the Goblin Chief" is being built (the plan: "Wave 5 — Phase 6A" in the one plan file; rulings D46–D49, D51,
  D53–D57, D59–D61). Waves 6A.1 (the Warrior is a real boss) and 6A.2 (levels 10 and 11 open) are built and closed.
- **Wave 6A.3 "Storm Valley and the Chief" is two thirds built.** Level 15 "Storm Valley" is open (run 61).
  **The Goblin Chief's first half is built** (run 62, 6A-CH1): he waits until the arena locks, jumps between three
  lanes, lands with a screen shake that can stagger Ferazel, and throws one or two boulders a
  landing. He cannot be hurt or killed yet (6A-CH2), and no player can meet him yet: his level, 18, is not open
  (6A-L18). Levels playable on main: **1–5, 10, 11, 15** — unchanged.
- **Windows test build 5 is with Andrew** (Ben asked, 2026-11-18): GitHub pre-release `ferazel-windows-test-5`, staged
  from 02717f8 (levels past 5 closed). His report is the Windows half of Q18; Ben's Mac verdict is still open. The zip
  and its checksum are in `releases/ferazel-windows-test-5/`.
- **Staged builds on the Desktop are old** (game code as e9183ce, run 50): they still show the stand-in Warrior and no
  level past 5. The next stage is the 6A phase end unless Ben asks for one.
- **Next:** run 63 = **6A-CH2 ⚑** (the Chief's Hit and Kill, his three pieces, the fight; Core → 760), which first
  finds from the data how the fight is won (D49.1); then, in a later run, 6A-L18 (level 18 opens; → 764 / WinKit 87)
  with the wave 6A.3 end (the Windows test run by day, detached as D59.1 allows; the smoke; the Fable cross-check).
  None of it waits for Ben's verdict on Phase 5.
- **How long checks run under the Coordinator** (commands cut off at ten minutes): the suites in parts, the sweep one
  level group a command, the bot one command a shell (D59.4, D60.4); only the Windows test script may run detached
  (D59.1). Q21 asks Ben whether the sweep and bot may too — no longer pressing.
- **The plan:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` (self-contained); the design:
  `docs/superpowers/specs/2026-11-04-ferazel-remainder-design.md`.
- **Ben's gates:** Phase 1 passed; Phases 2 and 3 passed with notes; Phase 4 passed (Fireball note) and the Windows
  twin passed on Andrew's word (2026-11-07); **Phase 5 waiting (Q18)**. Then three gated Phase 6 parts (6A to the Goblin
  Chief, 6B to the Wizard and the fire, 6C the whole game), then one release `ferazel-1.0`.
- **Current numbers** (G2 and GW2 are the seat's own foreground runs of run 62, 2026-11-22, at d7dc0ad; G3, the
  sweep and the bot are run 61's at b4482a1 / game source as e8d6bfd — before the Chief, who is on no built level;
  Proof B and the smoke are run 60's at d82b2bf, game code as 66875a3 — before the plants, the rain, level 15 and the
  Chief; G5 / GW1 / GW3 / GW4 the implementer's at ea93ffb):

| gate | value |
|---|---|
| Ferazel/Core suite (G2) | **752** = 584 rules + 168 render; 750 passed, 0 failed, 2 opt-in skips by name: `FerazelRenderTests.VisitSweepTests testVisitEveryObject`, `FerazelRenderTests.RandomPlayTests testRandomPlay`; ten foreground parts, about 38 min, the longest 367 s (rules 107 s; A–C 277; D–E without the audit 58; the audit's first test 205 + 364 in two level groups; its second test 215 + 367 the same way; F–K 192; L 313; M–Z 148) |
| FerazelWinKit (GW2) | **86**; 84 passed, 0 failed, 2 opt-in skips (`WinVisitSweepTests testVisitEveryObjectThroughWinGame`, `WinRandomPlayTests testRandomPlayThroughWinGame`); seven foreground parts (B 301 s, F\|T 168, Win D\|F\|G 318, Win O\|R\|S\|V 154, the three level references 185 / 159 / 138), about 24 min |
| census (G3) | items 1,108 decoded, failures 0 |
| visit sweep (GE, levels 1–5, 10, 11, 15, both shells) | core 7,056 visits, windows 7,056 visits, rows 0 on both (1,652 s + 1,721 s in five commands a shell; run 61) |
| random-play bot (GE, the same 8 levels, both shells) | core and windows each: steps 172,800, deaths 25, exits 237, conversations 33, saves 1, failures 0 (80 s, 95 s; run 61) |
| Proof B in CrossOver, muted (GWB) | **719 passed / 0 failed / 3 skipped / 0 crashed (of 722)**, 834 s (run 60, 09:00, detached); next owed at the 6A.3 wave end (761 of 764) |
| Mac SDL smoke (GW4R) | exit 0, main menu identical, `video=dummy audio=none` (run 60, 09:15); GW6 and G9M last passed in run 50 |
| GW1 / GW3 / GW4 / G5 | 0 then 2 / 0 then 1 / Build complete! / BUILD SUCCEEDED |
| HectorKit (G1) | main **ef2c341**, clean; zero-skip executed **370**; Ferazel follows HectorKit main |
| ladder from here | 752 → CH2 760 → L18 764 … 814 at the 6A end; WinKit 86 → 90 |

- **Goldens (◈):** no existing value moved in run 62 and no picture was added (the Chief is on no built level).
  Measured and pinned for the Chief (seed 1, level 18 through the test fixture, headless): arena lock on frame 111,
  awake for good 121, first jump 176, first landing 212 — **6A-L18 re-measures these with real pictures and may move
  them** (D61.3). Every value is in the plan's "As executed — 6A-CH1".
- **Waiting on Ben (QUESTIONS.md "Open"):** **Q18 (the Phase 5 gate)**, Q21 (may the sweep and bot run detached —
  not blocking), Q19 (three small choices in the 6A plan), Q17, Q16 (defaults stand), Q15's follow-ups, Q13.
- **Worktrees:** run 62's `zen-hamilton-a3370d` was removed at its close. `compassionate-leavitt-7ca958` is run
  53's (merged; it was run 49's before). `gallant-brahmagupta-56ed81` (run 52), `eager-fermat-db9ed9` (run 51),
  `hungry-bun-395f55` (run 50; `out/` holds the latest stages), `nifty-mendel-0ad40e` (run 48),
  `ferazel-run-47-e0431c` and `ferazel-run-44-7428b3` are finished and merged — Ben or their sessions remove them.
  The others belong to other sessions.
- **The sweep and the bot are guarded (2026-11-10):** both scripts kill any worker past `MAX_WORKER_MB` (4096) and
  brake below `MIN_RUNNING_FREE_PCT` (15) free memory, with a failure row. Stop a run with a plain
  `kill <script pid>` — never `kill -9` / `pkill -9`. A `memory` row is a leak to fix, never a limit to raise. A
  shell that chains the sweep and then the bot starts the bot when the sweep is killed: stop the outer shell too.
- **Known deviation of muted launches (D44 As built run 48 (d)):** a muted run draws the random stream differently
  from an audible one; boot checks only.
- **Open carries** [LOW unless marked]:
  - From run 62: the Chief's wake and first-jump frames were measured headless (whole-cell wake rectangle) — 6A-L18
    re-measures with pictures; the renderer cannot yet load his picture sets 0x777–0x77a (6A-CH2 / 6A-L18);
    `Smite.swift:16` still calls him inert (6A-CH2's file); the ledger now shows picture 161 on level 67 as "named in
    code only" — a false match on the boulder's x offset `0xa1` at `Chief.swift:255` (the script matches the number,
    not its meaning); the seven older player arms stop the spin sound without first asking whether it is playing
    (the original asks every time; same sound, a different call list); `Chief.stagger` (the length 0x18) and
    `PlayerStates.stagger` (face 1037) share a name; the audit test works out "is this run filtered?" in two places;
    one assert that cannot fail is left at `ChiefTests` (`+0xa6` 0 on the return to waiting — harmless).
  - From run 61: the audit's scripted run on level 15 never gets past the first 300 px (the push sends the player back
    out of the exit), so it draws 7 of the 38 placed types there and none of the four modes level 15's Setups write —
    those are still drawn once each by the audit's fixed-spot check and visited by the sweep, but values the game
    writes after the player touches things on level 15 are seen by the bot only (a later start point for that run
    would fix it); the first-frame picture equals the stand-in's by construction (same open function) — only the
    Windows reference goes through New Game; the helpers still named `TenEleven` now serve level 15 too; a
    redundant `q / 2` term in the cache-bar assert; `WinLevelReferenceTests` is a `@MainActor` class (since run 56; Proof B runs Core only).
  - From run 60: the generated marker list (`docs/ferazel/gap-ledger/markers.tsv:154`) still quotes an old comment
    about the auto-scroll ambience sound (regenerating renumbers about 1,370 ids — a ledger pass); the engine
    contract §2.7 still calls the fade switch a "preference" and asks for a Windows rain picture the plan overrides;
    the rain's read-only test hook `OmniPxRain.entrySeed` lives in shipped source; the rain picture's particle filter
    could misread a slot reused within one tick (no case seen); in `PlantTests` one assert compares the test's own
    table with its own formula and the load-bar values are the port's own arithmetic; a mirrored plant keeps an
    unflipped empty hot rect (D59.2, as D53.2); one mutation run of the Windows-kit audio tests with the cue's loop
    default flipped on did not finish in ten minutes (a deliberately broken build; not chased).
  - From run 58's fix round: two comments still give "levels 1–5" reasons nobody could verify on levels 10 and 11
    (`Walker.swift:48`, `BoxSprite.swift:1141`); the water-current assert cannot tell the direction of the random
    spread (it catches a flipped sign only because one sampled draw is 0); the ice value's floor of 1 is reached on
    no level; level 11 holds 1 in both the underwater byte and its neighbour, so only the older asserts catch a read
    of the wrong byte; the new underwater-light asserts build their expected picture with the port's own blend step
    (the older asserts in the same test pin that step against the dump).
  - From run 57's cross-check (kept): the passage jump skips its p2 ≠ 0 arm without a refusal (no passage on any
    level 10–70 has p2 ≠ 0, per the ledger); the renderer works out the horizon strip's colour table by the same
    formula as the game rather than reading the game's answer (they can drift; no test compares the two on all six
    strip levels).
  - From run 56: the ledger script still treats only levels 1–5 as built, so levels 10 and 11 still show as later
    levels (no generated number is wrong); a missing rippled frame in the Windows level-11 test shows as an unwrap
    failure, not a clear message; refused spawns on levels 10 and 11 are asserted over a short run only (the sweep
    and bot would not report one); the sweep costs about 0.2 s a visit, twice the plan's old estimate — at 12 levels
    about 80 minutes for both shells.
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

## Deimos Rising — 2026-11-21 (Phase 4 built and staged; Ben's gates 2, 3 and 4 all wait on the one app)

- **Where it stands:** Phase 1 "level 1 look" gate passed 2026-10-07. Phase 2 "level 1 plays", Phase 3 "the
  campaign" and **Phase 4 "the front end" are all built, merged to local main and staged as ONE app**:
  `~/Desktop/Deimos Rising.app` with `~/Desktop/Deimos Rising — WHAT-TO-EXPECT.md` beside it (also `out/Deimos/` in
  the main checkout). The card (`Deimos/WHAT-TO-EXPECT.md`) leads with gate 4 ("cold start → game → scores → quit":
  ten steps, Ben's answers as built, every ruling numbered for him to overturn, the known gaps); the gate-3 and gate-2
  cards follow, trimmed where the front end replaced their stand-ins. The app now boots to the original's menu
  (logos, loading screen, menu), with the level select, high scores and name entry, demos and Last Film (`F`), credits,
  the settings and controls windows drawn by the game, a controller, and quit-with-save. `-players` / `-sector` are
  gone; `-film deNN` and `-mute` are hidden switches. First launch: NOT DONE. The app has never been launched. The question (mailbox Q6: may the section launch it once, muted?) had no answer by the close, so its default applied: Ben launches it first.
- **Numbers (S8b's seat, at the staged head):**

| check | value |
|---|---|
| `Deimos/Core` (without the replay and campaign bundles) | **491 / 0 / 0** (the phase's ladder ends at 491: S8a's 483 + eight goldens) |
| `DeimosReplayTests`, and `deimos-replay --all` | 4 / 0; four PASS lines, exit 0 |
| `DeimosCampaignTests` (one test at a time) | 3 / 0 (about 8 minutes for the longest) |
| HectorKit zero-skip | executed 370, 0 failed, the 4 known Aki 1.1 data skips (kit main ef2c341, unchanged) |
| app builds | Deimos Debug and Release, Aki, BubbleTroubleX: all BUILD SUCCEEDED |
| census file; layering grep | unchanged; empty |

- **Waiting on Ben:** (1) his first play of the staged app — the first launch of the front end ever, unless the line
  above says otherwise; (2) gate 4, "does the front end work like Deimos", and any of the card's numbered decisions he
  wants changed; (3) gate 3, "does the campaign play like Deimos", with its four named questions (flip pitch; sector
  12 ending with the Beamer alive; own overload while invulnerable; player 2's keys); (4) gate 2, "does level 1 play
  like Deimos". His notes from any gate become a fix wave first.
- **Where things are:** the plan `docs/superpowers/plans/2026-11-20-deimos-phase4.md` (D52; as executed: D58); the
  section handoffs `docs/handoff-deimos-phase4-*.md` (history below); Ben's answers in
  `~/.claude/coordinator-notes/deimos-phase4-mailbox.md`; the OS X build compared with the OS 9 one in
  `docs/deimos/osx-build.md`; the controller guide `Deimos/GAMEPAD.md`.
- **Next after the gates:** the fix wave from Ben's notes; the whole-game OS 9 / OS X comparison (Ben: "Yes, after
  Phase 4"); Phase 5 (Windows).
- **Open from Phase 4** (all on the card's "Known gaps and faults"): one narrow known fault (an app switch during the
  erase question, then Quit, leaves the suspended flags set); the original's pause screen on leaving the app not
  built (a macOS quit during play waits for the player's return); the OS X build's Preferences… menu item and Edit
  menu not built; the cursor not shown during a game's Caps Lock pause (the OS X build shows it, osx-build D12); the
  pressed 1 / 2 PLAYER button lit a pass too long on the way back; the menu loading `back` into a
  level-map-sized buffer (unchecked against the listing); input on the pass where a screen that draws nothing
  finishes; small ones (a key with no character sent as 0, the background pump's bound, the logo sound on a quit
  during the boot, no test for an unreadable settings file or a sector chosen after a Quit at the level select);
  `FrontEndState.recordedFilmForTests` unused. Nothing a test can check proves how any screen looks.
- **Data:** `Resources/Deimos/` in git; `deimos-census` 872 entries, 0 failures.
- **Open (older):** RE bank `docs/deimos/INDEX.md` #13, #59 residue, #63 and 134 cross-file label mismatches (#64
  closed 2026-11-20); Ben's ear/eye items (on the gate cards). Not proved by any test: winning sector 12's end fight by
  destroying the Beamer (the sweep outlasts it on the controller's timer, as the data allows); the feel of sectors
  5–12 (no film covers them). A game started above sector 1 has no finale (the original's rule). Small follow-ups:
  four private film lookups remain inside the core test bundle; the app's argument parser has no test target; a
  failed `--frames` write can hide a film's result line; `HeadlessRunner` traps on an end no rule
  explains; stale comments (`ScrollState.step` "Phase 2", `Removal.swift:59`); `MotionBlurPool.emit` copies +0x90.
  Not independently confirmed: sound actually reaching the speakers (an offline probe of the same audio graph
  passed); frame checks under translucent or scaled draws.
- **Deimos Phase 4 history** (each section closed 2026-11-20 unless dated; `Deimos/Core` count at its close):
  - **Plan** (D52): twelve sections, four grounding appendices; `docs/handoff-2026-11-20-deimos-phase4-plan.md`.
  - **S0** the OS X build on file and compared (14 differences change the build); bank corrections; no Swift —
    `docs/handoff-deimos-phase4-s0.md`.
  - **S1a** the seam additions and the element list; fades follow OS X (16 passes); 385 —
    `docs/handoff-deimos-phase4-s1a.md`.
  - **S1b** the `FrontEnd` frame, a placeholder per screen, the direct start; 392 — `docs/handoff-deimos-phase4-s1b.md`.
  - **S4** the settings file, high-score table, name entry, scores screen; erase question moved to the menu; 406 —
    `docs/handoff-deimos-phase4-s4.md`.
  - **S2** the main menu and the credits (ten pages, no blank eleventh); 416 — `docs/handoff-deimos-phase4-s2.md`.
  - **S3a** starting a game and coming back; `-players` / `-sector` and the erase question left for S8a; 423 —
    `docs/handoff-deimos-phase4-s3a.md`.
  - **S5** the film recorder (byte-exact against demo 1), Last Film, the demo cycle and `F`; 433 —
    `docs/handoff-deimos-phase4-s5.md`.
  - **S3b** the level select; the right-hand preview does draw its hover outline (ruling 15 corrected); 441 —
    `docs/handoff-deimos-phase4-s3b.md`.
  - **S6** the boot and the configuration window (Apple's Geneva 9; the drawn-control helpers); 454 —
    `docs/handoff-deimos-phase4-s6.md`.
  - **S7** the controls window and the controller layout; 467 — `docs/handoff-deimos-phase4-s7.md`.
  - **S8a** the app wired to the front end; `-players` / `-sector` deleted; the erase question; unit names on the
    first launch only; Command-Q ignored in a game; `-mute`; 483 — `docs/handoff-deimos-phase4-s8a.md`.
  - **S8b** (2026-11-21) Command-Q quits from a game's pause (Ben's A5) and from the level select's (the seat's);
    eight front-end goldens; the gate-4 card (one fix round); staged;
    **491 / 0 / 0** — `docs/handoff-deimos-phase4-s8b.md`.

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
