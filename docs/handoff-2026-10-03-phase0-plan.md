# Handoff — 2026-10-03 — Phase 0 plan (HectorKit lift + Aki census), written and reviewed

**TL;DR.** Phase 0 is planned, not executed. `docs/plans/2026-10-03-phase0-hectorkit-lift.md` (Opus planner,
Fable adversarial review with a full dry run, fix pass) is LOCKED. No code landed in either repo; the EV repo is
untouched. The session stopped at the orchestrator token cap after STEP 1 of Trigger B; STEP 2 is Trigger B2.

| | state |
|---|---|
| HectorKit | door only; plan Tasks 1–6 build it; expected floor 112 tests, 0 skips with data |
| Ambrosia-Classics | design + plan + this handoff; plan Task 7 adds `Aki/Core` + census; Task 8 tags v0.1.0 |
| EV repo | untouched (HEAD e23122f4 pinned in the plan as lift provenance) |

**Findings with evidence (all from tool output; the Python walkers are gone with the scratchpad, the numbers are
in the plan's research notes and will be re-derived by the census tool):**
- Aki 1.1 `.rsrc`: data-fork classic map (no resource fork), header 256/7922960/7922704/2116; types CHNK 1,
  STR 4, PICT 82, pnot 1, icns 1, 8BIM 33, TEXT 1, ANPA 1; **0 snd**.
- 82 PICT = 11 raw single-band 0x009A (7 × 16-bit packType 3, 4 × 32-bit packType 4 — PICT 135 cmpCount 4,
  the rest cmpCount 3) + **71 QuickTime-JPEG, every one banded**: `0011 0C00 A1(kind 498 "8BIM") 0001`
  then N × [`8200` jpeg band, dst from the matrix ty · `0098` 1-bit BitMap 44x69 rowBytes 10 placeholder with
  dstRect = the band] `00FF`. Bands: 45×1, 5×2, 20×4, 1×6 (PICT 130). Band heights sum to the frame height.
- Aki 1.2: 50 PNG (sizes in the plan), 10 AIFF (ima4 44.1 kHz), 5 MP3; afinfo opens all.

**Ruled out / do not re-chase.**
- "Use `compressedQuickTimePayload` + ImageIO as-is" — it throws `unsupportedOpcode(0x00A1)` on every Aki
  QuickTime PICT and returns only the first band. The plan's Task 5 replaces it (walker + composite); the EV
  extractor stays for EV's 5027/5030.
- "The design's 70/12 split" — it is 71/11 (tool output). Accepted as a spec-vs-data delta (plan, Classics D1).
- `swift test` on Swift 6.4 prints one `All tests` block per test bundle and no package total — the zero-skip
  script counts `Test Case` lines (review C1/C2).

**Rulings this session (seed of `docs/DECISIONS.md`, written by plan Task 8):** banded-walk paint ops are
skipped-and-recorded like `PICT.init`; raster ops inside the banded walk are refused; real data only through
`HECTORKIT_DATA_*` env vars with counted skips; HectorKit works on `main` directly, Classics in a worktree with
the `.claude/worktrees/HectorKit` symlink for the `../../../HectorKit` path dependency; every commit carries the
`Co-Authored-By: Claude Fable 5.1` trailer.

**Next session's first instruction:** paste Trigger B2 from `docs/RESUME.md`.

**Resume phrase:** "Ambrosia Classics — execute Phase 0 from the locked plan."
