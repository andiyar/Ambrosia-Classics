# STATE — Ambrosia Classics — 2026-11-11

Settled history lives in docs/STATE-history.md.

> Live state only, one dated block per game. This file is the one live state for every game, Ferazel's included (the
> chip `docs/NEXT.md` holds only the next run's instructions). Each close **replaces** its game's block with today's
> numbers and open items and moves anything settled to the top of `docs/STATE-history.md`; it never appends a run story
> here. Forks go in `docs/DECISIONS.md`, narrative in the handoff. Re-verify before acting.

## Ferazel's Wand — 2026-11-26 (attended run 70 closed: the magic carpet is built; level 22 heads run 71)

- **Ben's ruling 2026-11-26: finish Phase 6A, then archive.** The original author is selling an official remaster,
  so Ferazel pauses (not cancelled) after the 6A phase end: run 71 = level 22, run 72 = the phase end plus an
  in-game level chooser, complete Mac and Windows builds (no public upload), then `STATUS: PAUSED`. No 6B planning
  run. The full text is the block at the top of `docs/NEXT.md`.
- **The five public Windows test builds were taken down from GitHub (2026-11-26, Ben's word):** releases
  `ferazel-windows-test-1` … `-5` are deleted there (their tags remain); every zip and checksum is still in
  `releases/ferazel-windows-test-N/` in the main checkout. Andrew already has build 5.
- **Where it stands:** Phase 5 "Enemies" is closed on the machine side — **Ben's gate pending (Q18)**. Phase 6A
  "through the Goblin Chief" is being built (the plan: "Wave 5 — Phase 6A" in the one plan file; rulings D46–D49, D51,
  D53–D57, D59–D62, D64, D65, D67–D71). Waves 6A.1, 6A.2 and 6A.3 are built and closed; wave 6A.4 has levels 20 and
  21 open and the magic carpet built, with level 22 left.
- **The magic carpet is built (run 70) but not yet reachable in play:** the game's only carpet is on level 22,
  which opens in run 71. Touch the rolled carpet and it unrolls, rises, sinks and settles, and the player steers
  it; the shipped one flies for ever (carpets with a ride count, which flash and burst, exist only in tests).
- **Levels playable on main: 1–5, 10, 11, 15, 18, 20, 21.** Level 21 "Obfuscation & Edification" opened in run 69:
  a dark level with six pipes that push enemies out, insects, fourteen teleporters, graves that talk, blinking and
  crumbling platforms. Level 20 "Hangnabit" opened in run 67. **Nobody has seen either yet:** both were launched
  muted on 2026-11-25 and stayed running, but the seat was not allowed to look at the window. The staged builds do
  not hold them.
- **The lit blade (D67.1) is built:** on level 20, where the map has no lighting, anything lit by a light made
  during play (blades, maces, chains) is drawn plain and unlit instead of ending the game. A listed known
  deviation (number 7). **Ben confirmed it** (mailbox A1, 2026-11-25: "A: plain, unlit"; D71.5).
- **Windows test build 5 is with Andrew** (Ben asked, 2026-11-18): GitHub pre-release `ferazel-windows-test-5`, staged
  from 02717f8 (levels past 5 closed). His report is the Windows half of Q18; Ben's Mac verdict is still open. The zip
  and its checksum are in `releases/ferazel-windows-test-5/`.
- **Staged builds on the Desktop are old** (game code as e9183ce, run 50): they still show the stand-in Warrior and no
  level past 5. The next stage is the 6A phase end unless Ben asks for one.
- **Next:** run 71 = **6A-L22** "The Labyrinth" (Core → 816, WinKit → 90; the full sweep and bot on twelve
  levels), then the phase end (6A-END). Neither waits for Ben's Phase 5 verdict.
- **How long checks run under the Coordinator** (commands cut off at ten minutes): the suites in parts, the sweep one
  level group a command (levels 3 and 4 apart on the Windows path), the bot one command a shell (D59.4, D60.4); only
  the Windows test script may run detached (D59.1). One heavy command a message (D70.6). The longest commands now:
  the sweep's first Mac-path group with its build 422 s, level 11 on the Windows path 366 s, the draw audit for
  levels 10, 11, 15 about 375 s a test. With other projects building, a part can run a third slower (run 70: one
  took 424 s against 315) — chain parts in one command only when their usual times sum under six minutes (D71.6). Q21 asks Ben whether the sweep and bot may run detached — a convenience only.
- **The plan:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` (self-contained); the design:
  `docs/superpowers/specs/2026-11-04-ferazel-remainder-design.md`.
- **Ben's gates:** Phase 1 passed; Phases 2 and 3 passed with notes; Phase 4 passed (Fireball note) and the Windows
  twin passed on Andrew's word (2026-11-07); **Phase 5 waiting (Q18)**. Then three gated Phase 6 parts (6A to the Goblin
  Chief, 6B to the Wizard and the fire, 6C the whole game), then one release `ferazel-1.0`.
- **Current numbers** (the seat's own runs of run 70, 2026-11-26, at 651314e, except: the sweep and bot, run 69's
  at 63183f8; Proof B and the smoke, run 64's at a66d567; GW6 / G9M, last passed in run 50):
| gate | value |
|---|---|
| Ferazel/Core suite (G2) | **812** = 633 rules + 179 render; 810 passed, 0 failed, 2 opt-in skips by name: `FerazelRenderTests.VisitSweepTests testVisitEveryObject`, `FerazelRenderTests.RandomPlayTests testRandomPlay`; foreground parts, about 55 min (rules 136 s; A–C 424, 315 on a quiet Mac; D–E without the audit 55; F–K 258; the L classes without `LevelSweepTests` 104; `LevelSweepTests` 298; M–Z 164; the audit: levels 1–5 one test a command 191 + 202, level 18 87, level 20 203, level 21 115, levels 10, 11, 15 one test a command 369 + 377) |
| FerazelWinKit (GW2) | **89**; 87 passed, 0 failed, 2 opt-in skips (`WinVisitSweepTests testVisitEveryObjectThroughWinGame`, `WinRandomPlayTests testRandomPlayThroughWinGame`); ten foreground parts (B 333 s, F\|T 174, Win D\|F\|G 304, Win O\|R\|S\|V 141, the six level references 169 / 153 / 121 / 121 / 133 / 107), about 30 min |
| census (G3) | items 1,108 decoded, failures 0 |
| visit sweep (GE, levels 1–5, 10, 11, 15, 18, 20, 21, both shells; run 69's — not owed by the carpet) | core 9,824 visits, windows 9,824 visits, rows 0 on both (1,991 s in seven commands + 2,317 s in nine) |
| random-play bot (GE, the same 11 levels, both shells) | core and windows each: steps 237,600, deaths 41, exits 370, conversations 33, saves 3, failures 0 (110 s, 132 s) |
| Proof B in CrossOver, muted (GWB) | **761 passed / 0 failed / 3 skipped / 0 crashed (of 764)** — run 64's; not run on the 46 tests added since (owed at the wave end, by day) |
| Mac SDL smoke (GW4R) | exit 0, main menu identical, `video=dummy audio=none` (run 64) |
| GW1 / GW3 / GW4 / G5 | 0 then 2 / 0 then 1 / Build complete! / BUILD SUCCEEDED (run 70, at 651314e) |
| HectorKit (G1) | main **ef2c341**, clean; zero-skip executed **370**; Ferazel follows HectorKit main |
| ladder from here | 812 → L22 816 at the 6A end; WinKit 89 → 90 (every Core number is two above the original plan: D68.1, D69.1) |
- **Goldens (◈):** no existing value moved in run 70 beyond the card's named one (level 22's load-bar count in
  `CachedFacesTests`, 35 → 36 records); the carpet's new picture values are in the plan's "Goldens" paragraph.
- **Waiting on Ben:** QUESTIONS.md "Open": **Q18 (the Phase 5 gate)**, Q21 (may the sweep and bot
  run detached — not blocking), Q19 (three small choices in the 6A plan), Q17, Q16 (defaults stand), Q15's
  follow-ups, Q13.
- **Owed:** somebody's eyes on levels 20 and 21 (they start and stay running; the picture is unseen — D70.5);
  Proof B and the Mac SDL smoke at the wave end, by day.
- **Worktrees:** run 70's `focused-jennings-d776d7` was removed at its close. Run 67's
  `exciting-panini-fdb834` (under `Aki/.claude/worktrees/`) is unregistered and its branch deleted, but about 560 MB of its files remain
  in that folder (the app refused the last delete): remove by hand.
  `compassionate-leavitt-7ca958` is run 53's (merged; it was run 49's before). `gallant-brahmagupta-56ed81` (run 52),
  `eager-fermat-db9ed9` (run 51), `hungry-bun-395f55` (run 50; `out/` holds the latest stages), `nifty-mendel-0ad40e`
  (run 48), `ferazel-run-47-e0431c` and `ferazel-run-44-7428b3` are finished and merged — Ben or their sessions
  remove them. The others belong to other sessions.
- **The sweep and the bot are guarded (2026-11-10):** both scripts kill any worker past `MAX_WORKER_MB` (4096) and
  brake below `MIN_RUNNING_FREE_PCT` (15) free memory, with a failure row. Stop a run with a plain
  `kill <script pid>` — never `kill -9` / `pkill -9`. A `memory` row is a leak to fix, never a limit to raise. A
  shell that chains the sweep and then the bot starts the bot when the sweep is killed: stop the outer shell too.
- **Known deviation of muted launches (D44 As built run 48 (d)):** a muted run draws the random stream differently
  from an audible one; boot checks only.
- **Open carries** [LOW unless marked]:
  - From run 70: the carpet's picture is stored at Setup where the original sets it on the first Handle (an older
    house rule; the original draws nothing for one frame) — not visible on level 22 from its real start, but the
    carpet's picture test pins it: look again when level 22 opens; the engine contract §2.11's "Today" paragraph
    and the ledger's §9 line (about l. 1412) still call the carpet unbuilt; a missing space at `LevelRun.swift`
    about l. 1406; `0x439` is a bare number beside the named `rolledCarpet`; the ledger script's built arm for the
    carpet does not check its picture is in the Setup-face table; the mailbox next free number is still Q2.
  - From run 69: the Windows level-21 reference has no darkness twin (the Mac picture carries it); a passage
    that overrides the darkness switch (p2 not 0) is unbuilt — none on a built level — and when it is built the
    particle colour row, read once when the renderer is set up, must follow the live value [MED when that passage
    is built]; the throwaway child of a pipe has its draw layer pinned nowhere; level 21's platform and path-bat
    expectations are worked out from the port's own Setup; the example comment in `tools/ferazel-built-levels.sh`
    lists the old levels; nothing in the draw audit counts that the darkening ran (level 21's picture twin shows it
    does); the two helper commits of run 69 carry different co-author lines.
  - From run 68: **[MED] what a level restart does to other objects' touch areas.** The original keeps a level's
    pictures loaded across a restart, so anything whose Setup measures itself from a cached picture gets its real
    size on a restart and a 64 × 64 stand-in size on a first load. The port now does this for the pipes only
    (D69.1); the other types that read a cached picture at Setup still always get the stand-in size (their idle
    bounds) — unread against the dump, on built levels too; a short reading task, not yet in the plan. Small ones:
    the throwaway-world set-up is copied in three places; the renderer's own Setup pass runs without the level
    spawn (a pipe set up there gets no throwaway child; nothing draws from it); the ledger's owner column still
    says "level 21 pipe wiring"; the plan's line 745 still carries the old pipe dump lines.
  - From run 67: the draw audit checks the lit-blade guard by its exact source text, so a harmless rewrite fails
    it with a confusing first message; level 20's "no spawn refused" assert cannot fail on its own; in the new
    light test the picture comparisons follow from the equal draw words; a dead store in the candelabra arm of
    `BonusSprite.swift` (older); the plan's ENG §2.8 text still says the cloud draws are back to back.
  - From run 66: Core keeps a second copy of the renderer's cos/sin tables (pinned equal by a test; one table in
    Core is the fix); `testBladeArmEndpoints` pins exact cos/sin values Wine's maths library might round
    differently — watch Proof B at the wave end [MED until Proof B has run]; the blade's Setup slot carries its
    face though the original sets none at Setup (never drawn on level 20's first frames; check again on level 22);
    the mace trace follows one record with
    no p4 offset; the plan's "6C-BG3 1 type" line is stale; ENG §2.8 / §2.10 / E19 wording errors are noted in
    the As executed notes, not corrected in the contract.
  - From run 65 (the cross-check): `ScreenFlash.swift`'s header says every writer stores 3, but Xichra's Handle
    stores 5 and 7 (6C-XI's to write); the audit's horizon-strip note lists "levels 1–5 and 11" where 15 and 18
    are also without a strip; the new held-item table's keys are not checked against the built-level list; on
    level 18 alone the new count catches an under-count only (an over-claim is caught on level 1).
  - From run 64: the bot meets the Chief on one quick-mode seed of four and never kills him, and its summary line cannot show a
    meeting (a probe did); one audit assert (the arm bytes for a level under the new light proof) is true by
    construction once the proof passes; the new light proof groups variable-type spawns by kind rather than tracing
    each (crate drops are checked record by record); level 15's audit run never puts the held item under a liquid,
    so the held-item water rule is exercised on level 18 only.
  - From run 63: the picture loader now loads a level-coloured picture set under the level's colour table, but the
    shared-picture path (`recordSheets` in `LevelRun.swift`) still skips that table — nothing reaches it today, check
    when a later boss needs it; the loader treats any non-zero flag as "level-coloured" (the original only ever uses
    0 and 1); the Chief's and the Warrior's Kill are the same code twice and their crush arms differ only in a sound —
    share them if a third boss repeats it; the fight script reads three internal values as stand-ins for what a player
    sees (the stagger count, his invulnerability count, hit rectangles), named so in its comment (D62.3); a "killed
    for good" row for the Chief exists but can never be reached (he has his own kill arm); the 0x7f60 right-opening
    camera bound is reached on neither level 5 nor level 18 (still untested); the Smite test calls the strike
    directly rather than through the Ring.
  - From run 62: the ledger shows picture 161 on level 67 as "named in code only" — a false match on
    the boulder's x offset `0xa1` in `Chief.swift` (the script matches the number, not its meaning); the seven older
    player arms stop the spin sound without first asking whether it is playing (the original asks every time; same
    sound, a different call list); `Chief.stagger` (the length 0x18) and `PlayerStates.stagger` (face 1037) share a
    name; the audit test works out "is this run filtered?" in two places; one assert that cannot fail is left at
    `ChiefTests` (`+0xa6` 0 on the return to waiting — harmless).
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
  - From run 55: the conversation test counts a portrait as loaded when it is drawn and
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
  - From run 47: the 0x7f60 right-opening bound is unreachable on level 5 (untested; the second camera bound is now tested on level 18, run 63); `try!` at
    `GremlinFloater.swift:298` (safe: Bonus setup throws only for 0xc25 / out-of-table) is outside the census.
  - From run 46: a census row marked "trap: unreachable" is not checked to point at a trap
    (`DrawModeAuditTests.swift`); the failure message says "throw" for traps; `try!` ×3 and `assert`
    (`FrameRenderer.swift`) are not counted by the census.
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

## Deimos Rising — 2026-11-24 (Phase 4 built and staged; the plan from here to the release is written and waits for Ben's approval; gates 2, 3 and 4 wait on the one app)

- **The plan for everything left (2026-11-24, D66):** `docs/superpowers/plans/2026-11-24-deimos-to-release.md` —
  the one authority; the earlier Deimos plans are history. Phase 5 loose ends on the Mac (Ben's gate notes, eight
  known faults, the OS X build's pause on leaving the app, the end boss beaten by a test, records put right);
  Phase 6 the OS 9 / OS X comparison of the whole game and the research notes closed; Phase 7 Windows; Phase 8
  the release `deimos-1.0`. **Nothing starts until Ben approves it** (`docs/QUESTIONS.md`, DQ1–DQ11; only DQ1
  blocks everything). Handoff: `docs/handoff-2026-11-24-deimos-remaining-plan.md`.

- **Where it stands:** Phase 1 "level 1 look" gate passed 2026-10-07. Phase 2 "level 1 plays", Phase 3 "the
  campaign" and **Phase 4 "the front end" are all built, merged to local main and staged as ONE app**:
  `~/Desktop/Deimos Rising.app` with `~/Desktop/Deimos Rising — WHAT-TO-EXPECT.md` beside it (also `out/Deimos/` in
  the main checkout). The card (`Deimos/WHAT-TO-EXPECT.md`) leads with gate 4 ("cold start → game → scores → quit":
  ten steps, Ben's answers as built, every ruling numbered for him to overturn, the known gaps); the gate-3 and gate-2
  cards follow, trimmed where the front end replaced their stand-ins. The app now boots to the original's menu
  (logos, loading screen, menu), with the level select, high scores and name entry, demos and Last Film (`F`), credits,
  the settings and controls windows drawn by the game, a controller, and quit-with-save. `-players` / `-sector` are
  gone; `-film deNN` and `-mute` are hidden switches. First launch: Ben's, 2026-11-22.
- **The bomb freeze (2026-11-22, D63):** Ben's first play: after bombs the arrow keys died until he clicked the
  picture. Cause: a quick double-tap of Option is another app's shortcut (the Claude app's quick-entry box); its panel
  took the keyboard, hidden behind the full-screen picture. Fix, app layer only (no HectorKit change): in full screen
  the game takes the keyboard back within a tick and keeps keys that were held across the steal. A hidden key log
  (`-keylog`) stays in the app. The restaged app is on the Desktop with the key log switched ON by a user default
  (`defaults delete com.ambrosiaclassics.deimos keylog` turns it off). **Ben's replay of the fix is owed**: no test
  can show the reclaim works on real hardware. His log from the fault is kept at
  `~/Library/Application Support/Claude/side-session-notes/local_f2c134b5-6951-46d4-9de2-485cd57ef9e7/bomb-freeze-keys-2026-11-22.log`.
- **Numbers (the bomb-freeze seat, 2026-11-22, at the staged head; S8b's were 491):**

| check | value |
|---|---|
| `Deimos/Core` (without the replay and campaign bundles) | **511 / 0 / 0** (Phase 4 ended at 491; + 20 keyboard-focus tests) |
| `DeimosReplayTests`, and `deimos-replay --all` | 4 / 0; four PASS lines, exit 0 |
| `DeimosCampaignTests` (one test at a time) | 3 / 0 (about 8 minutes for the longest) |
| HectorKit zero-skip | executed 370, 0 failed, the 4 known Aki 1.1 data skips (kit main ef2c341, unchanged) |
| app builds | Deimos Debug and Release: BUILD SUCCEEDED (Aki and BubbleTroubleX not rebuilt: nothing shared changed) |
| census file; layering grep | unchanged; empty |

- **Waiting on Ben:** (1) his first play of the staged app — the first launch of the front end ever, unless the line
  above says otherwise; (2) gate 4, "does the front end work like Deimos", and any of the card's numbered decisions he
  wants changed; (3) gate 3, "does the campaign play like Deimos", with its four named questions (flip pitch; sector
  12 ending with the Beamer alive; own overload while invulnerable; player 2's keys); (4) gate 2, "does level 1 play
  like Deimos". His notes from any gate become a fix wave first.
- **Where things are:** Phase 4 as executed: D58 and the section handoffs `docs/handoff-deimos-phase4-*.md`
  (history below); Ben's answers in `~/.claude/coordinator-notes/deimos-phase4-mailbox.md`; the OS X build
  compared with the OS 9 one (front end only) in `docs/deimos/osx-build.md`; the controller guide `Deimos/GAMEPAD.md`.
- **Next:** Ben's approval of the plan, then its Phase 5 (the order of tasks is in the plan's "Order" paragraph).
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
