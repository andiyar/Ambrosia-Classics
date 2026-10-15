# QUESTIONS — Ben's queue for the unattended loop

> The loop (`.looper/config.sh`, chip `docs/NEXT.md`, ledger `docs/LOOP-LOG.md`; rulings D34) cannot ask questions
> while it runs. Anything only Ben can decide lands here; the loop takes the recommendation's default only where the
> item says so, and otherwise carries on with whatever is not blocked. **Ben answers by writing under `Answer:` and
> committing to local `main`** (from any session, phone included); the next run reads this file first, applies the
> answer as an authorization for exactly what it says, records it in DECISIONS, and moves the item to "Answered".
> Nothing here blocks the loop unless the item's `Blocks:` says everything does — then `docs/NEXT.md` carries
> `STATUS: BLOCKED` and the loop stops until he answers.

**How to answer (Ben):** write on the `Answer:` line (a letter is enough, a sentence is better), save on local `main` —
`/Users/andiyar/Developer/Ambrosia-Classics/docs/QUESTIONS.md` — and commit. If the loop stopped with `STATUS: BLOCKED`,
change the first line of `docs/NEXT.md` to `STATUS: CONTINUE`, `rm STOP` if it exists, and start the loop again
(`.looper/config.sh` header has the command).

Item shape (the kit's standing prompt; the loop writes these, numbered in order):

```
### Q<n> — <date> — <one-line question>
Context: <two or three plain-English sentences; paths, SHAs, the gate card or what "pass" looks like>
Options: (a) … (b) … (c) …
Recommendation: <letter> — <why>
Blocks: <what cannot proceed until answered; what can>
Answer:
```

Standing kinds of item: a phase's gate card ("play the staged build at ~/Desktop/Ferazel's Wand.app"; the gate card
itself lives in `Ferazel/WHAT-TO-EXPECT.md`), a visual or feel verdict a MED/LOW reading needs, a new phase plan (for
his later read — execution does not wait, D34), two Opus review legs contradicting each other on a MAJOR point that a
Fable tie-break could not settle, anything that needs an install, a credential, a notarized build, a remote, or his
brother's Windows machine.

## Open

### Q1 — 2026-10-13 — Remove the leftover loop-1 worktree and branch?
Context: Loop run 1 ended its turn while a background implementer was still working. In the looper's headless mode
that exits the session and kills the agent, so run 1 merged nothing. It left uncommitted, superseded partial P4 edits
in `.claude/worktrees/loop-1-20261013-180951` (branch `loop/1-20261013-180951`, at 17f5b04). Run 2 rebuilt P4 + P5
from scratch and merged them, and later runs now dispatch subagents in the foreground. The loop never deletes what it
did not create.
Options: (a) delete it: `git worktree remove --force .claude/worktrees/loop-1-20261013-180951 && git branch -D
loop/1-20261013-180951`; (b) keep it.
Recommendation: a. Nothing in it is needed; everything was rebuilt, reviewed and merged.
Blocks: nothing.
Answer: (a) yes — done 2026-10-15 by Ben's attended session: worktree removed, its partial work was archived as 51c9532 on loop/1-20261013-180951, then that branch was deleted too.

### Q2 — 2026-10-14 — Phase 2 gate: does Ferazel move like Ferazel on levels 1–2?
Context: Phase 2 ("Ferazel moves") is built and its machine gates are green (Ferazel/Core 256/0, census 1,108/0, app
builds, staged build boots and quits clean; Fable phase review passed after fixes — D33 as built, loop run 7). Ben's
gate is pending. Play `~/Desktop/Ferazel's Wand.app` (build d5586fb) with the keypad, beside the Let's Play; the
checklist is `~/Desktop/Ferazel's Wand — WHAT-TO-EXPECT.md` (repo: `Ferazel/WHAT-TO-EXPECT.md`). Level 2 directly:
`open -n ~/Desktop/Ferazel\'s\ Wand.app --args -FerazelLevel 2`. Pass looks like: walking, running, jumping, spinning,
wall clinging, slopes, the camera, water, acid, platforms, pendulums, cannons, passages, death → wipe → restart and the
level 1 → 2 exit all feel like the original; sounds land where and when they should. Known stand-ins are listed at the
card's end (enemies stand still, no pickups, no title/menu, no fade-in after a restart).
Options: (a) pass; (b) pass with notes (write them — each becomes a task); (c) fail (say what feels wrong).
Recommendation: a or b — the machine reads match the binary on every point checked; only your hands can judge feel.
Blocks: nothing (D34: gates queue). The loop plans and builds Phase 3 meanwhile; a fail re-opens Phase 2 as tasks.
Answer: DEFERRED, not a verdict — Ben will play it when he is back from Fiji. Keep this item open; do not treat Phase 2 as passed or failed.

### Q3 — 2026-10-14 — Phase 3 plan (front end + saves): four small choices, for your later read
Context: Loop run 8 wrote and reviewed the Phase 3 plan (`docs/plans/2026-10-14-ferazel-phase3.md`, rulings in
DECISIONS D35): title, menu, options, world map, chapter and stats screens, save points, Continue, death screen,
conversations, pause. Execution starts next run without waiting (D34). Four choices in it are yours; each has a default
the loop builds unless you say otherwise.
Options: (1) saved games written in the data fork (portable; reads original saves too) vs a real resource fork
(original-readable, stripped by zip/Windows) — default data fork; (2) macOS save/open panels instead of 1997 Standard
File dialogs — default yes; (3) in a window the macOS menu bar stays visible during play (full screen hides it, as
design §7.4) — default visible; (4) keep the hidden `-FerazelLevel N` test switch — default keep.
Recommendation: the defaults — each keeps the game's behaviour and only touches the Mac around it.
Blocks: nothing (D34). A different answer becomes a small task in the phase.
Answer: the defaults, all four — (1) data fork; (2) modern macOS save/open panels; (3) menu bar visible in a window, hidden in full screen; (4) keep the -FerazelLevel switch for now ("probably" — Ben may revisit).

## Answered

_(moved here by the run that acted on the answer, with what it did)_
