# Plan — Ferazel's Wand Phase 5 "Enemies": every enemy class, enemy shots, damage both ways, particles in full, the underwater tint, level 5 up to the Warrior's arena; Ben's Q15 safety checks first — 2026-10-30

> Status: **DRAFT — planner Opus 5.5, loop run 36 (2026-10-30), unattended; two Opus review legs ACCEPT_WITH_FIXES,
> fix round 1 applied (see "Review ledger"); the FABLE-GRADE plan leg owed** (D34 as amended 2026-10-13). Implements
> `docs/plans/2026-10-06-ferazel-design.md` (APPROVED) **§8 row 5** ("Enemies: ground, flyers, water/cave classes,
> enemy shots, damage, particles in full, effects"; Ben's gate "through the first boss door") + **§9 (b)** (geysers NR
> 2–4) + the enemy half of **§9 (c)**, written against what Phases 1–4 and Phase W landed (Classics main **6a70bce**:
> D38 as built, D39–D43 as built, Ben's attended sessions of 2026-10-29/30 — the teleporter sparkle, the re-seat, the
> light-806 shrink, the rope faces, every boot face, the Continue refusal, the gap ledger, the visit sweep;
> `Ferazel/Core` **502 = 501 passed + 1 skipped**; FerazelWinKit **79 = 78 passed + 1 skipped** (the seat's GW2, 2026-10-30); HectorKit 35a85ba, floor 361).
> **Format (Ben, 2026-10-03): CONTRACTS, not code.** Files, public names (signatures only where they pin a seam),
> behaviour with bank + dump anchors, test names with what each checks, gate commands, commit messages. No Swift bodies.
> **Grounding.** Phase 3's research digests A–F were **never committed**. This plan is grounded on the bank
> (`docs/ferazel/`), the committed dump (`ghidra/ferazel/Ferazel_pef.decompiled.c`, 88,106 lines, cited "M l. N";
> `Ferazel_pef.disasm.txt`, cited "raw XXXXXXXX"), the committed gap ledger (`docs/ferazel/port-gap-ledger.md` +
> `docs/ferazel/gap-ledger/*.tsv`, in particular `placements-all.tsv`), the current code, and the planner's throwaway
> census scripts (not committed; results in "Research notes"). **Every function span cited here was computed from the
> committed dump's `// ==== name @ addr ====` headers on 2026-10-30** (Research note 1); the individual M lines quoted
> were re-read in the dump that day. The bank's "handler l. N" / "h. l. N" / "m. l. N" numbers come from older dumps —
> **use the spans here and the raw addresses, never the bank's line numbers**. Where the dump disagrees with the bank
> or with this plan, **the dump wins** (Ben 2026-10-07, "follow the binary"); the task's "As executed" note records it.
> **Standing brief for every task (copy into each implementer and reviewer prompt):** *re-read each cited M line in the
> committed dump before coding; the dump wins; record any disagreement in the task's As-executed note.*

**Lockstep — Phase W Ruling 16, copied verbatim (D43; Ben's Q10 → D41):**

16. **Lockstep (D41) — the standing contract for Phase 5 onward** (copied into every later plan's preamble):
    (a) a task that changes what the Mac app shows or does — `Ferazel/App`, `Ferazel/Shared`, a new `ShellRequest` /
    `FerazelDialog` case, a new text face, a new data file — carries its Windows side in the same task (FerazelWinKit /
    FerazelWin change + GW2 tests + GW3), and its Files list names both; (b) a Core-only task runs GW1, GW2 and GW3 and
    G5 — a Core API change can break the shared files, the Windows package or the Mac app without touching them (the
    run-25 lesson); (c) a change to `Ferazel/Shared` is reviewed for
    both shells; (d) a text-path change re-runs `fz-bake-font` and commits the `.fzfont` files (the staleness test fails
    otherwise); (e) every phase end stages both builds (`tools/stage-ferazel.sh` + `tools/windows/stage-ferazel-win.sh`)
    with ONE gate card that has a Mac part and a Windows part, and the Fable phase review covers both diffs.

How it lands here: **every task** runs G2 + GW1 + GW2 + GW3 + GW4 + GW-symlinks + G-MUTE + G5 (Core-only ones too, (b);
GW4 because GW2's `swift test` builds the test bundle and FerazelWinKit, not the `FerazelWin` executable's own sources —
only GW3 (cross) and GW4 (Mac SDL) compile those); a
task whose Files name `Ferazel/App`, `Ferazel/Shared` or `Ferazel/Windows` names both shells' files. Almost all of
Phase 5 is Core + FerazelRender, which both shells run unchanged (the renderer and the screen gamma live in
FerazelRender — `ScreenSurface`/`ScreenGamma`; both shells present that surface), so the Windows side of most tasks is
"nothing to change, GW1–GW3 green". GW2's ladder moves only when FerazelWinKit changes (PB, RB). The phase end (A5)
runs GW5 + GW6 + GWB + G9M, stages both builds, and writes one gate card with a Mac part and a Windows part.

**Goal.** The enemies of levels 1–5 come alive the original's way — they walk, patrol, sleep and wake, chase, leap,
throw axes and boulders, thrust spears, spit, swarm, block, flee — they hurt Ferazel on contact and with their shots
(knockback, blood, lost coins, the shield's block and reflection), and they take damage from every spell, the held
weapons, crushing boxes, statues, explosions, liquids and the Ring of Smiting, then die the original's way (death
frames, the burn-away, the corpse raft, coins, score, the enemies-defeated stat). Every **non-boss** enemy class is
transcribed now, also the ones first placed after level 5 (Dillo, Gremlin, Wraith, Salamander, Crab, the enemy pipes,
the geysers), because no later phase owns them (Phase 6 is bosses). The underwater screen tint and the Magical
Shield's crouch picture, missing since Phases 2/4, are built. Level 5 "Manditraki Warrior" opens: its moving
backdrop, the arena that locks behind Ferazel with the camera pan, the closed gate, the boss music rule — with the
Warrior itself a stand-in that stands and hurts on contact (Phase 6 builds the fight). **Ben's gate: "through the
first boss door"** (Ruling 2 reads it). And before any of that, **Ben's Q15**: the sparkle's random-number drift, a
standing draw-mode audit, a random-play bot on both shells, and the reviewers' open items — so the phase cannot end with
a picture the renderer refuses (both shells quit on a refusal).

**Scope (D44, recorded at merge; "Rulings" is the full text).**
- **In:** design §8 row 5 in full; §9 (b); §9 (c)'s enemy-drop half; every `// later: Phase 5` stub in the tree
  ("Carries owned"); Q15 items 1–5 and 6's code items; gap-ledger items #2 (= Q15 1), #3 (empty-inventory box); the
  underwater tint; the Magical Shield crouch face; `BuiltLevels` → 1...5.
- **Out (named):** the bosses' Handles, Hits, Kills and projectiles' *spawners* (Phase 6; the Warrior's Setup is
  built, its Handle is ◇ — Ruling 3); `.Victory`; every level-feature first used on level ≥ 10 (OmniPx modes 1/3/6/7
  and the rain, the fire and rippling backdrops, the horizon strip's draw mode 8, wind, auto-scroll, programmed-path
  cannons and maces, the countdown digits, water kinds 206–209 — Phase 6 opens those levels); Box/Background types first
  placed on levels ≥ 10 other than the geysers and enemy pipes (Phase 6); gap #4 voice eviction (a recorded deviation,
  Ruling 10); the QuickDraw shrink rule (a QUESTIONS item for Ben, not a task — Q15 item 6).

**Architecture (design §3, unchanged in shape).** `FerazelCore` gains the enemy classes as Swift transcriptions in a
new folder `World/Enemies/` (one file per class or pair: `EnemyCommon`, `EnemyShot`, `Walker`, `AxGoblin`,
`CrawlerRoach`, `Dillo`, `Bat`, `GremlinFloater`, `FrogSalamander`, `BlobCrab`, `Warrior`), the burn-away
(`Particles/Burn.swift`), the geysers and pipes in `World/Movers/BoxSprite.swift`'s arms (+ `World/Movers/Geyser.swift`),
the boss arena (`Camera/BossArena.swift`), the OmniPx state (`Frame`-free, `World/OmniPx.swift`) and the underwater
tint (`Player/PlayerLiquids.swift`). `FerazelRender` gains the OmniPx compositing, the burn's top clip in the blitter
(the clip seam exists), the darkness over-read case, and the audit/bot test harnesses. The App and the Windows shell
change only through the test harnesses (PB, RB) and the shared driver's closure wiring (SP, `Ferazel/Shared`). **HectorKit: untouched** (Ruling 13).

**Tech:** Swift 6.4 / Xcode 27 beta, SwiftPM tools 6.0, XCTest, macOS 15 (Core) / macOS 26 (Windows package), xcodegen;
the Windows cross toolchain at `~/Developer/Toolchains/windows-cross/` (Phase W).

**Paths:**
```
WT      = /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/<lane worktree>   (branched from Classics main)
HK      = /Users/andiyar/Developer/HectorKit   (main 35a85ba, zero-skip FLOOR 361; read-only this phase)
SCRATCH = the executing session's scratch directory (mktemp -d)
DUMPS   = $WT/ghidra/ferazel/Ferazel_pef.decompiled.c ("M l. N"), Ferazel_handlers.decompiled.c,
          Ferazel_pef.disasm.txt ("raw XXXXXXXX") — committed; never regenerated in this phase.
          Function finder: python3 $WT/ghidra/find_func.py '<regex>' --file <dump>   (--func <exact name> prints one)
          Bank tools: FZ_PEF=$WT/ghidra/ferazel/Ferazel_pef python3 $WT/docs/ferazel/tools/{const,pef,tocrefs,rsrc_census}.py
          Gap-ledger tools: $WT/tools/ferazel/gap-{markers,routines,placements,resources}.py (re-run recipes: ledger §5)
CORE    = $WT/Ferazel/Core/Sources/FerazelCore      RENDER = $WT/Ferazel/Core/Sources/FerazelRender
TESTS   = $WT/Ferazel/Core/Tests/{FerazelCoreTests,FerazelRenderTests}
APP     = $WT/Ferazel/App     SHARED = $WT/Ferazel/Shared     WIN = $WT/Ferazel/Windows
```
(Files lists are relative to `Ferazel/Core/` unless they start with `Ferazel/`, `tools/` or `docs/`.)

---

## Verification model (read first)

**Machine gates — executors close these alone** (copy the fenced commands literally):

| # | gate | expected |
|---|---|---|
| G1 | HectorKit | clean at `35a85ba`, floor 361, untouched by every task |
| G2 | `Ferazel/Core` suite | total = the task's ladder number; **0 failed**; skipped = **exactly the opt-in list** (Ruling 8): `VisitSweepTests testVisitEveryObject` until RB, then also `RandomPlayTests testRandomPlay` |
| G3 | census | `0`, `Totals: items 1,108 decoded, failures 0` (every wave end) |
| G5 | Mac app builds | `** BUILD SUCCEEDED **` — every task (Ruling 16 (b)) |
| G6 | scope fence | ⊆ the task's **Files** (+ `docs/DECISIONS.md` / the bank file its BC names / the plan's own "As executed" note) |
| G7 | layering | the greps empty (`Sources/ferazel-census` excluded); G7b no `UserDefaults`/`NSSavePanel`/`NSOpenPanel` in `Ferazel/Core/Sources` |
| G8 | file hygiene | `git -C "$WT" status --porcelain --ignored -- Resources ghidra` prints nothing new; tests write only under the temporary directory |
| G10 | clean tree per commit | empty |
| GW1 | Core + tests cross-build | exit 0, then `2` |
| GW2 | FerazelWinKit (macOS-hosted) | total = the Windows ladder; **0 failed**; skipped = exactly the opt-in list: `WinVisitSweepTests testVisitEveryObjectThroughWinGame`, from RB also `WinRandomPlayTests testRandomPlayThroughWinGame` |
| GW3 | the game cross-builds and links | exit 0, then `1` |
| GW4 | the Mac SDL development build compiles (`swift build --product FerazelWin`) | last line `Build complete!` — every task (GW2 does not build the `FerazelWin` executable target) |
| GW-symlinks / G-MUTE / G7W | Phase W's | empty / `1` then `1` / empty |
| GWB | Proof B (launch gate, by day, muted) | `proof-b: P passed / 0 failed / S skipped / 0 crashed (of N)`, N = the Core ladder at that commit, S = 1 (Wine) + the opt-in count, P = N − S (Ruling 8; PB teaches the script the opt-in list) |
| GW4R / GW5 / GW6 / G9M | Phase W's (launch gates) | as Phase W (GW6: the three "identical" lines; references from PB's in-process pins) |
| **GE** | **phase-end three checks** (Q15, Ruling 6) | visit sweep `both` exit 0 · random-play bot `both` exit 0 · the load-every-face tests (`BootFacesTests`, `FaceTests.testEverySpawnableTypeHasSheet`, inside G2) pass · plus DA's audit inside G2. **A phase cannot close while any fails.** |

```sh
WT=$PWD; SCRATCH=$(mktemp -d)
WINB=$HOME/Developer/Toolchains/windows-cross/build/ferazel   # never the default root (Phase W Ruling 19)
# G1 HectorKit untouched
git -C ~/Developer/HectorKit status --porcelain; git -C ~/Developer/HectorKit log --oneline -1      # empty; 35a85ba
# G2 suite: (1) the ladder total, (2) 0, (3) exactly the opt-in skip lines (one before RB, two from RB)
cd "$WT/Ferazel/Core" && swift test > "$SCRATCH/fz.log" 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/fz.log"
grep -cE "^Test Case '.*' failed \(" "$SCRATCH/fz.log"
grep -oE "^Test Case '[^']*' skipped" "$SCRATCH/fz.log" | sort
#   before RB:  Test Case '-[FerazelRenderTests.VisitSweepTests testVisitEveryObject]' skipped
#   from RB:    + Test Case '-[FerazelRenderTests.RandomPlayTests testRandomPlay]' skipped
# G3 census (every wave end, and whenever Resources/ or a decoder changes): 0 and the Totals line
cd "$WT/Ferazel/Core" && swift build -c release --product ferazel-census > /dev/null && "$(swift build -c release --show-bin-path)/ferazel-census" "$WT/Resources/Ferazel" > "$SCRATCH/census.md"; echo $?; tail -n 1 "$SCRATCH/census.md"   # 0 / Totals: items 1,108 decoded, failures 0
# G5 Mac app builds (every task): ** BUILD SUCCEEDED **
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
# GW2 the Windows package's macOS-hosted tests: (1) the Windows ladder, (2) 0, (3) exactly the opt-in skip lines
cd "$WT/Ferazel/Windows" && swift test > "$SCRATCH/fw.log" 2>&1
grep -cE "^Test Case '.*' (passed|failed|skipped) \(" "$SCRATCH/fw.log"
grep -cE "^Test Case '.*' failed \(" "$SCRATCH/fw.log"
grep -oE "^Test Case '[^']*' skipped" "$SCRATCH/fw.log" | sort
#   before RB:  Test Case '-[FerazelWinKitTests.WinVisitSweepTests testVisitEveryObjectThroughWinGame]' skipped
#   from RB:    + Test Case '-[FerazelWinKitTests.WinRandomPlayTests testRandomPlayThroughWinGame]' skipped
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

Launch gates (Phase W Ruling 15 + D42: by day only, muted, each behind the guard; a run outside 09..20 skips them and
writes "boot check owed (night rule)" in LOOP-LOG and on the gate card):
```sh
# LAUNCH GUARD
h=$(date +%H); (( 10#$h >= 9 && 10#$h <= 20 )) && echo "launch ok ($h)" || echo "boot check owed (night rule) ($h)"
# GWB Proof B (every wave end that touches Core or Windows, by day; run once whole)
"$WT/tools/windows/proof-b-ferazel.sh"          # proof-b: P passed / 0 failed / S skipped / 0 crashed (of N) — Ruling 8
# GW4R the Mac SDL development build, headless (only through the smoke script)
"$WT/tools/windows/smoke-ferazel-win.sh" --mac-only
# GW5 stage (A5; any hour)
"$WT/tools/windows/stage-ferazel-win.sh" --no-desktop; echo $?
# GW6 the staged zip boots in a clean CrossOver bottle, muted (A5): three "identical" lines, exit 0
"$WT/tools/windows/smoke-ferazel-win.sh"
# G9M the Mac staged app boots MUTED (A5)
APP="$WT/out/Ferazel/Ferazel's Wand.app"; open -n "$APP" --args -FerazelMute YES; sleep 5; pgrep -fl "Ferazel's Wand" | cut -c1-100; osascript -e 'tell application "Ferazel'"'"'s Wand" to quit'; sleep 2; pgrep -fl "Ferazel's Wand"; ls -t ~/Library/Logs/DiagnosticReports | head -n 3
```

Phase-end checks (GE; headless, no window, no audio — allowed at any hour, D42; A5 and the named wave ends):
```sh
OUT=$SCRATCH/visit tools/ferazel-visit-sweep.sh both > "$SCRATCH/visit-sweep.txt" 2>&1; echo "exit $?"      # exit 0
OUT=$SCRATCH/bot   tools/ferazel-random-play.sh both > "$SCRATCH/random-play.txt" 2>&1; echo "exit $?"     # exit 0 (RB)
grep -E "^== (core|windows):" "$SCRATCH"/visit-sweep.txt "$SCRATCH"/random-play.txt                         # summary lines → gate card
#   (the visit sweep's runner prints `== core: …` / `== windows: …` (tools/ferazel-visit-sweep.sh:75); RB's runner
#    prints the same fixed shape: `== core: random play — levels L, seeds S, steps T, deaths D, exits E, conversations C,
#    saves V, failures F in W s` and the same for `windows`)
```

**Ladders** (canonical order = execution order; STOP if different; merged in another order: previous + the task's N):

| after | `Ferazel/Core` (G2 total / skipped) | FerazelWinKit (GW2 total / skipped) | run |
|---|---|---|---|
| base (6a70bce) | **502** / 1 | **79** / 1 | — |
| PB | 502 / 1 | 80 / 1 | 1 |
| SP | 505 / 1 | 80 / 1 | 1 |
| RV | 508 / 1 | 80 / 1 | 1 |
| DK | 510 / 1 | 80 / 1 | 2 |
| UT ◈ | 513 / 1 | 80 / 1 | 2 |
| DA | 515 / 1 | 80 / 1 | 2 |
| RB ⚑ | 517 / **2** | 81 / **2** | 3 |
| EC ⚑ | 525 / 2 | 81 / 2 | 3 |
| ES ⚑ | 536 / 2 | 81 / 2 | 4 |
| WK1 ⚑◈ | 545 / 2 | 81 / 2 | 4 |
| CR ⚑◈ | 553 / 2 | 81 / 2 | 5 |
| WK2 ⚑◈ | 559 / 2 | 81 / 2 | 5 |
| BA ⚑◈ | 568 / 2 | 81 / 2 | 6 |
| FR ⚑◈ | 576 / 2 | 81 / 2 | 6 |
| BL ⚑ | 583 / 2 | 81 / 2 | 7 |
| GF ⚑ | 590 / 2 | 81 / 2 | 7 |
| DL | 595 / 2 | 81 / 2 | 8 |
| GY ⚑ | 602 / 2 | 81 / 2 | 8 |
| PI | 606 / 2 | 81 / 2 | 8 |
| OX ⚑ | 611 / 2 | 81 / 2 | 9 |
| LV5 ⚑ | 617 / 2 | 81 / 2 | 9 |
| A5 | 617 / 2 | 81 / 2 | 10 |

Proof B at the phase end: **614 passed / 0 failed / 3 skipped / 0 crashed (of 617)**. Review fix rounds add asserts,
not tests, unless the orchestrator rules otherwise ("As executed").

**Goldens (◈).** Current values (test files at 6a70bce): level 1 first frame `9db8f32f7e3d88b4`, highest tie-break
`b80b0efd384ffdb9`, ports `2ed3103e74e4550b`; pan 30 `b1f4efcf3c34735f`, pan 60 `80d88efdc8fac27c`, chain
`aaab15c0710cbcf7`; level 2 first frame `565e867a02736c18` / `df22325e851e782d`; jump `deb577ecdeb64c58`; swim
`c1dd428a3f146d77`; 600-frame `a8dda9cf3e448016` / cues `28a48762cfff1b2b`; FE0 `ed142fed9e3bdce7`; map first frame
`38563faaa2276f05`; the Windows smoke references (PB pins them in-process): menu `0xae2b1ee08c089b2a` (1,437 wakes),
level 1 first frame `0xc99ce8e85b4bd8f7` (1,865), level-1 text `0xfbb2dd7a1d289726` (3,833); WF2's text reference
`0x908483fb603623e8`. **Only the tasks marked ◈ may move a golden, and only for the cause they name:** UT (the swim
route goes under water — the tint op enters the stream), WK1 / CR / WK2 / BA / FR (that class's Setup completion and
Handle now run on levels 1–2: its `FastRand` draws, faces, sounds, contact damage and coin drops enter the frame). **The
"switch it off" check (each ◈ task, implementer and reviewer independently):** set the class's `SpriteHandler.forClass`
row back to `.inert` and its Setup back to the stub (one local patch, never committed) → **every old value returns**;
then the new values are re-derived twice. Each ◈ task lists every golden's old → new in its commit body and "As
executed", and moves the Windows references in PB's pin test + `tools/windows/smoke-ferazel-win.sh` in the same commit
(GW4R/GW6 confirm by day). Every other task, and a ◈ task for any other golden or cause, **must not move a golden or a
count** (Invariant 10). FE0 and the map first frame must hold for the whole phase.

**Honesty gate (Ben only):** the Phase 5 gate card ("through the first boss door") — Mac and Windows. Completion is
phrased "machine gates green; Ben's gate pending".

**What the machine does NOT prove:** the feel of every enemy's AI at 30 steps a second; the colours of the tint
tables (Walker tiers 0x10..0x15, Crawler 2/3/0xf, statue 0xb — bank NR, Color2Index LOW); the burn-away's look; the
underwater tint's strength on screen (gamma, MED); the OmniPx backdrop's look (MED); sound by ear; agents cannot
screenshot on this machine and never launch to "just look" (D42).

---

## Non-negotiable invariants

1. **Layering** (Phase 4 Invariant 1 + G7b + G7W). Core: Foundation + HectorResources (+ HectorInput) only. Enemy state,
   the counting window, the arena globals, the OmniPx counters and positions are Core state; pixels (the OmniPx port,
   the burn clip, the darkness tables) are Render's; the shells only present, play and pass the playing set.
2. **Transcribe, don't reinvent.** Every behaviour cites its bank section and the dump span. A contract never
   overrides the dump: if they disagree, follow the dump and record it (the plan is wrong against the dump about once a
   task — NEXT lesson 2).
3. **Frame order is the binary's** (design §3.2; enemy-shots-and-damage-2 §4.2): sprites created inside a Handle run
   this frame only if inserted after the saved `next`; a Setup runs inside `.MTNewSprite` before the insert, so its
   draws precede the caller's next draw; **the player is reached only by `.MTCollideSpecialSprite`** (its own `+0x5c`
   is 0) — enemy contact damage is `.HitPlayerSprite`'s, never the enemy's Hit.
4. **One RNG stream** (Phase 2 Invariant 4): every `FastRand` at its call site in the binary's order —
   `STPlay3DSoundRand`'s pitch draw even with sound off; idle-only calls (`FUN_100916dc`) through `SoundVoices`; the
   goblin cries' voice tests and stops are **global over all voices** (enemies-ground-2 §3).
5. **The counting window** (enemies-ground-2 §4): `+0x1b5` and the live-enemy count `_DAT_1009ffb4` are set by a Setup
   **only while `_DAT_1009fe8c` is set** (around `.SetupLevelSprites`, raw `10004da4..10004dc0`). Pipe children, spawned
   shots and re-activated idle sprites are never counted.
6. **Stubs are named** (`// later: <phase>` / ◇), never simplified away; each keeps the original's surrounding draws
   and state. This phase's ◇ are in "Stand-ins kept".
7. **No modern affordances** (D30/D67 standing ruling): no health bars over enemies, no hit numbers, no enemy
   highlighting, no difficulty change, no auto-aim beyond the original's homing.
8. **No refusal reachable** (Q15, Ruling 6): a task that makes a new draw input reachable (a mode, a rotation, a clip, a
   face, a light case, a backdrop) makes the renderer draw it as the binary does **in the same task**, adds it to DA's
   audit table, and names it in "As executed". A renderer refusal reachable from shipped data in a built level is a
   STOP, never a test to skip.
9. **Seam types are LOCKED** (design §3): cases and fields may be **added**, never renamed or retyped (S3 list).
10. **STOP on any unexpected number** — totals, skips, hashes, census lines, the plan's numbers. Report; never edit an
    expectation or the code to make them agree.
11. **Commits.** Explicit paths only; never `git add -A`/`.`; never `git stash`; verify `git branch --show-current`
    before every commit; trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. G10 after each commit.
12. ⚠️ **Landmines** (Phase 2 (a)–(g), Phase 3, Phase 4 (h)–(k) still apply). (l) D-number: this plan's rulings are
    **D44** — confirm free at commit time, renumber in the same commit if taken. (m) `Ferazel/FerazelCore` is a symlink
    to `Core`; the app name has an apostrophe — quote every path. (n) Swift `>>` binds tighter than `&*`/`&+`. (o) A
    `SpriteSlot` copy held across a call that can create or move sprites and written back loses their writes
    (`SpriteWorld.swift` rule 2) — every enemy Handle spawns (shots, coins, corpses, children). (p) Foreground only in
    loop runs (no background shells or agents); never launch outside a launch gate (D42). (q) Ben may commit to local
    main mid-run → rebase before merge.

### Hazards for every implementer (read before any dump reading)
Phase 1–4 hazards apply verbatim (copy loops, TOC-load ≠ write count, SSH zeroes per-frame fields, the signed-compare
idiom, live key reads, globals vs fields, nested blocking loops → explicit states; sound handles are TOC slots — map
pickups-boxes-2 §1.2; colourised CopyBits). Added for Phase 5:
- **Class is the Handle, never the type.** Enemy-shot types reuse the spawner type space (0x6a9, 0x6d6, 0x6f4, 0x709,
  0x712, 0x71f, 0x753, 0x754, 0x771…0x774, 0x77b — enemy-shots-and-damage §1.2 notes); every "is it a Walker?" test in
  the dump compares `+0x4c`. Model it as `SpriteSlot.handler`, never `type`.
- **Exact-type dispatch.** `.HandleWalkerSprite` dispatches on the exact types 1700/1705/1750/1760; other Walker types
  only fall and take hazards and never die (enemies-ground §3.2) — transcribe, do not "fix".
- **`+0x1b2` (pipe emergence):** every class Handle returns at once while set; the sprite is still drawn and still
  collidable as the inner sprite of `.MTCollideSprites` (enemies-flyers §7.4).
- **Idle children:** swarm members and the insect body are `MTNewSprite` children with record 0x200 — never idled,
  never counted; they keep running while their parent is idle (enemies-flyers §7.5).
- **`.IdleToActiveSprite` (M l. 4215–4275) re-runs no Setup:** it calls `.MTNewSprite` with setup 0, restores the
  0x220-byte snapshot, **clears `+0xe9`** (M l. 4264), **writes `+0xa8` = the idle index (its argument, M l. 4265)**, calls the sprite's `+0x58` proc if one is set (M l. 4266–4268),
  and **kills the sprite at once when its restored `+0x4c` is 0 or its type is 0** (M l. 4269–4270) (verified 2026-10-30).
- **The 16-voice pool:** `FUN_100916dc(x)` counts voices playing x (by id or sound pointer; 0 = all);
  `FUN_10091504(x)` stops every such voice (enemies-ground-2 §3) — `SoundVoices` answers the first, `FrameOps`
  stop cues carry the second.
- **No free record (D38 Ruling 16):** a spawn that finds all 700 records in use runs no Setup and makes none of its
  draws; stores to it are dropped; the caller's later draws are still made — every enemy spawner (shots, coins,
  corpses, shards, children).

---

## Shared architecture (LOCKED — every task codes against these names)

### S1. Packages — unchanged targets
New folders `Sources/FerazelCore/World/Enemies/`; tests in `Tests/FerazelCoreTests/Enemies/` (SwiftPM picks up
sub-folders). No new target, no `Package.swift` change in either package.

### S2. FerazelCore additions (★ LOCKED after Phase 5; ◇ = Phase-5 stub, replaced later)
- ★ `SpriteHandler` cases added (EC adds all of them at once so later tasks only fill their bodies; each body is a
  named `// later: <task>` no-op until its task — the Phase-1 `.inert` behaviour, drawn, no Handle, no hit): `.walker`,
  `.crawler`, `.roach`, `.dillo`, `.bat`, `.swarmMember`, `.insectBody`, `.gremlin`, `.floater`, `.frog`, `.salamander`,
  `.blob`, `.deadBlob`, `.crab`, `.crabSegment`, `.enemyShot`, `.geyserSegment`, `.warrior` (◇, Ruling 3). `.inert`
  stays for the four bosses not placed on levels 1–5. `forClass(type:)` maps each class of `SpriteClassTable`
  to its case **in the task that builds the class** (WK1 `.walker`, CR `.crawler`/`.roach`, …) — the switch-off check
  of ◈ is that one row.
- ★ `EnemyCounting` (EC, `World/Enemies/EnemyCommon.swift`): `window: Bool` (`_DAT_1009fe8c`), `live: Int32`
  (`_DAT_1009ffb4`), with `countIfWindow(_ s: inout SpriteSlot)` (the Setup idiom: window → `+0x1b5 = 1`, live + 1) and
  `kill(_ s: inout SpriteSlot, globals: inout GameGlobals, level: Int)` (the Kill idiom, `.KillCrawler` /
  `.KillWalker` / `.KillWarrior` M l. 56695–56700 / 58624–58629 / 73479–73485 (the same test in every enemy Kill): **`+0xe9 == 0 && +0x1b5 ≠ 0`** → live
  − 1, `G+0x306+2·L` + 1; then `+0xe9 = 1` **unconditionally**; `+0xea` only where the class's Kill sets it — an
  uncounted sprite (pipe child, spawned, re-activated) dies with no count and no stat). `LevelRun`/`.SetupLevel`
  opens the window around the level's sprite setup and copies `live` into `G+0x6ee+2·L` as today's totals do.
- ★ `EnemyCommon` (EC): `.HurtSprite` reuse (exists), `hurtGoblin` (`.HurtGoblin`, M l. 58472–58505),
  `goblinRandomCry` / `goblinHurtCry` (M l. 56848–56897 / 56802–56847), `playPitchedGob` (M l. 56773–56785),
  `playRandGob` (`.STPlay3DSoundRandGob`, M l. 56786–56801: a `FastRand(10000)` pitch draw, pitch `+0xf0` + R − 5000 —
  made even with sound off, Invariant 4; also called by `.HurtGoblin` at M l. 58490 / 58494), the
  crush test (enemies-ground §2.3), the liquids table (§2.4), the environmental hazards (Effect 0x4b7 `+0x46 < 8`, geyser
  0x5a0 kinds), `turnIntoStatue` for enemies (wrapping `StatueSprite`, M l. 38244–38272), the burn start
  (`+0x1a2 = 1`).
- ★ `Burn` (EC, `Particles/Burn.swift`): `.HandleBurn` (M l. 38765–38840) + `.BurnFaceRow` (M l. 38514–38663) called
  from `.StandardSpriteCleanup` while `+0x1a2 ≠ 0` (replaces `StandardSprite.swift:94/:124`'s stubs): the top clip
  `+0x1bc` advancing `+0x8d + 1` rows a frame from the opaque top, particles per consumed row, the Kill proc `+0x50`
  when the row passes the opaque bottom `face+0xc` (draw-effects §4.2; particles §5.5).
- ★ `EnemyShot` (ES, `World/Enemies/EnemyShot.swift`): `spawn(type:x:y:layer:)` = `MTNewSprite(type, x, y, layer, −1,
  .SetupEnemyShotSprite)`; Setup / Handle / Hit / HitTile / Kill (M l. 51393–52260); `shieldBlock` (M l. 48359–48444).
- ★ `BossArena` (LV5, `Camera/BossArena.swift`): `noBossAlive` (`_DAT_1009fed0`), `locked` (`PTR_DAT_1009fed4`),
  `panCounter` (`_DAT_1009ff9c`); `.PlayerConstraints`' arena part (M l. 43991–44126) and `.FindUpperLeftCorner`'s
  bounds (M l. 5882–6239) read them; `.SetupLevelSprites` clears `locked` and sets `noBossAlive = 1` before spawning
  (M l. 2016–2019, verified).
- ★ `OmniPx` (OX, `World/OmniPx.swift`): mode (`hdr+0x26c7`), the 16 face refs, fx/fy/vx/vy/accX/accY (16 × i16
  each), the counter `c` (BSS, **never reset between levels** → rides `LevelCarry`), `G+0x174` on-flag (the existing
  `GameGlobals.omniPxActive`, `GameGlobals.swift:67` — reused, not duplicated);
  `setup(level:)` (M l. 13125–13297), `turnOn` (M l. 13019–13060), `update()` (M l. 13393–13519, drawn frames only, at
  M l. 9434 — after `DrawParticles`, before the copy).
- ★ `SpriteSlot` fields added under their offsets (each task documents its own, never two offsets in one field):
  `emerging` `+0x1b2` (EC; written by PI), `burnRow` `+0x1a2` exists, clip edges `+0x1b6/+0x1b8/+0x1ba/+0x1bc` (exist
  as `SpriteClip`), the class fields per task (`+0x14c…+0x170`, `+0x1d4`/`+0x1d8` children, `+0xf0` goblin pitch, …).
- ◇ `BuiltLevels.range` → `1...5` (LV5); report "Level n is not built yet (Phase 6)." (Ruling 2).

### S3. Seam additions (cases/fields ADDED only; Invariant 9)
```swift
// DrawOp — new cases
case omniPx(OmniPxFrame)            // OX: one `.UpdateOmniPx` at M l. 9434 — the base cell and the two faces'
                                    //     (x, y) for this drawn frame; Render composites the 128×128 port
// SpriteHandler — the S2 cases
// FerazelSession / LevelServices — `DiffuseRandoms` keeps its type; SP adds a second closure type
//     `DiffuseRandomsAt = (SpriteDraw, h, v, drawnH, drawnV, inout FastRand) -> Void` used when present (added, not retyped)
// FrontInput, SoundCue, MusicCue, ShellRequest, FrameSuspension, ScreenGammaOp — unchanged (UT uses the existing
//     ScreenGammaOp cases `.fadeToColor(15, rgb)` / `.fadeToColor(100, nil)` — settled in fix round 1, no new case)
```

### S4. FerazelRender additions
`FrameRenderer` executes `.omniPx` (OX: the port as PxBack slot 0 for the backdrop compositor, the factors zeroed for
modes 1–3 and ≥ 8 as `.TurnOnOmniPx` does); `SpriteBlitter` honours the burn's top clip (exists as `SpriteClip.top`)
and the darkness over-read (DK); `diffuseRandoms` walks at the same (h, v, drawn) as the draw (SP). Test harnesses:
`DrawModeAuditTests` (DA), `RandomPlayTests` (RB).

### S5. Shells
Mac App: no change except what G5 shows; `Ferazel/Shared/FerazelDriver.swift` (both shells) passes SP's new closure and
carries LV5's comment range. Windows: `FerazelWinKitTests` gains `WinReferenceFramesTests` (PB) and
`WinRandomPlayTests` (RB); `tools/windows/proof-b-ferazel.sh` and `smoke-ferazel-win.sh` (PB). New
`tools/ferazel-random-play.sh` (RB).

---

## Tasks

Legend as Phase 4: ⚑ MAJOR = **two Opus review legs** (spec/fidelity against the dump, then quality/mutation); minor =
one Opus leg; ◈ = may move a golden (Verification model). "→ N" = Core ladder total after the task. Every task: G1, G2,
G5, G6, G7(+b), G8, G10, GW1, GW2, GW3, GW4, GW-symlinks, G-MUTE, G7W; G3 + GWB (by day) at each wave end. **All implementers
and reviewers are Opus 5.5 (D34).** Each task's precondition: read the named bank sections, then **re-read the named
dump spans** before writing code — *re-read each cited M line in the committed dump before coding; the dump wins; record
any disagreement in the task's As-executed note.*
**Faces of run-time-spawned sprites (Phase 4 B5):** every task that spawns a type at run time (shots, shards, coins,
corpses, children, Effect ids) adds its sheet where the faces are loaded since b535527 — the boot list
`Sources/FerazelCore/Sprites/BootFaces.swift` (`BootFaces`, `.InitSprites`' boot sets; it already holds 0x6a7, 0x6e1,
0x6e2, 0x6e6, 0x45d, 0x454…0x457, 0x71f, 0x753, 0x754, 0x771…0x774, 0x516; it lacks 0x77b, 0x46a, 0x709, 0x712, 0x6f4,
0x744 and the other Bat sets) or the level-load picture cache (`LevelRun.swift` `CachedFaces` (`:1039`) sets/marks,
M l. 73769–73869 `.LoadCachedSpriteFaces` + each class's `.Init*Sprite`) — whichever of the two the original uses for
that set — and names the additions (not `FrameRenderer.swift`, which only consumes the two lists, `:201–:209`); `FaceTests.testEverySpawnableTypeHasSheet` and `BootFacesTests` are
extended by the task (no new test needed for that; asserts inside them).
**Files lists name every flow / renderer / test seam the task touches;** a file found missing is added and recorded in
"As executed" (G6 reads the amended list).
**Every class task also:** wires its class's Statue arm (the Hit routine's branch to `.TurnIntoStatue`; the eleven enemy
statue sites of run 28 — Walker, Crawler, Roach, Dillo, Bat, swarm member, Gremlin, Floater, Frog, Salamander, Blob —
each in its class task), its Smiting reaction (its Hit routine on the Smite explosion 0x4b7, `Smite.swift`), its
liquids and environmental hazards (EC's helpers), its Kill bookkeeping (EC), its idle margins, its picture-cache
marks, and **its save write-back flags** — `+0x188`, `+0x189`, `+0x18a`, `+0x18b` and `+0xea` set at the dump's own
sites in its Setup / Handle / Kill (D38 seat ruling (1): every later Setup sets them where the binary does, Phase 5
enemies included; a test row in the class's Setup test pins each flag the dump writes); runs `tools/ferazel-random-play.sh core` on the levels it brings to life (RB's quick mode, one level, 60 s) and
records the summary line.

### Wave 5.0 — Ben's Q15 first (default (a), item 5 Ben's "yes"), and the two Phase 2/4 gaps that are not enemies

#### PB — minor — Proof B's opt-in skips; the Windows reference frames pinned in-process (→ 502; WinKit 80)
- **Why first:** Ben's visit sweep (8fd0ed6) added a test that skips unless opted in; `proof-b-ferazel.sh` accepts only
  the Wine skip list (`:117–127`), so **Proof B fails today** on a correct suite. And the Windows smoke's reference
  FNVs live only in the script, measurable only by a launch — so a ◈ task by night could not move them honestly.
- **Files:** `tools/windows/proof-b-ferazel.sh` (a second list `optin_skips=(FerazelRenderTests.VisitSweepTests/testVisitEveryObject)`
  — skipped everywhere unless opted in; accepted like `wine_skips`; the pass line requires `skipped == ${#wine_skips} +
  ${#optin_skips}`; the script's `unset` line (`:22`, today `WIN_SWIFT_FLAGS HECTORKIT_PATH FERAZEL_PNG_OUT`) gains
  `FERAZEL_VISIT_SWEEP`, `FERAZEL_BOT` and every `FERAZEL_BOT_*` (by pattern) — Proof B passes the caller's environment
  into Wine, so an opted-in shell would otherwise run the long tests under Wine), `tools/windows/smoke-ferazel-win.sh` (comment: the references are pinned by
  `WinReferenceFramesTests`; values unchanged), `Ferazel/Windows/Tests/FerazelWinKitTests/WinReferenceFramesTests.swift`
  (new), `tools/windows/README.md` (the bar sentence).
- **Contract:** (1) Proof B's verdict: `P passed / 0 failed / S skipped / 0 crashed (of N)`, S = 1 + opt-in count, P =
  N − S; any other skip fails; the opt-in variables are cleared before Wine starts (so the opt-in tests always skip
  there). (2) `WinReferenceFramesTests.testSmokeReferencesInProcess`: a headless `WinGame` in
  `--frames` mode in-process (the `WinSweepGame` / `WinGameTests` rig — scripted host, baked fonts, pinned seed and
  clock, Ruling 20 of Phase W), the three runs of the smoke (menu 1,437 wakes; New Game 1,865 wakes with the smoke's
  key file; the text run 3,833 wakes) → RGBA FNVs equal the script's `menu_fnv`, `newgame_fnv`, `text_fnv`. If the
  in-process rig cannot reach the same frame as the exe's `--frames` path, STOP and report (do not loosen).
- **Tests (WinKit 1):** `testSmokeReferencesInProcess`.
- **Gate:** G2 502 / 1 skip, GW2 80 / 1 skip, GWB by day (expected **500 / 0 / 2 / 0 (of 502)**), the rest per
  legend. **Commit:** `Proof B accepts the opt-in visit sweep skip; the Windows smoke references pinned in-process`.
- **As executed (fix round):** zsh's `unset -m 'FERAZEL_BOT_*'` returns 1 when nothing matches, so under `set -e` the
  script exited silently in the usual case — now `|| true`. Files fence amended: the `--frames` loop moved from
  `Ferazel/Windows/Sources/FerazelWin/main.swift` into `WinGame.runFrames(_:scripted:)`
  (`Ferazel/Windows/Sources/FerazelWinKit/WinGame.swift`), called by both the exe and `WinReferenceFramesTests`
  (behaviour unchanged). Known, left as is: `--class` mode's verdict does not check the opt-in skip.
- **As executed (fix round 2):** Proof B's `--list-tests` step crashed in Windows XCTest (swift-corelibs-xctest casts
  every listed test to `(Self) -> () throws -> ()`; `VisitSweepTests` was `@MainActor`, so its method's type carried
  the main actor and the cast trapped). The class and `testVisitEveryObject` are now non-isolated; the sweep body
  moved into a `@MainActor private static func sweep()` entered with `MainActor.assumeIsolated` (XCTest runs a
  synchronous test on the main thread on both platforms). Skip and opted-in behaviour unchanged; the test's name is
  unchanged, so `optin_skips` still matches. Files fence amended: `Ferazel/Core/Tests/FerazelRenderTests/VisitSweepTests.swift`.
  It was the only global-actor-isolated or async test in Ferazel/Core/Tests. The FerazelWinKit test classes are all
  `@MainActor` too, but they run macOS-hosted only (GW2) and are not in GW1's Windows test exe — left as is.
- **As executed (fix round 3):** Proof B then measured 499 / 1 / 2 / 0: under Wine `BootFacesTests`' scan of Core's
  sources found zero literal face PICTs (its directory enumerator reads file attributes, its matcher was an ICU regex).
  The scan is now one code path on every platform: a recursive `contentsOfDirectory(atPath:)` +
  `fileExists(atPath:isDirectory:)` walk (both already green in Proof B) read once into comment-stripped lines, and a
  pure-Swift matcher with the regex's semantics — a reusable helper RV's computed-id scan can share. The test also
  asserts ≥ 100 Core `.swift` files scanned, so an empty walk is told apart from no matches. Mac: the same 20 PICTs
  before and after. Files fence amended: `Ferazel/Core/Tests/FerazelRenderTests/BootFacesTests.swift`.

#### SP — minor — the sparkle: one scroll for Core's walk and the renderer; the bank's row guard; a teleporter through LevelRun (→ 505)
- **Q15 items 1, 3, 4; gap ledger #2 (A22).** Today `FerazelSession.diffuseSeeds` walks mode-5 draws at the **camera**
  scroll (`FerazelSession.swift:1006–1026`, `camera.scrollH/V`, no drawn pair) while `FrameRenderer` draws them at its
  own scroll with the grid's drawn location (`FrameRenderer.swift:~371`, `wrapDrawSprites(…, h: scroll.h, v: scroll.v,
  drawn: (grid.drawnH, grid.drawnV))`). On passage-jump and teleport-mosaic frames the two differ, so the pixels walked
  — and so the `FastRand` count — differ.
- **Files:** `Sources/FerazelCore/Session/FerazelSession.swift` (the init gains `diffuseRandomsAt: DiffuseRandomsAt? =
  nil`; **both** `diffuseSeeds` call sites change: `:437` (the frame pass — its own (h, v) plus the drawn pair Core
  already emits through `.redrawScrollGrid` / `.redrawEntireScrollGrid` / `.setDrawnScroll`) and `:1008`
  (`wrapDrawSpritesOp`, the passage's and teleport's own wrap — today at `camera.scrollH/V`, **the drift's site**: it
  takes the scroll and drawn pair the renderer will use for that op)), `Sources/FerazelCore/Front/LevelServices.swift`
  (`DiffuseRandomsAt`, S3; `LevelFaces` gains `diffuseRandomsAt: DiffuseRandomsAt?`, added, the old field kept),
  `Sources/FerazelCore/Front/LevelRun.swift` (`:597` passes `faces.diffuseRandomsAt` to the session),
  `Sources/FerazelRender/Frame/FrameRenderer.swift` (`:316` gains a `diffuseRandomsAt` closure with the drawn pair),
  `Sources/FerazelRender/Frame/SpriteBlitter.swift` (`diffuseRandoms(_:h:v:drawn:rng:)`, the old signature kept as the
  drawn = (h, v) case), **`Ferazel/Shared/FerazelDriver.swift`** (`:437` `prepare(level:)` returns `diffuseRandomsAt:
  r.diffuseRandomsAt` — the apps' path, both shells; Ruling 16 (a)/(c): reviewed for both shells, GW-symlinks),
  `Ferazel/Windows/Tests/FerazelWinKitTests/FerazelDriverTests.swift` (an assert in
  `testPrepareAndAttachThroughTheDriver`: `faces.diffuseRandomsAt` non-nil — proves the shared driver passes it; no
  WinKit ladder change), `Tests/FerazelRenderTests/{VisitSweepTests,LevelSweepTests}.swift` (`VisitSweepTests.swift:267`,
  `LevelSweepTests.swift:25/:63` — the test mirrors of the driver pass the new closure too), `docs/ferazel/draw-effects.md`
  (§2.6 — the colour-pass row guard the code follows, as a ⚑ planner note BC51), `Tests/FerazelRenderTests/DiffuseSquashTests.swift`
  (`:211` the session it builds passes the new closure), `Tests/FerazelRenderTests/TeleportLevelRunTests.swift` (new — in
  **FerazelRenderTests**, since it runs a `FrameRenderer`; `FerazelCoreTests` does not depend on FerazelRender).
- **Contract:** re-read `.WrapDrawSprites` (M l. 10221–10397, raw `100144c8..`) for which globals the blit and its
  clip read — `_DAT_1009fe74` / `_DAT_1009fe70` (the grid's drawn location; M l. 10255–10256); **`PTR_DAT_1009fe78`
  (the scroll point) is not read inside `.WrapDrawSprites`** — it reaches the blit only through what the callers set
  (the implementer traces where the scroll the blit uses comes from and records it) — and `.BlitEncFaceDiffuse @
  10029988` (draw-effects §2.3); Core's walk takes **exactly** the (h, v, drawn) the renderer uses for that
  `.wrapDrawSprites` op, in list order, from the same seed. The renderer's replay and Core's walk then consume the same
  number of `FastRand`s by construction; the drift is gone. **Wiring is part of the contract:** a session built with
  `diffuseRandomsAt` uses it and ignores `diffuseRandoms`; one built with only the old closure behaves exactly as today
  (Core-only tests unchanged); the apps (via `FerazelDriver.prepare`), `LevelRun` and every test mirror pass the new
  one. BC51 records the row guard of §2.6.
- **Tests (3):** `testDiffuseWalkUsesDrawnScroll` (a mode-5 draw on a frame where camera ≠ drawn: Core's seed after
  the walk equals a fresh `FastRand` advanced by the renderer's replay count at the drawn pair; at the camera pair the
  counts differ — pins the cause) · `testTeleportThroughLevelRun` (level 1, a `LevelRun` built through a `LevelServices`
  whose `prepare` is the driver's construction, with Ferazel standing on the urn rec 148: the charge to 80, stage 1
  mosaic, the move to rec 149, stage 2, the frames after arrival with the mode-5 sparkle — every op executes in a
  level-1 `FrameRenderer` without a refusal, and the stream after the sparkle frame equals the renderer's replay at the
  drawn pair (so `LevelRun` hands the new closure to the session); the after-arrival sparkle draws at
  `HitPlayerSprite.swift:~456`'s site) · `testPassageJumpSparkleSeed` (a passage jump frame with a sparkle: the stream
  after the frame equals the renderer-consistent count). Plus the WinKit assert above (no new WinKit test).
- **Gate:** G2 505. **Commit:** `Ferazel: the sparkle's random walk at the renderer's own scroll; draw-effects row guard; teleporter through LevelRun; 3 tests`.
- **As executed (loop run 37):** ladder 503 → **506** (Ben's 3cf72df added one Core test before SP). **Where the
  blit's scroll comes from (dump):** `.WrapDrawSprites` reads only the drawn pair `_DAT_1009fe74/fe70` (M l.
  10255–10256), for its cull — which offsets the face rect and the window by the same pair, so it never culls (R4
  correction 1); the scroll the blits clip and wrap at is `PTR_DAT_1009fe78`, read **live inside `.WrapDrawFace`**
  (M l. 10641–10664) — the camera point `.FindUpperLeftCorner` and the re-seats write (the passage/teleport arms set it
  before their 90/120 passes, M l. 49444–49449 / 49659–49664, then copy it into fe74/fe70). The port's renderer
  models it as the last `.redrawScrollGrid` / `.redrawEntireScrollGrid` op's (h, v). **Finding:** at every
  `.WrapDrawSprites` the session reaches today (the frame pass, the passage's, the teleport's stage-2 pass, both
  mosaic preludes) Core has just emitted a scroll op at the camera, so the renderer's pair already equalled the
  camera — the A22 drift is not reachable at this head (the re-seat fix 78e81c3 and the existing snap
  `.redrawEntireScrollGrid` close it); SP makes the agreement hold by construction. **How:** `FerazelSession` notes
  each scroll op it emits (`RendererScroll`: `.redrawScrollGrid` → scroll (h, v) + drawn = `.SetScrollLocation`'s
  clamp, M l. 9488–9499 / 9532–9533; `.redrawEntireScrollGrid` → scroll; `.setDrawnScroll` → drawn) and asks
  `DiffuseRandomsAt` at that state; the old closure path keeps the camera pair exactly. Scroll ops made outside the
  session (`Pause` / `SaveGame` / `LevelRun`'s `(0, 0)` grid) are not noted: each is at the camera or before the
  level's first frame, and the frame pass's own `.redrawScrollGrid` resets both pairs before its sprites.
  `testDiffuseWalkUsesDrawnScroll` therefore builds the camera ≠ renderer case by hand (a `.redrawScrollGrid` at
  sparkle x + 50 handed to both, `noteRendererScroll`); `testPassageJumpSparkleSeed` runs level 2's passage 43 → 44
  with the charge held at −40 (no level has a passage on a sparkle frame by itself). Mutation checks (not committed):
  walking at the camera pair fails `testDiffuseWalkUsesDrawnScroll`; `LevelRun` not passing the closure fails
  `testTeleportThroughLevelRun`. No golden or count moved.

#### RV — minor — reviewer open items (Q15 item 6) and the empty-inventory box (gap ledger #3) (→ 508)
- **Files:** `Sources/FerazelRender/Faces/LightFaces.swift` (`:69` comment: light faces load at boot from
  `.InitSprites`' list, not at level setup — re-read M l. 103–147), `Tests/FerazelRenderTests/BootFacesTests.swift`
  (the source scan also finds **computed** sprite pict ids: `pict: 0x… + …` / `+ p1` forms — e.g. the boulder `0x6e1 +
  p1`, the balloons, the held items — by a second regex over `Sources/FerazelCore`, each resolved by the class's
  declared ranges), `Sources/FerazelRender/Frame/StatusBar.swift` (`:188` — the selection −1 case),
  `Tests/FerazelRenderTests/StatusBarTests.swift`.
- **Contract (gap #3, follow the binary):** `.UpdateItemStat` (M l. 4674–4841, re-read 2026-10-30: icon index
  `*(short*)(G + sel·10 + 0x24)`, sheet choice `*(char*)(G + sel·10 + 0x2c) == 1`, count `*(short*)(G + 0x26 + sel·10)`)
  with the selection `G+0x172 = −1` reads `G+0x1a` (icon), `G+0x22` (sheet), `G+0x1c` (count) — whatever the replica's
  G image holds there (the save-block layout, SV1; never-written bytes are 0, Phase 3 Invariant 7) — and draws that
  cell as for any selection. The empty box is replaced by the binary's read; the look goes to Ben as a non-blocking
  check (Open question 4). The other Q15 item ("newly loaded faces may change box hot-rects / particle emitters") is
  its own test (a separate test, ladder +1 — not an assert folded into another): every hot rect / emitter source for
  levels 1–4 equals the value before b535527 or the change is listed in the test with its cause.
- **Tests (3):** `BootFacesTests.testComputedFacePictsAreLoaded` · `StatusBarTests.testEmptyInventoryReadsTheGap`
  (selection −1 with G+0x1a = 2, G+0x1c = 3 → icon cell 2 and "x3"; all zero → cell 0, no count) ·
  `BootFacesTests.testHotRectsAndEmittersUnchangedByBootFaces` (every level 1–4 record's hot rect and every particle
  emitter's source face, with the boot faces loaded, equals a table pinned from `b535527^` (the tree before the boot faces landed) — derived by
  the implementer from that commit's code, re-derived by the reviewer; any differing row is listed with its cause).
- **Gate:** G2 508. **Commit:** `Ferazel: computed face ids in the boot-face scan, the empty-inventory box as the binary reads it, hot rects and emitters pinned across the boot faces, LightFaces comment; 3 tests`.
- **As executed (loop run 37):** ladder 506 → **509** (Ben's 3cf72df, one higher than planned). **Dump re-read:**
  `.UpdateItemStat` M l. 4674–4841 agrees with the contract (sel −1: icon G+0x1a, sheet byte G+0x22, count G+0x1c; a
  count is drawn only when `1 < count`, M l. 4720, so 0 and 1 draw none); `.InitSprites` M l. 103–147 calls every
  `.Init*Sprite` that loads a light face (`.Load1LightFaceFromPICT` callers M l. 50257–56147) — boot, as the
  comment now says. **Gap #3:** the selection −1 case moved from `StatusBar.swift:188` to `:207` (3cf72df); the empty
  box is gone. Files fence amended: `Sources/FerazelCore/Seams/StatusBarState.swift` (a field added, S3:
  `gapSlot`, "slot −1" = G's bytes +0x1a…+0x23) and `Sources/FerazelCore/Session/GameGlobals.swift` (`gapSlot`
  as `image()` writes those bytes — +0x20 the darkness override byte, +0x22 the saved darkness's high byte, the rest
  0 — and `statusBar(levelName:)` hands it over) — the renderer has no G, so the read needs the seam. In practice the
  replica draws item cell 0 of 702 with no count. No golden or count moved (no golden has an empty inventory).
  **Computed face ids found** (Core's sources, the same Wine-safe walk; the literal matcher now also reports
  `<lit> + …` / `<lit> &+ …`): `0xc80 &+ k` (the thought balloon's key icon, keys 1…26 → 3201…3226) and `750 + item`
  (the held item → `HeldItem.sheets` 750, 756, 768, 771); both boot faces, loaded on levels 1–4. The plan's boulder
  `0x6e1 + p1` is not in the tree yet (the spouts' spawn is ◇, AxGoblin is WK1's) — the test's "every form has a
  declared range" assert will make that task add its row. **Hot rects and emitters:** measured at `b535527^` and at
  HEAD with the same row text (git archive into a temp dir, a scratch test, not committed): levels 1–4 at the start
  and after 30 and 120 idle frames, 3,257 rows (every active sprite and idle entry: type, record, hot rect, idle face
  rect, face, `faceBounds`, `particleFaces.sprite` digest) — **no row differs**; every faced row's face was loaded
  before the boot faces too. Pinned as 12 (count, FNV-1a) pairs. Mutation check (not committed): `faceBounds` top + 1
  fails it. The gap ledger tracks no per-item status line, so it is untouched. Extra doc item (SP review, fence
  amended): `draw-effects.md` §2.6 BC51 — the row counter starts at 0 (`li r30,0x0`, raw 10027328), not at the first
  source row, as `SpriteBlitter.squashWalk` has it.

#### DK — minor — the lit sprite at full darkness under the brightest light (ledger A13) (→ 510)
- **Why now:** A13 is a latent quit: a `+0x89` dynamic-lit sprite on a light-15 cell under a colour-99 light. Phase 5
  makes things move on level 4 (the only level with light-15 cells) — thrown boulders 0x6e1/0x6e2 and spout boulders,
  corpses, bats — so it can become reachable; build it before. **Where it is refused today:** darkness 15 passes the
  `ambient` guard (`SpriteBlitter.swift:571`, `Refusal.darkness`); with F = 110 the light index base = 15·0x6e00 +
  110·0x100 = 0x6e000 = the light table's whole size, so it is refused at `:577` (`Refusal.mode`).
- **Files:** `Sources/FerazelRender/Frame/SpriteBlitter.swift` (`:569–:579`, the mode-0xc arm),
  `Sources/FerazelRender/Frame/LevelTables.swift` (the light table `_DAT_100a0134` and ambient `_DAT_100a0130` as one
  contiguous view for the over-read; `:42–:44`), `Tests/FerazelRenderTests/LightingTests.swift`.
- **Contract (settled from the data section, Leg A fix round 1):** lighting-tables §7 + draw-effects §2 (mode 0xc).
  The TOC slots point into the data section at: `0x100a0134` (light) → data+0x5c52c, size 0x6e000 (16 × 0x6e00);
  `0x100a0130` (ambient) → data+0xca52c = **exactly the light table's end**, size 0x1000 (16 rows × 0x100); the next,
  `0x100a0120`, → data+0xcb52c (checked with `docs/ferazel/tools/pef.py` `u32`, 2026-10-30). So the original's
  `light[L·0x6e00 + F·0x100 + i]` at L = 15 and F = 110 + k (k 0…15) reads **ambient row k** (`ambient[k][i]`) — the
  bytes that follow in memory. The port reads exactly that: for an index ≥ 0x6e000 and < 0x6f000, ambient row
  `(index − 0x6e000) >> 8`. **Past F = 125** (index ≥ 0x6f000) the original runs into the table at data+0xcb52c (slot
  0x100a0120) — **kept a refusal** (`Refusal.mode`, listed in DA's table with its unreachability reason: the
  implementer derives F's maximum over the built levels from `.GetFakeLight` M l. 15290–15359 and
  `.CalcAmbientDarken` M l. 13655–13689 and records it; if F > 125 is reachable from shipped data, STOP). No clamp.
- **Tests (2):** `testDynamicLightAtFullDarknessReadsFollowingTable` (L 15, F 110 → ambient row 0; F 125 → ambient row
  15; F 126 → still refused) · `testA14LightByteMinusOneStillRefused` (pins A14 as still refused — DA proves it
  unreachable).
- **Gate:** G2 510. **Commit:** `Ferazel: mode 0xc at full darkness reads the ambient table that follows the light table, as the original; 2 tests`.
- **As executed (2026-10-30, loop run 38):** G2 **511** (the +1 after Ben's 3cf72df, as run 37 recorded), 0 failed,
  the one opt-in skip; no golden or other count moved. **F max = 110**, derived from the dump: `.GetFakeLight` (M l.
  15290–15359) gives k = 0xb − dist·11/r kept in 0…11 (k = 11 at a distance under r/11 — the bank's "k 0..10" is
  short by one), plus the slot colour `+0x18`; every live colour writer is ≤ 99 (AddLight constants 0x16…99 incl. 0x58
  at M l. 52562, `.ChangeLightColor` 0/0x21/0x42/0x4d), the only data-sourced colour (M l. 54143, record p1) is the
  dead 0x726 arm. So index ≥ 0x6f000 (F ≥ 126) is unreachable and stays `Refusal.mode`. `.CalcAmbientDarken` (M l.
  13655–13689) builds the table colours and does not bound F (cited by the plan, no bearing). TOC slots re-checked with
  `pef.py`: 0x5c52c / 0xca52c / 0xcb52c, as the contract. Built as `LevelTables.followingLightRow(at:)` (ambient row
  for a base in [0x6e000, 0x6f000), nil past it) called from the mode-0xc arm only when the light read would leave the
  table — the light table itself is unchanged, no contiguous copy. Bank: ⚑ note appended to lighting-tables (k 11,
  the 0x58 writer, F max). Tests also pin F 111, F 109 (light's last row), L 14 F 110 (inside), F 0 → ambient 15,
  F 0xff refused, the drawn frame bytes, and A14 for F 1/11/110 plus L −1 F 0 → mode 0.

#### UT — minor ◈ — the underwater screen tint (Phase 2 carry, D38 A4 ruling) (→ 513)
- **Files:** `Sources/FerazelCore/Player/PlayerLiquids.swift` (`:137–139` stub), `Sources/FerazelCore/Player/Player.swift`
  (`:360` comment) — both labelled `// later: no Phase-2 seam…` (`:139`, `:360`), not `later: Phase 5`, so A5's grep
  cannot see them: UT removes both labels when the tint lands, `Sources/FerazelCore/Player/PlayerState.swift` (the flag `PTR_DAT_100a066c`),
  `Sources/FerazelCore/Front/ScreenFade.swift` (the `fadingEnabled` gate `DAT_100a53c2`),
  `Tests/FerazelCoreTests/LiquidHazardTests.swift`, `Tests/FerazelRenderTests/Phase2GoldenTests.swift` (◈ values),
  `Ferazel/Windows/Tests/FerazelWinKitTests/WinReferenceFramesTests.swift` + `tools/windows/smoke-ferazel-win.sh` (◈
  Windows references, **if they move** — none of the three smoke runs is expected to enter water; record "not moved").
  **No `ScreenGammaOp` change** (the existing cases express it — below).
- **Contract:** row 41 of `.HandlePlayerSprite` (M l. 46449–46476, re-read 2026-10-30): `+0x11c` in 1…9 and the flag
  clear → rgb by `+0x128` (1 → green 64000; < 1 and ≥ 0 → blue 64000; 2 → red 64000; else black), `.TintScreen(&rgb,
  0xf)`, flag 1; `+0x11c` > 10 or 0 with the flag set → flag 0, `.TintScreen(0, 0)`. `.TintScreen` (M l.
  31704–31727): only while `DAT_100a53c2` (fading enabled); nil → `MT_FadeToColor(0, 0, 100, 1, 1)`, else
  `MT_FadeToColor(0, &rgb<<16, n, 1, 1)`. **Mapping (settled, Leg A fix round 1, MED):** `.MT_FadeToColor` (M l.
  79455ff) with a 1 ms duration and the linear flag reaches the full percent at once (`uVar13 = param_3·min(elapsed,
  1)/1`, then `iVar6 = uVar13·100`) — so the tint is the existing `.fadeToColor(percent: 15, rgb: rgb)` and the clear
  is the existing `.fadeToColor(percent: 100, rgb: nil)` (the original gamma). **No new seam case.** The library's 1 ms
  blocking wait inside the call is ignored (recorded deviation: under one tick, nothing drawn in it). The gamma is applied by FerazelRender's screen surface, which both
  shells present — no shell change (Ruling 16 (b) only).
- **◈ goldens:** swim `c1dd428a3f146d77` (and any golden whose route enters water — list them) — the op enters the
  stream. Switch-off: the row-41 tint branch commented out → old values return.
- **Tests (3):** `testUnderwaterTintBlue` (kind 0, `+0x11c` 3 → one tint op toward (0, 0, 64000), 15; flag 1; a second
  frame emits nothing) · `testTintClearsOnSurfacing` (`+0x11c` 0 with the flag → `.TintScreen(0,0)`, flag 0) ·
  `testTintGatedByFading` (fading disabled → no op, flag still set as the dump does — check the order).
- **Gate:** G2 513 + ◈ record. **Commit:** `Ferazel: the underwater screen tint (.TintScreen, row 41); swim golden moved as recorded; 3 tests`.
- **As executed (2026-10-30, loop run 38):** G2 **514** (the +1 after Ben's 3cf72df), 0 failed, the one opt-in skip.
  **No golden moved** (swim `c1dd428a3f146d77` and every other value unchanged; the Windows references not moved).
  Switch-off check: with the row-41 tint branch disabled locally the FerazelRenderTests suite is also 0 failed, same
  values — on and off agree. Why nothing moved: (1) the swim route never enters the band — `+0x11c` is how far the top
  of the hot rect is above the surface (`.HandleUnderWater` M l. 38169: surface y − (y + hot-rect top); l. 38179
  clamps anything < 1 to 1; the kind-5 arm l. 38209–38212 the same from `+0x148`; held items copy it at M l. 43518–43521,
  also clamped), so 1 means fully submerged (or the head top exactly 1 px above), 2…9 the head top 2–9 px above the
  surface, and > 10 the head well out; 0 = not in liquid this frame (`.StandardSpriteHandles` zeroes it every frame,
  M l. 32487, keeping the last value in `+0x120`, before `.HandleUnderWater` rewrites it; `.InitSprite` M l. 35669);
  the route swims at the surface (`+0x11c` 69 at its end) and a probe found no
  `.screenGamma` op in any of its 397 iterations; (2) even when it fires, the golden hashes FrameRenderer's indexed
  pixels and the sound words, and FrameRenderer drops `.screenGamma` (the screen surface's gamma is not in the hash).
  Dump re-read (M l. 46449–46476, 31704–31727, 79455ff): agrees with the contract — tint branch calls `.TintScreen`
  then sets the flag; clear branch clears the flag then calls it; so with fading disabled the flag is still written
  both ways (test 3). rgb by `+0x128` in the local's order (uStack_c6 red, c4 green, c2 blue). The flag lives in
  `.ClearPlayerVars` (M l. 42631) → `PlayerState.screenTinted`, reset by every `Player.spawn` (level load, restart,
  new game); only row 41 writes it. The gate reads `SpriteWorld.gammaFade.fadingEnabled` (LevelRun hands
  `ScreenFade.fadingEnabled` over at `.armFade`); the op is built by `ScreenFade.tintScreen` and goes out in
  `PlayerState.tileOps`, i.e. at the player Handle's place in the pass. Both `// later: no Phase-2 seam` labels gone.

#### DA — minor — the standing draw-mode audit (Q15 item 2) (→ 515)
- **Files:** `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (new), `docs/ferazel/port-gap-ledger.md` (§2.1 gains
  "maintained by DrawModeAuditTests"), `Sources/FerazelRender/Frame/SpriteBlitter.swift` (doc comment: the refusal list
  points at the audit).
- **Contract:** two tests in the normal suite (fast):
  (1) **`testEveryWrittenModeIsDrawable`** — for every level in `BuiltLevels.range`, the set of draw inputs Core can
  write: every `SpriteDraw` mode word, rotation, scale, mirror, light byte case, water kind, clip, backdrop mode and
  OmniPx mode reachable from the level's placements (each Setup run once; each class's documented mode writers — a
  table in the test, one row per writer with its file:line, kept by every task that adds a writer, Invariant 8) and
  from a 2,000-step scripted run of the level through `LevelRun` + `FrameRenderer` — is drawn by `SpriteBlitter` /
  `FrameRenderer` without a refusal;
  (2) **`testEveryRefusalIsUnreachable`** — a table of **every error FerazelRender throws on a level frame** — built
  by scanning every `throw` in `Sources/FerazelRender` (Research note 5's counts: `SpriteBlitter.Refusal`,
  `ParallaxBlitter.Refusal`, the water-face throw in `Effects/WaterFaceBlitter.swift`, `ScreenRenderer`'s
  `Refusal.levelOp` cases (a level op reaching the front-end renderer), `FrameRenderer`'s light-slot and tint-table
  throws, and the face/picture loaders' throws) — with, for each, the reason it cannot be reached in the built levels (no writer; data absent per `placements-all.tsv`; a
  header value 0) checked by code (writer list, header scan) — a new refusal or a new writer without a row fails.
  **Ruling 6:** refusals stay refusals (a quit is loud), guarded by DA + the visit sweep + the bot at every phase end.
- **Tests (2):** the two above.
- **Gate:** G2 515. **Commit:** `Ferazel: the draw-mode audit — every written mode drawable, every refusal unreachable, levels in scope; 2 tests`.
- **As executed (2026-10-30, loop run 38):** G2 **516** (the +1 after Ben's 3cf72df), 0 failed, the one opt-in skip; no
  golden or other count moved. **Writer table:** 147 rows, one per writer site of a mode word, rotation, scale, mirror,
  flash, flash table or water kind in `Sources/FerazelCore` (a pure-Swift scan of `.<field> <op> ` lines; two file /
  field pairs listed as not draw inputs: the particle pool's erase mode, the screen flash); a writer without a row or a
  row whose line no longer writes fails, printing the scanned `file:line`. Each distinct value is drawn and erased on
  every built level (plain, mirrored, wrapped; the transform-safe modes 0/1/3/4/6/9/0xc also rotated and scaled; the
  dynamic-light words over the level's own light bytes, F 0…110); every Setup once; then 2,000 `LevelRun` steps per
  level (scripted keys, Return, all-keys-up blocks) applied to `FrameRenderer`, skipping only the ops whose `apply` arm
  holds no `try` (checked by a source scan) — every drawn word, rotation, scale and water kind must be one a row names.
  **Refusal table:** the scan finds 99 `throw`s in FerazelRender in 47 (file, name) rows — DK's new `Refusal.darkness`
  included: no writer 3 rows / 14 throws (mode, rotation, diffuse seed), data absent 4 / 5 (faces loaded, the light
  pass's carried refusals, darkness, light slots), header value 0 2 / 2 (fire backdrop, ripple), by construction 7 / 11
  (translucency, transform, tint draws, death step, tint table attached, level CLUT, water-face tile), loads clean
  17 / 33 (face / picture / light-face loaders, Mlvl), not on a level frame 13 / 33 (the level ops in ScreenRenderer,
  MapRenderer, SoundBank, MusicTrack, the census), time bound 1 / 1. **No refusal reachable.** DK's index ≥ 0x6f000 stays
  refused (F max 110); A14 is pinned unreachable (every cell of levels 1–4 has light byte 0…15 — measured 0…11/13/14/15,
  so no 0xbff00 + F word). Reasons that needed a code read: the hovering rock's 0xb modes (`+0x160 < 0`) never meet the
  boulder's rotation (`+0x160` is written only by `PlayerShot.setup`, 0 or 10, and the hover branch's own count-up);
  the floe's 0xb0000 (`tail`, `+0xa6` 1…0x2c) never meets the raft's tilt (the raft's Setup arm sets `+0xa6 = 0`); the
  orb's 0xb flashes never meet a shot rotation (orb gravity 0). **Time bound:** the ripple phase goes negative only after
  2^23 frames in one level (> 77 h at 30 a second). **Deviation:** the run's renderer uses `LevelSweepTests`' search
  (ruled, lowest) — with the shells' exact-nearest / highest faces Core's steps ran about 4× slower in this harness (not
  investigated; follow-up). **Cost:** the two tests take ≈ 100 s of the suite (four renderers and 4 × 2,000 Core steps
  are ≈ 50 s of it in a debug build); `runSteps` is the knob. **Seat ruling (Q15 item 7):** `StatusBar.swift`'s header
  now says black is 96 (lowest) / 255 (highest) in clut 200, which holds black at 96 and 160…255, and 255 in clut 700;
  `MapRenderTests.testMapStatusBarIsTheInLevelBarMatchedIntoClut700` gains pins worked by hand from the clut data
  (157 → 74, white 0 → 0, every clut-200 black → 255, checked on the bar's pixels).
- **Fix rounds (2026-10-30, loop run 38):** **Round 1 — the Proof B crash.** Under CrossOver both audit tests trapped
  (illegal instruction inside Foundation) and took the rest of the Windows run with them: on Windows `String.contains`
  with a string argument resolves to Foundation's version, which traps under Wine (the same family as the regex that
  finds nothing). The audit now searches and trims in plain Swift (`has`, `trim`); the file's header lists it with the
  other Wine-safe rules. **Round 2 — the review's seven findings.** (1) The draw checks were mostly empty: the Setup
  draws sat at their level points and were culled before the mode was read, and every table probe carried
  `SpriteDraw`'s default all-zero clip, an empty window (found while fixing this; the "wrapped" probe was also off the
  view at scroll 0). Every probe now has the whole face, the wrapped one draws at scroll 0x40 across the ring's edges,
  the Setup draws move to (100, 100), and each must reach its mode read — a non-empty window in view, proved once per
  place and transform by a control draw with the unwritten word 0x20000 being refused. All 717 Setup draws of levels
  1–4 reach it. (2) Each writer row is checked against the lines it cites: a word row's words must be exactly the
  mode-word literals there, a one-value row's value a literal, a flag row's literal assignment, and every derived row
  (ranges, light words, tints, liquids) carries pins — the constants it is computed from; rows that assign a variable
  cite the lines that set it (the shadow double's row now reads the 0x1000b literal, not the constant). (3) The floe /
  raft and orb / rotated-shot arguments are code checks like the hovering rock's (the guards enclosing each writer, the
  raft's Setup arm, every later `+0xa6` write, every shot rotation and gravity write). (4) Clip rows: 19 writer sites of
  the four clip edges (the per-frame reset, the occluder clamp, the blink / crumble platforms, the spikes, the gate,
  the spring), each edge value drawn under one word of every mode the level writes, mirrored, and transformed where a
  row transforms the sprite; the face is not a row — `Check.facesLoaded` now also holds every face the run draws.
  (5) The assignment scan takes any spacing (`s.mode=0x20000`). (6) A second refusal table covers every `throw` in
  FerazelCore (45 throws, 25 rows: CLUT and level loads, Setups, camera header values, the saved-game reader, dialog
  resources, conversations), each reason checked. (7) The ripple's step is checked in code (+0x100 only in the
  `.wrapEraseSprites` arm, start 0x200, one renderer per level start) and in the run (phase = 0x200 + 0x100 per erase,
  renderers = restarts + 1). Every finding's mutation fails the audit (the round's report has the table). The two tests
  now take ≈ 121 s (was ≈ 104; the probes now walk real windows); `runSteps` stays 2,000. G2 **516**, 0 failed, the one opt-in skip.

#### RB — ⚑ MAJOR — the random-play bot, both shells (Q15 item 5, Ben's "yes") (→ 517; WinKit 81)
- **Files:** `Tests/FerazelRenderTests/RandomPlayTests.swift` (new; reuses `VisitSweepPlan.swift`'s `SweepShell` and
  driver mirror), `Tests/FerazelRenderTests/RandomPlayPlan.swift` (new: the input generator, shared with Windows by
  symlink as `VisitSweepPlan.swift` is), `Ferazel/Windows/Tests/FerazelWinKitTests/WinRandomPlayTests.swift` (new),
  `Ferazel/Windows/Tests/FerazelWinKitTests/RandomPlayPlan.swift` (symlink, mode 120000),
  `tools/ferazel-random-play.sh` (new; the visit sweep's runner shape: `core|windows|both`, release build with
  `-enable-testing`, shards, survives a trap, `OUT=`), `tools/windows/proof-b-ferazel.sh` (`optin_skips` gains
  `FerazelRenderTests.RandomPlayTests/testRandomPlay`).
- **Contract:** headless, no window, no audio device, nothing launched (D42-clean, any hour). For every level in
  `BuiltLevels.range`, `FERAZEL_BOT_SEEDS` seeds (default 4) × `FERAZEL_BOT_MINUTES` of play (default 3 minutes = 5,400
  steps at the 30-step cap): a New Game jumped to the level by the flow's `startLevel` (the hidden `FerazelLevel`
  path), then random input through the **real** path — `GameFlow` → `LevelRun` → `FerazelSession` → `FrameRenderer` /
  `ScreenRenderer` / `ConversationRenderer` (Core path) and headless `WinGame` + the shared `FerazelDriver` (Windows
  path, quit-on-draw-failure included). The generator (seeded, its own RNG — never the game's): held directions in runs
  of 5–60 steps, jump/run/use/cast taps and holds, item stepping 7/9, mashing bursts, occasional Esc/⌘P/Caps Lock and
  answers to every dialog/conversation as the shells answer (Cancel on quit confirms), a save at save points
  (in-memory/temp file), death → Continue; on a level end the map → re-enter the same level. Fails on any render
  refusal, thrown error, error/report dialog, quit, stuck modal (600 ticks with nothing moving), trap (the process dies —
  the runner records the seed/step from a progress file). Prints `RANDOM PLAY (Core|Windows): levels L, seeds S, steps
  T, deaths D, exits E, conversations C, saves V` and a failure table; the runner script prints one fixed summary line
  per path in the visit sweep's shape — `== core: random play — levels L, seeds S, steps T, deaths D, exits E,
  conversations C, saves V, failures F in W s` (and `== windows: …`) — which GE greps (`^== (core|windows):`). Opt-in: `FERAZEL_BOT=1` (skipped otherwise —
  Ruling 8). `RandomPlayPlan` also has an always-run unit test of the generator (deterministic sequence for a seed).
  Quick mode for class tasks: `FERAZEL_BOT_LEVELS=n FERAZEL_BOT_MINUTES=1 tools/ferazel-random-play.sh core`.
- **Tests (Core 2, WinKit 1):** `RandomPlayPlanTests.testGeneratorIsDeterministic` (runs) ·
  `RandomPlayTests.testRandomPlay` (opt-in) · `WinRandomPlayTests.testRandomPlayThroughWinGame` (opt-in).
- **Acceptance:** at RB's merge, `tools/ferazel-random-play.sh both` exits 0 on levels 1–4 (its summary in "As
  executed" with the wall time); a deliberately injected refusal (a test-only patch, not committed) is caught on both
  paths.
- **Gate:** G2 517 / 2 skips, GW2 81 / 2 skips, GWB by day **514 / 0 / 3 / 0 (of 517)**. **Commit:**
  `Ferazel: the random-play bot — Core and Windows paths, runner script, Proof B opt-in list; 3 tests`.

- **As executed (2026-10-30, loop run 39):** f5fb48e + fix round 34290ad (rebased onto Ben's 8f7746f) + runner limits
  fe7b20c. G2 **518** / 0 failed / the two opt-in skips; GW2 **81** / 0 / 2 skips; census 1,108/0; GWB **owed (night
  rule)** — run 40 runs it first. `tools/ferazel-random-play.sh both` (defaults: levels 1–4, 4 seeds, 3 min): `== core:
  random play — levels 4, seeds 4, steps 86400, deaths 10, exits 47, conversations 21, saves 1, failures 0` and the
  Windows line identical (seat, ≈ 3–4 min wall). Every failure kind (refusal, throw, error and report dialog, quit, stuck
  modal, trap) injected by the two legs and caught on both paths at the same seed/step. A "step" = 2 game ticks (5,400
  steps = 3 min). Deviations: `VisitSweepTests.swift` (+2 lines: the Core test shell gains a Caps Lock setting, default
  off — the sweep never sets it) outside Files; the bot taps Space while a level has not started (the chapter card waits
  1,200 ticks); on Windows Ctrl accompanies a key pressed while ⌘ is held; after a trap the logged step is ≤ 30 steps
  early. **Seat ruling (fix round):** level 3 starts ~156 px from an exit, so a re-entered level ends at once — the
  contract's "level end → map → re-enter" runs once per run, every later level end starts a fresh New Game at the
  level (level 3 still gives ~40 of 47 exits — level data). Fix round: the runner fails on a failed / never-reported run,
  floors JOBS at 1, refuses a level outside `BuiltLevels.range` (exit 2), clears only its own files in a reused `OUT`,
  has a per-shard watchdog (`FERAZEL_BOT_WATCHDOG`); a Windows exit 0 is reported as a quit. **Ben's 8f7746f** (his Mac
  ran out of RAM under the sweep's 14 workers) copied into the bot's runner: 4 workers (6 max), `swift build -j 4`, a
  30 %-free-memory wait. Carried [LOW]: saves reached once per 16 runs; a trapped run's counts are zero; conversations
  counted by object identity; the Windows test class is main-actor (Proof B does not run WinKit).

### Wave 5.1 — the enemy foundation

#### EC — ⚑ MAJOR — enemy common: handlers, counting, kills, statues, hazards, the burn-away, goblin voices, contact damage (→ 525)
- **Files:** `Sources/FerazelCore/World/Enemies/EnemyCommon.swift` (new), `Sources/FerazelCore/Particles/Burn.swift`
  (new), `Sources/FerazelCore/Sprites/SpriteSlot.swift` (S2 cases, `+0x1b2`), `Sources/FerazelCore/Physics/StandardSprite.swift`
  (`:94`, `:124` — the burn call; both stubs are labelled `// later: burn-away` / `// later: \`.HandleBurn\``, not
  `later: Phase 5`, so A5's grep cannot see them — EC removes both labels when the call lands), `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:538–:649` the enemy stubs: counted
  only inside the window — run 29 carry [MED], `SetupFaces.swift:575–580`'s tally), `Sources/FerazelCore/Front/LevelRun.swift`
  (the window around the sprite setup), `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift` (dispatch for the
  new cases, each a named no-op until its task; the `+0x1b2` early return), `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (step 6's enemy rows and step 7's generic path for the enemy classes — contact damage by class, coins, blood, the
  0x6d6 invul 0x24; `:10`, `:994`, `:1032`), `Sources/FerazelCore/Items/Smite.swift` (`:23`, `:26` — the 15 enemy Handles
  by `SpriteHandler` (TOC 0x100a048c…0x100a04c4, **0x100a0494 = `.HandleWarriorSprite` included** — Ruling 3a); the
  position is the sprite's **stored** `+0x10` / `+0xe` − 4 read directly (M l. 47038) — whatever the last
  `.CalcCenterPos` (M l. 32612–32628, called by the Handles) left there — never recomputed at Smite time),
  `Sources/FerazelCore/Player/GroundCeilingEffects.swift`
  (`:68–:69` relabel), `Sources/FerazelRender/Frame/SpriteBlitter.swift` (the top clip for the burn, if not already
  honoured), `Tests/FerazelCoreTests/Enemies/EnemyCommonTests.swift` (new), `docs/ferazel/held-item-melee.md` (BC52),
  `Tests/FerazelCoreTests/ItemUseTests.swift` (`:533–:559` `testSmitingRing` — today it matches the inert enemies by
  class and computes the hot-rect centre; **seat ruling (in advance):** retarget it to the `SpriteHandler` cases and the
  stored `+0x10`/`+0xe`, re-derive every expected value from M l. 46981–47046, and list each changed value with its
  cause in "As executed").
- **Contract:** enemies-ground §2 (all), enemies-flyers §1, enemies-water-cave §0.1/§6, enemy-shots-and-damage §3.2,
  §3.4, §3.5 (non-shot rows), §3.7, enemies-ground-2 §3–§4, particles §5.5, draw-effects §4. Dump: `.HitPlayerSprite`
  (M l. 48445–49929; the hazard arm raw `10058458..10058494`, the generic path raw `10057968..10057bcc`), `.HurtPlayer`
  (M l. 47955–48112), `.HurtSprite` (M l. 32705–32729), `.HurtGoblin` (M l. 58472–58505), the goblin voice helpers (M l.
  56773–56897), `.TurnIntoStatue` / `.HandleStatueSprite` (M l. 38244–38272 / 56521–56555), `.HandleBurn` /
  `.BurnFaceRow` (M l. 38765–38840 / 38514–38663), `.StandardSpriteCleanup` (M l. 32629–32704), `.SmiteEnemies` (M l.
  46981–47046), `.SetupLevel` (M l. 2189–2590; the window raw `10004da4..10004dc0`). **INDEX item 29 remainder (§9 (c)):**
  scan every enemy Setup/Handle/Hit/Kill span (Research note 1) for `MTNewSprite`/`.GenerateSprite` with the Bonus Setup
  and list the types spawned; record in `held-item-melee.md` NR 4 as BC52 (expected: **money bags 0x50d and 0x50c and
  coins 0x516** — `.PopupGoblinCoins` (M l. 57348ff) draws `FastRand(total)` to choose one of: one 0x50d (M l. 57435,
  then R(1000)); 2 + R(3) × 0x50c (M l. 57452, each R(1000), R(2000)); one 0x50c (M l. 57470, R(1000)); 2 + R(3) ×
  0x516 (M l. 57485, each R(1000), R(2000)); the other classes spawn 0x516 from their Handles; items 8/21 never — if any class drops an
  item, its class task builds it as read). 0x50c/0x50d/0x516 are already boot faces (`BootFaces.swift:55–56`,
  `.InitBonusSprite`) — no draw gap. **Scan the bare token `MTNewSprite` (and `GenerateSprite`), never `MTNewSprite(`:**
  the decompiler wraps long calls as `.debug::_MTNewSprite` + newline + `(0x516, …` (`.HandleCrawlerSprite` M l. 56468, Roach 65085,
  Bat 68798, Gremlin 69324) — read the type from the next line.
  **Contact damage stays dormant until each class is mapped:** the new step-6/step-7 rows key on the new
  `SpriteHandler` cases (`.walker`, `.crawler`, …), never on type, so while `forClass` still answers `.inert` for every
  enemy (EC through the class's own task) none of them runs — "no golden moves" holds for EC, and each ◈ task's
  switch-off check (its `forClass` row back to `.inert`) also switches its contact damage off. **The coin draw (M l.
  49899–49904):** when the damage is 0x70 the `FastRand(100)` is drawn (> 0x50 → 3 coins) **before** `.HurtPlayer` and
  whatever `.HurtPlayer` then decides (Ferazel invulnerable, the attacker dead) — the draw is made regardless; damage >
  0x70 → 5 coins with no draw.
- **Tests (8):** `testCountingWindow` (a Setup inside the window → `+0x1b5` 1 and live + 1; outside → neither; the
  level-1 total unchanged from today's 0x… value — record it) · `testKillBookkeeping` (once; stat `G+0x306+2L`; `+0xea` per
  class flag; an **uncounted** kill — `+0x1b5` 0 — leaves live and the stat unchanged and still sets `+0xe9` to 1) · `testContactDamageWalker` (step 7: 0x70, invul 60, coins 3 iff R(100) > 80, blood; the R(100) is drawn
  also when Ferazel is invulnerable and when the attacker is dead — the seed after the hit equals one draw in all three
  cases) · `testContactDamage0x6d6Invul`
  (0x24) · `testDeadEnemyHarmless` (HP < 1 → `.HurtPlayer` returns 0) · `testBurnAwayClipsAndKills` (`+0x1a2 = 1`: the
  top clip advances `+0x8d + 1` rows/frame; particles per row; the Kill proc at the opaque bottom) ·
  `testGoblinCriesGlobal` (465 playing on another goblin → no random cry and no draw beyond R(500); hurt cry stops every
  465/466/468) · `testSmiteMatchesEnemyHandles` (16-target cap; the seed at the stored `+0x10` − 4, `+0xe` − 4, with a stale stored
  centre to prove it is not recomputed; the Warrior Handle is a target).
- **Gate:** G2 525. No golden moves (no Handle body runs yet). **Commit:** `FerazelCore: enemy common — handlers, the counting window, kills, contact damage, statues, hazards, the burn-away, goblin voices; 8 tests`.

- **As executed (2026-10-31, loop run 39):** 8180742 + fix round a2d1fa9. G2 **526** / 0 failed / 2 opt-in skips; GW2
  **81** / 0 / 2; census 1,108/0; no golden or other count moved; level-1 counted total **0xf** unchanged (the run-29
  carry fixed: `+0x1b5` only inside the window). Dump vs plan: `+0x1b2` already existed as `handleSkip` (`emerging` is
  a second name); every enemy Kill except the Walker's sets `+0xea` (the bank listed three classes); Smite's spawn is at
  M l. 47036 (not 47038); 11 of the 15 Smite Handles have cases (the four bosses stay `.inert`); the crush helper's
  `+0xb0 ≠ 4` gate is at M l. 58584, before `.PlatformBounce`. **BC52:** the enemy spans spawn only money bags 0x50d /
  0x50c and coin 0x516 (goblins via `.PopupGoblinCoins`; one 0x516 each from Crawler, Roach, Bat, Gremlin) — no item
  drops. **`testSmitingRing` (seat ruling in advance):** its enemies are now bat / frog / walker handlers with stale
  stored centres; seeds (323,227) (457,192) (76,304) → (313,229) (447,194) (66,306) — the stored `+0x10`/`+0xe` − 4
  (M l. 47036) instead of the hot-rect centre; the cap enemies are roaches, the idled one a bat. **Visible now:** the
  Ring of Smiting hits nothing on levels 1–4 until each class task maps its handler (plan-mandated dormancy).
  **Fix round (both legs):** the implementer had the Gremlin backwards — `.KillGremlinSprite` returns at once when
  `+0xe9 ≠ 0` (M l. 69736–69738), now as the dump with the test corrected; the burn's Kill ran on a held slot copy
  (landmine (o)) — now written back before and re-read after, the Kill against the world by id; burn with no face = no-op
  (`.HandleBurn` M l. 38780; headless-only); citations fixed (BC52 coin lines 57435/57452/57470/57485, shield block
  48389); `Smite.enemyClasses` removed; 38 surviving mutations (taunt 467, step-6 rows and exclusions, Bat/Blob damage,
  liquids, hazards, `.HurtGoblin`, the tally window) now each fail an assert; `DrawModeAuditTests` two rows re-pointed
  (values unchanged) — a file outside Files. Carried [LOW]: the Dillo 0x74f coin count is asserted as a range (6 → 5
  survives); with no face provider the burn skips its sound's random draw (headless only); a non-numeric `MIN_FREE_PCT`
  stalls the runner's memory wait 10 min (as Ben's sweep).

#### ES — ⚑ MAJOR — the EnemyShot class, the shield block, the Magical Shield crouch, boulder spouts firing (→ 536)
- **Files:** `Sources/FerazelCore/World/Enemies/EnemyShot.swift` (new), `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (step 7's EnemyShot rows: damage by type, `_DAT_100a0570 = 0`, the 0x77b spin reversal, every other shot killed;
  `.ShieldBlock`), `Sources/FerazelCore/Player/PlayerStates.swift` (`:556` the Magical Shield crouch face with
  `.HasItem(0xf)`), `Sources/FerazelCore/Shots/PlayerShotHits.swift` (`:151`, `:189`, `:191` — the enemy-shot arms of
  `.HitPlayerShotSprite`), `Sources/FerazelCore/Player/Pentashield.swift` (`:7` — orbs kill enemy shots),
  `Sources/FerazelCore/World/Movers/BoxSprite.swift` (`:12`, `:776`, `:785` — the spouts 0x5aa…0x5ad spawn 0x6e1 + p4
  with their Setup's draws, re-arm 50 + R(30)), `Sources/FerazelCore/World/Movers/ButtonSprite.swift` (`:101` — an enemy
  shot presses), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (`:402–:437` — cannon capture of an enemy
  shot; the dart traps 0x76c…0x76f if placed on 1–5, else built as read and unreachable), `Sources/FerazelCore/Session/FerazelSession.swift`
  (dispatch), `Sources/FerazelCore/Sprites/BootFaces.swift` / `Sources/FerazelCore/Front/LevelRun.swift` (`CachedFaces`)
  — the shot sheets: 0x6a7, 0x6e1, 0x6e2, 0x6e6, 0x45d, 0x454…0x457, 0x71f, 0x753, 0x754, 0x771…0x774 are already boot
  faces (b535527); **0x77b and 0x46a** are added where the original loads them (boot list or the owning class's
  `.Init*Sprite` cache), `Tests/FerazelCoreTests/Enemies/EnemyShotTests.swift` (new),
  `Tests/FerazelCoreTests/ButtonGateTests.swift` (`:384–:393` — pins the spout's ◇ "no sprite, `count` unchanged";
  **seat ruling (in advance):** retarget it to the firing spout, re-derive the stream, the new shot and the count from
  the dump (`BoxSprite` spout arm + `.SetupEnemyShotSprite`), and list each changed value with its cause in "As
  executed" — a stub-pinning test takes the dump's value; never edit to make a number agree).
- **Contract:** enemy-shots-and-damage §1 (all), §3.5–§3.6, enemy-shots-and-damage-2 §4.1–§4.3, §4.6. Dump: M l.
  51393–52260 (Init, Setup, Handle, Hit, Kill, HitTile), `.ShieldBlock` M l. 48359–48444, `.FindDesiredDirectionGeneric`
  M l. 37684–37833 (homing), `.KillPlayerShot` (exists) for the player-shot arms. **Every type of §1.2** is built (the
  boss types' Setup/Handle arms are in this class's routines — built as read, reachable only from Phase 6 spawners).
  The spouts (run 27 carry, BC44): the shot's Setup draws (`FastRand(5)`) and the bounce-budget draws now enter level
  4's stream — no golden is on level 4 (not ◈). The Magical Shield crouch face (D38 A4 ruling): the face row the dump
  selects while crouching with the shield raised and `.HasItem(0xf)`.
  **`.ShieldBlock` (M l. 48359–48444) acts only on enemy shots:** its whole body is gated on the attacker's `+0x4c`
  being the EnemyShot Handle (M l. 48380, with the side test, the facing `_DAT_100a5f5a` and the shield counter > 2);
  its non-shot `else` arms are therefore unreachable and are transcribed as read. Inside: darts/spines 0x76c…0x775 and
  0x754 → reflected (×−0.38 via the double constants, vy − 0x5dc, gravity 0x100; Magical Shield → `+0x1a2 = 1`); **the
  Wraith shot 0x6f4 with `.HasItem(0xf)` (M l. 48384–48393)** → once (`+0x160 == 0`): the sound, vx and vy negated,
  vy + 0x140, `+0x160 = 1`, `.ExplodeFaceIntoParticles(face, pos, 1, 1, 1, 100, 0x65)` — the shot is not killed; a
  second block of the same shot does nothing but the counter write; every other shot → sound + `.KillEnemyShot`.
- **Tests (11):** `testWalkerAxeShot` (type 0/1 flight, gravity 0xaf, frame ±1, dies on first wall) · `testBoulderBounceBudget`
  (start −6…−1 with the 13 % adjust; split into 3…5 × 0x6e6 with vx/vy per §1.6) · `testBombBoulderExplodes` (0x6e2:
  snd 435, 0x4b7 at (x−32, y−32)) · `testShardHurtsOnlyYoung` (0x6e6 `+0x164 ≤ 1`) · `testFrogSpitTintDead` (the `+0xa4`
  multipliers never reach damage) · `testWraithHoming` (20 frames of 0x8c impulses then coast) · `testShieldBlockReflectsDart`
  (side test, counter > 2 → 7, ×−0.38, vy −1500, gravity 0x100; Magical Shield → `+0x1a2 = 1` burns it) ·
  `testShieldBlockKillsOthers` (and a non-shot attacker is never blocked) · `testShieldReflectsWraithShot` (0x6f4 with
  the Magical Shield: velocities negated, vy + 0x140, `+0x160` 1, particles, not killed; a second block leaves it; without
  the item → killed) · `testSpoutFiresWhenLinkedButtonPressed` (level 4 rec 28: p1/p2 record p4 == 1 → spawn
  0x6e1 + p4 at own x,y with the arm's velocities; re-arm R(30) + 50) · `testMagicalShieldCrouchFace`.
- **Gate:** G2 536. Wave 5.1 end: G3, GWB by day. **Commit:** `FerazelCore: the EnemyShot class, the shield block and reflection, the Magical Shield crouch, boulder spouts fire; 11 tests`.

- **As executed (2026-10-31, loop run 40):** 067d570 + fix round 8bc8cf7, merged to main 8bc8cf7. Seat gates at
  8bc8cf7: G2 **537** / 0 failed / 2 opt-in skips (ladder +1 as recorded); G3 1,108/0 (wave 5.1 end); GW1 0/2, GW2
  **81**/0/2, GW3 0/1, GW4, G5, G7, G7W, GW-symlinks, G-MUTE 1/1 all as expected; GWB not run at 8bc8cf7 (night); run at b8d56c5 by day: 543/0/3/0 of 546. No golden moved (no golden is on level 4). **Dump vs plan:** cannons
  never capture an enemy shot (M l. 63684 — the plan said they do); the spout's speed draws are made only when a record
  was made (raw `1006e9a8`) and its shot sits on the spout's layer − 1 (9, `subi` at `1006e99c`); the Wraith shot homes
  **19** frames, not 20 (age incremented before the `< 0x14` test); the Warrior shot 0x71f mirrors when vx **> 0**
  (raw `1005c408..28`; bank §1.2 said ≤ 0 — bank note appended); the egg's facing flag is set when its draw > 0x32; a
  reflected dart's burn ends `+0xe9 = 1` (its Setup never stores a Kill proc `+0x50`). **`ButtonGateTests` spout row
  (seat ruling in advance):** each firing now makes the shot Setup's draws R(5), R(2), R(100) and R(5) when the third
  > 0x56, then the speed draws, then R(30) + 50; the sprite count rises by one per firing (four in the test) instead of
  staying flat. **Faces:** 0x46a ×3 and 0x77b added to `CachedFaces.sets` after the Background's records
  (`.InitEnemyShotSprite` M l. 51434–51437); only the boss Setups mark them, so nothing loads them before Phase 6;
  `loadedSets` keys by PICT, so the three 0x46a records count as one [LOW, latent until Phase 6]. Outside Files:
  `DrawModeAuditTests.swift` (rows re-pointed for shifted lines, five new draw rows, EnemyShot added to the `+0x160`
  writer list — both legs judged it right), `EnemyCommon.swift` (two labels), `SetupFaces.swift` + `LevelRun.swift`
  (the dart traps' Setup arm and cache marks, fix round). **Fix round (both legs MERGEABLE; leg 2's 90 mutations left
  33 survivors):** `.ShieldBlock`'s non-shot arm (M l. 48430–48435) and the dart traps' Setup arm (M l. 62495–62520)
  built as read (traps placed only on Mlvl 22, 30, 31, 45, 62 — unreachable on 1–5); asserts added inside the existing
  tests for the side test's speed term and left edge, the bounce-gate countdown through real frames, the spout speeds,
  Hit's exclusions and boundaries, kill-path particles, the orb arm; 82 of 86 hand mutations now fail a test, the 4
  survivors are equivalent (type 1 covered twice; the spit effect's layer rewritten by the Effect Setup; the orb's
  effect flag never read; the orb arm's `return`). Carried [LOW]: the egg's 0.9 and the −0.15 constants were not
  re-checked against the data section (compressed).

### Wave 5.2 — ground enemies (levels 1–4 come alive)

#### WK1 — ⚑ MAJOR ◈ — Walker: Setup by tier, the frame, the thrower 1700, the spear guard 1705, hits, death, coins, the corpse raft (→ 545)
- **Files:** `Sources/FerazelCore/World/Enemies/Walker.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift` (the
  Walker Setup completed: `+0x14c = 120 + R(70)`, `+0x150 = −1`, `+0x154 = 1000 + R(400)`, `+0xf0 = 2·R(0x5fff) +
  0xbfff`, tier by p3, idle margins by p4, flip, hot rects, faces), `Sources/FerazelCore/Sprites/SpriteSlot.swift`
  (`forClass` → `.walker`), `Sources/FerazelCore/World/Movers/PlatformSprite.swift` (the corpse as a platform and its
  flotation, enemies-ground-2 §1), `Sources/FerazelCore/Front/LevelRun.swift` (cache marks for 1701…1707, 1760 set),
  `Sources/FerazelCore/Sprites/BootFaces.swift` (only if a Walker sheet is a boot set — the face notes),
  `Tests/FerazelCoreTests/Enemies/WalkerTests.swift` (new),
  `Tests/FerazelRenderTests/{FrameGoldenTests,Phase2GoldenTests}.swift` (◈ values), the existing tests that pin a
  Walker as `.inert` — `Tests/FerazelCoreTests/BonusSpriteTests.swift` (`:424`, the 0x6a4 "untouched by the Bonus
  Handle" row), `Tests/FerazelCoreTests/BackgroundMoverTests.swift` (`:742` the cannoned walker's handler, `:779` "a
  walker (inert): captured"), `Tests/FerazelCoreTests/LevelFourTests.swift` (`:70`, the level-4 boulder goblin 1760 —
  a Walker type, so its `forClass` row becomes `.walker` here with its 1760 arm a `// later: WK2` no-op) — **seat
  ruling (in advance):** each is retargeted to `.walker` and its other values re-derived from the dump (what the
  Walker Handle/Setup does at that site, e.g. whether a walking Walker is still captured by the cannon), every changed
  value listed with its cause in "As executed"; a stub-pinning value takes the dump's; never edit to make a number agree,
  `Ferazel/Windows/Tests/FerazelWinKitTests/WinReferenceFramesTests.swift` + `tools/windows/smoke-ferazel-win.sh` (◈
  Windows references, if they move).
- **Contract:** enemies-ground §3.1–§3.5, §3.7, §3.8; enemies-ground-2 §1. Dump: `.InitWalkerSprite` M l. 56746–56772,
  `.SetupWalkerSprite` 56898–57100, `.PopupGoblinCoins` 57348–57506, `.HandleWalkerSprite` 57507–58471 (the 1700 and
  1705 arms, the tail, the death entry), `.HurtGoblin` 58472–58505, `.HitWalkerSprite` 58506–58611, `.KillWalker`
  58612–58633, `.HitWalkerTileSprite` 58634–58696, `.HandleFlotation` 38075–38124. Types 1750 and 1760 are WK2's (their
  arms stay `// later: WK2` no-ops that keep the shared tail). Statue arm, liquids (incl. `hdr+0x270e` surface damage),
  Smite reaction, burn-away after the death animation.
- **◈ goldens:** every level-1/level-2 golden (Walkers 1700 ×2 p1 1 and 1705 ×4 on level 1; 1700/1705 ×6 each on level
  2) and the Windows references B/C — old → new recorded with the switch-off check.
- **Tests (9):** `testWalkerTierTable` (p3 0…7 → HP/`+0x158`/`+0xb8` per §3.1, 1750 column for 0x6d6 only) ·
  `testThrowerWalksToRange` (target `P.x ± +0x14c`, ±25 px, the 16-step counter backwards when walking away) ·
  `testThrowerNeverWalksP1` · `testThrowerThrowsAtStep8` (snd 704, cooldown `+0x158 + R(26)`, the shot per ES) ·
  `testSpearGuardBlocksShot` (snd 303) · `testSpearGuardThrust` (0x6a9 at counter 0x10, ±3000) · `testWalkerKnockbackP2`
  · `testWalkerDeathCoinsAndScore` (1700 +500; coins per tier) · `testCorpseFloats` (buoyancy ramp 0 → 0x50, §1.3).
- **Gate:** G2 545 + ◈. Quick bot on levels 1–2. **Commit:** `FerazelCore: Walkers 1700/1705 — tiers, throwing, spear guard, hits, death, coins, the corpse raft; goldens moved as recorded; 9 tests`.

- **As executed (2026-10-31, loop run 40):** 0efe8e2 + fix round b8d56c5. Seat gates at b8d56c5: G2 **546** / 0 failed /
  2 opt-in skips (ladder +1); GW2 **81**/0/2; GW1, GW3, GW4, G5, G7, G7W, GW-symlinks, G-MUTE as expected. Quick bot
  (levels 1–2, 1 min): `== core: random play — levels 2, seeds 4, steps 14400, deaths 1, exits 1, conversations 5,
  saves 0, failures 0`. **◈ goldens:** only the Phase 2 level-2 iteration-2 frame moved, `df22325e851e782d` →
  `b310ef334de49c00` (the 1705 at record 12 wakes on iterations 1–2 and settles onto the ground — a 16 px drop, y 119 →
  135, not the commit body's "2 px"); **every level-1 golden is unchanged because no Walker is awake on any level-1 golden
  route** (leg 1 logged all 1,037 steps of the jump / swim / 600-frame routes) — the plan's "every level-1/level-2
  golden" prediction was wrong; Windows references (menu, new game, text) unchanged. Also moved for the same cause:
  `BootFacesTests`' twelve hot-rect FNVs (counts unchanged — the Walker Setup now sets hot rects), `GameFlowGameTests`
  continue write-backs (walker records' y 429→428, 1103→1098, 972→973, 29→27), `PlayerTileTests` crunch light counts
  (frame 6 9→8, frame 15 3→4 — walker cry draws). Switch-off (row `.inert`, Setup stub): every old value returns —
  implementer and leg 1 independently. **Stub retargets (seat ruling in advance):** `BonusSpriteTests` 0x6a4 row `[5,
  0x40, 0]` → `[4, 0x40, 0x151]` (a never-set-up Walker has HP 0 → the death entry, then gravity); the cannoned walker
  returns `.walker`; level-4 record 119 → `.walker`, `hasHit` true. **Dump vs plan:** setting speed also writes vy
  (M l. 32815); the death thud 703 plays at counter 0 (M l. 57757); each dropped coin's Handle runs at once (M l.
  57498); 0x6e0 is always flipped (M l. 56945); the cache marks for 1701…1707 already existed (`LevelRun.swift`
  unchanged by the first commit). The implementer's "corpse landing sound not built" was wrong — `Player.swift:376`
  (M l. 44545) already builds it. **Fix round (both legs MERGEABLE; leg 2: 42 of 70 mutations survived):** the Walker
  sheets moved from a third renderer list to the original's level cache (`CachedFaces.handleSets` +
  `sheets(markedBy:)`, `.InitWalkerSprite` M l. 56757–56763, marked by the 1700 / 1705 Setups M l. 56966–56980);
  `killProc` reads `forGood` off the Kill proc (M l. 58624–58630); ~360 lines of asserts inside the nine tests (hazards,
  crush, traps, wall hits, the corpse wiring, the 1760 death entry, fields, boundaries) — all leg-2 survivors killed
  except four equivalents (`:185` cleared by the tail; `:382`'s first check behind the Handle's dead return; `:762` as
  `n < 1`; coins make no light ops). Outside Files: `FerazelSession.swift`, `EnemyCommon.swift`, `FrameRenderer.swift`,
  `GameFlowGameTests.swift`, `PlayerTileTests.swift`, `BootFacesTests.swift`, `DrawModeAuditTests.swift` (rows
  re-pointed, Walker rows added, the HurtSprite flash row 0xc → 8…0xc). Carried [LOW]: the Setup-face fallback width
  without a renderer measures the whole 0x6a5 / 0x6a6 pictures, not one cell; the airborne face's `onSprite` term
  unpinned (rewritten each frame by the separation).

#### CR — ⚑ MAJOR ◈ — Crawler and Roach (→ 553)
- **Files:** `Sources/FerazelCore/World/Enemies/CrawlerRoach.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (Crawler Setup; **Roach Setup `+0x154 = x` and `+0x24 = 0x4b0`, M l. 64945–64946, verified** — run 29 carry),
  `Sources/FerazelCore/Sprites/SpriteSlot.swift` (`forClass`), `Sources/FerazelCore/Shots/PlayerShotHits.swift`
  (`:163`, `:228` — the Crawler arm `.KillPlayerShot(s, 0, 0)`), `Sources/FerazelCore/Front/LevelRun.swift` (marks),
  `Tests/FerazelCoreTests/Enemies/CrawlerRoachTests.swift` (new), golden test files (◈), Windows references (◈).
- **Contract:** enemies-ground §4, §5; enemies-ground-2 §2; enemy-shots §3.5 (0x38, no coins). Dump: Crawler M l.
  56123–56745 (Init 56123, Setup 56153, Handle 56247, Hit 56556, Kill 56683, HitTile 56706), Roach M l. 64886–65262.
  The Crawler's hazard test reads `+0x14c == 1 || +0x150 == 2` (as read, intent LOW); crush `+0x150 = 0x16`; Crawler
  `+0xa6` live cooldown incl. the initial 3, Roach's write-only.
- **◈ goldens:** level 1 (Crawler ×3, Roach ×5) and level 2 (×11, ×3) goldens; Windows references.
- **Tests (8):** `testCrawlerJumpCycle` · `testCrawlerCooldownStartsAt3` · `testCrawlerKilledByShotArm` ·
  `testRoachSetupFields` (`+0x154` = x, speed 0x4b0) · `testRoachPatrol` · `testCrushByBox` (vy > 0 or grounded → HP 0,
  `+0x150 = 0x16`) · `testCrawlerRoachLiquids` (§2.4 rows) · `testKillScores` (Crawler 500, Roach 600, `+0xea`).
- **Gate:** G2 553 + ◈. Quick bot levels 1–2. **Commit:** `FerazelCore: Crawlers and Roaches; goldens moved as recorded; 8 tests`.

- **As executed (2026-10-31, loop run 41, implementer):** G2 **554** / 0 failed / the 2 opt-in skips (ladder +1, the
  attended commit); GW1 exit 0, 2; GW2 **81** / 0 / 2 opt-in skips (references unchanged, `WinReferenceFramesTests` green); G5 BUILD SUCCEEDED; G7 / G7b / G8 empty. Quick bot (levels 1–2, 1 min): `== core: random play
  — levels 2, seeds 4, steps 14400, deaths 2, exits 1, conversations 5, saves 0, failures 0`. **◈ goldens:** only the
  two level-1 routes on which a Crawler wakes moved — swim `[67, 321]` / `c1dd428a3f146d77` → `[67, 322]` /
  `3e99f74fa10e87e2`; 600-frame `a8dda9cf3e448016` / 3114 / `28a48762cfff1b2b` / seed 1574122804 / 156 →
  `0cce4b0446e2a48e` (the test's `hex` prints `cce4b0446e2a48e`) / 3160 / `1b06b8a4117cf9dc` / 1361095401 / 150 (the
  player's path and the scroll unchanged). Every other golden (Phase 1 first frame, tie-break, pans 30 / 60, chain, L2
  both frames, jump, FE0, map) and the Windows references unchanged. **Awake log** (every Crawler / Roach Handle call on
  every golden route): swim — Crawler rec 39 iterations 183…318 (136 Handles, ceiling throughout), Crawler rec 9
  275…397 (123: drops at 302, lands at 316, y 452 → 559, floor); 600-frame — rec 39 183…501 (169, ceiling), rec 9
  275…600 (326); **no Roach wakes on any golden route, and nothing on level 2's, the jump's or the Phase-1 routes** —
  the plan's "level 1 and level 2 goldens move" was wrong (as WK1's). Also moved for the same cause: `BootFacesTests`'
  twelve hot-rect FNVs (counts unchanged — the two Setups set hot rects), `GameFlowGameTests` continue write-backs
  (Roach rec 15 x 2275 → 2279, y 1130 → 1123; ceiling Crawler rec 39 y 742 → 740), `PlayerTileTests` crunch (the two
  woken Roaches (2275, 1130) / (3168, 572) → (2279, 1123) / (3172, 567)). **Switch-off** (both `forClass` rows `.inert`
  + HEAD's `SetupFaces.swift`, HEAD expectations): the goldens, the BootFaces FNVs, the continue and crunch pins and
  SpriteList / LevelRun / BackgroundMover / EnemyCommon / ItemUse — 54 tests, all pass: every old value returns. New
  values measured twice. **Dump vs plan / bank** (⚑ enemies-ground Corrections #10): the Roach's death has no × 0.97
  friction; neither Setup stores a Kill proc `+0x50` (the Handles call `.KillCrawler` / `.KillRoach`; `EnemyCommon.
  killProc`'s Crawler / Roach arm is therefore never the original's — unreachable, left as EC built it); the leap and
  the `+0xb2` count-down run before the ground test and the leap frame counts the new `+0xa6` once; the hop's halving
  runs on the hop frame; the Crawler's state-3 `HP < 300` only re-stores 3; the Roach's band is `p3 / 2` toward zero;
  `.KillPlayerShot(o, 0, 0)`'s stale r29 in both Hit routines is the shot itself (`or r29,r4,r4`, raw `100665d4` /
  `10078034`) — its own `+0x9a` is recoloured for ids 1…4; the floor crawler (p1 ≠ 0, placed nowhere) now sets up with
  no face (the absent 0x5dd) instead of refusing; the ceiling crawler keeps the Phase-1 `.handle` stand-in 0x6b0 (the
  Handle's face; it is idled at spawn, so never drawn before its Handle). No save flag `+0x188…+0x18b` is stored by
  either class; `+0xea` by both Kills (pinned); no idle margins; no new run-time face sheet (coins 0x516 are boot faces).
  **Cache marks:** the marks already existed; `CachedFaces.handleSets` gains 0x6ae / 0x6af / 0x6b1 / 0x6b9. **Outside
  Files:** `FerazelSession.swift` (Handle + hit dispatch), `EnemyCommon.swift` (comment), `GameFlowGameTests.swift`,
  `PlayerTileTests.swift`, `BootFacesTests.swift`, `DrawModeAuditTests.swift` (Crawler / Roach mode + facing rows, the
  HurtSprite flash row's sites, the shifted SetupFaces rows, the SetupFaces `notTranscribed` count 13 → 12),
  `docs/ferazel/enemies-ground.md` (#10). **Self-mutation:** 112 mutants of the new code and the shot arm, 103 killed;
  the 9 survivors are equivalent or unreachable (the wind-up face clamp at 4; the two state-3 self-stores; `+0xb2 == 0`
  at the hold test; +100 at the Roach's cap; the `HP > 0` cry branch behind `HP < 3`; tile kinds 99 / 199 that neither
  bounce routine acts on).
- **Fix round:** tests only (still 8 functions, ladder 554), every expected value worked by hand from the dump and the random draws from Park–Miller by hand (seeds 3 / 10 / 3); doc comments now say the hop halves vx moving *away* from the player. Closed, each by its mutant now failing: the leap cap (`<< 1` → `<< 2` / none — bites only with a `+0x158` below 500, written in), the dying gravity (0x151 → 0x150), both death edges (`< 1` → `< 2` / `< 0`), the ceiling halving at ±1 / ±2 (`1 <` / `>> 1`), the flee level with the player (`<=` either side), the draws R(30) → R(31) and R(3) → R(4), the hazard cries' ids and edges (0xc9 / 3 ± 1), the blood spray's speed / spread / kind (pool equals a twin's literal call), and the crush / tile literals (centre h and v by geometries where the centre picks the side; the v centre by FG kind 0x13 at y −64; `kind − 100` by BG 102 / 103). Equivalent: the `factor: 0` arguments to `.PlatformBounce` / `.WallBounce` / `.WallBounceBG` (read only under the bounce flag, which is 0 in every call, as the dump passes).

#### WK2 — ⚑ MAJOR ◈ — Walker 1760 boulder thrower and 1750 Ax goblin (→ 559)
- **Files:** `Sources/FerazelCore/World/Enemies/Walker.swift`, `Sources/FerazelCore/World/Enemies/AxGoblin.swift` (new),
  `Sources/FerazelCore/Front/LevelRun.swift` (1750–1754 marks), `Tests/FerazelCoreTests/Enemies/WalkerTests.swift`, golden
  files (◈), Windows references (◈).
- **Contract:** enemies-ground §3.5, §3.6. Dump: the 1760 arm of `.HandleWalkerSprite` (M l. 57507–58471),
  `.AxGoblinCoreLogic` M l. 57101–57347. 1760 throws 0x6e1 + p1 at `+0xb2 == 8` (ES's class); 1750 swings 0x6d6
  (never times out, dies on the first wall), jumps (snd 414 / 610), lands with `+0xa6 = 2 + R(4)`. 1750 is first placed
  on level 10 — built, synthetic tests (Ruling 1).
- **◈ goldens:** level 1 (1760 ×1 near …) — record whether it is awake on any route; level 4 not golden.
- **Tests (6):** `test1760ThrowsBoulder` · `test1760BombVariantP1` · `test1760FacesLeftSheet` · `testAxGoblinSwing` ·
  `testAxGoblinJumpLand` · `testAxGoblinTierHP` (1750 column).
- **Gate:** G2 559 + ◈ (or "no golden moved" with the probe). Wave 5.2 end: G3, GWB by day, `tools/ferazel-random-play.sh
  core` + `tools/ferazel-visit-sweep.sh core` on levels 1–4 (exit 0). **Commit:** `FerazelCore: Walker 1760 boulder thrower and 1750 Ax goblin; 6 tests`.

- **As executed (2026-10-31, loop run 41, implementer):** G2 **560** / 0 failed / the 2 opt-in skips (ladder +1, the
  attended commit), run in class batches (432 Core + 128 Render); GW1 exit 0, 2; G5 BUILD SUCCEEDED; G7 / G7b empty.
  Quick bot (levels 1 and 4, 1 min): `== core: random play — levels 2, seeds 4, steps 14400, deaths 0, exits 4,
  conversations 5, saves 0, failures 0`. **◈ goldens: none moved** (Phase 1, pans, chain, L2 both frames, jump, swim,
  600-frame, FE0, map) and the Windows references are untouched. **Awake log** (a temporary print in both arms, every
  golden test class run alone): **no 1760 or 1750 Handle on any golden route**; level 1's 1760 (rec 73) runs exactly one
  Handle per session start in `GameFlowGameTests` (16 over its 9 tests, each state 5, `+0xb2` 0, before it idles again
  — its first Handle reads the centre 0, so it never attacks there), and those tests' pins (rec 73 y 29 → 27) hold.
  **Switch-off** (both arms back to `break`, local only): goldens, `GameFlowGameTests`, `LevelFourTests`,
  `PlayerTileTests`, the BootFaces hot rects all pass on the old values; only the six new tests fail. **LevelFourTests
  rec 119:** no value changed (the test pins its Setup entry, which WK1 built); its stale `later: WK2` comment now names
  the bomb 0x6e2 it throws. **Stub retargets (WK1 tests):** `testWalkerTierTable`'s "1750's Setup throws" row → state 1;
  `testWalkerDeathCoinsAndScore`'s 1760 death rows now place the player so the arm's own facing (cx < P.x, cx 0 at the
  first Handle) gives the row's flip before the death entry inverts it (values unchanged). **Dump vs plan / bank**
  (⚑ enemies-ground Corrections #11): a chasing core-logic call stores `+0x174 = 0` (M l. 57143), so the flee
  retreat's lockout only spares the next call; the target-below arms 21…60 / ≥ 61 draw a second R(20) for `+0x160`; the
  jump cry 610 draws its own R(4000); the hop's −6000 clamp is unreachable; the landed cooldown also zeroes `+0x16c`
  (masked by the tail's zero); the 1760 blink draws R(25) only outside the blink, and its re-arm stores −(R(0x50) +
  0x28) + 1; states 0 / 3 / 5 `.ReportError` are a no-op here (no writer); no save write-back flag and no `+0xea` on
  either arm or the 1750 death path (`+0xea` stays the 1700 path's). The 1750 Setup was a `notTranscribed` throw in
  `SetupFaces` (WK1 left it) — built here with its face and sheet. **Faces:** the 1750's single 0x6d6 joins the Setup
  table and the cache singles; 0x6d7…0x6da join the cache sets (registration order, after 0x6ab) and
  `CachedFaces.handleSets`; marks for 0x6d6…0x6df; the 1760's nine 0x6e0 cells were already loaded (asserts in
  `FaceTests.testEverySpawnableTypeHasSheet`, `BootFacesTests`). **Invariant 8:** six `.mirrored` writer rows
  (`Walker.swift:115`, `:518`, `AxGoblin.swift:157/159/161/280`), the Walker / SetupFaces / SpriteSlot rows re-pointed,
  and the hovering rock's `+0x160` reason extended (the Ax goblin's negative jump budget is written only from
  `Walker.handle`'s 0x6d6 arm). **Outside Files:** `SetupFaces.swift`, `SpriteSlot.swift` (`+0xb6` `classWordB6`,
  `+0x174` `classWord174`), `LevelFourTests.swift` (comment), `DrawModeAuditTests.swift`, `BootFacesTests.swift`,
  `FaceTests.swift`, `docs/ferazel/enemies-ground.md` (#11). **Self-mutation:** 117 mutants of both arms, the core
  logic, the Setup arm and the throws; 113 killed after one round of added asserts; 4 equivalent (the landed
  cooldown's `+0x16c = 0`, re-zeroed by the tail before anything reads it; the flee T.y tie, reachable only through a
  wall jump that reads no T.y; the swing's inner `dx < 110`, implied by "not a wall jump"; the wall jump's `T.x < cx`
  tie, impossible at dx ≥ 110).

### Wave 5.3 — flyers, water and cave

#### BA — ⚑ MAJOR ◈ — the Bat class: chasers, path bats and their spit, swarms, insects (→ 568)
- **Files:** `Sources/FerazelCore/World/Enemies/Bat.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (`:538`, `:550` — the bat Setup by sub-range, the path fields `+0xf8/+0xfc/+0x100/+0x104`; the Bat's path mode now
  in its own field, not `voicePitch` — run 29 note), `Sources/FerazelCore/Sprites/SpriteSlot.swift`,
  `Sources/FerazelCore/World/Movers/BoxSprite.swift` (`:1148` — `.KillCrate`'s Bat 0x6cc drop arm after
  `.GenerateSprite`, M l. 61312–61320, now reachable), `Sources/FerazelCore/Front/LevelRun.swift` (`CachedFaces`: `.InitBatSprite` M l.
  68092–68107 caches **five picture sets** — 0x6cc (11 cells), 0x744 (9), 0x74d (8), 0x73a (12), 0x73b (12); the
  Bat **types** 0x6cc–0x6d5 are the ones whose Setup marks the 0x6cc set — run 29 carry: today only types 0x6cc/0x6cd
  mark it; every set marked as each type's Setup marks it), `Tests/FerazelCoreTests/Enemies/BatTests.swift` (new),
  `Tests/FerazelCoreTests/LevelFlowTests.swift` (`:119` — pins the level-2 Bat as `.inert`; **seat ruling (in
  advance):** retarget to `.bat`, re-derive the row's values from the dump, list each change with its cause),
  golden files (◈), Windows references (◈).
- **Contract:** enemies-flyers §1, §3 (all), §6, §7.1–§7.5. Dump: M l. 68092–69079 (Init, Setup, SwarmMember Setup/
  Handle/Hit, Handle, InsectBody, Hit, Kill, HitTile). Chasers 0x6cc/0x6d1, 0x73a, 0x744; path bats 1741/1742 (→ 1741)
  and the spit 0x712; swarm 1869 + members; insect 1860 + body; death: coins `R(3) + 1` × 0x516, blood N = 170/100,
  +500/+100 score.
- **◈ goldens:** level 2 (Bat 1740 ×1) goldens if awake on a route; record.
- **Tests (9):** `testBatSetupBySubRange` · `testSleeperWakesOnHit` (`+0xa6 < 2 → 0x15`) · `testChaserAI` (the §3.2
  constants) · `testPathBat1741` (level 3 rec with p 2, 340, 800) · `testPathBatSpit` · `testSwarmMembersHome` ·
  `testInsectBodyFollows` · `testBatDeathCoinsBlood` · `testKillCrateBatDropArm`.
- **Gate:** G2 568 + ◈. Quick bot levels 2–4. **Commit:** `FerazelCore: the Bat class — chasers, path bats and spit, swarms, insects; 9 tests`.

#### FR — ⚑ MAJOR ◈ — Frog and Salamander (→ 576)
- **Files:** `Sources/FerazelCore/World/Enemies/FrogSalamander.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (`:587` — Frog `+0x8e`, the cache face), `Sources/FerazelCore/Sprites/SpriteSlot.swift`,
  `Sources/FerazelCore/Front/LevelRun.swift` (marks; `LevelRun.swift:1051/:1117`), `Tests/FerazelCoreTests/Enemies/FrogSalamanderTests.swift`
  (new), golden files (◈), Windows references (◈).
- **Contract:** enemies-water-cave §0.1–§0.3, §1, §2, §5, §6, §7.1, §7.4. Dump: Frog M l. 70111–70641 (incl.
  `.STPlay3DSoundRandFrog` 70121–70136), Salamander M l. 70642–70981. Frog variants by p1 (`+0x15c`), spit 0x709 at
  attack step 6, the death dissolve via the burn (EC); the dead-water blocks stay dead (§7.4). Salamander first placed
  on level 50 — synthetic.
- **◈ goldens:** level 2 (Frog ×2) goldens if awake.
- **Tests (8):** `testFrogVariantsByP1` · `testFrogLeapCycle` · `testFrogSpitAtStep6` · `testFrogHitByShot` ·
  `testFrogDeathBurns` · `testSalamanderFireball` (0x712 at step 0xc) · `testSalamanderWater` · `testSalamanderContactHazardArm`.
- **Gate:** G2 576 + ◈. **Commit:** `FerazelCore: Frogs and Salamanders; 8 tests`.

#### BL — ⚑ MAJOR — Blob and Crab; the Multi Crystal's Blob-attacker exception (→ 583)
- **Files:** `Sources/FerazelCore/World/Enemies/BlobCrab.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (`:570`), `Sources/FerazelCore/Sprites/SpriteSlot.swift`, `Sources/FerazelCore/Player/HitPlayerSprite.swift` (`:997` —
  `.HurtPlayer`'s Multi Crystal skip for Blob attackers, MS carry), `Tests/FerazelCoreTests/Enemies/BlobCrabTests.swift` (new),
  `Tests/FerazelCoreTests/LevelThreeTests.swift` (`:103` — pins the level-3 Blob 0x6c2 as `.inert`; **seat ruling (in
  advance):** retarget to `.blob`, re-derive the row's values from the dump, list each change with its cause).
- **Contract:** enemies-water-cave §3, §4, §7.3. Dump: Blob M l. 67661–68091 (`.HandleDeadBlobSprite` 67738–67765),
  Crab M l. 73957–74323 (+ `.HandleCrabSegSprite` 74296–74307). Blob variants by type; Crab invulnerable claw on a
  chain (first placed on level 62 — synthetic). Blobs on levels 3–4 — no golden (not ◈).
- **Tests (7):** `testBlobVariantsByType` · `testBlobStates` · `testBlobDeadSprite` · `testBlobAttackerKeepsMultiCrystal`
  · `testCrabAims` · `testCrabStrike30Frames` · `testCrabInvulnerable`.
- **Gate:** G2 583. Wave 5.3 end: G3, GWB by day, bot + visit sweep `core` on levels 1–4. **Commit:** `FerazelCore: Blobs and Crabs; 7 tests`.

### Wave 5.4 — the classes first placed after level 5, geysers, pipes

#### GF — ⚑ MAJOR — Gremlin (body + rider) and Floater (the Wraith) (→ 590)
- **Files:** `Sources/FerazelCore/World/Enemies/GremlinFloater.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (`:649` — their Setup sites), `Sources/FerazelCore/Sprites/SpriteSlot.swift`, `Tests/FerazelCoreTests/Enemies/GremlinFloaterTests.swift` (new).
- **Contract:** enemies-flyers §4, §5, §7.6; enemy-shots §1.4 (Gremlin 0x712 by direction table, `+0x1aa` rotation —
  -2 §4.5; Floater 0x6f4). Dump: Gremlin M l. 69080–69819, Floater M l. 69820–70110. Placed on levels 15+ — synthetic
  (the 36-direction table is physics §6's, exists).
- **Tests (7):** `testGremlinCompositeSetup` · `testGremlinBody` · `testGremlinRiderSpit` · `testGremlinHits` ·
  `testFloaterCycle` · `testFloaterShotAtStep0x1d` · `testFloaterHurtsOnlyAfterFrame12`.
- **Gate:** G2 590. **Commit:** `FerazelCore: Gremlins and Wraiths; 7 tests`.

#### DL — minor — the Dillo (→ 595)
- **Files:** `Sources/FerazelCore/World/Enemies/Dillo.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`,
  `Sources/FerazelCore/Sprites/SpriteSlot.swift`, `Tests/FerazelCoreTests/Enemies/DilloTests.swift` (new).
- **Contract:** enemies-ground §6, enemies-ground-2 §7; enemy-shots §1.4 rows (0x753 eggs, `.ShootSpines`). Dump: M l.
  72276–72974 (`.ShootSpines` 72381–72472, `.DilloLayEgg` 72473–72487, `.RandomDilloAttack` 72488–72539). No shield
  block on the Dillo contact path; contact 0xe0/0x1c0 per type. Placed on 15/22 — synthetic.
- **Tests (5):** `testDilloSetup` · `testDilloSpines5And7` · `testDilloEggBomb` · `testDilloArmourBlock` · `testDilloKillScore1500`.
- **Gate:** G2 595. **Commit:** `FerazelCore: the Dillo — spines, egg bombs, armour; 5 tests`.

#### GY — ⚑ MAJOR — geysers (design §9 (b)) (→ 602)
- **Files:** `Sources/FerazelCore/World/Movers/Geyser.swift` (new), `Sources/FerazelCore/World/Movers/BoxSprite.swift`
  (`:14`, `:142`, `:421`, `:1172` — the geyser Setup arm, the eruption cycle, the column buffer `+0x9c`),
  `Sources/FerazelCore/Player/GroundCeilingEffects.swift` (`:136` — the 0x5a0 segment's Effect arm),
  `Sources/FerazelCore/Player/HitPlayerSprite.swift` (`:180`, `:219`, `:1159` — the head 0x5a9 hurt, the segment hazard
  row), `Sources/FerazelCore/World/Enemies/EnemyCommon.swift` (enemies vs geysers), `Sources/FerazelCore/Sprites/SpriteSlot.swift`
  (`.geyserSegment`), `Tests/FerazelCoreTests/GeyserTests.swift` (new).
- **Contract:** geysers.md (all); particles §4.4 (rows 200–202). Dump: `.SetupBoxSprite`'s geyser arm (inside M l.
  58892–59730; raw `1006bbdc..1006bde8`), `.HandleBoxSprite`'s eruption arm (inside M l. 60030–61180; raw
  `1006df20..1006e274`), `.HandleGeyserColumn` M l. 59731–59920, `.HandleGeyserSegSprite` M l. 53891–53899. **§9 (b)
  rulings (Ruling 9):** NR 2 — **no Setup re-run** on idle → active (`.IdleToActiveSprite` re-read 2026-10-30: setup 0,
  snapshot restored, `+0xe9` cleared, `+0xa8` = the idle index (M l. 4265), `+0x58` proc called if set, killed if `+0x4c` 0 or type 0). **Settled (fix round
  1):** the only Setup that stores a `+0x58` proc is `.SetupRopeSprite` (M l. 71122), so a geyser has none; and
  `.MTKillSprite` (M l. 30739ff) only unlinks the record and frees nothing, so the geyser's `+0x9c` column buffer
  (`AllocateGameMem(0x44)`) survives idling and is reused as it was; NR 3 —
  kinds 3/4 are built as read; their base face index past the 12-face cache **draws nothing** (◇ named, unreachable:
  no placement) — never a refusal; NR 4 — p4 inert as read; no sound (§6). Placed on levels 10, 50, 51 — synthetic.
- **Tests (7):** `testGeyserSetupDefaults` (p1 0 → 0x6400, p2/p3 0 → 60) · `testEruptionPhase` (`C mod (on+off+1)`) ·
  `testColumnSegmentsAndHead` · `testHeadHurtsByKind` (acid 0x70 / lava 0x150, the immunities) · `testSegmentHazard` ·
  `testTripleChildrenKind0` · `testIdleReactivationKeepsBlock` (no Setup draw; the column buffer kept; `+0xe9` 0 and
  `+0xa8` = the idle index it came back from).
- **Gate:** G2 602. **Commit:** `FerazelCore: geysers — setup, eruption, column, head and segment hurt; §9 (b) as read; 7 tests`.

#### PI — minor — the enemy pipes (→ 606)
- **Files:** `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the pipe arm 0x5d2…0x5d5), `Sources/FerazelCore/Session/SpriteWorld.swift`
  (`+0x1b2` collision rule: skipped as the outer sprite only), `Tests/FerazelCoreTests/EnemyPipeTests.swift` (new).
- **Contract:** enemies-ground-2 §6, enemies-flyers §7.4. Dump: `.HandleBoxSprite`'s pipe arm (raw `1006ec90..1006f060`),
  `.MTCollideSprites` (M l. 30216–30373; raw `10032744`). Child via `.GenerateSprite(p1, rec 0x200, now)`, `+0x1b2 = 1`,
  pushed 3 px/frame, the clip edge per direction, the sound at frame 3, release at `+0x150 > +0x154`. Level 21 —
  synthetic.
- **Tests (4):** `testPipeSpawnsChild` · `testEmergingClipAndPush` · `testEmergingStillCollidable` · `testPipeChildNotCounted`.
- **Gate:** G2 606. Wave 5.4 end: G3, GWB by day. **Commit:** `FerazelCore: enemy pipes; 4 tests`.

### Wave 5.5 — level 5, up to the Warrior's arena

#### OX — ⚑ MAJOR — OmniPx modes 2/4/5 (level 5's moving backdrop) (→ 611)
- **Files:** `Sources/FerazelCore/World/OmniPx.swift` (new), `Sources/FerazelCore/Seams/DrawOp.swift` (`.omniPx`, S3),
  `Sources/FerazelCore/Session/FerazelSession.swift` (the op at `.PaintFrameWrap`'s M l. 9434, drawn frames only),
  `Sources/FerazelCore/Front/LevelRun.swift` (`:622` already clears `omniPxActive`), `Sources/FerazelCore/Flow/LevelFlow.swift`
  (setup at level start M l. 2540 — `.SetupOmniPx(0)`, right after the `G+0x174` clear at M l. 2539; the counter on
  `LevelCarry`; turn off/kill at the loop's end M l. 5321–5322), `Sources/FerazelCore/World/LevelHeader.swift` (Core's
  copy of the backdrop factors is zeroed by `.TurnOnOmniPx`, below), `Sources/FerazelRender/Frame/{FrameRenderer,ParallaxBlitter}.swift`
  (the 128×128 port as PxBack slot 0; the factor backup/zeroing of `.TurnOnOmniPx`; `ParallaxBlitter.omniPxActive`
  (`:99`, `:288`) is the existing flag the op sets — reused; the faces 6200/6201, 6300/6301 under the level+sprite
  CLUT), `Sources/FerazelRender/Screens/ScreenRenderer.swift` (`:63–:125`, its exhaustive `switch`: `.omniPx` →
  `throw Refusal.levelOp("omniPx")` like every other level op — a new refusal, so also a row in DA's table),
  `Tests/FerazelCoreTests/SessionTests.swift` (`:291`, the `kinds` switch over `DrawOp` gains `.omniPx`),
  `Tests/FerazelRenderTests/DrawModeAuditTests.swift` (the OmniPx rows), `Tests/FerazelRenderTests/OmniPxTests.swift`
  (new). Any other exhaustive `switch` over `DrawOp` the compiler finds (both packages, both shells) is added and
  recorded (G6's amended list). **G5 is named for OX** (a `DrawOp` case reaches the Mac app's code), with GW1–GW4.
- **Contract:** rendering-omnipx-titles §1, §3.1–§3.5. Dump: M l. 13019–13547. Modes 2/4/5 share the base-cell path
  (cells 6 + (c >> 1), c reset at 18) and the two faces (acc mod 0x8000, toroidal wrap); mode 0 off. **Modes 1/3/6/7
  and ≥ 8 stay refused at level open** (◇ Phase 6: rain, thunder, interlace, ping-pong — levels 15, 70; the level-open
  refusal is caught by `GameFlow.swift:555` and is not a quit). No RNG in modes 2/4/5. **The op is emitted only while
  OmniPx is on** (`G+0x174` set, mode ≠ 0): levels 1–4 (mode 0) emit no `.omniPx`, their op streams and every golden
  are unchanged. **The counter (M l. 13471):** `c` + 1 **per active face inside the face loop** (M l. 13469–13514) —
  so "+2 per drawn frame" holds only with two faces (level 5, mode 2); the base-cell copy resets `c` to 0 when it
  exceeds 0x11, before the copy (M l. 13430–13432). **Face positions wrap as 16-bit:** `fx += vx`, `fy −= vy`, then > 0x7fff
  → − 0x8000 and **negative → − 0x8000 as a 16-bit short** (M l. 13476–13487) — model with `Int16` wrapping
  arithmetic, never a modulo on `Int`. **`.TurnOnOmniPx` (M l. 13019–13060)** for modes other than 4…7 (so mode 2)
  backs up and then **zeroes the level header's backdrop factors** (`hdr+0x326c + 2·i`, i < 0x2000, and `hdr+0xb26c`)
  — it runs after the level's sprite Setup, so every later Core read of those header fields sees zeros (Core's header
  copy is zeroed too, not only Render's).
- **Tests (5):** `testOmniPxSetupMode2` (faces 6201/6200, fx/fy 0x40/0x80, vx/vy per §3.3) · `testUpdateCyclesBaseCells`
  (9-frame cycle; c + 1 per active face — + 2 a drawn frame with level 5's two faces; one face → + 1) · `testFaceWrapToroidal` (incl. a negative position wrapping as a 16-bit short; and after `turnOn` the header
  factors read 0 from Core) · `testCounterCarriesAcrossLevels` ·
  `testLevel5FirstFrameDraws` (a level-5 `FrameRenderer` executes the first frame's ops with the OmniPx op, no refusal).
- **Gate:** G2 611 (DA's table gains the OmniPx rows). **Commit:** `Ferazel: OmniPx modes 2/4/5 — level 5's moving backdrop; 5 tests`.

#### LV5 — ⚑ MAJOR — level 5 "Manditraki Warrior" enterable: the arena lock, the camera pan, the gate, the boss music, the Warrior stand-in (→ 617)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (`1...5`; report "(Phase 6)"), `Sources/FerazelCore/Camera/BossArena.swift`
  (new), `Sources/FerazelCore/Camera/Camera.swift` (`.FindUpperLeftCorner`'s arena bounds and pan; `:46` relabel),
  `Sources/FerazelCore/Player/Player.swift` (`.PlayerConstraints`' arena clamp — the routine lives there today), `Sources/FerazelCore/World/Movers/BoxSprite.swift`
  (the 2940 gate's p1 −1 arm), `Sources/FerazelCore/World/Enemies/Warrior.swift` (new: Setup as read, M l. 72989–73079,
  in the dump's order — `.InitSprite`; **`+0x84 = 0`, `+0x86 = 0`, `+0x80 = 0xc` (M l. 73015–73019: the layer — the
  Setup runs inside `.MTNewSprite` before `.MTInsertSprite` (M l. 30711 / 30716 / 30719), so layer 12 overrides the
  caller's and decides the Warrior's place in the active list and its draw/erase order)**; Handle `+0x4c` 0x100a0494,
  Hit `+0x5c` 0x100a0d44, HitTile `+0x1f8` 0x100a0d40, Kill `+0x50` 0x100a0d3c stored (the stand-in's Handle/Hit/Kill
  bodies are ◇); `+0x18a = 1`; the three sets marked; `+0x170 = p4` (record +0xe); `+0x110 = 0x122`; `+0xc0 = 0`; **p4
  ≠ 0 → HP `+0xa4` 2000, `noBossAlive = 0`, `+0x88 = 0`; p4 = 0 → HP 0x4b0 and no boss flag**; `+0x1b4 = 1`; `+0x168` =
  HP; **the re-seat `+0xc = +8`, `+0xa = +6` (M l. 73046–73047)**; hot rect (0x1a, 0x17, 0x4a, 0x3a); `+0x150 = −1`,
  `+0xb0 = 6`, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`; **`+0xa6 = FastRand(10)`**; the record's p2 (record +0xa)
  **written back 0 → 0x96**; `+0x15c` / `+0x160` = `+0xc` − 350 / `+0xc` + 350 (the re-seated x); `+0x168 = +0xc`;
  `+0x164 = 0`; **`+0x17e = (FastRand(100) < 51)`**; `+0xc0` = the 0x71c set's first face; `+0xf0 = 0x1e`; counted only
  inside the window; `+0x14`/`+0x1c` = `+8`/`+6` << 8. `.InitWarriorSprite` M l.
  72975–72988: three cached sets 0x71c (8), 0x71d (8), 0x71e (6), each marked by the Setup; the Handle **◇** —
  `.StandardSpriteHandles` + its Setup face, no AI, no shot, no Hit callback, `// later: Phase 6`),
  `Sources/FerazelCore/Sprites/{SetupFaces,SpriteSlot}.swift` (`.warrior`; whatever level 5's census
  finds: platform 1403 p1 52, Box 1065, decorations 2820–2841, Bonus 3100/3214), `Sources/FerazelCore/Front/LevelRun.swift`
  (`:504–:512` the boss-music rule at level start, **M l. 5218–5221**, and the in-loop block `:684–:690`, **M l.
  5266–5269**; level 5's picture-cache marks incl. the Warrior's sets), `Ferazel/Shared/FerazelDriver.swift` (`:12`,
  `:40` — the `FerazelLevel` comments' "(1…4)" → "(1…5)"; the code reads `BuiltLevels.range`; comment-only, both
  shells), `Ferazel/Windows/Tests/FerazelWinKitTests/FerazelSettingsTests.swift` (`:17` comment "(1…4)" → "(1…5)"; its
  table's `("9", 1)` still holds; no new row, WinKit ladder unchanged), `Tests/FerazelCoreTests/LevelFiveTests.swift`
  (new), `Tests/FerazelCoreTests/GameFlowGameTests.swift` (`:247–:249` `1...4` → `1...5`; `:460–:478` the not-built
  walk retargeted to node 10 via level 5's exit p1 1 and the report text; **`:691–:699` the "seven" original save at
  level 5 now Continues into level 5** instead of the not-built report — re-derived), `Tests/FerazelCoreTests/LevelFourTests.swift`
  (`:153–:177` `testBuiltLevelsFour`: the range and the "Level 5 is not built yet (Phases 5-6)." report become level 5
  entered from level 4's exit p1 1; header comment `:7–:8`), `Tests/FerazelCoreTests/LevelThreeTests.swift` (`:8` header
  comment's range), `Tests/FerazelRenderTests/FaceTests.swift` (level 5's spawnables). **Seat ruling (in advance) for
  the existing tests above:** each is retargeted to what level 5 being built does, every expected value re-derived from
  the dump and the data, every changed value listed with its cause in "As executed"; never edit to make a number agree.
- **Contract:** bosses §1.1–§1.4 (framework only); world-data-format §3.2 (`hdr+0x2724` −1444, `+0x272e` 0, music 23,
  start at the right edge facing left `0x26c8`). Dump: `.PlayerConstraints` M l. 43991–44126, `.FindUpperLeftCorner` M l.
  5882–6239, `.SetupLevelSprites` M l. 1940–2103 (`fed4 = 0`, `fed0 = 1` at M l. 2016–2019, verified), `.GameLoop` M l.
  5093–5328 — **the boss-music rule:** at level start (M l. 5218–5221) `hdr+0x284a = 0x1e` only when `hdr+0x2724 ≠ 0
  ∧ fed0 ≠ 0`; in the loop (M l. 5266–5269) track 30 is set (async fade 0x3c) when `hdr+0x2724 ≠ 0 ∧ fed0 ≠ 0 ∧ the
  current track ≠ 0x1e ∧ …`. So **level 5 plays its own track 23 from the start** (the Warrior's Setup cleared `fed0`
  before the loop), **the arena lock changes nothing musically**, and track 30 comes only after the Warrior's Kill sets
  `fed0` (Phase 6). **`.KillWarrior` itself (M l. 73486–73493), when p4 ≠ 0:** snd 453 at 48000, **screen shake
  `_DAT_1009ffa0 = 0x1e`** (the shake counter, engine §5 / `Camera.swift` `shake` — not the music track, which is
  `_DAT_100a5be0`), flash `_DAT_100a00fc = 3`, `fed0 = 1`; the music switch to 30 is still the loop rule's on the next
  frame. Phase 6 builds all four. `.HandleBoxSprite`'s 2940 arm (p1 −1: open
  while `fed0 == 1` — rise 2 px/frame to 100 px above `+0x158`, else back down). Level 5 census (Research note 2): 16
  types, 32 records. With the ◇ Warrior alive (`fed0 = 0`): walking left past x 1384 locks the arena (`fed4 = 1`, the
  40-frame pan), the player is clamped at x ≤ 1384, the gate at x 416 stays shut. **Camera bounds
  (`.FindUpperLeftCorner`, `hdr+0x2724` < 0, boss alive):** before the lock the scroll's lower bound is |−1444| = 1444
  (M l. 5941–5948); while locked and the pan counter is < 0, 1444 − 0x260 (M l. 5953–5954), else −32000, and the upper
  bound is 1444 − 0x260 (from `sVar26` = 1444, M l. 5961, applied at M l. 6171–6172); the pan shifts both by 16·|counter|
  (M l. 6011–6028);
  the Warrior stands and hurts on contact (`.HitPlayerSprite` step 7: 0x70, invul 60). Leaving: Esc / ⌘W abort as
  Phase 3. A synthetic `noBossAlive = 1` (what `.KillWarrior` will set, Phase 6) opens the gate, releases the arena and
  switches to track 30 — tested, unreachable in play this phase.
- **Tests (6):** `testLevel5SetsUpEveryRecord` (32 records, no `notTranscribed`; the Warrior record: the two
  `FastRand`s in order (R(10) → `+0xa6`, R(100) → `+0x17e`), p2 written back 0 → 0x96, `+0x1b4` 1, `+0x88` 0, `+0x170`
  = p4, **`+0x80` 12 (and its place in the active list follows layer 12, not the caller's layer), `+0x84` 0, `+0x86`
  0, `+0xc`/`+0xa` re-seated from `+8`/`+6`**, `+0x15c`/`+0x160` = the re-seated x ∓ 350, the four procs, HP and the boss flag for level 5's p4 — plus a synthetic p4 = 0
  record: HP 0x4b0, `noBossAlive` untouched) · `testArenaLocksAtX1384` (lock, pan counter −40 → 0 over 40 frames,
  clamp; **before the lock**, boss alive, the scroll's lower bound is 1444) · `testCameraWindowWhileLocked` (**during
  the pan** the lower bound is 1444 − 0x260, after it −32000; the upper bound) · `testGateStaysShutWhileBossAlive` ·
  `testSyntheticKillOpensGateAndTrack30` · `testBuiltLevelsFive` (`1...5`; level 5's exit p1 1 → node 10 → "Level 10 is
  not built yet (Phase 6)."; `startLevel` 5 accepted).
- **Gate:** G2 617, G5. Wave 5.5 end: G3, GWB by day, the full GE on levels 1–5 (both paths). **Commit:** `Level 5 enterable: the arena lock and camera pan, the gate, the boss music rule, the Warrior stand-in, BuiltLevels 1...5; 6 tests`.

### Wave 5.6 — phase end

#### A5 — minor — the three checks, the `later: Phase 5` sweep, both builds staged, one gate card
- **Files:** `Ferazel/WHAT-TO-EXPECT.md` (the Phase 5 card, Mac part), `Ferazel/WINDOWS-WHAT-TO-EXPECT.md` (Windows part,
  same card's second half — one card, two files as Phase W keeps them), any `Ferazel/Core/Sources` file with a leftover
  `// later: Phase 5` (comment-only relabels to the real owner), `tools/stage-ferazel.sh` /
  `tools/windows/stage-ferazel-win.sh` (only if needed), `docs/ferazel/port-gap-ledger.md` (a dated "after Phase 5"
  note: what the checks covered).
- **Contract:** (1) **GE** — visit sweep `both`, random-play bot `both` (levels 1–5, default seeds/minutes), G2's
  load-every-face tests and DA — every one exit 0 / green; **a non-zero exit stops the phase end**: each row becomes a fix
  task, nothing is staged (Q15, Ruling 6). Their summary lines go on the card. (2) `grep -rn 'later: Phase 5'
  "$WT/Ferazel/Core/Sources"` prints nothing (owners per "Carries owned"). (3) Stage both (`tools/stage-ferazel.sh`,
  `tools/windows/stage-ferazel-win.sh`), GW5; by day G9M, GW6, GWB, GW4R (else "boot check owed (night rule)"). (4) The
  FABLE-GRADE phase review over the whole phase diff (Mac + Windows) + the card (D34; told: no background agents), its
  fixes, re-stage. **STOP for Ben** (QUESTIONS item: the Phase 5 gate, Mac and Windows).
- **Gate:** G1, G2 617 / 2 skips, GW2 81 / 2 skips, G3, G5, GW1–GW4, GW5, GE; by day GWB **614 / 0 / 3 / 0 (of 617)**,
  GW6, G9M. **Commit:** `WHAT-TO-EXPECT: Phase 5 gate card (through the first boss door), Mac and Windows`.

---

## What Ben (and Andrew) check — the Phase 5 gate card ("through the first boss door")

Play `~/Desktop/Ferazel's Wand.app` (Mac) and `Ferazel's Wand (Windows).zip` (Windows), New Game or a Phase 4 save,
beside the Let's Play (https://www.youtube.com/watch?v=ESuyxMUEzDw). Jump to a level with the hidden switch `-FerazelLevel N` (1–5) — the same
argument on the Mac (`open -n … --args -FerazelLevel 5`) and on the Windows exe's command line (Phase W Ruling 11). **Levels 1–5 can be entered; level 5's Warrior stands still
(Phase 6); level 10 and later say "not built yet (Phase 6)".**
1. **Goblins (level 1 onwards)** — the axe throwers walk into range, throw axes in arcs, and the ones that never walk
   stay put; the spear guards turn to face you, block shots with a metal clang and thrust; the boulder goblin on level 1
   and level 4 throws boulders that bounce a few times and burst into shards (the dark ones explode). Goblins growl and
   taunt now and then, cry out when hit.
2. **Crawlers and Roaches** — crawlers hop, roaches scuttle back and forth; a falling crate or boulder crushes them.
3. **Bats (levels 2–4)** — sleeping bats wake when shot or approached and chase; the level-3 path bat flies its route;
   bats burst into blood and drop coins.
4. **Frogs (levels 2–4) and Blobs (3–4)** — frogs leap and spit; blobs ooze and attack.
5. **Getting hurt** — touching an enemy or its shot knocks you back by its speed, splashes blood, sometimes loses coins
   (they fly out and blink); a big hit makes the big "ouch". Dead enemies never hurt.
6. **Hurting them** — every spell, the dagger and the other held weapons, crushing boxes, the big explosion and the
   Ring of Smiting; goblins die with their death frames and burn away; a goblin dying in water leaves a corpse that
   floats and can be stood on; scores add up (goblin 500–800, crawler 500, roach 600, bat 500); the stage-complete panel
   counts the enemies defeated.
7. **Statue spell on an enemy** — it turns to stone for 4 s, you can stand on it, it thaws 200 HP weaker.
8. **Shields** — a raised shield blocks shots from the front with a clang; the Magical Shield reflects darts and spines
   (they burn away) and shows its crouch picture.
9. **Level 4's boulder spouts** fire boulders when their button is pressed.
10. **Under water** the screen takes a blue (green in acid, red in lava) tint, and clears when you surface.
11. **Level 5 "Manditraki Warrior"** — the moving sky behind the level; its own music from the start (the boss track
    comes only after the Warrior is beaten, Phase 6 — the arena locking does not change the music); walk left: the
    camera pans and the arena locks behind you, the gate ahead stays shut, the Warrior stands (Phase 6 builds the
    fight) and hurts on contact; leave with Esc → abort. Expected missing until Phase 6: the three falling crates the real
    Warrior drops from above on its first frames (type 0x433 into `+0x1d4/+0x1d8/+0x1dc`, M l. 73145–73182) do not fall. If you use the Ring of Smiting on it, it may stop hurting but
    stays standing and the gate stays shut — expected until Phase 6.
12. **Readings Ben can't see but may feel (MED):** the tint tables' colours, the burn-away, the backdrop's look, the
    goblins' voices' pitch spread.
**Windows part:** the same 12 points on a Windows PC; please also note anything that differs from the Mac.
**Machine checks run for this card:** the visit sweep (both shells), the random-play bot (both shells), the face-load
tests and the draw-mode audit — summary lines pasted here by A5.
Known stand-ins/deviations: the Warrior (Phase 6); levels 10+ (Phase 6); the enemies first placed after level 5
(Dillo, Gremlin, Wraith, Salamander, Crab, enemy pipes, geysers) are built and machine-tested but not reachable yet.

---

## Execution order

| run | tasks, in order | review legs (all Opus) | Core after |
|---|---|---|---|
| 1 | **PB → SP → RV** (wave 5.0) | one each | 508 |
| 2 | **DK → UT ◈ → DA** (wave 5.0) | one each | 515 |
| 3 | **RB ⚑** (wave 5.0 end) **→ EC ⚑** | two each | 525 |
| 4 | **ES ⚑** (wave 5.1 end) **→ WK1 ⚑◈** | two each | 545 |
| 5 | **CR ⚑◈ → WK2 ⚑◈** (wave 5.2 end) | two each | 559 |
| 6 | **BA ⚑◈ → FR ⚑◈** | two each | 576 |
| 7 | **BL ⚑ → GF ⚑** | two each | 590 |
| 8 | **DL → GY ⚑ → PI** (wave 5.4 end) | GY two; DL, PI one | 606 |
| 9 | **OX ⚑ → LV5 ⚑** (wave 5.5 end) | two each | 617 |
| 10 | **A5** + FABLE-GRADE phase review + fixes | one + Fable | 617 |

Every run is 2 tasks, or 3 with at most one ⚑ (D34 cap rule). G3 + GWB (by day) at each wave end; GE at the end of
waves 5.2 (levels 1–4, `core`), 5.3 (levels 1–4, `core`), 5.5 (levels 1–5, `both`) and A5 (`both`, mandatory).
No HectorKit task: G1 = HK `35a85ba` untouched for the whole phase.
- **Dependencies:** SP, RV, DK, UT independent; DA after DK (A13 drawn) and UT; RB after DA and PB; EC after RB; ES after
  EC; WK1 after ES (axes, spear thrust); CR after EC; WK2 after WK1 + ES; BA after ES (spit) + EC; FR after ES + EC; BL
  after EC; GF after ES; DL after ES; GY after EC; PI after WK1 + BL + BA (its children are Walkers, Blobs, insects); OX
  independent of the enemies (after DA, its rows); LV5 after OX + WK1 (contact path) + ES; A5 after all.
- **File overlaps that force order:** `SpriteSlot.swift` (EC, WK1, CR, BA, FR, BL, GF, DL, GY, LV5), `SetupFaces.swift`
  (EC, WK1, CR, BA, FR, BL, GF, DL, LV5), `HitPlayerSprite.swift` (EC, ES, BL, GY), `FerazelSession.swift` (SP, EC, ES,
  OX), `LevelRun.swift` (SP, EC, ES, WK1, CR, WK2, BA, FR, OX, LV5), `BoxSprite.swift` (ES, BA, GY, PI, LV5),
  `FrameRenderer.swift` (SP, OX), `BootFaces.swift` (ES, WK1, and any class task whose set is a boot set),
  `SpriteBlitter.swift` (SP, DK, DA, EC), `Ferazel/Shared/FerazelDriver.swift` (SP, LV5), `ScreenRenderer.swift` (OX),
  `LevelFourTests.swift` (WK1, LV5), golden test files (UT, WK1, CR, WK2, BA, FR),
  `proof-b-ferazel.sh` (PB, RB), `smoke-ferazel-win.sh` + `WinReferenceFramesTests.swift` (PB and every ◈ that moves a
  Windows reference).
- A task merged out of order rebases; the orchestrator adjusts the ladder by N.

## Orchestration notes
- Foreground only: implementers and reviewers as foreground subagents, one message may hold parallel legs (run 10
  lesson); never background shells; poll long gates with `stat -L` on the transcript, never sleep loops.
- Reviewers build in a `mktemp` archive with their own `WIN_BUILD_ROOT` and HectorKit symlink in temp (runs 19/28).
- The visit sweep and the bot are long: run them once per wave end named above, with `JOBS` = half the cores; record
  the wall time in "As executed". They write only to `$OUT` (temp).
- Night rule: GWB, GW4R, GW6, G9M by day only; everything else at any hour. A ◈ task by night moves the Windows
  references through PB's in-process test; GW4R confirms by day.
- Ben may commit to local main mid-run (runs 25/27/31): rebase before merge, re-run G2.

---

## Stand-ins kept (◇, named) and the phase that replaces them

| ◇ | where | replaced by |
|---|---|---|
| The Warrior's Handle/Hit/Kill: it stands in its Setup face, hurts on contact as read, has no Hit callback, never dies; the gate stays shut while it lives; the real Handle's three falling-crate children (0x433 into `+0x1d4/+0x1d8/+0x1dc`, spawned when p4 ≠ 0 on its first frames, M l. 73145–73182) are not spawned | LV5 (`Warrior.swift`) | Phase 6 |
| The Warrior under the Ring of Smiting (Ruling 3a): `.SmiteEnemies` targets its Handle (0x100a0494) as the binary does, so a seed explosion lands on it and can take its HP below 1 — with no Kill until Phase 6 it stays standing, harmless (a dead attacker hurts nobody), `fed0` stays 0, the gate stays shut for good and only Esc / ⌘W leaves | EC (target list) + LV5 | Phase 6 (the Kill) |
| The other bosses (Wizard, Chief, Demon, Xichra) stay `.inert`; their projectiles' spawners | — | Phase 6 |
| OmniPx modes 1/3/6/7/≥8 (rain, thunder, interlace, ping-pong) refused at level open (caught, not a quit) | OX | Phase 6 (levels 15, 70) |
| Geyser kinds 3/4: the base face past the 12-face cache draws nothing (unplaced) | GY | kept (as read, unreachable) |
| `BuiltLevels = 1...5`; the not-built report "(Phase 6)" | LV5 | Phase 6 |
| Refusals kept and pinned unreachable: A14 light byte −1, mode 5 rotated/scaled, 0xa mirrored, 0xb rotated, modes 2/7/8/0xd/0xe/≥0xf, water kinds ≥ 6, fire/ripple backdrops | DA | Phase 6 (the levels that place them) |
| `ParticleLife` vs CLUT 222 (levels 52/55) | carried | the phase that loads 52/55 |
| `.Victory`, falling rocks 1075/1076, spiked balls, magic carpet, rope bridge 1466, boss grab `_DAT_100a0570` writers, countdown digits | — | Phase 6 |

## Carries owned (every `// later: Phase 5` at 6a70bce, plus the named carries)

| carry (file:line at 6a70bce, or source) | owner |
|---|---|
| underwater tint — `PlayerLiquids.swift:137–139`, `Player.swift:360` (D38 A4; labelled `later: no Phase-2 seam`, outside A5's grep — UT removes the labels) | UT |
| Magical Shield crouch face — `PlayerStates.swift:556` (D38 A4) | ES |
| `+0x1b5` counted only inside `_DAT_1009fe8c` — `SetupFaces.swift:538–:649` stubs (run 29 [MED]) | EC |
| Bat cache marks: Bat types 0x6ce–0x6d5 mark the 0x6cc set (run 29), plus 0x744/0x74d/0x73a/0x73b; Bat path mode in `voicePitch` | BA |
| Roach Setup `+0x154 = x`, speed 0x4b0, M l. 64945–64946 (run 29) | CR |
| spout shot Setup draws + boulder spouts firing — `BoxSprite.swift:12/:776/:785` (run 27, BC44) | ES |
| Smite centre + enemy Handles — `Smite.swift:23/:26` (run 25) | EC |
| crystal shards' Blob-attacker exception — `HitPlayerSprite.swift:997` (run 25, MS) | BL |
| eleven enemy statue sites — `StatueSprite.swift:5`, `SpriteSlot.swift:513` (run 28) | each class task (EC helper) |
| Shadow Double flag clears (run 24 → SD) | **done** by SD (run 26, M l. 45410/45478) — nothing owed |
| geysers NR 2–4 (design §9 (b)) — `BoxSprite.swift:14/:142/:421/:1172`, `GroundCeilingEffects.swift:136`, `HitPlayerSprite.swift:180/:219/:1159` | GY |
| enemy pipes — `BoxSprite.swift:14/:421` | PI |
| enemy drops of items 8/21 (§9 (c)) — `BoxSprite.swift:1148` (crate's Bat arm) | EC (scan) + BA (the arm) |
| EnemyShot arms — `PlayerShotHits.swift:151/:189/:191`, `Pentashield.swift:7`, `ButtonSprite.swift:101`, `BackgroundSprite.swift:402/:408/:410/:437`, `HitPlayerSprite.swift:994/:1032` | ES |
| Crawler shot arm — `PlayerShotHits.swift:163/:228` | CR |
| enemy Handles dispatch — `FerazelSession.swift:512/:1032`, `SpriteSlot.swift:482`, `SpriteWorld.swift:435` | EC (cases) + class tasks (bodies) |
| enemy Setup stubs — `SetupFaces.swift:538/:550` (Bat), `:570` (Blob), `:587` (Frog), `:649` (others) | BA, BL, FR, GF/DL |
| 1207 vs enemies — `GroundCeilingEffects.swift:68–:69` | each class's Hit (EC relabels) |
| burn-away — `StandardSprite.swift:94/:124` (labelled `later: burn-away` / `later: .HandleBurn`, outside A5's grep — EC removes the labels) | EC |
| boss music rule — `LevelRun.swift:504–:512`, `:684–:690`; boss Setups' `fed0` | LV5 |
| level-load cache marks for other classes — `LevelRun.swift:1051/:1117` | each class task; LV5 for level 5 |
| boss grab — `PlayerStates.swift:371`, `PlayerState.swift:196` | **Phase 6** (Chief, Xichra) — A5 relabels |
| `HitPlayerSprite.swift:10` header, `PlayerStates.swift:8` header, `Camera.swift:46`, `BackgroundSprite.swift:402/:437` stale "later: SH" | A5 sweep (comment-only) |
| Q15 items 1–6 | SP (1, 3, 4), DA (2), RB (5), RV (6's code items); shrink rule → Open question 3 |
| gap ledger #3 empty-inventory box | RV |
| gap ledger #4 voice eviction | **recorded deviation** (Ruling 10, KD1) |
| A13 lit sprite at full darkness | DK |
| save write-back flags `+0x188…+0x18b`, `+0xea` set at the dump's sites by every later Setup (D38 seat ruling (1)) — Phase 5's enemy Setups / Handles / Kills | each class task ("Every class task also") + LV5 (the Warrior's `+0x18a`) |

## Known deviations (forced by the platform or ruled; recorded in D44)

1. **Voice eviction (gap #4):** a play that pushes another sound out of the 16-entry list is not modelled in Core's
   `SoundVoices`, so an idle-only check can be off for one tick. Reasons: no quit, no misdraw; a faithful model needs
   the shell's voice table (ids, priorities, volumes) in Core every tick — a seam change on both shells — and the
   query is already tick-granular (D38 KD2), so it would still not be exact; headless runs use the silent mixer. Revisit
   if Ben hears a difference. [MED]
2. **Tint colours** of the remap tables (Walker tiers, Crawler, statue) through the replica's Color2Index reading [LOW].
3. **The underwater tint** is applied by FerazelRender's screen gamma to the presented image (as every fade since
   Phase 3), not the monitor's gamma [MED].
4. **Tick:** every enemy timer runs at the 30-step cap (D30, D39 Q9).
5. **The tint's 1 ms library wait** (UT): `.TintScreen`'s `MT_FadeToColor(…, 1 ms, linear)` blocks for about a
   millisecond while it reaches the full percent; the port applies the percent at once and does not wait (under one
   tick, nothing drawn in it) [MED: the library's timing].

---

## Pre-execution self-audit

1. **Design §8 row 5 coverage.** ground (WK1, WK2, CR, DL) ✅; flyers (BA, GF) ✅; water/cave (FR, BL) ✅; enemy shots
   (ES) ✅; damage both ways (EC, ES, each class's Hit) ✅; particles in full (EC burn; blood/explode/glow exist) ✅;
   effects (ES kill effects, EC hazards) ✅; §9 (b) (GY) ✅; §9 (c) enemy half (EC scan, BA) ✅; "through the first boss
   door" (OX, LV5, Ruling 2) ✅; Q15 1–6 (SP, DA, RB, RV, Open q. 3) ✅; the two Phase 2/4 gaps (UT, ES) ✅.
2. **Numbers sourced.** Function spans: Research note 1 (computed from the dump's headers). M lines re-read
   2026-10-30: 2016–2019, 4215–4275, 4674–4719, 9428–9436, 31704–31727, 46440–46480, 64940–64950, 68092–68107; fix
   round 1 re-read: 2536–2542, 4262–4270, 5212–5221, 5262–5269, 5930–5997, 10250–10260, 13019–13060, 13405–13514,
   30739–30765, 32612–32628, 46446–46478, 46981–47046, 48359–48444, 49885–49929, 56685–56700, 56773–56802,
   58614–58633, 72975–73080, 73465–73486, 79455–79540; TOC slots 0x100a0120/0130/0134 and 0x100a0494 read with
   `docs/ferazel/tools/pef.py`. Bank
   numbers are cited by section; each task re-reads. Ladder arithmetic (after fix round 1: RV 2 → 3, ES 10 → 11): 502 + (0+3+3+2+3+2+2) = 517; + (8+11) = 536;
   + (9+8+6) = 559; + (9+8+7) = 583; + (7+5+7+4) = 606; + (5+6) = 617 ✅ (each task's "Tests (N)" equals the names it
   lists). ⚑ MAJOR: RB, EC, ES, WK1, CR, WK2, BA, FR, BL, GF, GY, OX, LV5 = **13**. Every run ≤ 2 ⚑, 3-task runs hold ≤ 1.
3. **Names checked against the code (6a70bce).** `SpriteHandler` (`SpriteSlot.swift:483ff`, `.inert` at `:485`),
   `forClass(type:)`, `FerazelSession.swift:512` (`.inert` no-op), `:1006–:1026` (`wrapDrawSpritesOp`, `diffuseSeeds`),
   `FrameRenderer.swift:~371` (`wrapDrawSprites(… drawn:)`), `SpriteBlitter.swift:170` / `:571` (`Refusal.darkness`),
   `LevelServices.DiffuseRandoms`, `BuiltLevels.range` (1...4), `ScreenGammaOp` (5 cases), `ScreenFade.fadingEnabled`,
   `SoundVoices.playing: Set<Int16>`, `SoundTool.listLength` 16, `StatusBar.swift:188`, `BootFacesTests` (2 tests),
   `VisitSweepTests` / `WinVisitSweepTests` (opt-in `FERAZEL_VISIT_SWEEP`), `proof-b-ferazel.sh:117–127`,
   `smoke-ferazel-win.sh:59–64`. Fix round 1: `FerazelSession.swift:437/:1008` (both `diffuseSeeds` sites),
   `LevelRun.swift:597/:622`, `Shared/FerazelDriver.swift:12/:40/:437`, `LevelServices.swift:14` (`LevelFaces`),
   `FrameRenderer.swift:201–209/:316`, `SpriteBlitter.swift:569–579`, `LevelTables.swift:42–44`,
   `ScreenRenderer.swift:61–125`, `ParallaxBlitter.swift:99/:288`, `GameGlobals.swift:67`, `BootFaces.swift`,
   `CachedFaces` (`LevelRun.swift:1039`), the test lines each task now names, `tools/ferazel-visit-sweep.sh:75`,
   `proof-b-ferazel.sh:22`; Windows `Package.swift` (the test target does not depend on `FerazelWin`).
4. **Layering.** Core gains no Apple framework; OmniPx positions are integers in Core, the port is Render's; the bot
   and audit are tests; the shells' only source change is `Ferazel/Shared/FerazelDriver.swift` (SP's closure wiring;
   LV5's comments).
5. **Risk.** Biggest: the ◈ tasks — five classes come alive on the golden routes; each must show the cause by the
   switch-off check. Second: the bot finding real refusals (good — but it can stall the phase: each row is a fix task
   inserted before A5). Third: LV5's arena + camera (the pan shifts both bounds by 16·|counter|). Fourth (settled in
   fix round 1): DK's over-read target is the ambient table, read from the data section.

---

## Open questions for Ben (non-blocking; execution does not wait — D34)

1. **"Through the first boss door"** — read as: levels 1–4 with every enemy alive, and level 5 open up to the Warrior's
   arena (the arena locks, the gate stays shut, the Warrior stands still until Phase 6). (a) as read (default); (b) keep
   level 5 closed until Phase 6 builds the Warrior. Recommendation: (a) — the arena, camera and backdrop are built and
   checked now, Phase 6 only adds the fight.
2. **Drawing refusals** — the game quits if it is ever asked to draw something the port cannot; the new checks make
   that unreachable in the built levels. (a) keep quitting (loud, caught by the checks) (default); (b) draw nothing and
   write a log line instead. Recommendation: (a).
3. **The picture-shrink rule** (stage screens, map, light 806; Q15 item 6): a capture from your Mac OS 9 VM of any
   stage screen or level 2's big light, or a Let's Play frame number, settles whether QuickDraw samples rows from the
   top or the centre. No task until then; it cannot quit the game.
4. **The empty item box** (gap #3): the port now draws what the original reads there (RV). If you ever see the
   original with nothing in the inventory, tell us what the box shows.
5. **Enemies first placed after level 5** (Dillo, Gremlin, Wraith, Salamander, Crab, pipes, geysers) are built and
   tested now though unreachable until Phase 6 — fine? Default: yes (as D38 Ruling 11 for player systems).

---

## Bank corrections to append (each as a ⚑ planner note in the named file, by the task named)

BC51 `draw-effects.md` §2.6 — the colour-pass row guard the code follows (SP; text from `SpriteBlitter`'s mode-5/0xa
walk and Q15 item 3).
BC52 `held-item-melee.md` NR 4 / INDEX item 29 remainder — enemy drops: the scan of every enemy routine's spawns
(EC; expected money bags 0x50d/0x50c (goblins, `.PopupGoblinCoins`) and coins 0x516; scan the bare token `MTNewSprite`).
BC53 `geysers.md` NR 2 — closed: `.IdleToActiveSprite` (M l. 4215–4275) calls `.MTNewSprite` with setup 0, restores the
0x220-byte snapshot, clears `+0xe9`, calls `+0x58` if set and kills a record whose `+0x4c` or type is 0 — no Setup
re-run, no second `AllocateGameMem(0x44)`; a geyser has no `+0x58` proc (only `.SetupRopeSprite` M l. 71122 stores
one) and `.MTKillSprite` frees nothing, so the `+0x9c` buffer survives idling.
BC54 `port-gap-ledger.md` §2.1 — A13 built (DK), A22 fixed (SP), maintained by `DrawModeAuditTests` (DA).
(Tasks add BCs for every dump-over-bank disagreement they meet.)

---

## Research notes (where every number came from)

1. **Function spans** (computed 2026-10-30 from the committed dump's 1,236 `// ==== name @ addr ====` headers: start =
   header line, end = next header − 1). Enemies: Crawler 56123–56745, `.HandleStatueSprite` 56521–56555, Walker
   56746–58696 (Init 56746, gob sound helpers 56773–56897, Setup 56898, `.AxGoblinCoreLogic` 57101, `.PopupGoblinCoins`
   57348, Handle 57507, `.HurtGoblin` 58472, Hit 58506, Kill 58612, HitTile 58634), Roach 64886–65262, Blob 67661–68091,
   Bat 68092–69079, Gremlin 69080–69819, Floater 69820–70110, Frog 70111–70641, Salamander 70642–70981, Dillo
   72276–72974, Warrior 72975–73532, Crab 73957–74323. EnemyShot 51393–52260; `.ShieldBlock` 48359–48444; `.HurtPlayer`
   47955–48112; `.HitPlayerSprite` 48445–49929; `.HitPlayerShotSprite` 50947–51071; `.KillPlayerShot` 51072–51392;
   `.SmiteEnemies` 46981–47046; `.HurtSprite` 32705–32729; `.StandardSpriteHandles` 32420–32611; `.CalcCenterPos`
   32612–32628; `.StandardSpriteCleanup` 32629–32704; `.TurnIntoStatue` 38244–38272; `.BurnFaceRow` 38514–38663;
   `.ParticleGlow` 38664–38764; `.HandleBurn` 38765–38840; `.BloodSpray` 37890–37961; `.HandleFlotation` 38075–38124;
   `.HandleUnderWater` 38125–38222; `.TintScreen` 31704–31727; `.PlayerConstraints` 43991–44126; `.FindUpperLeftCorner`
   5882–6239; `.GameLoop` 5093–5328; `.SetupLevelSprites` 1940–2103; `.SetupLevel` 2189–2590; `.IdleToActiveSprite`
   4215–4275; `.HandleIdleSprites` 4276–4360; `.UpdateItemStat` 4674–4841; `.PaintFrameWrap` 9104–9463;
   `.WrapDrawSprites` 10221–10397; OmniPx 13019–13547; `.CalcAmbientDarken` 13655–13689; `.GetFakeLight` 15290–15359;
   `.MTCollideSprites` 30216–30373; `.MTCollideSpecialSprite` 30374–30551; `.SetupBoxSprite` 58892–59730;
   `.HandleGeyserColumn` 59731–59920; `.HandleBoxSprite` 60030–61180; `.HitBoxSprite` 61328–61482;
   `.LoadCachedSpriteFaces` 73769–73869; `.HandleGeyserSegSprite` 53891–53899.
2. **Enemy census** (`docs/ferazel/gap-ledger/placements-all.tsv`, active records): L1 Walker 1700 ×2 (p1 1), 1705 ×4,
   1760 ×1; Crawler 1712 ×3; Roach 1720 ×5. L2 1700 ×6, 1705 ×6, Crawler ×11, Roach ×3, Bat 1740 ×1, Frog 1800 ×2. L3
   1700 ×2, 1705 ×6, Crawler ×2, Blob 1730 ×4, Bat 1740 ×11, 1741 ×1 (p1 2), Frog ×1. L4 1700 ×5, 1705 ×1, Crawler ×6,
   Roach ×5, Blob ×1, Bat 1740 ×6, 1760 ×5, Frog ×6. **L5 (16 types):** Bonus 1059 ×2, 1340, 3100 ×5, 3214; Box 1065 ×2,
   2820 ×2, 2821, 2822 ×2, 2826, 2829 ×2, 2840 ×3, 2841 ×2, 2940 (p1 −1); Platform 1403 ×4 (p1 52); Warrior 1820;
   Background 3249 ×2 (p1 −1, 1) — 32 records. First placements after 5: 1750 (L10), Gremlin 1770 (L15), Dillo
   1870 (L15), Floater 1780 (L62), Salamander 1810 (L50), Crab 1892 (L62), geysers 1440 (L10) / 1442 (L50, L51), pipes
   1490–1493 (L21), bats 1851/1860/1869 (L10+).
3. **Level 5's arena** (bosses §1.1–§1.4): `hdr+0x2724` −1444 → lock when x < 1384, window [map left, 1444]; gate 2940 p1
   −1 at x 416; exit 3249 p1 1 at x −93 (→ level 10); start at the right edge facing left (world-data §3.2 `0x26c8` = 1
   on level 5); music 23 → 30 after the kill; OmniPx mode 2 (faces 6201/6200, sheet 600 cells 6..14).
4. **Measured base:** the seat's G2 at 6a70bce: 502 = 501 passed + 1 skipped (`VisitSweepTests.testVisitEveryObject`);
   the seat's GW2 (`/tmp/loop36-gw2.log`): 79 tests = 78 passed + 1 skipped (`WinVisitSweepTests testVisitEveryObjectThroughWinGame`), 0 failed, 712.8 s; Proof B last measured 489/0/1/0 of 490 (run 35) — it would now
   fail on the visit-sweep skip (PB).
5. **The draw audit and refusals:** `docs/ferazel/gap-ledger/markers-render-classified.tsv` rows A01–A25 (§2.1 of the
   ledger); `SpriteBlitter.swift:43–50` the refusal list.

---

## Rulings (→ DECISIONS D44, copied by the orchestrator)

1. **Scope:** design §8 row 5 in full — every non-boss enemy class (placed on levels 1–5 or not: no later phase owns
   them), the whole EnemyShot class, the enemy pipes, the geysers, damage both ways, the burn-away, the Effect ids
   enemies spawn; plus the underwater tint and the Magical Shield crouch face (Phase 2/4 carries), Q15, gap #3. Out:
   bosses' Handles/Hits/Kills and projectile spawners, level features first used on levels ≥ 10, `.Victory`.
2. **"Through the first boss door" = levels 1–4 with every enemy alive, and level 5 open up to the Warrior's arena.**
   `BuiltLevels` → 1...5 at LV5; level 10+ refused with "Level n is not built yet (Phase 6)." Ben's read: Open question 1.
3. **The Warrior is a stand-in** whose Setup is transcribed (HP, boss flag → `noBossAlive = 0`, counted, `+0x18a`,
   faces) and whose Handle only stands; contact damage is `.HitPlayerSprite`'s as read; no Hit, no Kill (Phase 6). The
   arena lock, camera pan, gate p1 −1 and boss-music rule are built (Phase 6 reuses them on 18, 25, 55).
   **3a. The Warrior stays a Smite target** (Leg A fix round 1, seat ruling): `.SmiteEnemies`' list includes the
   Warrior Handle, so the stand-in can reach HP < 1 with no Kill; kept faithful to "no Kill until Phase 6" rather than
   dropping it from the list (which would change the Smite's 16-target count and its draws) or adding a stand-in Kill
   (invented behaviour). Harmless: a dead attacker hurts nobody; the arena stays locked and the gate shut; Esc leaves.
   Recorded under "Stand-ins kept" and on the gate card.
4. **OmniPx modes 2/4/5 built** (no RNG); 1/3/6/7/≥8 stay refused at level open (caught, not a quit).
5. **The counting window** gates `+0x1b5` and the live count for every Setup (Invariant 5), stubs included.
6. **Refusals stay refusals** (a quit is loud); every phase end runs the visit sweep, the random-play bot and the
   load-every-face tests on both shells, plus the draw-mode audit in G2 — **a phase cannot close while any fails**
   (Ben's Q15 (5)); any refusal made reachable by a task is drawn in that task (Invariant 8).
7. **The bot**: headless, opt-in (`FERAZEL_BOT=1`), seeded generator, both paths, default 4 seeds × 3 minutes per
   level in `BuiltLevels.range`, runner `tools/ferazel-random-play.sh`.
8. **Test bars with opt-in skips:** G2 = ladder total, 0 failed, skipped exactly the named opt-in tests (1 → 2 at
   RB); GW2 the same with the Windows names; Proof B = `(N − 1 − k) passed / 0 / (1 + k) skipped / 0 crashed (of N)`,
   k opt-in tests, the script accepting only the Wine list and the opt-in list. The Windows smoke references are
   pinned in-process (`WinReferenceFramesTests`) so a ◈ task can move them by night.
9. **Geysers (§9 (b)):** no Setup re-run on re-activation (the snapshot is restored; `+0x58` proc as read); kinds 3/4
   built, their out-of-cache face draws nothing; p4 inert; no sound.
10. **Gap #4 voice eviction: a recorded deviation, not a task** (KD1). **Gap #3: follow the binary** (RV). **The shrink
    rule: a QUESTIONS item** (needs a capture), not a task.
11. **Goblin voices** use the one shared voice pool: idle tests via `SoundVoices`, stops via stop cues, global over all
    goblins.
12. **Enemy drops 8/21 (§9 (c)):** copied as the Kill routines spawn them (EC's scan records which); no data change.
13. **No HectorKit change** (HK 35a85ba, floor 361, no HK D-number, no other app rebuilt).
14. **The lit-sprite darkness over-read (A13)** is built from the binary before enemies move (DK); A14 stays refused
    and pinned unreachable.
15. **Lockstep** (Phase W Ruling 16, verbatim in the preamble) holds for every task.

---

## Review ledger

**Fix round 1 (2026-10-30, loop run 36, planner Opus 5.5)** — both Opus legs returned ACCEPT_WITH_FIXES; every
finding was checked against the committed dump / data section / code at 6a70bce before it was applied. None rejected.
Ladder moved by +2 (RV +1 test, ES +1 test): Core 615 → **617**, Proof B at the end **614 / 0 / 3 / 0 (of 617)**, RB's
GWB **514 / 0 / 3 / 0 (of 517)**; WinKit unchanged (81). Ladder, task headers/gates, Execution order, self-audit and
A5's gate updated together.

**Leg A — against the dump + bank**

| # | finding | verified | done |
|---|---|---|---|
| A1 | Kill bookkeeping also needs `+0x1b5 ≠ 0` | ✅ M l. 56695 / 58624 / 73479 (and every enemy Kill) | S2 `kill` contract; `testKillBookkeeping` gains the uncounted kill (cites corrected to 56695–56700 / 58624–58629 / 73479–73485) |
| A2 | DK: refused at `:577`; the over-read lands in the ambient table | ✅ `SpriteBlitter.swift:571/:577`; TOC 0x100a0134 → data+0x5c52c, 0x100a0130 → data+0xca52c, 0x100a0120 → data+0xcb52c (`pef.py` has no CLI for this; the repeatable recipe is its Python API from the worktree root: `FZ_PEF=ghidra/ferazel/Ferazel_pef PYTHONDONTWRITEBYTECODE=1 python3 -c "import sys; sys.path.insert(0,'docs/ferazel/tools'); from pef import u32; print(hex(u32(0x100a0134)))"` → `0x5c52c`, the data-section offset (absolute = + `DBASE` 0x1009f840); re-run 2026-10-30, all three match) | DK rewritten: F = 110 + k reads ambient row k; past F = 125 kept a refusal (DA row); STOP clause removed; Files → `Frame/LevelTables.swift` (there is no `Color/*` table file) |
| A3 | Warrior Setup omits draws and writes | ✅ M l. 72989–73079 | LV5 Files list the Setup's writes in order — **corrected by the FABLE-GRADE leg (F1):** fix round 1 missed `+0x84`/`+0x86`/`+0x80 = 0xc`, `+0xc0 = 0` and the `+0xc`/`+0xa` re-seat; now listed; `testLevel5SetsUpEveryRecord` pins them + a synthetic p4 = 0 record |
| A4 | boss-music cites; level 5 plays 23 throughout | ✅ M l. 5218–5221 / 5266–5269 | LV5 Files + Contract; gate card item 11 rewritten |
| A5 | UT span; no new seam case | ✅ M l. 46449–46476; `.MT_FadeToColor` M l. 79455ff | UT maps to `.fadeToColor(15, rgb)` / `.fadeToColor(100, nil)`; S3 comment; 1 ms wait → Known deviation 5 (MED) |
| A6 | camera bounds before the lock and during the pan | ✅ M l. 5941–5948 / 5953–5954 (and 5961, 6011–6028, 6171–6172) | LV5 Contract; asserts inside `testArenaLocksAtX1384` (before the lock) and `testCameraWindowWhileLocked` (the pan) — ladder unchanged |
| A7 | shield block acts only on enemy shots; Wraith reflection needs a test | ✅ M l. 48380, 48384–48393 | ES Contract; new `testShieldReflectsWraithShot` (ES 10 → 11) |
| A8 | the R(100) coin draw happens regardless | ✅ M l. 49899–49904 | EC Contract; pinned in `testContactDamageWalker` |
| A9 | Smite uses stored `+0x10`/`+0xe` − 4; Warrior is a target | ✅ M l. 47038; TOC 0x100a0494 = `.HandleWarriorSprite` | EC Files + test; seat recommendation taken as Ruling 3a (faithful, no Kill), Stand-ins row, gate card note |
| A10 | IdleToActive clears `+0xe9` and kills on `+0x4c`/type 0; geyser has no `+0x58`; buffer survives | ✅ M l. 4264, 4266–4270; only `.SetupRopeSprite` M l. 71122 stores a sprite `+0x58` proc; `.MTKillSprite` M l. 30739ff unlinks only | Hazards line, GY Contract, BC53 settled |
| A11 | `.STPlay3DSoundRandGob` missing | ✅ M l. 56786–56801; called at 58490 / 58494 | S2 `EnemyCommon` gains `playRandGob` |
| A12 | OmniPx counter per face; 16-bit wrap; TurnOnOmniPx zeroes header factors | ✅ semantics; **line numbers corrected**: the face-loop increment is M l. 13471 (loop 13469–13514), the wraps 13476–13487 (13486 is one of the wraps) | OX Contract + tests; Core's header copy zeroed (zeroing applies to modes other than 4…7) |
| A13 | Bat Init caches five sets | ✅ M l. 68092–68107 | BA Files + Carries wording |
| A14 | OmniPx setup at 2540; `fe78` not read in `.WrapDrawSprites` | ✅ M l. 2539/2540; 10255–10256 read only `fe74`/`fe70` | OX Files; SP Contract |

**Leg B — against what landed + rulings**

| # | finding | verified | done |
|---|---|---|---|
| B1 | existing tests pinning inert enemies / a non-firing spout | ✅ every line ref | listed with an in-advance seat ruling (retarget, re-derive from the dump, list each change): ES `ButtonGateTests:384–393`; WK1 `BonusSpriteTests:424`, `BackgroundMoverTests:742/779`, `LevelFourTests:70`; BL `LevelThreeTests:103`; BA `LevelFlowTests:119`; EC `ItemUseTests:533–559`; LV5 `LevelFourTests:153–177`. **Also found:** `GameFlowGameTests:691–699` (an original save at level 5 now Continues) → LV5. Tests that build their own `.inert` sprite are unaffected |
| B2 | SP's new closure is passed by nobody | ✅ `FerazelDriver.swift:437`, `LevelRun.swift:597`, `VisitSweepTests:267`, `LevelSweepTests:25/63`, `DiffuseSquashTests:211`; `diffuseSeeds` at `FerazelSession.swift:437` and `:1008` | SP Files + Contract: both sites change (`:1008` is the drift's); wiring is contract; WinKit assert in `FerazelDriverTests.testPrepareAndAttachThroughTheDriver` proves the apps' path; `TeleportLevelRunTests` moved to FerazelRenderTests (planner error: FerazelCoreTests cannot run a `FrameRenderer`) |
| B3 | `.omniPx` breaks exhaustive switches | ✅ `ScreenRenderer.swift:61–125`, `SessionTests.swift:291` | OX Files (+ DA row for the new refusal); op emitted only while OmniPx is on; reuses `GameGlobals.omniPxActive` / `ParallaxBlitter.omniPxActive`; G5 named |
| B4 | D38 seat ruling (1) write-back flags | ✅ (`SpriteSlot.swift:220–227`) | "Every class task also" line + Carries row |
| B5 | GE grep matches nothing | ✅ `tools/ferazel-visit-sweep.sh:75` prints `== core: …` | grep `^== (core\|windows):`; RB's runner prints the same fixed shape |
| B6 | sheets now in `BootFaces` | ✅ `BootFaces.swift` contents; `FrameRenderer.swift:201–209` only consumes | Faces note, ES, WK1 point at `BootFaces` / `CachedFaces` |
| B7 | LV5's "1…4" comments are in Shared + WinKit test | ✅ `FerazelDriver.swift:12/:40`, `FerazelSettingsTests.swift:17`; nothing in `FerazelController.swift` | LV5 Files |
| B8 | Proof B passes the environment into Wine | ✅ `proof-b-ferazel.sh:22` unsets only three variables | PB Files + Contract |
| B9 | DA's refusal table must cover every renderer throw | ✅ throws across FerazelRender | DA Contract (2) |
| B10 | GW4 missing | ✅ the WinKit test target does not depend on `FerazelWin` | GW4 added to the gate table, commands, legend and the Ruling 16 line |
| B11 | RV's comparison: test or assert | — | a separate test `testHotRectsAndEmittersUnchangedByBootFaces` (RV 2 → 3) |
| B12 | UT: name the Windows references | ✅ | UT Files (expected "not moved") |
| B13 | EC's contact damage dormant until mapped | ✅ | EC Contract: rows key on the new handler cases |

**FABLE-GRADE leg (run 36)** — fix round 2 (2026-10-30, loop run 36, planner Opus 5.5). Every finding re-read in the
committed dump `ghidra/ferazel/` before it was written. Eight applied, one applied with a correction (F3). **No count
change:** every new pin is an assert inside an existing test — Core ladder 617, Proof B **614 / 0 / 3 / 0 (of 617)**,
WinKit 81 unchanged. No new question for Ben.

| # | finding | verified | done |
|---|---|---|---|
| F1 | IMPORTANT — LV5's Warrior Setup omits `+0x80 = 0xc`, `+0x84`, `+0x86` and the `+0xc`/`+0xa` re-seat; A3 claimed "every write" | ✅ M l. 73015–73019, 73046–73047; layer before insert: `.MTNewSprite` M l. 30711 (caller's layer) → 30716 (Setup) → 30719 (`.MTInsertSprite`). Also found: `+0xc0 = 0` before the HP arm | LV5 Files list them in order (with `+0xc0 = 0`; `+0x15c/+0x160/+0x168` from the re-seated `+0xc`; `+0x14/+0x1c` from `+8/+6`); asserts in `testLevel5SetsUpEveryRecord`; A3 wording corrected |
| F2 | IMPORTANT — BC52 "coins 0x516 only" is wrong; the scan misses wrapped calls | ✅ `.PopupGoblinCoins` (only caller `.HandleWalkerSprite`) spawns 0x50d M l. 57435, 0x50c 57452 / 57470, 0x516 57485 with the R(1000)/R(2000)/R(3) draws; wrapped `_MTNewSprite` + newline at 56468 (Crawler Handle), 65085 (Roach), 68798 (Bat), 69324 (Gremlin); 0x50c/0x50d/0x516 are `.InitBonusSprite` boot faces (`BootFaces.swift:55–56`) — no draw gap | EC Contract + BC52 expect 0x50d/0x50c/0x516; scan the bare token |
| F3 | MINOR — `.KillWarrior` sets "track 0x1e" itself | ⚠ partly: M l. 73486–73493 writes `_DAT_1009ffa0 = 0x1e`, which is the **screen shake** counter (engine §5; bosses.md Kill step 2; `Camera.swift` `shake`), not the music track (`_DAT_100a5be0`, M l. 5267); it also sets flash `_DAT_100a00fc = 3`, snd 453 and `fed0 = 1` | LV5's Phase 6 note names all four Kill writes and keeps track 30 on the loop rule (rejected only the "track" reading) |
| F4 | MINOR — the stand-in omits the real Handle's three children | ✅ M l. 73145–73182: when p4 ≠ 0, type 0x433 (falling crates, bosses.md) into `+0x1d4/+0x1d8/+0x1dc` once `+0x16c` counts below 1 | gate card item 11 + Stand-ins row |
| F5 | MINOR — gate card "bat 600" | ✅ M l. 68795 `+ 500` | card item 6 → bat 500 |
| F6 | MINOR — wave 5.1's end names no G3/GWB | ✅ | ES Gate line + Execution order run 4 "(wave 5.1 end)" |
| F7 | MINOR — three carries are outside the `later: Phase 5` grep | ✅ `Player.swift:360`, `PlayerLiquids.swift:139` (`later: no Phase-2 seam…`), `Physics/StandardSprite.swift:94` (`later: burn-away`) and `:124` (`later: .HandleBurn`) | UT and EC Files: remove the labels; Carries rows say so |
| F8 | MINOR — A2's `pef.py` check has no CLI | ✅ `pef.py`'s `__main__` prints only the section table; default path `../../../ghidra/Ferazel_pef` is stale (the PEF is `ghidra/ferazel/Ferazel_pef`) | A2 records the Python-API recipe with `FZ_PEF`; re-run, all three offsets match |
| F9 | MINOR — `.IdleToActiveSprite` also writes `+0xa8` | ✅ M l. 4265 (`+0xa8 = param_1`, the idle index) | Hazards line, GY Contract, assert in `testIdleReactivationKeepsBlock` |
