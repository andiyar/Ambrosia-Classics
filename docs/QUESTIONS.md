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
Answer:

## Answered

_(moved here by the run that acted on the answer, with what it did)_
