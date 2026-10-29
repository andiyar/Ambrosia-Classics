# Plan — Ferazel's Wand Phase 5 "Enemies": every enemy class, enemy shots, damage both ways, particles in full, the underwater tint, level 5 up to the Warrior's arena; Ben's Q15 safety checks first — 2026-10-30

> Status: **DRAFT — planner Opus 5.5, loop run 36 (2026-10-30), unattended; review legs owed** (two Opus legs, then
> the FABLE-GRADE plan leg, D34 as amended 2026-10-13 — "Review ledger" is empty for them). Implements
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

How it lands here: **every task** runs G2 + GW1 + GW2 + GW3 + GW-symlinks + G-MUTE + G5 (Core-only ones too, (b)); a
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
change only through the test harnesses (PB, RB). **HectorKit: untouched** (Ruling 13).

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
| GW-symlinks / G-MUTE / G7W | Phase W's | empty / `1` then `1` / empty |
| GWB | Proof B (launch gate, by day, muted) | `proof-b: P passed / 0 failed / S skipped / 0 crashed (of N)`, N = the Core ladder at that commit, S = 1 (Wine) + the opt-in count, P = N − S (Ruling 8; PB teaches the script the opt-in list) |
| GW4R / GW5 / GW6 / G9M | Phase W's | as Phase W (GW6: the three "identical" lines; references from PB's in-process pins) |
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
grep -E "^VISIT SWEEP|^RANDOM PLAY" "$SCRATCH"/visit-sweep.txt "$SCRATCH"/random-play.txt                     # summary lines → gate card
```

**Ladders** (canonical order = execution order; STOP if different; merged in another order: previous + the task's N):

| after | `Ferazel/Core` (G2 total / skipped) | FerazelWinKit (GW2 total / skipped) | run |
|---|---|---|---|
| base (6a70bce) | **502** / 1 | **79** / 1 | — |
| PB | 502 / 1 | 80 / 1 | 1 |
| SP | 505 / 1 | 80 / 1 | 1 |
| RV | 507 / 1 | 80 / 1 | 1 |
| DK | 509 / 1 | 80 / 1 | 2 |
| UT ◈ | 512 / 1 | 80 / 1 | 2 |
| DA | 514 / 1 | 80 / 1 | 2 |
| RB ⚑ | 516 / **2** | 81 / **2** | 3 |
| EC ⚑ | 524 / 2 | 81 / 2 | 3 |
| ES ⚑ | 534 / 2 | 81 / 2 | 4 |
| WK1 ⚑◈ | 543 / 2 | 81 / 2 | 4 |
| CR ⚑◈ | 551 / 2 | 81 / 2 | 5 |
| WK2 ⚑◈ | 557 / 2 | 81 / 2 | 5 |
| BA ⚑◈ | 566 / 2 | 81 / 2 | 6 |
| FR ⚑◈ | 574 / 2 | 81 / 2 | 6 |
| BL ⚑ | 581 / 2 | 81 / 2 | 7 |
| GF ⚑ | 588 / 2 | 81 / 2 | 7 |
| DL | 593 / 2 | 81 / 2 | 8 |
| GY ⚑ | 600 / 2 | 81 / 2 | 8 |
| PI | 604 / 2 | 81 / 2 | 8 |
| OX ⚑ | 609 / 2 | 81 / 2 | 9 |
| LV5 ⚑ | 615 / 2 | 81 / 2 | 9 |
| A5 | 615 / 2 | 81 / 2 | 10 |

Proof B at the phase end: **612 passed / 0 failed / 3 skipped / 0 crashed (of 615)**. Review fix rounds add asserts,
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
  0x220-byte snapshot and calls the sprite's `+0x58` proc if one is set (verified 2026-10-30).
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
  `kill(_ s: inout SpriteSlot, globals: inout GameGlobals, level: Int)` (the Kill idiom: once, `+0xe9 == 0` →
  live − 1, `G+0x306+2·L` + 1, `+0xe9 = 1`; `+0xea` only where the class's Kill sets it). `LevelRun`/`.SetupLevel`
  opens the window around the level's sprite setup and copies `live` into `G+0x6ee+2·L` as today's totals do.
- ★ `EnemyCommon` (EC): `.HurtSprite` reuse (exists), `hurtGoblin` (`.HurtGoblin`, M l. 58472–58505),
  `goblinRandomCry` / `goblinHurtCry` (M l. 56848–56897 / 56802–56847), `playPitchedGob` (M l. 56773–56785), the
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
  each), the counter `c` (BSS, **never reset between levels** → rides `LevelCarry`), `G+0x174` on-flag;
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
//     ScreenGammaOp cases; if the dump's `MT_FadeToColor(0, rgb, 15, 1, 1)` needs a new case, UT ADDS one and says so)
```

### S4. FerazelRender additions
`FrameRenderer` executes `.omniPx` (OX: the port as PxBack slot 0 for the backdrop compositor, the factors zeroed for
modes 1–3 and ≥ 8 as `.TurnOnOmniPx` does); `SpriteBlitter` honours the burn's top clip (exists as `SpriteClip.top`)
and the darkness over-read (DK); `diffuseRandoms` walks at the same (h, v, drawn) as the draw (SP). Test harnesses:
`DrawModeAuditTests` (DA), `RandomPlayTests` (RB).

### S5. Shells
Mac App: no change except what G5 shows. Windows: `FerazelWinKitTests` gains `WinReferenceFramesTests` (PB) and
`WinRandomPlayTests` (RB); `tools/windows/proof-b-ferazel.sh` and `smoke-ferazel-win.sh` (PB). New
`tools/ferazel-random-play.sh` (RB).

---

## Tasks

