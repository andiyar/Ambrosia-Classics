# Handoff — Ferazel's Wand, run 66 (2026-11-24)

**Seat:** Fable 5.2, started by the Coordinator; foreground only; nothing launched.
**Times:** first started 2026-11-22 and cut off by the weekly usage limit after the clouds were built and
reviewed; resumed 2026-11-24 12:22, closed about 20:30 (Sydney).
**Context:** 124k at the start of the resumed session, 226k at the close. Weekly limit at the close: 29% Fable,
39% all models.

## What is now true
- Three engine features for level 20 "Hangnabit" are on main: **clouds**, **the rotating blade** (with the
  line-crossing test that decides when it hurts), and **maces that travel a programmed path**. None is visible in
  play yet — level 20 itself is still closed.
- Core suite **791** (was 764), 0 failed, the two opt-in skips by name; Windows kit **87**, 0 failed; the Mac app
  and both Windows cross-builds succeed. All run by the seat at each of the three merges; main is at the commit
  that carries this file.
- No picture or state value of any playable level moved.

## Rulings (D67)
1. A blade lit by a play-made light on level 20's "no light" map: the original reads leftover memory, so there
   is nothing to copy. The port will draw the blade plain and unlit. **Not built yet** — today the draw is
   refused, and a refused draw ends the game, so the level-20 task must build this first.
2. The interrupted run's finished test logs were accepted for the clouds after checking the game tree was
   unchanged; the cut-off part and all Windows-side checks were run fresh.
3. The draw audit's refusal count for one file went 14 → 13 because the mace task removed that refusal.

## Waiting on Ben
- Coordinator mailbox **Q1**: what a lit blade on level 20 should show (plain and unlit — the default; a black
  silhouette; or what he remembers). Blocks nothing until level 20 opens; the default stands meanwhile.
- Unchanged: Q18 (the Phase 5 gate), Q21, Q19 and the older ones in `docs/QUESTIONS.md`.

## Brief for run 67 (rebuilt from nothing)
Read `docs/NEXT.md` and run it. In short: open **level 20 "Hangnabit"** (task 6A-L20 in the one plan,
`docs/superpowers/plans/2026-11-04-ferazel-remainder.md`; Core → 794, Windows kit → 88), building ruling D67.1
(the lit blade) inside it before the level joins the playable list; read the mailbox for Ben's answer to Q1
first. It is a level task: besides the two suites it owes the census, a new Windows level picture, and the full
visit sweep and random-play bot on ten levels in both shells, one level group a command. If the context holds,
go on to 6A-PS (the pipes' level spawn, → 795). Then 6A-L21, 6A-CP, 6A-L22 and the phase end.

Things run 66 learned that the next seat needs:
- Every card in this wave has stale file line anchors, and dump line citations were off by one several times:
  tell implementers to verify each.
- The clouds' and the blade's first-frame behaviour differs from the original's first load in two small ways
  (named in their "As executed" notes): check both before pinning level 20's first frame.
- Give level 20 its own audit group; the 10, 11, 15 group has run as long as 449 s of the 600 s limit.
- The Mac app build from a clean copy needs a `HectorKit` link beside the copy.
- Proof B (Wine) has not run on the new blade tests: one of them pins exact sine and cosine values and could
  differ in the last bit under Wine. It is owed at the wave end, by day.

## Cleaned up
- The interrupted run's worktree `elastic-kare-da496c` (845 MB, only ignored build files left; its three commits
  are on main) and its branch; its scratch folder (1.3 GB: a built test copy and logs). It had no Xcode
  DerivedData folder.
- This run's worktree `peaceful-hellman-2312c4` (971 MB, of which 729 MB build folders; everything merged) and
  its scratch files. Every test copy and build folder was deleted after its check.
