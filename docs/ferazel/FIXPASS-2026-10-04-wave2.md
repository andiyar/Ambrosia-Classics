# Ferazel RE bank — fix pass for the wave-2 reviews (2026-10-04)

Register: code readings only; nothing behaviour-verified (meta file of the RE bank).
Review: `REVIEW-2026-10-04-wave2.md` (legs A–H → markers 2a–2h). Every finding was checked against the
raw listing at the cited address before it was applied. Review fixes are marked in place
`⚑ corrected (review 2x, 2026-10-04) #n` (n = order in the leg: Critical, Important, Minor, Notes);
merged corrections rows `⚑ wave 2 corr (2026-10-04) <SRC> #n` (LT lighting-tables, DE draw-effects,
PA particles, RO rendering-omnipx-titles, CM conversations-mcnv, B3 bosses-2 W-rows, EG2 enemies-ground-2,
SD2 spells-detail-2, PR2 platforms-ropes-radial-2, ES2 enemy-shots-and-damage-2, PB2 pickups-boxes-2).
INDEX.md and coverage.md were not touched (another agent's).

## Leg A (0 C / 2 I / 8 M)
- #1 row 8 label MED (word add `10026be4..10026bec`) → draw-effects §2.1 row 0x80000.
- #2 one `Color2Index` model → particles §4.3 owns it (exact nearest RGB, index LOW, "model; several
  steps may differ"; 4-bit alternatives k200 e0x78 → 26, k202 age 20 → 175 / 188, water0@9e → 49);
  §4.4 cells; lighting-tables §1.2 + NR 1 point to it (also 2c #4).
- #3 kind 200 blue add (`cmplwi r3,0xd6d8` `10030f8c`) → particles §4.4.
- #4 negative L never reaches the 0xc blitter (`100147a4..100147b0`) → draw-effects §1.1 step 4, §2.1.
- #5 `li r15,0xd; stb` (`10027d0c`/`10027d74`) → draw-effects §2.7.
- #6 "delay 2": raw confirms it — callers `li r6,0x2` `100795fc`/`100796f0`, 10-space pass `li r6,0`
  `10079784` → conversations-mcnv §6.2 (label stays HIGH).
- #7 l. 418 → 446 → conversations-mcnv corr #8 row; row applied at triggers-background §3 (CM #8).
- #8 items 17/18 names HIGH ("Buy Escape Ring/Ice Pick" strings) → conversations-mcnv §4.1.
- #9 "tried" lines → draw-effects NR 3/5/6/7, particles NR 2–5, conversations NR 2–4.
- #10 L5/L8 overlap → deduped in the CM #4–#6 / PB2 #P5/#P6 merges below.

## Leg B (0 C / 1 I / 4 M / 2 Notes)
- #1 W3 duplicate → merged into the existing ⚑ wave 2 text of triggers-background §2.2 (no second edit).
- #2 capture gate `+0x130 ≥ 0` (handler l. 15324) → bosses-3 §8.3.
- #3 "tb-2 §0" → §6 → bosses-3 "Proposed additions".
- #4 `.STPlay3DSoundRand` (`bl 0x10047d44` at `10073d3c`; `10047d60..10047d90`) → bosses-3 §8.2.
- #5 entry 240 (0xdeb0, 0x0001, 0xdeb7) → bosses-3 §9.3.
- #6 Note: MED → HIGH (NewGWorld + DrawPicture, exact entries) → bosses-3 §9.3.
- #7 Note: p4-writer list is grep-only → bosses-3 §8.5.

## Leg C (2 C / 2 I / 2 M)
- #1 water loops `ble` (`100204bc`, `10020698`, `10020778`, `10020848`, `10020a08`): 0xff written,
  table 0 → 0x60 black; table 4 unwritten stands → lighting-tables §4 header + paragraph, NR 4 (moot).
  Bank grep for "0xff … white" / "index 0 (white)": no other owned file repeats the water claim (INDEX.md
  hits are the other agent's); rendering NR 3 cross-reference reconciled (2e #6).
- #2 mode 0xa = vertical squash (`100275d4`, `100271f0`, `10027614..10027630`) → lighting-tables §2.1
  table + paragraph, NR 9 closed, proposed `+0xb8` row defers to draw-effects.
- #3 colour 99 spill (`li r8,0x63` ×3; slab 16 = `0x10169d6c`) → lighting-tables §7.5.
- #4 one model → see 2a #2 (lighting-tables §1.2, §4 table cell 9e: 49 4-bit / 84 exact).
- #5 "tried" → lighting-tables NR 6/7/8/10. #6 "only stored mode without a table" struck → §2.1 (with #2).

## Leg D (0 C / 0 I / 9 M)
- #1 activity rect unites the player's hot rect (m. l. 4304–4309) → enemies-flyers §7.5.
- #2 "≥ 120 px" → "≈" → enemies-flyers §1.1 edit and NR. #3 `.DrawBlackLines 1001fb60` → §7.1.
- #4 `> 0` gate (`1003edf4`/`1003ee3c`) → §7.1. #5 Xichra `+0x54` stores [LOW] → §7.5. #6 far-edge arms
  (h. l. 12875, 12904) → §7.4.
- #7 Manhattan / Chebyshev 23, 23, 36 → enemies-water-cave §7.3. #8 0 diffs with full masking → §7.4.
- #9 Walker gravity `li`/`sth` (`100673e4`, `100684e8`, `10069144`) → enemies-ground-2 §1.2 step 5.

## Leg E (0 C / 0 I / 7 M)
- #1 0x100f00a8 / 0x100f40a8 (TOC `0x100a00c0/bc`) → rendering-omnipx-titles §3.2.
- #2 level 22 switches at 6001 → §1.5. #3 back refill + ripple (`10018974`, TOC −0x682c) → §1.3 step 6.
- #4 flag 0x86 trigger (`100187a8..100187c4`) [MED] → §1.3 step 6. #5 drop jitter (`10010bb4`,
  `10010c3c`; heavy 4 px down/1 left) → §3.6. #6 NR 3 cross-reference to lighting-tables §1.4/§4.
- #7 coverage routine map → handed to the INDEX agent.

## Leg F (0 C / 1 I / 5 M)
- #1 same-frame caveat (`10032f68..10032f9c`, direct `+0x80` stores) → spells-detail-2 §4,
  spells-detail §2.4; matching hedge for ES2 (2h #5).
- #2 `.InitSprite` `1003d56c`/`1003d584` → spells-detail-2 §2. #3 rock pile `+0xb0` HIGH → §6.
- #4 NOT applied (see below). #5 S2 duplicate → deduped (text already says Chief 0x18 / Xichra 0x14 /
  −1 per frame / zeroed by `.HitPlayerSprite`; enemy-shots §3.5/NR 3 and spells-detail NR 3 untouched).
- #6 "tried" → spells-detail-2 NR 1–2.

## Leg G (0 C / 1 I / 7 M / 1 Note)
- #1 R = 360 px (`10032274`/`10032278`) → platforms-ropes-radial-2 §8.3.
- #2 first-visit kill / no re-test → §8.3. #3 `.TheSectRect` vs `.SectRectFast` [MED] → §8.3.
- #4 `100149f4` is a copy; split gates (`100147cc..100147e4`) → held-item-melee §4.3.
- #5 spans X−23..X+16 / X+15..X+54 → §12. #6 trunk lifetime 120/121 → pickups-boxes §2.4.9.
- #7 platforms-ropes-radial corrections reordered 9, 10, 11, 12, 13, 14 (numbers kept); player-states W1
  sixth cell removed. #8 save point HIGH arithmetic / MED standing → save-continue §2.1 table.
- #9 Note: `+0xeb` rewrite (`100552a0`/`100552ac` → `100552b4`) → player-states-2 §13.

## Leg H (rulings 1–3; 0 C / 2 I / 4 M)
- Ruling 1: nothing to change. Ruling 2: ES2 §4.2 axis wording → "far edge in y, near edge in x".
- Ruling 3 (205 #8 Platinum Key, #5 Health Potion out; 207 #7 Ice Pick 500, #9 Steel Key out) →
  world-data §5, pickups-boxes §1.7/§1.8/§2.4.3/NR 7, pickups-boxes-2 §8 + P6 row (0-based "line 6/7"
  = #7/#8), held-item-melee §1.9/NR 4, spells-items §1.
- #1 W7 stale → not re-applied (spells-detail NR 3 already closed). #2 W5 → merged into L10's text.
- #3 NOT applied as stated (see below); the ES2 cite was extended with `10009e4c`. #4 omitted callers
  (`.MTKillPxSprites` `100334ec`; `1005567c`, `10057c6c`, `1005d214/350/46c`) → ES2 §4.2/§4.3.
- #5 0x6a9 hedge [MED] → ES2 §4.3 (and handle-pass caveat §4.2). #6 tried + pointer → pickups-boxes-2.

## Corrections rows merged
- LT #1 → sprites §3.2 · #2 → sprites §4 Lighting · #3 = B3 #W2 → sprites §4 `.AnimateCLUT` (one edit)
  · #4 → sprites §4.1 · #5 → world-data 0x2706 · #6 = B3 #W1 → world-data 0x2730 (one edit) · #7 = DE #4
  → physics `+0xb8` (one row) · #8 → enemies-water-cave §0.2 (with DE #10).
- DE #1, #2 → enemies-water-cave §0.3 · #3, #10 → §0.2 · #4 → physics `+0xb8` · #5, #6 → platforms §2.8
  (+ NR 1 closed, PR2 NR 1 closed) · #7 → enemies-ground §2 burn + NR 2 (with PA #7) · #8 → bosses §1 ·
  #9 → bosses-2 NR 1 (+ bosses-3 NR 1) · #11 = PA #1 → geysers §4 items 2 and 5 (same section, two sentences).
- PA #1 → geysers §4 item 5, NR 1 · #2 → enemies-flyers §3.6 · #3 → spells-detail §3.2 note, NR 1 · #4 →
  triggers-background-2 §2.1, NR 5 · #5 → enemies-water-cave §3.4, NR 4 · #6 → save-continue §8.2 · #7 →
  enemies-ground NR 2.
- RO #1, #2, #13 → engine §3 · #3–#6, #12 → world-data §3.2/§3.3/§1/§6 · #7, #8 → save-continue §8.3/§8.4,
  NR 3–5 · #9, #10 → sprites §7 / §3 · #11 → player-states §7 + NR 1, player-states-2 NR 4.
- CM #1–#3 = PB2 #P9 → world-data §5 (one merged text) · #4–#6 = PB2 #P5/#P6 (= L8's in-place strikes) →
  pickups-boxes §1.7/§1.8/§2.4.3/NR 7, held-item-melee §1.9/NR 4, world-data §5 (merged, ruling 3) ·
  #7 → spells-items §1 · #8 → triggers-background §3 (l. 446).
- B3 #W1, #W2 (with LT #6/#3) · #W3 = triggers-background-2 §8.1 = triggers-background §2.2: merged
  into the existing ⚑ wave 2 text (adds the Mlvl census); tb-2 NR 2 already closed · #W4 →
  triggers-background §1 · #W5 → handed over.
- EG2 #1 already in place (marker added to enemies-ground NR 7) · #2 → sprites §6.2 · #3 → platforms §2.5
  · #4 → handed over · #5 → pickups-boxes §2.2 row 1490..1493.
- SD2 #S1 already in place (spells-detail §3.2/§3.7) · #S2 already in place (L8; checked) · #S3 →
  physics `+0x80` · #S4 → enemies-flyers §1.1.
- PR2 #1 already in place (held-item-melee §1.5) · #2 → triggers-background §2.3; enemy-shots NR 6
  already closed by L8 · #3 → physics `+0x80` (with S3).
- ES2 #W1, #W3 → enemies-ground §2.1 / §7 table · #W2 → enemies-flyers §1.3 · #W4 → engine §4 sketch ·
  #W5 merged into held-item-melee §1.5 · #W6 already in place · #W7 stale (not applied).
- PB2 #P1–#P4 already in place · #P5, #P6, #P9 merged with CM (above) · #P7 → physics `+0xa0` · #P8 →
  triggers-background-2 §2 effect damage.

## Proposed field rows (physics §0 / §0.1)
§0: new `+0x00`; `+0x68/+0x6c` (SD2, PR2, ES2); `+0x80` one row (SD2 S3 + PR2 #3 + three proposals +
leg F caveat); `+0xe9` (SD2); `+0x19e` (EG2). §0.1: `+0x89`, `+0x8c/8d/8e` (LT, DE, PA), `+0xa0` (PB2),
`+0xa6` (EG2), `+0xb8/+0xbc` one row (DE semantics: written 0, 1, 5, 8, 9, 0xa, 0xb, 0xc; 3/4/6 draw-time;
0x10..0x15 table indices; 0xa squash; 0xe never written), `+0x14c..+0x174` (EG2 `+0x150`, PB2 `+0x154`,
`+0x160`, `+0x168`), `+0x18c`, `+0x190` (PR2), `+0x1a2`, `+0x1a6/+0x1a8` (PA), `+0x1aa` (ES2),
`+0x1d4..` (SD2); new `+0x3c..+0x44` (ES2, PR2), `+0x1b3` (DE). physics.md 440 lines.

## Handed to the INDEX agent
- EG2 #4: "INDEX.md item 16 | open | closed: floats (§1), Crawler/Roach `+0xa6` (§2), sound helpers HIGH (§3)".
- B3 #W5: "coverage.md §2 rows `.AnimateCLUT` / `.UpdateXichraCannons` | "SC, B2" / "cannon values" | add **B3 §9** / **B3 §8.2**".
- Review 2e #7: "coverage.md routine map lacks the blitters (synthesis)".

## Not applied
- 2f #4 (1008bbc8 / 1008f3e4 belong to `.GoblinChiefRandomCry` / `.DoXichraShot`): the names table lists
  only some starts. Raw: `1008b878 stmw r26` begins a body whose traceback at `1008c0c0` names
  `.HandleChiefSprite`; `1008e4ec stmw r19` begins a body whose traceback at `1008fdd0` names
  `.HandleXichraSprite` (the `.GoblinChiefRandomCry`/`.DoXichraShot` tracebacks sit at `1008b864`/`1008e4dc`,
  before those starts). spells-detail-2 §1's attribution stands.
- 2h #3 (`li r5,0xa` 1004af88 "is a SetRect arg"): raw `1004af88 li r5,0xa` … `1004afac stw r5,0x80(r23)`
  in `.SetupPlayerSprite` — it is the layer store (r5 is reused for SetRect only from `1004afb0 li r5,0x22`).
  Cite kept; `li r6,0xa` `10009e4c` (spawn argument) added beside it.
- Not in this pass's brief (rows of part-1/wave-2 lanes outside the 11 files; reviewed accurate by legs
  D/F/G but not merged here): enemies-flyers W1–W3, enemies-water-cave W2–W3, held-item-melee W1–W2,
  player-states-2 W1–W3, save-continue W1–W3, player-states W1, triggers-background-2 W1–W6 (e.g. physics
  §6 orientation and the `+0x84/+0x86` row still read as before).

## Round 2 — W-rows of the in-place lanes
Marker `⚑ wave 2 corr (2026-10-04) <SRC> W<n>`. Every raw cite re-read in `ghidra/Ferazel_pef.disasm.txt`
(all present and agreeing; `.GetBGTile` arg order and `.SafeReportStr`'s r3 overwrite re-derived).
- EF W1 → physics §0 `+0x84 / +0x86` (row replaced) · W2 → physics §0 `+0x1b2` (outer-skip `10032744` added)
  · W3 → sprites-backgrounds-sounds §6.3 · W4/W5 done by the INDEX agent · W6 already in place (§3.6 carries
  `⚑ wave 2 (2026-10-04)`).
- EW W1 done (INDEX) · W2 → world-data §3.3 getter sentence · W3 → bosses §1.2 and pickups-boxes §1.10 Stats
  (raw `10004da4..10004dc0`). Not touched: enemies-ground l. 126 still says "[MED]" for the same window.
- HM W1 → pickups-boxes NR 8 (already closed by PB2 §6; write-only clause added, consistent with physics
  `+0xa0` P7) · W2 → enemies-ground §2.3 (the only "melee" hit-test note; no "hits once"/"once per" sentence
  exists in enemies-*/bosses*; bosses §4.3's 15 invul frames needed no change).
- P2 W1 → physics §3.3 crunch bullet (struck "bounce if not broken") · W2 → spells-detail §3 crunch line ·
  W3 → sprites-backgrounds-sounds §3.1 step 2 · W4 done (own lane).
- SC W1 → pickups-boxes §2.4.8 ("lit face" struck; "lit" → "used") · W2 → engine §6 · W3 already in place
  (save-continue §9.3 said "shows nothing"; marker added). Bank grep: `.SafeReportStr` appears only there; its
  other five callers (`.EncodeRect`, `.OpenDefaultWorldConv/Map/World`) have no "message shown" sentence.
- P1 W1 → enemy-shots-and-damage-2 §4.2 item 1 (the rule's one statement, cites player-states §9.1 and
  platforms-ropes-radial-2 §8.2 + raw) and spells-detail §2.4 item 1 (cite only). The rule sits in §4.2,
  not §4.3.
- T2 W1 → physics §6 (header [HIGH], orientation paragraph) · W2 → world-data §3.3 overlay row · W3 →
  physics §0 `+0x1c6 / +0x1c8..+0x1ce` · W4 → engine §5 · W5 → player-states §2 rows `_DAT_100a05f8`,
  `_DAT_100a06f0` · W6 → pickups-boxes §2.2 row 1450..1453 (census) + enemy-shots-and-damage §1.4 (pointer).
- Not applied: none. Line counts after: physics 452, pickups-boxes 576, enemies-ground 585, engine 340,
  sprites 262, world-data 458, spells-detail 479, save-continue 517, player-states 464, bosses 372,
  enemy-shots-and-damage 504, enemy-shots-and-damage-2 185 (enemies-flyers 586 / enemies-water-cave 617
  untouched).

## Label counts
`ls docs/ferazel/*.md | grep -v -E 'REVIEW-|FIXPASS-|REPORT-' | xargs grep -o "\[HIGH" | wc -l` (and
`\[MED`, `\[LOW`): **HIGH 1100 · MED 291 · LOW 41** (after round 2; round 1 was HIGH 1096).