Legend as Phase 4: ⚑ MAJOR = **two Opus review legs** (spec/fidelity against the dump, then quality/mutation); minor =
one Opus leg; ◈ = may move a golden (Verification model). "→ N" = Core ladder total after the task. Every task: G1, G2,
G5, G6, G7(+b), G8, G10, GW1, GW2, GW3, GW-symlinks, G-MUTE, G7W; G3 + GWB (by day) at each wave end. **All implementers
and reviewers are Opus 5.5 (D34).** Each task's precondition: read the named bank sections, then **re-read the named
dump spans** before writing code — *re-read each cited M line in the committed dump before coding; the dump wins; record
any disagreement in the task's As-executed note.*
**Faces of run-time-spawned sprites (Phase 4 B5):** every task that spawns a type at run time (shots, shards, coins,
corpses, children, Effect ids) adds its sheet to the renderer's tables and to the level-load picture cache
(`LevelRun.swift` `CachedFaces` sets/marks, M l. 73769–73869 `.LoadCachedSpriteFaces` + each class's `.Init*Sprite`) as
the original marks them, and names the additions; `FaceTests.testEverySpawnableTypeHasSheet` and `BootFacesTests` are
extended by the task (no new test needed for that; asserts inside them).
**Files lists name every flow / renderer / test seam the task touches;** a file found missing is added and recorded in
"As executed" (G6 reads the amended list).
**Every class task also:** wires its class's Statue arm (the Hit routine's branch to `.TurnIntoStatue`; the eleven enemy
statue sites of run 28 — Walker, Crawler, Roach, Dillo, Bat, swarm member, Gremlin, Floater, Frog, Salamander, Blob —
each in its class task), its Smiting reaction (its Hit routine on the Smite explosion 0x4b7, `Smite.swift`), its
liquids and environmental hazards (EC's helpers), its Kill bookkeeping (EC), its idle margins, and its picture-cache
marks; runs `tools/ferazel-random-play.sh core` on the levels it brings to life (RB's quick mode, one level, 60 s) and
records the summary line.

### Wave 5.0 — Ben's Q15 first (default (a), item 5 Ben's "yes"), and the two Phase 2/4 gaps that are not enemies

#### PB — minor — Proof B's opt-in skips; the Windows reference frames pinned in-process (→ 502; WinKit 80)
- **Why first:** Ben's visit sweep (8fd0ed6) added a test that skips unless opted in; `proof-b-ferazel.sh` accepts only
  the Wine skip list (`:117–127`), so **Proof B fails today** on a correct suite. And the Windows smoke's reference
  FNVs live only in the script, measurable only by a launch — so a ◈ task by night could not move them honestly.
- **Files:** `tools/windows/proof-b-ferazel.sh` (a second list `optin_skips=(FerazelRenderTests.VisitSweepTests/testVisitEveryObject)`
  — skipped everywhere unless opted in; accepted like `wine_skips`; the pass line requires `skipped == ${#wine_skips} +
  ${#optin_skips}`), `tools/windows/smoke-ferazel-win.sh` (comment: the references are pinned by
  `WinReferenceFramesTests`; values unchanged), `Ferazel/Windows/Tests/FerazelWinKitTests/WinReferenceFramesTests.swift`
  (new), `tools/windows/README.md` (the bar sentence).
- **Contract:** (1) Proof B's verdict: `P passed / 0 failed / S skipped / 0 crashed (of N)`, S = 1 + opt-in count, P =
  N − S; any other skip fails. (2) `WinReferenceFramesTests.testSmokeReferencesInProcess`: a headless `WinGame` in
  `--frames` mode in-process (the `WinSweepGame` / `WinGameTests` rig — scripted host, baked fonts, pinned seed and
  clock, Ruling 20 of Phase W), the three runs of the smoke (menu 1,437 wakes; New Game 1,865 wakes with the smoke's
  key file; the text run 3,833 wakes) → RGBA FNVs equal the script's `menu_fnv`, `newgame_fnv`, `text_fnv`. If the
  in-process rig cannot reach the same frame as the exe's `--frames` path, STOP and report (do not loosen).
- **Tests (WinKit 1):** `testSmokeReferencesInProcess`.
- **Gate:** G2 502 / 1 skip, GW2 80 / 1 skip, GWB by day (expected **500 / 0 / 2 / 0 (of 502)**), the rest per
  legend. **Commit:** `Proof B accepts the opt-in visit sweep skip; the Windows smoke references pinned in-process`.

#### SP — minor — the sparkle: one scroll for Core's walk and the renderer; the bank's row guard; a teleporter through LevelRun (→ 505)
- **Q15 items 1, 3, 4; gap ledger #2 (A22).** Today `FerazelSession.diffuseSeeds` walks mode-5 draws at the **camera**
  scroll (`FerazelSession.swift:1006–1026`, `camera.scrollH/V`, no drawn pair) while `FrameRenderer` draws them at its
  own scroll with the grid's drawn location (`FrameRenderer.swift:~371`, `wrapDrawSprites(…, h: scroll.h, v: scroll.v,
  drawn: (grid.drawnH, grid.drawnV))`). On passage-jump and teleport-mosaic frames the two differ, so the pixels walked
  — and so the `FastRand` count — differ.
- **Files:** `Sources/FerazelCore/Session/FerazelSession.swift` (the walk's arguments; Core mirrors the drawn pair it
  already emits through `.redrawScrollGrid` / `.redrawEntireScrollGrid` / `.setDrawnScroll`),
  `Sources/FerazelCore/Front/LevelServices.swift` (`DiffuseRandomsAt`, S3), `Sources/FerazelRender/Frame/FrameRenderer.swift`
  (the `diffuseRandoms` closure passes the drawn pair), `Sources/FerazelRender/Frame/SpriteBlitter.swift`
  (`diffuseRandoms(_:h:v:drawn:rng:)`), `docs/ferazel/draw-effects.md` (§2.6 — the colour-pass row guard the code
  follows, as a ⚑ planner note BC51), `Tests/FerazelRenderTests/DiffuseSquashTests.swift`,
  `Tests/FerazelCoreTests/TeleportLevelRunTests.swift` (new).
- **Contract:** re-read `.WrapDrawSprites` (M l. 10221–10397, raw `100144c8..`) for which globals the blit and its
  clip read (`PTR_DAT_1009fe78` the scroll point; `_DAT_1009fe74` / `_DAT_1009fe70` the grid's drawn location) and
  `.BlitEncFaceDiffuse @ 10029988` (draw-effects §2.3); Core's walk takes **exactly** the (h, v, drawn) the renderer
  uses for that `.wrapDrawSprites` op, in list order, from the same seed. The renderer's replay and Core's walk then
  consume the same number of `FastRand`s by construction; the drift is gone. BC51 records the row guard of §2.6.
- **Tests (3):** `testDiffuseWalkUsesDrawnScroll` (a mode-5 draw on a frame where camera ≠ drawn: Core's seed after
  the walk equals a fresh `FastRand` advanced by the renderer's replay count at the drawn pair; at the camera pair the
  counts differ — pins the cause) · `testTeleportThroughLevelRun` (level 1, a `LevelRun` with Ferazel standing on the
  urn rec 148: the charge to 80, stage 1 mosaic, the move to rec 149, stage 2, the frames after arrival with the
  mode-5 sparkle — every op executes in a level-1 `FrameRenderer` without a refusal; the after-arrival sparkle draws
  at `HitPlayerSprite.swift:~456`'s site) · `testPassageJumpSparkleSeed` (a passage jump frame with a sparkle: the
  stream after the frame equals the renderer-consistent count).
- **Gate:** G2 505. **Commit:** `Ferazel: the sparkle's random walk at the renderer's own scroll; draw-effects row guard; teleporter through LevelRun; 3 tests`.

#### RV — minor — reviewer open items (Q15 item 6) and the empty-inventory box (gap ledger #3) (→ 507)
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
  check (Open question 4). The other Q15 item ("newly loaded faces may change box hot-rects / particle emitters") is a
  test: every hot rect / emitter source for levels 1–4 equals the value before b535527 or the change is listed.
- **Tests (2):** `BootFacesTests.testComputedFacePictsAreLoaded` · `StatusBarTests.testEmptyInventoryReadsTheGap`
  (selection −1 with G+0x1a = 2, G+0x1c = 3 → icon cell 2 and "x3"; all zero → cell 0, no count).
- **Gate:** G2 507. **Commit:** `Ferazel: computed face ids in the boot-face scan, the empty-inventory box as the binary reads it, LightFaces comment; 2 tests`.

#### DK — minor — the lit sprite at full darkness under the brightest light (ledger A13) (→ 509)
- **Why now:** A13 is a latent quit (`SpriteBlitter.swift:571` `Refusal.darkness`): a `+0x89` dynamic-lit sprite on a
  light-15 cell under a colour-99 light. Phase 5 makes things move on level 4 (the only level with light-15 cells) —
  thrown boulders 0x6e1/0x6e2 and spout boulders, corpses, bats — so it can become reachable; build it before.
- **Files:** `Sources/FerazelRender/Frame/SpriteBlitter.swift` (`:571`), `Sources/FerazelRender/Color/*` (the table
  layout the over-read lands in), `Tests/FerazelRenderTests/LightingTests.swift`.
- **Contract:** lighting-tables §7 + draw-effects §2 (mode 0xc). Re-read `.CalcAmbientDarken` (M l. 13655–13689),
  `.GetFakeLight` (M l. 15290–15359) and the mode-0xc blitter for the index arithmetic; the original indexes past the
  ambient table into the bytes that follow it in memory (ledger A13: "reads the ambient table that follows") — find
  in the dump which allocation follows (the tables' build order) and read those bytes, as the binary does. If the
  following bytes cannot be determined from the dump, STOP: the seat rules (do not invent a clamp).
- **Tests (2):** `testDynamicLightAtFullDarknessReadsFollowingTable` · `testA14LightByteMinusOneStillRefused` (pins A14
  as still refused — DA proves it unreachable).
- **Gate:** G2 509. **Commit:** `Ferazel: mode 0xc at full darkness reads past the ambient table as the original; 2 tests`.

#### UT — minor ◈ — the underwater screen tint (Phase 2 carry, D38 A4 ruling) (→ 512)
- **Files:** `Sources/FerazelCore/Player/PlayerLiquids.swift` (`:137–139` stub), `Sources/FerazelCore/Player/Player.swift`
  (`:360` comment), `Sources/FerazelCore/Player/PlayerState.swift` (the flag `PTR_DAT_100a066c`),
  `Sources/FerazelCore/Front/ScreenFade.swift` (the `fadingEnabled` gate `DAT_100a53c2`), `Sources/FerazelCore/Seams/ScreenGammaOp.swift`
  (only if a case must be added — S3), `Sources/FerazelRender/Effects/ScreenGamma.swift`,
  `Tests/FerazelCoreTests/LiquidHazardTests.swift`, `Tests/FerazelRenderTests/Phase2GoldenTests.swift` (◈ values).
- **Contract:** row 41 of `.HandlePlayerSprite` (M l. 46452–46474, re-read 2026-10-30): `+0x11c` in 1…9 and the flag
  clear → rgb by `+0x128` (1 → green 64000; < 1 and ≥ 0 → blue 64000; 2 → red 64000; else black), `.TintScreen(&rgb,
  0xf)`, flag 1; `+0x11c` > 10 or 0 with the flag set → flag 0, `.TintScreen(0, 0)`. `.TintScreen` (M l.
  31704–31727): only while `DAT_100a53c2` (fading enabled); nil → `MT_FadeToColor(0, 0, 100, 1, 1)`, else
  `MT_FadeToColor(0, &rgb<<16, n, 1, 1)` — map onto the existing `ScreenGammaOp` cases if the library semantics agree
  (lighting-tables §10), else add one case (S3). The gamma is applied by FerazelRender's screen surface, which both
  shells present — no shell change (Ruling 16 (b) only).
- **◈ goldens:** swim `c1dd428a3f146d77` (and any golden whose route enters water — list them) — the op enters the
  stream. Switch-off: the row-41 tint branch commented out → old values return.
- **Tests (3):** `testUnderwaterTintBlue` (kind 0, `+0x11c` 3 → one tint op toward (0, 0, 64000), 15; flag 1; a second
  frame emits nothing) · `testTintClearsOnSurfacing` (`+0x11c` 0 with the flag → `.TintScreen(0,0)`, flag 0) ·
  `testTintGatedByFading` (fading disabled → no op, flag still set as the dump does — check the order).
- **Gate:** G2 512 + ◈ record. **Commit:** `Ferazel: the underwater screen tint (.TintScreen, row 41); swim golden moved as recorded; 3 tests`.

#### DA — minor — the standing draw-mode audit (Q15 item 2) (→ 514)
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
  (2) **`testEveryRefusalIsUnreachable`** — a table of every `SpriteBlitter.Refusal` / `FrameRenderer` refusal with,
  for each, the reason it cannot be reached in the built levels (no writer; data absent per `placements-all.tsv`; a
  header value 0) checked by code (writer list, header scan) — a new refusal or a new writer without a row fails.
  **Ruling 6:** refusals stay refusals (a quit is loud), guarded by DA + the visit sweep + the bot at every phase end.
- **Tests (2):** the two above.
- **Gate:** G2 514. **Commit:** `Ferazel: the draw-mode audit — every written mode drawable, every refusal unreachable, levels in scope; 2 tests`.

#### RB — ⚑ MAJOR — the random-play bot, both shells (Q15 item 5, Ben's "yes") (→ 516; WinKit 81)
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
  T, deaths D, exits E, conversations C, saves V` and a failure table. Opt-in: `FERAZEL_BOT=1` (skipped otherwise —
  Ruling 8). `RandomPlayPlan` also has an always-run unit test of the generator (deterministic sequence for a seed).
  Quick mode for class tasks: `FERAZEL_BOT_LEVELS=n FERAZEL_BOT_MINUTES=1 tools/ferazel-random-play.sh core`.
- **Tests (Core 2, WinKit 1):** `RandomPlayPlanTests.testGeneratorIsDeterministic` (runs) ·
  `RandomPlayTests.testRandomPlay` (opt-in) · `WinRandomPlayTests.testRandomPlayThroughWinGame` (opt-in).
- **Acceptance:** at RB's merge, `tools/ferazel-random-play.sh both` exits 0 on levels 1–4 (its summary in "As
  executed" with the wall time); a deliberately injected refusal (a test-only patch, not committed) is caught on both
  paths.
- **Gate:** G2 516 / 2 skips, GW2 81 / 2 skips, GWB by day **513 / 0 / 3 / 0 (of 516)**. **Commit:**
  `Ferazel: the random-play bot — Core and Windows paths, runner script, Proof B opt-in list; 3 tests`.

### Wave 5.1 — the enemy foundation

#### EC — ⚑ MAJOR — enemy common: handlers, counting, kills, statues, hazards, the burn-away, goblin voices, contact damage (→ 524)
- **Files:** `Sources/FerazelCore/World/Enemies/EnemyCommon.swift` (new), `Sources/FerazelCore/Particles/Burn.swift`
  (new), `Sources/FerazelCore/Sprites/SpriteSlot.swift` (S2 cases, `+0x1b2`), `Sources/FerazelCore/Physics/StandardSprite.swift`
  (`:94`, `:124` — the burn call), `Sources/FerazelCore/Sprites/SetupFaces.swift` (`:538–:649` the enemy stubs: counted
  only inside the window — run 29 carry [MED], `SetupFaces.swift:575–580`'s tally), `Sources/FerazelCore/Front/LevelRun.swift`
  (the window around the sprite setup), `Sources/FerazelCore/Session/{FerazelSession,SpriteWorld}.swift` (dispatch for the
  new cases, each a named no-op until its task; the `+0x1b2` early return), `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (step 6's enemy rows and step 7's generic path for the enemy classes — contact damage by class, coins, blood, the
  0x6d6 invul 0x24; `:10`, `:994`, `:1032`), `Sources/FerazelCore/Items/Smite.swift` (`:23`, `:26` — the 15 enemy Handles
  by `SpriteHandler`, the centre by `.CalcCenterPos` M l. 32612–32628), `Sources/FerazelCore/Player/GroundCeilingEffects.swift`
  (`:68–:69` relabel), `Sources/FerazelRender/Frame/SpriteBlitter.swift` (the top clip for the burn, if not already
  honoured), `Tests/FerazelCoreTests/Enemies/EnemyCommonTests.swift` (new), `docs/ferazel/held-item-melee.md` (BC52).
- **Contract:** enemies-ground §2 (all), enemies-flyers §1, enemies-water-cave §0.1/§6, enemy-shots-and-damage §3.2,
  §3.4, §3.5 (non-shot rows), §3.7, enemies-ground-2 §3–§4, particles §5.5, draw-effects §4. Dump: `.HitPlayerSprite`
  (M l. 48445–49929; the hazard arm raw `10058458..10058494`, the generic path raw `10057968..10057bcc`), `.HurtPlayer`
  (M l. 47955–48112), `.HurtSprite` (M l. 32705–32729), `.HurtGoblin` (M l. 58472–58505), the goblin voice helpers (M l.
  56773–56897), `.TurnIntoStatue` / `.HandleStatueSprite` (M l. 38244–38272 / 56521–56555), `.HandleBurn` /
  `.BurnFaceRow` (M l. 38765–38840 / 38514–38663), `.StandardSpriteCleanup` (M l. 32629–32704), `.SmiteEnemies` (M l.
  46981–47046), `.SetupLevel` (M l. 2189–2590; the window raw `10004da4..10004dc0`). **INDEX item 29 remainder (§9 (c)):**
  scan every enemy Setup/Handle/Hit/Kill span (Research note 1) for `MTNewSprite`/`.GenerateSprite` with the Bonus Setup
  and list the types spawned; record in `held-item-melee.md` NR 4 as BC52 (expected: coins 0x516 only; items 8/21 never
  — if any class drops an item, its class task builds it as read).
- **Tests (8):** `testCountingWindow` (a Setup inside the window → `+0x1b5` 1 and live + 1; outside → neither; the
  level-1 total unchanged from today's 0x… value — record it) · `testKillBookkeeping` (once; stat `G+0x306+2L`; `+0xea` per
  class flag) · `testContactDamageWalker` (step 7: 0x70, invul 60, coins 3 iff R(100) > 80, blood) · `testContactDamage0x6d6Invul`
  (0x24) · `testDeadEnemyHarmless` (HP < 1 → `.HurtPlayer` returns 0) · `testBurnAwayClipsAndKills` (`+0x1a2 = 1`: the
  top clip advances `+0x8d + 1` rows/frame; particles per row; the Kill proc at the opaque bottom) ·
  `testGoblinCriesGlobal` (465 playing on another goblin → no random cry and no draw beyond R(500); hurt cry stops every
  465/466/468) · `testSmiteMatchesEnemyHandles` (16-target cap, centre − (4,4) by `.CalcCenterPos`).
- **Gate:** G2 524. No golden moves (no Handle body runs yet). **Commit:** `FerazelCore: enemy common — handlers, the counting window, kills, contact damage, statues, hazards, the burn-away, goblin voices; 8 tests`.

#### ES — ⚑ MAJOR — the EnemyShot class, the shield block, the Magical Shield crouch, boulder spouts firing (→ 534)
- **Files:** `Sources/FerazelCore/World/Enemies/EnemyShot.swift` (new), `Sources/FerazelCore/Player/HitPlayerSprite.swift`
  (step 7's EnemyShot rows: damage by type, `_DAT_100a0570 = 0`, the 0x77b spin reversal, every other shot killed;
  `.ShieldBlock`), `Sources/FerazelCore/Player/PlayerStates.swift` (`:556` the Magical Shield crouch face with
  `.HasItem(0xf)`), `Sources/FerazelCore/Shots/PlayerShotHits.swift` (`:151`, `:189`, `:191` — the enemy-shot arms of
  `.HitPlayerShotSprite`), `Sources/FerazelCore/Player/Pentashield.swift` (`:7` — orbs kill enemy shots),
  `Sources/FerazelCore/World/Movers/BoxSprite.swift` (`:12`, `:776`, `:785` — the spouts 0x5aa…0x5ad spawn 0x6e1 + p4
  with their Setup's draws, re-arm 50 + R(30)), `Sources/FerazelCore/World/Movers/ButtonSprite.swift` (`:101` — an enemy
  shot presses), `Sources/FerazelCore/World/Movers/BackgroundSprite.swift` (`:402–:437` — cannon capture of an enemy
  shot; the dart traps 0x76c…0x76f if placed on 1–5, else built as read and unreachable), `Sources/FerazelCore/Session/FerazelSession.swift`
  (dispatch), `Sources/FerazelRender/Frame/FrameRenderer.swift` (sheets: 0x6a7, 0x6e1, 0x6e2, 0x6e6, 0x45d, 0x454/0x455,
  0x456/0x457, 0x71f, 0x753, 0x754, 0x771…0x774, 0x77b, 0x46a), `Tests/FerazelCoreTests/Enemies/EnemyShotTests.swift` (new).
- **Contract:** enemy-shots-and-damage §1 (all), §3.5–§3.6, enemy-shots-and-damage-2 §4.1–§4.3, §4.6. Dump: M l.
  51393–52260 (Init, Setup, Handle, Hit, Kill, HitTile), `.ShieldBlock` M l. 48359–48444, `.FindDesiredDirectionGeneric`
  M l. 37684–37833 (homing), `.KillPlayerShot` (exists) for the player-shot arms. **Every type of §1.2** is built (the
  boss types' Setup/Handle arms are in this class's routines — built as read, reachable only from Phase 6 spawners).
  The spouts (run 27 carry, BC44): the shot's Setup draws (`FastRand(5)`) and the bounce-budget draws now enter level
  4's stream — no golden is on level 4 (not ◈). The Magical Shield crouch face (D38 A4 ruling): the face row the dump
  selects while crouching with the shield raised and `.HasItem(0xf)`.
- **Tests (10):** `testWalkerAxeShot` (type 0/1 flight, gravity 0xaf, frame ±1, dies on first wall) · `testBoulderBounceBudget`
  (start −6…−1 with the 13 % adjust; split into 3…5 × 0x6e6 with vx/vy per §1.6) · `testBombBoulderExplodes` (0x6e2:
  snd 435, 0x4b7 at (x−32, y−32)) · `testShardHurtsOnlyYoung` (0x6e6 `+0x164 ≤ 1`) · `testFrogSpitTintDead` (the `+0xa4`
  multipliers never reach damage) · `testWraithHoming` (20 frames of 0x8c impulses then coast) · `testShieldBlockReflectsDart`
  (side test, counter > 2 → 7, ×−0.38, vy −1500, gravity 0x100; Magical Shield → `+0x1a2 = 1` burns it) ·
  `testShieldBlockKillsOthers` · `testSpoutFiresWhenLinkedButtonPressed` (level 4 rec 28: p1/p2 record p4 == 1 → spawn
  0x6e1 + p4 at own x,y with the arm's velocities; re-arm R(30) + 50) · `testMagicalShieldCrouchFace`.
- **Gate:** G2 534. **Commit:** `FerazelCore: the EnemyShot class, the shield block and reflection, the Magical Shield crouch, boulder spouts fire; 10 tests`.

### Wave 5.2 — ground enemies (levels 1–4 come alive)

#### WK1 — ⚑ MAJOR ◈ — Walker: Setup by tier, the frame, the thrower 1700, the spear guard 1705, hits, death, coins, the corpse raft (→ 543)
- **Files:** `Sources/FerazelCore/World/Enemies/Walker.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift` (the
  Walker Setup completed: `+0x14c = 120 + R(70)`, `+0x150 = −1`, `+0x154 = 1000 + R(400)`, `+0xf0 = 2·R(0x5fff) +
  0xbfff`, tier by p3, idle margins by p4, flip, hot rects, faces), `Sources/FerazelCore/Sprites/SpriteSlot.swift`
  (`forClass` → `.walker`), `Sources/FerazelCore/World/Movers/PlatformSprite.swift` (the corpse as a platform and its
  flotation, enemies-ground-2 §1), `Sources/FerazelCore/Front/LevelRun.swift` (cache marks for 1701…1707, 1760 set),
  `Sources/FerazelRender/Frame/FrameRenderer.swift` (sheets), `Tests/FerazelCoreTests/Enemies/WalkerTests.swift` (new),
  `Tests/FerazelRenderTests/{FrameGoldenTests,Phase2GoldenTests}.swift` (◈ values),
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
- **Gate:** G2 543 + ◈. Quick bot on levels 1–2. **Commit:** `FerazelCore: Walkers 1700/1705 — tiers, throwing, spear guard, hits, death, coins, the corpse raft; goldens moved as recorded; 9 tests`.

#### CR — ⚑ MAJOR ◈ — Crawler and Roach (→ 551)
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
- **Gate:** G2 551 + ◈. Quick bot levels 1–2. **Commit:** `FerazelCore: Crawlers and Roaches; goldens moved as recorded; 8 tests`.

#### WK2 — ⚑ MAJOR ◈ — Walker 1760 boulder thrower and 1750 Ax goblin (→ 557)
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
- **Gate:** G2 557 + ◈ (or "no golden moved" with the probe). Wave 5.2 end: G3, GWB by day, `tools/ferazel-random-play.sh
  core` + `tools/ferazel-visit-sweep.sh core` on levels 1–4 (exit 0). **Commit:** `FerazelCore: Walker 1760 boulder thrower and 1750 Ax goblin; 6 tests`.

### Wave 5.3 — flyers, water and cave

#### BA — ⚑ MAJOR ◈ — the Bat class: chasers, path bats and their spit, swarms, insects (→ 566)
- **Files:** `Sources/FerazelCore/World/Enemies/Bat.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (`:538`, `:550` — the bat Setup by sub-range, the path fields `+0xf8/+0xfc/+0x100/+0x104`; the Bat's path mode now
  in its own field, not `voicePitch` — run 29 note), `Sources/FerazelCore/Sprites/SpriteSlot.swift`,
  `Sources/FerazelCore/World/Movers/BoxSprite.swift` (`:1148` — `.KillCrate`'s Bat 0x6cc drop arm after
  `.GenerateSprite`, M l. 61312–61320, now reachable), `Sources/FerazelCore/Front/LevelRun.swift` (cache marks
  **0x6cc–0x6d5** of `.InitBatSprite` M l. 68092–68107 — run 29 carry: today only 0x6cc/0x6cd; and 0x744, 0x74d, 0x73a,
  0x73b), `Tests/FerazelCoreTests/Enemies/BatTests.swift` (new), golden files (◈), Windows references (◈).
- **Contract:** enemies-flyers §1, §3 (all), §6, §7.1–§7.5. Dump: M l. 68092–69079 (Init, Setup, SwarmMember Setup/
  Handle/Hit, Handle, InsectBody, Hit, Kill, HitTile). Chasers 0x6cc/0x6d1, 0x73a, 0x744; path bats 1741/1742 (→ 1741)
  and the spit 0x712; swarm 1869 + members; insect 1860 + body; death: coins `R(3) + 1` × 0x516, blood N = 170/100,
  +500/+100 score.
- **◈ goldens:** level 2 (Bat 1740 ×1) goldens if awake on a route; record.
- **Tests (9):** `testBatSetupBySubRange` · `testSleeperWakesOnHit` (`+0xa6 < 2 → 0x15`) · `testChaserAI` (the §3.2
  constants) · `testPathBat1741` (level 3 rec with p 2, 340, 800) · `testPathBatSpit` · `testSwarmMembersHome` ·
  `testInsectBodyFollows` · `testBatDeathCoinsBlood` · `testKillCrateBatDropArm`.
- **Gate:** G2 566 + ◈. Quick bot levels 2–4. **Commit:** `FerazelCore: the Bat class — chasers, path bats and spit, swarms, insects; 9 tests`.

#### FR — ⚑ MAJOR ◈ — Frog and Salamander (→ 574)
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
- **Gate:** G2 574 + ◈. **Commit:** `FerazelCore: Frogs and Salamanders; 8 tests`.

#### BL — ⚑ MAJOR — Blob and Crab; the Multi Crystal's Blob-attacker exception (→ 581)
- **Files:** `Sources/FerazelCore/World/Enemies/BlobCrab.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (`:570`), `Sources/FerazelCore/Sprites/SpriteSlot.swift`, `Sources/FerazelCore/Player/HitPlayerSprite.swift` (`:997` —
  `.HurtPlayer`'s Multi Crystal skip for Blob attackers, MS carry), `Tests/FerazelCoreTests/Enemies/BlobCrabTests.swift` (new).
- **Contract:** enemies-water-cave §3, §4, §7.3. Dump: Blob M l. 67661–68091 (`.HandleDeadBlobSprite` 67738–67765),
  Crab M l. 73957–74323 (+ `.HandleCrabSegSprite` 74296–74307). Blob variants by type; Crab invulnerable claw on a
  chain (first placed on level 62 — synthetic). Blobs on levels 3–4 — no golden (not ◈).
- **Tests (7):** `testBlobVariantsByType` · `testBlobStates` · `testBlobDeadSprite` · `testBlobAttackerKeepsMultiCrystal`
  · `testCrabAims` · `testCrabStrike30Frames` · `testCrabInvulnerable`.
- **Gate:** G2 581. Wave 5.3 end: G3, GWB by day, bot + visit sweep `core` on levels 1–4. **Commit:** `FerazelCore: Blobs and Crabs; 7 tests`.

### Wave 5.4 — the classes first placed after level 5, geysers, pipes

#### GF — ⚑ MAJOR — Gremlin (body + rider) and Floater (the Wraith) (→ 588)
- **Files:** `Sources/FerazelCore/World/Enemies/GremlinFloater.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`
  (`:649` — their Setup sites), `Sources/FerazelCore/Sprites/SpriteSlot.swift`, `Tests/FerazelCoreTests/Enemies/GremlinFloaterTests.swift` (new).
- **Contract:** enemies-flyers §4, §5, §7.6; enemy-shots §1.4 (Gremlin 0x712 by direction table, `+0x1aa` rotation —
  -2 §4.5; Floater 0x6f4). Dump: Gremlin M l. 69080–69819, Floater M l. 69820–70110. Placed on levels 15+ — synthetic
  (the 36-direction table is physics §6's, exists).
- **Tests (7):** `testGremlinCompositeSetup` · `testGremlinBody` · `testGremlinRiderSpit` · `testGremlinHits` ·
  `testFloaterCycle` · `testFloaterShotAtStep0x1d` · `testFloaterHurtsOnlyAfterFrame12`.
- **Gate:** G2 588. **Commit:** `FerazelCore: Gremlins and Wraiths; 7 tests`.

#### DL — minor — the Dillo (→ 593)
- **Files:** `Sources/FerazelCore/World/Enemies/Dillo.swift` (new), `Sources/FerazelCore/Sprites/SetupFaces.swift`,
  `Sources/FerazelCore/Sprites/SpriteSlot.swift`, `Tests/FerazelCoreTests/Enemies/DilloTests.swift` (new).
- **Contract:** enemies-ground §6, enemies-ground-2 §7; enemy-shots §1.4 rows (0x753 eggs, `.ShootSpines`). Dump: M l.
  72276–72974 (`.ShootSpines` 72381–72472, `.DilloLayEgg` 72473–72487, `.RandomDilloAttack` 72488–72539). No shield
  block on the Dillo contact path; contact 0xe0/0x1c0 per type. Placed on 15/22 — synthetic.
- **Tests (5):** `testDilloSetup` · `testDilloSpines5And7` · `testDilloEggBomb` · `testDilloArmourBlock` · `testDilloKillScore1500`.
- **Gate:** G2 593. **Commit:** `FerazelCore: the Dillo — spines, egg bombs, armour; 5 tests`.

#### GY — ⚑ MAJOR — geysers (design §9 (b)) (→ 600)
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
  snapshot restored, `+0x58` proc called if set — GY reads whether the geyser stores one and transcribes it); NR 3 —
  kinds 3/4 are built as read; their base face index past the 12-face cache **draws nothing** (◇ named, unreachable:
  no placement) — never a refusal; NR 4 — p4 inert as read; no sound (§6). Placed on levels 10, 50, 51 — synthetic.
- **Tests (7):** `testGeyserSetupDefaults` (p1 0 → 0x6400, p2/p3 0 → 60) · `testEruptionPhase` (`C mod (on+off+1)`) ·
  `testColumnSegmentsAndHead` · `testHeadHurtsByKind` (acid 0x70 / lava 0x150, the immunities) · `testSegmentHazard` ·
  `testTripleChildrenKind0` · `testIdleReactivationKeepsBlock`.
- **Gate:** G2 600. **Commit:** `FerazelCore: geysers — setup, eruption, column, head and segment hurt; §9 (b) as read; 7 tests`.

#### PI — minor — the enemy pipes (→ 604)
- **Files:** `Sources/FerazelCore/World/Movers/BoxSprite.swift` (the pipe arm 0x5d2…0x5d5), `Sources/FerazelCore/Session/SpriteWorld.swift`
  (`+0x1b2` collision rule: skipped as the outer sprite only), `Tests/FerazelCoreTests/EnemyPipeTests.swift` (new).
- **Contract:** enemies-ground-2 §6, enemies-flyers §7.4. Dump: `.HandleBoxSprite`'s pipe arm (raw `1006ec90..1006f060`),
  `.MTCollideSprites` (M l. 30216–30373; raw `10032744`). Child via `.GenerateSprite(p1, rec 0x200, now)`, `+0x1b2 = 1`,
  pushed 3 px/frame, the clip edge per direction, the sound at frame 3, release at `+0x150 > +0x154`. Level 21 —
  synthetic.
- **Tests (4):** `testPipeSpawnsChild` · `testEmergingClipAndPush` · `testEmergingStillCollidable` · `testPipeChildNotCounted`.
- **Gate:** G2 604. Wave 5.4 end: G3, GWB by day. **Commit:** `FerazelCore: enemy pipes; 4 tests`.

### Wave 5.5 — level 5, up to the Warrior's arena

#### OX — ⚑ MAJOR — OmniPx modes 2/4/5 (level 5's moving backdrop) (→ 609)
- **Files:** `Sources/FerazelCore/World/OmniPx.swift` (new), `Sources/FerazelCore/Seams/DrawOp.swift` (`.omniPx`, S3),
  `Sources/FerazelCore/Session/FerazelSession.swift` (the op at `.PaintFrameWrap`'s M l. 9434, drawn frames only),
  `Sources/FerazelCore/Front/LevelRun.swift`, `Sources/FerazelCore/Flow/LevelFlow.swift` (setup at level start M l. 2540; the counter on `LevelCarry`;
  turn off/kill at the loop's end M l. 5321–5322), `Sources/FerazelRender/Frame/{FrameRenderer,ParallaxBlitter}.swift`
  (the 128×128 port as PxBack slot 0; the factor backup/zeroing of `.TurnOnOmniPx`; the faces 6200/6201, 6300/6301
  under the level+sprite CLUT), `Tests/FerazelRenderTests/OmniPxTests.swift` (new).
- **Contract:** rendering-omnipx-titles §1, §3.1–§3.5. Dump: M l. 13019–13547. Modes 2/4/5 share the base-cell path
  (cells 6 + (c >> 1), c reset at 18) and the two faces (acc mod 0x8000, toroidal wrap); mode 0 off. **Modes 1/3/6/7
  and ≥ 8 stay refused at level open** (◇ Phase 6: rain, thunder, interlace, ping-pong — levels 15, 70; the level-open
  refusal is caught by `GameFlow.swift:555` and is not a quit). No RNG in modes 2/4/5.
- **Tests (5):** `testOmniPxSetupMode2` (faces 6201/6200, fx/fy 0x40/0x80, vx/vy per §3.3) · `testUpdateCyclesBaseCells`
  (9-frame cycle; c += 2 per drawn frame) · `testFaceWrapToroidal` · `testCounterCarriesAcrossLevels` ·
  `testLevel5FirstFrameDraws` (a level-5 `FrameRenderer` executes the first frame's ops with the OmniPx op, no refusal).
- **Gate:** G2 609 (DA's table gains the OmniPx rows). **Commit:** `Ferazel: OmniPx modes 2/4/5 — level 5's moving backdrop; 5 tests`.

#### LV5 — ⚑ MAJOR — level 5 "Manditraki Warrior" enterable: the arena lock, the camera pan, the gate, the boss music, the Warrior stand-in (→ 615)
- **Files:** `Sources/FerazelCore/Front/BuiltLevels.swift` (`1...5`; report "(Phase 6)"), `Sources/FerazelCore/Camera/BossArena.swift`
  (new), `Sources/FerazelCore/Camera/Camera.swift` (`.FindUpperLeftCorner`'s arena bounds and pan; `:46` relabel),
  `Sources/FerazelCore/Player/Player.swift` (`.PlayerConstraints`' arena clamp — the routine lives there today), `Sources/FerazelCore/World/Movers/BoxSprite.swift`
  (the 2940 gate's p1 −1 arm), `Sources/FerazelCore/World/Enemies/Warrior.swift` (new: Setup as read M l. 72989–73079 —
  HP by p4 (2000), the boss flag → `noBossAlive = 0`, counted in the window, `+0x18a = 1`; `.InitWarriorSprite` M l.
  72975–72988 faces; the Handle **◇** — `.StandardSpriteHandles` + its Setup face, no AI, no shot, no Hit callback,
  `// later: Phase 6`), `Sources/FerazelCore/Sprites/{SetupFaces,SpriteSlot}.swift` (`.warrior`; whatever level 5's census
  finds: platform 1403 p1 52, Box 1065, decorations 2820–2841, Bonus 3100/3214), `Sources/FerazelCore/Front/LevelRun.swift`
  (`:504–:512` the boss-music rule at level start M l. 5183–5185 area and the in-loop block `:684–:690` (M l. 5231–5240
  area — re-read: the bank and the code cite different lines); level 5's picture-cache marks incl. the Warrior's sets),
  `Ferazel/App/FerazelController.swift` (the `FerazelLevel` comment's range — code reads `BuiltLevels.range`; G5),
  `Tests/FerazelCoreTests/LevelFiveTests.swift` (new), `Tests/FerazelCoreTests/GameFlowGameTests.swift` (`1...4` →
  `1...5`; the not-built walk retargeted to node 10 via level 5's exit p1 1; the report text), `Tests/FerazelCoreTests/LevelThreeTests.swift`
  (range), `Tests/FerazelRenderTests/FaceTests.swift` (level 5's spawnables).
- **Contract:** bosses §1.1–§1.4 (framework only); world-data-format §3.2 (`hdr+0x2724` −1444, `+0x272e` 0, music 23,
  start at the right edge facing left `0x26c8`). Dump: `.PlayerConstraints` M l. 43991–44126, `.FindUpperLeftCorner` M l.
  5882–6239, `.SetupLevelSprites` M l. 1940–2103 (`fed4 = 0`, `fed0 = 1` at M l. 2016–2019, verified), `.GameLoop` M l.
  5093–5328 (music 30 when `hdr+0x2724 ≠ 0 ∧ fed0 ≠ 0 ∧ track ≠ 0x1e …`), `.HandleBoxSprite`'s 2940 arm (p1 −1: open
  while `fed0 == 1` — rise 2 px/frame to 100 px above `+0x158`, else back down). Level 5 census (Research note 2): 16
  types, 32 records. With the ◇ Warrior alive (`fed0 = 0`): walking left past x 1384 locks the arena (`fed4 = 1`, the
  40-frame pan), the player is clamped at x ≤ 1384, the camera window [map left, 1444], the gate at x 416 stays shut;
  the Warrior stands and hurts on contact (`.HitPlayerSprite` step 7: 0x70, invul 60). Leaving: Esc / ⌘W abort as
  Phase 3. A synthetic `noBossAlive = 1` (what `.KillWarrior` will set, Phase 6) opens the gate, releases the arena and
  switches to track 30 — tested, unreachable in play this phase.
- **Tests (6):** `testLevel5SetsUpEveryRecord` (32 records, no `notTranscribed`) · `testArenaLocksAtX1384` (lock,
  pan counter −40 → 0 over 40 frames, clamp) · `testCameraWindowWhileLocked` · `testGateStaysShutWhileBossAlive` ·
  `testSyntheticKillOpensGateAndTrack30` · `testBuiltLevelsFive` (`1...5`; level 5's exit p1 1 → node 10 → "Level 10 is
  not built yet (Phase 6)."; `startLevel` 5 accepted).
- **Gate:** G2 615, G5. Wave 5.5 end: G3, GWB by day, the full GE on levels 1–5 (both paths). **Commit:** `Level 5 enterable: the arena lock and camera pan, the gate, the boss music rule, the Warrior stand-in, BuiltLevels 1...5; 6 tests`.

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
- **Gate:** G1, G2 615 / 2 skips, GW2 81 / 2 skips, G3, G5, GW1–GW3, GW5, GE; by day GWB **612 / 0 / 3 / 0 (of 615)**,
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
   floats and can be stood on; scores add up (goblin 500–800, crawler 500, roach 600, bat 600); the stage-complete panel
   counts the enemies defeated.
7. **Statue spell on an enemy** — it turns to stone for 4 s, you can stand on it, it thaws 200 HP weaker.
8. **Shields** — a raised shield blocks shots from the front with a clang; the Magical Shield reflects darts and spines
   (they burn away) and shows its crouch picture.
9. **Level 4's boulder spouts** fire boulders when their button is pressed.
10. **Under water** the screen takes a blue (green in acid, red in lava) tint, and clears when you surface.
11. **Level 5 "Manditraki Warrior"** — the moving sky behind the level; walk left: the camera pans and the arena locks
    behind you, the boss music plays, the gate ahead stays shut, the Warrior stands (Phase 6 builds the fight) and hurts
    on contact; leave with Esc → abort.
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
| 1 | **PB → SP → RV** (wave 5.0) | one each | 507 |
| 2 | **DK → UT ◈ → DA** (wave 5.0) | one each | 514 |
| 3 | **RB ⚑** (wave 5.0 end) **→ EC ⚑** | two each | 524 |
| 4 | **ES ⚑ → WK1 ⚑◈** | two each | 543 |
| 5 | **CR ⚑◈ → WK2 ⚑◈** (wave 5.2 end) | two each | 557 |
| 6 | **BA ⚑◈ → FR ⚑◈** | two each | 574 |
| 7 | **BL ⚑ → GF ⚑** | two each | 588 |
| 8 | **DL → GY ⚑ → PI** (wave 5.4 end) | GY two; DL, PI one | 604 |
| 9 | **OX ⚑ → LV5 ⚑** (wave 5.5 end) | two each | 615 |
| 10 | **A5** + FABLE-GRADE phase review + fixes | one + Fable | 615 |

Every run is 2 tasks, or 3 with at most one ⚑ (D34 cap rule). G3 + GWB (by day) at each wave end; GE at the end of
waves 5.2 (levels 1–4, `core`), 5.3 (levels 1–4, `core`), 5.5 (levels 1–5, `both`) and A5 (`both`, mandatory).
No HectorKit task: G1 = HK `35a85ba` untouched for the whole phase.
- **Dependencies:** SP, RV, DK, UT independent; DA after DK (A13 drawn) and UT; RB after DA and PB; EC after RB; ES after
  EC; WK1 after ES (axes, spear thrust); CR after EC; WK2 after WK1 + ES; BA after ES (spit) + EC; FR after ES + EC; BL
  after EC; GF after ES; DL after ES; GY after EC; PI after WK1 + BL + BA (its children are Walkers, Blobs, insects); OX
  independent of the enemies (after DA, its rows); LV5 after OX + WK1 (contact path) + ES; A5 after all.
- **File overlaps that force order:** `SpriteSlot.swift` (EC, WK1, CR, BA, FR, BL, GF, DL, GY, LV5), `SetupFaces.swift`
  (EC, WK1, CR, BA, FR, BL, GF, DL, LV5), `HitPlayerSprite.swift` (EC, ES, BL, GY), `FerazelSession.swift` (SP, EC, ES,
  OX), `LevelRun.swift` (EC, WK1, CR, WK2, BA, FR, OX, LV5), `BoxSprite.swift` (ES, BA, GY, PI, LV5), `FrameRenderer.swift`
  (SP, ES, WK1, OX), `SpriteBlitter.swift` (SP, DK, DA, EC), golden test files (UT, WK1, CR, WK2, BA, FR),
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
| The Warrior's Handle/Hit/Kill: it stands in its Setup face, hurts on contact as read, takes no damage, never dies; the gate stays shut while it lives | LV5 (`Warrior.swift`) | Phase 6 |
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
| underwater tint — `PlayerLiquids.swift:137–139`, `Player.swift:360` (D38 A4) | UT |
| Magical Shield crouch face — `PlayerStates.swift:556` (D38 A4) | ES |
| `+0x1b5` counted only inside `_DAT_1009fe8c` — `SetupFaces.swift:538–:649` stubs (run 29 [MED]) | EC |
| Bat cache marks 0x6ce–0x6d5 (run 29); Bat path mode in `voicePitch` | BA |
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
| burn-away — `StandardSprite.swift:94/:124` | EC |
| boss music rule — `LevelRun.swift:504–:512`, `:684–:690`; boss Setups' `fed0` | LV5 |
| level-load cache marks for other classes — `LevelRun.swift:1051/:1117` | each class task; LV5 for level 5 |
| boss grab — `PlayerStates.swift:371`, `PlayerState.swift:196` | **Phase 6** (Chief, Xichra) — A5 relabels |
| `HitPlayerSprite.swift:10` header, `PlayerStates.swift:8` header, `Camera.swift:46`, `BackgroundSprite.swift:402/:437` stale "later: SH" | A5 sweep (comment-only) |
| Q15 items 1–6 | SP (1, 3, 4), DA (2), RB (5), RV (6's code items); shrink rule → Open question 3 |
| gap ledger #3 empty-inventory box | RV |
| gap ledger #4 voice eviction | **recorded deviation** (Ruling 10, KD1) |
| A13 lit sprite at full darkness | DK |

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

---

## Pre-execution self-audit

1. **Design §8 row 5 coverage.** ground (WK1, WK2, CR, DL) ✅; flyers (BA, GF) ✅; water/cave (FR, BL) ✅; enemy shots
   (ES) ✅; damage both ways (EC, ES, each class's Hit) ✅; particles in full (EC burn; blood/explode/glow exist) ✅;
   effects (ES kill effects, EC hazards) ✅; §9 (b) (GY) ✅; §9 (c) enemy half (EC scan, BA) ✅; "through the first boss
   door" (OX, LV5, Ruling 2) ✅; Q15 1–6 (SP, DA, RB, RV, Open q. 3) ✅; the two Phase 2/4 gaps (UT, ES) ✅.
2. **Numbers sourced.** Function spans: Research note 1 (computed from the dump's headers). M lines re-read
   2026-10-30: 2016–2019, 4215–4275, 4674–4719, 9428–9436, 31704–31727, 46440–46480, 64940–64950, 68092–68107. Bank
   numbers are cited by section; each task re-reads. Ladder arithmetic: 502 + (0+3+2+2+3+2+2) = 516; + (8+10) = 534;
   + (9+8+6) = 557; + (9+8+7) = 581; + (7+5+7+4) = 604; + (5+6) = 615 ✅ (each task's "Tests (N)" equals the names it
   lists). ⚑ MAJOR: RB, EC, ES, WK1, CR, WK2, BA, FR, BL, GF, GY, OX, LV5 = **13**. Every run ≤ 2 ⚑, 3-task runs hold ≤ 1.
3. **Names checked against the code (6a70bce).** `SpriteHandler` (`SpriteSlot.swift:483ff`, `.inert` at `:485`),
   `forClass(type:)`, `FerazelSession.swift:512` (`.inert` no-op), `:1006–:1026` (`wrapDrawSpritesOp`, `diffuseSeeds`),
   `FrameRenderer.swift:~371` (`wrapDrawSprites(… drawn:)`), `SpriteBlitter.swift:170` / `:571` (`Refusal.darkness`),
   `LevelServices.DiffuseRandoms`, `BuiltLevels.range` (1...4), `ScreenGammaOp` (5 cases), `ScreenFade.fadingEnabled`,
   `SoundVoices.playing: Set<Int16>`, `SoundTool.listLength` 16, `StatusBar.swift:188`, `BootFacesTests` (2 tests),
   `VisitSweepTests` / `WinVisitSweepTests` (opt-in `FERAZEL_VISIT_SWEEP`), `proof-b-ferazel.sh:117–127`,
   `smoke-ferazel-win.sh:59–64`.
4. **Layering.** Core gains no Apple framework; OmniPx positions are integers in Core, the port is Render's; the bot
   and audit are tests; no shell source changes.
5. **Risk.** Biggest: the ◈ tasks — five classes come alive on the golden routes; each must show the cause by the
   switch-off check. Second: the bot finding real refusals (good — but it can stall the phase: each row is a fix task
   inserted before A5). Third: LV5's arena + camera (the pan shifts both bounds by 16·|counter|). Fourth: DK — if the
   bytes after the ambient table cannot be determined, the seat rules.

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
(EC; expected coins 0x516 only).
BC53 `geysers.md` NR 2 — closed: `.IdleToActiveSprite` (M l. 4215–4275) calls `.MTNewSprite` with setup 0, restores the
0x220-byte snapshot and calls `+0x58` if set — no Setup re-run, no second `AllocateGameMem(0x44)` (GY confirms the
geyser's `+0x58`).
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

(empty — for the two Opus plan legs, the FABLE-GRADE plan leg, and their fix rounds)
