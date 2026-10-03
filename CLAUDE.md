# Ambrosia Classics — native Apple Silicon revivals of Ambrosia's smaller games

Non-commercial game preservation, sibling of `~/Developer/Ambrosia` (the EV engine). One xcodegen
project, one app target + small core package per game, all on `HectorKit`
(`~/Developer/HectorKit`, local path dependency during build-out). Each game loads the ORIGINAL
data from its own folder under `Resources/` and replicates its own original 100% (no modern
affordances, no per-element commissioning questions — standing ruling carried from EV, D30/D67).

The games (Ben's list, final 2026-10-03): **Aki — Mahjong Solitaire** (first), **Bubble Trouble X**
(second), then Ferazel's Wand, Deimos Rising, Cythera. Nothing else unless Ben names it.

## Session start (read first)
1. `docs/STATE.md` — live state, whole file (small by rule).
2. `docs/DECISIONS.md` rulings index + only the entries your trigger names.
3. Newest `docs/handoff-*.md` only if a session left WIP.
4. The game's RE bank under `docs/<game>/` — load only the topical file the task needs.
5. First session on this machine: `~/Developer/Toolkits/fable-kit/fable.md` §4 §6 §10.

## Oracles
- The original binaries, decompiled with Ghidra headless into `ghidra/<game>.decompiled.c`
  (git-ignored; recipe in `ghidra/README.md`). Aki 1.1.0 PPC + 1.2.0 UB; Bubble Trouble X 1.1 UB.
- Shipped documentation per game (Aki Handbook PDF; the Bubble Trouble HTML guide + editor read-me).
- The archive mirror index: `~/Developer/Ambrosia/docs/ARCHIVE-INDEX.md` (where every recovered
  copy lives and how it was opened).
- Ben's play recall is the feel oracle; his eyes close the honesty gates (fable-kit §6).

## Build / run / test
```sh
cd Aki/Core && swift test                          # each game's core package has its own suite
xcodegen generate && xcodebuild -scheme Aki build  # never hand-edit the pbxproj; project.yml is truth
```
Staged builds for Ben go to `out/<Game>/` as a double-clickable `.app` + what-to-expect steps.

## Workflow
Fable-kit method: STATE updated the same session; real forks recorded in DECISIONS; sessions end
with a handoff + a `spawn_task` chip carrying the full next-session trigger (RESUME.md fallback).
Commit each verified logical step to `main` and push. Local verification only; no cloud CI.
Opus implementers, Fable reviewers; reviewers report everything with confidence, no self-filtering.
