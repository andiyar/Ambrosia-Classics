# Handoff — Ferazel's Wand, attended run 51 (2026-11-13)

**What happened.** The first Phase 6A build run. Three tasks merged, each with one implementer, two Opus review legs
and a fix round:

| task | what a player would notice | commits |
|---|---|---|
| 6A-BL | nothing — the game now keeps a list of the levels that are built (1–5), instead of "1 to 5", so level 10 can join without admitting 6–9; the test scripts read the same list | 3831cb6, fix 0cbab29 |
| 6A-CF ⚑ | nothing on levels 1–5 — the level-load picture list is now the original's whole list (285 entries), so later levels' cannons, springs, maces, the glider and the bosses' fireballs find their pictures | dc1d65c, fix 798f3b1 |
| 6A-FR | nothing yet — a fast-falling rock landing on Ferazel now hurts and shatters; no rock exists until the Warrior throws them (run 52) | 5c95d75, fix 8919326 |

Also: the ledger's check script, which 6A-CF's change broke, repaired (833506a) and the ledger's generated blocks
regenerated (8c93e9e). Neither had review legs — the wave cross-check in run 52 reads them.

**Numbers (the seat's own runs).** Core suite 620 at the start, 633 at the end, 0 failed, the two opt-in skips by name.
The intermediate 622 and 628 were not run separately (an app restart killed those runs). WinKit 82 / 0 / 2 is the
implementers' number at each task commit.

**Rulings.** `docs/DECISIONS.md` D48. **Open items.** `docs/STATE.md`, "From run 51".

**No WIP.** The worktree `eager-fermat-db9ed9` is merged and clean. Nothing was launched. Q18 and Q19 were unanswered
at the start of the run.

**Next.** Run 52: 6A-W1 and 6A-W2 (the Warrior), then the wave 6A.1 end — `docs/NEXT.md`.
