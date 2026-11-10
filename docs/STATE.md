# STATE — Ambrosia Classics — 2026-11-08

Settled history lives in docs/STATE-history.md.

> Live state only, one dated block per game. This file is the one live state for every game, Ferazel's included (the
> chip `docs/NEXT.md` holds only the next run's instructions). Each close **replaces** its game's block with today's
> numbers and open items and moves anything settled to the top of `docs/STATE-history.md`; it never appends a run story
> here. Forks go in `docs/DECISIONS.md`, narrative in the handoff. Re-verify before acting.

## Ferazel's Wand — 2026-11-10 (attended run 47 closed; main bc31efa (the code head; the close documents sit on top), pushed; run 48 started 2026-11-10)

- **Where it stands:** Phase 5 "Enemies" is one task from its machine end. Waves 5.0–5.5 are done: every enemy class
  placed on levels 1–4 is alive, the later classes are built and machine-tested, level 5's moving sky (OmniPx modes
  2/4/5) draws, and **level 5 is enterable up to the Warrior's arena** — the arena locks at x 1384 with the 40-frame
  camera pan, the gate stays shut while the Warrior lives, level 5 plays its own track 23 throughout, and the Warrior
  stands as a Phase 6 stand-in (no AI, no rocks, no shot absorption; hurts on contact). Levels 1–5 enterable on Mac and
  Windows.
- **Next:** run 48 = A5 + the Fable cross-check = the Phase 5 end (GE both shells, the relabel sweep, both builds
  staged, the gate card to QUESTIONS for Ben). Ben held the chain for quota on 2026-11-08 and released it on 2026-11-10 ("trigger the next one"): run 47's close
  started run 48. Run 49 = the Phase 6 research and
  the 6A plan (does not wait for his verdict).
- **The plan:** `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` (self-contained); the design:
  `docs/superpowers/specs/2026-11-04-ferazel-remainder-design.md`.
- **Ben's gates:** Phase 1 passed; Phases 2 and 3 passed with notes; Phase 4 passed (Fireball note) and the Windows
  twin passed on Andrew's word (2026-11-07). After Phase 5: three gated Phase 6 parts (6A to the Goblin Chief, 6B to the
  Wizard and the fire, 6C the whole game), then one release `ferazel-1.0`.
- **Current numbers** (the seat's own runs at run 47's close, commit bc31efa, 2026-11-10):

| gate | value |
|---|---|
| Ferazel/Core suite (G2) | **619** = 486 rules + 133 render; 617 passed, 0 failed, 2 opt-in skips by name: `FerazelRenderTests.VisitSweepTests testVisitEveryObject`, `FerazelRenderTests.RandomPlayTests testRandomPlay` |
| FerazelWinKit (GW2) | **82** (run 47's leak fix added `WinGameReleaseTests`); 80 passed, 0 failed, 2 opt-in skips (`WinVisitSweepTests testVisitEveryObjectThroughWinGame`, `WinRandomPlayTests testRandomPlayThroughWinGame`) |
| census (G3) | items 1,108 decoded, failures 0 |
| visit sweep (GE, levels 1–5, both shells) | core 3,488 visits, windows 3,488 visits, rows 0 on both (teleports 15 / 15 arrived, level exits 37 / 37 reached the map), exit 0 — 4 workers under the new per-worker limit, 2026-11-10 |
| random-play bot (GE, levels 1–5, both shells) | core and windows each: levels 5, seeds 4, steps 108,000, deaths 14, exits 106, conversations 22, saves 1, failures 0; exit 0 (2026-11-10) |
| Proof B in CrossOver, muted (GWB) | **616 passed / 0 failed / 3 skipped / 0 crashed (of 619)**, 2026-11-10 |
| Mac SDL smoke (GW4R) | main menu identical (FNV 0xae2b1ee08c089b2a) |
| GW1 / GW3 / GW4 / G5 / G-MUTE | 0 then 2 / 0 then 1 / Build complete! / BUILD SUCCEEDED / 1 then 1 |
| HectorKit (G1) | main **ef2c341**, clean; zero-skip executed **370**; Ferazel follows HectorKit main |
| ladder from here | 619 → A5 619 (Proof B 616 / 0 / 3 / 0 of 619 at the phase end); the ladder runs +1 over the plan's October numbers since run 47 (the cross-check's geyser test) |

- **Goldens (◈, current; run 47 moved none on levels 1–4):** Phase 1 level-1 first frame `9db8f32f7e3d88b4`, highest
  tie-break `b80b0efd384ffdb9`, pan 30 `b1f4efcf3c34735f`, pan 60 `80d88efdc8fac27c`, chain `aaab15c0710cbcf7`; Phase 2
  level 2 `565e867a02736c18` / `b310ef334de49c00`, jump `deb577ecdeb64c58`, swim `3e99f74fa10e87e2` (particles [67,
  322]), 600-frame `0cce4b0446e2a48e` / cues `1b06b8a4117cf9dc` (cue words 3160, seed 1361095401, particles 150); Phase
  3 FE0 `ed142fed9e3bdce7`, map first frame `38563faaa2276f05`, map RNG `0x7b052a62`, sign frame `c8e41941c1e4d6da`;
  `BootFacesTests` level 3 f30 `0x56a7ccb0dd544488`, f120 `0xc43bacea46d2ff94`; **level 5 (new, first measured):** init
  46 / `0xb039da66a884cb8a`, f30 55 / `0x69068d5e8151b0cc`, f120 55 / `0xb9f08ee19927f3e7`; Windows smoke references
  menu `0xae2b1ee08c089b2a`, level 1 first frame `0xc99ce8e85b4bd8f7`, level-1 text `0xfbb2dd7a1d289726`.
