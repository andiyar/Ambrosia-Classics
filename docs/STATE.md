# STATE — Ambrosia Classics — 2026-11-11

Settled history lives in docs/STATE-history.md.

> Live state only, one dated block per game. This file is the one live state for every game, Ferazel's included (the
> chip `docs/NEXT.md` holds only the next run's instructions). Each close **replaces** its game's block with today's
> numbers and open items and moves anything settled to the top of `docs/STATE-history.md`; it never appends a run story
> here. Forks go in `docs/DECISIONS.md`, narrative in the handoff. Re-verify before acting.

## Ferazel's Wand — 2026-11-14 (attended run 52 closed: the Warrior is a real boss; wave 6A.1 built; two launch checks owed)

- **Where it stands:** Phase 5 "Enemies" is closed on the machine side — **Ben's gate pending (Q18)**. Phase 6A
  "through the Goblin Chief" is being built (the plan: "Wave 5 — Phase 6A" in the one plan file; rulings D46–D49).
  **Wave 6A.1 is built: 6A-BL, 6A-CF, 6A-FR (run 51), 6A-W1, 6A-W2 (run 52).** On level 5 the Warrior now walks, runs,
  swings and throws; three crates hang over his arena; Ferazel wins by climbing to the right-hand ledge and pushing
  crates onto him (ten crushes); his death opens the gate and ends the boss music. Levels 1–4 are unchanged.
- **Owed, first act of the next run that starts by day (09:00–20:59), muted:** Proof B (expect **647 / 0 / 3 / 0 of
  650**) and the Mac SDL smoke. Run 52 reached the wave end at 20:52. The wave's Fable cross-check is done (pass, no
  fixes).
- **Staged builds on the Desktop are old** (game code as e9183ce, run 50): they still show the stand-in Warrior. The
  next stage is the 6A phase end unless Ben asks for one.
- **Next:** run 53 = the two owed launch checks (by day), then 6A-FX (the level fixture), 6A-S8 ⚑ (the horizon strip),
  6A-WD ◈ (wind): Core 650 → 652 → 663 → 672. It does not wait for Ben's verdict.
