# Ferazel's Wand — the remainder: implementation plan (Phase 5 second half, Phase 6A/6B/6C, release)

> **For agentic workers:** this plan is executed one run at a time from `docs/NEXT.md` (the run's chip). Each task gets
> one `fk-implementer` and two `fk-reviewer` legs (spec, then quality, the second told what the first found), all Opus
> 5.5 with no `model` parameter; Fable 5.1 is the cross-check once per completed chunk — each phase plan and each phase
> end — never per task (Ben's model policy, 2026-10-07, 2026-10-13 and 2026-11-08). Plans in
> this house carry **contracts, not code** (Ben, 2026-10-03): files with line anchors, APIs, test names, commands,
> commit messages. Steps use checkboxes.

**Authority:** this file is the authority for the remaining work; the earlier plans and the audit are history.

**Goal:** finish Ferazel's Wand as the spec's "0. The game in one paragraph" defines it — every enemy, every boss, all 24
levels, victory, on Mac and Windows — then release it, in gates Ben can play.

**Architecture:** unchanged (spec "2. The shape of the program"): `FerazelCore` rules, `FerazelRender` pixels,
`Ferazel/Shared` driver, the Mac and Windows shells. Every remaining class lands in `World/Enemies/`, every engine
feature in the module that owns the original routine, every level in a `Level<N>Tests` file; the seam types only gain
cases.

**Paths** (every Files list is relative to `Ferazel/Core/` unless it starts with `Ferazel/`, `tools/` or `docs/`):
```
WT      = the run's worktree (branched from Classics main)        REPO = /Users/andiyar/Developer/Ambrosia-Classics
HK      = /Users/andiyar/Developer/HectorKit (read-only to Ferazel tasks; Ferazel follows its main — see G1)
SCRATCH = the executing session's scratch directory (mktemp -d)
DUMPS   = $WT/ghidra/ferazel/Ferazel_pef.decompiled.c (88,106 lines, cited "M l. N"), Ferazel_handlers.decompiled.c,
          Ferazel_pef.disasm.txt (cited "raw XXXXXXXX") — committed; never regenerated.
          Function finder: python3 $WT/ghidra/find_func.py '<regex>' --file <dump>   (--func <exact name> prints one)
          Bank tools: FZ_PEF=$WT/ghidra/ferazel/Ferazel_pef python3 $WT/docs/ferazel/tools/{const,pef,tocrefs,rsrc_census}.py
          (pef.py's built-in default path is stale — always set FZ_PEF)
          Gap-ledger tools: $WT/tools/ferazel/gap-{markers,routines,placements,resources}.py
CORE    = $WT/Ferazel/Core/Sources/FerazelCore      RENDER = $WT/Ferazel/Core/Sources/FerazelRender
TESTS   = $WT/Ferazel/Core/Tests/{FerazelCoreTests,FerazelRenderTests}
```
**Grounding.** Every function span here was computed from the committed dump's `// ==== name @ addr ====` headers. The
bank's "handler l. N" / "h. l. N" numbers come from older dumps — use the spans here and the raw addresses. Where the
dump disagrees with the bank or with this plan, **the dump wins** (Ben, 2026-10-07, "follow the binary"); the task's
"As executed" note records it. **Standing brief for every task (copy into each implementer and reviewer prompt):**
*re-read each cited M line in the committed dump before coding; the dump wins; record any disagreement in the task's
As-executed note.*

---

## Done before the remaining waves (runs 37–46; full notes for runs 37–45 are in the git history of the earlier plan)

| task | what landed | Core after |
|---|---|---|
| PB SP RV DK UT DA RB EC ES WK1 CR WK2 | wave 5.0–5.2: Proof B opt-in skips, sparkle scroll, reviewer items, dark-level light, underwater tint, draw-mode audit, random-play bot, enemy foundation, enemy shots, Walkers, Crawlers/Roaches, the 1760 and Ax goblin | 560 |
| RC | reconcile: HectorKit followed to its main, run 42's Bat cherry-picked, Ben's answers recorded | 560 → 569 (Bat in) |
| BAf ⚑◈ | the Bat's fix round. `ProgrammedPath` moved to `World/Movers/ProgrammedPath.swift` with the mode-10/11 Handle body; **the 1xx-form flag zeroes the swing SPEED (p3, `.MakeRadial`'s fifth argument), not the radius** (M l. 39310–39313, 39354–39378, 35737–35767). No golden moved | 569 |
| FR ⚑◈ | Frogs and Salamanders; the Frog's first aim test reads playerX (M l. 70358). No golden moved | 577 |
| BL ⚑ | Blobs and Crabs; `EnemyCommon.killProc` keeps only real Kill-proc arms (default arm `+0xe9 = 1`); `BootFacesTests` level-3 pins moved for the Blob turning on (switch-off held) | 584 |
| GF ⚑ | Gremlins and Wraiths; `ProgrammedPath.makeRadial`'s first caller is the Gremlin Setup (modes 10/11 admitted there; the Bat still refuses them) | 591 |
| DL | the Dillo; unplaced types 1872–1879 refused at Setup (◇) | 596 |
| GY ⚑ | geysers; the head sorts at layer 2; only segments hurt enemies; kinds 3/4 face draws nothing past the 12-face cache (◇) | 603 |
| PI | the enemy pipes; a pipe waits for its child to die before the next (card and As executed in wave 2 below) | 607 |
| PT | the renderer's 18 traps → 7 refusals + 11 census-pinned traps; OmniPx modes ∉ {0, 2, 4, 5} and a horizon strip refused at level open; wave 5.4 closed (card and As executed in wave 2 below) | 607 |

Process lessons that bind every remaining task (from those runs): comments move `DrawModeAuditTests`' line-anchored
writer rows — every task re-runs `--filter DrawModeAuditTests` and re-anchors moved rows (values unchanged); a class
turning on may move a `BootFacesTests` 120-frame pin even when no golden moves — that pin is ◈ for its cause, with the
switch-off check; a headless session has no face pixels, so a burn never ends there (deaths by burn do not complete in
headless tests). From run 46: two implementers can work at once — one in the worktree, one in a scratch `git clone`
at the same base, cherry-picked after — when their files are disjoint or touch one file in different regions (PI and PT
both edited `DrawModeAuditTests.swift`, no conflict).

---

## 0. The verification model (read before any dispatch)

| rule | what it means here |
|---|---|
| Numbers from the seat's own runs | every count in a close note comes from a command the seat ran (G2 in a background shell from a `git archive` copy); a subagent's number is never relayed on faith |
| One implementer + two Opus review legs per task (Ben, 2026-11-08) | leg 1 checks the work against the card (spec); leg 2 checks quality and builds a mutation table (it has found 20–40 unpinned behaviours per class task, every time), told what leg 1 found so they check each other; the fix round is tests-only unless the dump says otherwise; a large fix round gets a re-review |
| The seat briefs; it does not pre-read | the seat hands each leg the card, the dump / source line range and the test names; the leg anchors to file:line itself. The seat never reads source before a dispatch — a grep confirming that a symbol exists is enough (Ben, 2026-11-08) |
| Fable cross-check | once per completed chunk (Ben, 2026-11-08): each phase plan (after its two Opus legs), each closed wave (the wave's whole diff plus its gate numbers, before the next wave's first task) and each phase end (the whole phase diff, Mac + Windows, and the gate card), before staging; never per task. Wave 5.4 (runs 44–46) closed under the older rule with one Opus leg per task and no Fable pass: run 47 opens with that cross-check. A Fable seat does it itself; an Opus seat dispatches `fk-reviewer` with `model: "fable"`, named "Fable cross-check" in its brief, foreground |
| Reviewers run things | each leg builds in **its own `mktemp` copy** (never a shared scratchpad folder) with its own `WIN_BUILD_ROOT` and HectorKit symlink, re-runs the task's test class, and confirms one numeric prediction (a golden, a count) |
| The dump beats the bank beats the plan | every brief: "re-read each cited M line in the committed dump before coding; record disagreements in As executed" |
| ◈ goldens move only for the named cause, with the switch-off check | implementer and leg 1 independently: **stub the class's Handle body (and any hit it adds) with one local patch, never committed; every old value must return; revert.** Setting the class's `SpriteHandler.forClass` row to `.inert` switches nothing off — every class Setup stores its own handler (`Walker.swift:92`, `CrawlerRoach.swift:57`, `Bat.setup`) |
| STOP on any unexpected number | any other moved value, total, skip, hash or census line: STOP, reconcile, record; never edit an expectation or the code to make them agree |
| Scope fence (G6) | the diff ⊆ the task's Files (+ `docs/DECISIONS.md`, the bank file a correction names, this plan's As-executed note) |
| Launches | only muted, few and short, and never between 21:00 and 09:00 Mac time (Ben's ruling, 2026-10-26); never by planning or audit sessions; agents never launch to "just look" |
| Ben's gate | a phase closes on the machine side only: "machine gates green; Ben's gate pending" |
| Context | 300k per run; the seat reads its meter (`get_usage`) before each dispatch and at the close; 2 tasks a run (3 when at most one is ⚑); at ~240k it finishes the task in flight and closes; a run that cannot merge records why in LOOP-LOG + QUESTIONS and keeps its worktree |
| Current-only STATE and chip | `docs/STATE.md` holds the live state only and `docs/NEXT.md` the current run only; at every close the finished run's story goes to `docs/STATE-history.md`, the LOOP-LOG line, the DECISIONS as-built paragraph and the handoff — never kept in STATE or the chip (Ben, 2026-11-08) |
| The seat never waits silently | the looper's watchdog ends a session after 45 silent minutes: long gates run in background shells, and the seat polls with `stat -L` on the log or transcript, printing each time |
| Memory (Ben's RAM rule, 2026-10-30) | never two whole suites or sweeps at once (Core suite, WinKit suite, visit sweep, bot); the sweep and the bot run with at most 4 workers; one seat gate run in a `git archive` copy beside one working implementer, or two review legs alone. **Per-worker limit (2026-11-10, after the sweep's kernel panics of 2026-11-08 and 2026-11-10):** both scripts watch every running worker (every ~3 s, the larger of `ps` resident size and `top`'s footprint) and kill it past `MAX_WORKER_MB` (default 4096) with a `memory` row and exit 1, never restarting it; below `MIN_RUNNING_FREE_PCT` (default 15) free machine memory every worker is killed (`tools/ferazel-worker-watchdog.sh`; `tools/ferazel-watchdog-selftest.sh` proves it with stand-ins). Bad settings refuse to start (exit 2); the wait for free memory refuses instead of continuing; stop a background run with `kill <script pid>`. Never raise the limit to get a sweep through: a memory row is a leak to fix |

**Lockstep (Ben, 2026-10-26: Windows after Phase 4, then kept in step).** (a) A task that changes what the Mac app
shows or does — `Ferazel/App`, `Ferazel/Shared`, a new `ShellRequest` / `FerazelDialog` case, a new text face, a new
data file — carries its Windows side in the same task (FerazelWinKit / FerazelWin change + GW2 tests + GW3), and its
Files list names both. (b) A Core-only task runs GW1, GW2, GW3, GW4 and G5 — a Core API change can break the shared
files, the Windows package or the Mac app without touching them. (c) A change to `Ferazel/Shared` is reviewed for both
shells. (d) A text-path change re-runs `fz-bake-font` and commits the `.fzfont` files. (e) Every phase end stages both
builds (`tools/stage-ferazel.sh` + `tools/windows/stage-ferazel-win.sh`) with ONE gate card that has a Mac part and a
Windows part, and the Fable phase review covers both diffs.

### Machine gates (executors close these alone; copy the commands literally)

| # | gate | expected |
|---|---|---|
| G1 | HectorKit | clean; at the SHA `docs/STATE.md` records, or a later clean main that passes `tools/check-zero-skip.sh` with 0 failed and executed ≥ the recorded floor (then the run records the new SHA + floor in STATE and LOOP-LOG). Ferazel follows HectorKit main (Ben, 2026-11-07); "no HectorKit change" means none *by a Ferazel task*. At 2026-11-08 (run 46): ef2c341, executed 370 (366 passed + 4 Aki 1.1 skips — a machine data-path matter, accepted) |
| G2 | `Ferazel/Core` suite | total = the task's ladder number; **0 failed**; skipped = **exactly the opt-in list, checked by name**: `FerazelRenderTests.VisitSweepTests testVisitEveryObject` and `FerazelRenderTests.RandomPlayTests testRandomPlay`. Run as **two commands** — `--filter FerazelCoreTests` (the rules tests, ~1 min) then `--filter FerazelRenderTests` (the render tests, ~12 min, the slow part); the totals add up to the ladder. Run once per task at merge by the seat, in a background shell with a 40-minute timeout, from a `git archive` copy; implementers and reviewers run `--filter <Class>` per touched class and never end a turn while anything runs. At 2026-11-08 (run 46): **607** = 479 rules + 128 render, 0 failed, exactly the two opt-in names |
| G3 | census | `0`, `Totals: items 1,108 decoded, failures 0` (every wave end, and whenever `Resources/` or a decoder changes) |
| G5 | Mac app builds | `** BUILD SUCCEEDED **` — every task (lockstep (b)) |
| G6 | scope fence | ⊆ the task's Files (+ DECISIONS / the named bank file / this plan's As executed) |
| G7 | layering | the greps empty (`Sources/ferazel-census` excluded); G7b no `UserDefaults`/`NSSavePanel`/`NSOpenPanel` in `Ferazel/Core/Sources` |
| G8 | file hygiene | `git -C "$WT" status --porcelain --ignored -- Resources ghidra` prints nothing new; tests write only under the temporary directory |
| G10 | clean tree per commit | empty |
| GW1 | Core + tests cross-build | exit 0, then `2` |
| GW2 | FerazelWinKit (macOS-hosted) | **82** total at the Phase 5 end; the 6A ladder is in Wave 5 (81 until run 47's sweep-leak fix added `WinGameReleaseTests`); 0 failed; skipped = exactly `WinVisitSweepTests testVisitEveryObjectThroughWinGame` and `WinRandomPlayTests testRandomPlayThroughWinGame` (~13 min: background it) |
| GW3 | the game cross-builds and links | exit 0, then `1` |
| GW4 | the Mac SDL development build compiles | last line `Build complete!` — every task (GW2 does not build the `FerazelWin` executable target) |
| GW-symlinks / G-MUTE / G7W | | empty / `1` then `1` / empty |
| GWB | Proof B (launch gate, by day, muted) | `proof-b: P passed / 0 failed / S skipped / 0 crashed (of N)`, N = the Core ladder at that commit, S = 3 (one Wine-only skip + the two opt-in skips), P = N − 3 |
| GW4R / GW5 / GW6 / G9M | launch gates (GW5 any hour) | below |
| **GE** | **phase-end checks** | visit sweep `both` exit 0 · random-play bot `both` exit 0 · the load-every-face tests (`BootFacesTests`, `FaceTests.testEverySpawnableTypeHasSheet`, inside G2) pass · `DrawModeAuditTests` inside G2. **A phase cannot close while any fails** (Ben, 2026-10-29). The full sweep and bot run after each level task and at each phase end — not at every wave end (Ben, 2026-11-08); a class task runs only the bot's quick mode on the levels it brings to life |

**Opt-in tests.** Proof B accepts exactly one Wine-only skip plus the opt-in skips. A task that adds an opt-in test
edits, in the same commit, `tools/windows/proof-b-ferazel.sh:21–22` (its environment switch on the clearing line) and
`:126–127` (the opt-in list), and this table's G2/GW2 skip lists and GWB's S.

```sh
WT=$PWD; SCRATCH=$(mktemp -d)
WINB=$HOME/Developer/Toolchains/windows-cross/build/ferazel   # never the default root
# G1 HectorKit: empty; the SHA STATE records (or a later clean main → the zero-skip check, then record SHA + floor)
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1
HECTORKIT_DATA_AKI11="$REPO/Resources/Aki/1.1.0.app/Contents/Resources" bash ~/Developer/HectorKit/tools/check-zero-skip.sh   # only when HK moved; background, ~5 min
# G2 suite, two commands (background, 40-min timeout, from a git archive copy): (1) the ladder total, (2) 0, (3) exactly the two opt-in names
cd "$WT/Ferazel/Core" && swift test --filter FerazelCoreTests > "$SCRATCH/fz-core.log" 2>&1; swift test --filter FerazelRenderTests > "$SCRATCH/fz-render.log" 2>&1
cat "$SCRATCH/fz-core.log" "$SCRATCH/fz-render.log" | grep -cE "^Test Case '.*' (passed|failed|skipped) \("
cat "$SCRATCH/fz-core.log" "$SCRATCH/fz-render.log" | grep -cE "^Test Case '.*' failed \("
cat "$SCRATCH/fz-core.log" "$SCRATCH/fz-render.log" | grep -oE "^Test Case '[^']*' skipped" | sort
#   Test Case '-[FerazelRenderTests.RandomPlayTests testRandomPlay]' skipped
#   Test Case '-[FerazelRenderTests.VisitSweepTests testVisitEveryObject]' skipped
# G3 census: 0 / Totals: items 1,108 decoded, failures 0
cd "$WT/Ferazel/Core" && swift build -c release --product ferazel-census > /dev/null && "$(swift build -c release --show-bin-path)/ferazel-census" "$WT/Resources/Ferazel" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"
# G5 Mac app builds: ** BUILD SUCCEEDED **
cd "$WT" && xcodegen generate --quiet && xcodebuild -scheme Ferazel -derivedDataPath "$SCRATCH/dd" build 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)"
# G6 scope fence
git -C "$WT" diff --name-only "$TASK_BASE"..HEAD
# G7 layering + G7b
grep -rlE '^import (AppKit|CoreGraphics|AVFoundation|Metal|QuartzCore|SwiftUI|UIKit)' "$WT/Ferazel/Core/Sources" | grep -v ferazel-census
grep -rnE 'UserDefaults|NSSavePanel|NSOpenPanel' "$WT/Ferazel/Core/Sources"
# G8 file hygiene
git -C "$WT" status --porcelain --ignored -- Resources ghidra
# G10 clean tree after every commit
git -C "$WT" status --porcelain | grep -v '^??'
# GW1 Core + its tests cross-build for Windows (build only): exit 0, then 2
WIN_BUILD_ROOT="$WINB" "$WT/tools/windows/build.sh" "$WT/Ferazel/Core" all --tests > "$SCRATCH/gw1.log" 2>&1; echo $?
grep -cE '/(FerazelCorePackageTests|ferazel-census)\.exe$' "$SCRATCH/gw1.log"
# GW2 the Windows package's macOS-hosted tests: 82, 0, the two Windows opt-in names (background, ~13 min)
cd "$WT/Ferazel/Windows" && swift test > "$SCRATCH/fw.log" 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/fw.log"
grep -cE "^Test Case '.*' failed \(" "$SCRATCH/fw.log"
grep -oE "^Test Case '[^']*' skipped" "$SCRATCH/fw.log" | sort
#   Test Case '-[FerazelWinKitTests.WinRandomPlayTests testRandomPlayThroughWinGame]' skipped
#   Test Case '-[FerazelWinKitTests.WinVisitSweepTests testVisitEveryObjectThroughWinGame]' skipped
# GW3 the game cross-builds and links for Windows (build only): exit 0, then 1
WIN_BUILD_ROOT="$WINB" "$WT/tools/windows/build.sh" "$WT/Ferazel/Windows" FerazelWin --sdl > "$SCRATCH/gw3.log" 2>&1; echo $?
grep -cE '/FerazelWin\.exe$' "$SCRATCH/gw3.log"
# GW4 the Mac SDL development build compiles (build only, nothing launched): Build complete!
cd "$WT/Ferazel/Windows" && swift build --product FerazelWin 2>&1 | tail -n 1
# G7W layering for the shared/Windows code: empty
grep -rlE '^import (AppKit|Carbon|CoreGraphics|CoreText|AVFoundation|Metal|QuartzCore|SwiftUI|UIKit|HectorShell|HectorSDL|CSDL3)' \
  "$WT/Ferazel/Shared" "$WT/Ferazel/Windows/Sources/FerazelWinKit" | grep -v '/CoreTextRasterizer\.swift$'
# GW-symlinks: empty
zsh -c 'for f in "$1"/Ferazel/Shared/*.swift; do n=${f:t}; git -C "$1" ls-files -s "Ferazel/Windows/Sources/FerazelWinKit/$n" | grep -q "^120000" || echo "missing $n"; done' _ "$WT"
# G-MUTE: 1, then 1
grep -rn 'ShellMixer(' "$WT/Ferazel/App" "$WT/Ferazel/Shared" | wc -l
grep -rn 'NSSound\.beep()' "$WT/Ferazel/App" | wc -l
```

Launch gates (by day only, muted, each right after the guard; a run outside 09..20 skips them and writes "boot check
owed (night rule)" in LOOP-LOG and on the gate card):
```sh
# LAUNCH GUARD
h=$(date +%H); (( 10#$h >= 9 && 10#$h <= 20 )) && echo "launch ok ($h)" || echo "boot check owed (night rule) ($h)"
# GWB Proof B (every wave end that touches Core or Windows, by day; run once whole; the script mutes itself)
"$WT/tools/windows/proof-b-ferazel.sh"          # proof-b: P passed / 0 failed / 3 skipped / 0 crashed (of N)
# GW4R the Mac SDL development build, headless (only through the smoke script): exit 0; a line ending "video=dummy audio=none"
"$WT/tools/windows/smoke-ferazel-win.sh" --mac-only
# GW5 stage (phase end; any hour; commit first — it refuses uncommitted content): exit 0, subsystem 00000002, manifest diff empty
"$WT/tools/windows/stage-ferazel-win.sh" --no-desktop; echo $?
# GW6 the staged zip boots in a clean CrossOver bottle, muted (phase end, after a fresh stage of HEAD): "main menu: identical", "new game: identical", "level 1 text: identical", exit 0
"$WT/tools/windows/smoke-ferazel-win.sh"
# G9M the Mac staged app boots MUTED (phase end)
APP="$WT/out/Ferazel/Ferazel's Wand.app"; open -n "$APP" --args -FerazelMute YES; sleep 5; pgrep -fl "Ferazel's Wand" | cut -c1-100; osascript -e 'tell application "Ferazel'"'"'s Wand" to quit'; sleep 2; pgrep -fl "Ferazel's Wand"; ls -t ~/Library/Logs/DiagnosticReports | head -n 3
```
The CrossOver mute is `HECTOR_SDL_AUDIO_DRIVER=dummy` plus the game's `--mute`; the scripts set both.

Phase-end checks (GE; headless, no window, no audio — allowed at any hour):
```sh
OUT=$SCRATCH/visit tools/ferazel-visit-sweep.sh both > "$SCRATCH/visit-sweep.txt" 2>&1; echo "exit $?"      # exit 0
OUT=$SCRATCH/bot   tools/ferazel-random-play.sh both > "$SCRATCH/random-play.txt" 2>&1; echo "exit $?"     # exit 0
grep -E "^== (core|windows):" "$SCRATCH"/visit-sweep.txt "$SCRATCH"/random-play.txt                         # summary lines → gate card
#   the sweep prints its summary at tools/ferazel-visit-sweep.sh:91; the bot prints
#   `== core: random play — levels L, seeds S, steps T, deaths D, exits E, conversations C, saves V, failures F in W s`
#   and the same for `windows`. Quick mode for one level: tools/ferazel-random-play.sh core (one level, 60 s).
```

**Ladders** (Core G2 total; 2 opt-in skips throughout; WinKit 81 / 2 until run 47's sweep-leak fix, 82 / 2 from it, unless a row says otherwise). The Phase 5 ladder
runs one above its original numbers because Ben's commit 3cf72df (world-map status bar, 2026-10-30) added one test:

| after | Core | GWB at wave end (by day) |
|---|---|---|
| GY (run 45, done) | 603 | 600 / 0 / 3 / 0 (of 603) |
| PI (run 46, done) | 607 | — |
| PT (run 46, done; wave 5.4 end) | 607 = 479 + 128 | 604 / 0 / 3 / 0 (of 607) — measured |
| wave 5.4 Fable cross-check fix round (run 47; one geyser test by the seat's ruling) | 608 | — |
| OX ⚑ (run 47, done) | 613 | — |
| LV5 ⚑ (run 47, done; wave 5.5 end) | 619 | 616 / 0 / 3 / 0 (of 619) |
| A5 (Phase 5 end; run 48, done) | 619 | — |
| Phase 5 Fable cross-check fix round (run 48; one burn-away test by the seat's ruling) | **620** = 486 + 134 | 617 / 0 / 3 / 0 (of 620) — measured by day 2026-11-11 (run 50, ee0fa6e) |

The wave 5.4 end measured in run 46: G3 `Totals: items 1,108 decoded, failures 0`; GE `core` on levels 1–4 — visit
sweep 3,360 visits / 0 failures, bot 86,400 steps / 0 failures; GW4R main menu identical; GW1 0 / 2, GW2 81 / 0 / 2,
GW3 0 / 1, GW4 and G5 green. From here the ladder was **607 → OX 612 → LV5 618**; run 47 measured 608 → 613 → **619** (the cross-check's +1).

Review fix rounds add asserts, not tests, unless the seat rules otherwise (recorded in As executed). Merged out of
order: previous + the task's N. The 6A ladder is in Wave 5's "Verification-model additions for 6A" (Core 620 → 814,
WinKit 82 → 90 from 6A-L10L11 on); 6B's and 6C's are set by their own planning runs.

**Goldens (◈).** The values live in the test files (`FrameGoldenTests`, `Phase2GoldenTests`, `BootFacesTests`,
`WinReferenceFramesTests`); at c8d9cf5 (after run 46 — PI and PT moved none) they are: Phase 1 level-1 first frame `9db8f32f7e3d88b4`,
highest tie-break `b80b0efd384ffdb9`, pan 30 `b1f4efcf3c34735f`, pan 60 `80d88efdc8fac27c`, chain `aaab15c0710cbcf7`;
Phase 2 level 2 `565e867a02736c18` / `b310ef334de49c00`, jump `deb577ecdeb64c58`, swim `3e99f74fa10e87e2` (particles
[67, 322]), 600-frame `0cce4b0446e2a48e` / cues `1b06b8a4117cf9dc` (cue words 3160, seed 1361095401, particles 150);
Phase 3 FE0 `ed142fed9e3bdce7`, map first frame `38563faaa2276f05`, map RNG `0x7b052a62`, sign frame
`c8e41941c1e4d6da`; the Windows smoke references menu `0xae2b1ee08c089b2a`, level 1 first frame `0xc99ce8e85b4bd8f7`,
level-1 text `0xfbb2dd7a1d289726`. **Only a task marked ◈ may move a golden, and only for the cause it names**, with
the switch-off check; it lists every golden's old → new in its commit body and As executed. The Windows references live
in two copies today — `tools/windows/smoke-ferazel-win.sh:63–67` and `WinReferenceFramesTests.swift:39–47` (written
with underscores, so a grep for the hash misses the test copy; also the two hash lines in `tools/windows/README.md` — grep for each hash) — a ◈ task that
moves one edits all of them until A5 makes the script read the test file. FE0 and the map first frame hold for the
whole remainder.

**What the machine does NOT prove:** the feel of every enemy's AI at 30 steps a second; the colours of the tint tables
(through the replica's colour search, LOW); the underwater tint's strength on screen (gamma, MED); the OmniPx
backdrop's look (MED); sound by ear. Agents cannot screenshot on this machine.

---

## Invariants and hazards (every task)

1. **Layering.** Core: Foundation + HectorResources (+ HectorInput) only. Enemy state, the counting window, the arena
   globals, the OmniPx counters and positions are Core state; pixels (the OmniPx port, the burn clip, the darkness
   tables) are Render's; the shells only present, play and pass the playing set.
2. **Transcribe, don't reinvent.** Every behaviour cites its bank section and the dump span; if they disagree, follow the
   dump and record it (the plan is wrong against the dump about once a task).
3. **Frame order is the binary's**: sprites created inside a Handle run this frame only if inserted after the saved
   `next`; a Setup runs inside `.MTNewSprite` before the insert, so its draws precede the caller's next draw; the player
   is reached only by `.MTCollideSpecialSprite` — enemy contact damage is `.HitPlayerSprite`'s, never the enemy's Hit.
4. **One RNG stream**: every `FastRand` at its call site in the binary's order — `STPlay3DSoundRand`'s pitch draw even
   with sound off; idle-only calls (`FUN_100916dc`) through `SoundVoices`; goblin cries' voice tests and stops are
   global over all voices.
5. **The counting window**: `+0x1b5` and the live-enemy count `_DAT_1009ffb4` are set by a Setup only while
   `_DAT_1009fe8c` is set (around `.SetupLevelSprites`, raw `10004da4..10004dc0`). Pipe children, spawned shots and
   re-activated idle sprites are never counted.
6. **Stubs are named** (`// later: <phase>` / ◇), never simplified away; each keeps the original's surrounding draws and
   state.
7. **No modern affordances** (Ben's standing 100 % rule): no health bars, hit numbers, enemy highlighting, difficulty
   change, auto-aim beyond the original's homing.
8. **No refusal reachable**: a task that makes a new draw input reachable (a mode, a rotation, a clip, a face, a light
   case, a backdrop) makes the renderer draw it as the binary does **in the same task**, adds it to
   `DrawModeAuditTests`' table, and names it in As executed. A renderer refusal reachable from shipped data in a built
   level is a STOP, never a test to skip. Refusals stay refusals — the game quits loudly, and the phase-end checks make
   that unreachable (Ben's default, 2026-11-07). Since PT, `DrawModeAuditTests` counts FerazelRender's `precondition(` /
   `preconditionFailure(` per file as well as its throws: a new trap or throw without a census row fails the suite — a
   new trap is either proven unreachable from any data (a "trap: unreachable" row) or made a refusal.
9. **Seam types are locked**: cases and fields may be added, never renamed or retyped.
10. **STOP on any unexpected number** — report; never edit an expectation or the code to make them agree.
11. **Commits.** Explicit paths only; never `git add -A`/`.`; never `git stash`; verify `git branch --show-current` before
    every commit; trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; G10 after each commit.
12. **Landmines.** `Ferazel/FerazelCore` is a symlink to `Core`; the app name has an apostrophe — quote every path. Swift
    `>>` binds tighter than `&*`/`&+`. A `SpriteSlot` copy held across a call that can create or move sprites and
    written back loses their writes (`SpriteWorld.swift` rule 2) — every enemy Handle spawns. Foreground subagents only
    (seat gates may run in background shells). Ben may commit to local main mid-run → rebase before merge, re-run G2.
    The next free decision number is checked in `docs/DECISIONS.md` at commit time (several projects share the ledger).

**Hazards (read before any dump reading).** Copy loops; TOC-load ≠ write count; `.StandardSpriteHandles` zeroes
per-frame fields; the signed-compare idiom; live key reads; globals vs fields; nested blocking loops become explicit
states; sound handles are TOC slots (pickups-boxes-2 §1.2); colourised CopyBits. And:
- **Class is the Handle, never the type.** Enemy-shot types reuse the spawner type space; every "is it a Walker?" test
  in the dump compares `+0x4c`. Model it as `SpriteSlot.handler`, never `type`.
- **`+0x1b2` (pipe emergence):** every class Handle returns at once while set; the sprite is still drawn and still
  collidable as the inner sprite of `.MTCollideSprites` (enemies-flyers §7.4).
- **Idle children:** swarm members and the insect body are `MTNewSprite` children with record 0x200 — never idled, never
  counted; they keep running while their parent is idle.
- **`.IdleToActiveSprite` (M l. 4215–4275) re-runs no Setup:** it calls `.MTNewSprite` with setup 0, restores the
  0x220-byte snapshot, clears `+0xe9` (M l. 4264), writes `+0xa8` = the idle index (M l. 4265), calls the sprite's
  `+0x58` proc if one is set (M l. 4266–4268), and kills the sprite at once when its restored `+0x4c` or its type is 0.
- **The 16-voice pool:** `FUN_100916dc(x)` counts voices playing x (0 = all); `FUN_10091504(x)` stops every such voice —
  `SoundVoices` answers the first, `FrameOps` stop cues carry the second.
- **No free record:** a spawn that finds all 700 records in use runs no Setup and makes none of its draws; stores to it
  are dropped; the caller's later draws are still made.

**Function spans the remaining waves cite** (from the dump's headers): Warrior 72975–73532 (Init 72975–72988, Setup
72989–73079, Kill 73465–73493); OmniPx 13019–13547; `.PlayerConstraints` 43991–44126; `.FindUpperLeftCorner`
5882–6239; `.GameLoop` 5093–5328; `.SetupLevelSprites` 1940–2103; `.SetupLevel` 2189–2590; `.PaintFrameWrap`
9104–9463; `.MTCollideSprites` 30216–30373; `.MTCollideSpecialSprite` 30374–30551; `.HandleBoxSprite` 60030–61180;
`.LoadCachedSpriteFaces` 73769–73869; `.HitPlayerSprite` 48445–49929; `.SmiteEnemies` 46981–47046.

---

## Shared architecture for the remaining waves (code against these names)

- **Packages:** no new target, no `Package.swift` change in either package. Enemy tests in
  `Tests/FerazelCoreTests/Enemies/`.
- **`SpriteHandler`** cases exist for every Phase 5 class (`.walker` … `.geyserSegment`, `.warrior` ◇). `.inert` stays
  for the four bosses not placed on levels 1–5 until their Phase 6 tasks.
- **`BossArena`** (LV5, `Camera/BossArena.swift`, new): `noBossAlive` (`_DAT_1009fed0`), `locked` (`PTR_DAT_1009fed4`),
  `panCounter` (`_DAT_1009ff9c`); `.PlayerConstraints`' arena part (M l. 43991–44126) and `.FindUpperLeftCorner`'s
  bounds (M l. 5882–6239) read them; `.SetupLevelSprites` clears `locked` and sets `noBossAlive = 1` before spawning
  (M l. 2016–2019).
- **`OmniPx`** (OX, `World/OmniPx.swift`, new): mode (`hdr+0x26c7`), the 16 face refs, fx/fy/vx/vy/accX/accY (16 × i16
  each), the counter `c` (BSS, **never reset between levels** → rides `LevelCarry`), the on-flag `G+0x174` (the existing
  `GameGlobals.omniPxActive`, `GameGlobals.swift:67` — reused); `setup(level:)` (M l. 13125–13297), `turnOn` (M l.
  13019–13060), `update()` (M l. 13393–13519, drawn frames only, at M l. 9434 — after `DrawParticles`, before the copy).
- **Seam addition:** `DrawOp.omniPx(OmniPxFrame)` (OX) — one `.UpdateOmniPx` at M l. 9434: the base cell and the two
  faces' (x, y) for this drawn frame; Render composites the 128×128 port. `FrameRenderer` executes it as PxBack slot 0
  for the backdrop compositor, the factors zeroed for modes 1–3 and ≥ 8 as `.TurnOnOmniPx` does.
- **`BuiltLevels.list`** (`Front/BuiltLevels.swift`, `[1, 2, 3, 4, 5]` since 6A-BL, run 51 — an explicit sorted list;
  every reader asks `contains`), with the report "Level n is not built yet (Phase 6)."; the scripts read it through
  `tools/ferazel-built-levels.sh`, and each level task adds its ids.
- **Faces of run-time-spawned sprites:** every task that spawns a type at run time adds its sheet where the original
  loads it — the boot list `Sprites/BootFaces.swift` or the level-load picture cache (`Front/LevelRun.swift`
  `CachedFaces`: `sets`, `singles`, `marks`, `handleSets`), registered **at the original's position** in `.InitSprites`'
  registration order (M l. 106–145) and `.LoadCachedSpriteFaces` (M l. 73769–73869) — never `FrameRenderer.swift`,
  which only consumes the two lists. `FaceTests.testEverySpawnableTypeHasSheet` and `BootFacesTests` gain asserts.
- **Every class task also:** wires its class's Statue arm (its Hit routine's branch to `.TurnIntoStatue`), its Smiting
  reaction, its liquids and environmental hazards (`EnemyCommon` helpers), its Kill bookkeeping
  (`EnemyCounting.kill`: `+0xe9 == 0 && +0x1b5 ≠ 0` → live − 1 and the level stat + 1; then `+0xe9 = 1`), its idle
  margins, its picture-cache marks, and **its save write-back flags** `+0x188`…`+0x18b` and `+0xea` set at the dump's own
  sites (a test row in its Setup test per flag the dump writes); names `Session/FerazelSession.swift` in Files (the
  Handle and hit dispatch rows); runs the bot's quick mode on the levels it brings to life and records the `== core:`
  line.
- **Files lists name every flow / renderer / test seam the task touches;** a file found missing is added and recorded in
  As executed (G6 reads the amended list).

---

## Risk waves

| wave | what | risk it retires | runs |
|---|---|---|---|
| 2 (rest) | PI, PT — wave 5.4 end (done) | the last Box arm of Phase 5; the renderer's traps | 46 |
| 3 | OX, LV5; then A5 + the Fable phase review → Ben's gate | level 5 and the first engine feature (OmniPx); "through the first boss door" | 47–48 |
| 4 | Phase 6 research: LL later-level ledger, BOS boss contracts, ENG engine-feature contracts; then the 6A plan | every Phase 6 number measured before a build task exists | 49 |
| 5 | Phase 6A — the Warrior's fight, the engine features of levels 10–22, levels 10–22 enterable, the Goblin Chief; gate | the first two boss fights; eleven new engine features (strip, wind, cannons, trees, ripple, rain, clouds, blade, mace paths, carpet, rocks) | 13 (runs 51–63) |
| 6 | Phase 6B — levels 25–52, the Wizard, ice, timer, CLUT animation, auto-scroll, fire; gate | the renderer's last big features | ~7 |
| 7 | Phase 6C — levels 55–70, the Fire Guardians, Xichra's lair, victory; gate = the whole game | the end of the game | ~6 |
| 8 | release (attended) | — | 1 session |

Phase 6 is three gated phases, each ending in a staged build and a card Ben can play (Ben's ruling, 2026-11-07).

---

## Wave 2 (rest) — run 46: PI → PT (Phase 5 wave 5.4 end) — done 2026-11-08

*Both merged in run 46 (PI 43b2842 + its tests-only fix round cab8d5c; PT 178788f); wave 5.4 closed. Each card keeps
its As-executed note: what the dump changed against the card.*

#### PI — minor — the enemy pipes (→ 607) — ✅ done (run 46)
- **Files:** `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the pipe arm 0x5d2…0x5d5; its `handleBuilt` row),
  `Sources/FerazelCore/Session/SpriteWorld.swift` (the `+0x1b2` collision rule: an emerging child is skipped as the
  outer sprite only), `Sources/FerazelCore/Session/FerazelSession.swift` (the Box Handle path; the child's Handle goes
  through `EnemyCommon.handle`'s `+0x1b2` early return — already built), `Tests/FerazelCoreTests/EnemyPipeTests.swift`
  (new).
- **Contract:** enemies-ground-2 §6, enemies-flyers §7.4. Dump: `.HandleBoxSprite`'s pipe arm (raw
  `1006ec90..1006f060`, inside M l. 60030–61180), `.MTCollideSprites` (M l. 30216–30373; raw `10032744`). The child is
  made by `.GenerateSprite(p1, rec 0x200, now)` with `+0x1b2 = 1`, pushed 3 px a frame, clipped at the edge for its
  direction, the sound at frame 3, released when `+0x150 > +0x154`. Children are Walkers, Blobs and insects — all built.
  A pipe child is never counted (Invariant 5). Placed first on level 21 — the tests are synthetic; not ◈.
- **Tests (4):** `testPipeSpawnsChild` · `testEmergingClipAndPush` · `testEmergingStillCollidable` ·
  `testPipeChildNotCounted`.
- **Review:** one Opus leg (ask it for a light mutation table); a tests-only fix round if it finds gaps.
- **Gate:** G2 607. **Commit:** `FerazelCore: enemy pipes; 4 tests`.
- **As executed — PI (run 46):** Ferazel/Core 603 → 607. Re-read against the dump (dump over bank and card):
  - **Setup (M l. 59325–59356):** layer 1 (`+0x80 = 1`, so the child's argument is 2); p2 0 → 100 **written back**;
    `+0xa6 = .Deviation(p2)` = p2 + R(p2 >> 1) − (p2 >> 2) (M l. 39497–39503, new `BoxSprite.deviation`); `+0x15c` = p1; the
    class-cache face; hot rect = face `+0` inset 3; gravity, tile callback and hit 0. The arm **does spawn a child at
    Setup** — `.GenerateSprite(…, 0x200, 1, 2)` then child `+0xe9 = 1` (a throwaway: its Setup's draws, and +1 on the
    level's enemy count while the Setup window is open, never taken back). Ported as `BoxSprite.setupPipe` (the stores);
    the throwaway child and `SetupFaces`' pipe arm (which still refuses 1490…1493) belong to level 21's task.
  - **Handle (M l. 60624–60768):** `+0x15c == 0` returns without the tail; else the tail runs. The spawn frame also
    runs the step, so `+0x150` is **2** after it (card: 1) and the child is already pushed 3 px. `+0x154`: 0x5d2 hot
    bottom / 3 + 4, 0x5d3 (bottom − top) / 3 + 4, 0x5d4 (right − left) / 3 + 4, 0x5d5 hot right / 3 + 4 (the bank's ⚑
    far-edge forms, as written). Cue: `.STPlay3DSoundRand(459, 1, 0x100, centre)` at `+0x150 == 3`. Release at
    `+0x150 > +0x154` clears `+0x1b2`, resets the clip to (0, 32000, 32000, 0) and `+0x150` — **`+0x1d4` is not cleared
    there** (card): it clears, with a new `.Deviation` interval, only when the child has `+0xe9` / `+0xea`, so a pipe
    waits for its child's death before the next one.
  - **Child layer:** the class Setup stores its own `+0x80` after `.MTNewSprite`'s (Walker 4, Blob 8), not pipe + 1.
  - **`generate`:** Walker arm (record 0x200 read as zeros, playerX, face as `SetupFaces`) and Blob arm added; the insects
    0x744…0x74c already get their Setup face from `Bat.setup` (cache 0x744 cell 3, M l. 68219), so the 1860 child has its
    `+0xc0` and emerges with no extra store (a redundant one was dropped in the review fix round); no shipped crate drops
    an insect.
  - **Collide rule / class guards:** `SpriteWorld.collideSprites` already matched (`+0x1b2` outer only, M l. 30253); the
    Walker, Blob and Bat Handles already return while emerging — no change.
  - **Other files:** DrawModeAudit re-anchored (BoxSprite rows moved) and gained the eight pipe-child clip rows (the
    release written as the dump's four edge stores); `BatTests.testKillCrateBatDropArm`'s twin crate drops Blobs, which
    `generate` now makes (two, no draw) — its assertion follows, its stream measurement is unchanged.

#### PT — minor — the renderer's traps into the refusal census; the two header checks (→ 607, asserts only) — ✅ done (run 46)
- **Files:** `Ferazel/Core/Sources/FerazelRender/Frame/TileGridRenderer.swift:286` (water table ≥ 6, tile kinds
  206–209), `FerazelRender/Frame/LightRenderer.swift:91/:252/:298/:398`, and every other `precondition` site in the
  renderer (`grep -rn "precondition(" Ferazel/Core/Sources/FerazelRender` — 18 counted at 07bc11d; the same grep counts
  17 lines at 44f6919 — take the grep's list at the run's head), `Tests/FerazelRenderTests/DrawModeAuditTests.swift`
  (the header checks near `:1076–:1079`; the census rows), `Ferazel/Core/Sources/FerazelCore/Front/LevelRun.swift` (the
  level-open refusal for `hdr+0x26c7` ∉ {0, 2, 4, 5} and for `hdr+0x2716` ≠ 0 — caught by `GameFlow.swift:555` like
  every level-open refusal, not a quit), `docs/ferazel/port-gap-ledger.md` (the draw-audit rows).
- **Contract:** every `precondition` in FerazelRender that shipped data could reach becomes a `throw Refusal.…` with a
  reason row in the audit's census, so Proof B reports a refusal instead of a crashed run (a trap takes the whole render
  bundle down in `swift test` and marks every later Proof B test "crashed"); one proven unreachable from any data stays
  and gets a census row saying so. The audit gains two header checks, both refused at level open: the horizon strip
  (`hdr+0x2716` ≠ 0, until 6A-S8 draws it — today nothing puts the strip sprites in the table, so level 10 would open
  silently with no strip) and OmniPx modes 1/3/6/7/≥ 8 (today nothing reads `omniPxMode`, so level 15 or 70 would open
  and draw with no rain and no error; only the audit's `== 0` header check catches it).
- **Tests:** asserts inside `DrawModeAuditTests` (the census row count moves by the number of converted sites; the two
  header rows); no new test. **Gate:** G2 607; wave 5.4 end: G3, GE `core` on levels 1–4 (visit sweep + bot), GWB by
  day **604 / 0 / 3 / 0 (of 607)**, GW4R by day. **Commit:** `FerazelRender: the renderer traps become refusals with
  census rows; the horizon-strip and OmniPx header checks`.

**As executed — PT (run 46).** `grep -rn "precondition(" Ferazel/Core/Sources/FerazelRender` finds **17**; the audit's
18 is that grep without the parenthesis, which also matches `preconditionFailure()` at `SpriteBlitter.swift:486` — so
18 traps, all decided below. The census now counts FerazelRender's `precondition(` / `preconditionFailure(` per file
like a throw (`scannedTraps`, new `Reason.trapUnreachable`); FerazelCore's traps are not scanned (outside PT). **7
converted, 11 kept.** The census grows by 6 FerazelRender refusal rows (the 7 converted sites), 8 kept-trap rows (the
11 kept sites) and 2 FerazelCore rows (the card's "+18" counted sites, not rows). No new test: DrawModeAuditTests stays
2 tests; Ferazel/Core stays 607.

| site (base 44f6919) | reachable from data? | result | reason | check |
|---|---|---|---|---|
| `Color/InverseTable.swift:21`, `Color/ColorSearch.swift:39` (bits 1…6) | no — `bits` is the `ColorSearch.Model` the shells choose in code (`.exactNearest`; `.ruled` uses 4) | kept | trapUnreachable | — |
| `Frame/TileGridRenderer.swift:286` (water table w ≥ 6) | yes — BG kinds 206–209 | `TileGridRenderer.Refusal.waterTable` | dataAbsent | new `waterKindsInTables` (every BG cell's kind of levels 1–4) |
| `Frame/StatusBar.swift:82` (PICT 132 size) | yes — the data's PICT | `StatusBarError.backSize` (init already threw) | loadsClean | `levelsLoad` |
| `Frame/Mosaic.swift:16` (buffer sizes) | no — the renderer's fixed 640×480 port and screen | kept | trapUnreachable | — |
| `Frame/ParallaxBlitter.swift:123` (60 slots) | no — the public inits build the array | kept | trapUnreachable | — |
| `Frame/ParallaxBlitter.swift:141` (cell 128×128) | no — `PlainFaceSheet` cuts fixed 128×128 arguments; `ConvertedPicture.cell` returns w·h bytes whatever the PICT | kept | trapUnreachable | — |
| `Frame/ParallaxBlitter.swift:236/:238` (ports / screen sizes) | no — fixed `FramePorts` / screen | kept (2) | trapUnreachable | — |
| `Frame/ParallaxBlitter.swift:553` (`faceBase`, slot unloaded) | yes — PxBack / PxMid map cells | `ParallaxBlitter.Refusal.cellSlot` (`compose` → `copyToScreen` / `copyMaskToScreen` throw) | dataAbsent | `pxBackSlotsLoaded` + new `pxMidSlotsLoaded` |
| `Frame/LightRenderer.swift:91` (ambient D ≠ −1), `:252` (D over the ambient rows) | yes — light bytes | `LightRenderer.Refusal.darkness` (2) | dataAbsent | `lightBytesInRange` |
| `Frame/LightRenderer.swift:298` (light-table index) | yes — light bytes, light-face pixels, colours | `LightRenderer.Refusal.lightIndex` | dataAbsent | `lightBytesInRange`, `lightIndexInRange` |
| `Frame/LightRenderer.swift:398` (overlay o1 / o2) | yes — the overlay map | `TileGridRenderer.Refusal.overlay` (thrown in `LightRenderer.swift`'s grid extension) | dataAbsent | new `overlaysInSet` |
| `Frame/TextRasterizer.swift:52` (glyph mask size) | no — both shells' rasterizers allocate w × h | kept | trapUnreachable | — |
| `Effects/DeathEffect.swift:66` (step k) | no — `LevelRun`'s loop counter; `FrameRenderer.deathEffectStep` refuses first | kept | trapUnreachable | `deathSteps` |
| `Faces/LightFaces.swift:54` (light face size) | no — w, h are Core's light-face constants; the pixels are the picture at its own size (`ConvertedPicture` throws on a mismatch) or the w × h sample | kept | trapUnreachable | — |
| `Frame/SpriteBlitter.swift:486` (`preconditionFailure`) | no — the fetch is set on the line above or it threw | kept | trapUnreachable | — |

The plumbing: the grid's redraws (`setScrollLocation`, `redrawEntireScrollGrid`, `redrawScrollGrid`, `apply`,
`drawLightsOntoTiles`, the plain-wrap tiles), the tile light pass (`lightTile`, `lightOpTile`, `ambientSlab`, the
blitters; `forEachCopyRun` rethrows) and the parallax copies became `throws`; `FrameRenderer.apply` already threw;
`ConversationRenderer`'s view restore adds a `try`; `SpriteBlitter` reads `ambientSlab` with `try?` behind its own
darkness guard (no new throw there). `skippedOpsCannotThrow` now admits exactly the four `try` calls of the skipped copy
and light arms (`skippedTries`): their throws are the rows above, checked over the data, so the run may still skip
them. The header checks: `LevelOpenRefusal.omniPxMode` / `.horizonStrip` thrown by
`LevelRun.refuseUndrawnHeader` at the top of `setupLevel` (before `services.prepare`); census rows `headerZero` with the
new check `headerOmniPxStrip` (built levels, a synthetic level-1 header by value, the call's place in `setupLevel`, and
`GameFlow`'s level arm catching to `levelFailed`). The behavioural GameFlow assert lives in
`GameFlowGameTests.testNewGameStartsLevel1` (FerazelCoreTests — `DrawModeAuditTests` has no access to that test's flow
rig): level 1 patched with OmniPx 1 or a strip → the level-load report, no `prepare`, no quit. Minimal `try` edits in
ParallaxTests, LightingTests, TileGridTests, SpriteDrawTests, DrawEffectTests and the Windows `TeleportRedrawTests`
(compile only). The existing `omniPxMode == 0` assert (`testEveryWrittenModeIsDrawable`) is unchanged and consistent.

---

## Wave 3 — run 47: OX → LV5 (Phase 5 wave 5.5); run 48: A5 + the Fable phase review

#### OX — ⚑ MAJOR — OmniPx modes 2/4/5 (level 5's moving backdrop) (→ 612)
- **Files:** `Sources/FerazelCore/World/OmniPx.swift` (new), `Sources/FerazelCore/Seams/DrawOp.swift` (`.omniPx`),
  `Sources/FerazelCore/Session/FerazelSession.swift` (the op at `.PaintFrameWrap`'s M l. 9434, drawn frames only),
  `Sources/FerazelCore/Front/LevelRun.swift` (`:642` already clears `omniPxActive`; PT's level-open refusal
  `refuseUndrawnHeader` (`:577`, called at the top of `setupLevel`) for modes ∉ {0, 2, 4, 5} is kept), `Sources/FerazelCore/Flow/LevelFlow.swift` (setup at level start M l. 2540 — `.SetupOmniPx(0)`,
  right after the `G+0x174` clear at M l. 2539; the counter on `LevelCarry`; turn off/kill at the loop's end M l.
  5321–5322), `Sources/FerazelCore/World/LevelHeader.swift` (Core's copy of the backdrop factors is zeroed by
  `.TurnOnOmniPx`, below), `Sources/FerazelRender/Frame/{FrameRenderer,ParallaxBlitter}.swift` (the 128×128 port as
  PxBack slot 0; the factor backup/zeroing of `.TurnOnOmniPx`; `ParallaxBlitter.omniPxActive` (`:102`, `:291`) is the
  existing flag the op sets — reused; the faces 6200/6201, 6300/6301 under the level+sprite CLUT),
  `Sources/FerazelRender/Screens/ScreenRenderer.swift` (`:63–:125`, its exhaustive `switch`: `.omniPx` → `throw
  Refusal.levelOp("omniPx")` like every other level op — a new refusal, so also a row in the audit's table),
  `Tests/FerazelCoreTests/SessionTests.swift` (`:291`, the `kinds` switch over `DrawOp` gains `.omniPx`),
  `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (the OmniPx rows; PT left `testEveryWrittenModeIsDrawable`'s
  `omniPxMode == 0` assert over the built levels at `:1207` — it narrows here to {0, 2, 4, 5}, matching
  `refuseUndrawnHeader`, never deleted; left at `== 0` it fails the moment LV5 adds level 5), `Tests/FerazelRenderTests/OmniPxTests.swift` (new). Any other
  exhaustive `switch` over `DrawOp` the compiler finds (both packages, both shells) is added and recorded. Source line
  numbers in this card are at c8d9cf5. **G5 is named
  for OX** (a `DrawOp` case reaches the Mac app's code), with GW1–GW4.
- **Contract:** rendering-omnipx-titles §1, §3.1–§3.5. Dump: M l. 13019–13547. Modes 2/4/5 share the base-cell path
  (cells 6 + (c >> 1), c reset at 18) and the two faces (acc mod 0x8000, toroidal wrap); mode 0 off. **Modes 1/3/6/7
  and ≥ 8 stay refused at level open** (◇ Phase 6: rain, thunder, interlace, ping-pong — levels 15, 70; caught by
  `GameFlow.swift:556`, not a quit). No RNG in modes 2/4/5. **The op is emitted only while OmniPx is on** (`G+0x174`
  set, mode ≠ 0): levels 1–4 (mode 0) emit no `.omniPx`, their op streams and every golden are unchanged. **The counter
  (M l. 13471):** `c` + 1 **per active face inside the face loop** (M l. 13469–13514) — "+2 per drawn frame" holds only
  with two faces (level 5, mode 2); the base-cell copy resets `c` to 0 when it exceeds 0x11, before the copy (M l.
  13430–13432). **Face positions wrap as 16-bit:** `fx += vx`, `fy −= vy`, then > 0x7fff → − 0x8000 and **negative →
  − 0x8000 as a 16-bit short** (M l. 13476–13487) — `Int16` wrapping arithmetic, never a modulo on `Int`.
  **`.TurnOnOmniPx` (M l. 13019–13060)** for modes other than 4…7 (so mode 2) backs up and then **zeroes the level
  header's backdrop factors** (`hdr+0x326c + 2·i`, i < 0x2000, and `hdr+0xb26c`) — it runs after the level's sprite
  Setup, so every later Core read of those fields sees zeros (Core's header copy is zeroed too, not only Render's).
- **Tests (5):** `testOmniPxSetupMode2` (faces 6201/6200, fx/fy 0x40/0x80, vx/vy per rendering-omnipx-titles §3.3) ·
  `testUpdateCyclesBaseCells` (9-frame cycle; c + 1 per active face — + 2 a drawn frame with level 5's two faces; one
  face → + 1) · `testFaceWrapToroidal` (incl. a negative position wrapping as a 16-bit short; after `turnOn` the header
  factors read 0 from Core) · `testCounterCarriesAcrossLevels` · `testLevel5FirstFrameDraws` (a level-5 `FrameRenderer`
  executes the first frame's ops with the OmniPx op, no refusal).
- **Gate:** G2 612 (the audit's table gains the OmniPx rows), G5, GW1–GW4. **Commit:** `Ferazel: OmniPx modes 2/4/5 —
  level 5's moving backdrop; 5 tests`.

- **As executed — OX (run 47, 2026-11-08):** Ferazel/Core 608 → 613 (the wave 5.4 cross-check's fix round had added one geyser test, 607 → 608, by the seat's ruling). Commits a2e0904 (task) and a023930 (fix round); the seat's own suite 613 / 0 / the two opt-in names. Dump over bank and card: the bank's "0xaa then 0xc0" for mode 1's layer-3 factors is one dead 0xc0 write in the dump; **`.TurnOnOmniPx`'s yb backup (M l. 13043–13054) saves through a pointer it never advances, so the backup ends 0 and `.TurnOffOmniPx` restores `hdr+0xb26c` as 0** — the port now does the same (bank corrected). Two review legs (spec, quality: 27 mutations, 4 survivors all wiring that no mode-0 level exercises) → one fix round, rulings: (R1) **the turn-on reaches Render at level setup** (M l. 2540, after the cache loader's 100 % bar and before the M l. 2569 bar and the player spawn), not at the first drawn frame — frame-1 mode-0xb sprites read the zeroed factors as the binary has it; the renderer no longer turns on at the first update; (R2) yb restored as 0. The op carries a turn-on or a per-frame update; the session's emission (after `DrawParticles`, before the copy, drawn frames only) is pinned in `SessionTests.testStepOrderAndSkippedDraw` on a level-1 header patched to mode 2; the toroidal wrap gains the one-offset-zero cases; audit rows prove cells 6–14 and faces 6200/6201/6300/6301 draw; test 5 pins a port hash, pixel values and the CLUT id independently of the code path; the sprite pass's shared backdrop copy is dropped before the in-place write and re-shared after (no 1 MB copy a frame). Files beyond the card: `LevelFile.swift`, `SpriteWorld.swift` (`internal(set)` on the header factors — the minimal widening). Goldens and BootFaces pins on levels 1–4: unchanged. Gates: G5, GW1 0/2, GW2 81/0/2 by name, GW3 0/1, GW4, G7/G7b/G8/G10 empty. Owed to LV5 and paid there: the level runner's setup / turn-off wiring and a real level-5 counter carry (stubbing either now fails `testBuiltLevelsFive`).

#### LV5 — ⚑ MAJOR — level 5 "Manditraki Warrior" enterable: the arena lock, the camera pan, the gate, the boss music, the Warrior stand-in (→ 618)

Ben's reading of "through the first boss door" (his default stands, 2026-11-07): levels 1–4 with every enemy alive, and
level 5 open up to the Warrior's arena — the arena locks, the gate stays shut, the Warrior stands until Phase 6.

- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (`1...5`; the not-built report text `:11–:13` "(Phases 5-6)"
  → "Level n is not built yet (Phase 6)."), `Sources/FerazelCore/Camera/BossArena.swift` (new),
  `Sources/FerazelCore/Camera/Camera.swift` (`.FindUpperLeftCorner`'s arena bounds and pan; the stale `later:` at
  `:46` relabelled), `Sources/FerazelCore/Player/Player.swift` (`.PlayerConstraints`' arena clamp),
  `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the 2940 gate's p1 −1 arm),
  `Sources/FerazelCore/World/Enemies/Warrior.swift` (new — Setup below; Handle ◇), `Sources/FerazelCore/Sprites/{SetupFaces,SpriteSlot}.swift`
  (`.warrior`; whatever level 5's census needs: platform 1403 p1 52, Box 1065, decorations 2820–2841, Bonus 3100/3214),
  `Sources/FerazelCore/Session/FerazelSession.swift` (the Warrior's Handle row), `Sources/FerazelCore/Front/LevelRun.swift`
  (the boss-music rule at level start near `:504–:512` and the in-loop block near `:684–:690`; the stale comment near
  `:507` "levels 1–2: 0" → levels 1–4 have 0, levels 5, 18, 25, 55 have −1444, −1400, 592, 16000, level 67 has 0;
  level 5's picture-cache marks incl. the Warrior's three sets, registered at their place in `.InitSprites`' order),
  `Ferazel/Shared/FerazelDriver.swift` (`:12`, `:40` — the `FerazelLevel` comments "(1…4)" → "(1…5)"; the code reads
  `BuiltLevels.range`; comment-only, both shells), `Ferazel/Windows/Tests/FerazelWinKitTests/FerazelSettingsTests.swift`
  (`:17` comment "(1…4)" → "(1…5)"; its `("9", 1)` row still holds; WinKit ladder unchanged),
  `Tests/FerazelCoreTests/LevelFiveTests.swift` (new), and the tests pinned to the old range, each retargeted:
  `Tests/FerazelCoreTests/GameFlowGameTests.swift` (`:247–:260` `1...4` → `1...5`; `:458–:487` the not-built walk
  retargeted to node 10 via level 5's exit p1 1 and the new report text; `:691–:699` the "seven" original save at level
  5 now Continues into level 5 instead of the not-built report — re-derived), `Tests/FerazelCoreTests/LevelFourTests.swift`
  (`:153–:181` `testBuiltLevelsFour`: the range and the "Level 5 is not built yet (Phases 5-6)." report become level 5
  entered from level 4's exit p1 1; `:185–:199` `testStartLevelSwitch`: switch 5 no longer clamps to 1; header comment
  `:7–:8`), `Tests/FerazelCoreTests/LevelThreeTests.swift` (`:8` header comment, `:390`),
  `Tests/FerazelRenderTests/BootFacesTests.swift` (`:281` `for level in 1...4` → `1...5`, with level 5's pins
  re-derived), `Tests/FerazelRenderTests/FaceTests.swift` (`:595–:602`: the per-level drops/keys table gains level 5,
  re-derived from the data — the `keys[n]!` force-unwrap traps if the loop is widened without it). Line numbers are at
  07bc11d; find each by its symbol. **Seat ruling (in advance) for these existing tests:** each is retargeted to what
  level 5 being built does, every expected value re-derived from the dump and the data, every changed value listed with
  its cause in As executed; never edit to make a number agree. Measured by the audit: widening the range before level
  5's records all set up makes the camera refuse its arena bound, and the flow reports the original's "level could not
  be loaded from the world file!" — so the range widens in this task only, once every record sets up.
- **The Warrior's Setup** (`Warrior.swift`, M l. 72989–73079, in the dump's order): `.InitSprite`; **`+0x84 = 0`,
  `+0x86 = 0`, `+0x80 = 0xc`** (M l. 73015–73019: the layer — the Setup runs inside `.MTNewSprite` before
  `.MTInsertSprite` (M l. 30711 / 30716 / 30719), so layer 12 overrides the caller's and decides the Warrior's place in
  the active list and its draw/erase order); Handle `+0x4c` 0x100a0494, Hit `+0x5c` 0x100a0d44, HitTile `+0x1f8`
  0x100a0d40, Kill `+0x50` 0x100a0d3c stored (the stand-in's Handle/Hit/Kill bodies are ◇); `+0x18a = 1` (its save
  write-back flag); the three sets marked; `+0x170 = p4` (record +0xe); `+0x110 = 0x122`; `+0xc0 = 0`; **p4 ≠ 0 → HP
  `+0xa4` 2000, `noBossAlive = 0`, `+0x88 = 0`; p4 = 0 → HP 0x4b0 and no boss flag**; `+0x1b4 = 1`; `+0x168` = HP; **the
  re-seat `+0xc = +8`, `+0xa = +6` (M l. 73046–73047)**; hot rect (0x1a, 0x17, 0x4a, 0x3a); `+0x150 = −1`, `+0xb0 = 6`,
  `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`; **`+0xa6 = FastRand(10)`**; the record's p2 (record +0xa) **written back 0 →
  0x96**; `+0x15c` / `+0x160` = `+0xc` − 350 / `+0xc` + 350 (the re-seated x); `+0x168 = +0xc`; `+0x164 = 0`;
  **`+0x17e = (FastRand(100) < 51)`**; `+0xc0` = the 0x71c set's first face; `+0xf0 = 0x1e`; counted only inside the
  window; `+0x14`/`+0x1c` = `+8`/`+6` << 8. `.InitWarriorSprite` (M l. 72975–72988): three cached sets 0x71c (8), 0x71d
  (8), 0x71e (6), each marked by the Setup. **The Handle is ◇:** `.StandardSpriteHandles` + its Setup face, no AI, no
  shot, no Hit callback, `// later: Phase 6`. The Warrior stays a Ring-of-Smiting target as the binary has it
  (`.SmiteEnemies` lists its Handle 0x100a0494): a seed explosion can take its HP below 1, and with no Kill until Phase 6
  it stays standing and harmless, `noBossAlive` stays 0, the gate stays shut and only Esc / ⌘W leaves (kept faithful
  rather than dropping it from the 16-target list or inventing a stand-in Kill). (corrected 2026-11-10, Phase 5
  cross-check: nothing lowers the Warrior's health in this build — the seeds reach it, but its Hit is the empty
  stand-in (`FerazelSession.swift`'s `.warrior` hit arm), and a probe read HP 2000 after Smite with contact still
  hurting; in the original `.HitWarriorSprite` (M l. 73422–73458) only swallows shots and only a falling crate or
  statue takes 200 off. Before the lock the level's own right exit also leaves.)
- **Contract:** bosses §1.1–§1.4 (framework only); world-data-format §3.2 (`hdr+0x2724` −1444, `+0x272e` 0, music 23,
  start at the right edge facing left `0x26c8`). Dump: `.PlayerConstraints` M l. 43991–44126, `.FindUpperLeftCorner`
  M l. 5882–6239, `.SetupLevelSprites` M l. 1940–2103 (`fed4 = 0`, `fed0 = 1` at M l. 2016–2019), `.GameLoop` M l.
  5093–5328.
  **The boss-music rule, both sites, with `noBossAlive` read live from `BossArena` (today the level-start site is a
  constant "no boss alive = false"):** at level start (M l. 5218–5221) `hdr+0x284a = 0x1e` only when `hdr+0x2724 ≠ 0 ∧
  fed0 ≠ 0`, then `SetAIFFMusic(hdr+0x284a)`; in the loop (M l. 5266–5274, at the iteration-end slot where
  `handleAsyncFade` already runs) when `hdr+0x2724 ≠ 0 ∧ fed0 ≠ 0 ∧ the current track ≠ 0x1e ∧ prefs+0xc ∧ the music-on
  byte`: volume `fd6c` < 1 ? `SetAIFFMusic(30)` + `FadeAIFFMusicAsync(1, 60)` : `FadeAIFFMusicAsync(0, 60)`. So **level 5
  plays its own track 23 from the start** (the Warrior's Setup cleared `fed0` before the loop), **the arena lock changes
  nothing musically**, and track 30 comes only after the Warrior's Kill sets `fed0` (Phase 6). (A revisit with the boss
  dead keeps `fed0` = 1 and starts on 30 in the original — the live read gives that; the header write does not carry over
  because each visit opens a fresh copy of the level, M l. 41551–41554.) **`.KillWarrior` itself (M l. 73486–73493), when
  p4 ≠ 0:** snd 453 at 48000, screen shake `_DAT_1009ffa0 = 0x1e` (the shake counter, `Camera.swift` `shake` — not the
  music track, which is `_DAT_100a5be0`), flash `_DAT_100a00fc = 3`, `fed0 = 1`; the switch to 30 is the loop rule's on
  the next frame. Phase 6 builds all four.
  **The gate:** `.HandleBoxSprite`'s 2940 arm (p1 −1: open while `fed0 == 1` — rise 2 px a frame to 100 px above
  `+0x158`, else back down). **Level 5's census:** 16 types, 32 records — Bonus 1059 ×2, 1340, 3100 ×5, 3214; Box 1065
  ×2, 2820 ×2, 2821, 2822 ×2, 2826, 2829 ×2, 2840 ×3, 2841 ×2, 2940 (p1 −1); Platform 1403 ×4 (p1 52); Warrior 1820;
  Background 3249 ×2 (p1 −1, 1). The gate 2940 is at x 416; the exit 3249 p1 1 at x −93 (→ node 10); start at the right
  edge facing left (`0x26c8` = 1 on level 5); OmniPx mode 2 (faces 6201/6200, sheet 600 cells 6..14).
  **With the ◇ Warrior alive (`fed0 = 0`):** walking left past x 1384 locks the arena (`fed4 = 1`, the 40-frame pan),
  the player is clamped at x ≤ 1384, the gate stays shut. **Camera bounds (`.FindUpperLeftCorner`, `hdr+0x2724` < 0,
  boss alive):** before the lock the scroll's lower bound is |−1444| = 1444 (M l. 5941–5948); while locked and the pan
  counter is < 0, 1444 − 0x260 (M l. 5953–5954), else −32000, and the upper bound is 1444 − 0x260 (from `sVar26` =
  1444, M l. 5961, applied at M l. 6171–6172); the pan shifts both by 16·|counter| (M l. 6011–6028). The Warrior stands
  and hurts on contact (`.HitPlayerSprite` step 7: 0x70, invulnerability 60). Leaving: Esc / ⌘W abort as Phase 3. A
  synthetic `noBossAlive = 1` (what `.KillWarrior` will set) opens the gate, releases the arena and switches to track
  30 — tested, unreachable in play this phase.
- **Tests (6):** `testLevel5SetsUpEveryRecord` (32 records, no `notTranscribed`; the Warrior record: the two `FastRand`s
  in order (R(10) → `+0xa6`, R(100) → `+0x17e`), p2 written back 0 → 0x96, `+0x1b4` 1, `+0x88` 0, `+0x170` = p4,
  `+0x80` 12 (and its place in the active list follows layer 12, not the caller's layer), `+0x84` 0, `+0x86` 0,
  `+0xc`/`+0xa` re-seated from `+8`/`+6`, `+0x15c`/`+0x160` = the re-seated x ∓ 350, the four procs, `+0x18a` 1, HP and
  the boss flag for level 5's p4 — plus a synthetic p4 = 0 record: HP 0x4b0, `noBossAlive` untouched) ·
  `testArenaLocksAtX1384` (lock, pan counter −40 → 0 over 40 frames, clamp; before the lock, boss alive, the scroll's
  lower bound is 1444) · `testCameraWindowWhileLocked` (during the pan the lower bound is 1444 − 0x260, after it
  −32000; the upper bound) · `testGateStaysShutWhileBossAlive` · `testSyntheticKillOpensGateAndTrack30` (also: level
  start with `fed0` = 1 picks track 30) · `testBuiltLevelsFive` (`1...5`; level 5's exit p1 1 → node 10 → "Level 10 is
  not built yet (Phase 6)."; `startLevel` 5 accepted).
- **Gate:** G2 618, G5, GW1–GW4. Wave 5.5 end: G3, GWB by day **615 / 0 / 3 / 0 (of 618)**, the full GE on levels 1–5
  (`both`). **Commit:** `Level 5 enterable: the arena lock and camera pan, the gate, the boss music rule, the Warrior
  stand-in, BuiltLevels 1...5; 6 tests`.

- **As executed — LV5 (run 47, 2026-11-08):** Ferazel/Core 613 → 619 (6 tests; the wave 5.4 cross-check's +1 carried). Commits 1d907fc (task), aafa17d (fix round), 0f7d839 (a citation). Dump over card, confirmed by both legs: **(a) the Warrior's facing `+0x17e` is set when FastRand(100) ≥ 51** (raw 10087a54–10087a68, the Dillo's compare idiom) — the card's "< 51" was backwards; **(b) "the music-on byte" in the loop rule is the no-async-fade-running flag `cRam100a5be2`** (set/cleared only by the fade code, M l. 42067–42123), not a music setting; **(c) the pan:** the lower-bound choice reads the counter before this frame's +1 and the shift after it, so the forced view runs 836 + 16·(40 − k), capped by the map edge at 1408, and before the lock the camera sits at 1408 because the map edge beats 1444; **(d) the original draws one more 100 % load bar after `.SetupOmniPx`** (M l. 2569), so the OmniPx turn-on is pinned between the cache loader's bar and that last bar. Seat rulings from the legs: **the pan counter `_DAT_1009ff9c` is carried across levels on `LevelCarry`** (zeroed only by the globals init, M l. 822 — New Game and Continue; nothing resets it per level); **the in-loop boss-music rule reads `noBossAlive` before `_UpdateSprites`** as M l. 5266–5275 order it (the session records the flag at that point, the rule still runs at the iteration end); the ◇ Warrior Handle skips the original's pre-lock work — three falling rocks (type 1075) above the arena refilled every 15 frames and the wounded-glow timer (M l. 73151–73212) — and its Hit (shots absorbed with a sound, crates bounced, M l. 73422ff) is empty: both named Phase 6 stand-ins, on the gate card. Retargeted expectations, each re-derived: `GameFlowGameTests` 1...5, the not-built walk 4 → 5 → 10 ("Level 10 is not built yet (Phase 6)."), the "seven" save Continues into level 5; `LevelFourTests` exit → level 5, switch 5 starts level 5; `BootFacesTests` level 5 first measured (init 46 / 0xb039da66a884cb8a, f30 55 / 0x69068d5e8151b0cc, f120 55 / 0xb9f08ee19927f3e7); `FaceTests` level 5 no keys / no drops, the Warrior's three sets required; **`GremlinFloaterTests.testGremlinCompositeSetup`'s picture-cache lists gain the Warrior's sets 0x71c/0x71d/0x71e (8/8/6) between the Dillo's and the Floater's** — `.InitSprites` M l. 133–134, `.InitWarriorSprite` M l. 72982–72984 (the seat's suite caught it; the implementer had not run that class). Files beyond the card: `SpriteWorld.swift` (the arena; the dead `bossFlag` forwarder removed, `ButtonGateTests` retargeted to `BossArena`), `EnemyCommon.swift`, `PlayerStates.swift`, `PlayerState.swift` (stale Phase 5 labels → Phase 6), `DrawModeAuditTests.swift` (the camera arena-refusal row removed — no throw left; two Warrior writer rows and the patrol-bound row added), `OmniPxTests.swift` (the no-op switch-off loop removed), `FerazelSettingsTests.swift` (a `("5", 5)` row; WinKit 81 unchanged). Goldens and levels 1–4 pins: unchanged. Legs: spec PASS WITH FIXES, quality 34 mutations / 24 caught / survivors equivalent or Phase 6 (the stand-in Handle's per-frame step is untested). Gates: G5, GW1 0/2, GW2 81/0/2, GW3 0/1, GW4, G3 1,108 / 0, bot quick mode level 5 `steps 7200, deaths 0, exits 15, failures 0`; the wave 5.5 end gates (G2 at bc31efa, GE both, GWB, GW4R — run on 2026-11-10 after the sweep-leak fix 36e9a58 / fafc00f / 33f52b8 / bc31efa, D44 As built (f)) are in LOOP-LOG's run 47 line.

#### A5 — minor — the three checks, the `later: Phase 5` sweep, both builds staged, one gate card (run 48)
- **Files:** `Ferazel/WHAT-TO-EXPECT.md` (the Phase 5 card, Mac part), `Ferazel/WINDOWS-WHAT-TO-EXPECT.md` (Windows
  part — one card, two files), any `Ferazel/Core/Sources` file with a leftover `// later: Phase 5` or a stale `later:`
  owner (comment-only relabels to the real owner — below), `tools/windows/smoke-ferazel-win.sh` (reads the three
  reference hashes from `WinReferenceFramesTests.swift` — one source; today a copy at `:63–:67`) and
  `tools/windows/README.md` (its two hash lines), `tools/stage-ferazel.sh` / `tools/windows/stage-ferazel-win.sh` (only if
  needed), `docs/ferazel/port-gap-ledger.md` (a dated "after Phase 5" note: what the checks covered; and the test-harness
  note that a burn with no face provider is a silent no-op in headless runs only).
- **The relabel sweep:** `grep -rn 'later: Phase 5' "$WT/Ferazel/Core/Sources"` prints nothing at the end (8 lines at
  c8d9cf5, before LV5). The boss grab (`PlayerState.swift:196`, `PlayerStates.swift:371`) → "later: Phase 6" (the
  Goblin Chief and Xichra own it). Stale owners whose task merged: `GroundCeilingEffects.swift:69` (WK1, CR),
  `EnemyCommon.swift:95` (CR), `Camera.swift:46` and `BackgroundSprite.swift:498` (SH, Phase 4 — if LV5 has not already
  relabelled `Camera.swift:46`), `StatueSprite.swift:5` ("one caller" — Walker, Crawler and Roach now call it), the
  stale "refused" comment in `World/Movers/ProgrammedPath.swift` (the Gremlin now calls `makeRadial`), the generic
  "Phase 5–6" notes (`SetupFaces.swift`, `LevelRun.swift` picture-cache notes, `FerazelSession.swift`) → their Phase 6
  owner. Line numbers are at 07bc11d; find each by its text.
- **Contract:** (1) **GE** — visit sweep `both`, random-play bot `both` (levels 1–5, default 4 seeds × 3 minutes), G2's
  load-every-face tests and the draw-mode audit — every one exit 0 / green; **a non-zero exit stops the phase end**:
  each row becomes a fix task, nothing is staged. Their summary lines go on the card. (2) The relabel sweep above.
  (3) Stage both (`tools/stage-ferazel.sh`, `tools/windows/stage-ferazel-win.sh`), GW5; by day G9M, GW6, GWB, GW4R (else
  "boot check owed (night rule)" on the card and in LOOP-LOG). (4) The Fable cross-check (§0: the seat itself if it is Fable, else
  `fk-reviewer` with `model: "fable"`, named "Fable cross-check" in its brief; foreground) over the whole Phase 5 diff, Mac + Windows
  (`git diff <phase-start SHA>..HEAD`), plus the card; Opus implementers fix its findings; re-stage. **STOP for Ben:** the
  card goes to QUESTIONS as a new item (the Phase 5 gate, Mac and Windows). The next run is the planning run (wave 4),
  which does not wait for his verdict.
- **Gate:** G1, G2 618 / 2 named skips, GW2 82 / 2 named skips, G3, G5, GW1–GW4, GW5, GE; by day GWB **615 / 0 / 3 / 0
  (of 618)**, GW6, G9M. **Commit:** `WHAT-TO-EXPECT: Phase 5 gate card (through the first boss door), Mac and Windows`.

- **As executed (run 48, 2026-11-10, Fable 5.2 seat; A5 at e9183ce).** Implementer afa986f / dadb814 / 19d6c7a; two
  Opus legs (spec, then quality with a 17-row mutation table on the smoke script's hash parse) → fix round 4048d8a /
  f41c182 / 1e82506; the Phase 5 Fable cross-check (`fk-reviewer`, `model: "fable"`, e815146..head: PASS WITH FIXES, no
  sampled divergence from the dump) → fix round bffd3c0 / 34a05d5 / 2bf8634; the seat's numbers into the cards e9183ce.
  **The card was wrong against the data in six places, all corrected on the cards:** no shield is reachable (level 5's
  Wooden Shield lies behind the shut gate, none on levels 1–4, the Magical Shield first on level 25); a bat scores 600
  and the reachable goblins 400 / 500 / 600 (the 800 goblin, type 1750, is on no level 1–5); lava is on none of levels
  1–5 (acid on 1–3; brine dims 15 % toward black, M l. 46449–46476); the Warrior's "three crates" are rocks (three
  slots, a 15-frame refill, M l. 73151–73182); nothing lowers the Warrior's health in this build (the Ring of Smiting
  claim was untrue); level 5 can be left by its own right-hand exit before the lock, and "level 10 not built" is
  unreachable in normal play. **Seat rulings:** (1) one new test, not an assert — `GoblinBurnLevelRunTests` (a level-1
  axe thrower burns away through the real renderer's face store; score +500, live enemies 15 → 14, defeated 0 → 1) —
  ladder **620**; (2) muted launches draw the random stream differently from audible ones (no Sound Tool, so "is it
  playing?" is always no) — recorded as a known deviation of the muted boot checks only, no code change; (3) the guard
  scripts are not changed at a phase end: "never force-kill" documented, the gaps carried in STATE. Also: the smoke
  script reads its hashes from `WinReferenceFramesTests.swift` (1–16 hex digits, normalised to the exe's spelling); both
  stage scripts refuse a card with an unfilled `<<SEAT:` slot; the OmniPx owner labels corrected (mode 1 → 6A-RN, mode 6
  → 6C-L55…L70, modes 3 / 7 unplaced). **Gates (the seat's own runs):** at the head 8aa4db5 G2 619 / 0 / 2 named, G3
  1,108 / 0; at 2bf8634 G2 **620** = 486 + 134 / 0 failed / the 2 named skips, GW2 **82** / 0 / the 2 named skips, G3
  1,108 / 0, GW1 0 / 2, GW3 0 / 1, GW4 Build complete!, G5 BUILD SUCCEEDED, G7 / G7W empty, G-MUTE 1 / 1; GE at 1e82506
  (game code identical to the head, comment-stripped diff empty): visit sweep core 3,488 visits rows 0 and windows 3,488
  rows 0 (teleports 15 / 15, exits 37 / 37), bot core and windows each 108,000 steps, deaths 14, exits 106,
  conversations 22, saves 1, failures 0; GW5 both stages exit 0, stamp e9183ce. **Owed by day (night rule, the run sat
  21:28–23:30):** G9M, GW6, GWB (expect 617 / 0 / 3 / 0 of 620), GW4R — run 49 does them first if it starts by day,
  after a fresh stage of its head.

#### The Phase 5 gate card ("through the first boss door") — A5 writes it from this

Play `~/Desktop/Ferazel's Wand.app` (Mac) and `Ferazel's Wand (Windows).zip` (Windows), New Game or a Phase 4 save,
beside the Let's Play (https://www.youtube.com/watch?v=ESuyxMUEzDw). Jump to a level with the hidden switch
`-FerazelLevel N` (1–5) — the same argument on the Mac (`open -n … --args -FerazelLevel 5`) and on the Windows exe's
command line. **Levels 1–5 can be entered; level 5's Warrior stands still (Phase 6); level 10 and later say "not built
yet (Phase 6)".**
1. **Goblins (level 1 onwards)** — the axe throwers walk into range, throw axes in arcs, and the ones that never walk
   stay put; the spear guards turn to face you, block shots with a metal clang and thrust; the boulder goblin on levels 1
   and 4 throws boulders that bounce a few times and burst into shards (the dark ones explode). Goblins growl and taunt
   now and then, cry out when hit.
2. **Crawlers and Roaches** — crawlers hop, roaches scuttle back and forth; a falling crate or boulder crushes them.
3. **Bats (levels 2–4)** — sleeping bats wake when shot or approached and chase; the level-3 path bat flies its route;
   bats burst into blood and drop coins.
4. **Frogs (levels 2–4) and Blobs (3–4)** — frogs leap and spit; blobs ooze and attack.
5. **Getting hurt** — touching an enemy or its shot knocks you back by its speed, splashes blood, sometimes loses coins
   (they fly out and blink); a big hit makes the big "ouch". Dead enemies never hurt.
6. **Hurting them** — every spell, the dagger and the other held weapons, crushing boxes, the big explosion and the Ring
   of Smiting; goblins die with their death frames and burn away; a goblin dying in water leaves a corpse that floats
   and can be stood on; scores add up (goblin 500–800, crawler 500, roach 600, bat 500); the stage-complete panel counts
   the enemies defeated.
7. **Statue spell on an enemy** — it turns to stone for 4 s, you can stand on it, it thaws 200 HP weaker.
8. **Shields** — a raised shield blocks shots from the front with a clang; the Magical Shield reflects darts and spines
   (they burn away) and shows its crouch picture.
9. **Level 4's boulder spouts** fire boulders when their button is pressed.
10. **Under water** the screen takes a blue (green in acid, red in lava) tint, and clears when you surface.
11. **Level 5 "Manditraki Warrior"** — the moving sky behind the level; its own music from the start (the boss track
    comes only after the Warrior is beaten, Phase 6 — the arena locking does not change the music); walk left: the
    camera pans and the arena locks behind you, the gate ahead stays shut, the Warrior stands and hurts on contact;
    leave with Esc → abort. Expected missing until Phase 6: the three falling crates the real Warrior drops on its first
    frames do not fall. No spell, weapon or the Ring of Smiting harms the Warrior in this build: it stays standing and
    the gate stays shut until Phase 6.
12. **Readings Ben can't see but may feel (MED):** the tint tables' colours, the burn-away, the backdrop's look, the
    goblins' voices' pitch spread.

**Windows part:** the same 12 points on a Windows PC; note anything that differs from the Mac. **Machine checks run for
this card:** the visit sweep and the random-play bot (both shells), the face-load tests and the draw-mode audit —
summary lines pasted by A5. **Known stand-ins:** the Warrior (Phase 6); levels 10+ (Phase 6); the enemies first placed
after level 5 (Dillo, Gremlin, Wraith, Salamander, Crab, enemy pipes, geysers) are built and machine-tested but not
reachable yet.

### Stand-ins kept at the Phase 5 end (◇, named) and who replaces them

| ◇ | where | replaced by |
|---|---|---|
| The Warrior's Handle/Hit/Kill: stands in its Setup face, hurts on contact as read, no Hit callback, never dies; the gate stays shut while it lives; the real Handle's three falling-crate children (type 0x433 into `+0x1d4/+0x1d8/+0x1dc`, spawned when p4 ≠ 0 once `+0x16c` counts below 1, M l. 73145–73182) are not spawned | LV5 | 6A-W1 (the Handle: the crates from the first frame, the attacks, the dying) |
| The Warrior under the Ring of Smiting: nothing lowers its health in this build (its Hit is the empty stand-in; HP stays 2000, contact still hurts); Esc / ⌘W leaves | LV5 | 6A-W2 (the Hit and the Kill) |
| The other bosses (Wizard, Chief, Demon, Xichra) stay `.inert`; their projectiles' spawners | — | 6A-CH1 / CH2, 6B-WZ1 / WZ2, 6C-DM1–DM3, 6C-XI1–XI3 |
| OmniPx modes 1/3/6/7/≥8 refused at level open; the horizon strip refused at level open | PT, OX | mode 1: 6A-RN; mode 6: 6C-L55…L70 (level 70); 3 / 7 / ≥ 8 placed nowhere — kept; the strip: 6A-S8 |
| Geyser kinds 3/4: the base face past the 12-face cache draws nothing (unplaced) | GY | kept (as read) |
| Dillo types 1872–1879 and the Wraith variant 0x6fe–0x707 refused at Setup (unplaced) | DL, GF | kept (as read) |
| The enemy pipe's level spawn: `BoxSprite.setupPipe` (the Setup's stores) is not wired into level spawn; the throwaway child `.SetupBoxSprite` spawns and kills at once (its Setup's random draws and its +1 on the live-enemy count, M l. 59347–59353) is not made; `SetupFaces`' pipe arm 1490…1493 still refuses | PI | 6A-L21 (level 21 places the first pipe) |
| `BuiltLevels = 1...5`; the not-built report "(Phase 6)" | LV5 | 6A-BL, then deleted at 6C-END |
| Refusals kept and pinned unreachable: the light byte −1, mode 5 rotated/scaled, 0xa mirrored, 0xb rotated, modes 2/7/8/0xd/0xe/≥0xf, water kinds ≥ 6, fire/ripple backdrops | `DrawModeAuditTests` | the Phase 6 task whose level places each — mode 8: 6A-S8; the ripple: 6A-RP; the fire: 6B-FI; water kinds 206–209 are placed on no level (ENG §5): kept for good, the check widened to all 24 levels at 6A-BX1a |
| `ParticleLife` vs CLUT 222 (levels 52/55) | carried | the task that opens 52/55 |
| `.Victory`, falling rocks 1075/1076, spiked balls, magic carpet, rope bridge 1466, boss grab `_DAT_100a0570` writers, countdown digits | — | 6C-VI; 6A-FR (the rocks' player arm) with 6A-W1 (their spawn); 6B (ENG §3.4); 6A-CP; none — placed nowhere, pinned by `testRopeBridgeUnplaced` (6A-BX1a); 6A-CH1 (the arm and the Chief's writer; Xichra's at 6C-XI); 6B-TM |

### Known deviations (forced by the platform or ruled)
1. **Voice eviction:** a play that pushes another sound out of the 16-entry list is not modelled in Core's
   `SoundVoices`, so an idle-only check can be off for one tick (no quit, no misdraw; a faithful model needs the shell's
   voice table in Core every tick). Revisit if Ben hears a difference. [MED]
2. **Tint colours** of the remap tables (Walker tiers, Crawler, statue) through the replica's colour search [LOW].
3. **The underwater tint** is applied by FerazelRender's screen gamma to the presented image, not the monitor's gamma
   [MED]; its 1 ms library wait is not modelled (under one tick, nothing drawn in it) [MED].
4. **Tick:** every timer runs at the 30-step cap (Ben kept the original's top speed, 2026-10-25).

---

## Wave 4 — run 49 (planning run): Phase 6 research, then the 6A plan

One planning run = the next phase's plan, extended: three research tasks run first (two Opus researchers in parallel +
one; each writes a document and a checker script, no game code), then the Opus planner writes the 6A plan from them and
from the cards in waves 5–7, two Opus review legs, the Fable cross-check, fix rounds, the rulings recorded under the next
free decision number, a QUESTIONS item for Ben's later read.

### Task LL — the later-level ledger (research; `fk-implementer`, docs + a script only)

**Files:** `docs/ferazel/later-levels-ledger.md` (new), `tools/ferazel/later-levels-ledger.py` (new, `-I`-safe, reads
`Resources/Ferazel/` and `docs/ferazel/gap-ledger/placements-all.tsv` and the committed dump's headers; regenerates
every table in the document), `docs/ferazel/INDEX.md` (one line).

**Contract — one section per level 10 … 70, each with:**
1. The header switches that differ from every built level (fields `0x26c6`–`0x26d0`, `0x2706`–`0x2736`, `0x284a`, per
   world-data-format §3.2), with the original routine each switches on, the port file that owns it (spec "3.2 The engine
   features whose switch is zero on every built level") and today's state (built / refused / not built), citing the
   refusal row in `DrawModeAuditTests` where one exists.
2. Every placed type not placed on levels 1–5 (the census counts 23, 22, 21, 4, 17, 23, 26, 3, 21, 26, 17, 12, 23, 19,
   17, 2, 36, 2, 15 for levels 10 … 70), with its class, the port's arm (`notTranscribed` / `later:` site: file:line) or
   "built", the dump span of its Setup/Handle arm (from the 1,236 headers: `grep -n "==== " ghidra/ferazel/<dump>`), and
   the bank section.
3. The resources it needs that the port never loads today (`resources-classified.tsv` "future phase" rows: 125 PICTs,
   3 cluts, music track 29, the 20 `Mlvl` / 23 `Mcnv`), and which loader (boot list, level cache, the stage screens)
   loads them in the original.
4. The conversations (`Mcnv` ids) on it and whether the interpreter already handles every opcode they use.
5. A proposed task owner (a 6A/6B/6C card below, or a new card) — every type and switch owned exactly once.
6. The original's picture-cache registration order per class from `.LoadCachedSpriteFaces` (M l. 73769–73869) and each
   `.Init*Sprite`, so every class and level task slots its `CachedFaces` entries at the original's position (today
   `CachedFaces` is a per-class subset copy of that order, holding only what levels 1–5 mark; a misplaced entry makes
   the load bar's steps and counts drift). Option for the planner: transcribe the whole registration list once so only
   `marks` grows.

**Acceptance:** `python3 -I tools/ferazel/later-levels-ledger.py --check` exits 0 (every type in the census appears
once; every nonzero header field appears); the document's totals equal the census (5,641 active records over 24
levels); two Opus legs review it (§0); the first checks it against the dump on three sampled levels (10, 50, 62). Commit: `Ferazel bank:
later-levels ledger (levels 10–70: switches, types, resources, owners) + checker`.

**As executed (run 49, 2026-11-11).** Done: `docs/ferazel/later-levels-ledger.md` + `tools/ferazel/later-levels-ledger.py`
(84529ea; fix round 16963f5, which also wrote the three INDEX lines). `--check`: OK — 142 census types once, 101 nonzero
header fields on 19 later levels, 5,641 active records over 24 levels. Two Opus legs, both PASS WITH FIXES; leg 2 ran the
port's real Setup over every active record of all 24 levels — the ledger's port model matched on every level × type.
Measured: 401 records on levels 10–22 are refused today (10: 31 · 11: 35 · 15: 38 · 18: 6 · 20: 209 · 21: 30 · 22: 52),
730 on all later levels. **This plan's cards were wrong against the data** (the ledger's closing section lists them for
P6A): wind is on levels 10 and 20 (103 / 2,899 cells), not 10 only; the submerged-tile tint (6A-T11) and the side push
are already built — prove only; 6A-BN1 has nothing to build; the cannon and mace path arms are Background class, not
Box; the horizon strip is on six levels (10, 30, 40, 45, 62, 67); picture 0x46a has three cache records but two cuts,
so 6A-FB's test cannot pass as worded; level 21's graves 2833 / 2834 / 2836 reach an unbuilt hot-rect flip. New card
proposed: 6A-CF — transcribe the whole picture-cache registration list once (285 records: 92 sets, 193 singles), keyed
by record; feasible as one task (touches `CachedFaces` only; two tests re-anchor). The fix round's corrected leg-1
claim: the overlay-cell water tint is built (`LightRenderer.plainWrapFGOverlayTile`).

### Task BOS — the boss contracts (research)

**Files:** `docs/ferazel/phase6-boss-contracts.md` (new), corrections appended to `bosses.md`, `bosses-2.md`,
`bosses-3.md` where the dump disagrees, `docs/ferazel/INDEX.md` (one line).

**Contract — for each of the Warrior (M l. 72975–73532), Chief, Wizard, Demon (the Fire Guardians), Xichra (spans from
the headers; the bank's `l.` numbers are the old 64,189-line dump — re-map every one):** the Setup's writes in dump
order (as LV5 does for the Warrior); the Handle's state machine as a table (state → entry, per-frame, exit; the random
draws in order; the sounds; the shots spawned with their EnemyShot types; the children); the Hit routine (what hurts it,
bosses §1.5); the Kill's writes (the four of bosses §1.4 + any class extra); the Init's cache sets; the arena and music
rules it relies on (LV5's). **Every boss contract names the three pieces every boss task must build, which no boss has
today:** its `EnemyCommon.killProc` case, its contact-damage row in `.HitPlayerSprite` step 7 (damage 0x70, M l.
49836–49846), and its `.SmiteEnemies` target entry. For Xichra also the three cannons, the minions (0x6d6, record 500),
the lair gates (p1 = 0), the CLUT animation of level 67 (bosses-3 §8–§9) and the hand-off to `.Victory`. Each contract
ends with the **test list** its build task will carry (names + the number each pins) and a scripted-keys kill scenario
(seed, keys, expected frame of death) the build task turns into `test<Boss>ScriptedKill`.

**Acceptance:** every routine in `routines-classified.tsv` with "phase 6 (boss)" or "boss face cache registration"
appears in exactly one contract (52 rows); two Opus legs review it (§0); the first re-derives two states per boss from the dump. Commit: `Ferazel
bank: Phase 6 boss contracts (Warrior, Chief, Wizard, Fire Guardians, Xichra) from the dump`.

**As executed (run 49, 2026-11-11).** Done: `docs/ferazel/phase6-boss-contracts.md` (1cfc137; fix round 2e22132; a
re-review of that large fix round and its 13 small fixes a5a5016), dated corrections appended to `bosses.md` and
`bosses-2.md`. Two Opus legs, both PASS WITH FIXES; leg 1 re-derived ten states from the dump, all matching. **The card's
"52 rows" was wrong:** 46 rows carry the phrases, 8 of them (+ `.ShootSpines`) are the built Dillo's — 39 rows, each in
exactly one contract (Warrior 8, Chief 7, Wizard 6, Fire Guardians 7, Xichra 11). Other card errors (the document's
closing section lists them for P6A): the step-7 lines are routing M l. 49514–49521 and damage rows 49840–49851; Xichra
has no contact row; the Warrior already has its three pieces in part; 6A-FB is not a Warrior prerequisite; the Wizard
has 13 switch arms, 6 live, not "eleven states"; level 67's CLUT animation belongs to 6B-CA's routine. **Seat's
rulings:** every scripted kill's death frame is measured by its build task (none can be derived on paper) — the
contract names seed 1 and a starting key script; each spawned type carries a "runs on its spawn frame" row (insert by
layer; the Handle pass reads the next sprite first); the two mutation tables' 58 unpinned behaviours (Warrior 28,
Chief 30) are listed as asserts for the build tasks. Proposed split: 6A-W1 9 tests / W2 8, 6A-CH1 10 / CH2 8, 6B-WZ1
10 / WZ2 7, 6C-DM1 8 / DM2 9 / DM3 8, 6C-XL 1, 6C-XI1 9 / XI2 10 / XI3 8.

### Task ENG — the engine-feature contracts (research)

**Files:** `docs/ferazel/phase6-engine-contracts.md` (new), corrections to `rendering-omnipx-titles.md`,
`lighting-tables.md`, `draw-effects.md`, `particles.md` where the dump disagrees, `docs/ferazel/INDEX.md`.

**Contract — one section per feature of the spec's "3.2" table not built by Phase 5:** OmniPx rain (mode 1) and
interlace (mode 6), the horizon strip (draw mode 8, `.BlitEncFaceBehindTiles*`), wind cells (`.LookupModedImpulse`),
the parallax ripple, the constant side push, auto-scroll (x, y, the marker sprites), the fire backdrop and flame buffer
(the eight `.Flame*` / `.My*` routines, `.LoadCoolingMap`, the fire variant of `.DoubleBlitUniversal`), CLUT animation
(`.AnimateCLUT`, bosses-3 §9), the level-wide liquid flag and the tinted submerged tiles, the countdown digits, the
programmed-path cannon/mace arms, rope bridge, trees, clouds, the rotating blade (`.SectLineSegs`), falling rocks,
spiked balls, carpet, snowball, table, water kinds 206–209, `.Victory` + stitch + credits. For each: the dump span, the
header/type that switches it, the port module and the exact seam change (a `DrawOp` case? a `ScreenGammaOp`? none?),
the first level that shows it, **the golden plan** (which level, which frame, both shells' references), the test list,
and the phase (6A/6B/6C) it belongs to. Each engine feature is its own task, proven by a frame golden on the first level
that uses it and built before that level's "enterable" task (a level task that also builds an engine feature is what
blew up level 3's review in run 29).

**Acceptance:** the 27 "later-level" routines and the Phase 6 "not built" non-boss rows of `routines-classified.tsv`
each appear once; two Opus legs review it (§0); the first re-derives OmniPx mode 1's rain generator and the CLUT animation's step from the dump.
Commit: `Ferazel bank: Phase 6 engine-feature contracts from the dump`.

**As executed (run 49, 2026-11-11).** Done: `docs/ferazel/phase6-engine-contracts.md` (d662b44 + its review fix
round, the last `Ferazel bank: engine-feature contracts` commit of run 49). Two Opus legs, both PASS WITH FIXES (44
findings, none critical); leg 1 re-derived the rain generator, the CLUT step, the wind lookup and the strip Setup.
**The card's "27 later-level routines" are nine reason phrases** among the not-built rows; with the 4 non-boss Phase 6
rows the set is 31, each in exactly one section. Card errors (listed in the document for P6A): `.RipplePxBackOffsets`
never runs (its header switch 0x271e is 0 on every level) — the ripple of levels 11 and 18 is inline in
`.PaintFrameWrap`; the rotating cannon arm (p1 101–106) is first placed on level 10, so it is 6A; water kinds 206–209,
rope bridge 1466 and table 0xb71 are placed on no level; the strip sprites take the first records on their six levels.
**Seat's rulings (D46):** the engine document's feature tasks own every type that has a feature section; the ledger's
type-split tasks own the rest. 6A-FB is absorbed by 6A-CF. A feature is proven before its level opens on a test-only
level fixture (the real level data without the still-unbuilt records) with a feature golden; the level's "enterable"
task pins the real first-frame golden as a new value. Frames of thunder, ripple and death are measured by the build.

**P6A was not reached in run 49** (the context cap: the three research tasks and their reviews took the run). It is
run 50's whole job.

### Task P6A — the Phase 6A plan (the planning run's product)

Written by the Opus planner from LL, BOS, ENG and the cards in wave 5, **in this file** (a new "Wave 5 — Phase 6A"
section expanded in place, the cards below replaced by bite-sized tasks — never a separate plan file): Verification
model additions (the 6A ladder, gate commands with numbers), tasks with Files/Contract/Tests/Gate/Commit, execution
order, stand-ins, known deviations, the gate card; two Opus legs + the Fable cross-check; rulings recorded under the next
free decision number. Its first task is 6A-BL, then 6A-FB, then the Warrior (replacing LV5's stand-in) — as planned:
6A-BL, then 6A-CF (which absorbed 6A-FB, D46.2), then 6A-FR and the Warrior's 6A-W1 / W2 (ENG P14). The 6B and 6C
sections are expanded the same way by their own planning runs at the end of 6A and 6B. The plan budgets the visit
sweep's time and memory as it grows from 5 to 24 levels (Ben's RAM rule).

**As executed (run 50, 2026-11-11).** Done: Wave 5 below, written by one Opus planner from the three documents (draft
636a8c3), two Opus review legs (both PASS WITH FIXES, 0 critical: 13 should-fix, 32 minor; fix round 41270e2 — 41
fixed, 3 rejected with reasons), then the Fable cross-check by a Fable reviewer (PASS WITH FIXES, 0 critical, 6
should-fix, 17 minor; fix round 16f3398 — 20 fixed, 3 rejected). **The plan:** 29 build tasks + 6A-END, 9 ⚑; Core
620 → 814, WinKit 82 → 90; runs 51–63 in four waves (6A.1 the Warrior, 6A.2 levels 10 / 11, 6A.3 level 15 and the
Chief, 6A.4 levels 20–22). Checked by script after each round: every card's number, the ladder / run / Proof B tables,
206 new test names against the 702 existing, 95 dependency pairs, the ledger's `--check` (OK, through the cross-walk
table). Rulings: D47. Ben's later read: Q19. The review found and the rounds fixed, among others: the pipes' level
spawn was inside a level task (now 6A-PS); the level fixture was inside the strip task (now 6A-FX) and opened levels a
way that would have missed the strip; the picture-cache task's file list was about fifteen files short (now ⚑); the
strip's colour table was unstated for five of its six levels; the ledger's two open reads had no owner (now a step in
every level task). **The four launch checks owed since run 48 were done by day at the head of this run, muted, all
passing** — G9M (boots, quits, no crash report), GW6 (three screens identical), GWB 617 / 0 / 3 / 0 (of 620), GW4R
(main menu identical) — on a stage of efeb66f; the cards updated (ee0fa6e); both builds staged again at the close.
Left open for the builds (the cards STOP if wrong): the in-package symlink of the fixture (6A-FX's first step); whether
all four pipe child types are on level 21 (6A-PS); stores to the strip's colour-table pointer during play (6A-S8).

---

## Wave 5 — Phase 6A (expanded by P6A, run 50, from LL, BOS and ENG)

Gate: **"through the Goblin Chief"** — levels 1–22 playable (the world file holds levels 1–5, 10, 11, 15, 18, 20, 21
and 22 in that span), the Warrior and the Chief beatable, Mac and Windows.

Sources, cited by section: **LL** = `docs/ferazel/later-levels-ledger.md`, **BOS** = `docs/ferazel/phase6-boss-contracts.md`,
**ENG** = `docs/ferazel/phase6-engine-contracts.md`; rulings D46 (1–6). Where a research document corrects a card of the
old Wave 5 table, the document won and the card below already says so; the "Planner's notes" at the end list the places
where two documents disagreed and what this plan chose. Spans are the committed dump's ("M l. N"); every card's brief
carries the standing sentence (*re-read each cited M line in the committed dump before coding; the dump wins; record any
disagreement in the task's As-executed note*).

**Every level task** ("level N enterable") is one level, or two adjacent levels when neither adds a class or an engine
feature (only 10 + 11 qualify, LL §8(c)): every record of the level set up (no `notTranscribed` — counted **per record**,
old types included, LL §10.8), the picture cache marked at the original's positions (6A-CF's list), the load bar counted,
a `Level<Name>Tests` file in `FerazelCoreTests`, the face-load tests extended (`BootFacesTests`' per-level pins,
`FaceTests`' per-level drops / keys table re-derived), the level's **new** real first-frame golden (Mac) and its Windows
reference, the visit sweep and the bot extended to it by the list, the bot's quick mode on it with 0 failures, then the
full GE; `BuiltLevels.list` gains the level only once its census sets up every record. A level task builds **no** engine
feature and **no** type: every feature and type task its data switches on comes first (D46.3; the pipes' level spawn is
its own type task, 6A-PS, before 6A-L21). It deletes or keeps its levels' feature goldens as each feature card says (the
ladder counts both). **Before the list widens, the parameter trace (LL §9's open reads):** a plain script over the level
files lists every already-built type placed on the level whose p1…p4 take a value no level 1–5 record of that type has
(crate and chest contents, item and scroll ids, path forms and modes, exits, rope geometry — LL §4 item 2 and §9 name
the kinds); the task traces each such value through the type's Setup and Handle arms in the dump and pins its
behaviour with one assert inside `testLevel<N>SetsUpEveryRecord` (asserts, not new tests — the ladder does not move);
the script's list and each value's dump line go in As executed. If an arm the value reaches turns out not to be built
(a `// later:`, a refusal, a missing case), STOP: the seat inserts a type task before the level task (a level task
builds no type). Each level card's Contract names its candidates from LL §4. `testLevel<N>SetsUpEveryRecord` also
asserts `SpriteWorld.refusedSpawns` (6A-W1) is 0 at its end — known deviation 6 makes a dropped spawn silent, so
neither the sweep nor the bot could report one.

**Every boss task** replaces its stand-in in place (same file, the ◇ markers removed) and passes the switch-off check
(its Handle — and its Hit, where the Hit is the task's — stubbed back with one local patch, never committed: every old
value returns); builds or completes the boss's three pieces (its `EnemyCommon.killProc` arm, its `.HitPlayerSprite`
step-7 row, its `.SmiteEnemies` entry — BOS §1.2) and the class duties of "Shared architecture"; adds BOS's "asserts the
build task adds" as assert lines inside its named tests (not new tests); and turns BOS's scripted-kill scenario into a
test by **running the starting key script once, measuring the HP-0 and Kill frames and pinning both** (D46.4) — a
script that fails (no Kill by its frame cap, or the player dies) is a STOP for the seat's ruling.

**Every engine-feature task** (D46.3) is built before its first level opens and proves itself on a **test-only level
fixture** (below) with a feature golden; it removes its own level-open refusal; **no golden of levels 1–5 moves** (those
goldens are its switch-off check: each ENG section says why the levels 1–5 path never reaches the new arm); it adds
ENG's "asserts the build task adds" inside its named tests and its `DrawModeAuditTests` writer rows (Invariant 8).

### Verification-model additions for 6A

- **The level fixture** — one design, stated here once, built by **6A-FX** (its own task, directly before 6A-S8, the
  first task that needs it); every task that uses it names its files in its Files. A named test stand-in, never in
  `Sources`; the game data stays read-only (the patch is made in memory).
  - `Tests/FerazelCoreTests/LevelFixture.swift` (new at 6A-FX): `LevelFixture.resources(level:leaveOut:header:)`
    returns a patched `FerazelResources` — the world's `ResourceCollection` copied in memory with the level's `Mlvl`
    changed only in the left-out placements' active flag and in the named header bytes (the pattern of
    `GameFlowGameTests.swift:297–306`): every other record, every other header byte and the stream as the level has
    them (ENG §7.2). `header:` is a list of (offset, bytes) patches, empty by default (6A-RP forces `0x26c6` to 0).
    `LevelFixture.open(level:leaveOut:header:start:prefs:carry:services:seed:)` opens that level **through the level
    runner** — `LevelRun(resources:…, prefs:, level:, seed:, carry:, …, services:, start:)` (`LevelRun.swift:247`), the
    `GoblinBurnLevelRunTests` / `TeleportLevelRunTests` pattern, never through `BuiltLevels` (`LevelRun` does not
    consult it) — so the strip sprites (`setupLevel`, 6A-S8) and the OmniPx turn-on (OX's R1, `LevelRun`'s level setup)
    exist. `start:` is `LevelRun`'s own start override (nil = the header's start; 6A-CP moves it); `prefs:` defaults to
    `FerazelPrefs()` (6A-RN sets the fading and sound preferences); `carry:` defaults to a new game's carry (6A-CH2
    hands a test carry); `services:` defaults to a headless stub (no faces — the `LevelServices` stub the Core
    `LevelRun` tests already use, e.g. `SoundVoicesTests`), so the **Core rules tests** open fixtures directly.
  - `Tests/FerazelRenderTests/LevelFixture.swift` (new at 6A-FX): a git symlink to the Core file (the
    `VisitSweepPlan.swift` pattern, here inside one package), at the **same folder depth** as the Core file, so any data
    path found from `#filePath` resolves the same in both targets; and
    `Tests/FerazelRenderTests/LevelFixtureServices.swift` (new at 6A-FX): the `LevelServices` built as
    `FerazelDriver.prepare` builds them (the `GoblinBurnLevelRunTests.Services` shape), the renderer made from the
    **same** patched resources (`FrameRenderer.init` runs `SetupFaces` on the active placements,
    `FrameRenderer.swift:195`) — so the **Render tests** (goldens, burns) open the same fixture with face pixels. The
    in-package symlink is 6A-FX's first step; if SwiftPM refuses it, 6A-FX STOPs for the seat (the fallback is in its
    card; never two copies of the file).
  - **Each fixture's leave-out list is a literal list written in the test** — by type where every record of the type
    is left out, by placement index otherwise (level 10's three refused 1090 records, p1 101 / 103) — with its count
    asserted (31, 27, 14, 27, 23, 30, 44, 16, or 0 — each card gives its own); **never computed from what the port
    refuses today**, so a later task cannot change an earlier fixture's world by building a type. An empty list for a
    level that opens with nothing left out but is not yet in `BuiltLevels` (15 for 6A-RN, 18 for the Chief, 20 for
    6A-MP, 21 for 6A-PS, 22 for 6A-CP). Moving a task changes its fixture — re-read ENG §7.2 then. A test that only
    needs records of one type, or a level's header, reads them from the level file (per record through
    `SetupFaces.setup`, or the header alone) and opens no level; each card says which of the three its tests use.
- **New goldens are new values, not moves.** Three kinds: a *feature golden* (on a fixture, Mac,
  `Tests/FerazelRenderTests/FeatureGoldenTests.swift`, new at 6A-S8), a *level first-frame golden* (the real level, Mac,
  `Tests/FerazelRenderTests/LevelFrameGoldenTests.swift`, new at 6A-L10L11) with its *Windows reference*
  (`Ferazel/Windows/Tests/FerazelWinKitTests/WinLevelReferenceTests.swift`, new at 6A-L10L11: `WinGame` headless,
  `-FerazelLevel N`, N held, the FNV and flow step of the first presented **level** frame — the first one after the
  chapter card when `-FerazelLevel N` shows one, measured at 6A-L10L11, the card itself being 6A-MC's golden —
  `WinReferenceFramesTests.framesRun`'s shape), and the two *chapter-card goldens* (6A-MC). Each is measured by the build, recorded in the task's As executed
  and, at the wave close, in this plan's "Goldens" paragraph. The CrossOver smoke script keeps its three level-1
  references only. **Only 6A-W1 and 6A-W2 (◈) may move an existing level golden** — level 5's (`BootFacesTests` level-5
  pins init 46 / `0xb039da66a884cb8a`, f30 55 / `0x69068d5e8151b0cc`, f120 55 / `0xb9f08ee19927f3e7`, and any other
  level-5 value), for their named cause, with the switch-off check. **A fixture golden of an earlier 6A task** (a
  feature golden, or a frame value pinned on a fixture) may move only in a later task marked ◈ **for that one golden**,
  because that task's feature is live in that fixture's frame: it names the cause, lists old → new in its commit body
  and As executed, and carries the switch-off check (its new branch stubbed with one local patch, never committed → the
  old value returns). Today one case is known — **6A-WD on 6A-S8's level-10 strip golden** (wind cells in the frame;
  the fixture leaves no wind cell out). Every other 6A fixture's world is fixed by its literal leave-out list, and no
  later 6A task's feature is live in it (checked against each card: the trees, cannons, Box scenery, blades and maces a
  later task builds are left out of every earlier fixture that holds them). Any other fixture-golden move is a STOP.
- **Measured, never invented** (D46.4): every golden's value and frame, every scripted kill's HP-0 and Kill frame, the
  first thunder frame, the first ripple frame, the Chief's activation frame on level 18. The build measures, pins and
  records; a later change is a STOP (Invariant 10).
- **Burns end only with face pixels** (process lesson): a kill whose death ends in a burn completes only through the real
  renderer's face store, so the kill-frame and scripted-kill tests live in `Tests/FerazelRenderTests/BossKillLevelRunTests.swift`
  (new at 6A-W2), as `GoblinBurnLevelRunTests` does; the rest of each boss's tests stay in `FerazelCoreTests/Enemies/`.
- **Proof-B test rules** (Phase 4–5 lessons): no `@MainActor` test class; no `FileManager.enumerator` or
  `NSRegularExpression`; no Foundation string search or trim (`String.contains(String)` traps under Wine) — plain Swift.
- **Gate bundles** (the commands are §0's; every task also runs G6 ⊆ its Files, G7 / G7b / G8, G10 after each commit,
  and `--filter DrawModeAuditTests` with moved writer rows re-anchored, values unchanged).
  `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (its rows are `file:line`) is **inside every task's fence** for
  line re-anchors only, values unchanged, whether or not the card's Files name it; 6A-CF and 6A-FR touch different
  regions of it (CF the face-store / `LevelRun` rows, FR the `HitPlayerSprite` rows), so they may still run at once.
  - **Gate-F** (feature or type task; Core / Render only — lockstep (b)): G2 = the ladder number with exactly the two
    named opt-in skips; G5; GW1 0 / 2; GW2 = the WinKit number / 0 / the two named skips; GW3 0 / 1; GW4; every built
    level's goldens unchanged — levels 1–5's, `LevelFrameGoldenTests`, the Windows level references and the
    `BootFacesTests` pins (from 6A-L10L11 on that is more than levels 1–5) — and every earlier fixture golden unchanged
    (`FeatureGoldenTests`, the fixture frame values in `HorizonStripTests` and `LevelFixtureRenderTests`) except the one
    a ◈ card names; the feature golden measured and pinned.
  - **Gate-B** (boss task): Gate-F with ◈ (the switch-off check, every moved value old → new in the commit body and As
    executed) where a golden moves; the bot's quick mode on the boss's level (`FERAZEL_BOT_LEVELS=n FERAZEL_BOT_MINUTES=1
    tools/ferazel-random-play.sh core`) 0 failures, its `== core:` line recorded — only when that level is in
    `BuiltLevels.list`; otherwise the check moves to the level's task (the bot exits 2 on an unbuilt level).
  - **Gate-L** (level task; lockstep (a): the Windows side is in the task): Gate-F; G3; the new Windows reference test
    (GW2 + 1 a level) and `FerazelSettingsTests`' `-FerazelLevel` rows for the new ids; the quick mode on each new
    level 0 failures; then the full GE — `tools/ferazel-visit-sweep.sh both`, then `tools/ferazel-random-play.sh both`,
    every built level, background, at most 4 workers, nothing else heavy running — both exit 0, summary lines in
    LOOP-LOG (budget below).
  - **Wave end:** G3; GWB by day (the line below); GW4R by day; the Fable cross-check of the wave's whole diff and gate
    numbers before the next wave's first task (§0) — it opens the next run when the context is spent. The last wave's
    cross-check is the phase review (6A-END). A wave end's GWB or GW4R owed by the night rule is the **first act of the
    next run that starts by day**, before any task; no wave end closes while the previous wave's is still owed.

**The 6A ladder** (Core G2 total, 2 opt-in skips throughout; WinKit GW2 total, 2 opt-in skips throughout). Each task's
"(→ N)" = the previous N + its new tests − the feature goldens it deletes; "+a / −d" names both.

| # | task | ⚑ ◈ | tests | Core after | WinKit after | wave end: GWB by day (P = N − 3) |
|---:|---|---|---|---:|---:|---|
| — | start (run 49 close) | | | 620 | 82 | |
| 1 | 6A-BL built-level list | | +2 | 622 | 82 | |
| 2 | 6A-CF picture cache in full (+ the fireball records) | ⚑ | +6 | 628 | 82 | |
| 3 | 6A-FR falling rocks' player arm | | +5 | 633 | 82 | |
| 4 | 6A-W1 the Warrior's Handle | ⚑ ◈ | +9 | 642 | 82 | |
| 5 | 6A-W2 the Warrior's Hit, Kill, fight | ⚑ ◈ | +8 | 650 | 82 | **6A.1 end:** 647 / 0 / 3 / 0 (of 650) |
| 6 | 6A-FX the level fixture | | +2 | 652 | 82 | |
| 7 | 6A-S8 horizon strip | ⚑ | +11 | 663 | 82 | |
| 8 | 6A-WD wind | ◈ (S8's strip golden only) | +9 | 672 | 82 | |
| 9 | 6A-RC rotating cannons | | +10 | 682 | 82 | |
| 10 | 6A-TR trees | | +11 | 693 | 82 | |
| 11 | 6A-RP river ripple (+ the T11 proof) | ⚑ | +10 | 703 | 82 | |
| 12 | 6A-BX1a Box scenery | | +6 | 709 | 82 | |
| 13 | 6A-BX1b Box faces and talkers | | +4 | 713 | 82 | |
| 14 | 6A-MC conversations and chapter cards | | +3 | 716 | 82 | |
| 15 | 6A-L10L11 levels 10 and 11 enterable | ⚑ | +8 / −2 | 722 | 84 | **6A.2 end:** 719 / 0 / 3 / 0 (of 722) |
| 16 | 6A-BG1c plants | | +3 | 725 | 84 | |
| 17 | 6A-RN rain, thunder, side push | ⚑ | +12 | 737 | 85 | |
| 18 | 6A-L15 level 15 enterable | | +4 / −1 | 740 | 86 | |
| 19 | 6A-CH1 the Chief's class and Handle, the stagger | ⚑ | +12 | 752 | 86 | |
| 20 | 6A-CH2 the Chief's Hit, Kill, fight | ⚑ | +8 | 760 | 86 | |
| 21 | 6A-L18 level 18 enterable | | +4 | 764 | 87 | **6A.3 end:** 761 / 0 / 3 / 0 (of 764) |
| 22 | 6A-CL clouds | | +7 | 771 | 87 | |
| 23 | 6A-BD rotating blade | | +13 | 784 | 87 | |
| 24 | 6A-MP mace paths | | +7 | 791 | 87 | |
| 25 | 6A-L20 level 20 enterable | | +4 / −1 | 794 | 88 | |
| 26 | 6A-PS the pipes' level spawn | | +1 | 795 | 88 | |
| 27 | 6A-L21 level 21 enterable | | +3 | 798 | 89 | |
| 28 | 6A-CP magic carpet | | +12 | 810 | 89 | |
| 29 | 6A-L22 level 22 enterable | | +4 | **814** | **90** | **6A.4 end = phase end:** 811 / 0 / 3 / 0 (of 814) |
| 30 | 6A-END phase end | | 0 | 814 | 90 | (the same, at the staged head) |

New tests 198, deleted 4 (the wind, rotating-cannon, rain and mace-path feature goldens), net **+194**. 29 build tasks
+ the phase end; **9 ⚑** (CF, W1, W2, S8, RP, L10L11, RN, CH1, CH2); ◈ W1 and W2 (level 5's goldens) and WD (one
fixture golden, 6A-S8's level-10 strip golden). Review fix rounds add asserts, not tests, unless the seat rules
otherwise (As executed); the level tasks' parameter-trace pins ("Every level task") are asserts inside
`testLevel<N>SetsUpEveryRecord`, not new tests; merged out of order: previous + the task's net N.

**The old cards' ids → the 6A tasks** (the ledger's owner names, `docs/ferazel/later-levels-ledger.md`, are the old
ids; its `--check` reads this table):

| old card | 6A tasks |
|---|---|
| 6A-BL | 6A-BL |
| 6A-FB | 6A-CF (D46.2) |
| 6A-W | 6A-W1, 6A-W2 |
| 6A-FR | 6A-FR (the rocks' spawn is 6A-W1's) |
| 6A-S8 | 6A-S8 |
| 6A-WD | 6A-WD |
| 6A-RP | 6A-RP |
| 6A-T11 | 6A-RP (two proof tests) |
| 6A-RN | 6A-RN |
| 6A-BG1 | 6A-TR, 6A-CL, 6A-RC, 6A-BD, 6A-MP, 6A-BG1c (D46.1) |
| 6A-BX1 | 6A-CP, 6A-BX1a, 6A-BX1b, 6A-PS (the pipes' level spawn) |
| 6A-BN1 | dropped (nothing to build, LL §10.3) |
| 6A-L10…L22 | 6A-L10L11, 6A-L15, 6A-L18, 6A-L20, 6A-L21, 6A-L22 (the level-21 pipe wiring: 6A-PS) |
| 6A-CH | 6A-CH1, 6A-CH2 |
| 6A-MC | 6A-MC |
| 6A-END | 6A-END |

---

#### 6A-BL — minor — the built-level list (→ 622)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (`range` `:11` → `public static let list: [Int] = [1, 2, 3, 4, 5]`
  + `contains(_:)`; the doc comment), `Sources/FerazelCore/Front/NewGame.swift` (`:68`, `:277–:280`),
  `Sources/FerazelCore/Front/ContinueGame.swift` (`:134–:135`), `Sources/FerazelCore/Front/GameFlow.swift` (`:170`, the
  doc comment naming `BuiltLevels.range`), `Ferazel/Shared/FerazelDriver.swift` (`:39–:44`, both
  shells; the `:12` doc comment naming `BuiltLevels.range`), `Tests/FerazelRenderTests/VisitSweepPlan.swift` (`:18`) and `Tests/FerazelRenderTests/RandomPlayPlan.swift`
  (`:120`) (both git-symlinked into `FerazelWinKitTests`), `tools/ferazel-built-levels.sh` (new — prints the list as
  `1,2,3,4,5` from the one source line), `tools/ferazel-random-play.sh` (`:74–:89`: the `sed` / `seq` range parse →
  the helper's list; `FERAZEL_BOT_LEVELS` checked against it; the header comments `:4`, `:44` naming the range),
  `tools/ferazel-visit-sweep.sh` (`FERAZEL_VISIT_LEVELS` checked against it; the header comments `:4`, `:43`), the tests pinned to the range (each retargeted, values unchanged): `Tests/FerazelCoreTests/{GameFlowGameTests.swift:249,
  LevelFiveTests.swift:320–:321, LevelFourTests.swift:158, LevelThreeTests.swift:355}`, `Tests/FerazelRenderTests/{BootFacesTests.swift:237/:303/:359,
  DrawModeAuditTests.swift:931/:1756, LevelSweepTests.swift:60/:75/:80, FaceTests.swift}` (the per-level loop),
  `Ferazel/Windows/Tests/FerazelWinKitTests/FerazelSettingsTests.swift` (`:17–:19` comment and rows: `("6", 1)` and
  `("10", 1)` added — asserts, WinKit unchanged), `Tests/FerazelCoreTests/BuiltLevelsTests.swift` (new).
- **Contract:** the old card's (a closed range cannot say "1 to 5, then 10"; `1...10` would admit 6–9, which have no
  level data). One sorted list of built level ids; every reader asks `contains`; the scripts take the list from one
  printed source. No behaviour changes in this task (the list holds 1–5); the not-built report text is unchanged
  ("Level n is not built yet (Phase 6).", D35 — deleted at 6C-END). `-FerazelLevel` outside the list → 1, as today.
- **Tests (2):** `testBuiltLevelsListAndContains` (the list is `[1, 2, 3, 4, 5]`, sorted, no duplicates; 6–9 and 10 are
  not in it; `notBuiltReport(10)`) · `testBuiltLevelsSourceLineParses` (`BuiltLevels.swift` holds exactly one line of the
  shape the helper reads, and its plain-Swift parse equals `BuiltLevels.list` — the script and the code cannot drift).
- **Gate:** Gate-F (G2 622, GW2 82 — the shared driver and the symlinked plans compile and pass in both packages);
  the bot's quick mode on level 1 through the new parse (`FERAZEL_BOT_LEVELS=1`) exits 0 and a bad level (`=6`) exits 2;
  `tools/ferazel-watchdog-selftest.sh` still passes. **Commit:** `Ferazel: BuiltLevels becomes an explicit list; the
  scripts read it from one source; 2 tests`.
- **As executed — 6A-BL (run 51):** task 3831cb6 (2 tests, `BuiltLevelsTests`), review fix round 0cbab29 (asserts and
  self-test rows only). Two Opus legs: MERGEABLE (0 / 0 / 8 minor), then MERGEABLE WITH FIXES (0 / 0 / 11 minor; 11
  surviving mutations, all killed by the fix round). **Card against code:** `BootFacesTests` `:359` and `FaceTests`'
  loop were literal `1...5` loops, not reads of the range — both retargeted to the list. **Beyond the card (seat's
  rulings):** the visit sweep now checks `FERAZEL_VISIT_LEVELS` (it never did) and both scripts parse their level
  setting alike — an unbuilt level, a repeated id or a set-but-empty value exits 2 before any worker starts, and the
  message names the setting; `tools/ferazel-watchdog-selftest.sh` admitted to Files (it now runs the helper and the bad
  level settings: 55 → 63 verdicts); `testContinueRefusals` gains the level-10 save. Left: a bot run with no
  `FERAZEL_BOT_LEVELS` at all has no self-test row (it would run the real bot). "Shared architecture"'s
  `BuiltLevels.range` paragraph now reads `BuiltLevels.list`.

#### 6A-CF — ⚑ MAJOR — the picture cache in full, keyed by record (+ the fireball records) (→ 628)
- **⚑ because** more than five files outside `CachedFaces` change (EnemyShot, FrameRenderer, two re-anchored tests, the
  new test file, `FaceTests`; FaceRef and the audit if needed).
- **Files:** `Sources/FerazelCore/Front/LevelRun.swift` (`CachedFaces`, `:1085` on: `sets`, `singles`, `marks`,
  `handleSets`, `loadedSets`, `load(needed:)`, `sheets(markedBy:)`, `needed(by:)`), `Sources/FerazelCore/World/Enemies/EnemyShot.swift`
  (`:381`, `:400` — the face read by record), `Sources/FerazelRender/Frame/FrameRenderer.swift` (**required**:
  `spriteSheets` `:219–:239` loads one sheet per PICT — the `seen` set — so 0x46a's two cuts cannot both load; the
  face store keys 0x46a's cuts by record), `Sources/FerazelCore/Seams/FaceRef.swift` (only if the 64×64 cut cannot ride
  in `FaceRef` as it is: one `FaceSetKind` case added — Invariant 9, lockstep (a), named in As executed).
  The tests that must change (grep `CachedFaces|loadedSets|markedBy|handleSets` under `Tests`, 2026-11-11 — every other
  hit stands, the outward API staying picture-valued, below), each re-derived from LL §6, none edited to agree:
  `Tests/FerazelCoreTests/LevelFiveTests.swift:136–:139` (the Dillo's 0x751, the Warrior's three, then the Floater's
  0x6f4 — the Wizard, Chief, Demon and Xichra records now sit between) and
  `Tests/FerazelCoreTests/Enemies/GremlinFloaterTests.swift:252–:257` (the 16 sets from 0x762 — the same insertion).
  `Tests/FerazelCoreTests/CachedFacesTests.swift` (new), `Tests/FerazelRenderTests/FaceTests.swift`
  (`testFireballCutsByRecord`: it needs face pixels), `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (only if the
  face-store change adds a trap or a throw: its census row). `BootFaces` is untouched; `handleSets` keeps its twelve
  rows (the new records carry their own geometry), so `BootFacesTests.swift:149` stands.
- **Contract:** LL §6 (the table is the transcription target), LL §8(b)1 (the card), ENG §2.14 (R2). Dump:
  `.InitSprites` M l. 103–145 (the Init order), the two cache routines M l. 73888–73902 (sets) / 73943–73951 (singles),
  `.LoadCachedSpriteFaces` M l. 73769–73869; EnemyShot M l. 51434–51436 and 51822–51861.
  - The whole registration list: **285 records — 92 sets, 193 singles, 805 faces** — in `.InitSprites` order, each with
    its geometry and its CLUT flag (the boss Inits' flag-1 records; the cannon set 0x442's flag 0), keyed by **record
    (list position)**, not picture, in the records, the marks, the loaded records, the load and the face store.
  - **The outward API stays picture-valued** (fix-round ruling): `marks(type:p1:)` still returns PICTs; `sets` /
    `singles` stay `Record` arrays in list order, each record carrying its `pict`; `Needed(sets:singles:)`,
    `needed(by:)`, `loadedSets` / `loadedSingles` and `sheets(markedBy:)` keep their PICT-valued shapes as views. The
    record key is added beside them (e.g. `markedRecords(type:p1:)`, `Needed.records`, `loadedRecords`); the load, the
    bar count and the face store key by it. A PICT-valued `Needed` marks every record of that PICT (only 0x46a has more
    than one, and no level 1–5 type marks it). So these existing asserts stand unedited: the `marks(type:).sets ==
    [PICT…]` rows of the Bat, Blob / Crab, Dillo, EnemyShot, Frog / Salamander, Gremlin / Floater, Walker and Geyser
    tests; `WalkerTests.swift:1929–:1933`; `GameFlowGameTests.swift:555`; `BootFacesTests.swift:149–:221, :247–:282`;
    `FaceTests.swift:584, :619`; `LevelThree / Four / FiveTests`' `needed` / `load`; `BatTests.swift:293–:297` and
    `GeyserTests.swift:233–:235` (their neighbours stay adjacent in the full list: the Bat's five then the Blob's 0x6c2,
    LL §6; the geyser's three consecutive). A hit found failing that this list says stands is a STOP.
  - The **23 records whose PICT no file holds** (2805–2807, 2950, 2966–2969, 1489, 2718–2729, 1790, 1791) kept as
    records that load nothing: `.CountNeededCachedSpriteFaces` has no presence test (M l. 73749–73764), so a **marked**
    absent record counts its faces in n and in q = 2n, makes no step and is never marked loaded (M l. 73822–73832,
    73852–73859), and is counted again at every load. Unreachable as shipped — no placed type marks one (types 2805–2807,
    2950, 2966–2969, 1489, 2718–2729 and the Wraith variant are placed nowhere) — so it is a data pin.
  - The marks the port misses for types it already calls built (LL §1 finding 8): set 0x442 for every cannon
    0x443…0x44a; the spring sets 0x47e / 0x47f / 0x480 (1150…1153); each mace / ball single 0x5c8…0x5d0 by type; the
    hang glider 0xbea's four Player sets 0x41a…0x41d (records #1–#4); the passage single 0xb55. Marks of types not
    built yet stay with their tasks (trees, clouds, plants, scenery, the carpet set 0x438, the Chief's five, fire 1208).
  - Picture 0x46a has **three records and two cuts** (48×48 at `_DAT_100a0848`; 64×64 twice at `0844` / `0840`,
    identical): 0x46a reads `0848`, 0x46b `0844`, 0x46c `0840`; each Setup marks its own record (the Wizard only `0848`,
    the Demon all three, Xichra #1 and #3).
  - **Levels 1–5's load-bar steps are unchanged**, so no level 1–5 golden moves: their only types in the new ranges
    (0x442, 0x5cd, 0xb54) are already marked (LL §8(b)1).
- **Tests (6):** in `CachedFacesTests` (Core) unless named: `testCacheRegistrationListInFull` (285 / 92 / 193 / 805;
  every row's order, geometry and flag against LL §6; assert: a synthetic mark on an absent record counts in n and q,
  makes no step and leaves the record unloaded; no placed type on the 24 levels marks one) · `testLevel20LoadBarMarks`
  and `testLevel22LoadBarMarks` — computed from the level file per record (each record `SetupFaces.setup` sets up at
  this point, its record-keyed marks; no level opened). Each pins **only CF's own marks** on that level (20: the four
  Player sets by 3050, set 0x442 by 1092 / 1094 / 1096; 22: 0x442 by 1091 / 1094 / 1096, the mace singles by type —
  checked against §6's mark column) and the level's needed-record count and bar total at CF's point, measured. **Every
  later task that adds a mark on level 20 or 22, or makes one of their records set up, names `CachedFacesTests.swift` in
  its Files and re-derives that count and total** (20: RC, CL, BD, MP; 22: BX1b, BD, MP, CP), old → new in its As
  executed — an expected re-derivation, not a golden move; at 6A-L20 / L22 the opened level's `needed(by:)` is asserted
  equal to it · `testFireballCutsByRecord` (Render, in `FaceTests`: 0x46a draws the 48×48 cut, 0x46b / 0x46c the 64×64
  one, each from its own record; the two 64×64 cuts equal) · `testShot46bReadsRecord0844` (0x46b's face comes from
  record `0844`; assert: 0x46c reads `0840`, not `0844`) · `testCacheMarksPerRecord` (a Setup that marks record #k marks
  no other record of the same PICT). Asserts: ENG §2.14's first (the spark draws are 6B-WZ1's).
- **Gate:** Gate-F (G2 628; G5, GW1–GW4 for the renderer and any `FaceSetKind` case); `BootFacesTests`,
  `LevelFiveTests` and `GremlinFloaterTests` green with the re-anchored neighbours; levels 1–5 load-bar step counts
  printed before and after — identical. **Commit:** `FerazelCore: the picture cache in full (285
  records, keyed by record), the missing marks of built types, the fireball's three records; 6 tests`.
- **As executed — 6A-CF (run 51):** task dc1d65c (6 tests: 5 in `CachedFacesTests`, `FaceTests.testFireballCutsByRecord`),
  review fix round asserts only (no new test). The 285 rows match the dump row for row (both legs). Levels 1–5 load
  bars identical before and after; no golden moved. **Files beyond the card:** `Sources/FerazelRender/Frame/SpriteBlitter.swift`
  (the face store is `SpriteBlitter.Faces`: `recordSheets`, the `records:` init parameter, the record fallback in
  `face(_:)` — FrameRenderer cannot key by record without it); `tools/windows/proof-b-ferazel.sh` (fix round: the
  ledger copied into the Windows proof run's work tree — `CachedFacesTests` reads it five levels above `#filePath`).
  **Dump over card:** (a) the mace / ball arm runs **0x5c8…0x5d1** (singles #151…#160), not …0x5d0 — the `else` of
  `t < 0x5c8` guarded `t < 0x5d2` (M l. 62312–62321); 0x5d1 is the absent PICT 1489 and placed nowhere; (b) a marked
  absent record **is counted in n** (q = 2n) at every load — `.CountNeededCachedSpriteFaces` has no presence test (M l.
  73749–73764) — and makes no step (M l. 73822–73832, 73852–73859). LL §1 findings 8 and 9 corrected to match; LL §4's
  preamble notes that the Bat 1851 marks set #48 0x73b only for p1 < 0 (M l. 68262–68267), so not on levels 22 / 31.
  Measured at CF's point: level 20 needs 10 records, n 51, q 102, 10 steps; level 22 33 / 168 / 336 / 33.
  **`later:` for the first task that marks a 0x46a record (6B-WZ1 / the Demon / Xichra):** the Setup-level per-record
  mark asserts (the Wizard `0848` only, the Demon all three, Xichra `0848` + `0840`); assert the opened level's
  `renderer.sprites.faces.recordSheets.keys`; extend `DrawModeAuditTests`' per-sheet probes to `recordSheets`;
  re-derive `testCacheMarksPerRecord`'s `recordSheets(markedBy: 0…0xd00).isEmpty`; and either route
  `CachedFaces.sharedPict` refs to the record store first in `SpriteBlitter.Faces.face` or retire
  `EnemyShot.cachedSheets` (a PICT-keyed 0x46a sheet would shadow the record cuts and refuse 0x46b / 0x46c's faces).

#### 6A-FR — minor — the falling rocks' player arm (→ 633)
- **Files:** `Sources/FerazelCore/Player/HitPlayerSprite.swift` (`:177`, the `// later: Phase 6` arm),
  `Tests/FerazelCoreTests/FallingRockTests.swift` (new).
- **Contract:** ENG §2.12 (BOS §2.7). Dump: `.HitPlayerSprite` M l. 49170–49188 (not `.HurtPlayer`, ENG P11). 0x434
  with `+0x160 < 0` → return at once; 0x433 with `+0x160 ≥ 0`: its centre y < the player's (strict) and vy > 599 →
  `.HurtPlayer(player, rock, 0x38, blood 1, invul 0x1e, coins 0)` + `.KillBox(rock)`, return, else fall through; 0x434
  with `+0x160 ≥ 0` the same with 0x70 / 0x3c; a 0x433 with `+0x160 < 0` matches no arm and falls through. The Box arms
  (`BoxSprite.isBoulder`), `.KillBox` and `.HurtPlayer` are built. No rock exists before 6A-W1, so levels 1–5 never
  enter the arm; no feature golden (6A-W2's scripted fight is its first frame proof).
- **Tests (5)** (synthetic rocks beside the player; no level opened): `testRock433HurtsWhenFallingOnPlayer` · `testRock434HurtsHarder` · `testRock434NegativeReturnsEarly` ·
  `testRockSlowOrBelowFallsThrough` · `testRockBoundaries` (a 0x433 with `+0x160 < 0` falls through; equal centre y
  falls through; vy 599 falls through, 600 hurts). Asserts: ENG §2.12's three.
- **Gate:** Gate-F (G2 633). **Commit:** `FerazelCore: the falling rocks' player arm (0x433 / 0x434); 5 tests`.
- **As executed — 6A-FR (run 51):** task 5c95d75 (5 tests, `FallingRockTests`), review fix round 8919326 (tests only;
  the Sources file byte-identical to the task commit). Two Opus legs: MERGEABLE (0 / 0 / 4 minor), MERGEABLE (0 / 0 /
  6 minor; 32 mutations, 30 killed after the fix round, 2 equivalent: the arm before or after the NPC test — a rock type
  is never an NPC type). No disagreement between dump, documents and card (BOS's "vy ≥ 600" is the dump's `599 < vy`).
  The arm sits in the Box arm before the NPC test, as M l. 49170–49188 orders it. The tests build a world from level
  1's header without a level run. `DrawModeAuditTests`: three `HitPlayerSprite` rows re-anchored, values unchanged.
  **`later:` for 6A-W1 (it spawns the rocks):** type 0x434 has no row in `SpriteClassTable`; the `classWord160` doc
  comment should name the rock's hover counter.

#### 6A-W1 — ⚑ MAJOR ◈ — the Warrior's Handle: the crates, the decide, the walk and run, the swing and shot, the dying (→ 642)
- **Files:** `Sources/FerazelCore/World/Enemies/Warrior.swift` (the ◇ Handle replaced in place; the stand-in markers
  removed), `Sources/FerazelCore/Session/FerazelSession.swift` (the `.warrior` Handle row), `Sources/FerazelCore/World/Enemies/EnemyCommon.swift`
  (`liquids(class: .dillo)` reused by the Warrior's tail, BOS §2.3), `Sources/FerazelCore/World/Enemies/CrawlerRoach.swift`
  (`hitTile` reused as `.HitWarriorTileSprite`, only if it must be widened), `Sources/FerazelCore/Session/SpriteWorld.swift`
  (`newSprite` `:176`: a `refusedSpawns` count, + 1 whenever a spawn finds no free record — known deviation 6's
  diagnostic, read by every level task's `testLevel<N>SetsUpEveryRecord`), `Tests/FerazelCoreTests/Enemies/WarriorTests.swift`
  (new), `Tests/FerazelRenderTests/BootFacesTests.swift` (level 5's pins, ◈), `Tests/FerazelCoreTests/LevelFiveTests.swift`
  (any level-5 value the real Handle moves, re-derived), `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (the
  Warrior's face writers), `Tests/FerazelRenderTests/FaceTests.swift` (asserts only: `testEverySpawnableTypeHasSheet`
  gains the crate 0x433 and the shot 0x71f on level 5 — 0x71f is a boot set, `BootFaces.swift:79` — if not already
  there; "Shared architecture", faces of run-time-spawned sprites).
- **Contract:** BOS §2.3 (the Handle, the state table, the decide, the timing facts, the spawn frame order, the tail),
  §2.8 (hazards). Dump: `.HandleWarriorSprite` M l. 73115–73419, `.WarriorLayEgg` 73080–73092, `.RandomWarriorAttack`
  73095–73112, `.HitWarriorTileSprite` 73498–73530.
  - The **boss-mode block** (p4 ≠ 0, whatever the lock, M l. 73151–73213): the three crate slots `+0x1d4/+0x1d8/+0x1dc`,
    the first Handle frame spawns all three 0x433 at (689, −173), (945, −273), (1201, −173), **layer 2** (the Box Setup's,
    not the argument 9); a dead crate's slot is cleared on the first Handle that sees `+0xe9`, the new crate comes 14
    Handle frames later (k + 14 for a kill before his Handle, k + 15 for a collide-pass kill); the wounded glow.
    **This closes the Phase 5 carry "the Warrior's pre-lock rocks are not spawned".**
  - States 6 (decide; unlocked → return before gravity), 7 (walk 15 frames ±0x600 / run 7 frames ±0xc00), 2 (attack:
    snd 704 at n = 7, shot 0x71f at n = 9, first swing 18 frames, later 17), 4 (dying, `+0x1a2 = 1` on dying frame 45);
    the decide's draws R(100), R(3), R(100) [, R(100) → the egg's R(2)]; `.RandomWarriorAttack` draws R(100) and
    **discards it**, then R(2) (BOS D1); R(6000) at n = 7 (M l. 73233); the 0x71f Setup's R(5) at n = 9 (M l. 51460);
    R(9) on every exit to state 6 (M l. 73259, 73296, 73320).
  - Spawn frame order: neither the crates (layer 2, in front of him) nor the shot (layer 0) run on their spawn frame.
  - No free record (Ruling 16, widened as BOS §1.1 — known deviation 6, ruled under D47 before this task): `+0x16c`
    keeps counting below 1, the slot re-tries each frame; the shot's vx store through a null result is dropped;
    `SpriteWorld.refusedSpawns` counts each such spawn (asserted in `testWarriorCrateRespawnAfter14Or15` with a full
    record table). No `SpriteSlot` copy held across a spawn (`SpriteWorld` rule 2).
  - The tail reuses the `.dillo` liquids (BOS §2.3); its test is W2's `testWarriorLavaAndBrine` (BOS §2.9's split), so
    W1's mutation leg may find the liquids unpinned — accepted, named in As executed.
  - ◈ **Cause: the real Handle runs on level 5** (crates from frame 1). Switch-off: stub the Warrior Handle body back to
    LV5's stand-in — level 5's old values return. Levels 1–4: no Warrior — unchanged.
- **Tests (9)** (level 5 — built — directly, as `LevelFiveTests` opens it; no fixture): BOS §2.9's 6A-W1 list, names as written: `testWarriorCratesFirstFrame` ·
  `testWarriorCrateRespawnAfter14Or15` · `testWarriorUnlockedReturnsBeforeGravity` · `testWarriorDecideDraws` ·
  `testWarriorAttackDiscardsR100` · `testWarriorSwingTimingAndShot` · `testWarriorWalkRunCycles` ·
  `testWarriorDeathAndGlow` · `testWarriorTileCallbackIsCrawlerBody`. Asserts: BOS §2.11 items 1–21.
- **Gate:** Gate-B (G2 642; ◈ level 5's moved values old → new; the bot's quick mode on level 5).
  **Commit:** `FerazelCore: the Warrior's Handle — crates, decide, walk / run, swing and shot, dying; 9 tests`.
- **As executed — 6A-W1 (run 52):** task 8f1d61f (9 tests, `WarriorTests`), review fix round 0e378b9 (asserts and
  wording; Sources comments only). Two Opus legs: MERGEABLE AFTER FIXES (0 / 1 / 7 minor — the Handle matches the dump
  line for line), MERGEABLE AFTER FIXES (0 / 5 / 10 minor; 156 mutations: 123 killed, 9 equivalent, 22 survivors — all
  22 killed after the fix round — and the 2 liquids survivors the card accepts until 6A-W2). No disagreement between
  dump, BOS and card.
  ◈ **Moved (level 5 only, the three crates):** `BootFacesTests` f30 55 / `0x69068d5e8151b0cc` → 58 /
  `0x1142f7a252aecfcd`; f120 55 / `0xb9f08ee19927f3e7` → 58 / `0x9806297cea4531f2`. Init 46 / `0xb039da66a884cb8a`
  held; no `LevelFiveTests` value and no golden of levels 1–4 moved. Switch-off (the Handle body stubbed back to the
  stand-in) returned every old value — done by the implementer and by leg 1 independently.
  Gate-B: the bot's quick mode on level 5 — `== core: random play — levels 1, seeds 4, steps 7200, deaths 1, exits 17,
  conversations 0, saves 0, failures 0 in 166 s`; G5, GW1 0 / 2, GW3 0 / 1, GW4 green; GW2 not run (nothing Windows or
  Shared touched).
  Notes: (a) on level 5 a crate that lands rests on a background ledge and never breaks by landing (the dump agrees), so
  `testWarriorCrateRespawnAfter14Or15` uses a **test-only foreground ledge patched into the in-memory map** for the
  k + 14 case and calls the crate-break routine after a frame for k + 15 — a test stand-in, though the card says no
  fixture. (b) The constants 0.9 / 0.4 / 0.5 were confirmed by leg 1 in the binary's unpacked data section
  (0x100a1c30 / 1c38 / 1c40). (c) 6A-FR's two `later:` items closed as comments: the dump's sprite generation has no
  0x434 arm (M l. 1740–1741), so `SpriteClassTable` rightly has no row and says so; `classWord160` names the rocks'
  hover counter — `SpriteSlot.swift`, `SpriteClassTable.swift` and (wording) `BuiltLevels.swift` joined the Files by
  the seat's ruling. (d) `testLevel5SetsUpEveryRecord` now asserts `refusedSpawns == 0` after 30 frames. (e) Rope
  segments check the 700-record cap outside `newSprite`, so `refusedSpawns` does not count them (older code; open
  carry). (f) Declined: leg 1's F5 (an unreachable boundary).

#### 6A-W2 — ⚑ MAJOR ◈ — the Warrior's Hit and Kill, the three pieces, the fight (→ 650)
- **Files:** `Sources/FerazelCore/World/Enemies/Warrior.swift` (Hit, Kill), `Sources/FerazelCore/Session/FerazelSession.swift`
  (the `.warrior` hit arm — today's empty stand-in), `Sources/FerazelCore/World/Enemies/EnemyCommon.swift` (`:98–:107`:
  the `.warrior` `killProc` arm gains `.KillWarrior`'s tail), `Sources/FerazelCore/Player/HitPlayerSprite.swift` (`:67`,
  the step-7 row exists — a test row only), `Sources/FerazelCore/Items/Smite.swift` (`:18`, exists — a test row),
  `Tests/FerazelCoreTests/Enemies/WarriorTests.swift`, `Tests/FerazelRenderTests/BossKillLevelRunTests.swift` (new),
  `Tests/FerazelRenderTests/BootFacesTests.swift` and `Tests/FerazelCoreTests/LevelFiveTests.swift` (◈, if a crush
  inside the pinned frames moves them).
- **Contract:** BOS §2.4 (Hit), §2.5 (Kill), §2.6 (pieces and duties), §2.10 (the scripted kill), §1.1 (the boss-kill
  tail, the death entry, the burn's Kill-frame formula). Dump: `.HitWarriorSprite` M l. 73422–73462, `.KillWarrior`
  73465–73495, the routing list M l. 49514–49521, damage row 49840–49842.
  - Hit: a player shot (`+0xa6 == 0`, HP > 0) is killed (sound 0, effect 1) with snd 303 — immune; a Statue or Box
    landing (`.PlatformBounce` == 2 ∧ (vy > 0 ∨ `+0xce`)) → `.HurtSprite(S, 200, …)`, `+0xf0 = 0`, `.KillBox`, then
    R(10000), R(10000), R(2) (`.KillBox`'s own draws first) — 2000 / 200 = 10 crate hits. A Statue-spell shot is an
    ordinary shot (no boss calls `.TurnIntoStatue`).
  - Kill: the count head, `+0xe9 = 1`, `+0xea = 1`; with p4 ≠ 0 snd 453 at 48000, shake 0x1e, flash 3, `noBossAlive
    = 1` → the gate opens from the next gate Handle, track 30 by the loop rule (LV5, built). **Closes the Phase 5 carry
    "the Warrior's killProc arm would count and remove the Warrior without opening the gate".**
  - Liquids: the `.dillo` row (kind 2: −100, invul 0x13, flash 0x11, snd 701 vol 0x55; kind 3: + 4 below HP 500).
  - The scripted kill (BOS §2.10): seed 1; `.left` held from the level start until the lock (x < 1384), then no keys
    but a one-frame `.jump` whenever a 0x71f shot is within 0x40 px; until the Kill or 20,000 frames. Measured once:
    HP0 (the death-entry frame, one after the tenth crush) and the Kill frame; Kill − HP0 = 45 + (B − T) of face 0x71e[5]
    (1 row a frame; one R(100) a row at effects 1) is checked, then both are pinned.
  - ◈ **Cause: the real Hit** (a crate landing on him inside the pinned frames). Switch-off: stub the Hit back to the
    empty arm — the old values return.
- **Tests (8)** (level 5 directly — built; the two Render tests through `LevelRun` as `GoblinBurnLevelRunTests` does; no fixture): BOS §2.9's 6A-W2 list: `testWarriorAbsorbsShots` · `testWarriorCrateCrush200` ·
  `testWarriorStatueShotIsAShot` · `testWarriorLavaAndBrine` · `testWarriorKillTail` (also: with the music preference
  off the loop rule never switches to 30 — the Phase 5 carry "no test with music off") · `testWarriorContactAndWriteBack`
  — in `WarriorTests`; `testWarriorKillFrameFormula` · `testWarriorScriptedKill` — in `BossKillLevelRunTests` (the burn
  needs face pixels). Asserts: BOS §2.11 items 22–28.
- **Gate:** Gate-B (G2 650; the bot's quick mode on level 5 — the fight now ends; the visit sweep on level 5 alone,
  `FERAZEL_VISIT_LEVELS=5 tools/ferazel-visit-sweep.sh core`, 128 visits, exit 0 — W1 / W2 change level 5 more than any
  task since LV5, and the next full sweep is 6A-L10L11's). Wave 6A.1 end: G3, GWB by day
  **647 / 0 / 3 / 0 (of 650)**, GW4R by day, the Fable cross-check of BL…W2. **Commit:** `FerazelCore: the Warrior's Hit and
  Kill — crates crush him, the gate opens, the boss track; the scripted fight; 8 tests`.
- **As executed — 6A-W2 (run 52):** task bcc67f2 (8 tests: 6 in `WarriorTests`, 2 in the new
  `BossKillLevelRunTests`), review fix round 38ce1d9 (asserts, test tidying and wording; Sources comments only). Two
  Opus legs: MERGEABLE (0 / 0 / 8 minor — Hit and Kill match the dump line by line), MERGEABLE AFTER FIXES (0 / 1 / 10
  minor; 84 mutations: 68 killed, 6 equivalent, 10 survivors — all 10 killed after the fix round, with two more
  mutants the fix round added). No disagreement between dump, BOS and card except the scripted kill, below.
  **The scripted kill — the contract's starting script cannot win; replaced by the seat's ruling (D49.1).** With BOS
  §2.10's script (hold left to the lock, then stand and jump the shots) the three crates come to rest on the
  background ledges above his patrol line and never fall on him: his HP stays 2000 and the player dies (~frame 1369).
  The fight is won as the data intends: a 0x433 crate is pushable (the Box Setup's push mass 0x8c, M l. 59068);
  Ferazel climbs from the blinking platform (x 1274) onto the right-hand ledge (x 1184–1247) and pushes the crate over
  the edge as the Warrior walks beneath; a new crate drops 14 frames after each crush. `WarriorFightScript` (in the
  test file) does that with **keys only**, deciding from positions a player can see, seed 1, level 5 through the level
  runner from the level start, cap 20,000 frames. **Measured and pinned (game-loop frames):** crushes at 350, 842,
  1962, 2391, 2546, 2759, 3834, 4164, 4584, 4965; **HP 0 (the death entry) 4966; Kill 5051**; Kill − HP0 = 85 = 45 +
  (B 151 − T 111) of face 0x71e[5]. Leg 1 re-ran the fight and checked that the script writes nothing.
  ◈ **No value moved** (level 5's pins hold: init 46, f30 58, f120 58), so no switch-off check was needed.
  Gate-B: the bot's quick mode on level 5 — `== core: random play — levels 1, seeds 4, steps 7200, deaths 1, exits 17,
  conversations 0, saves 0, failures 0 in 168 s`; the level-5 visit sweep — `== core: 128 visits in 39 s (build
  included); a teleport fired in 0, arrived in 0; a level exit taken in 8, reached the world map in 8; rows 0`, exit 0;
  G5, GW1 0 / 2, GW3 0 / 1, GW4 green; GW2 not run (nothing Windows or Shared touched).
  Closed Phase 5 carries: the Warrior's kill arm now opens the gate (tested through the level runner); the boss music
  has a test with music off. Closed W1's accepted gap: `testWarriorLavaAndBrine` kills "liquids call removed" and
  "class swapped" (a swap to `.blob` is equivalent — its rows equal the Dillo's).
  Notes: (a) a real Statue (a petrified Walker) landing on him crushes for 200 with no crate-break draws — asserted.
  (b) The burn's one R(100) a row is counted by replaying the burn on the run's own world after the Kill (the run
  mixes other sprites' draws in). (c) The session's hit row handing the face bounds to the Hit is pinned through one
  real session step with custom bounds — the same pattern fits every other enemy's row (open carry: none of them has
  it). (d) Wording only, outside the card's Files by the seat's ruling: `BossArena.swift`, `Camera.swift`,
  `ScreenFlash.swift`, `LevelFlow.swift`, `BuiltLevels.swift`. (e) **For 6A-CH2:** BOS §3.9's starting script for the
  Chief is likewise unproven — the build task first finds from the data how that fight is won.

#### 6A-FX — minor — the level fixture (→ 652)
- **Files:** `Tests/FerazelCoreTests/LevelFixture.swift` (new), `Tests/FerazelRenderTests/LevelFixture.swift` (new, a git
  symlink to the Core file, at the same folder depth), `Tests/FerazelRenderTests/LevelFixtureServices.swift` (new),
  `Tests/FerazelCoreTests/LevelFixtureTests.swift` (new), `Tests/FerazelRenderTests/LevelFixtureRenderTests.swift` (new).
  No `Sources` file and no `Package.swift` change: `LevelRun.init` (`Front/LevelRun.swift:247`) already takes `prefs:`,
  `seed:`, `carry:`, `services:` and `start:`; if the fixture needs anything it does not take, STOP for the seat.
- **Contract:** "Verification-model additions" (the fixture, stated there once), ENG §7.2, D46.3.
  1. **The in-package symlink, first, before any other code:** the Core file with a one-line body, the Render link
     (`git ls-files -s` shows mode `120000`), then `swift build --build-tests` in `Ferazel/Core` — both test targets
     compile it, once each, with no duplicate-source error or warning — and a `git archive` copy of the tree keeps the
     link (the seat's G2 copy; Proof B's `rsync -a` copy). **STOP and report if SwiftPM refuses it** (an error, a
     duplicate-source warning, or the Render target not seeing the type). The fallback, for the seat's ruling: the
     cross-check found no simpler design inside "no new target, no `Package.swift` change, never in `Sources`", so each
     fallback gives one of those up — (a) the fixture file in `FerazelRenderTests` only, and every fixture test this
     plan puts in `FerazelCoreTests` moves to `FerazelRenderTests` with the headless services (ladder unchanged; the
     rules half of G2 loses them), or (b) a test-support target both test targets depend on (a `Package.swift` change,
     against "Shared architecture"). Never two copies of the file, never in `Sources`.
  2. The fixture as stated: `resources(level:leaveOut:header:)`, `open(level:leaveOut:header:start:prefs:carry:services:seed:)`,
     the literal leave-out list with its count asserted, the header patches, the headless services and
     `LevelFixtureServices`.
  3. Proved on **level 21**: its header switches no strip and no OmniPx mode, and it opens at this point once its 30
     refused records are left out (LL §4 "Level 21"), by type: the faces and talkers 1061 ×14, 2921 ×2, 2962 ×1; the
     pipes 1490, 1491 ×3, 1492, 1493; the Box scenery 2827, 2831 ×2, 2833, 2834, 2836, 2850 — 30 asserted. If level 21
     does not open here (a refusal or a throw LL does not list), STOP. Later tasks build those types but never edit
     this list (the literal-list rule), so no later 6A task moves what these tests pin.
- **Tests (2):** `testLevelFixtureOpensLevel21Headless` (Core, `LevelFixtureTests`, headless: the patched `Mlvl`
  differs from the file only in the 30 listed records' active flag, and with a one-byte `header:` patch only in that
  byte; the stream and every other byte identical; the data file on disk unchanged; the level opens through `LevelRun`,
  every active record set up — no `notTranscribed`; `start:` nil → the header's start, a given point → the player
  there; `prefs:` and `carry:` reach `LevelRun` as passed) · `testLevelFixtureOpensLevel21WithFaces` (Render,
  `LevelFixtureRenderTests`, through `LevelFixtureServices`: the renderer holds faces for the active placements only —
  none for a left-out one; the first presented frame draws with no refusal; two openings with one seed give the same
  frame FNV, pinned — a fixture golden under the "New goldens" rule).
- **Gate:** Gate-F (G2 652; both test targets build with the link, GW1 0 / 2 cross-builds it; G6 — test files only).
  **Commit:** `Ferazel tests: the level fixture (one file linked into both test targets), proven on level 21; 2 tests`.

#### 6A-S8 — ⚑ MAJOR — the horizon strip (draw mode 8) (→ 663)
- **Files:** `Sources/FerazelCore/Sprites/PxSprites.swift` (built R4, unused — becomes the real records; the strip
  creation as **one routine that takes a level header** and the Backgrounds file and returns the strip sprites),
  `Sources/FerazelCore/Front/LevelRun.swift` (`setupLevel` calls that routine at `.SetupLevel`'s position, after
  `.KillAllSprites` and before `.SetupLevelSprites`, on the long path and on the restart fast path; `refuseUndrawnHeader`
  `:584` — the strip's refusal removed, the OmniPx one kept), `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift`
  (the Handle in the sprite pass; the allocations), `Sources/FerazelCore/Camera/Camera.swift` (the second
  `.MTHandlePxSprites` pass at the end of `.FindUpperLeftCorner`, M l. 6235), `Sources/FerazelCore/Seams/FaceRef.swift`
  (one `FaceSetKind` case for a Backgrounds-file single — Invariant 9, a case added), `Sources/FerazelRender/Frame/SpriteBlitter.swift`
  (mode 8, both variants; `:301`), `Sources/FerazelRender/Frame/FrameRenderer.swift` (the strip face loaded from the
  Backgrounds file under the colour table the Contract names), `Tests/FerazelCoreTests/HorizonStripSetupTests.swift`
  (new), `Tests/FerazelRenderTests/FeatureGoldenTests.swift` (new), `Tests/FerazelRenderTests/HorizonStripTests.swift`
  (new), `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (the `horizonStrip` `.headerZero` row gone, mode 8 drawn,
  the header check at `:1949` narrowed), `Tests/FerazelCoreTests/GameFlowGameTests.swift` (PT's strip patch at
  `:293–:306` now opens — retargeted; the OmniPx patch stays a refusal), the level fixture (6A-FX's
  `Tests/FerazelCoreTests/LevelFixture.swift` and `Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift`
  — used, not changed). Any exhaustive `switch` over `FaceSetKind` the compiler finds (both packages) is added and
  recorded.
- **Contract:** ENG §2.1 (creation, `.SetupPxSprite`, the twice-a-frame Handle, the mode-8 add with carries, the clipped
  walk from the raw, the mask pass). Dump: `.SetupLevel` M l. 2252–2268 / 2350–2356, `.MTAddPxSprite` 30853–30927,
  `.SetupPxSprite` 30798–30819, `.HandlePxSprite` 30771–30797, `.MTHandlePxSprites` 30928–30948,
  `.BlitEncFaceBehindTilesClip` 22251–22449 (raw `100269c4..10026d04`), `…NoClip` 22450–22548.
  - Six levels (10, 30, 40, 45, 62, 67; LL §10.5): built once here; 30 … 67 only need their goldens later.
  - **The colour table each strip face converts under** (re-read for this round; ENG §2.1 gives only the `0x26cc`
    case). `.MTAddPxSprite` loads the face under whatever `*_DAT_1009ff94` holds, swapping in `*_DAT_1009ff8c` (the
    level+base CLUT) only when hdr `0x26cc` ≠ 0 and restoring it after a successful load (M l. 30884–30886, 30919).
    On the long path `.SetupLevel` sets `*_DAT_1009ff94 = *_DAT_100a0020` (M l. 2273, through `piVar9 = _DAT_1009ff94`,
    M l. 2235), and `_DAT_100a0020` is `GetCTable(200)` (`.InitAppGlobals`, M l. 404–405, `piVar4 = _DAT_100a0020`);
    between M l. 2273 and the add at M l. 2353 the routine calls only `_CheckFlags`, `_MTKillPxSprites` and the
    open-failure report. So: **levels 10, 30, 40, 45 and 67 (`0x26cc` = 0) convert under clut 200; level 62
    (`0x26cc` = 1) under the level+base CLUT** (`*_DAT_1009ff8c`). On the restart fast path (M l. 2252–2268) the pointer
    is not reset: it holds what the last writer left. The writers traced: `.LoadLevelTilesets` saves and restores it
    (M l. 1576–1577, 1630), `.InitTiles` restores it to `*_DAT_100a0020` (M l. 889, 928), `.MTAddPxSprite` and
    `.InitMapFaces` restore their own swaps (M l. 30919; 66626–66639), and `.SetupOmniPx` writes `*_DAT_1009ff8c`
    without a restore (M l. 13184) but returns first when hdr `0x26c7` = 0 (M l. 13172) — 0 on all six strip levels —
    so the fast path also converts under clut 200 on 10 / 30 / 40 / 45 / 67 unless a writer reached during play changes
    it: the implementer greps every alias store to `_DAT_1009ff94` reached between a level's start and a restart,
    records them in As executed, and the restart assert below pins the result.
  - **The strip shifts every sprite-slot id on those six levels** (placement indices do not move): every later test that
    names a slot on them is measured after this task (ENG §7.3).
  - `0x271a` is read as the level has it (222 on 10) — `.BuildSineTable`'s clamp runs before any level loads.
  - Fixture: level 10 with 31 records left out, a literal list — the trees 3080, 3081, 3082, 3083 (13) and the Box
    scenery 2816, 2817, 2837, 2846, 2847, 2861 (14) by type; the rotating cannons 1097 (1) by type and the three refused
    1090 records (p1 101 / 103) by placement index, read once from the level file and written as literals — 31
    asserted.
  - Levels 30, 40, 45, 62 and 67 cannot open in 6A (their records are 6B's / 6C's types; 67 has the CLUT-animation
    header), so their strip tests run the creation routine on each level's **header** and open no level.
- **Tests (11):** ENG §2.1's list less the audit row (in `HorizonStripTests`, Render, unless named; level 10 on the
  fixture, the other five levels by header only): `testStripSpritesAreTheFirstAllocations` (Core,
  `HorizonStripSetupTests`, the fixture headless through `setupLevel` — the strip sprites are Core records, no pixels
  needed; assert: after a death's restart on the fast path (M l. 2252–2268) the strip is 9 sprites again in the same
  slots, its face loaded under the same table) · `testStripCopiesPerLevel` (the creation routine called on the headers
  of 10, 30, 40, 45, 62, 67: 9, 12, 12, 3, 9, 2 sprites — not the `PxSprites` model `ParallaxTests.testStripSpriteCopies`
  already pins; level 10's count also equals what `setupLevel` creates on the fixture) · `testHandlePxSpriteRunsTwice` ·
  `testStripFaceUsesBackgroundsFile` (assert: level 10's strip face is converted under clut 200, not the level+base
  CLUT `*_DAT_1009ff8c` — M l. 2273, 404–405) · `testStripFaceClutOnLevel62` (the level-62 strip face loaded from the Backgrounds file
  under the `0x26cc` CLUT, from the header alone) · `testModeEightWordAddCarries` · `testModeEightTailBytes` ·
  `testModeEightClipped` · `testModeEightMaskPassZeroes` · `testFrameIsZeroUnderOpenMaskOnLevel10` (on the fixture) ·
  `testLevel10StripFeatureGolden` (in `FeatureGoldenTests`; the first frame with a strip pixel on screen, measured;
  kept at 6A-L10L11; 6A-WD may move it, ◈ — "New goldens"). Asserts: ENG §2.1's seven.
- **Gate:** Gate-F (G2 663; the new `FaceSetKind` case compiles in both shells — G5, GW1–GW4; no shell source switches on
  it). **Commit:** `Ferazel: the horizon strip — draw mode 8, the strip sprites of six levels; 11 tests`.

#### 6A-WD — minor ◈ (one fixture golden) — wind cells (→ 672)
- **Files:** `Sources/FerazelCore/Physics/StandardSprite.swift` (`:60`, the empty `// later: wind` branch; the
  `+0x92` clear at the routine's top), `Sources/FerazelCore/Sprites/SpriteSlot.swift` (`:443`, the fields exist),
  `Tests/FerazelCoreTests/WindTests.swift` (new), `Tests/FerazelRenderTests/FeatureGoldenTests.swift` (its own two tests;
  and 6A-S8's `testLevel10StripFeatureGolden`, ◈, only if the wind reaches S8's frame),
  `Tests/FerazelRenderTests/HorizonStripTests.swift` (◈, only if the wind reaches the frame of S8's
  `testFrameIsZeroUnderOpenMaskOnLevel10`), the level fixture
  (`Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used, not changed).
- **Contract:** ENG §2.2. Dump: `.StandardSpriteHandles` M l. 32489–32574 (raw `100369b0..10036c5c`), `+0x92 = 0` at
  M l. 32460; `.LookupModedImpulse` 37020–37412 (built). Wind is on **levels 10 (103 cells) and 20 (2,899)** (LL §10.1);
  it moves every sprite with a wind scale, not only the player (ENG P6); the test impulse (15·o2), the gates — **crossed on
  h < 0, v < 0 directions, as written** (o1 10…15: 4 cells on 10, 36 on 20) — the push impulse (14·o2) scaled below
  0xff, the 33-frame ramp, `+0x98` un-ramped, the leaving arm. No random draw; no draw writer. Fixture: level 10 with the
  same literal 31-record list as 6A-S8's.
  - ◈ **Cause: wind is live in 6A-S8's level-10 fixture frame** (the fixture leaves no wind cell out; 103 cells) — if a
    wind-scaled sprite in the frame S8 pinned sits in a wind cell, S8's strip golden (and, if its frame moves, the
    open-mask frame) moves for that cause and no other: old → new in the commit body and As executed. Switch-off: stub
    the wind branch (`StandardSprite.swift:60`) with one local patch, never committed — S8's old values return. Levels
    1–5 have no wind cell (their goldens do not move); any other moved value is a STOP.
- **Tests (9):** in `WindTests` on synthetic cells: `testWindGatesEachQuadrant` · `testWindCrossedGatesOnDiagonalUpLeft`
  · `testWindRampUpAndOff` · `testWindScaleBelow255` · `testWindNeedsPositiveStrength` · `testWindSetsInWindFlag`;
  `testWindCellCensus` (the 24 levels' overlay cells read from the level files, no level opened: 103 / 2,899 / 0 on
  every other level); in `FeatureGoldenTests` on the fixture: `testLevel10WindTrace` (Render; kept for good — 6A-L10L11
  keeps it when it deletes the golden beside it) · `testLevel10WindFeatureGolden` (the trace's last frame; **deleted at
  6A-L10L11**). Asserts: ENG §2.2's four.
- **Gate:** Gate-F (G2 672). **Commit:** `FerazelCore: wind cells (levels 10 and 20), the crossed gates as written; 9 tests`.

#### 6A-RC — minor — the rotating cannon arm (p1 101…106) and its shot steering (→ 682)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:377–:380`, the p1 ≠ 0 refusal),
  `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (`:334` the Handle stub, `:498` the steering `// later`),
  `Tests/FerazelCoreTests/RotatingCannonTests.swift` (new), `Tests/FerazelRenderTests/FeatureGoldenTests.swift`,
  `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (the cannon face writer rows near `BackgroundSprite.swift:355/:364`
  re-keyed), `Tests/FerazelCoreTests/CachedFacesTests.swift` (level 20's count re-derived if the 1092 setting up moves
  it — 6A-CF), the level fixture (`Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used).
- **Contract:** ENG §2.3. Dump: Setup arm M l. 62057–62184 (p1 ≥ 1: 62120–62170), Handle 62944–63069 (rotation
  62983–63021), `.HitBackgroundSprite` 63680–63714 (steering 63689–63709). Owns 1092, 1097 and the p1 101–106 records of
  1090 on 10 / 15 (level 20's rotating cannon is the 1092, p1 103 — ENG §2.3's census) (D46.1; LL's 6A-BG1b dissolves); 1091 / 1093–1096 with p1 0 are built (their first refused
  records are 6B's, LL finding 10); the path arm p1 < 0 is 6B (ENG §3.1). Record p2 written back (105, or 106 with
  p2 0 → 4); the pause and step; the click only with no voice playing (`SoundVoices`); 105 / 106 never turn by
  themselves; a player shot steers a paused 105 / 106 by the 12 / 24 and 8 / 23 windows; a shot into a 101–104 cannon is
  cannoned. The set mark 0x442 is 6A-CF's. Every cannon on levels 1–5 has p1 0 (measured) — no golden moves. Fixture:
  level 10 with a literal 27-record list — 6A-S8's trees 3080–3083 (13) and Box scenery (14), by type — 27 asserted.
- **Tests (10):** ENG §2.3's list — in `RotatingCannonTests` on synthetic cannons (records per record through
  `SetupFaces.setup` where a field comes from the data): `testRotatingCannonSetupFields` · `testCannon105WritesRecordP2` ·
  `testRotatingCannonPauseAndStep` · `testRotatingCannonClickNeedsSilentVoice` · `testCannon105DoesNotSelfTurn` ·
  `testShotSteersCannonLeftAndRight` · `testShotSteeringOnlyWhilePaused` · `testCannonP1OutsideRangeTakesPath`; in
  `FeatureGoldenTests` on the fixture: `testLevel10CannonTrace` (Render; kept — 6A-L10L11 keeps it when it deletes the
  golden beside it) · `testLevel10RotatingCannonFeatureGolden` (**deleted at 6A-L10L11**). Asserts: ENG §2.3's seven.
- **Gate:** Gate-F (G2 682). **Commit:** `FerazelCore: rotating cannons (p1 101…106) and shot steering; 10 tests`.

#### 6A-TR — minor — trees and their branches (→ 693)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:430`, the Background `default` for 0xc08…0xc0f),
  `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (`:10`; the Handle arm; `faceWidth` at `:144`),
  `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the branch arms for Box 0xc08 / 0xc09),
  `Sources/FerazelCore/World/Movers/PlatformSprite.swift` (`:402–:409` — `flipH`, the existing `.FlipHRect` port: made
  callable from both movers, never a second copy), `Sources/FerazelCore/Front/LevelRun.swift` (`CachedFaces` marks of
  `_DAT_100a0ae0` on CF's list), `Tests/FerazelCoreTests/TreeTests.swift` (new),
  `Tests/FerazelRenderTests/FeatureGoldenTests.swift`, `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (the tree's
  mirror at Setup and every Handle, its face store, layer 30000 / −10), the level fixture
  (`Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used).
- **Contract:** ENG §2.4. Dump: Setup arm M l. 62597–62617, `.SetupTree` 62679–62886, Handle 63538–63546, branch Box arms
  60941–60947 (0xc08) / 61067–61075 (0xc09), `.SetupBoxSprite` head 58934–58947 and tail 59722–59727, `.FlipHRect`
  39474–39491. Owns 3080–3087 and the spawned branches (D46.1). The first Handle plants the branches (3 / 4 / 4 / 5 / 0 /
  1 by tree; 0xc0b's fifth overwrites slot `1d4`, as written), mirrored by the face width, at **layer 2** (the Box Setup's
  head overwrites 0xb), first handled next frame; 0xc0f's one solid branch (type 0xc09, `+0x185 = 0`; unplaced).
  ENG says "build the shared `flipHRect`": it exists as `PlatformSprite.flipH` (Planner's note 6). Fixture: level 10
  with the Box scenery 2816, 2817, 2837, 2846, 2847, 2861 left out by type — 14 asserted.
- **Tests (11)** (in `TreeTests` on synthetic trees and per-record setups, the golden in `FeatureGoldenTests` on the
  fixture, the data pin from the 24 level files): ENG §2.4's ten: `testTreeSetupFields` · `testTreePlantsBranchesOnFirstHandle` ·
  `testTreeFifthBranchOverwritesFirstSlot` · `testTreeBranchesMirror` · `testBranchBoxArm` · `testBranchLayerIsTwo` ·
  `testBranchFirstHandleNextFrame` · `testTreeNoFreeRecordDropsStores` · `testTreeCacheMarks` ·
  `testLevel10TreeFeatureGolden` (kept); plus ENG §5's pin `testUnplacedBackgroundArms` (Background 0x73f / 0x740 and
  their `.HitPlayerSprite` arm, M l. 49753–49760, placed on no level). Asserts: ENG §2.4's ten.
- **Gate:** Gate-F (G2 693). **Commit:** `FerazelCore: trees plant their branches (one FlipHRect); 11 tests`.

#### 6A-RP — ⚑ MAJOR — the river ripple (and the submerged-tint proof) (→ 703)
- **Files:** `Sources/FerazelRender/Frame/ParallaxBlitter.swift` (`:130` `Refusal.ripple` removed; `rippleTable` `:107`,
  `:370` — the consumer is built), `Sources/FerazelRender/Frame/FrameRenderer.swift` (the table filled at
  `.PaintFrameWrap`'s position: the add on every call, the formula on drawn frames, before the copy),
  `Tests/FerazelRenderTests/RippleTests.swift` (new), `Tests/FerazelRenderTests/FeatureGoldenTests.swift`,
  `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (the `Refusal.ripple` row gone; `:1340`), the level fixture
  (`Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used).
- **Contract:** ENG §2.5 (the ripple) and §2.6 (T11, prove only — LL §10.2). Dump: `.PaintFrameWrap` M l. 9211–9226
  (every call) and 9255–9425 (drawn frames; raw `10011fe0..100126c8`), the 55-entry table `.BuildSineTable` 17389–17397.
  **`.RipplePxBackOffsets` is not this feature** (gated on hdr `0x271e`, 0 on all 24 levels — ENG §5, P7). The 55-entry
  f32 sine table; rows 0x200…0x27f and 0x280…0x47f by their formulas, b growing by 2 a frame (the drift), `fctiwz`
  saturating; ffbc added on every call (a no-op as shipped, pinned 0). Render only, no seam type. T11: the dump's seven
  submerged-tint readers (M l. 8825, 9618, 9635, 9728, 9957, 9982, 27043) are built at five port sites —
  `Sources/FerazelRender/Frame/TileGridRenderer.swift:257` (and the blend op's water table, `:265`),
  `Sources/FerazelRender/Frame/LightRenderer.swift:447, :490`, `Sources/FerazelCore/Particles/WaterEffects.swift:246`
  (its env built at `:201`) (ENG §2.6); the task proves them against the dump, no golden of its own.
  Fixture: level 11 with 27 records left out by type — the Box scenery 2816, 2817, 2831, 2837, 2857, 2872, 2873, 2875,
  2876 (26) and the Nimbo NPC 2955 (1) — 27 asserted; the switch-off test adds the fixture's `header:` patch.
- **Tests (10)** (in `RippleTests`, Render; the table and row tests synthetic, the golden and the switch-off on the
  fixture, the data pin from the 24 headers): ENG §2.5's seven: `testRippleSineTable55` · `testRippleRowsShallow` ·
  `testRippleRowsDeep` · `testRippleDriftsTwoPerFrame` · `testRippleAddIsNoOp` · `testRippleOnlyOnDrawnFrames` ·
  `testLevel11RippleFeatureGolden` (the first frame showing a PxBack row ≥ 512, measured; kept); ENG §2.6's two:
  `testSubmergedTintSitesMatchDump` (a synthetic water cell under each of the seven dump readers: with `0x26c6` = 0 the
  plain draw, with 1 the water-table draw, at the port site the Contract names) · `testLevel11SubmergedSwitchOff` (the
  fixture's `header:` patch forcing `0x26c6` (`submergedFaces`) to 0 changes the feature golden; levels 1–5's unchanged); ENG §5's pin `testNoLevelSetsParallaxMode` (hdr
  `0x271e` = 0 on all 24 levels).
  Asserts: ENG §2.5's three.
- **Gate:** Gate-F (G2 703). **Commit:** `FerazelRender: the river ripple of levels 11 and 18; the submerged tint
  proven; 10 tests`.

#### 6A-BX1a — minor — Box scenery: decorations, outcrops, mushrooms, the graves' mirrored hot rect (→ 709)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift` (the Setup-face table rows; `:493` decorations and the
  outcrop / mushroom arms; the face check `:715`), `Sources/FerazelCore/World/Movers/BoxSprite.swift` (`:385–:388`,
  the `.FlipHRect(+0x34, face +6)` `// later`), `Sources/FerazelCore/Front/LevelRun.swift` (the singles' marks on CF's
  list), `Tests/FerazelCoreTests/BoxSceneryTests.swift` (new), `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (the
  water-kinds check widened to all 24 levels — ENG §5), the level fixture (`Tests/FerazelCoreTests/LevelFixture.swift`
  — used).
- **Contract:** LL §8(a) (6A-BX1a), §1 finding 6; ENG §5. Dump: `.SetupBoxSprite` M l. 58892–59730 (decorations from
  M l. 59641; the hot rect 59650–59667; the flip 59670–59673). The 19 types 2808, 2816, 2817, 2827, 2831, 2833, 2834, 2836,
  2837, 2846, 2847, 2850, 2852, 2857, 2861, 2872, 2873, 2875, 2876: faces into the table, singles marked (outcrops
  flag 1); **the level-21 graves 2833 / 2834 / 2836 (p1 260, 261, 1) have non-empty hot rects and need the flip**
  (`PlatformSprite.flipH`, made shared by 6A-TR); 2833 / 2834 (p1 > 100) open Mcnv 260 / 261 through the built talk arm
  (`HitPlayerSprite.swift:332`); 2836 (p1 1 ≤ 100) opens none, but its contact still sets the 90-frame cooldown 0x5a
  and writes the record's p4 = 1 (M l. 49286–49287; `HitPlayerSprite.swift:336–339`). Every decoration on levels 1–5 has the empty rect (the flip leaves it empty)
  — no golden moves. Also ENG §5's unplaced Box pins.
- **Tests (6)** (in `BoxSceneryTests`, Core): `testBoxSceneryFacesSetUp` (every record of the 19 types on 10–22 sets
  up, per record through `SetupFaces.setup` — levels 15, 20, 21 and 22 still hold other refused records, so no level is
  opened; the face per type) · `testBoxSceneryCacheMarks` (the singles at LL §6's positions; outcrops flag 1) ·
  `testGraveHotRectFlip` (2833 / 2834 / 2836 mirrored by the face width; contact on the mirrored side) ·
  `testGraveTalkersOpenConversations` (260 / 261 on contact; 2836: no conversation, cooldown 0x5a, record p4 = 1) —
  these two on the fixture: level 21 with the 23 records later tasks build left out by type (BX1b's 1061, 2921, 2962 —
  17; the pipes 1490–1493 — 6), 23 asserted; `testRopeBridgeUnplaced` (1466 on no
  level, spawned by nothing — ENG §5) · `testTableUnplaced` (0xb71 on no level — ENG §5) — from the 24 level files.
- **Gate:** Gate-F (G2 709). **Commit:** `FerazelCore: Box scenery of levels 10–22 and the graves' mirrored hot rect;
  6 tests`.

#### 6A-BX1b — minor — Box faces and talkers: teleporters, furniture, NPCs (→ 713)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:512` — no face arm for 1060 / 1061; `:505` furniture,
  `:507` NPCs; the table rows), `Sources/FerazelCore/Front/LevelRun.swift` (marks on CF's list),
  `Tests/FerazelCoreTests/BoxTalkerTests.swift` (new), `Tests/FerazelCoreTests/CachedFacesTests.swift` (level 22's
  count re-derived for the 1060 / 2956 marks — 6A-CF).
- **Contract:** LL §8(a) (6A-BX1b). Dump: `.SetupBoxSprite` M l. 58892–59730 (furniture M l. 59603; NPCs) and
  `.InitBoxSprite` (header M l. 58697: the teleporter faces from the boot singles 0x424 / 0x425, M l. 58737–58740).
  Types 1060, 1061 (the `BoxSprite.setup` arm and the teleport are built, TP), 2921, 2955, 2956, 2962; the NPCs open
  Mcnv 206 (2955, level 11), 220 (2956 rec 283 flag 99 on level 11 — dormant), 221 (2956, level 22), 300 (2962, level
  21) through the built NPC arm (`HitPlayerSprite.npc`, `HitPlayerSprite.swift:316`; the `talk` arm at `:332` is the
  signs' and graves').
- **Tests (4)** (in `BoxTalkerTests`, Core, per record through `SetupFaces.setup` and on synthetic contacts — levels 21
  and 22 still hold refused records, so no level is opened): `testTeleporterFacesFromBootSingles` (1060 / 1061 face
  0x424 / 0x425; every 1060 / 1061 record on 21 / 22 sets up)
  · `testFurnitureAndNpcFacesSetUp` (2921, 2955, 2956, 2962: face rows, marks) · `testNpcConversationIds` (2955 → 206,
  2956 → 220 / 221 by record, 2962 → 300; the flag-99 record does not talk) · `testTeleporterSheetsSpawnable`
  (`FaceTests.testEverySpawnableTypeHasSheet`'s rule holds for the new types).
- **Gate:** Gate-F (G2 713). **Commit:** `FerazelCore: teleporter faces, furniture and NPCs of levels 10–22; 4 tests`.

#### 6A-MC — minor — conversations and chapter cards of levels 10–22 (prove) (→ 716)
- **Files:** `Sources/FerazelCore/Talk/{ConvActions,ConversationRun}.swift` and `Sources/FerazelCore/Front/StageScreens.swift`
  (only if a check fails — the interpreter and `ChapterScreenRun` are built), `Tests/FerazelCoreTests/LaterConversationTests.swift`
  (new), `Tests/FerazelRenderTests/ScreenTests.swift` (the two card goldens).
- **Contract:** LL §5 (every opcode of levels 10–22 handled: conditions [4, 5], actions [1, 2, 4, 5, 9, 10]), LL §4
  items 3–4. Dump: `.ChapterScreen` M l. 5038–5089 (picture `chapter·10 + 0x11f8`, clut `chapter + 0x118`). The six
  `Mcnv` of 10–22 (206, 220, 221, 260, 261, 300) run to their end through `ConversationRun` with their portraits (4001,
  4013, 4014, 4022, 4024) loaded; chapter card 2 (level 10: PICT 4620, clut 282) and card 5 (level 22: PICT 4650,
  clut 285) draw. Render through the shared `ScreenRenderer`: lockstep (b), no WinKit test (Planner's note 4).
- **Tests (3)** (the conversations and cards run standalone from the data files; no level opened):
  `testLevels10To22ConversationsRunToEnd` · `testChapterCard2FrameGolden` · `testChapterCard5FrameGolden`.
- **Gate:** Gate-F (G2 716). **Commit:** `Ferazel: the conversations and chapter cards of levels 10–22 proven; 3 tests`.

#### 6A-L10L11 — ⚑ MAJOR — levels 10 "Unemployed In Greenland" and 11 "River of Fears" enterable (→ 722)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (`[1, 2, 3, 4, 5, 10, 11]`), `Sources/FerazelCore/Front/LevelRun.swift`
  (whatever the two censuses still need — none expected), `Tests/FerazelCoreTests/LevelTenTests.swift` (new),
  `Tests/FerazelCoreTests/LevelElevenTests.swift` (new), `Tests/FerazelRenderTests/LevelFrameGoldenTests.swift` (new),
  `Tests/FerazelRenderTests/FeatureGoldenTests.swift` (the wind and rotating-cannon feature goldens deleted; the two
  traces beside them kept), `Ferazel/Windows/Tests/FerazelWinKitTests/WinLevelReferenceTests.swift` (new),
  `Ferazel/Windows/Tests/FerazelWinKitTests/FerazelSettingsTests.swift` (the `("10", 1)` row from 6A-BL becomes
  `("10", 10)`; `("11", 11)` added), and the tests pinned to the list, each retargeted with every value re-derived:
  `Tests/FerazelCoreTests/LevelFiveTests.swift` (`testBuiltLevelsFive`: level 5's exit p1 1 → node 10 now **enters**
  level 10), `Tests/FerazelCoreTests/GameFlowGameTests.swift` (the not-built walk moves to the first unbuilt node reached
  from 10 / 11's exits, measured), `Tests/FerazelRenderTests/{BootFacesTests,FaceTests}.swift` (levels 10, 11 pins and
  table rows), `Tests/FerazelCoreTests/BuiltLevelsTests.swift`.
- **Contract:** LL §4 "Level 10", "Level 11" (switches, types, resources, marks), LL §7 deps, ENG §7.2. Dump:
  `.SetupLevelSprites` M l. 1940–2103, `.SetupLevel` 2189–2590, `.ChapterScreen` 5038–5089.
  - Level 10: 312 records (31 refused today: trees, rotating cannons, Box scenery — all built by now); the strip's 9
    sprites first; 103 wind cells; `0x26c9` = 1 (the water-surface effect, built); music 4; chapter card 2 on entry
    (measured: whether `-FerazelLevel 10` shows it). Level 11: 397 records (35 refused: trees 8, Box scenery 26, Nimbo
    1); the ripple; the submerged tint; `0x270c` −30, `0x270e` 150, `0x2710` 80, `0x2714` −512, start facing left,
    music 6; Mcnv 206 on contact, 220 dormant.
  - First placements now real: the 800-point goblin 1750, the swarm 1869, the bat 1851, the geyser 1440 on 10, the
    rope 3020, the platform 1407.
  - **The Phase 5 carry "parent / child sprite links across idling for the classes first placed after level 5"**: read
    for the swarm 1869 (its members, record 0x200, never idled, keep running while the parent idles — Hazards
    "Idle children") and the bat 1851 on these two levels; `testLevels10And11IdleChildLinks` pins it: with the parent
    idled (the player moved out of its margins), the members' count, their `+0x1d4` links to the parent and their
    positions after a measured number of idle frames, and the members still moving; the bat's state across its own
    idling.
  - **Parameter trace** ("Every level task"): the built types of LL §4 item 2 on 10 and 11 — the cannons 1091,
    1092, 1093–1096 (p1 0), the Bonus 1330 and 3217, the platform 1407, the geyser 1440, the Walker 1750, the bats 1851
    and 1869, the rope 3020 (its geometry), the Backgrounds 1840 / 1843 — and every type built on 1–5 whose p1…p4 here
    the script finds new (crate and chest contents, item and scroll ids, path forms, exits).
- **Tests (+8 / −2):** `testLevel10SetsUpEveryRecord` · `testLevel11SetsUpEveryRecord` (each: the record count, no
  `notTranscribed`, the switch values, the music cue) · `testLevels10And11CacheMarks` (LL §4 item 6's records, the
  bar's step count) · `testLevel10FirstFrameGolden` · `testLevel11FirstFrameGolden` (new values, measured) ·
  `testBuiltLevelsTenEleven` (the list; level 5's exit → level 10; `startLevel` 10 / 11 accepted; assert: a save made
  on level 10 continues there through `ContinueGame`) ·
  `testLevels10And11IdleChildLinks` · `testLevel11NimboConversationOnContact`; deleted:
  `testLevel10WindFeatureGolden`, `testLevel10RotatingCannonFeatureGolden` (ENG §2.2, §2.3: the traces and the real
  golden cover them). WinKit (+2): `testLevel10FirstFrameReference` · `testLevel11FirstFrameReference` (each the first
  presented level frame; when that frame shows no strip pixel (10) or no ripple row (11), the same test also holds the
  level to the first frame that does — measured — and pins it, so the shell path draws both features in 6A).
- **Gate:** Gate-L (G2 722, GW2 84; the seat records the G2 render half's time here beside the bot's `W`). Wave 6A.2
  end: G3, GWB by day **719 / 0 / 3 / 0 (of 722)**, GW4R by day, the Fable cross-check of FX…L10L11 (in this run, 56;
  it opens run 57 if the context is spent). **Commit:** `Levels 10 and 11 enterable: the strip,
  wind, cannons, trees, the river; BuiltLevels [1…5, 10, 11]; 8 tests (2 feature goldens retired), 2 Windows references`.

#### 6A-BG1c — minor — plants (→ 725)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:401` the arm, built; the Setup-face table rows; `:715`),
  `Sources/FerazelCore/Front/LevelRun.swift` (singles #161–#172 marked on CF's list), `Tests/FerazelCoreTests/PlantTests.swift`
  (new).
- **Contract:** LL §8(a) (6A-BG1c). Dump: `.SetupBackgroundSprite` M l. 61919–62678 (plants M l. 62629–62668),
  `.HandleBackgroundSprite` 62887–63563. Types 2700, 2701, 2702, 2705, 2711 (levels 15, 18; 25 later): faces into the
  table, flag-1 singles marked. **Before 6A-RN** (fix-round ruling): with the plants built, level 15 opens with nothing
  left out but its rain, so RN's Core and Render tests share one fixture.
- **Tests (3)** (in `PlantTests`, Core, per record through `SetupFaces.setup` — level 18 still holds the Chief, so no
  level is opened): `testPlantFacesSetUp` · `testPlantCacheMarksFlagOne` · `testPlantsOnLevels15And18` (every plant
  record of 15 and 18 sets up).
- **Gate:** Gate-F (G2 725). **Commit:** `FerazelCore: the plants of levels 15 and 18; 3 tests`.

#### 6A-RN — ⚑ MAJOR — OmniPx rain (mode 1), thunder, the side push (→ 737)
- **Files:** `Sources/FerazelCore/World/OmniPx.swift` (mode 1 — 6000 / 6001 already loaded, `:96`, `:125`),
  `Sources/FerazelCore/Front/LevelRun.swift` (`:583` — mode 1 leaves the refusal; 3 / 6 / 7 / ≥ 8 stay; the first-call
  flag cleared after `.SetupOmniPx`; `AsyncGammaFade` `:536–:541`), `Sources/FerazelCore/Front/Pause.swift`
  (`painted` `:252`: the flag clear after the loop stop), `Sources/FerazelCore/Session/FerazelSession.swift` (`GenerateRain`
  at `.PaintFrameWrap`'s position, every call, drawn or not), `Sources/FerazelCore/Particles/{ParticlePool,ScreenFlash}.swift`
  (`.NewParticle` mode 1; the built flash), `Sources/FerazelCore/Seams/SoundCue.swift` (a loop field, default off —
  Invariant 9; shaped so 6B-AS can add a "set the volume of the voice playing snd N" cue), `Ferazel/Shared/FerazelAudio.swift`
  (`:152–:153`, the loop play), `Ferazel/App/FerazelController.swift` and `Ferazel/Windows/Sources/FerazelWinKit/WinAudioDriver.swift`
  (`:59`) only if the cue's path passes through them, `Ferazel/Windows/Tests/FerazelWinKitTests/FerazelAudioTests.swift`,
  `Sources/FerazelRender/Frame/{FrameRenderer,ParallaxBlitter}.swift` (mode 1's port update: faces only, no base cell),
  `Tests/FerazelCoreTests/RainTests.swift` (new), `Tests/FerazelRenderTests/{FeatureGoldenTests,OmniPxTests,DrawModeAuditTests}.swift`
  (`omniPxMode` row: 1 drawn; `:1464`), `Tests/FerazelCoreTests/GameFlowGameTests.swift` (PT's OmniPx patch → mode 3),
  the level fixture (`Tests/FerazelCoreTests/LevelFixture.swift` and
  `Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used).
- **Contract:** ENG §2.7 (re-read line by line). Dump: `.GenerateRain` M l. 8429–8531 (called 9228–9229, before the
  drawn-frame test), the first-call flag's writers 2541, 3203, 5300; the extra paints 3190, 3918, 3922, 3980, 4005;
  `.GammaFadeOutAsync` 31893–31915, `.HandleAsyncGammaFade` 31917–31945, `.GammaFadeInAsync` 31872–31891,
  `.STPlayLoopedSound` 40978ff; the side push 46347–46365 (**built**, `Player.sidePush` — a test only, ENG E4 / LL §10.7).
  - First call: T = R(90) + 90, the rain loop snd 452 (no stream draw); after every Caps-Lock pause a fresh R(90) and
    the loop again. Thunder: T counts down; 0 → flash 3 + snd 453; −2 → the fade as **`AsyncGammaFade` plus three
    `gammaStep` ops in the same iteration**, gated on the fading preference and the faded flag; then T = R(150) + 210.
    Drops: x from H + R(50) while < H + 660, heavy / light by R(2), three particles each, the draw order R(2), [R(100),
    R(100)], R(200). Runs on undrawn frames and on the pause's and the quit dialogs' extra paints.
  - Fixture: level 15 with nothing left out (6A-BG1c, before this task, built the plants; level 15 is not yet in
    `BuiltLevels`). The Core rain tests open it through `LevelFixture` with the headless services; the Render tests
    with `LevelFixtureServices`; the thunder tests set the fading and sound preferences through the fixture's `prefs:`.
- **Tests (12):** ENG §2.7's list less the audit row — in `RainTests` (Core, on the fixture):
  `testRainFirstCallTimerAndLoop` · `testRainRestartsAfterPause` · `testRainThunderSequence` · `testRainThunderGammaOps`
  · `testRainDropColumnsAndDraws` · `testRainHeavyDropParticles` · `testRainLightDropParticles` ·
  `testRainRunsOnUndrawnFrames` · `testSidePushOnLevel15`; in `OmniPxTests` (Render): `testOmniPxModeOneFacesOnly`; in
  `FeatureGoldenTests` (Render, on the fixture): `testLevel15RainFeatureGolden` (frame 1; **deleted at 6A-L15**) ·
  `testLevel15ThunderFlashFeatureGolden` (the flash frame, measured; kept). WinKit (+1): `testLoopedCueOnTheMixer`.
  Asserts: ENG §2.7's five.
- **Gate:** Gate-F with lockstep (a) (G2 737, GW2 85; G5; G-MUTE 1 / 1). **Commit:** `Ferazel: Storm Valley's rain,
  thunder and the looped rain sound; the side push pinned; 12 tests, 1 Windows audio test`.

#### 6A-L15 — minor — level 15 "Storm Valley" enterable (→ 740)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (+ 15), `Tests/FerazelCoreTests/LevelFifteenTests.swift` (new),
  `Tests/FerazelRenderTests/{LevelFrameGoldenTests,FeatureGoldenTests,BootFacesTests,FaceTests}.swift` (the rain
  feature golden deleted), `Ferazel/Windows/Tests/FerazelWinKitTests/{WinLevelReferenceTests,FerazelSettingsTests}.swift`,
  the list-pinned tests (`BuiltLevelsTests`, `GameFlowGameTests`' not-built walk if it moves).
- **Contract:** LL §4 "Level 15". 183 records (38 refused today: trees 10, rotating cannons 3, plants 22, Box scenery 3);
  OmniPx mode 1; `0x26c9` = 1; `0x270e` 56; the side push −320; music 5; the springs 1150 / 1152 / 1153 (built; marks
  CF's); the Gremlin 1770 and the Dillo 1870 first placed — **the parent / child idling carry** read for the Gremlin's
  composite and the Dillo (a test).
  - **Parameter trace:** the springs 1150 / 1152 / 1153, the Bonus 1293, 3102, 3219, 3223, the Gremlin 1770, the Dillo
    1870, and every type built on 1–5 whose p1…p4 here the script finds new.
  - The new real first-frame golden is checked against the rain golden it retires: 6A-RN's fixture left nothing out,
    so the two worlds agree at frame 1 unless the opening path differs (`LevelRun` through `BuiltLevels` and the
    chapter / stage screens against the fixture's direct open) — As executed records "new = RN's retired value", or
    why not.
- **Tests (+4 / −1):** `testLevel15SetsUpEveryRecord` · `testLevel15FirstFrameGolden` · `testBuiltLevelsFifteen` ·
  `testLevel15IdleChildLinks` (the Gremlin's composite parts and the Dillo across their idling: each part's link to
  its body, the parts' count and positions after a measured number of idle frames, re-activation through
  `.IdleToActiveSprite` with no Setup re-run); deleted: `testLevel15RainFeatureGolden` (deleted as ENG §2.7 says; the
  real first-frame golden supersedes it). WinKit (+1): `testLevel15FirstFrameReference`.
- **Gate:** Gate-L (G2 740, GW2 86). **Commit:** `Level 15 enterable: Storm Valley; 4 tests (1 feature golden retired),
  1 Windows reference`.

#### 6A-CH1 — ⚑ MAJOR — the Goblin Chief: class, Init, Setup, Handle; the player's stagger arm (→ 752)
- **Files:** `Sources/FerazelCore/World/Enemies/Chief.swift` (new), `Sources/FerazelCore/Sprites/SpriteSlot.swift`
  (`SpriteHandler.chief`), `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:712`, the Chief's refusal),
  `Sources/FerazelCore/World/SpriteClassTable.swift` (already `(.chief, .idle)` for 0x776…0x77f — confirm),
  `Sources/FerazelCore/Session/FerazelSession.swift` (the Handle row), `Sources/FerazelCore/Front/LevelRun.swift` (his
  Setup's marks only, incl. the 0x77b set — the five flag-1 registration records are 6A-CF's and are not edited here),
  `Sources/FerazelCore/Player/PlayerStates.swift`
  (`:371–:372`, the boss-grab early return → the arm; the comment's cite corrected to M l. 45591–45632),
  `Sources/FerazelCore/Player/PlayerState.swift` (`bossGrab`, `:201`), `Tests/FerazelCoreTests/Enemies/ChiefTests.swift`
  (new), `Tests/FerazelCoreTests/PlayerStaggerTests.swift` (new), `Tests/FerazelRenderTests/DrawModeAuditTests.swift`,
  the level fixture (`Tests/FerazelCoreTests/LevelFixture.swift` — used).
- **Contract:** BOS §3.1–§3.3, §3.6 (duties), §3.7 (the stagger, its length); ENG §2.13. Dump: `.InitChiefSprite`
  M l. 75008–75028, `.SetupChiefSprite` 75031–75115, `.HandleChiefSprite` 75162–75441, `.GoblinChiefRandomCry`
  75118–75159, `.HitChiefTileSprite` 75535–75567, the stagger arm `.HandlePlayerSprite` 45591–45632.
  - Setup in dump order (HP 2000 / 1200, gravity 0x276, `+0x8d = 1`, `+0xa6` −40, lane 2, R(10) drawn then
    overwritten, **no `+0x18a`, no `+0x1b4`**); spawned idle.
  - States 6 (wait; counts only while locked), 1 (jump: R(100) before R(6000), snd 414, vy −0x2904, the nine lane rows),
    3 (land: R(12000), snd 435, shake 0x16, **stagger 0x18** when the player's `+0xce ∨ +0xcd`), 2 (throw: R(8000),
    snd 704 vol 0x5f, the 0x77b boulder at layer 0xb, its Setup's R(5), R(500), R(0x96); 1 or 2 throws a landing), 4
    (dying: `+0x1a2 = 1` on dying frame 20); the tail (the `+0xb2` counter; the death entry's R(100) < 0x3c → the cry
    first; no liquids, no glow). The no-free-record boulder (Ruling 16 widened — known deviation 6, D47: stores and
    reads dropped, R(500) and R(0x96) still drawn).
  - The stagger arm: vx × 0.5, the six faces by (c mod 12) >> 1, the clears, the spin-sound stop through `SoundVoices`,
    then the end of the state chain; 0x18 → 23 arm frames, 0x14 (Xichra's) → 19; a pre-empted frame shortens it.
  - Level 18 opens with nothing left out (BG1c and RP are in): `ChiefTests` open it through `LevelFixture` (an empty
    list; not yet in `BuiltLevels`); the stagger tests are synthetic.
- **Tests (12):** BOS §3.8's 6A-CH1 list less `testPlayerStaggerArm`: `testChiefSetupWrites` ·
  `testChiefCacheRegistration` (reads his five records' place and flag 1 in CF's list as CF wrote them; pins his
  Setup's marks incl. 0x77b) ·
  `testChiefFirstJumpAfterLock` · `testChiefJumpDrawOrderAndLanes` · `testChiefLandingShakeAndStagger` ·
  `testChiefThrowBoulder` · `testChiefThrowCount` · `testChiefDeathCryDraws` · `testChiefTileCallbackIsCrawlerBody`;
  ENG §2.13's three in its place: `testStaggerSlowsAndPoses` (with BOS's 0x18 → 23 / 0x14 → 19 and the pre-empted
  frame) · `testStaggerClearsStates` · `testStaggerSkipsStateChain`. Asserts: BOS §3.10 items 1–23; ENG §2.13's two.
- **Gate:** Gate-B (G2 752; no golden moves — the Chief is on no built level; `_DAT_100a0570` has no writer on 1–5;
  the bot: not applicable until 6A-L18 — level 18 is not in `BuiltLevels.list` — its quick mode on 18 is 6A-L18's).
  **Commit:** `FerazelCore: the Goblin Chief's class and Handle; the player's stagger; 12 tests`.

#### 6A-CH2 — ⚑ MAJOR — the Chief's Hit and Kill, the three pieces, the fight (→ 760)
- **Files:** `Sources/FerazelCore/World/Enemies/Chief.swift`, `Sources/FerazelCore/World/Enemies/EnemyCommon.swift`
  (a `.chief` `killProc` arm; `killsForGood` gains `.chief`), `Sources/FerazelCore/Player/HitPlayerSprite.swift` (`:67`,
  `.chief` joins the routing case — row M l. 49849–49851, 0x70), `Sources/FerazelCore/Items/Smite.swift` (`:18`,
  `.chief` appended), `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift` (the hit arm; the per-frame
  record write-back with no `+0x18a`), `Tests/FerazelCoreTests/Enemies/ChiefTests.swift`,
  `Tests/FerazelRenderTests/BossKillLevelRunTests.swift`, the level fixture (`Tests/FerazelCoreTests/LevelFixture.swift`
  and `Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used: level 18, an empty list).
- **Contract:** BOS §3.4 (Hit), §3.5 (Kill), §3.6 (pieces, write-back, arena), §3.9 (the scripted kill). Dump:
  `.HitChiefSprite` M l. 75444–75499, `.KillChief` 75502–75532, `.UpdateSprites` write-back 4959–4966.
  - Hit: a player shot is killed silently **first**, then `.HurtSprite(S, shot +0xa4, 0, 0, 2, 8)` — a miss wastes the
    shot; a hurt sets `+0x116 = 15`, `+0xb2 = 1`, blood spray, snd 701 / 702 (HP ≤ 200), the cry by R(100) < 0x3c;
    Fireball 100 → 20 landed hits. A crush: 200, `+0xf0 = 0`, `.KillBox`'s draws, R(10000), the cry.
  - Kill as the Warrior's; the level-18 gate (x 628) opens, track 30. His own record follows him every frame (no
    `+0x18a`) and is cleared by `+0xea`. The arena: v −1400, lock at x < 1340, the second bound −640 — built at LV5,
    now reached (**closes the Phase 5 carry "the second camera bound is untested"**).
  - The scripted kill (BOS §3.9): seed 1; the Fireball carried — a fixture opened directly has no carry, so the test
    hands `LevelRun` a **test carry** (the fixture's `carry:` — the `LevelCarry` / `SaveBlock` `LevelRun` takes) with the
    Fireball owned and selected, and magic full if 20 casts need it (a named test stand-in, the stand-ins table);
    `.left` until the lock (x < 1340), then every 16th
    frame a one-frame tap toward his centre and next frame a one-frame `.use`; until the Kill or 20,000 frames. HP0 and
    the Kill measured; Kill − HP0 = 20 + ⌈(B − T + 1) / 2⌉ − 1 of face 0x77a[3] checked; both pinned.
- **Tests (8):** BOS §3.8's 6A-CH2 list: `testChiefTakesShotDamage` · `testChiefInvulnerableWastesShots` ·
  `testChiefCrush200AndCry` · `testChiefKillTailAndGate` · `testChiefRecordWriteBack` · `testChiefContactAndSmite` ·
  `testLevel18ArenaBounds` (also: whether level 18 reaches the 0x7f60 right-opening bound — measured; if it does not,
  that stays the run-47 carry, untested, and the As executed says so) — in `ChiefTests`, on the fixture;
  `testChiefScriptedKill` — in `BossKillLevelRunTests`, on the fixture with `LevelFixtureServices`. Asserts: BOS §3.10
  items 24–30.
- **Gate:** Gate-B (G2 760; the bot cannot reach level 18 until 6A-L18 — quick mode there). **Commit:** `FerazelCore:
  the Goblin Chief's Hit and Kill; the scripted fight on level 18; 8 tests`.

#### 6A-L18 — minor — level 18 "Goblin Chief" enterable (→ 764)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (+ 18), `Tests/FerazelCoreTests/LevelEighteenTests.swift` (new),
  `Tests/FerazelRenderTests/{LevelFrameGoldenTests,BootFacesTests,FaceTests}.swift`,
  `Ferazel/Windows/Tests/FerazelWinKitTests/{WinLevelReferenceTests,FerazelSettingsTests}.swift`, the list-pinned tests.
- **Contract:** LL §4 "Level 18"; the bot's check owed by 6A-CH1 / CH2 (Gate-B) is made here. 34 records (6 refused
  before 6A-BG1c: plants 5, the Chief 1); the ripple; `0x270c` −108, `0x270e` 150, `0x2710` 80, `0x2714` −512, start facing left; music 23 until the Kill, then 30; the Chief's idle
  activation frame measured (BOS §9.3).
  - **Parameter trace:** level 18 places no built type first (LL §4); every type built on 1–5 whose p1…p4 here the
    script finds new.
- **Tests (4):** `testLevel18SetsUpEveryRecord` · `testLevel18FirstFrameGolden` · `testBuiltLevelsEighteen` ·
  `testLevel18ChiefActivationFrame`. WinKit (+1): `testLevel18FirstFrameReference`.
- **Gate:** Gate-L (G2 764, GW2 87; the bot's quick mode on 18 meets the Chief). Wave 6A.3 end: G3, GWB by day
  **761 / 0 / 3 / 0 (of 764)**, GW4R by day, the Fable cross-check of BG1c…L18. **Commit:** `Level 18 enterable: the Goblin
  Chief's arena; 4 tests, 1 Windows reference`.

#### 6A-CL — minor — clouds (→ 771)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:430`), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift`,
  `Sources/FerazelCore/Front/LevelRun.swift` (the cloud singles #132–#135 marked), `Tests/FerazelCoreTests/CloudTests.swift`
  (new), `Tests/FerazelRenderTests/{FeatureGoldenTests,DrawModeAuditTests}.swift` (`+0xb8 = 0xb0004` and layer 0x7ef4
  writer rows; `Refusal.translucency`'s width case stays unreachable — the cloud widths 174 / 197 / 220 / 193 as its reason),
  `Tests/FerazelCoreTests/CachedFacesTests.swift` (level 20's count re-derived for the cloud singles — 6A-CF), the level
  fixture (`Tests/FerazelCoreTests/LevelFixture.swift` and `Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used).
- **Contract:** ENG §2.8. Dump: Setup arm M l. 62526–62567, Handle 63304–63341. Owns 2890–2893 (164 records, level 20
  only). **Two draws per cloud in `.SetupLevelSprites` (R(60) then R(50)) — 328 draws that every later level-20 number
  depends on** (ENG §7.3); fx = fy = R(60) + 270 > 256 on every shipped cloud; the fx / fy = 0 and < 0 arms pinned as
  read (synthetic). Fixture: level 20 with the blades 3060 (28) and the maces 1485 (16 — every 1485 on level 20 is a
  mode-1 path) left out by type, 44 asserted.
- **Tests (7):** in `CloudTests` (Core): `testCloudSetupDrawsTwo` (on the fixture: the 328 draws inside
  `.SetupLevelSprites`) · `testCloudSetupFields` · `testCloudParallaxX` · `testCloudParallaxY` · `testCloudNeverCollides`
  (synthetic clouds, the fx / fy = 0 and < 0 arms too) · `testCloudFxAlwaysAbove256OnLevel20` (per record from the level
  file); in `FeatureGoldenTests` (Render, on the fixture): `testLevel20CloudFeatureGolden` (kept). Asserts: ENG §2.8's six.
- **Gate:** Gate-F (G2 771). **Commit:** `FerazelCore: the clouds of Hangnabit; 7 tests`.

#### 6A-BD — minor — the rotating blade and the segment test (→ 784)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:430`), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift`,
  `Sources/FerazelCore/Player/HitPlayerSprite.swift` (`:126`, `:159` the `// later: 0xbf4`),
  `Sources/FerazelCore/Physics/LineSegments.swift` (new — `.SectLineSegs`, `.SectRectLineSeg`),
  `Sources/FerazelRender/Frame/SpriteBlitter.swift` (only if a rotated mode-0xc face with bottom clip 0x5e is refused
  today — Invariant 8), `Sources/FerazelCore/Front/LevelRun.swift` (single #136 marked), `Tests/FerazelCoreTests/BladeTests.swift`
  (new), `Tests/FerazelRenderTests/{FeatureGoldenTests,DrawModeAuditTests}.swift` (rotation `+0x1aa`, `+0x89 = 1`,
  `+0x1ba = 0x5e` writer rows), `Tests/FerazelRenderTests/SpriteDrawTests.swift` (`testBladeRotatedLitDrawIsDrawable` —
  whether a draw is drawable is the blitter's question), `Tests/FerazelCoreTests/CachedFacesTests.swift` (levels 20's
  and 22's counts re-derived for single #136 — 6A-CF), the level fixture (`Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used).
- **Contract:** ENG §2.9. Dump: Setup M l. 62571–62583, Handle 63511–63530, `.HitPlayerSprite` arm 49684–49724,
  `.SectRectLineSeg` 39562–39601, `.SectLineSegs` 39507–39561. Owns 3060 (28 on 20, 13 on 22). Angle + speed (p3 0 → 8)
  wrapped both ways; dynamic light; p4 = 0 → bottom clip 0x5e (levels 22, 62); p1 read by neither arm. The hurt only when
  the arm's segment (16…88 px) crosses the body box (top + 6, bottom − 8): R(100) for the coins drawn **only on a
  crossing frame**, vx ±0x8fc by the strict centre test, 0x70 / invul 0x3c; touching and collinear-disjoint segments
  count as crossings (i32). Fixture: level 20 with the maces 1485 left out by type, 16 asserted.
- **Tests (13):** ENG §2.9's list — in `BladeTests` (Core, synthetic blades and segments; per record from the level
  files where a field comes from the data): `testBladeSetupFields` · `testBladeHandleSpinsAndWraps` ·
  `testBladeBottomClipWhenP4Zero` · `testSectLineSegsCrossTouchAndMiss` · `testSectLineSegsCollinearDisjointHits` ·
  `testSectRectLineSegEdgesAndInside` · `testBladeArmEndpoints` · `testBladeHitKnockbackAndCoins` ·
  `testBladeNoDrawWithoutCrossing` · `testBladeHitRestoresVx` · `testBladeIgnoresP1`; in `SpriteDrawTests` (Render):
  `testBladeRotatedLitDrawIsDrawable`; in `FeatureGoldenTests` (Render, on the fixture): `testLevel20BladeFeatureGolden`
  (kept). Asserts: ENG §2.9's seven.
- **Gate:** Gate-F (G2 784). **Commit:** `Ferazel: the rotating blade and its segment test; 13 tests`.

#### 6A-MP — minor — programmed-path maces, modes 1 and 2 (→ 791)
- **Files:** `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:399` the modes 1–2 refusal; `:888–:898` the spawn —
  modes 1–2 make no radial), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (`:173` `mace`),
  `Sources/FerazelCore/World/Movers/ProgrammedPath.swift` (the one path — never a second copy),
  `Tests/FerazelCoreTests/MacePathTests.swift` (new), `Tests/FerazelRenderTests/FeatureGoldenTests.swift`,
  `Tests/FerazelCoreTests/CachedFacesTests.swift` (levels 20's and 22's counts re-derived if the mode-1 / mode-2 maces
  setting up move them — 6A-CF), the level fixture (`Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift` — used).
- **Contract:** ENG §2.10. Dump: Setup M l. 62338–62361 (after the built common stores and write-backs 62329–62336),
  Handle 63141–63146, the radial branch 62362–62420 (modes 10–14 only — ENG E19). Owns the mode-1 / mode-2 records of
  1485 (16 on 20, 29 on 22). `+0x170 = 1`, `+0x185 = 0`, `+0x188 = 1` (a write-back flag — a Setup-test row),
  `.SetupProgrammedPath(s, −1, 0)` with the bounds from the position **before** the p4 offset; mode 1 → y, mode 2 → x;
  the Handle: the face, the path, gravity and tiles; no chain, no spoke. Level 1's pendulums share the edited spawn: its
  goldens are the switch-off — none moves. Fixture: level 20 with nothing left out.
- **Tests (7):** in `MacePathTests` (Core, per record from levels 20 and 22 and synthetic paths):
  `testMacePathSetupModeOne` · `testMacePathSetupModeTwo` · `testMacePathHandleMoves` · `testMacePathMakesNoChain` ·
  `testMacePathWriteBackFlag`; in `FeatureGoldenTests` (Render, on the fixture): `testLevel20MacePathTrace` (kept — 6A-L20
  keeps it when it deletes the golden beside it) · `testLevel20MacePathFeatureGolden` (**deleted at 6A-L20**). Asserts:
  ENG §2.10's five.
- **Gate:** Gate-F (G2 791). **Commit:** `FerazelCore: mace paths (modes 1 and 2) on the one ProgrammedPath; 7 tests`.

#### 6A-L20 — minor — level 20 "Hangnabit" enterable (→ 794)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (+ 20), `Tests/FerazelCoreTests/LevelTwentyTests.swift` (new),
  `Tests/FerazelRenderTests/{LevelFrameGoldenTests,FeatureGoldenTests,BootFacesTests,FaceTests}.swift` (the mace-path
  feature golden deleted, its trace kept), `Ferazel/Windows/Tests/FerazelWinKitTests/{WinLevelReferenceTests,FerazelSettingsTests}.swift`,
  the list-pinned tests.
- **Contract:** LL §4 "Level 20". 333 records (209 refused today: clouds 164, blades 28, the cannon 1092 p1 103, maces 16);
  2,899 wind cells; music 15; the hang glider 3050 (its four Player sets marked — CF); the Gremlin 1770.
  - **Parameter trace:** the cannons 1094 / 1096 (p1 0), the Bonus 1290, 1291, 1293, 3102, 3206, 3219, the radial
    maces 1480, the Gremlin 1770, the glider 3050, and every type built on 1–5 whose p1…p4 here the script finds new.
- **Tests (+4 / −1):** `testLevel20SetsUpEveryRecord` (incl. the 328 cloud draws first in the stream; assert: the
  opened level's `CachedFaces.needed(by:)` equals `testLevel20LoadBarMarks`' count and total as last re-derived) ·
  `testLevel20FirstFrameGolden` · `testBuiltLevelsTwenty` · `testLevel20GliderMarksAndWind`; deleted:
  `testLevel20MacePathFeatureGolden`. WinKit (+1): `testLevel20FirstFrameReference`.
- **Gate:** Gate-L (G2 794, GW2 88). **Commit:** `Level 20 enterable: Hangnabit; 4 tests (1 feature golden retired), 1
  Windows reference`.

#### 6A-PS — minor — the pipes' level spawn (→ 795)
- **Files:** `Sources/FerazelCore/World/Movers/BoxSprite.swift` (`setupPipe` `:446` wired into the level spawn; the
  throwaway child), `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:512` — the pipe arm 1490…1493),
  `Sources/FerazelCore/Front/LevelRun.swift` (the pipe singles #6–#9 marked on CF's list),
  `Tests/FerazelCoreTests/EnemyPipeTests.swift` (the new test), the level fixture
  (`Tests/FerazelCoreTests/LevelFixture.swift` — used).
- **Contract:** the PI card's As executed (above); LL §4 "Level 21" (the 6 pipe records). Dump: the pipe Setup
  M l. 59325–59356 (the throwaway child 59347–59353). A **type task** (fix-round ruling: a level task builds no type).
  **The pipe's level spawn** (the Phase 5 stand-in): `BoxSprite.setupPipe` into the level spawn; the throwaway child
  `.GenerateSprite(…, 0x200, 1, 2)` then `+0xe9 = 1` — its Setup's draws and its + 1 on the live-enemy count while the
  window is open, never taken back; `SetupFaces`' pipe arm. The pipes are placed first on level 21 (PI) — no level 1–5
  record takes this arm, so no golden moves. Fixture: level 21 with nothing left out (BX1a and BX1b are in; not yet in
  `BuiltLevels`).
- **Tests (1):** `testLevel21PipeLevelSpawn` (in `EnemyPipeTests`, Core, on the fixture: the throwaway child's draws
  and count bump; the p2 write-back asserted in `w.records` — **closes the run-47 carry "pinned on the helper's return
  only"**; a pipe whose child lives across the pipe's idling keeps its `+0x1d4` link — the parent / child carry for
  pipes; assert: the throwaway child runs its class's real Setup (M l. 59347–59353), which marks its class's sets, but
  the level's load-bar count is the same with and without those marks, because every child type — 1700, 1705, 1730,
  1860 — is also placed on level 21 (the Fable cross-check's reading; the test asserts each type's placement), so
  `CachedFaces.needed(by:)`, which works from the placed types, already holds them; a child type not placed there is a
  STOP for the seat).
- **Gate:** Gate-F (G2 795; the bot cannot reach level 21 until 6A-L21 — its quick mode there is 6A-L21's, as for
  6A-CH1). **Commit:** `FerazelCore: the enemy pipes spawn from the level (levels 21 on); 1 test`.

#### 6A-L21 — minor — level 21 "Obfuscation & Edification" enterable (→ 798)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (+ 21), `Tests/FerazelCoreTests/LevelTwentyOneTests.swift`
  (new), `Tests/FerazelRenderTests/{LevelFrameGoldenTests,BootFacesTests,FaceTests}.swift`,
  `Ferazel/Windows/Tests/FerazelWinKitTests/{WinLevelReferenceTests,FerazelSettingsTests}.swift`, the list-pinned tests.
- **Contract:** LL §4 "Level 21". 325 records (30 refused before 6A-BX1a: Box scenery 7, faces and talkers 17, the
  pipes 6 — all built by now, the pipes' level spawn by 6A-PS). `0x2706` = 2 (the ambient row index: M l. 29824
  `0x2706 · 0x100` is in `.DrawParticles`, and `FrameRenderer.swift:208` passes it to `ParticleRenderer` — an assert on
  a lit-kind particle's colour, row 2); music 9; Mcnv 260 / 261 / 300; the insects 1860 (first placed here — the
  parent / child idling carry for the insect body, a record-0x200 child, Hazards "Idle children") and the bat 1742.
  - **Parameter trace:** the Bonus 1291, 1293, 3206, 3219, the mace 1487, the bats 1742, 1860, 1869, the Backgrounds
    1840 / 1843, the teleporters 1061 (their p1 pair ids), and every type built on 1–5 whose p1…p4 here the script finds new (the pipes' p1 child types are
    6A-PS's).
- **Tests (3):** `testLevel21SetsUpEveryRecord` (assert: with an insect 1860 idled, its body keeps its link and keeps
  running — measured over the idle frames) · `testLevel21FirstFrameGolden` · `testBuiltLevelsTwentyOne`. WinKit (+1):
  `testLevel21FirstFrameReference`.
- **Gate:** Gate-L (G2 798, GW2 89). **Commit:** `Level 21 enterable: Obfuscation & Edification; 3 tests, 1 Windows
  reference`.

#### 6A-CP — minor — the magic carpet (→ 810)
- **Files:** `Sources/FerazelCore/World/Movers/BoxSprite.swift` (`:147` the Setup `// later`; `:472` `handleBuilt`;
  `:1521`, `:1594` the wake; the tail `:605–:621` keeps its two exclusions), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (`:512`, the carpet's face arm), `Sources/FerazelCore/Front/LevelRun.swift` (set #27 0x438 marked), the player's half
  (built; proven, not changed): `Sources/FerazelCore/Player/{Player.swift:368–385, HandleKeys.swift:502–539,
  PlayerTiles.swift:158–172}`, `Tests/FerazelCoreTests/CarpetTests.swift` (new),
  `Tests/FerazelRenderTests/{FeatureGoldenTests,DrawModeAuditTests}.swift` (the mode words `p1 + 0x10000`, 0x10009,
  0x10008), `Tests/FerazelCoreTests/CachedFacesTests.swift` (level 22's count re-derived for set #27 — 6A-CF), the level
  fixture (`Tests/FerazelCoreTests/LevelFixture.swift` and `Tests/FerazelRenderTests/{LevelFixture,LevelFixtureServices}.swift`
  — used, with its `start:` override).
- **Contract:** ENG §2.11 (read in full). Dump: Setup M l. 59078–59103, Handle 60289–60375 (→ the Box tail 61152–61174),
  the wake `.HitBoxSprite` 61470–61476, the player's half 44532–44552 and 47249–47308. Owns 1080 / 1081 (D46.1; LL's
  6A-BX1c dissolves). The only shipped carpet (level 22, placement 486) has p2 0 → `+0x14c = −1`: **it never counts
  down, flashes or bursts** — those arms are synthetic (p2 > 0). The rolled carpet gets its tile hit back on its first
  Handle; rise 14 frames then sink; vx decay; vy · 0.8 once the bob ends; `.FootPressure` skipped and gravity forced for
  0x438 / 0x439. Fixture: level 22 with nothing left out and the player's start moved beside placement 486 through the
  fixture's `start:` (`LevelRun`'s own override; a named test stand-in).
- **Tests (12):** ENG §2.11's list — in `CarpetTests` (Core; the level-22 tests on the fixture, the p2 > 0 arms on
  synthetic carpets), the golden in `FeatureGoldenTests` (Render, on the fixture): `testCarpetSetupRolled` · `testCarpetSetupUnrolledDrawsR4` ·
  `testCarpetWakesOnPlayer` · `testCarpetRiseAndSink` · `testRolledCarpetGetsTileHitOnFirstHandle` ·
  `testCarpetVerticalDampingAfterBob` · `testCarpetRideCountAndFlash` · `testCarpetBurstsAtZero` ·
  `testCarpetLevel22NeverCounts` · `testCarpetSteeringMovesCarpet` · `testCarpetExcludedFromBoxTileHits` ·
  `testLevel22CarpetFeatureGolden` (the first frame after the wake, measured; kept). Asserts: ENG §2.11's ten.
- **Gate:** Gate-F (G2 810). **Commit:** `FerazelCore: the magic carpet; the player's built half proven; 12 tests`.

#### 6A-L22 — minor — level 22 "The Labyrinth" enterable (→ 814)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (`[1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21, 22]`),
  `Tests/FerazelCoreTests/LevelTwentyTwoTests.swift` (new), `Tests/FerazelRenderTests/{LevelFrameGoldenTests,BootFacesTests,FaceTests}.swift`,
  `Ferazel/Windows/Tests/FerazelWinKitTests/{WinLevelReferenceTests,FerazelSettingsTests}.swift`, the list-pinned tests.
- **Contract:** LL §4 "Level 22". 510 records (52 refused today: blades 13, maces 29, faces and talkers 9, the carpet 1);
  `0x2706` = 2; music 8; chapter card 5; the teleporters 1060 ×8; Dimbo 2956 (Mcnv 221: actions 5, 9, 10); the
  blades' bottom clip (p4 0) on screen; the Dillo 1870 / 1871, the Blob 1732, the bat 1851.
  - **Parameter trace:** the cannons 1091 / 1094 / 1096 (p1 0), the Bonus 1291, 1293, 1337, 1338, 3206, 3219, 3223, the
    radial maces 1480 and the 1485 records of modes 10–14, the Blob 1732, the Walker 1750, the Backgrounds 1840 and
    1900–1903, the bat 1851, the Dillo 1870 / 1871, the Box 3091, the teleporters 1060 (their p1 pair ids; the teleport arm is TP's), and every
    type built on 1–5 whose p1…p4 here the script finds new.
- **Tests (4):** `testLevel22SetsUpEveryRecord` (assert: the opened level's `CachedFaces.needed(by:)` equals
  `testLevel22LoadBarMarks`' count and total as last re-derived) · `testLevel22FirstFrameGolden` ·
  `testBuiltLevelsTwentyTwo` (the whole 6A list; level 22's exits → the not-built report for the next node, measured) ·
  `testDimboConversationActions` (Mcnv 221's actions 9 / 10 and what they write — the flag-99 Dimbo of level 11's
  record 283, Mcnv 220 — read in `ConvActions`, measured; assert: when what they write is what enables the dormant
  Dimbo (LL §5), level 11 opened with it sets record 283 up and it talks — Mcnv 220; if the measurement says otherwise,
  the As executed names it an open item for 6B). WinKit (+1): `testLevel22FirstFrameReference`.
- **Gate:** Gate-L (G2 814, GW2 90). Wave 6A.4 end = the phase end (6A-END). **Commit:** `Level 22 enterable: The
  Labyrinth; BuiltLevels holds every level through the Goblin Chief; 4 tests, 1 Windows reference`.

#### 6A-END — minor — the phase end: the checks, the relabel sweep, both builds staged, one gate card (→ 814)
- **Files:** `Ferazel/WHAT-TO-EXPECT.md` (the 6A card, Mac part), `Ferazel/WINDOWS-WHAT-TO-EXPECT.md` (Windows part —
  one card, two files), any `Ferazel/Core/Sources` file with a stale `// later:` naming a merged 6A task or "Phase 6"
  where a 6A task now owns it (comment-only relabels to the real owner: 6B / 6C task ids), `docs/ferazel/port-gap-ledger.md`
  (a dated "after Phase 6A" note), `tools/stage-ferazel.sh` / `tools/windows/stage-ferazel-win.sh` (only if needed).
- **Contract:** as A5's, for 6A. (1) **GE** over levels 1–5, 10, 11, 15, 18, 20, 21, 22, both shells: the visit sweep,
  the bot, the face-load tests and the draw-mode audit (inside G2) — every one exit 0 / green; **a non-zero exit stops
  the phase end** (each row becomes a fix task, nothing is staged); the summary lines go on the card. (2) The relabel
  sweep: `grep -rn 'later: 6A\|6A-' "$WT/Ferazel/Core/Sources"` prints only comments that name a 6B / 6C owner (each
  checked), and no `// later:` names a merged task (process lesson). (3) Stage both, GW5; by day G9M, GW6, GWB, GW4R
  (else "boot check owed (night rule)" on the card and in LOOP-LOG). (4) The Fable cross-check (§0) over the whole 6A
  diff (`git diff <phase-start SHA>..HEAD`, Mac + Windows) and the card — it covers wave 6A.4; Opus implementers fix
  its findings; re-stage. **STOP for Ben:** the card goes to QUESTIONS as a new item (the 6A gate, Mac and Windows). The
  next run is the 6B planning run (P6B: the Wave 6 cards expanded the same way), which does not wait for his verdict.
- **Gate:** G1; G2 814 / 2 named skips; GW2 90 / 2 named skips; G3; G5; GW1–GW4; GW5; GE; by day GWB **811 / 0 / 3 /
  0 (of 814)**, GW6, G9M. **Commit:** `WHAT-TO-EXPECT: Phase 6A gate card (through the Goblin Chief), Mac and Windows`.

### Execution order

Runs of 2 tasks, 3 when at most one is ⚑ (§0 "Context"); the seat may split a run at the 240k mark (the task in flight
finishes). Two implementers may work at once when their files are disjoint or touch one file in different regions (run
46's lesson): 6A-CF ∥ 6A-FR qualifies (they touch different regions of `DrawModeAuditTests.swift`); the level-10
features (S8, WD, RC, TR) and the level-20 ones (CL, BD, MP) do not — each measures on a fixture the one before it
defines — nor FX and S8 (S8 uses the fixture), nor BG1c and RN (RN's fixture needs the plants built). Run 51 opens with
6A-BL: the four launch checks owed at the run-49 close were done by day in run 50 (ee0fa6e, Q18 — Proof B 617 / 0 / 3 /
0 of 620). 6A-FX made wave 6A.2 ten tasks — four runs at most three a run — so the phase takes 13 runs (51–63), one more
than before; 6A-L10L11 (⚑, the first full GE over seven levels) runs alone in run 56 with its wave end.

| run | tasks (in order) | ⚑ | Core / WinKit at the run's end | wave end (Proof B by day + the Fable cross-check) |
|---:|---|---:|---|---|
| 51 | 6A-BL, 6A-CF, 6A-FR | 1 | 633 / 82 | — |
| 52 | 6A-W1, 6A-W2 | 2 | 650 / 82 | **6A.1 "the Warrior"**: GWB 647 / 0 / 3 / 0 (of 650); the cross-check here or opening run 53 |
| 53 | 6A-FX, 6A-S8, 6A-WD | 1 | 672 / 82 | — |
| 54 | 6A-RC, 6A-TR, 6A-RP | 1 | 703 / 82 | — |
| 55 | 6A-BX1a, 6A-BX1b, 6A-MC | 0 | 716 / 82 | — |
| 56 | 6A-L10L11 (+ the full GE) | 1 | 722 / 84 | **6A.2 "levels 10 and 11"**: GWB 719 / 0 / 3 / 0 (of 722); the cross-check in this run, or opening run 57 |
| 57 | 6A-BG1c, 6A-RN, 6A-L15 (+ the full GE) | 1 | 740 / 86 | — |
| 58 | 6A-CH1, 6A-CH2 | 2 | 760 / 86 | — |
| 59 | 6A-L18 (+ the full GE) | 0 | 764 / 87 | **6A.3 "Storm Valley and the Chief"**: GWB 761 / 0 / 3 / 0 (of 764); the cross-check in this run |
| 60 | 6A-CL, 6A-BD, 6A-MP | 0 | 791 / 87 | — |
| 61 | 6A-L20, 6A-PS, 6A-L21 (+ the full GE after each level) | 0 | 798 / 89 | — |
| 62 | 6A-CP, 6A-L22 (+ the full GE) | 0 | 814 / 90 | **6A.4 "Hangnabit to the Labyrinth"** — its cross-check is the phase review |
| 63 | 6A-END | — | 814 / 90 | the phase end: GE both shells, stages, GWB 811 / 0 / 3 / 0 (of 814), the Fable phase review, the card → Ben |

Every dependency holds: CF before every type and level task; FR before W1; FX before S8 and every other fixture user
(it builds the fixture); S8 before every level-10 feature (it removes the strip's refusal and shifts the slot ids they
measure); WD and RC before TR, RP (fixtures); TR before BX1a (the shared flip); BX1a and BX1b before PS (level 21 opens
on its fixture with nothing left out); BG1c before RN (level 15 opens with nothing left out but the rain); RC, TR, BX1a,
BG1c before RN; RP and BG1c before CH1 (level 18 opens); CL before BD before MP (fixtures); BD, MP, BX1b before CP; PS
before L21; every level task after every feature and type task its data switches on (LL §7 deps, ENG §7.2). Tests that
need records a later task builds use the fixture with those records left out, or read records per record from the
level file — each card says which.

### Stand-ins kept at the 6A end (◇, named) and who replaces them

| ◇ | where | replaced by |
|---|---|---|
| `BuiltLevels.list` = 1–5, 10, 11, 15, 18, 20, 21, 22; the not-built report "(Phase 6)" for 25 on | 6A-BL…6A-L22 | 6B-L25…L52, 6C-L55…L70; the report deleted at 6C-END |
| The Wizard, the Fire Guardians and Xichra stay `.inert` (their records refused at Setup) | — | 6B-WZ1 / WZ2, 6C-DM1–DM3, 6C-XI1–XI3 |
| OmniPx modes 3 / 6 / 7 / ≥ 8 refused at level open | PT, RN | mode 6: 6C-L55…L70 (level 70); 3 / 7 / ≥ 8 placed nowhere — kept |
| The path cannons (p1 < 0) refused at Setup | RC | 6B (ENG §3.1, level 40) |
| The spiked balls 0x5c3 / 0x5c4, the snowball 0xbfe (Box and player arms) | — | 6B (ENG §3.4, level 45; §3.5, level 31) |
| The countdown digits 2907; the CLUT animation; auto-scroll and its death arm; the fire backdrop, flame buffer and the placed fire 1208; the level-wide liquid flag / ice | — | 6B-TM, 6B-CA, 6B-AS, 6B-FI, 6B-ICE (prove) |
| The 0x46a spark draws of the EnemyShot Handle (CF pins the records only) | CF | 6B-WZ1 (ENG §2.14's second assert) |
| Every type first refused on levels 25–70 (LL §7: 6B-BG2 / BX2, 6C-BG3 / BX3 …) | — | its LL owner |
| Unreachable as shipped, kept refused or not transcribed and pinned: rope bridge 1466, table 0xb71, water kinds 206–209, `.RipplePxBackOffsets`, Background 0x73f / 0x740, tree 0xc0f's solid branch (synthetic), cannons p1 1…100 / ≥ 107; the passage darkness override for p2 ≠ 0 (`HitPlayerSprite.swift:970`, no shipped passage reaches it — LL finding 6) | ENG §5 (pins in BX1a, TR, RP, RC); LL finding 6 | kept (as read) |
| Geyser kinds 3 / 4 past the 12-face cache; Dillo 1872–1879; the Wraith variant | GY, DL, GF | kept (as read) |
| `.Victory`, the stitch, the credits | — | 6C-VI |
| `ParticleLife` vs CLUT 222 (levels 52 / 55) | carried | the task that opens 52 / 55 |
| **Test stand-ins:** `LevelFixture`'s patched in-memory `Mlvl` copies (records left out), 6A-CP's moved player start (the fixture's `start:`), 6A-CH2's test carry (the Fireball owned and selected, magic full if needed, for the scripted kill); 6A-RP's header patch (`0x26c6` → 0, the switch-off) | tests only | kept as tests (never in `Sources`) |

### Known deviations added by 6A
5. **The thunder's darkening** (`.GammaFadeOutAsync` / `.GammaFadeInAsync` on level 15) is presented through
   FerazelRender's screen gamma on the presented image, like the underwater tint (deviation 3), not the monitor's gamma
   [MED]; no golden sees it (`FrameRenderer` drops `.screenGamma` in level frames) — `testRainThunderGammaOps` pins the
   op list instead.
6. **No free record for a spawn** (ruled under D47; BOS §1.1 / §10 P10, Ruling 16 widened). When any spawner — the
   bosses (the Warrior's crates and shot, the Chief's boulder), the trees' branches, the pipes, every earlier spawner —
   asks for a sprite and all 700 sprite records are in use, the original gets nothing back and then writes to, reads
   from and (in the 6B / 6C bosses) calls through that missing sprite anyway — undefined on the Mac, writing into low
   memory, which cannot be reproduced. The port skips every one of those writes, reads and calls, and still makes every
   random draw the original makes there, so the random stream stays the binary's: the least deviation available.
   Never reached in normal play (it needs 700 live sprites); 6A-W1 and 6A-CH1 build it for the bosses as BOS §1.1
   says (the Warrior's crate block tests for a null result, M l. 73152–73160). A dropped spawn is
   silent, so 6A-W1 adds `SpriteWorld.refusedSpawns` and every level task asserts it 0.

### The 6A gate card ("through the Goblin Chief") — an outline; 6A-END checks every point against the level data

Play the staged Mac app and the Windows zip, New Game or a Phase 5 save; jump with `-FerazelLevel N` (N in the list).
**Levels 1–5, 10, 11, 15, 18, 20, 21 and 22 can be entered; 25 and later say "not built yet (Phase 6)".**
1. **Level 5, the Warrior** — three crates fall on the arena from the first moments; he walks, runs and swings, throws
   his blade-shot; crates landing on him hurt him (ten do it) — and a falling crate hurts you too; he dies with his death frames and burns away, thunder
   and a shake, the gate opens, the boss track plays. Shots and spells do not hurt him (as in the original).
2. **Level 10** — chapter card 2; the mountain strip moving at half speed behind the tiles; wind pushes you (and shots)
   in places; cannons that turn by themselves; trees whose branches you can stand on; the 800-point goblins; bat swarms.
3. **Level 11** — the river backdrop flowing and wobbling; tiles under water tinted; the water current; Nimbo talks.
4. **Level 15** — rain sheets and falling drops, lightning flashes with thunder and a brief darkening (with "fading"
   on), a steady push to the left; Gremlins and Dillos; springs; plants.
5. **Level 18, the Goblin Chief** — he waits until the arena locks, then jumps between three lanes, the landing shakes
   the screen and stuns you if you are standing, he throws boulders; 20 Fireball hits kill him; death, burn, gate,
   boss track.
6. **Level 20** — clouds in front of everything (they never move on their own: when the view moves they slide
   faster than the scenery); spinning blades (they hurt only when the arm crosses you);
   maces shuttling on paths; strong wind; the hang glider.
7. **Level 21** — darker; graves that speak; enemy pipes letting out creatures one at a time; teleporters; insects.
8. **Level 22** — chapter card 5; the Labyrinth's teleporters; Dimbo's conversation; the magic carpet (touch it, it
   unrolls, rises and you steer it — it never wears out here); blades with their lower half hidden; maces.
9. **Things only your eye and ear can judge (MED):** the strip's look, the ripple's speed, the rain's density, the
   thunder's darkening strength (screen gamma), the clouds' translucency; the two boss fights' feel (the Warrior's
   pace, the Chief's jumps and throws); the new sounds — the rain loop, the thunder, the Chief's cries, the boss track;
   the colours of the seven new level palettes (10, 11, 15, 18, 20, 21, 22).

**Windows part:** the same points on a Windows PC; note anything that differs. This is the first time the real
Windows program opens a level after 5 (the machine's Windows checks open them in the test build only): listen for the
new music tracks and the rain loop on 15. **Machine checks for the card:** the visit
sweep and the bot (both shells, every built level), the face-load tests, the draw-mode audit — summary lines pasted by
6A-END. **Known stand-ins:** the Wizard and later levels (6B, 6C).

### The sweep's and the bot's budget as levels 10–22 join (Ben's RAM rule)

The rule stands unchanged: at most 4 workers per path — the scripts are always run with at most 4 workers (`JOBS` ≤ 4)
whatever their own maximum is (`ferazel-visit-sweep.sh:52–53` and `ferazel-random-play.sh:66–67` accept up to 6) —
`MAX_WORKER_MB` 4096 never raised (a `memory` row is a leak to
fix), the machine brake at 15 % free, never two heavy things at once (the sweep, the bot, the Core suite, the WinKit
suite, Proof B — one at a time, beside at most one working implementer), stop with a plain `kill <script pid>`.

The sweep makes 4 visits per active record (levels 1–5: 872 records → 3,488 visits a path, measured at run 48). The
bot plays 4 seeds × 3 minutes a level = 21,600 steps a level (108,000 on 1–5, measured).

| after | levels | sweep visits a path | bot steps a path | sweep time, both paths | worker peak (sweep) |
|---|---:|---:|---:|---|---|
| Phase 5 (measured) | 5 | 3,488 | 108,000 | ~12 min on 1–4 (3,360 visits, measured at 6a70bce); 1–5 not recorded | Core ~130–140 MB; Windows ~295 MB after the leak fix (one worker, levels 1 / 4 / 5) — measured 2026-11-10 |
| 6A-L10L11 | 7 | 6,324 | 151,200 | ~23 min **(est.)** | ≤ 600 MB **(est.)** |
| 6A-L15 | 8 | 7,056 | 172,800 | ~25 min (est.) | ≤ 600 MB (est.) |
| 6A-L18 | 9 | 7,192 | 194,400 | ~26 min (est.) | ≤ 600 MB (est.) |
| 6A-L20 | 10 | 8,524 | 216,000 | ~31 min (est.) | ≤ 700 MB (est.: 164 clouds) |
| 6A-L21 | 11 | 9,824 | 237,600 | ~35 min (est.) | ≤ 700 MB (est.) |
| 6A-L22 / END | 12 | 11,864 | 259,200 | ~43 min, up to ~65 min if a visit costs more on the big levels (est.) | ≤ 800 MB (est.: 510 records) |
| 6C-END (the whole game) | 24 | 22,564 | 518,400 | ~80 min (est.) | ≤ 800 MB (est.) |

Visits a level: 10 → 1,248; 11 → 1,588; 15 → 732; 18 → 136; 20 → 1,332; 21 → 1,300; 22 → 2,040. The 24-level row
takes the ledger's 5,641 active records over the 24 levels (`later-levels-ledger.py --check`) × 4; the 6B and 6C
planning runs fill the rows between (6B-L25…L52, 6C-L55…L70) from LL §4's counts. **Estimates:** the time scales the
measured ~0.107 s a visit (the 6a70bce run: ~12 min for 3,360 visits × 2 — both paths, 4 workers each, builds
included; before the 2026-11-10 leak fix and watchdog) by the visit count; the peaks are
guesses from the level sizes, far below the 4 GB limit, never a reason to raise it. The bot's wall time is not
recorded in the repo (its summary prints `in W s`): its watchdog allows 120 s + 120 s a minute of play a process, so
at 12 levels × 4 seeds × 3 min over 4 workers the bound is ~75 min a path; the seat records the measured `W` at 6A-L10L11
and replaces this paragraph's estimates in the As executed. The G2 render half (~12 min at 134 render tests) grows with
the fixture and level goldens (~60 more render tests at most; leg 2 counted ~42) and with the per-level loops over
`BuiltLevels` that already exist — `LevelSweepTests.swift:60/:75/:80` (240-frame plays, three loops),
`DrawModeAuditTests.swift:931`, `BootFacesTests.swift:237/:303` — run over 12 levels, one of them 510 records (est.
20–30 min; the seat records the render half's time at 6A-L10L11 beside the bot's `W`): the 40-minute timeout holds; past 35 minutes the
seat records it in LOOP-LOG and raises it with Ben, never runs the two halves at once. At 6A-END the full GE (sweep then
bot, both shells, est. 1.5–2.5 h with builds) runs in a background shell polled with `stat -L`.

### Planner's notes (for Ben and the reviewers)

1. **Two documents disagree on the Chief's first task:** BOS gives 6A-CH1 ten tests with one stagger test
   (`testPlayerStaggerArm`); ENG says the stagger's three tests sit "inside CH1's 10". The sums cannot both hold. This
   plan keeps BOS's nine Chief tests and puts ENG's three stagger tests in place of BOS's one (BOS's 23 / 19 frame
   counts go into `testStaggerSlowsAndPoses`): CH1 is **12**, so the ladder runs 2 higher than the engine document's
   from there.
2. **ENG §5's four "data pin" tests had no task** (ENG §7.1 leaves them out): `testNoLevelSetsParallaxMode` → 6A-RP,
   `testUnplacedBackgroundArms` → 6A-TR, `testRopeBridgeUnplaced` and `testTableUnplaced` → 6A-BX1a; the water-kinds
   row widened to all 24 levels is an assert in 6A-BX1a. +4 against ENG's ladder.
3. **Windows references are pinned on real levels, not on fixtures.** ENG asks for "feature golden both shells" for the
   strip, the ripple and the rain; a fixture is test code in `FerazelRenderTests`, while `WinGame` boots the real world
   file (and the CrossOver smoke runs the real exe), so a Windows fixture would mean a second fixture mechanism in the
   Windows package. Instead every feature golden is Mac-only and each level task adds one Windows reference of its real
   first frame (7 WinKit tests, 82 → 90 with the rain's audio test). The features' pixels come from the shared
   `FerazelRender`, so the Windows reference on the real level covers the same drawing — and Proof B (GWB) runs the
   whole Core suite, the Render feature goldens included, on the Windows toolchain. Where the strip (10) or the ripple
   (11) is not on the first presented frame, the level's Windows reference also pins the first frame that shows it
   (6A-L10L11), so the shell path draws both in 6A.
4. **6A-MC has no WinKit test** (ENG's "card goldens both shells"): the chapter screen is the shared `ScreenRenderer`;
   if `-FerazelLevel 10` shows chapter card 2 before the level (measured at 6A-L10L11), the Windows reference pins the
   first level frame after it, and the card's own pixels are the shared renderer's, which Proof B runs on Windows.
5. **Scripted kills and the Warrior's kill-frame test live in a Render test file**, not in `WarriorTests` /
   `ChiefTests` as BOS wrote: a burn never completes without face pixels (the Phase 5 lesson), and both kills end in a burn.
6. **ENG §2.4 says "build one shared `flipHRect`"; it exists** as `PlatformSprite.flipH` (`PlatformSprite.swift:402–409`,
   the `.FlipHRect` port). 6A-TR makes it callable from the Box and Background movers; 6A-BX1a reuses it. No new copy.
7. **Feature goldens "kept unless frame 1" are always kept** (ENG lets the level task delete them when the feature's
   frame is frame 1). A fixture that leaves records out is a different world from the real level even at frame 1, so
   its golden is not a duplicate, and keeping them fixes the ladder in advance. The fixtures that leave nothing out (15,
   18, 20, 21, 22) are the real level's world, opened directly rather than through `BuiltLevels` and the stage screens:
   6A-L15 records whether its new golden equals 6A-RN's retired one, or why not. The four ENG says to delete (wind,
   rotating cannon, rain, mace path) are deleted as ENG says.
8. **`testStripCopiesPerLevel` (ENG) next to the existing `ParallaxTests.testStripSpriteCopies`:** kept, with its
   meaning narrowed to the sprites the real creation routine makes (the existing test pins the `PxSprites` model's
   copies). Levels 30–67 cannot open in 6A, so 6A-S8 factors the creation into one routine that takes a header and the
   test calls it on each of the six headers (fix-round ruling); only level 10 also goes through `setupLevel`.
9. **6A-L10L11 is ⚑** though neither document marks it: the first new levels since Phase 5, two levels in one task, the
   first Windows level references and the first full GE over 7 levels (LV5, its nearest neighbour, was ⚑).
10. **The full sweep and bot after every level task** (Ben, 2026-11-08) cost an estimated 45–65 minutes each by level 22
    (budget above), twice in run 61 (6A-L20 and 6A-L21; 6A-PS between them runs Gate-F only). If Ben prefers, a level task could sweep only its own levels and leave the full
    width to wave ends and the phase end — a question for QUESTIONS, not chosen here.
11. **Not determined on paper (each build measures):** the strip sprites' slot ids; whether the strip, trees, cannons
    show at frame 1 on level 10; the first ripple frame on 11; the first thunder frame on 15; the frame after the carpet's
    wake; the Chief's activation frame; both scripted kills' frames; whether `-FerazelLevel 10` shows chapter card 2;
    what Mcnv 221's actions 9 / 10 write; the not-built node reached from levels 11 and 22's exits; the bot's wall time.
12. **The old cards' errors, corrected in place:** 6A-FB folded into 6A-CF (D46.2); 6A-FR's arm is in `.HitPlayerSprite`,
    not `.HurtPlayer`; 6A-WD covers level 20 and moves every wind-scaled sprite; 6A-RP is `.PaintFrameWrap`'s inline
    loops, not `.RipplePxBackOffsets`; 6A-T11 is two proof tests inside 6A-RP; 6A-RN's side push is a test; 6A-S8 is
    sprites on six levels with a feature golden on a fixture; 6A-BG1 / BX1 split into the ENG feature tasks (TR, CL, RC,
    BD, MP, CP) and LL's BG1c / BX1a / BX1b (D46.1); 6A-BN1 dropped (nothing to build, LL §10.3); cannons 1091 /
    1093–1096 leave 6A (LL finding 10); the order is BL, CF, FR, the Warrior (ENG P14). The old card ids and the tasks
    that replaced them are in the cross-walk table under the ladder (the ledger's `--check` reads it).
13. Recorded as **D47** — "Ferazel's Wand: the Phase 6A plan's rulings (run 50, 2026-11-11)" in `docs/DECISIONS.md` —
    with this plan's rulings: notes 1–3, 5, 7, 10's question,
    14 and 15, and **the "no free record" rule of 6A-W1 and 6A-CH1** (BOS §1.1 / §10 P10, Ruling 16 widened: when a
    spawn returns nothing, skip the stores, reads and calls through the missing sprite, keep the random draws — known
    deviation 6), which the seat accepted at the fix round.
14. **T11's golden:** LL §10.2 says 6A-T11 "keeps its level-11 golden"; ENG §2.6 / P8 says no golden of its own (the
    switch-off runs on 6A-RP's ripple golden). This plan follows ENG, the later document: T11 is two proof tests inside
    6A-RP with no golden.
15. **The fix round's rulings (2026-11-11, the seat on the two review legs):** the pipes' level spawn is its own type
    task 6A-PS before 6A-L21 (a level task builds no type; ladder total unchanged); 6A-CF keeps the cache's outward API
    picture-valued and is ⚑ (more than five files outside `CachedFaces` change), and its level-20 / 22 load-bar tests
    pin only its own marks — each later task that adds marks there re-derives them; one level fixture, built by 6A-S8
    (by 6A-FX since note 16), opened through `LevelRun` and usable from the Core and the Render tests, with a start override; 6A-BG1c before
    6A-RN; 6A-S8's strip tests on headers for the levels 6A cannot open; the launch checks of run 51 were done in run 50;
    a boss task's bot check waits for its level task; the budget's 4-worker rule stated against the scripts' own
    maximum of 6.
16. **The Fable cross-check round's rulings (2026-11-11, the seat):** the level fixture is its own minor task 6A-FX
    directly before 6A-S8, proving the in-package link first and itself on level 21 (+2 tests; the ladder ends at 814;
    wave 6A.2 becomes ten tasks, so the phase takes 13 runs, 51–63); every fixture's leave-out list is literal, and a
    later task that moves an earlier fixture golden is ◈ for that one golden (6A-WD on 6A-S8's strip golden); 6A-S8
    names the colour table each strip level converts under, from the dump; every level task traces the new parameter
    values of its already-built types before the list widens (asserts; an unbuilt arm is a STOP and a new type task);
    D47 holds the plan's rulings. **Not taken:** splitting the looped rain sound out of 6A-RN — 6A-RN stays one ⚑ task
    (legal in its run, one ⚑ of three).

## Wave 6 — Phase 6B (cards; expanded in this file by its planning run)

Gate: **"through the Wizard and the fire"** — levels 25–52 playable.

| card | what |
|---|---|
| 6B-WZ Wizard ⚑ | BOS §4's contract — a 13-entry state table (0…12) with 7 coded arms, 6 live (2, 4, 6, 9, 10, 12), not "eleven states" (BOS P5); the three 0x46a fireballs (records by 6A-CF) and the hovering crate 0x434 (player arm by 6A-FR); split 6B-WZ1 Setup + Init + Handle (10 tests) → 6B-WZ2 Hit / Kill / fight (7); level 25's arena bounds 592 / 1384; OmniPx mode 5 on 25 (built by OX); `killProc` case, step-7 row (M l. 49846), Smite entry; the 0x46a spark draws (ENG §2.14's second assert) |
| 6B-ICE levels 30/31 | prove only (ENG §3.2, E8): the level-wide liquid flag `0x26cd` and ice friction 220 — the player, Box, Frog and built Background readers are built; only arms not yet built remain; the snowball 0xbfe on 31 (ENG §3.5); the ice types (LL) |
| 6B-TM countdown digits (level 40) | `.UpdateDigits`, the 2907 timer, the digit Effect ids |
| 6B-CA CLUT animation ⚑ | `.AnimateCLUT` (ENG §3.6; bosses-3 §9.2 as corrected): levels 50, 51, and 67 on Xichra's writes — not a Render-only op: it draws from the Core stream, needs a Core-writable hdr `0x2730` (built once here, reused by 6C-XI), a timer carried on `LevelCarry` that never resets, runs on every `.PaintFrameWrap` call (the pause's and the dialogs' too), feeds the level-start tint tables; `ScreenGammaOp.clut` exists but is not executed in level frames today (ENG P15) |
| 6B-AS auto-scroll ⚑ | `0x2726`–`0x272a`, the marker sprites of `.SetupLevelSprites` (the dump reads the speeds there only, LL finding 12), `.FindUpperLeftCorner`'s arm, the fire-wall markers 0x4bb…0x4bd, **the player's auto-scroll death arm in `.PlayerConstraints`** (raw `1004cd90..1004ce3c`) and the looped ambience with its volume updates (6A-RN's loop cue + a volume cue) (ENG §3.7, P16); levels 51 (x), 52 (y) |
| 6B-FI fire backdrop + flame buffer ⚑ | `.LoadCoolingMap`, the eight flame routines, `.DoubleBlitPPCParallaxOneLayerFire`, `.MyRandom` (its own generator); level 52 mode 1 (55 mode 2); **the placed fire 0x4b8 (1208), first on level 40**, whose Setup marks both sets 0x4b8 and 0x4b9 (LL finding 8; ENG §3.8) |
| 6B-BG2 / BX2 / BN2 | the Background / Box types first refused on 25–52 (LL §7: 6B-BG2 7 types, 6B-BX2 9), incl. the cannons 1091 / 1093–1096 (their first refused records on 40 / 52, LL finding 10); the path cannons p1 < 0 (ENG §3.1, level 40); the spiked balls 0x5c3 / 0x5c4 (ENG §3.4, level 45); **BN2 has nothing to build** (every Bonus / Platform / Rope type sets up today, LL §10.3) |
| 6B-L25…L52 levels enterable | 25, 30, 31, 40, 45, 50, 51, 52 (geysers 1442 on 50/51 and the Salamander on 50 are built); the horizon strip (6A-S8) on 30, 40, 45 needs only their goldens, measured after the strip's slot shift (LL §10.5, ENG §7.3) |
| 6B-MC | conversations + cards for 25–52 |
| 6B-END | phase end, gate card → Ben |

## Wave 7 — Phase 6C (cards)

Gate: **the whole game** — levels 55–70, the Fire Guardians, Xichra, victory.

| card | what |
|---|---|
| 6C-DM Fire Guardians ⚑ | BOS §5's contract: two guardians (partner at x − p3·32), 8 neck segments each (a new class, layer 0xc — BOS D7), fire mode 2 backdrop (after 6B-FI), the 0x46a records (6A-CF); the arena never locks (bosses-3 §11); +1000 score each; `killProc` cases, no step-7 row (the default 0x70), Smite entries; the End key in the guardians' Handle (ENG §4.2) and the guardians-alive global `*_DAT_1009fecc` (ENG §4.3); split 6C-DM1 Init + Setup + segments (8 tests) → DM2 Handle (9) → DM3 Hit / Kill / fight (8); the Demon's sine-table call re-derived at its planning run (BOS §9.4) |
| 6C-BG3 / BX3 / BN3 | the types first refused on 55–70 (LL §7: 6C-BG3 1 type, 6C-BX3 10); **BN3 has nothing to build** (LL §10.3) |
| 6C-L55…L70 levels enterable | 55, 62, 67, 70 (the Wraith and the Crab are placed on 62 — built); level 70's OmniPx interlace (mode 6, `.InterlaceBlit128`) ⚑. **The map's node ≠ level on two nodes** (node 60 → level 62, node 62 → level 67; return to the map uses `FindCurrNode(hdr+0x26c4)`): one level test walks 40 → 60 → 62 once (levels 62 / 67). Optional: one save-block round-trip on level 62 through `savePointSave` and `restoreSnapshot`. The horizon strip (6A-S8) on 62 and 67 needs only their goldens (LL §10.5). |
| 6C-XL Xichra's lair ⚑ | the three cannons and `.UpdateXichraCannons` (owned here, BOS P8), switching on 6A-RC's rotating arm (ENG E1, P18); the minions (0x6d6, record 500), the lair gates (p1 = 0); the CLUT animation of 67 runs 6B-CA's routine on Xichra's writes to hdr `0x2730` (BOS P6); 1 test |
| 6C-XI Xichra ⚑ | BOS §6's contract: float, the wing (a new class), phases, `.DoXichraShot`; no contact damage (in neither step-7 list, BOS D11); the stagger 0x14 → 19 frames through 6A-CH1's arm; conversations started inside her Handle (ENG §4.4); the 0x5c4 rain (ENG §3.4); split 6C-XI1 Setup + phases (9 tests) → XI2 states (10) → XI3 Hit / Kill / fight (8), after 6B-CA, the Handle-site suspension, 6C-VI's flag; the state-8 path sets the victory flag (`*_DAT_1009ffc4`, M l. 77190) and ends the game — her Kill is unreachable, so the scripted test is `testXichraScriptedVictory` (BOS P11) |
| 6C-VI victory (one task) | `.Victory`, `.CopyVictoryStitch`, `.CreditScreen` as a `GameFlow` state — `levelEnded` checks the victory flag before `openMap` (today a finished level always goes to the map, `NewGame.swift:175–181`; `.NewGame` / `.ContinueGame` test the flag at M l. 5737 / 6697); the end-of-game pictures PICT 4600–4607; music track 29; a frame golden per screen |
| 6C-END | phase end over all 24 levels both shells; the three invented gates — the New Game clamp, the map refusal, the Continue refusal of unbuilt-level saves (`NewGame.swift:66/:275–284`, `ContinueGame.swift:134–141`) — and the not-built report text deleted now that every level is built (the original has none; Continue's level > 0x4f "demo" refusal is the original's and stays); the "whole game" card → Ben |

## Wave 8 — release (attended session, after Ben's whole-game verdict)

| card | what |
|---|---|
| REL-1 | `tools/package-ferazel-release.sh` from `tools/package-btx-release.sh` (Developer ID sign, notarize via notarize-kit, staple; the Windows zip from `stage-ferazel-win.sh`); `CFBundleVersion` 1.0; `docs/release/ferazel-1.0.md`; one GitHub release `ferazel-1.0` with the notarized DMG and the Windows zip (Ben's ruling, 2026-11-07); the assets + `.sha256` copied to `releases/ferazel-1.0/` in the **main** checkout; README download links. Ben tries the downloaded DMG → "publish" (the BTX 1.0 shape). |

## Standing cards (not scheduled; the seat schedules one when its trigger fires)

| card | trigger | what |
|---|---|---|
| HK-REPIN | HectorKit main moves (Castles, Deimos, Cythera) | reconcile per G1; record SHA + floor in STATE and LOOP-LOG |
| NOTES-FIRST | Ben answers a gate with notes | a small named wave of fix tasks goes before the next scheduled wave |

---

## Self-review (rebuilt 2026-11-08 at 44f6919; run 46 folded in at c8d9cf5)

1. **Stands alone.** Every open Phase 5 task (OX, LV5, A5), the two run 46 finished (PI, PT, with their As-executed
   notes) and the Phase 5 gate card are here in full with
   the audit's corrections in their text; the verification model carries the gate table, every command, the ladders and
   the goldens. Waves 5–7 are cards by design, expanded in this file once LL, BOS and ENG land.
2. **Spec coverage.** Spec "3.4 What remains of Phase 5" → waves 2–3; "3.1–3.3" → wave 4 research, then waves 5–7 (every
   level, feature and boss has a card; the per-type split is LL's); "4. Faithful, ruled, or a platform departure" → the
   cards' text (three gated Phase 6 phases, engine features as their own tasks, level tasks one or two levels, one
   `ProgrammedPath`, the Warrior replaced in place with the switch-off check, the bot on every level, victory one task);
   "5. How each part is proven" → §0 and each card's acceptance; "6. Questions for Ben" → answered 2026-11-07, written in.
3. **Names.** `BossArena.noBossAlive`, `BuiltLevels.range` (→ a list at 6A-BL), `CachedFaces`, `SpriteHandler` cases,
   `ProgrammedPath` in `World/Movers/` — as in the code at c8d9cf5.
4. **Ben's method rulings of 2026-11-08** are in §0: two Opus legs per task; the seat briefs with the card and a line
   range and never pre-reads source; the sweep and the bot after level tasks and at phase ends only; STATE and the chip
   current-only.
