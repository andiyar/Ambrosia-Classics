# Handoff — Deimos Rising: Phase 3 wave 3.4 closed (2026-11-20) — the phase is built, checked and staged; it now waits on Ben

Wave 3.4 was the last of Phase 3. Every task of the phase plan is done. Nothing is in flight. The file keeps the
name the Coordinator gave it; the work was done on 2026-11-20.

## Where the phase stands

- **Built and merged to local main, not pushed.** The game plays all twelve sectors in one game, carries lives,
  score and multiplier across each level change, runs the finale after sector 12, and takes two players.
- **Checked.** Every machine check was re-run at today's main and is green (table below). The whole-phase
  cross-check found no code defect.
- **Staged.** One Release app now serves both open gates:

| What | Where |
|---|---|
| the app | `~/Desktop/Deimos Rising.app` (it replaced the Phase 2 build) |
| the card for Ben | `~/Desktop/Deimos Rising — WHAT-TO-EXPECT.md` |
| a second copy of both | `out/Deimos/` in the main checkout (git-ignored) |
| the card's source | `Deimos/WHAT-TO-EXPECT.md` |

- **Boot check passed (added after the close).** Ben's answer came through the Coordinator after this file was
  first written: "of course". At 09:01 on 2026-11-20, with the Mac muted, the staged app opened, ran for eight
  seconds and quit cleanly, with no crash report. Nobody has seen or heard it play.

## What waits on Ben

1. **His first real play** of the staged app.
2. **Part B of the card: "does level 1 play like Deimos?"** — the Phase 2 question, still open.
3. **Part A of the card: "does the campaign play like Deimos?"** — the gate-3 question.
4. Four short questions the card asks by name:
   - should bullet impacts be deep and slow ("flip pitch");
   - can sector 12 end with the Beamer still alive (as the data reads, the fight ends on a timer);
   - should your own weapon overload kill you while nothing else can;
   - are player 2's keys (number pad, End, Forward Delete, Page Down) the ones he remembers.

His notes from either gate become a fix wave before anything else. After gate 3 the next work is Phase 4, the front
end (menu, high scores, level select, settings on disk, the controls window). It has cards in
`docs/superpowers/plans/2026-11-05-deimos-remainder.md` but no plan of its own. Nothing of it is started.

## What this wave did

1. **Re-ran the checks at today's main.** Five days of Ferazel work had landed since wave 3.3; no Deimos file had
   changed, and every count is the same.

| Check | Result |
|---|---|
| Deimos core tests | 372 passed, 0 failed |
| demo-film replays | 4 of 4; all four films end on the original's score |
| the machine sweep (every sector, one whole campaign, a two-player start) | 3 of 3, about 13 minutes |
| app builds | Deimos (Debug and Release), Aki, Bubble Trouble X |
| HectorKit's own tests | 366 passed, plus the 4 known Aki skips |
| layering check, data census | clean, unchanged |

2. **The cross-check of the whole phase** (the one Fable review of the phase). The code fits together as recorded.
   It turned up three facts that matter to what Ben is told, and all three are on the card:
   - **A game started at a later sector has no finale.** The original runs the finale only when all twelve sectors
     were played in one game. My first draft of the card told Ben he could reach the finale with `-sector 12`; a
     reviewer caught it before staging. The card now says to play from sector 1 (the cheats help).
   - **A mistyped launch option quits with no message** in the staged build. The alert that the last handoff
     described exists only in a debug build.
   - **An overload kills during the level-end tally too**, not only in the two seconds after re-entering.
3. **The research bank** took 29 dated Phase 3 notes (17 corrections, 12 additions) across nine files under
   `docs/deimos/`. One implementer wrote them, one reviewer checked them against the sources and the listing, and
   a fix round settled eight points. Two corrections reach back to the wave 3.3 record: the last hold of sector 11
   is 2,250–2,325 game steps, not 2,360; and all five holds are random ranges, not fixed lengths.
4. **The card** was written by the seat, checked line by line against the code by a second reviewer, corrected,
   and staged with the app.

## Not independently confirmed

- The app has only been boot-checked, muted and unwatched, so nothing about sound from the speakers, the
  picture, or the launch options in the real app is confirmed. The launch options were checked by reading and building only.
- The card's corrections after review were made by the seat and not re-reviewed.
- The fix round on the bank notes was checked by its own implementer against the listing, not by a third reader.
- No machine run wins sector 12's last fight by destroying the Beamer.
- The feel of sectors 5 to 12 rests on Ben; no demo film covers them.

## For whoever picks this up

- Records: the DECISIONS entry "As built — Phase 3 (D50), task ST and the phase cross-check"; `docs/STATE.md`, the
  Deimos block.
- Commits on local main: bank notes 4ef49c6, 88d4c54, 6ba71bf; the card 4df24aa; then the records.
- The seat's context at the close: about 215k of the 300k cap (read 187k before the review dispatches).
- The wave's worktree is removed. It held only this wave's own build output (about 1 GB), nothing from another chain.
