# RESUME — one-paste session triggers (refreshed 2026-10-03)

## FOR BEN

Two sessions can run from here, in either order or at the same time: the **RE-bank lane** (decompile
and bank every game on the hit list) and **Phase 0** (lift HectorKit out of the EV engine, then census
Aki 1.2). Phase 0 waits on your read of the design doc; the RE lane does not.

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
 6. pop-pop 1.0.4 (stripped i386; strings + data formats only unless symbols appear).
Maelstrom: no RE — note the GPL 3.0.x upstream source as the oracle.

RULES: Ghidra headless per ghidra/README.md (reuse existing dumps; new dumps + binaries stay git-ignored);
Opus implementers for each game's bank, a Fable reviewer per bank that reports EVERYTHING with confidence
(no self-filtering) and demands raw-disasm/data evidence for every HIGH claim; census numbers only from tool
output; write files, not chat reports (background agents: name an output path). Commit each bank to main
and push. Orchestrator stop at ~300k of its OWN context: wrap (STATE + handoff + RESUME) and chip the
continuation; never start a new game's bank you cannot finish. This lane edits docs/<game>/ and appends ONE
status line to docs/STATE.md; it does not touch the design doc or HectorKit.
```

## Trigger B — Phase 0: HectorKit lift + Aki 1.2 census (after Ben's design review)

```
Session: Ambrosia Classics — Phase 0 (HectorKit lift from EV + Aki census). Repos ~/Developer/HectorKit
and ~/Developer/Ambrosia-Classics. READ FIRST (scoped): both CLAUDE.md; Ambrosia-Classics docs/STATE.md
(whole); docs/design-2026-10-03-hectorkit-and-classics.md (whole — it is the spec); the EV files to lift:
~/Developer/Ambrosia/engine/EVCore/Sources/EVResources/*.swift, EVGraphics/PICT.swift, EVGraphics/Ditl.swift,
EVCore/SndSound.swift + Tests/EVResourcesTests/*, the PICT opcode tests and SndSoundTests (grep them).
Method: fable-kit §4 §6 §10. Do NOT read the EV repo's STATE/DECISIONS.

STEP 1 — writing-plans: produce docs/plans/2026-10-xx-phase0-hectorkit-lift.md (one opus planner + one
Fable reviewer + fix pass; plan template ~/Developer/Toolkits/fable-kit/plan-template.md). The plan's top
section is the verification model from design §5.
STEP 2 — execute: HectorKit Package.swift (macOS 15, Swift 6, zero deps) with HectorResources /
HectorGraphics / HectorAudio (HectorShell is Phase 1); move the files + tests with history-free copies;
rename module prefixes only; `swift test` green; record the zero-skip floor in tools/check-zero-skip.sh;
real-data tests read HECTORKIT_DATA env paths and COUNT skips. Then a census task in Ambrosia-Classics:
all 82 Aki 1.1 PICTs + every Aki 1.2 PNG decode/load through the kit to declared sizes; every AIFF/MP3/snd
opens; write docs/aki/data-census.md. Tag HectorKit v0.1.0 when green. Commit each step, push both repos.
EV repo: untouched (the shim PR is a later, separate task).
RULES: Opus implementers, Fable spec review on every task (report-everything, mutation evidence for fixes);
Ben never builds; 300k orchestrator stop → wrap + chip with the Phase 1 trigger.
```