- **The plan:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` (self-contained); the design:
  `docs/superpowers/specs/2026-11-04-ferazel-remainder-design.md`.
- **Ben's gates:** Phase 1 passed; Phases 2 and 3 passed with notes; Phase 4 passed (Fireball note) and the Windows
  twin passed on Andrew's word (2026-11-07); **Phase 5 waiting (Q18)**. Then three gated Phase 6 parts (6A to the Goblin
  Chief, 6B to the Wizard and the fire, 6C the whole game), then one release `ferazel-1.0`.
- **Current numbers** (Core suite, WinKit suite, GW4 and the census: the seat's own runs at run 52's code head 38ce1d9,
  2026-11-14; G5 / GW1 / GW3: the implementer's at bcc67f2; the full sweep and bot, Proof B and the launch gates: runs
  48 and 50, older code):

| gate | value |
|---|---|
| Ferazel/Core suite (G2) | **650** = 513 rules + 137 render; 648 passed, 0 failed, 2 opt-in skips by name: `FerazelRenderTests.VisitSweepTests testVisitEveryObject`, `FerazelRenderTests.RandomPlayTests testRandomPlay` |
| FerazelWinKit (GW2) | **82**; 80 passed, 0 failed, 2 opt-in skips (`WinVisitSweepTests testVisitEveryObjectThroughWinGame`, `WinRandomPlayTests testRandomPlayThroughWinGame`) |
| census (G3) | items 1,108 decoded, failures 0 (run 52) |
| level 5 quick checks (run 52, core) | bot: levels 1, seeds 4, steps 7200, deaths 1, exits 17, failures 0; visit sweep: 128 visits, rows 0, exit 0 |
| visit sweep (GE, levels 1–5, both shells) | core 3,488 visits, windows 3,488 visits, rows 0 on both — run 48, older code |
| random-play bot (GE, levels 1–5, both shells) | core and windows each: steps 108,000, failures 0 — run 48, older code |
| Proof B in CrossOver, muted (GWB) | **owed** (expect 647 / 0 / 3 / 0 of 650); last measured 617 / 0 / 3 / 0 (of 620), run 50 |
| Mac SDL smoke (GW4R) | **owed**; GW6 and G9M last passed in run 50 |
| GW1 / GW3 / GW4 / G5 | 0 then 2 / 0 then 1 / Build complete! / BUILD SUCCEEDED |
| HectorKit (G1) | main **ef2c341**, clean; zero-skip executed **370**; Ferazel follows HectorKit main |
| ladder from here | 650 → FX 652 → S8 663 → WD 672 (run 53) … 814 at the 6A end; WinKit 82 → 90 |

- **Goldens (◈):** level 5's pins moved in 6A-W1 for the three crates — init 46 / `0xb039da66a884cb8a` (held), f30 58 /
  `0x1142f7a252aecfcd`, f120 58 / `0x9806297cea4531f2`; nothing else moved. The Warrior's scripted fight is pinned:
  HP 0 at game frame 4966, Kill at 5051. All other values as the plan's "Goldens" paragraph lists them.
- **Waiting on Ben (QUESTIONS.md "Open"; nothing blocks; none answered at run 52's start):** **Q18 (the Phase 5
  gate)**, Q19 (three small choices in the 6A plan), Q17, Q16 (defaults stand), Q15's follow-ups, Q13.
- **Worktrees:** `gallant-brahmagupta-56ed81` is run 52's (merged). `eager-fermat-db9ed9` (run 51), `hungry-bun-395f55`
  (run 50; `out/` holds the latest stages), `compassionate-leavitt-7ca958` (run 49), `nifty-mendel-0ad40e` (run 48),
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
  - From run 52: **two launch checks owed (night rule)** — Proof B (expect 647 / 0 / 3 / 0 of 650) and the Mac SDL
    smoke; the staged builds on the Desktop are older than main and now differ visibly (the Warrior fights); rope
    segments check the 700-record cap outside `newSprite`, so `refusedSpawns` does not count them; no other enemy's
    hit row has the Warrior's "face bounds handed to the Hit" pin; two `preconditionFailure`s in `CachedFaces`
    (`set` / `single`, programmer errors only) are outside the trap census; the Chief's starting fight script (boss
    contract §3.9) is unproven — 6A-CH2 first finds how that fight is won (D49.1).
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

## Deimos Rising — 2026-11-14 (wave 2b done: the per-tick update and the Phase 2 session are in; wave 3 next)

- **Where it stands:** Phase 1 "level 1 look" gate passed 2026-10-07 (60 Hz tick; staged `~/Desktop/Deimos
  Rising.app`). Phase 2 "level 1 plays": everything built so far is on **local main, not pushed** (wave 2b merges
  bcddbe6 and 28194b9; `origin/deimos-phase2` left for Ben). The core now runs a whole level tick by tick in the
  original's order (entity update, world update, draw, end frame), plays demo films and pauses on Caps Lock; the
  app itself still shows the Phase 1 picture until wave 3 wires the driver, sound and keys. `Deimos/Core`
  **335/0/0** (without `DeimosReplayTests`) on HectorKit ef2c341 (370 executed: 366 passed + 4 Aki 1.1 skips);
  Deimos, Aki and BubbleTroubleX build.
- **The plan:** `docs/superpowers/plans/2026-11-05-deimos-remainder.md`. Next = wave 3 (C18b ∥ H2 first → 336 and
  344; then H3 ∥ A3; F1 only if the de01 replay gate is red; A4 stages) and then Ben's "level 1 plays" gate. The
  session brief is in `docs/handoff-2026-11-14-deimos-wave-2b.md`. Ben, 2026-11-14: sessions chain wave after wave
  until a hard stop that needs him.
- **Data:** `Resources/Deimos/` in git; `deimos-census` 872 entries, 0 failures.
- **Open:** RE bank `docs/deimos/INDEX.md` #13, #59 residue, #62–#64 and 134 cross-file label mismatches; Ben's ear/eye
  items from the RE waves; Phase 1 carries for Phase 2 (a `DeimosAudio` target, the `playerOps` return type,
  `HeadlessRun` film parameters, the prefs file widening) as the plan places them.
  From wave 2a: bank rows not independently confirmed (list in the 2026-11-14 handoff); the Deimos listing is
  not committed (`ghidra/deimos-proj` is a symlink) and the sound-library addresses appear in no listing on disk.
  From wave 2b (for H2 / A4): the driver's `.pauseWait` no-op and the re-firing pause under a held Caps Lock; the
  missing end-of-session halt on a pause-and-quit pass; the mouse button does not end a film yet; frame checks do
  not cover translucent or scaled draws or the pan-240 frame through an independent path; stale comments outside
  the cards (`ScrollState.step` "Phase 2", `Removal.swift:59` naming); `MotionBlurPool.emit` copies +0x90.

## Cythera — 2026-11-08 (re-planned; waits for Ben's go)

- **Where it stands:** Phase 0 half built (K1 on HectorKit, C0–C5); `Cythera/Core` **44/0/0** (34 core + 10 render) on
  HectorKit ef2c341; `Resources/Cythera/` 20 files; the decompile committed at `ghidra/cythera/`; no Cythera branch.
- **The plan:** `docs/superpowers/plans/2026-11-05-cythera-remainder.md` (self-contained since 2026-11-08). Next = wave 1
  session A (C8 → C9, suite → 57), then B (C6 ∥ C7 ∥ C10) and C (C13 → C11 → C12). The brief is in
  `docs/handoff-2026-11-05-cythera-plan.md`, "The brief for the next session". **Waits for Ben's go.**
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