- **Staged builds:** the Phase 4 / Windows-twin stages on the Desktop and Windows test builds 1–4 in
  `releases/ferazel-windows-test-*`; nothing staged since — A5 stages both.
- **Waiting on Ben (QUESTIONS.md "Open"; nothing blocks):** Q17, Q16 (defaults stand), Q15's follow-ups, Q13.
- **Worktrees:** `ferazel-run-44-7428b3` and `ferazel-run-45-f94cf1` are finished (merged, rebased SHAs) — the app
  refused the seat's `git worktree remove` in run 47; Ben removes them. `ferazel-run-47-e0431c` is this run's (merged).
  `heuristic-chandrasekhar-f66ade` (at c8d9cf5) is another session's; `inspiring-cannon-e97ccd` (Deimos) and
  `~/Developer/gamepad-wt/` are Ben's.
- **The sweep and the bot are guarded (2026-11-10):** a finished Windows-path game is now freed (the flow reaches
  `FerazelDriver` through a weak link; one worker stays near 290 MB over 928 visits, was +70 MB a visit), and both
  scripts kill any worker past `MAX_WORKER_MB` (4096) and brake below `MIN_RUNNING_FREE_PCT` (15) free memory, with a
  failure row. Stop a background run with `kill <script pid>`. A `memory` row is a leak to fix, never a limit to raise.
- **Open carries** [LOW unless marked]:
  - From the watchdog's last review (2026-11-10; all over-cautious or unlikely, none lets a worker run unguarded on a
    real Mac): when the wait before a worker start gives up it pulls the whole brake, killing healthy running workers
    (should-fix); if both `ps` and `top` give no reading a worker measures 0 MB and is never killed; the bot takes
    defaults for bot settings that are set but empty; `FERAZEL_VISIT_LIMIT` is not validated; huge limit values are
    accepted; the sweep does not clear a reused `OUT`; a worker-exit comment in `tools/ferazel-worker-watchdog.sh`
    overstates when the cleanup runs; the release test covers the sweep's game wrapper only (the bot's has the same shape).
  - From run 47: the ◇ Warrior's pre-lock rocks (type 1075) and its shot-absorbing Hit are Phase 6 (named on the gate
    card); the stand-in Handle's per-frame step is untested; the boss-music "music is on" check has no test with music
    off; the second camera bound and the 0x7f60 right-opening bound are unreachable on level 5 (untested); `try!` at
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
    `try!` at `PlayerStates.swift:291`; the gap ledger's tint lines still call the tint unbuilt; the orb argument check
    covers `Shots/` only.
  - Readings the machine cannot prove [MED]: voice eviction is not modelled in Core's `SoundVoices`; the underwater tint
    is applied as screen gamma; the OmniPx backdrop's look; the text smoothing mix is linear and its 14 pt threshold
    read from the Let's Play; the tint tables' colours [LOW].
  - Older small carries from Phases 2–4: listed in the history file's Snapshot B; each closes when a task next touches
    its file.

## Deimos Rising — 2026-11-08 (re-planned; waits for Ben's go)

- **Where it stands:** Phase 1 "level 1 look" gate passed 2026-10-07 (60 Hz tick; staged `~/Desktop/Deimos
  Rising.app`). Phase 2 "level 1 plays" is on branch `deimos-phase2` (worktree `.claude/worktrees/inspiring-cannon-e97ccd`,
  pushed, unmerged): waves 2.0–2.5 reviewed, 2.6 built; suite **313/0/0** on HectorKit ef2c341.
- **The plan:** `docs/superpowers/plans/2026-11-05-deimos-remainder.md` (self-contained since 2026-11-08). Next = wave
  2a (the audit's fix round → 318, merge the branch into local main, bank corrections), then 2b (C12 → 327, C18a → 335).
  The session brief is in `docs/handoff-2026-11-05-deimos-replan.md`, "Brief for the next session". **Waits for Ben's go.**
- **Data:** `Resources/Deimos/` in git; `deimos-census` 872 entries, 0 failures.
- **Open:** RE bank `docs/deimos/INDEX.md` #13, #59 residue, #62–#64 and 134 cross-file label mismatches; Ben's ear/eye
  items from the RE waves; Phase 1 carries for Phase 2 (a `DeimosAudio` target, the `playerOps` return type,
  `HeadlessRun` film parameters, the prefs file widening) as the plan places them.

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
