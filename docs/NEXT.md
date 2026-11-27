STATUS: PAUSED

# NEXT — Ferazel's Wand is paused (archived 2026-11-28, after Phase 6A "through the Goblin Chief")

**Why.** The original author is selling an official remaster (https://mixedmetaphor.itch.io/ferazels-wand). Ben
ruled on 2026-11-26 (D72.1): finish Phase 6A, then pause. Paused, not cancelled: Ben resumes if the remaster
disappoints. **Start no session from this file unless Ben says to resume Ferazel.** The unattended loop stays stopped.

## Where it stands
- **12 of 24 levels play:** 1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21, 22, with both boss fights so far (the Warrior,
  the Goblin Chief) and a level chooser of our own (L on the main menu; known difference 9).
- **Both builds are staged from 5d1c966** (2026-11-28): the Mac app on Ben's Desktop and in `out/Ferazel/` of the
  main checkout; the Windows zip on the Desktop and, with its checksum, in `releases/ferazel-6a-archive/` of the
  main checkout. Nothing was uploaded; Ben sends the zip to Andrew himself.
- **Every machine check passed** (the table is in `docs/STATE.md` and on the card, `Ferazel/WHAT-TO-EXPECT.md`).

## What is owed (all Ben's, none blocks anything)
- **Q22** — the Phase 6A gate, Mac and Windows (`docs/QUESTIONS.md`). Levels 20, 21 and 22 have never been seen by
  anyone: his eyes are the first.
- **Q18** — the Phase 5 gate, still open.
- Older "for your later read" items: Q16, Q15's follow-ups, Q13, Q17.

## Open carries, for whoever resumes
- What a level restart does to the touch areas of object types that measure themselves from a cached picture is
  **not built** (D73.3; read in run 68, never implemented).
- **Not verified [LOW]:** when a looping sound (the rain) runs out, `SoundTool.mixBlock` re-inserts it in the same
  mix pass; a sound of equal priority and volume sitting before it may be mixed twice in that one block. Not
  checked against the binary's `.STLoopCallBack`.
- The older carries listed in STATE's Ferazel block and in the plan's "As executed — 6A-L22" (the full light
  table's missing alert, D72.3; the rope rounding tie; the blades' bottom clip shown only by tests).
- After the last harness fix (a6d448c, tests only) the sweep and the bot were re-run on the Core path and the
  three harness test classes pass; the other 177 render tests were not re-run (nothing they use changed).

## How to resume
1. Read `CLAUDE.md`, `docs/STATE.md` (the Ferazel block), `docs/handoff-2026-11-28-ferazel-archive.md`, and D72–D74.
2. Act on any answers under Q22 and Q18 first (each note becomes a task).
3. The next step is **the 6B planning run (P6B)**: research and plan levels 25 to 52, starting with the Wizard
   (level 25). Authority: `docs/superpowers/plans/2026-11-04-ferazel-remainder.md` ("0. The verification model",
   the wave table) and its design spec beside it.
4. Make a fresh worktree; the Ferazel worktrees were removed at the archive. The first builds will be cold.
5. Launch rules: muted only; unattended runs keep 09:00–21:00; when Ben himself says go, the hours rule yields
   (D74.1). Never ask to look at the game's window (D70.5).
