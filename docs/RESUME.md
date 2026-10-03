# RESUME — one-paste session triggers (refreshed 2026-10-03)

## FOR BEN

Phase 0 is done (HectorKit v0.1.0; Aki data census). Two sessions can run from here, in either order or at
the same time: the **RE-bank lane** remainder (Trigger A: Ferazel, Deimos, Cythera) and **Phase 1** (Trigger
C: HectorShell + Aki's splash, map and prefs screens — the first thing you will SEE).

---

## Trigger A — RE-bank lane (all hit-list games)

```
Session: Ambrosia Classics — RE-bank lane (all hit-list games). Repo ~/Developer/Ambrosia-Classics.
READ FIRST (scoped): CLAUDE.md; docs/STATE.md (whole); docs/design-2026-10-03-hectorkit-and-classics.md §1, §4, §6
only; ghidra/README.md (the decompile recipe + binary forms); ~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md
(where every original lives). Method: ~/Developer/Toolkits/fable-kit/fable.md §4 §6 §10 if first session here.
Do NOT read the EV repo's STATE/DECISIONS/ghidra findings.

GOAL: produce a confidence-labelled RE bank per game under docs/<game>/ (INDEX.md + topical files, same
discipline as the EV repo's docs/ghidra/INDEX.md: code readings, HIGH/MED/LOW per claim, NOT-RESOLVED
listed, nothing behaviour-verified until Ben's eyes). Games, in this order:
 1. Aki 1.2.0 (Intel slice of ~/Developer/Ambrosia/Resources/ambrosia-extracted/Action-Adventure/Aki -
    Mahjong Solitaire/Aki 1.2 UB/Aki.app) — Cocoa/ObjC rewrite; bank the ObjC method map, the rules
    (open-tile test, timer/bonus/penalty maths per difficulty, shuffle/hint/undo), level progression (17),
    the plain-text .aki format, prefs/stats storage; then DIFF against the 1.1.0 PPC dump
    (~/Developer/Ambrosia/ghidra/Aki_ppc.decompiled.c, Layout1..12 = AddTile(x,y,layer) lists; resolve the
    DOUBLE_ literals via read_const.py adapted to the PPC __literal8 section) — every rule delta is a
    banked item for Ben to arbitrate (1.1.0 = what he remembers, 1.2.0 = last word).
 2. Bubble Trouble X 1.1 (dump exists: ~/Developer/Ambrosia/ghidra/BTX_i386.decompiled.c, 1559 fns, all
    named): hero/enemy movement + AI per enemy type, bubble push/pop/bounce, dynamite, balloons, jewels,
    bonuses/EXTRA/multiplier/time bonus, MAZE(176 B)/LEVL(64 B)/btSP(TMPL in file)/FILM record layouts,
    the 30 fps frame step, FILM replay semantics (the future machine oracle).
 3. Ferazel's Wand 1.0.3 (PEF data fork `Ferazel's Wand` + .rsrc, under …/Ferazel's Wand (installed)/files/):
    engine identity, World Data / Sprites / Backgrounds record formats, physics constants, spell system.
 4. Deimos Rising 1.0.6 (PEF, …/DeimosRising/Deimos Rising 1.0.6 (volume)/Deimos Rising/): Pak format,
    sprite/sound containers, wave scripting.
 5. Cythera 1.0.4 (PEF, …/RPG/Cythera/Cythera (installed)/files/): Cythera Data format, .ai scripts.

RULES: Ghidra headless per ghidra/README.md (reuse existing dumps; new dumps + binaries stay git-ignored);
Opus implementers for each game's bank, a Fable reviewer per bank that reports EVERYTHING with confidence
(no self-filtering) and demands raw-disasm/data evidence for every HIGH claim; census numbers only from tool
output; write files, not chat reports (background agents: name an output path). Commit each bank to main
and push. Orchestrator stop at ~300k of its OWN context: wrap (STATE + handoff + RESUME) and chip the
continuation; never start a new game's bank you cannot finish. This lane edits docs/<game>/ and appends ONE
status line to docs/STATE.md; it does not touch the design doc or HectorKit.
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
