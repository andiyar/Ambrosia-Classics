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
| Memory (Ben's RAM rule, 2026-10-30) | never two whole suites or sweeps at once (Core suite, WinKit suite, visit sweep, bot); the sweep and the bot run with at most 4 workers; one seat gate run in a `git archive` copy beside one working implementer, or two review legs alone |

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
| GW2 | FerazelWinKit (macOS-hosted) | **81** total; 0 failed; skipped = exactly `WinVisitSweepTests testVisitEveryObjectThroughWinGame` and `WinRandomPlayTests testRandomPlayThroughWinGame` (~13 min: background it) |
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
# GW2 the Windows package's macOS-hosted tests: 81, 0, the two Windows opt-in names (background, ~13 min)
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

**Ladders** (Core G2 total; 2 opt-in skips throughout; WinKit 81 / 2 unless a row says otherwise). The Phase 5 ladder
runs one above its original numbers because Ben's commit 3cf72df (world-map status bar, 2026-10-30) added one test:

| after | Core | GWB at wave end (by day) |
|---|---|---|
| GY (run 45, done) | 603 | 600 / 0 / 3 / 0 (of 603) |
| PI (run 46, done) | 607 | — |
| PT (run 46, done; wave 5.4 end) | 607 = 479 + 128 | 604 / 0 / 3 / 0 (of 607) — measured |
| wave 5.4 Fable cross-check fix round (run 47; one geyser test by the seat's ruling) | 608 | — |
| OX ⚑ (run 47, done) | 613 | — |
| LV5 ⚑ (run 47, done; wave 5.5 end) | 619 | 616 / 0 / 3 / 0 (of 619) |
| A5 (Phase 5 end) | 619 | 616 / 0 / 3 / 0 (of 619) |

The wave 5.4 end measured in run 46: G3 `Totals: items 1,108 decoded, failures 0`; GE `core` on levels 1–4 — visit
sweep 3,360 visits / 0 failures, bot 86,400 steps / 0 failures; GW4R main menu identical; GW1 0 / 2, GW2 81 / 0 / 2,
GW3 0 / 1, GW4 and G5 green. From here the ladder was **607 → OX 612 → LV5 618**; run 47 measured 608 → 613 → **619** (the cross-check's +1).

Review fix rounds add asserts, not tests, unless the seat rules otherwise (recorded in As executed). Merged out of
order: previous + the task's N. Phase 6 ladders are set by their own plans (wave 4).

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
- **`BuiltLevels.range`** (`Front/BuiltLevels.swift:9`, `1...4` today) → `1...5` at LV5, with the report "Level n is not
  built yet (Phase 6)."; it becomes an explicit list at 6A-BL.
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
| 5 | Phase 6A — engine features of levels 10–22, levels 10–22 enterable, the Goblin Chief; gate | the first boss fight; six new engine features | ~8 |
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
  rather than dropping it from the 16-target list or inventing a stand-in Kill).
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

- **As executed — LV5 (run 47, 2026-11-08):** Ferazel/Core 613 → 619 (6 tests; the wave 5.4 cross-check's +1 carried). Commits 1d907fc (task), aafa17d (fix round), 0f7d839 (a citation). Dump over card, confirmed by both legs: **(a) the Warrior's facing `+0x17e` is set when FastRand(100) ≥ 51** (raw 10087a54–10087a68, the Dillo's compare idiom) — the card's "< 51" was backwards; **(b) "the music-on byte" in the loop rule is the no-async-fade-running flag `cRam100a5be2`** (set/cleared only by the fade code, M l. 42067–42123), not a music setting; **(c) the pan:** the lower-bound choice reads the counter before this frame's +1 and the shift after it, so the forced view runs 836 + 16·(40 − k), capped by the map edge at 1408, and before the lock the camera sits at 1408 because the map edge beats 1444; **(d) the original draws one more 100 % load bar after `.SetupOmniPx`** (M l. 2569), so the OmniPx turn-on is pinned between the cache loader's bar and that last bar. Seat rulings from the legs: **the pan counter `_DAT_1009ff9c` is carried across levels on `LevelCarry`** (zeroed only by the globals init, M l. 822 — New Game and Continue; nothing resets it per level); **the in-loop boss-music rule reads `noBossAlive` before `_UpdateSprites`** as M l. 5266–5275 order it (the session records the flag at that point, the rule still runs at the iteration end); the ◇ Warrior Handle skips the original's pre-lock work — three falling rocks (type 1075) above the arena refilled every 15 frames and the wounded-glow timer (M l. 73151–73212) — and its Hit (shots absorbed with a sound, crates bounced, M l. 73422ff) is empty: both named Phase 6 stand-ins, on the gate card. Retargeted expectations, each re-derived: `GameFlowGameTests` 1...5, the not-built walk 4 → 5 → 10 ("Level 10 is not built yet (Phase 6)."), the "seven" save Continues into level 5; `LevelFourTests` exit → level 5, switch 5 starts level 5; `BootFacesTests` level 5 first measured (init 46 / 0xb039da66a884cb8a, f30 55 / 0x69068d5e8151b0cc, f120 55 / 0xb9f08ee19927f3e7); `FaceTests` level 5 no keys / no drops, the Warrior's three sets required; **`GremlinFloaterTests.testGremlinCompositeSetup`'s picture-cache lists gain the Warrior's sets 0x71c/0x71d/0x71e (8/8/6) between the Dillo's and the Floater's** — `.InitSprites` M l. 133–134, `.InitWarriorSprite` M l. 72982–72984 (the seat's suite caught it; the implementer had not run that class). Files beyond the card: `SpriteWorld.swift` (the arena; the dead `bossFlag` forwarder removed, `ButtonGateTests` retargeted to `BossArena`), `EnemyCommon.swift`, `PlayerStates.swift`, `PlayerState.swift` (stale Phase 5 labels → Phase 6), `DrawModeAuditTests.swift` (the camera arena-refusal row removed — no throw left; two Warrior writer rows and the patrol-bound row added), `OmniPxTests.swift` (the no-op switch-off loop removed), `FerazelSettingsTests.swift` (a `("5", 5)` row; WinKit 81 unchanged). Goldens and levels 1–4 pins: unchanged. Legs: spec PASS WITH FIXES, quality 34 mutations / 24 caught / survivors equivalent or Phase 6 (the stand-in Handle's per-frame step is untested). Gates: G5, GW1 0/2, GW2 81/0/2, GW3 0/1, GW4, G3 1,108 / 0, bot quick mode level 5 `steps 7200, deaths 0, exits 15, failures 0`; the wave 5.5 end gates (G2 at 0f7d839, GE both, GWB, GW4R) are in LOOP-LOG's run 47 line.

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
- **Gate:** G1, G2 618 / 2 named skips, GW2 81 / 2 named skips, G3, G5, GW1–GW4, GW5, GE; by day GWB **615 / 0 / 3 / 0
  (of 618)**, GW6, G9M. **Commit:** `WHAT-TO-EXPECT: Phase 5 gate card (through the first boss door), Mac and Windows`.

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
    frames do not fall. If you use the Ring of Smiting on it, it may stop hurting but stays standing and the gate stays
    shut — expected until Phase 6.
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
| The Warrior's Handle/Hit/Kill: stands in its Setup face, hurts on contact as read, no Hit callback, never dies; the gate stays shut while it lives; the real Handle's three falling-crate children (type 0x433 into `+0x1d4/+0x1d8/+0x1dc`, spawned when p4 ≠ 0 once `+0x16c` counts below 1, M l. 73145–73182) are not spawned | LV5 | 6A-W |
| The Warrior under the Ring of Smiting: can reach HP < 1 with no Kill; harmless; Esc / ⌘W leaves | LV5 | 6A-W (the Kill) |
| The other bosses (Wizard, Chief, Demon, Xichra) stay `.inert`; their projectiles' spawners | — | 6A-CH, 6B-WZ, 6C-DM, 6C-XI |
| OmniPx modes 1/3/6/7/≥8 refused at level open; the horizon strip refused at level open | PT, OX | 6A-RN, 6C (interlace), 6A-S8 |
| Geyser kinds 3/4: the base face past the 12-face cache draws nothing (unplaced) | GY | kept (as read) |
| Dillo types 1872–1879 and the Wraith variant 0x6fe–0x707 refused at Setup (unplaced) | DL, GF | kept (as read) |
| The enemy pipe's level spawn: `BoxSprite.setupPipe` (the Setup's stores) is not wired into level spawn; the throwaway child `.SetupBoxSprite` spawns and kills at once (its Setup's random draws and its +1 on the live-enemy count, M l. 59347–59353) is not made; `SetupFaces`' pipe arm 1490…1493 still refuses | PI | 6A-L21 (level 21 places the first pipe) |
| `BuiltLevels = 1...5`; the not-built report "(Phase 6)" | LV5 | 6A-BL, then deleted at 6C-END |
| Refusals kept and pinned unreachable: the light byte −1, mode 5 rotated/scaled, 0xa mirrored, 0xb rotated, modes 2/7/8/0xd/0xe/≥0xf, water kinds ≥ 6, fire/ripple backdrops | `DrawModeAuditTests` | the Phase 6 task whose level places each |
| `ParticleLife` vs CLUT 222 (levels 52/55) | carried | the task that opens 52/55 |
| `.Victory`, falling rocks 1075/1076, spiked balls, magic carpet, rope bridge 1466, boss grab `_DAT_100a0570` writers, countdown digits | — | Phase 6 cards below |

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

### Task P6A — the Phase 6A plan (the planning run's product)

Written by the Opus planner from LL, BOS, ENG and the cards in wave 5, **in this file** (a new "Wave 5 — Phase 6A"
section expanded in place, the cards below replaced by bite-sized tasks — never a separate plan file): Verification
model additions (the 6A ladder, gate commands with numbers), tasks with Files/Contract/Tests/Gate/Commit, execution
order, stand-ins, known deviations, the gate card; two Opus legs + the Fable cross-check; rulings recorded under the next
free decision number. Its first task is 6A-BL, then 6A-FB, then the Warrior (replacing LV5's stand-in). The 6B and 6C
sections are expanded the same way by their own planning runs at the end of 6A and 6B. The plan budgets the visit
sweep's time and memory as it grows from 5 to 24 levels (Ben's RAM rule).

---

## Wave 5 — Phase 6A (cards; expanded in this file by P6A after LL, BOS, ENG)

Gate: **"through the Goblin Chief"** — levels 1–22 playable, the Warrior and the Chief beatable, Mac and Windows.

Every level task ("level N enterable") is one level, or two adjacent levels when neither adds a class or an engine
feature: every record set up (no `notTranscribed`), the picture cache marked at the original's positions, the load bar
counted, a `Level<N>Tests` file, the face-load tests extended (`FaceTests`' per-level drops/keys table re-derived), the
visit sweep and the bot extended to it, the bot's quick mode on it with 0 failures; the range/list widens only once its
census sets up every record. Every boss task replaces its stand-in in place and passes the switch-off check (its Handle
stubbed back → the old goldens return).

| card | what | files (today's owners) | acceptance |
|---|---|---|---|
| 6A-BL built-level list (first task of 6A) | `BuiltLevels` becomes an explicit sorted list of built level ids (`[1, 2, 3, 4, 5, 10]` …) with `contains` (a closed range cannot say "1 to 5, then 10"; `1...10` would admit 6–9, which have no level data); `NewGame.swift:66/:275–284`, `ContinueGame.swift:134–141`, `Shared/FerazelDriver.swift:44` (`-FerazelLevel`, both shells, refuses an id not in the list) read it; the bot and the sweep (`ferazel-random-play.sh:62/:76` parse the range with `sed`/`seq` today; `ferazel-visit-sweep.sh` / `VisitSweepPlan.swift:18`) take the list from one printed source, with a test of the parse; the tests pinned to a range move (`GameFlowGameTests`, `LevelFourTests`, `LevelThreeTests`, `BootFacesTests`, `FaceTests` — the LV5 list) | `Front/BuiltLevels.swift:9`, the readers above, both scripts | every reader compiles against the list; the bot runs on `[1…5, 10]` |
| 6A-FB the fireball cache (before 6A-W) | picture 0x46a is cut three ways (48×48 for 0x46a; 64×64 twice for the dead types 0x46b / 0x46c, M l. 51822–51861) but the port caches faces by picture only; the original reads three caches — key cached faces by record | `World/Enemies/EnemyShot.swift:381/:400`, `Front/LevelRun.swift:1216–1251` | a test that the three cuts differ and 0x46b draws the 64×64 cut |
| 6A-W Warrior ⚑ | the real Handle / Hit / Kill replacing LV5's stand-in in place (same file, the ◇ markers removed): eggs, random attacks, the three falling crates (0x433 into `+0x1d4/+0x1d8/+0x1dc`), the Kill's four writes (snd 453, shake 0x1e, flash 3, `fed0 = 1`), the gate opens, track 30 by the loop rule; its `killProc` case, step-7 contact row and Smite entry | `World/Enemies/Warrior.swift`, `BossArena`, `LevelRun.swift` (music), `Tests/.../Enemies/WarriorTests.swift` | the scripted-keys kill test; LV5's goldens return with the Handle stubbed |
| 6A-FR falling rocks 0x433/0x434 | the Warrior's crates and the rocks' player arm in `.HurtPlayer` | `World/Movers/BoxSprite.swift`, `Player/HitPlayerSprite.swift` | built with 6A-W or just before |
| 6A-S8 horizon strip (draw mode 8) ⚑ | `.BlitEncFaceBehindTiles{Clip,NoClip}`, the `Px` strip sprite from `hdr+0x2716/18/1a` | `FerazelRender/Frame/SpriteBlitter.swift` (the refusal row), `ParallaxBlitter.swift`, `DrawModeAuditTests` (PT's `0x2716` header check becomes a draw check), `LevelRun.swift` (PT's level-open refusal removed) | level-10 first-frame golden; the audit row moves to "drawn" |
| 6A-WD wind cells | `.LookupModedImpulse` on the overlay cells | `Player/PlayerTiles.swift`, `Physics/` | level-10 test rows |
| 6A-RP parallax ripple ⚑ | `.RipplePxBackOffsets` for levels 11, 18 | `ParallaxBlitter.swift` | level-11 golden |
| 6A-RN OmniPx rain (mode 1) ⚑ | `.GenerateRain` + overlay faces 6000/6001 (every logic frame, drawn or not); the side push `0x272c` | `World/OmniPx.swift`, `Camera/`, `DrawModeAuditTests` (PT's mode-1 refusal becomes a draw check) | level-15 golden; push pinned |
| 6A-T11 tinted submerged tiles | `hdr+0x26c6` in `.PlainWrapFGTile` / overlay | `FerazelRender/Frame/TileGridRenderer.swift` | level-11 golden |
| 6A-BG1 Background types of 10–22 (42 new; LL lists them) | trees 0xc08…, clouds 0xb4a…, the rotating blade 0xbf4 (`.SectLineSegs`), 1091–1097, 1150–1153, 1840/1843, 1900–1903, 2700–2711, 2890–2893, 3080–3084 | `World/Movers/BackgroundSprite.swift` | each type's Setup/Handle rows; split by LL into 2–3 tasks |
| 6A-BX1 Box types of 10–22 (LL) | geysers 1440 (built), pipes (built), 2808–2876…, 1060/1061/1080, the programmed-path cannon (p1 ≠ 0) and mace (modes 1–2) arms — added to the one `ProgrammedPath` (`World/Movers/ProgrammedPath.swift`), never a second copy; remember the 1xx-form flag zeroes the swing speed | `World/Movers/BoxSprite.swift`, `World/Movers/ProgrammedPath.swift` | split by LL |
| 6A-BN1 Bonus / Platform / Rope types of 10–22 | 1290–1339, 3050…3223, Platform 1404/1407, Rope 3020 | `BonusSprite.swift`, `PlatformSprite.swift`, `RopeSprite.swift` | — |
| 6A-L10…L22 levels enterable | 10, 11, 15, 18, 20, 21, 22 (the Dillo is placed on 15 and 22, the Gremlin on 15, pipes on 21 — all built). Level 21 also wires the pipe's level spawn: `BoxSprite.setupPipe` into level spawn, the throwaway Setup child (its random draws and its count bump, M l. 59347–59353), `SetupFaces`' pipe arm 1490…1493 | `Front/BuiltLevels.swift`, `LevelRun.swift`, new `Level<N>Tests.swift` | `testLevel<N>SetsUpEveryRecord`; bot quick mode 0 failures |
| 6A-CH Goblin Chief ⚑ | BOS's contract; the boss grab (`PlayerStates.swift:371`, `PlayerState.swift:196`); its `killProc` case, step-7 row, Smite entry | `World/Enemies/Chief.swift`, `Player/PlayerStates.swift` | scripted kill test; level-18 arena rows (second bound −640) |
| 6A-MC conversations + chapter cards for 10–22 | the `Mcnv` ids and cards LL lists; the resources loaded as the original | `Front/StageScreens.swift`, `Talk/` | the card goldens |
| 6A-END phase end | GE both shells over levels 1–22, Proof B, the Fable cross-check, both builds staged, the card → Ben (a new QUESTIONS item) | — | — |

## Wave 6 — Phase 6B (cards; expanded in this file by its planning run)

Gate: **"through the Wizard and the fire"** — levels 25–52 playable.

| card | what |
|---|---|
| 6B-WZ Wizard ⚑ | BOS's contract (eleven states, projectiles); level 25's arena bounds 592 / 1384; OmniPx on 25 (built by OX); `killProc` case, step-7 row, Smite entry |
| 6B-ICE levels 30/31 | the level-wide liquid flag `0x26cd`, ice friction 220, the ice types (LL) |
| 6B-TM countdown digits (level 40) | `.UpdateDigits`, the 2907 timer, the digit Effect ids |
| 6B-CA CLUT animation ⚑ | `.AnimateCLUT` (bosses-3 §9): levels 50, 51 (and 67 later) — a Render-side op on the current CLUT |
| 6B-AS auto-scroll ⚑ | `0x2726`–`0x272a`, the marker sprites of `.SetupLevelSprites`, `.FindUpperLeftCorner`'s arm; levels 51 (x), 52 (y) |
| 6B-FI fire backdrop + flame buffer ⚑ | `.LoadCoolingMap`, the eight flame routines, `.DoubleBlitPPCParallaxOneLayerFire`, `.MyRandom` (its own generator); level 52 mode 1 |
| 6B-BG2 / BX2 / BN2 | the Background / Box / Bonus / Platform / Rope types first placed on 25–52 (LL) |
| 6B-L25…L52 levels enterable | 25, 30, 31, 40, 45, 50, 51, 52 (geysers 1442 on 50/51 and the Salamander on 50 are built) |
| 6B-MC | conversations + cards for 25–52 |
| 6B-END | phase end, gate card → Ben |

## Wave 7 — Phase 6C (cards)

Gate: **the whole game** — levels 55–70, the Fire Guardians, Xichra, victory.

| card | what |
|---|---|
| 6C-DM Fire Guardians ⚑ | BOS's contract: two guardians (partner at x − p3·32), segments, fire mode 2 backdrop; the arena never locks (bosses-3 §11); +1000 score each; `killProc` cases, step-7 rows, Smite entries |
| 6C-BG3 / BX3 / BN3 | the 36 types of level 62 and the rest (LL): Background ×16, Box ×8, Bonus ×8 … |
| 6C-L55…L70 levels enterable | 55, 62, 67, 70 (the Wraith and the Crab are placed on 62 — built); level 70's OmniPx interlace (mode 6, `.InterlaceBlit128`) ⚑. **The map's node ≠ level on two nodes** (node 60 → level 62, node 62 → level 67; return to the map uses `FindCurrNode(hdr+0x26c4)`): one level test walks 40 → 60 → 62 once (levels 62 / 67). Optional: one save-block round-trip on level 62 through `savePointSave` and `restoreSnapshot` |
| 6C-XL Xichra's lair ⚑ | the three cannons, the minions (0x6d6, record 500), the lair gates (p1 = 0), the CLUT animation of 67 (bosses-3 §8) |
| 6C-XI Xichra ⚑ | BOS's contract: float, wings, phases, `.DoXichraShot`, `.UpdateXichraCannons`; the kill sets the victory flag (`*_DAT_1009ffc4`, M l. 77190) and ends the game |
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
