# Handoff — Ferazel's Wand, run 67 (2026-11-24 into 2026-11-25)

**Seat:** Fable 5.2, started by the Coordinator; foreground only; nothing launched (the whole run was at night).
**Times:** started 2026-11-24 20:23, closed 2026-11-25 about 03:20 (Sydney).
**Context:** 127k at the start, 240k at the close. Weekly limit at the close: 36% Fable, 48% all models.

## What is now true
- **Level 20 "Hangnabit" is playable on main** (commit fcea130): clouds in front of everything, 28 spinning
  blades, maces on programmed paths, strong wind, the hang glider. Levels playable: 1–5, 10, 11, 15, 18, 20.
- **The lit-blade fix is built inside it** (ruling D67.1, Ben's option A — his mailbox Q1 was still unanswered):
  on level 20, where the map has no lighting, anything lit by a light made during play is drawn plain and unlit
  instead of ending the game. It covers blades, maces and chains alike, and is listed as known deviation 7.
- Numbers, all the seat's own runs at the merged commit:

  | check | result |
  |---|---|
  | Core suite | 795 (793 passed, 0 failed, the 2 named opt-in skips) |
  | Windows-kit suite | 88 (86 passed, 0 failed, the 2 named skips) |
  | census | 1,108 items, 0 failures |
  | Mac app build, both Windows cross-builds, the Mac SDL build | all succeed |
  | visit sweep, ten levels | 8,524 visits on each path, no failures |
  | random-play bot, ten levels | 216,000 steps on each path, no failures |

- No picture or state value of any earlier level moved.

## Rulings (D68)
1. The lit-blade fix has its own test, so the Core count is 795, one above the plan's 794; every later number in
   the plan was moved up by one (the phase ends at 815).
2. The fix covers every sprite that takes play-made light, and sits where the draw word is formed.
3. The cloud test's frame-1 picture was retired: level 20's own first-frame picture is the same frame.
4. The clouds' first-frame difference from the original cannot be seen (the original's screen is black then).
5. The sweep ran during the reviews from a separate copy; the fix round was proven to touch tests and comments only.
6. The pipes task (6A-PS) was not started: no room left in the seat's context.

## Not done / owed
- **6A-PS** (the pipes' level spawn) — heads run 68.
- **The muted boot check of level 20** — owed by day (launches are forbidden 21:00–09:00). Nobody has seen the
  level on screen yet.
- Proof B (the Wine test run) and the Mac SDL smoke — owed at the wave end, by day; neither has run on any test
  added since run 64.

## Waiting on Ben
- Coordinator mailbox **Q1** (what a lit blade on level 20 shows): "plain and unlit" is now built; his answer
  would replace it. No new question was added this run (the next free number is still Q2).
- Unchanged: Q18 (the Phase 5 gate), Q21, Q19 and the older ones in `docs/QUESTIONS.md`.

## Brief for run 68 (rebuilt from nothing)
Read `docs/NEXT.md` and run it. In short: build **6A-PS** — enemy pipes spawn from the level data, a type task
tested on a stand-in copy of level 21 (Core → 796); then, only if the seat's context meter is under 150k once that
is merged, open **level 21 "Obfuscation & Edification"** (6A-L21: Core → 799, Windows kit → 89, with the census,
a new Windows level picture, and the full sweep and bot on eleven levels in both shells). If the run starts by
day, first do the owed muted boot check of level 20. The one plan is
`docs/superpowers/plans/2026-11-04-ferazel-remainder.md`; live state is the Ferazel block of `docs/STATE.md`.
After that: 6A-CP (the magic carpet), 6A-L22 (the Labyrinth), the phase end and Ben's gate.

Things run 67 learned that the next seat needs:
- A level task costs the seat about 113k of context end to end (helper briefs and reports 50k, about forty gate
  and sweep commands 35k, the close 30k). Plan one level task a run, or a feature task and then a level task
  only from a low meter.
- The sweep can run beside the review legs and the fix round if it runs from its own copy of the reviewed commit
  and the fix round is then proven to change tests and comments only. That saved about an hour.
- The sweep script leaves its output folder behind even on success: delete it after each group.
- Run the draw audit for levels 1–5 one test a command (both together took 411 s of the 600 s limit).
- A reviewer started one build in the background by mistake: say "never start a build in the background" in
  every brief.
- Level 21 is the first built level whose darkness switch is not 0; the draw audit's light proofs assume 0 on
  the "no light" levels. Read that before briefing the level-21 task.
- The cloud draws on level 20 are not back to back (crystals draw among them); the plan's notes are corrected.

## Cleaned up
- This run's worktree `exciting-panini-fdb834` (under `Aki/.claude/worktrees/`): 1.3 GB, of which 1.1 GB were
  build folders; its seven commits are on main. Removed with its branch and the `HectorKit` link beside it.
- The scratch folder: the suite copy, the sweep copy, every log and sweep output folder were deleted as each check
  passed; the two review files, the reviewer's patch and two small scripts were deleted at the close. The Mac app
  build's cache was written to the scratch folder and deleted there (no Xcode DerivedData folder was made).
