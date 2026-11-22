# Handoff — Ferazel's Wand, attended run 65 (2026-11-22 11:46 → 13:42; both times from `date`)

**What happened.** The seat's own review of the last wave (plants, rain, level 15, the Goblin Chief, level 18) is
done. It found nothing wrong in the game. The three new engine features planned for this run were **not started**:
the review used up the seat's working room.

| step | result |
|---|---|
| My review of the whole wave's changes | done; no fault in the game |
| Findings | four, all in tests or comments; fixed in one round (b42bb43) |
| Review of the fix round (one Opus helper) | pass |
| Mac-side test suite | 764 tests, 0 failed |
| Windows-kit test suite | 87 tests, 0 failed |
| Clouds, the rotating blade, programmed maces | not started — they head run 66 |

**What a player would notice.** Nothing: no game behaviour changed.

**The four findings.**
- The big standing check cited run 64's rulings under the wrong number 18 times (they were renumbered when another
  project's ruling took the number).
- The same check counted how often the dagger Ferazel holds is drawn under water in a special way, and then never
  looked at the count. It is now pinned per level, and breaking it on purpose makes the test fail.
- A comment still said only the Warrior's death flashes the screen; the Chief's does too. One line number in that
  comment was never a flash at all and was removed.
- One stale note about which levels have rain.

**Left for later** (small; listed under "From run 65" in STATE's open carries): one comment is still incomplete about
the last boss; one note lists too few levels; two limits of the new count.

**Things the next seat should know.**
- Reading a whole wave's changes cost 85k of context (123k → 208k). The next cross-check is at the 6A phase end:
  give it a run of its own, or read by file with long lines cut.
- One merge's gates are twenty commands; a one-line-per-part script kept them to about 20k of context.
- Nothing was launched. No sweep, bot or Windows test run was owed (no game source changed: the fix round's only
  source edit is a comment, same line count).
- No memory note written (D65.5).

**Numbers.** Weekly usage 64% (all models), 82% (Fable); it resets 2026-11-24 02:00 Sydney time. Seat's context:
123k at the start, 208k before the first dispatch, about 240k at the close. Two helpers, both Opus 5.5, both in the
foreground. Worktree `agitated-wu-7b475b` removed at the close (this run's own checkout and build folders; nothing
from another chain).

## The brief for run 66 (rebuilt from nothing)

You are the orchestrator seat for Ferazel's Wand, run 66, in `/Users/andiyar/Developer/Ambrosia-Classics`. Read
`docs/NEXT.md` and run it; work in your own worktree. The state is in `docs/STATE.md` (the Ferazel block); the plan
is `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`.

- **First:** read the weekly usage limit (82% Fable at run 65's close; it resets 2026-11-24 02:00 Sydney time) and
  your own context meter. Read `docs/QUESTIONS.md` "Open" for new answers (Q18: Ben's Phase 5 verdict).
- **Do, in this order, one at a time:** (1) 6A-CL, clouds on a level-20 test level (Core suite 764 → 771);
  (2) 6A-BD, the rotating blade (→ 784) — rule first on what the port draws where the original reads outside its
  light table (D64.6); if only Ben can say, queue it in QUESTIONS and build the rest of the card around it;
  (3) 6A-MP, programmed maces (→ 791). Each: one implementer, two review helpers, a fix round, your own run of
  both suites in parts. The Windows kit stays at 87. Nothing is launched; no sweep or bot is owed.
- **Start state:** main holds levels 1–5, 10, 11, 15 and 18 playable; Core suite 764 and Windows kit 87, 0 failed,
  at b42bb43 (run 65); sweep, bot, the Windows test run and the smoke clean at a66d567 (run 64; game source
  unchanged since). The wave 6A.3 cross-check is done — do not repeat it.
- **Expect to finish one or two of the three**, not all: a task costs the seat about 35–45k of context. Close at
  about 240k with the task in flight finished; the rest head the next run.
- **Must not happen:** two of the three tasks built at once; two suite parts chained in one command; a pinned value
  moving that the card does not name (the audit's new per-level held-item count is one); a launch at night or
  unmuted; more than four heavy workers; a card's numbers trusted over the level data or the original; the seat
  making an edit a helper was refused.
- **Done means:** each finished task merged with its gates, STATE and NEXT updated, a handoff on main, main pushed.
