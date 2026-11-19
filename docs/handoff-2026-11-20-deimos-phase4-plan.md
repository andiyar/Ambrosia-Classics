# Handoff — Deimos Rising Phase 4 (the front end): the plan is written (2026-11-20)

Seat: Claude Fable 5.2. Docs only; no Swift, no build, no test was changed.

## What exists now

- **The plan:** `docs/superpowers/plans/2026-11-20-deimos-phase4.md` (D52). It is the authority for Phase 4.
- **Four grounding appendices** beside it, `2026-11-20-deimos-phase4-grounding-{A,B,C,D}.md`: A the screens before a
  game; B starting a game and coming back, scores, films; C the settings file, the two settings windows, the
  controller; D the sweep of all 30 stand-ins and the Swift seams.
- **Reviews:** two Opus legs (spec, quality) — both "pass with fixes", 37 findings, all folded in — then the seat's
  cross-check. The spec leg re-read eight facts in the listing; all eight held.

## Running order (the Coordinator starts each; at most two at once)

| Order | Section | Seat | Needs on main | May run beside | Handoff it writes |
|---|---|---|---|---|---|
| 1 | S0 the OS X build on file; bank corrections | Opus | wave 3.4 | S1a | `docs/handoff-deimos-phase4-s0.md` |
| 1 | S1a seams and the element list | Fable | wave 3.4 | S0 | `docs/handoff-deimos-phase4-s1a.md` |
| 2 | S1b the front end's frame | Fable | S1a | S0 | `docs/handoff-deimos-phase4-s1b.md` |
| 3 | S2 main menu, credits | Fable | S0, S1b | S4 | `docs/handoff-deimos-phase4-s2.md` |
| 3 | S4 settings file, high scores, name entry | Opus | S0, S1b | S2 | `docs/handoff-deimos-phase4-s4.md` |
| 4 | S3a starting a game and coming back | Fable | S2, S4 | S5 | `docs/handoff-deimos-phase4-s3a.md` |
| 4 | S5 Last Film and demos | Opus | S0, S1b | S3a | `docs/handoff-deimos-phase4-s5.md` |
| 5 | S3b level select | Opus | S3a | S6 or S7 | `docs/handoff-deimos-phase4-s3b.md` |
| 5 | S6 boot; the configuration window | Fable | S0, S1b | S3b | `docs/handoff-deimos-phase4-s6.md` |
| 6 | S7 the controls window; the controller | Opus | S6 | S3b | `docs/handoff-deimos-phase4-s7.md` |
| 7 | S8a the app | Fable | S0–S7 | — | `docs/handoff-deimos-phase4-s8a.md` |
| 8 | S8b goldens, stage, gate 4 | Fable | S8a | — | `docs/handoff-deimos-phase4-s8b.md` |

The phase ends at S8b: the app is staged with the gate-4 card and everything stops for Ben. Wave 3.4 is already on
main (68b93b6), so S0 and S1a can start now.

## Open questions (sent to the Coordinator for Ben; none blocks — the plan builds the default)

1. Run a whole-game comparison of the OS 9 and OS X builds as its own job? (The app file holds both; all research
   so far read the OS 9 one; Ben played the OS X one.) Default: yes, outside Phase 4.
2. Whose name does the menu's "registered to …" line show? Default: "AMBROSIA CLASSICS" until he says.
3. The website line: a click does nothing (default), or the original's "open the browser" dialog?
4. Command-Q mid-game: quits at once and saves (default); the original ignored it there.
5. Controller: button choices; two pads; the original's own gamepad windows (default: not built); starting
   2 PLAYER from the pad (default: keyboard or mouse only).
6. Look of the two settings windows: classic grey with plain sliders (default); he saw the OS X look.
7. Loading screen: every item name for one screen update (default), or only the five lines.
8. "Erase all scores?" and the data alerts: a normal macOS alert (default), or drawn by the game.

## Corrections to `docs/deimos` found while planning (for S0's bank task; not applied — wave 3.4 owned those files)

The lists are in the appendices: A §11 (10 notes), B §9 (6), C §8 (6). In addition:
1. `front-end.md` and the remainder plan speak of an "attract mode": no demo ever starts by itself; `G+0x24` is the
   demo cycle counter (B §0; callers of `FUN_10024de0` are `10022d8c` and `10023cec` only).
2. No "replay" button exists: Last Film is the `F` key only (B §0, `10023d14`).
3. The remainder plan's stand-in 4 (level-1 music) is the original's own "no music playing" branch, not a stand-in.
4. Outside the bank: `DeimosPrefs.swift:15` and `KeyTable.swift:8` call the key-slot meanings LOW; they are HIGH (C §3b).

## Follow-ups outside Phase 4

- The whole-game comparison of the two builds (question 1).
- The OS X disassembly exists only in a finished helper's scratchpad; S0's first task regenerates and commits it.

## Brief for the first build sections (rebuilt from nothing)

**S0 (Opus seat) and S1a (Fable seat) start together; the same brief with the section name changed.**

You are the orchestrator for section **S1a** [or **S0**] of Deimos Rising Phase 4 (the front end), in
`~/Developer/Ambrosia-Classics`. Deimos Rising is a native Swift replica of the 2001 Mac game; the game itself is
built (Phases 1–3) and Phase 4 puts the original's screens around it. Say which model you are in your first message.

Read, in this order and nothing more: the repo's `CLAUDE.md`; the Deimos section of `docs/STATE.md`;
`docs/superpowers/plans/2026-11-20-deimos-phase4.md` from the top through "Sections and running order", then your
own section only; the "Verification model (read first)" part of `docs/superpowers/plans/2026-11-05-deimos-remainder.md`
(gates, standing rules, landmines); and from the grounding appendices only the sections your tasks cite (for S1a:
appendix D Part 2 §2, §3, §7 and Part 3, A §5.2 and §7, B §1c and §5; for S0: C §0, §6 and §8, A §11, B §9).
Method: `~/Developer/Toolkits/fable-kit/orchestrator.md`, under a Coordinator (`project-planning.md` §6, §6a).

Do your section's tasks in order. Per task: one `fk-implementer`, then two `fk-reviewer` legs (spec, then quality),
no `model` parameter, in the foreground. Before the first dispatch confirm that wave 3.4 is on main
(`git log main --oneline | /usr/bin/grep "wave 3.4 closed"`). Touch only the files your section lists; a seam or file
you need that is closed to you is a STOP, not an edit. Read your meter with `get_usage` before every dispatch and
say the figure; cap 300k. At most two heavy build or test processes at a time. No app launch, no sound.

At the close: merge to local main, update the Deimos lines of `docs/STATE.md`, write the handoff file your section
names (`docs/handoff-deimos-phase4-s1a.md`, with the final seam signatures in full; or
`docs/handoff-deimos-phase4-s0.md`), commit it to main, remove your worktree, and make the first line of your final
message `CLOSED S1a — handoff: docs/handoff-deimos-phase4-s1a.md` (or `STOPPED S1a — <reason>`). Do not start the
next session. Questions only Ben can answer go to the session that started you.
