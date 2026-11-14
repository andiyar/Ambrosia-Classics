# Handoff — Ferazel's Wand, attended run 52 (2026-11-14)

**What happened.** The Warrior on level 5 became a real boss. Two tasks merged, each with one implementer, two Opus
review legs and a fix round:

| task | what a player would notice | commits |
|---|---|---|
| 6A-W1 ⚑ ◈ | the Warrior walks, runs, swings and throws; three crates hang over his arena from the first frame | 8f1d61f, fix 0e378b9 |
| 6A-W2 ⚑ ◈ | Ferazel's shots bounce off him; a crate pushed off the ledge onto him hurts; ten crates kill him, he burns away, the gate opens and the boss music ends | bcc67f2, fix 38ce1d9 |

**The one surprise.** The boss contract's scripted fight (stand and jump his shots) cannot win: the crates rest on the
ledges and never fall on him. The implementer stopped; the seat ruled (D49.1); the build found the real win from the
data — climb to the right-hand ledge from the blinking platform and push the crate over as he walks beneath — and
pinned it: HP 0 at game frame 4966, Kill at 5051. Expect the same for the Chief (6A-CH2).

**Numbers (the seat's own runs).** Core suite 633 at the start, 642 after W1, 650 after W2; 0 failed; the two opt-in
skips by name. Census 1,108 / 0. WinKit and the Mac SDL build: see `docs/STATE.md`. Only level 5's two frame pins
moved (W1: 55 → 58 sprites at frames 30 and 120, the crates).

**Wave 6A.1 end.** Census done. The Fable cross-check of the whole wave was done by the seat (the Sources and tools
diff read in full): pass, no fixes. **Owed (night rule; the wave end came at 20:52): Proof B (expect 647 / 0 / 3 / 0
of 650) and the Mac SDL smoke** — the first act of the next run that starts by day.

**Continued under Ben's raised cap (500k), overnight.** Three more tasks merged, the first of wave 6A.2, none
visible to a player yet (no level past 5 opens until levels 10 and 11 do):

| task | what it is | commits |
|---|---|---|
| 6A-FX | a test-only fixture that opens a later level with its unbuilt objects left out; proved on level 21 | 520590c, fix 213aa19 |
| 6A-S8 ⚑ | the horizon strip: the distant skyline band behind six later levels, drawn behind the scenery | 06f7250, fix cdaf65d |
| 6A-WD ◈ | wind cells on levels 10 and 20; the earlier strip picture did not move | e7457f7, fix 4134bbc |

Core suite 652, 663, 672 at the three merges (the seat's runs), 0 failed. The fixture's interface that eleven later
tasks code against is written out in the plan's "As executed — 6A-FX". Proof B is still owed and now expects
669 / 0 / 3 / 0 of 672.

**Rulings.** `docs/DECISIONS.md` D49. **Open items.** `docs/STATE.md`, "From run 52".

**No WIP.** The worktree `gallant-brahmagupta-56ed81` is merged and clean. Nothing was launched. Q18 and Q19 were
unanswered at the start of the run. Local main also carries the Deimos session's commits; this run pushed main.

**Next.** Run 53: the owed launch checks by day, then 6A-RC, 6A-TR, 6A-RP ⚑ — `docs/NEXT.md`.
