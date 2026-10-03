# Handoff — 2026-10-03 — Phase 0 planned, reviewed and EXECUTED (HectorKit v0.1.0 + Aki census)

**TL;DR.** One session: the plan was written (Opus), adversarially reviewed with a full dry run (Fable), fixed,
then executed task-by-task (Opus implementers, Opus reviewers, Fable-grade quality leg on the MAJOR task).
Every review came back MERGEABLE. The seat re-ran both gates from the pushed heads.

| | state |
|---|---|
| HectorKit | `v0.1.0` = f578925; gate PASS floor 119, 0 skips; modules HectorResources/Graphics/Audio + HectorTestSupport |
| Ambrosia-Classics | `Aki/Core` (AkiCore, aki-census, 6 tests), `docs/aki/data-census.md`, DECISIONS D1–D2, plan DONE |
| EV repo | untouched (HEAD e23122f pinned as lift provenance in HectorKit D1) |

**Landed (HectorKit, main):** 49a5e75 Resources lift · 5afd9c0 Graphics lift · 4e08ca7 Audio lift · 0fc5386
zero-skip gate + docs · afc00bb gate log override · 2658581/009b9f5/49354ec/9a97406 banded QuickTime ·
1a342ef Aki 82-PICT census test · 46161b9 hardening (7 tests, `unsupportedBand`) · f578925 STATE + tag.
**Landed (Classics, this branch → main):** 299144a plan + docs · 39e3357 Aki/Core · f9fe029 census tool + doc ·
79fe40f doc header rulings · 036dd9e DECISIONS.

**What review caught (all fixed before merge):** the gate script read one bundle's total (Swift 6.4 prints one
'All tests' block per bundle — count `Test Case` lines); a bare `grep skipped` matched a log line; paint ops in
the banded walk had to be skipped-and-recorded (ruling), raster ops refused (ruling); shared `/tmp` gate log
between concurrent runs; three untested-but-correct walker behaviours + silently-ignored band srcRect/mode/
matte/mask → now tests + `unsupportedBand`. The Fable quality leg fuzzed the walker with 3,000 cases plus every
prefix of a real PICT: no traps.

**Facts (tool output):** Aki 1.1 `.rsrc` data-fork map, 124 resources, 82 PICT = 71 banded QuickTime-JPEG
(N bands × [0x8200 · 1-bit placeholder], N ∈ {1,2,4,6} = 45/5/20/1) + 11 raw DirectBits (7 × 16-bit, 4 × 32-bit,
135 cmpCount 4), 0 snd. Aki 1.2: 50 PNG, 10 AIFF, 5 MP3. Every band mode 64; EV 5027 carries a 10-byte mask
(so the field guards live in `decodeQuickTime`, not the walker).

**Do not re-chase:** `compressedQuickTimePayload` as-is (throws on 0x00A1, one band); the 70/12 split; a single
`Executed N tests` total from `swift test`; the three >6.0 similarity rows in data-census.md §3 (version
wording changes / 1.1-only splash, reviewer-rendered).

**Still owed by Ben:** none for Phase 0 (no screens). Read `docs/aki/data-census.md` if curious.

**Next session:** Trigger C in `docs/RESUME.md` (Phase 1: HectorShell + Aki splash/map/prefs). Resume phrase:
"Ambrosia Classics — Phase 1, from the Phase 0 handoff."
