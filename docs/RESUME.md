# RESUME — one-paste session triggers (refreshed 2026-10-03)

## FOR BEN

Phase 0 is done (HectorKit v0.1.0; Aki data census) and all five RE banks are on main. Next is **Phase 1**
(Trigger C: HectorShell + Aki's splash, map and prefs screens — the first thing you will SEE). Trigger A2 is
optional deepening, only if a build session hits a NOT-RESOLVED wall.

---

## Trigger A — RE-bank lane: DONE 2026-10-03

All five banks are on `main` (head 01cb120): `docs/aki/`, `docs/bubble-trouble/`, `docs/cythera/`, `docs/deimos/`,
`docs/ferazel/`. See `docs/handoff-2026-10-03-re-bank.md`. Ruling: Aki targets 1.2.0.

## Trigger A2 — optional RE deepening (only if a build session hits a NOT-RESOLVED wall)

```
Session: Ambrosia Classics — RE deepening for <game>. Repo ~/Developer/Ambrosia-Classics (main; push allowed).
READ FIRST: CLAUDE.md; docs/STATE.md; docs/handoff-2026-10-03-re-bank.md ("What remains"); docs/<game>/INDEX.md
(NOT-RESOLVED list + Review ledger) and ONLY the topical file the wall names; ghidra/README.md (recipe; the dumps
are git-ignored — regenerate with decompile.sh, PEF needs -processor PowerPC:BE:32:default -cspec macosx; set
GHIDRA_PROJ outside any dot-dir). Method: fable-kit orchestrator.md; Opus implementer, Fable-grade reviewer that
demands raw-disasm/data evidence per HIGH claim, Opus fix pass; append findings to the topical file + one INDEX line
(never a monolith), ⚑ corrected markers for changed readings. Known walls: Deimos gameplay code (movement, spawn
sets, weapons, damage — consider running the original under emulation to label functions by behaviour); Cythera
combat arithmetic (script bytecode; builtins are decompiled in script-builtins.md); Ferazel INDEX item 14.
Hazards: otool -tV fails on the Aki 1.1 PPC binary (use a Ghidra disasm post-script, e.g. docs/ferazel/tools/
FzDisasm.java); subagents cannot write files named REPORT-*.md. Commit per finished bank to main and push;
one STATE line; handoff + chip at the cap (250k orchestrator context).
```

## Trigger C — Phase 1: HectorShell + Aki static screens (brainstorm → plan → build)

```
You are the ORCHESTRATOR for Ambrosia Classics — Phase 1: HectorShell (fixed 800x600 logical canvas in an AppKit
window, integer-crisp scaling with fit-smooth fallback, fullscreen toggle, mouse/keys in canvas coords, per-frame
RGBA present path — Metal vs CALayer decided by MEASURING) plus Aki's static screens from the real 1.2.0 art:
splash (welcome.png), map (map.png + the twelve lanterns, progression state), Preferences dialog (strings from
the 1.2 nibs). Repos ~/Developer/Ambrosia-Classics (work in a worktree: EnterWorktree, never `git stash`, verify
the branch before every commit; the worktree needs the untracked symlink .claude/worktrees/HectorKit →
~/Developer/HectorKit for the ../../../HectorKit path dependency) and ~/Developer/HectorKit (main directly; pin
Classics to the HectorKit tag only when a game ships). Push both. Orchestrator cap: measure the drop in
<total_tokens> since your first message (note the opening figure); Ben may lift it — ask before pushing past 300k.
Invoke `superpowers:brainstorming` FIRST (this phase has unlocked design decisions: present path, window/scaling
behaviour, how the map's lanterns and progression are drawn), then `superpowers:writing-plans` (one Opus planner,
one Fable reviewer with a dry run, fix pass), then `superpowers:subagent-driven-development`. House method:
~/Developer/Toolkits/fable-kit/orchestrator.md; if you are not Fable, opus-driver.md first.

MODEL SEAT: say which model you are in your first message. Every subagent `model: "opus"` — except Fable-grade
review legs on MAJOR tasks (omit `model`).

READ FIRST (in order): 1. docs/STATE.md (whole). 2. docs/handoff-2026-10-03-phase0-plan.md. 3. Design doc
docs/design-2026-10-03-hectorkit-and-classics.md §2 (HectorShell row), §4, §4a (scaling ruling), §5, §6 item 1,
§7. 4. docs/aki/INDEX.md, then rules.md and method-map-1.2.md ONLY for splash/map/prefs (the RE bank; 1.2.0 is
the replica target — Ben's ruling 2026-10-03). 5. docs/aki/data-census.md §3 (art map 1.1 PICT ↔ 1.2 PNG) and
assets-census.md. 6. HectorKit CLAUDE.md + docs/DECISIONS.md D1–D3; its public API (Sources/HectorGraphics:
PICT, CodecImage, Ditl; HectorResources: ResourceReader). 7. The Aki Handbook PDF (1.2 bundle) for what the
screens look like. Do NOT read the EV repo's STATE/DECISIONS/ghidra findings.

STATE (live, 2026-10-03 night): HectorKit v0.1.0 = f578925, gate `tools/check-zero-skip.sh` PASS floor 119
(env HECTORKIT_DATA_NOVA / _NOVA_REFERENCE / _AKI11; defaults in the script). Classics main has Aki/Core
(AkiCore: AkiBundle; aki-census; 6 tests via AKI_DATA_11/_12), docs/aki/data-census.md, DECISIONS D1–D2.
Resources/Aki/1.1.0.app and 1.2.0.app are git-ignored symlinks to the archive copies. No app target, no
project.yml yet (xcodegen; one app target per game; never hand-edit the pbxproj). Deviations the design doc
doesn't know about: 71/11 PICT split; PICT 135 has a real alpha plane; 1.2.0 is the replica target.

SCOPE: design + plan + build HectorShell (HectorKit, new module, unit tests for coordinate mapping + scale
rules + a render smoke) and the Aki app target's splash/map/prefs — static screens, no game logic, no editor,
no sound beyond what the splash needs (music toggle in prefs may be a stub that records the setting). The
output Ben sees: a staged double-clickable `.app` in out/Aki/ with what-to-expect steps, boot-smoke-tested
without stealing focus more than once per batch. STOP at the honesty gate: "that is Aki's map screen" is Ben's
verdict; do not chip past it. Do NOT start Phase 2 (tiles/rules/timer).

VERIFICATION GATE: HectorKit `tools/check-zero-skip.sh` PASS at the new recorded floor (≥ 119 + HectorShell
tests); `swift test` in Aki/Core green; `xcodegen generate && xcodebuild -scheme Aki build` BUILD SUCCEEDED;
headless screenshot of each screen compared by eye (yours) against the Handbook/1.2 art before Ben sees it;
then SendUserFile the screenshots + the .app path and STOP for his verdict.

AUTHORIZATIONS: merge the worktree branch to main when gates pass: yes; push both repos: yes; tag HectorKit:
v0.2.0 only after Ben's map-screen verdict; EV repo: NEVER edit; game data: never commit.

HAZARDS: `swift test` prints one 'All tests' block per bundle — count `Test Case` lines (the gate does).
`HECTORKIT_TEST_LOG` per concurrent gate run. Retina: 800x600 logical → integer scale 2x/3x; fit-smooth only when
not an integer multiple. The 1.2 nibs are XML (no DITLs). Never put game knowledge in HectorKit.

CLOSE: finish the in-flight task at the cap, never start another. Merge when verified; STATE + DECISIONS
(real forks only) + handoff as-built; memory file + index line; spawn ONE chip for the next step carrying THIS
block updated; closing message in plain English: what landed, what review caught, "Still owed by you" (the
map-screen verdict), "Chips queued".
```
