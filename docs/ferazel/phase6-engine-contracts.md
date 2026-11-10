# Ferazel's Wand 1.0.3 — Phase 6 engine-feature contracts (Task ENG)

Research only, 2026-11-11, base 1cfc137. Every line number is the **committed** dump
`ghidra/ferazel/Ferazel_pef.decompiled.c` (88,106 lines), cited "M l. N"; raw addresses from `Ferazel_pef.disasm.txt`
are cited "raw XXXXXXXX". Spans come from the dump's `// ==== name @ addr ====` headers (next header − 1). Level facts
come from Python over `Resources/Ferazel/Ferazel's Wand World Data.rsrc` (`Mlvl` bodies; header offsets per
world-data-format §3.2; records at hdr + 4 + 16·i; the overlay map is the fourth main-grid map). Constants were read
with `docs/ferazel/tools/const.py`. Where the dump, the bank, the plan, the spec or a port comment disagree, the dump
wins and the difference is listed in §6.

How to read a section: **what it is** (one paragraph, plain), **switch** (the header field or type, and its value on
every level that has it), **spans** (dump lines; size = lines of original code still to transcribe), **today** (what
the port has, file:line), **contract** (the original's behaviour in dump order — the transcription target),
**seam** (Core / Render / shared seam type / either shell), **first level** and **golden plan** (level, frame,
shells — values are measured by the build, never written here), **tests** (names + what each pins), **phase**.
"R(n)" = one `.FastRand(n)` draw (0…n−1) of the one stream. H / V = the scroll (`PTR_DAT_1009fe78`: V at +0, H at +2).
Each 6A section ends with **asserts the build task adds**: behaviours of the dump routine that no named test pins yet
(the review's mutation tables), one line each, value + dump line; the build adds each as an assert inside the named
tests (not as new tests).

**Review fix round (2026-11-11, two Opus legs).** 44 findings, each re-read against the dump: 43 applied, one not (an
`INDEX.md` row this fix round may not add); the dump contradicted none, and one cited line was wrong (E20). §8 says
where each went. The seat's rulings below are written into every section.

## Rulings (the seat, 2026-11-11)

- **R1 — ownership.** This document's feature tasks own every type that has a feature section here: the trees and their
  branches (6A-TR), the clouds (6A-CL), the rotating cannons (6A-RC), the blade (6A-BD), the mace paths (6A-MP), the
  carpet (6A-CP), the rocks' player arm (6A-FR). The later-levels ledger's type-split tasks keep only the remaining
  types: 6A-BG1c (plants), 6A-BX1a (Box scenery), 6A-BX1b (faces and talkers); LL's 6A-BG1a, 6A-BG1b and 6A-BX1c
  dissolve. The full owner table for levels 10–22 is §9.1.
- **R2 — the fireball cache.** 6A-FB is absorbed by the ledger's 6A-CF (the whole cache registration list keyed by
  record, 285 records): one task. Picture 0x46a has three cache records and two cuts, so the test is "0x46b / 0x46c draw
  the 64×64 cut and 0x46a the 48×48 cut, by record" (§2.14).
- **R3 — proof before the level opens.** A feature is built before its first level's "enterable" task, while that level
  still cannot open in the game. So each feature task proves itself on its first level through a **test-only level
  fixture**: the real level data with the records of still-unbuilt types left out (the counts per level are §7.2), and
  the level-open refusal for that feature removed by the task itself. On that fixture it pins a **feature golden**
  (`…FeatureGolden`, both shells where the section says so). The level's "enterable" task later pins the real
  first-frame golden with every record set up — a new golden there, not a moved one; the feature golden is then
  deleted or kept as each section says. **No existing golden of levels 1–5 moves in any feature task**; each section
  says why.
- **R4.** The death, thunder and ripple frames (and every other golden frame number) are measured by the build task,
  never invented here.

---

## 0. At a glance

| § | feature | phase | first level (all levels) | switch | lines to transcribe | tests | seam | Windows |
|---|---|---|---|---|---:|---:|---|---|
| 2.1 | horizon strip (draw mode 8) | 6A | 10 (30, 40, 45, 62, 67) | hdr `0x2716/18/1a` | ~470 | 12 | Core + Render + **shared seam type** (`FaceSetKind` case; no shell source change) | feature golden both shells; GW1–GW4 + G5 |
| 2.2 | wind cells | 6A | 10 (20) | overlay o1 0…15 | 85 | 9 | Core only | GW1–GW4 + G5 |
| 2.3 | rotating cannon arm (p1 101…106) + shot steering | 6A | 10 (15, 20, 40, 50, 51, 52, 62; Xichra 67) | Background 0x442…0x44a p1 | 110 | 10 | Core only | GW1–GW4 + G5 |
| 2.4 | trees and their branches | 6A | 10 (11, 15) | Background 0xc08…0xc0f | 250 | 10 | Core only | GW1–GW4 + G5 |
| 2.5 | parallax ripple (the river) | 6A | 11 (18) | hdr `0x26ca` | ~190 | 8 | Render only | feature golden both shells; GW1–GW4 + G5 |
| 2.6 | tinted submerged tiles | 6A (inside 6A-RP) | 11 | hdr `0x26c6` | **0 (built)** | 2 | none | through §2.5's golden |
| 2.7 | OmniPx rain (mode 1) + thunder; side push | 6A | 15 | hdr `0x26c7` = 1; `0x272c` | ~110 (push built) | 13 | Core + Render + **shared** (a `SoundCue` loop field + `Shared/FerazelAudio.swift`) | feature goldens both shells; the loop on both mixers |
| 2.8 | clouds | 6A | 20 | Background 0xb4a…0xb4d | 80 | 7 | Core only | GW1–GW4 + G5 |
| 2.9 | rotating blade + segment test | 6A | 20 (22, 30, 62) | Background 0xbf4 | 170 | 13 | Core (+ Render audit rows) | GW1–GW4 + G5 |
| 2.10 | programmed-path maces (modes 1, 2) | 6A | 20 (22, 30, 31, 40, 62) | Background 0x5c8…0x5d1 p1 1/2 | 30 | 7 | Core only | GW1–GW4 + G5 |
| 2.11 | magic carpet 0x438 / 0x439 | 6A | 22 | Box 0x438 | ~120 (the player's half built) | 12 | Core only | GW1–GW4 + G5 |
| 2.12 | falling rocks' player arm | 6A | 5 (the Warrior's crates) | Box 0x433 / 0x434 at run time | 20 | 5 | Core only | GW1–GW4 + G5 |
| 2.13 | the player's boss-stagger arm | 6A (inside 6A-CH1) | 18 (67) | `_DAT_100a0570 > 0` | 42 | 3, inside CH1's 10 | Core only | GW1–GW4 + G5 |
| 2.14 | fireball cache by record (**inside 6A-CF**, R2) | 6A | 25 (55, 67) | EnemyShot 0x46a…0x46c | 40 | 3, inside CF's 6 | Core | GW1–GW4 + G5 |
| 3.1 | programmed-path cannons (p1 < 0) | 6B | 40 (62) | Background 0x442… p1 < 0 | 45 | 4 | Core only | — |
| 3.2 | level-wide liquid flag + ice | 6B | 30 (31) | hdr `0x26cd`, `0x2710` 220 | 0–20 (prove) | 3 | none | — |
| 3.3 | countdown digits | 6B | 40 | Box 2907 (0xb5b) | 140 | 6 | Core (+ faces) | — |
| 3.4 | spiked balls 0x5c3 / 0x5c4 | 6B | 45 (62; 0x5c4 from Xichra's rain on 67) | Box 0x5c3 | skimmed | ~5 | Core only | — |
| 3.5 | snowball 0xbfe | 6B | 31 | Box 0xbfe | skimmed | ~4 | Core only | — |
| 3.6 | CLUT animation | 6B | 50 (51, 67) | hdr `0x2730…0x2736` | 178 | ~8 | Core + Render + **shared** (a DrawOp case, or `ScreenGammaOp.clut` executed in level frames) | palette path, both shells |
| 3.7 | auto-scroll + the fire-wall marker sprites | 6B | 51 x (52 y) | hdr `0x2726…0x272a` | ~120 + arms | ~8 | Core | — |
| 3.8 | fire backdrop + flame buffer (+ placed fire 0x4b8) | 6B | 52 mode 1 (55 mode 2; fire 0x4b8 on 40) | hdr `0x2722`; Background 0x4b8 | ~1,000 | ~12 | Render + Core (`.MyRandom` stream, sparks) | reference frame only |
| 4.1 | OmniPx interlace (mode 6) | 6C | 70 | hdr `0x26c7` = 6 | 95 + 10 | 4 | Render (+ Core counter) | reference frame only |
| 4.2 | the End key in the guardians' Handle | 6C | 55 | key 0x77 | 3 | 1 | Core + both shells' key maps | yes (key map) |
| 4.3 | the guardians-alive global | 6C | 55 | `*_DAT_1009fecc` | 6 | 2 | Core only | — |
| 4.4 | conversations started inside a sprite Handle | 6C | 67 | Xichra's `.Conversation` calls | flow only | 3 | Core (`LevelRun` / flow) | — |
| 4.5 | victory + stitch + credits | 6C | after 67 | `*_DAT_1009ffc4` | 322 | ~6 | Core flow + Render (pictures) | reference frames |
| 5 | unreachable as shipped: rope bridge 1466, table 0xb71, water kinds 206–209, `.RipplePxBackOffsets`, 0x73f / 0x740 | — | none | — | 0 | 1 each (data pin) | none | — |

Sizes are dump lines still to transcribe, read from the spans below; test counts are sized like the neighbouring
movers and renderer tests (4–13); each 6A count includes the section's feature golden (R3) and counts a
`DrawModeAuditTests` row as a list item, not a new test method (§7.1's ladder counts methods). Every 6A feature is
Core-only or Render-only except the strip and the rain, which each add one shared seam case (§2.1, §2.7) and so change
both shells in lockstep (they compile against the same `FerazelCore` seam; the Windows shell draws through the same
`FerazelRender`). "GW1–GW4 + G5" in the Windows column means no shell source changes but the Windows gates still run
(lockstep (b)); only the rain changes shell source (`Shared/FerazelAudio.swift` and the Windows audio test).

---

## 1. Row coverage of `gap-ledger/routines-classified.tsv`

The card asks for "the 27 later-level routines and the Phase 6 not-built non-boss rows". The ledger never uses the
words "later-level" (the seat's grep found 0 lines, correctly); the 27 are the ledger's own count in
`port-gap-ledger.md` §3 ("27 later-level features") and are its **not built** rows whose reason column is one of nine
phrases. **Measured: 27 + 4 = 31 rows**, each owned by exactly one section here:

| reason phrase in the tsv (column 4) | n | rows (address name) | owner |
|---|---:|---|---|
| `fire parallax (hdr 0x2722) + flame buffer` | 10 | 10000924 `.LoadCoolingMap`, 10018dd4 `.DoubleBlitPPCParallaxOneLayerFire`, 10085300 `.FlameCreate`, 100854e4 `.FlameAddSpark`, 10085560 `.FlameAddLine`, 10085698 `.FlameUpdate`, 100857e0 `.FlameUp`, 10085df4 `.MyNewPixMap`, 10085f44 `.MyRandomizePixmap`, 100860e0 `.MyRandom` | §3.8 |
| `OmniPx (hdr 0x26c7: rain level 15; modes 2/5/6 levels 5, 25, 70)` | 7 | 100109c0 `.GenerateRain` | §2.7 |
| | | 1001a184 `.InterlaceBlit128` | §4.1 |
| | | 10019ac4 `.TurnOnOmniPx`, 10019bac `.TurnOffOmniPx`, 10019d78 `.SetupOmniPx`, 1001a434 `.UpdateOmniPx`, 1001a86c `.KillOmniPx` — **built by OX (run 47)** for modes 2/4/5 and set up for mode 1 (`OmniPx.swift`); stale "not built"; the mode-1 and mode-6 remainders are §2.7 / §4.1 | §2.7 (mode 1 parts) |
| `parallax ripple (hdr 0x26ca)` | 1 | 1001171c `.RipplePxBackOffsets` — **unreachable on shipped data** (its only call is gated on hdr `0x271e`, 0 on all 24 levels); the ripple of 11/18 is `.PaintFrameWrap` inline code | §5 (row), §2.5 (the feature) |
| `mode 8: only writer = parallax strip sprites (hdr 0x2716)` | 2 | 100269c4 `.BlitEncFaceBehindTilesClip`, 10026d38 `.BlitEncFaceBehindTilesNoClip` | §2.1 |
| `wind cells (overlay wind)` | 1 | 100404a4 `.LookupModedImpulse` — **built by E1b** (`WaterEffects.lookupModedImpulse`, wind dust); stale; the unbuilt part is its other caller, `.StandardSpriteHandles`' wind branch | §2.2 |
| `cannon p1≠0 / mace modes 1-2 paths` | 2 | 10044c58 `.SetupProgrammedPath`, 10044fe8 `.HandleProgrammedPath` — **built by BA/GF** (`ProgrammedPath.swift`); stale; the unbuilt parts are the mace and cannon call sites | §2.10 (maces), §3.1 (cannons) — rows owned by §2.10 |
| `only caller: HitPlayerSprite arm for rotating blade 0xbf4` | 2 | 10045340 `.SectLineSegs`, 10045468 `.SectRectLineSeg` | §2.9 |
| `countdown digits faces (2907 timer)` | 1 | 10060d04 `.UpdateDigits` | §3.3 |
| `trees 0xc08..0xc0f (HandleBackgroundSprite)` | 1 | 10072f50 `.SetupTree` | §2.4 |
| **later-level subtotal** | **27** | | |
| `phase 6 (victory sequence)` | 3 | 1000ac3c `.Victory`, 1000a6ac `.CopyVictoryStitch`, 1000aa68 `.CreditScreen` | §4.5 |
| `phase 6 (rope bridge 1466)` | 1 | 1006b3d8 `.GetRopeBridgeHeight` — 1466 is placed on no level and spawned by nothing | §5 |
| **total** | **31** | | |

Not in the count but named for completeness (the **partial** rows whose missing arms are later-level, each arm owned
once): `.SetupLevelSprites` (auto-scroll markers → §3.7), `.DoubleBlitUniversal` (fire variant → §3.8),
`.HitPlayerSprite` (rocks → §2.12, blade → §2.9, spiked balls → §3.4), `.HandleBoxSprite` / `.SetupBoxSprite`
(carpet → §2.11, spiked balls → §3.4, snowball → §3.5, table → §5), `.HitBoxSprite` (carpet → §2.11),
`.SetupBackgroundSprite` / `.HandleBackgroundSprite` (rotating cannons → §2.3, path cannons → §3.1, trees → §2.4,
clouds → §2.8, blade → §2.9, fire 0x4b8 → §3.8, fire walls 0x4bb…0x4bd → §3.7, 0x73f / 0x740 → §5; dart traps
0x76c…0x76f are **built** (ES) — stale), `.HitBackgroundSprite` (cannon steering → §2.3; fire → §3.8),
`.SetupEffectSprite` / `.HandleEffectSprite` (countdown digits → §3.3; effect ids 1202…1205, 1251, 1830, −1 are
the ledger's LL owners, not engine features), `.PlayerConstraints` (**partial**: the arena lock is built at LV5, BOS
§7; its auto-scroll death arm, raw `1004cd90..1004ce3c`, is §3.7's). `.FlipHRect` (M l. 39474–39491, a "partial" row)
is not an engine feature on its own but the trees call it (§2.4 step 3): 6A-TR builds the one shared helper and LL's
6A-BX1a reuses it. `.HitPlayerSprite` also has a 0x73f / 0x740 arm (M l. 49753–49760: `.HurtPlayer` 0x38,
`+0x116 = 0x28`) — unplaced, with §5's row.

Two more Phase 6 not-built rows carry neither "(boss)" nor a non-boss reason: `.ShootSpines` ("phase 6 (Dillo boss)")
and `.sinDegrees` ("phase 6 (Xichra)"). They are BOS's (cited there 3 and 4 times), so the 27 + 4 = 31 here is the whole
non-boss set.

The Phase 6 boss pieces BOS left to this document (BOS §2.7, §3.7, §5.6, §6.6, §6.7, §9.2), each with one owner:
the stagger arm → §2.13; the rocks' player arm → §2.12; the fireball cache → §2.14; the End key → §4.2; the
guardians-alive global → §4.3; a Core-writable `0x2730` → §3.6; Handle-site conversations → §4.4; the rotating
cannon arm → §2.3 (**6A, not 6C-XL** — §6 E1); the 0x5c4 ball → §3.4; victory → §4.5.

---

## 2. Phase 6A (levels 10–22) — full depth

### 2.1 The horizon strip — draw mode 8 (6A-S8 ⚑)

**What it is.** On six levels a wide picture (a mountain range, a skyline) sits between the scrolling sky backdrop and
the tiles, moving at half the camera's speed. It is not a backdrop layer: it is a row of ordinary sprites at layer
−500, drawn with mode 8, which paints only where nothing opaque has been drawn yet and then masks itself, so the sky
compositor later leaves it alone.

**Switch.** hdr `0x2716` (Backgrounds PICT), `0x2718` (x factor /256), `0x271a` (base y); the y factor is the PxBack
`yb` (hdr `0xb26c`). Measured: L10 PICT 265 fx 128 y 222 yb 56 (W 360 → N 8 → **9 sprites**); L30 275 / 128 / 227 / 136
(12); L40 315 / 128 / 48 / 22 (12); L45 315 / 128 / 48 / 10 (3); L62 345 / 128 / 116 / 43 (9, hdr `0x26cc` = 1: the
face converts under the level+base CLUT); L67 385 / 128 / 16 / 256 (2). All six PICTs are in the Backgrounds file.
`.BuildSineTable` clamps hdr `0x271a` to ≤ 100 (raw `100201cc lhau 0x271a`, `100201d0 cmpwi 0x64`, `100201dc sth`), but
it runs once, from `.InitAppGlobals` (M l. 550), before any level is loaded — it never touches a loaded level's y
(222 / 227 / 116 on L10 / L30 / L62 stay as read; the build confirms the header handle is a fresh one per level). Do
not "fix" y to 100.

**Spans.** `.SetupLevel` M l. 2252–2268 (fast path: `.MTKillPxSprites`, then `.MTAddPxSprite` with the Backgrounds
file open) and M l. 2350–2356 (long path); `.MTKillPxSprites` 30820–30852; `.MTAddPxSprite` 30853–30927;
`.SetupPxSprite` 30798–30819; `.HandlePxSprite` 30771–30797; `.MTHandlePxSprites` 30928–30948 (called from
`.FindUpperLeftCorner` M l. 6235); `.KillAllSprites` M l. 30958; `.BlitEncFaceBehindTilesClip` 22251–22449;
`.BlitEncFaceBehindTilesNoClip` 22450–22548; `.BlitEncFaceX` dispatch raw `1002cf5c..1002cfa4` (no flip test) and the
mask pass raw `1002d18c..1002d2c0` (draw-effects §1.2).

**Today.** `Sprites/PxSprites.swift` models `.MTAddPxSprite`'s copies and `.HandlePxSprite`'s position (built R4,
unused: nothing creates the sprites); `LevelRun.refuseUndrawnHeader` refuses the level (`LevelRun.swift:584`,
`LevelOpenRefusal.horizonStrip`); `SpriteBlitter` refuses mode 8 through the generic `Refusal.mode(word)` in
`blitEncFaceX` (the `guard mode == 6` branch, :301; :43 is the doc comment that names it); `DrawModeAuditTests` row
`LevelOpenRefusal.horizonStrip` (`.headerZero`).

**Contract.**
1. Creation (`.SetupLevel`, before `.SetupLevelSprites` M l. 2526 and after `.KillAllSprites` M l. 2246): the strip
   sprites are the **first nine (L10) sprite allocations of the level** — `.MTNewSprite` sprite records (slots), the
   first after `.KillAllSprites`; whether that makes them slots 0…8 depends on the allocator's free-list model, so the
   ids are measured by the build. Every later **sprite-slot** id on levels 10, 30, 40, 45, 62, 67 is shifted by the
   strip's count; the `Mlvl` **placement indices** (§2.3's "records 89, 108, 200, 250", LL's "rec 135") do **not**
   move. `.MTAddPxSprite` (M l. 30853–30925), all of it skipped when the face count `*_DAT_100a01b8` ≥ 31 (M l. 30884):
   N = ⌊((fx·W·32) >> 8) / 768⌋ + 1 (C division); one face `.Load1EncFaceFromPICT(PICT)` (under `*_DAT_1009ff8c` when
   hdr `0x26cc` ≠ 0, M l. 30885–30886, restored at M l. 30919); fail → `.ReportError` and nothing else (M l.
   30889–30890 — the restore of 30919 is in the success branch, so a failed load leaves the CLUT pointer swapped, as
   written); then k = 0, 1, … while k ≤ min(N, 31 − count) (the cap re-evaluated each pass, M l. 30897–30902):
   `.MTNewSprite(0, 0, 0, layer −500, record −1, .SetupPxSprite)` stored at slot-table entry **count + k** with count
   already advanced by the earlier passes (M l. 30904: the pointers land in every other entry); on success `+0xc0` =
   the face, `+0x14c` = 768·k, `+0x150` = y, `+0x154` = fx, `+0x158` = yb; count + 1 each pass (also on a failed spawn,
   M l. 30917); the face pointer is appended to the face table (`_DAT_100a01d0`, M l. 30920). The stride changes nothing
   on shipped data (≤ 12 sprites; `.MTKillPxSprites` and the Handle walk all 32 entries); the build checks
   `PxSprites.init` against it.
2. `.SetupPxSprite`: `.InitSprite`; empty rect; `+0x48 = 0x1ff`; `+0xea = 1`; type 1; `+0x88 = 0`; `+0x5c = 0`;
   `+0x1f8 = 0`; Handle `.HandlePxSprite`; `+0xb8 = 0x80000`.
3. `.HandlePxSprite` runs **twice a frame**: once in the sprite pass (it is in the sprite list) and once from
   `.MTHandlePxSprites` at the end of `.FindUpperLeftCorner` (M l. 6235), with the new scroll — the second wins for
   the draw. `+0xc = i16(x0 − (H·fx >> 8) + H)`; `+0xa = i16(y0 − (V·yb >> 8) + V + 232)` (the decompile's first
   `+0xc` store is overwritten, M l. 30781–30784).
4. Draw (`.WrapDrawSprites`, layer −500 → before every other sprite): mode 8 ignores the mirror flag. Per literal run
   of the encoded face, per 4-byte group: **if the mask word ≠ 0, dest word += src word & mask word** (a 32-bit
   big-endian add, carries crossing bytes); a 2-byte tail the same on 16 bits; a last byte: mask ≠ 0 → dest = src
   (M l. 22489–22511). Tokens 0 end / 1 next row / 2 literal / 3 skip / > 3 `DebugStr`. Then the ordinary mask pass
   writes 0 under the silhouette (mode < 0x14, ≠ 0xd), so the back-row compositor (rendering-omnipx-titles §1.2: M =
   0xFF → backdrop) keeps the strip's pixels. The clipped variant's walk (M l. 22251–22449) is garbled in the
   decompile (`in_r11` / `in_r12`); re-read in the raw (`100269c4..10026d04`, review leg 2): **token 1** (`10026ca0`):
   rows before the top clip skip the source by the row token's payload (`10026ca8 add r4,r4,r7`) while the dest and
   mask row pointers still advance (they start at the unclipped origin, `10026a7c subf r9,r10,r9`, `10026a88 subf
   r0,r5,r0`); the walk stops when the row count passes the bottom (`10026cb0`). **Token 2** (`10026b10`): the column
   counter r30 against the left clip r10 and the right limit r27, unsigned (`cmplw`): a run wholly left of the clip is
   skipped (dest, mask, source + n, the source padded by (4 − n & 3) & 3); a run crossing it advances all three by
   (clip − column) and **groups from the clip column**; a run ending past the right limit draws only up to it and
   skips the overhang after the 2- and 1-byte tails (`10026c64..10026c74`); the source pad always uses the full run
   length (`10026c64 rlwinm. r5,r7`). Groups: a 32-bit `lwz/and/add/stw` when the mask word ≠ 0; the 2-byte tail
   `lhz/and/add/sth` (wraps at 16 bits); the last byte copied when the mask byte ≠ 0. **Token 3** (`10026c90`): skip,
   no clip test. r11 / r12 / r30 are set only by token 1 (the decompile's `in_r11` / `in_r12`): every face starts with a
   row token. The unclipped variant groups from the run start.
5. The add equals a copy only where the frame byte is 0 under a 0xFF mask byte. The port must implement the add as
   written (with carries) rather than assume it; one test pins that on the level-10 fixture's first frame every frame
   byte under a 0xFF mask byte is 0 before the sprite pass (draw-effects §2.5's MED inference, made checkable).

**Seam.** Core: the strip sprites become real `SpriteWorld` records created in `LevelRun.setupLevel` at the
`.SetupLevel` position, their Handle in the sprite pass, a second `.HandlePxSprite` pass after the camera; the level
refusal removed. Render: `SpriteBlitter` mode 8 (both variants), the audit row moved to drawn. **Shared seam:** the
strip's face is a Backgrounds-file PICT and the Sprites file also holds a PICT 265 (measured), so `FaceRef(pict: 265,
set: .encoded)` would name the wrong picture — add one `FaceSetKind` case (e.g. `.backgroundsSingle`; Invariant 9:
cases may be added). Both shells compile against it; no shell source switches on `FaceSetKind` (grep of
`Ferazel/Shared`, `Ferazel/Windows`, `Ferazel/App`: none), so the change is Core + Render only and the shells need the
gates (GW1–GW4 + G5), not code. The loaders are Render's.

**First level / golden (R3).** First of the level-10 features (order §7.1): it removes the `horizonStrip` level-open
refusal itself, so the other level-10 features' fixtures open after it, and it shifts the sprite-slot ids they
measure. Fixture: level 10 with the 31 records of still-unbuilt types left out (§7.2: trees 13, rotating cannons 4,
Box scenery 14). `testLevel10StripFeatureGolden`: the first frame with a strip pixel on screen (on-screen top of the
strip = y0 + 232 − (V·yb >> 8) = 454 − (V·56 >> 8) in port rows against a view that ends at row 392, and the camera
starts at the player − 208, `Camera.swift:19–20` — so frame 1 may not show it; the build measures the frame, R4), Mac
(`FrameGoldenTests` style) and Windows (`WinReferenceFramesTests` + the smoke script copy). Kept at level 10's
enterable task unless its frame is frame 1 (then the real first-frame golden supersedes it and it is deleted).
**Levels 1–5:** hdr `0x2716` = 0 on all five, so no strip sprite is created, the new `FaceSetKind` case is never
named and mode 8 is never reached — no golden moves.

**Tests (12).** `testStripSpritesAreTheFirstAllocations` (L10: the first nine allocations after `.KillAllSprites`,
layer −500, ids as measured); `testStripCopiesPerLevel` (9, 12, 12, 3, 9, 2); `testHandlePxSpriteRunsTwice`
(positions after the sprite pass and after the camera); `testStripFaceUsesBackgroundsFile` (265 ≠ Sprites 265);
`testStripFaceClutOnLevel62` (`0x26cc`); `testModeEightWordAddCarries`; `testModeEightTailBytes`;
`testModeEightClipped` (a run crossing the left clip groups from the clip column; the right overhang skipped after the
tails; the source pad of the full run); `testModeEightMaskPassZeroes`; `testFrameIsZeroUnderOpenMaskOnLevel10` (on
the fixture); `DrawModeAuditTests` row moved (`horizonStrip` gone, mode 8 drawn); `testLevel10StripFeatureGolden`
(+ the Windows reference).

**Asserts the build task adds** (review leg 2's mutation table, 7):
- face-load failure → `.ReportError(…, 0)`, no sprite, the CLUT pointer left swapped (M l. 30889–30891, 30919).
- the whole add skipped at face count ≥ 31 (M l. 30884); count + 1 on a failed spawn (M l. 30917); the cap
  min(N, 31 − count) re-read each pass (M l. 30897–30902).
- slot-table entry = count + k, count already advanced (M l. 30904).
- mode 8 ignores the mirror flag (raw `1002cf5c..1002cfa4`).
- a token > 3 → `DebugStr` (M l. 22357 clipped, 22544 unclipped).
- `.SetupPxSprite`'s stores, each one: empty rect, `+0x48 = 0x1ff`, `+0xea = 1`, type 1, `+0x88 = 0`, `+0x5c = 0`,
  `+0x1f8 = 0`, Handle, `+0xb8 = 0x80000` (M l. 30806–30815).
- `+0x48 = 0x1ff` means no write-back to any placement (M l. 30808).

### 2.2 Wind cells (6A-WD)

**What it is.** Overlay cells 0…15 are wind: anything with a wind scale (the player, player and enemy shots, crates)
is pushed along a direction (o1 · 10° anticlockwise from right) with a strength o2, ramping up over 33 frames and
ramping off when it leaves.

**Switch.** Overlay o1 ∈ 0…15 with o2 > 0. Measured (cells with 0 ≤ o1 ≤ 15): **L10 103** (o1 9 strength 20 ×28, 9/50
×71, 10/50 ×4); **L20 2,899** (o1 1–7, 9, 12; strengths 20…70); no other level. Dust-only cells (o1 16…35, which
make wind dust but never push): L20 1,256, **L52 84** (o1 27 / 90).

**Spans.** `.StandardSpriteHandles` M l. 32489–32574 (raw `100369b0..10036c5c`); `.LookupModedImpulse` 37020–37412
(built); `.GetFGOverlay1Tile` 34974–34996, `2Tile` 34997–35019 (built). Writers of the scale `+0x90`: player Setup
0x100 (M l. 42852), the player's liquids/state (M l. 44636–44652, 46439), player shots (50301), enemy shots (51468),
Box (59073, 59523, 59558). Readers of the in-wind flag `+0x92`: `.PlayerScroll` (43803, 43813), the player's air
counter (46106, 46109) and stillness (46499) — all **built** (`PlayerScroll.swift:54`, `PlayerStates.swift:745`,
`Player.swift:850`).

**Today.** `Physics/StandardSprite.swift:60` — the branch is an empty stub (`// later: wind`); the fields
`windScale`, `inWind` (`+0x92`) and the ramp (`+0x96`, `+0x98`) exist (`SpriteSlot.swift:443`).

**Contract** (after the water current, before the ride carry; only while `+0x90 > 0`). First, at the top of
`.StandardSpriteHandles` and before the current, **`+0x92 = 0` every frame** (M l. 32460) — the in-wind flag is
re-earned each frame:
1. cell = (`+0x10 >> 5`, `+0xe >> 5`); o1 = `.GetFGOverlay1Tile`. o1 ∉ 0…15 → **leaving**: `+0x96 > 0` → `+0x96 − 1`,
   then `+0x14 += (+0x98 · +0x96) / 33` (C division). Done.
2. Else o2 = `.GetFGOverlay2Tile`; o2 ≤ 0 → done (no ramp-down either).
3. m = (o1 + 18) mod 36 (C remainder); (v, h) = `.LookupModedImpulse(m, 15·o2)` — the **test** impulse.
4. Gates, as the binary computes them (raw `10036a58..10036b44`, the signed-compare idiom): with vx = `+0x24`, vy =
   `+0x2c`, and "x-gate" / "y-gate" the flags that later allow the x push and the vy push:
   | test impulse | x-gate | y-gate |
   |---|---|---|
   | h ≥ 0, v ≥ 0 | h ≥ vx | v ≥ vy |
   | h ≥ 0, v < 0 | h ≥ vx | vy ≥ v |
   | h < 0, v ≥ 0 | vx ≥ h | v ≥ vy |
   | **h < 0, v < 0** | **vy ≥ v** | **vx ≥ h** |
   ⚑ In the last row the two flags are crossed (raw `10036a98 rlwinm r29,r6` takes the vy test into the x-gate,
   `10036a9c rlwinm r28,r0` the vx test into the y-gate) — every other branch puts each axis's test on its own gate.
   As written: transcribe the crossing. It is reachable: o1 10…15 give m 28…33 (h < 0, v < 0) — **L10's four
   o1 = 10 cells and L20's 36 o1 = 12 cells**; o1 9 (m 27) gives h = 0 and is not crossed. (The decompile shows it
   too, M l. 32514–32527, through `uVar8`/`uVar9`; a dated correction is appended to world-data-format §3.3.)
5. Neither gate → done. Else (v′, h′) = `.LookupModedImpulse(m, 14·o2)` — the **push** impulse; scale = `+0x90`:
   below 0xff → h′ = (h′·scale) >> 8, v′ = (v′·scale) >> 8 (arithmetic shifts).
6. Ramp: `+0x96 < 33` → `+0x96 + 1`, push = (h′·`+0x96`) / 33 (C division); else push = h′. `+0x98 = h′`;
   `+0x92 = 1`; x-gate → `+0x14 += push`; y-gate → `+0x2c += v′` (no ramp on the vertical).
7. No random draw anywhere (the wind dust's draws are `.WrapDrawWaterEffects`', built).

**Seam.** Core only. No draw input changes (positions only), so no `DrawModeAuditTests` writer row.

**First level / golden (R3).** Level 10, after 6A-S8 (whose task removes the strip's level-open refusal). Fixture:
level 10 with the 31 still-unbuilt records left out (§7.2). `testLevel10WindTrace`: 60 frames of the player held in
the first o1 = 9 column (x256, vy, `+0x96` per frame), seed fixed, on the fixture — it stays on the fixture for good.
`testLevel10WindFeatureGolden`: the trace's last frame, Mac. Deleted at level 10's enterable task: the wind draws
nothing of its own, so the trace (kept) and the real first-frame golden cover it. **Levels 1–5:** no overlay cell with
o1 0…15 and o2 > 0 on any of them, so the branch never pushes, `+0x96` stays 0 (the leaving arm never runs) and
`+0x92`'s per-frame clear stores the 0 it already holds — no golden moves.

**Tests (9).** `testWindGatesEachQuadrant` (four rows of the table, synthetic cells); `testWindCrossedGatesOnDiagonalUpLeft`
(o1 10); `testWindRampUpAndOff` (33 frames each way, the C division); `testWindScaleBelow255`;
`testWindNeedsPositiveStrength`; `testWindSetsInWindFlag` (and the air counter reads it; cleared the next frame out
of wind); `testWindCellCensus` (103 / 2,899 / 0 elsewhere); `testLevel10WindTrace`; `testLevel10WindFeatureGolden`.

**Asserts the build task adds** (4):
- `+0x92 = 0` at the top of `.StandardSpriteHandles` every frame (M l. 32460).
- the branch's place: after the water current (M l. 32461–32488), before the ride carry (M l. 32575).
- scale exactly 0xff → no shift (the test is `< 0xff`, M l. 32552).
- `+0x98` stored un-ramped (M l. 32563) and reused by the leaving arm (M l. 32496–32498).

### 2.3 The rotating cannon arm, p1 101…106, and its shot steering (6A-RC)

**What it is.** Cannons the player can climb into normally sit still (p1 0, built). With p1 101…106 they turn on
their own, pausing at each step; a pause ends with a click sound; 105 / 106 cannons turn only when the player shoots
them, toward the side the shot came from.

**Switch.** Background 0x442…0x44a with p1 101…106. Measured: **L10** records 89 (1090 p1 101), 108 (1097 101), 200
and 250 (1090 103); **L15** 156, 157 (1090 105), 158 (1092 101); **L20** 288 (1092 103); also L40 (103 ×5), L50
(101), L51 (103), L52 (103 ×7), L62 (102 ×2, 1097 105). Xichra's lair writes p1 0x67 / 0x68 into its cannons at
phase 3 (BOS §6.6). No shipped cannon has p1 1…100 or ≥ 107.

**Spans.** Setup arm M l. 62057–62184 (the p1 ≥ 1 branch is 62120–62170); Handle arm 62944–63069 (rotation 62983–
63021); `.HitBackgroundSprite` M l. 63680–63714 (steering 63689–63709).

**Today.** `SetupFaces.swift:380` refuses any p1 ≠ 0 (`notTranscribed`; :377 is the `case`); `BackgroundSprite.cannon` stubs the rest
(`BackgroundSprite.swift:334`); the `.HitBackgroundSprite` steering is a `// later` (`BackgroundSprite.swift:498`).

**Contract.**
1. Setup, p1 ≥ 1 (M l. 62120–62170; also taken by p1 1…100 and ≥ 107, which then never set up a path — as written):
   `+0x158 = 4`; p1 105, or p1 106 with record p2 = 0 → **record p2 = 4 (written into the level record)**;
   `+0xa6` = record p2; record p3: 0 → `+0x158` 4, 1 → 8, 2 → 16 (other values keep 4); `+0x15c` = step: 101 → +1,
   102 → −1, 103 → +2, 104 → −2, else 0; step ≠ 0 → `+0x158 /= |step|`; `+0x160 = +0x158`; `+0x164` = record p4
   (0 → 9000, 1 → 0x1c20). The common tail as p1 0: rect (0x35, 0x38, 0x61, 0x5b), hit `+0x5c`, the water test
   `+0x16c` (M l. 62171–62182). The aim `+0x46 = (type − 0x442)·4` and home `+0x14c/+0x150` come before (M l.
   62062–62066).
2. Handle, p1 101…106 (M l. 62983–63021): `+0xa6 == 0` → aim `+0x46 += +0x15c`, `+0x160 − 1`, at < 1 →
   `+0x160 = +0x158` and `+0xa6` = record p2 (the pause); else, **not** for 105 / 106: `+0xa6 − 1`, and on reaching 0
   with no voice playing the cannon sound (`FUN_100916dc(*_DAT_100a0308) == 0`, `SoundVoices`) →
   `.STPlay3DSoundRand(*_DAT_100a0308, 1, 0x41, +0xe)` (one R(10000)); then the recoil ease home (the p1 0 formula,
   built, M l. 63001–63020). The path branch is wider than "p1 < 0": **p1 < 101 and ≠ 0, or p1 > 106** (M l.
   62954–62955, 62984) → `.HandleProgrammedPath` + `x256 += vx`, `y256 += vy` (M l. 62975–62980; §3.1) — so p1 1…100
   also run it, with no path set up (unplaced, as written). Then the common aim fold and face (built).
3. `.HitBackgroundSprite`, the other is a player shot (`+0x4c == PTR_PTR_100a04e8`) and the cannon's p1 is 105 or
   106 (M l. 63689–63709): `.KillPlayerShot(shot, 0, 1)`; `.STPlay3DSoundRand(*_DAT_100a041c, 1, 0xab, +0xe)`; if
   `+0xa6 ≠ 0`: shot vx < 0 → (aim > 24 or aim < 12 or p1 106) → step −1, `+0x160 = +0x158`, `+0xa6 = 0`; shot vx ≥
   0 → (aim > 23 or aim < 8 or p1 106) → step +1, the same. Any other qualifying sprite → `.TurnIntoCannoned` +
   `+0x154 = 6` (built for p1 0, M l. 63711–63713) — a player shot hitting a 101–104 cannon takes this arm too, now
   reachable with a turning cannon. For 105 / 106 the Handle never counts `+0xa6` down (M l. 62995–62998 skip both),
   so their pause never ends by itself: the record-p2 write of step 1 only makes `+0xa6` ≠ 0 so the steering test
   (M l. 63694) passes; after a shot turns the cannon `+0x158` frames (4 at p3 0) it pauses again at `+0xa6` = record
   p2 = 4.

**Seam.** Core only (the sound cue is an ordinary `SoundCue`). The cannon's face writer rows in
`DrawModeAuditTests` (`BackgroundSprite.swift:355 / :364` today) move with the new arm: their file:line keys are
updated in the same task (`Tests/FerazelRenderTests/DrawModeAuditTests.swift`). Owns types 1092 and 1097 and the
p1 101–106 records of 1090 (R1; LL's 6A-BG1b dissolves); their set mark (0x442 for 0x443…0x44a) is 6A-CF's.

**First level / golden (R3).** Level 10 (placements 89, 108, 200, 250), after 6A-S8 and 6A-WD. Fixture: level 10 with
the trees (13) and Box scenery (14) left out. `testLevel10CannonTrace`: the aim and face per frame for two full turns
of placements 89 (101) and 200 (103), on the fixture, kept for good. `testLevel10RotatingCannonFeatureGolden`: the
first frame on which a rotating cannon on screen has turned (measured), Mac. Deleted at level 10's enterable task (the
trace pins the turning; the real first-frame golden pins the draw). **Levels 1–5:** every cannon there has p1 0
(measured), so the new Setup / Handle / Hit arms are never entered; level 1–5 goldens run as the switch-off — none
moves.

**Tests (10).** `testRotatingCannonSetupFields` (each p1, p3, p4 value); `testCannon105WritesRecordP2` (and 106 only
with p2 0); `testRotatingCannonPauseAndStep`; `testRotatingCannonClickNeedsSilentVoice`; `testCannon105DoesNotSelfTurn`
(the pause never ends by itself; re-pause at 4 after a shot); `testShotSteersCannonLeftAndRight` (the 12/24 and 8/23
windows); `testShotSteeringOnlyWhilePaused`; `testCannonP1OutsideRangeTakesPath` (p1 1…100 and > 106; unplaced; pinned
as read); `testLevel10CannonTrace`; `testLevel10RotatingCannonFeatureGolden`.

**Asserts the build task adds** (7):
- p1 106 with record p2 = 0 → record p2 = 4; 106 with p2 ≠ 0 keeps it (M l. 62122–62125).
- the steering hit's `.STPlay3DSoundRand(*_DAT_100a041c, 1, 0xab, …)`: one stream draw per qualifying hit (M l. 63693).
- p1 106 steers at any aim (M l. 63697, 63704).
- `.KillPlayerShot(shot, 0, 1)` — those two arguments (M l. 63692).
- a player shot into a 101–104 cannon is cannoned, `+0x154 = 6` (M l. 63711–63713).
- the captive fires only on an aim that is a multiple of 4 (`.HandleCannonedSprite` M l. 50062–50063) — with step ±2
  and odd pauses this decides when the player leaves.
- the recoil ease home runs for 101–106 every frame, after the step (M l. 63001–63020).

### 2.4 Trees and their branches (6A-TR)

**What it is.** Big tree pictures; the first time each runs it plants invisible one-way branch platforms on itself
that the player can stand on (0xc0f's one long branch is solid, not one-way).

**Switch.** Background 0xc08…0xc0f. Measured: L10 0xc08 ×2, 0xc09 ×4, 0xc0a ×4, 0xc0b ×3; L11 0xc08 ×2, 0xc09, 0xc0a,
0xc0b ×4; L15 0xc0c ×4, 0xc0d ×4, 0xc0e ×2; 0xc0f nowhere (§5). p1 = mirror; the mirrored trees are L10 0xc08 ×1,
0xc0a ×1, L11 0xc0b ×1 (all three plant branches, so the flip is reached on 10 and 11) and L15 0xc0c, 0xc0d, 0xc0e ×1
each (no branches). Face widths (PICTs, measured): 0xc08 226, 0xc09 227, 0xc0a 264, 0xc0b 198, 0xc0f 414.

**Spans.** Setup arm M l. 62597–62617; `.SetupTree` 62679–62886; Handle arm 63538–63546; the branch Box arms
`.HandleBoxSprite` M l. 60941–60947 (type 0xc08) and 61067–61075 (type 0xc09); `.SetupBoxSprite`'s head M l.
58934–58947 and tail M l. 59722–59727 (no arm matches 0xc08 / 0xc09: the `< 0xc12` branch tests only 0xbfe, M l.
59497–59531, and the trailing ranges, 59563–59720, miss them); `.MTNewSprite` M l. 30696–30721 (the Setup runs, then
the insert); `.FlipHRect` M l. 39474–39491.

**Today.** Refused at Setup (the Background `default` throw, `SetupFaces.swift:430`); `BackgroundSprite.swift:10`
`// later`. `BackgroundSprite.handle` already takes a `faceWidth: (FaceRef) -> Int` closure
(`BackgroundSprite.swift:144`); the same hot-rect flip is owed by LL's 6A-BX1a (`BoxSprite.swift:387`) and exists for
platforms (`PlatformSprite.swift:402`).

**Contract.**
1. Setup (M l. 62597–62617): margins `+0x1ca = +0x1c8 = +0x1cc = 0x80`, `+0x1ce = 0xa0`; the cache record flag of
   `_DAT_100a0ae0[type − 0xc08]`; `+0x17c = 0`; layer 30000 (0xc0f: −10); mirror `+0x17e` = (byte) p1; `+0x88 = 0`;
   callbacks 0; empty rect.
2. Handle (M l. 63538–63546): `+0x17c == 0` → `.SetupTree`; the face from the cache (M l. 63542); mirror `+0x17e` =
   (byte) p1 again (M l. 63544) — every frame, as at Setup (M l. 62606).
3. `.SetupTree` (M l. 62683–62886): `+0x17c = 1`; the face; then per type a list of branch rects (top, left, bottom,
   right), each mirrored by `.FlipHRect(rect, *(short*)(face + 6))` when `+0x17e` (the face width; `.FlipHRect`
   flips both x coordinates and swaps them when right < left, M l. 39474–39491), offset by the tree's position,
   spawned `.MTNewSprite(0xc08, rect.left, rect.top, layer argument 0xb, record −1, .SetupBoxSprite)`
   (`_DAT_1009ff34` = `.SetupBoxSprite`) — **the layer argument is overwritten to 2 by `.SetupBoxSprite`'s head
   (M l. 58939) before the insert (M l. 30719)**, so the branch lives at layer 2, ahead of the player (10) and of its
   tree (30000) — stored in a slot, and given the rect back at the origin as its hot rect `+0x34/+0x38`:
   | tree | branches (`SetRect` arguments left, top, right, bottom, as the dump passes them) → slot |
   |---|---|
   | 0xc08 | (0x62,0xc,0xb4,0x24) → `+0x1d4`; (0x10,0x31,0x66,0x4a) → `+0x1d8`; (0x94,0x4b,0xd6,0x5f) → `+0x1dc` |
   | 0xc09 | (0x27,0xb,0x6e,0x15) → `1d4`; (0x6c,0x1f,0xaf,0x2c) → `1d8`; (8,0x3b,0x5c,0x50) → `1dc`; (0x8e,0x46,0xd7,0x59) → `1e0` |
   | 0xc0a | (0x42,0x10,0x8c,0x23) → `1d4`; (0x96,0xe,0xd0,0x23) → `1d8`; (0x14,0x34,0x5c,0x49) → `1dc`; (0xc0,0x30,0xfd,0x44) → `1e0` |
   | 0xc0b | (0x43,0xd,0x96,0x1d) → `1d4`; (0x34,0x48,0x6d,0x5f) → `1d8`; (0x81,0x3e,0xbc,0x4c) → `1dc`; (10,0x6f,0x44,0x84) → `1e0`; (0x61,0x7d,0xa5,0x98) → **`1d4` again** (the first pointer lost, as written) |
   | 0xc0c…0xc0e | none (no arm) |
   | 0xc0f | (0xb,0x1b,0x182,0x46), **type 0xc09**, → `1d4`, then that child's `+0x185 = 0` |
   Every rect in this document is written as `SetRect`'s four arguments (left, top, right, bottom); the build copies
   them literally. A spawn with no free record stores to address 0 (Ruling 16: dropped) and the rect writes after it are
   dropped too.
4. The branch (Box 0xc08, M l. 60941–60947, every frame): `+0x5c = 0`, `+0xc0 = 0` (no face), `+0x1f8 = 0`,
   gravity `+0x110 = 0`, one-way `+0x185 = 1`. The 0xc09 child (0xc0f's, M l. 61067–61075, `0xc08 < type < 0xc0a`):
   the same four stores and **`+0x185 = 0`** — not one-way: 0xc0f's long branch (386 × 43 px) is a solid platform,
   which SetupTree's own `+0x185 = 0` store on the child (M l. 62885) agrees with. (0xc0f is placed nowhere.)
5. Spawned in the sprite pass → Invariant 3's insert order; never counted (record −1), never written back. Inserted at
   layer 2, ahead of the tree in the list, so **its first Handle runs on the next frame**; for the rest of the planting
   frame it is a solid Box with `.SetupBoxSprite`'s head state: `+0x4c` the Box Handle, `+0x5c` the Box hit, `+0x1f8`
   the Box tile hit, `+0xa6 = 3`, gravity `+0x110 = 0x151`, HP 600 (M l. 58936–58947), then the tail: x256 / y256
   from `+8` / `+6`, `+0xa/+0xc` = `+6/+8`, `+0x13c = 0x80` (M l. 59722–59727). `BoxSprite.setup` already sets layer 2
   (`BoxSprite.swift:151`): a builder who calls it gets the right layer.

**Seam.** Core only (the cache marks of `_DAT_100a0ae0` join `CachedFaces` at `.InitBackgroundSprite`'s position —
on top of 6A-CF's record-keyed list). One shared `flipHRect(rect, width)` helper, built here (6A-TR lands before LL's
6A-BX1a, §7.1) and reused by BX1a; Core reads the width through the existing `faceWidth` closure. New writer rows in
`Tests/FerazelRenderTests/DrawModeAuditTests.swift`: the tree's mirror `+0x17e` at Setup and at every Handle (M l.
62606, 63544), its face store (M l. 63542) and layer 30000 / −10. Owns types 3080–3087 and the Box branch types
0xc08 / 0xc09 it spawns (R1; LL's 6A-BG1a dissolves).

**First level / golden (R3).** Level 10, after 6A-S8, 6A-WD and 6A-RC. Fixture: level 10 with the Box scenery (14)
left out. `testLevel10TreeFeatureGolden`: the first frame with a tree on screen (measured), Mac. Kept at level 10's
enterable task unless that frame is frame 1 (then deleted: the real first-frame golden shows the same trees). Level 11's
mirrored 0xc0b and level 15's trees are pinned by their levels' enterable goldens. **Levels 1–5:** no type 0xc08…0xc0f
is placed or spawned there, and the flip helper is new code no level 1–5 path calls — no golden moves.

**Tests (10).** `testTreeSetupFields`; `testTreePlantsBranchesOnFirstHandle` (counts 3/4/4/5/0/1);
`testTreeFifthBranchOverwritesFirstSlot`; `testTreeBranchesMirror` (`.FlipHRect` with each tree's face width);
`testBranchBoxArm` (0xc08: one-way, no face, no gravity; 0xc09: `+0x185 = 0`); `testBranchLayerIsTwo`;
`testBranchFirstHandleNextFrame` (the Box head state for the rest of the planting frame); `testTreeNoFreeRecordDropsStores`;
`testTreeCacheMarks`; `testLevel10TreeFeatureGolden`.

**Asserts the build task adds** (10):
- the face and the mirror re-read on every Handle, not only at Setup (M l. 63542, 63544).
- `.SetupTree` stores the face itself before planting (M l. 62695–62696).
- every rect constant of the table, not only the counts (M l. 62683–62886).
- each rect offset by the tree's `+0xc` / `+0xa` (e.g. M l. 62703).
- the branch's layer 2 (M l. 58939), not 0xb.
- the hot rect given back at the origin (`+0x34/+0x38`, after each spawn).
- 0xc0f spawns type 0xc09 and stores the child's `+0x185 = 0` (M l. 62885).
- the 0xc09 Box arm's `+0x185 = 0` (M l. 61069–61075).
- the first Handle of a branch on the next frame (insert after Setup, M l. 30716–30719).
- `.FlipHRect` swaps the x coordinates when right < left (M l. 39474–39491).

### 2.5 The parallax ripple — the river backdrop (6A-RP ⚑)

**What it is.** On levels 11 and 18 the lower part of the sky backdrop (virtual rows 512…1151) slides sideways a
little more each frame and wobbles — a flowing river. Rows 512…639 flow slower near the top and faster lower down;
rows 640…1151 all at one rate.

**Switch.** hdr `0x26ca` = 1 on levels 11 and 18 only.

**Spans.** `.PaintFrameWrap` M l. 9211–9226 (every call, after `.WrapDrawSprites`) and M l. 9255–9425 (drawn frames;
raw `10011fe0..100126c8`); the 55-entry table of `.BuildSineTable` M l. 17389–17397 (`_DAT_100a00d0`); the phase
`*_DAT_1009fd74` (0x200 at level start M l. 5217, + 0x100 per `.PaintFrameWrap` M l. 9456 — built in
`FrameRenderer`). The consumer (`DoubleBlitPPCParallaxOneLayer`'s per-row offset, rendering-omnipx-titles §1.3) is
**built** (`ParallaxBlitter.rippleTable`, `ParallaxBlitter.swift:107, :370`). **`.RipplePxBackOffsets` is not this
feature** (§5, §6 E3).

**Today.** `ParallaxBlitter.init` refuses the level (`ParallaxBlitter.swift:130`, `Refusal.ripple`); the table stays
empty.

**Contract.** Table S[i] = trunc(f32(sin(f32(i) · 0.11423963f)) · 3.0f), i = 0…54 (f32 `100a1724`, f32 3.0 at
`100a1720`, as `.BuildSineTable`'s other loops; the port's 35-entry `SpriteBlitter.rippleOffsets` is the model).
With t = the phase before this frame's + 0x100, a = t >> 8, b = t >> 7:
1. Every `.PaintFrameWrap` call, drawn or not, while `0x26ca` ≠ 0 (M l. 9211–9226, before the drawn-frame test of
   M l. 9254): rows 0x200…0x47f: table[r] += `_DAT_1009ffbc`[r] (i16). ffbc has no
   non-zero writer in the dump (cleared by `.InitGameGlobals` M l. 725ff and `.SetupLevelSprites` M l. 1994ff) — a
   no-op as shipped; transcribe it (cheap) and pin ffbc = 0.
2. Drawn frames (M l. 9255–9425): rows r = 0x200…0x27f: table[r] = fctiwz((1.9·(r − 0x200) + 32.0) · (S[(r + a) mod
   55] − b)) (f64 `100a15d0` 1.9, `100a15d8` 32.0; `fmadd` then `fmul`, raw `10012070..10012090`); rows 0x280…0x47f:
   table[r] = fctiwz(275.2 · (S[(r + a) mod 55] − b)) (f64 `100a15c8`). (r + a) mod 55 by `mulhw 0x094f2095`.
   **b grows by 2 every frame** (raw `10012004 srawi r6,r0,7`; `1001205c subf r7,r6,r7`): the offset is a steady
   drift plus a ±3 wobble — the river flows. The products overflow i32 after about 3.9 million frames (36 hours);
   `fctiwz` saturates — the ripple-phase time bound already in the audit (`Refusal.ripplePhase`, `.timeBound`) covers
   the same span.
3. The compositor uses −(table[r + v0b] >> 8) as each row's x offset (built).

**Seam.** Render only: `FrameRenderer` fills `rippleTable` before the copy on drawn frames, at the `.PaintFrameWrap`
position; no Core state, no seam type.

**First level / golden (R3).** Level 11, after 6A-TR. The task removes the `Refusal.ripple` refusal of
`ParallaxBlitter.init` itself. Fixture: level 11 with the 27 still-unbuilt records left out (Box scenery 26, the faces
task's 1; §7.2). `testLevel11RippleFeatureGolden`: the first frame whose view shows a PxBack row ≥ 512 (yb = 256 on
11 and 18, measured, so the PxBack rows track V 1:1; the build measures the frame, R4), Mac and Windows references.
Kept at level 11's enterable task unless that frame is frame 1 (then deleted). Level 18 is pinned by its own enterable
task. **Levels 1–5:** hdr `0x26ca` = 0 on all five, so neither loop runs, the table stays empty and the compositor's
offsets stay 0 — no golden moves.

**Tests (8).** `testRippleSineTable55`; `testRippleRowsShallow` (r 0x200, 0x27f); `testRippleRowsDeep` (0x280,
0x47f); `testRippleDriftsTwoPerFrame`; `testRippleAddIsNoOp` (ffbc 0); `testRippleOnlyOnDrawnFrames` (loop 2 only;
loop 1 on every call); `DrawModeAuditTests` (`Refusal.ripple` row gone); `testLevel11RippleFeatureGolden` (+ Windows
reference).

**Asserts the build task adds** (3):
- the ffbc add runs on every `.PaintFrameWrap` call, drawn or not (M l. 9211–9226, before M l. 9254).
- the phase t is read before this call's + 0x100 (M l. 9456 adds it at the end of the call).
- `fctiwz` saturates at ±2³¹ rather than wrapping (raw `10012070..10012090`).

### 2.6 Tinted submerged tiles (6A-T11 — built; prove only)

**What it is.** On level 11 every tile under water is drawn through the water tint instead of having a tinted water
face laid over it.

**Switch.** hdr `0x26c6` = 1 on level 11 only.

**Spans / today.** Readers M l. 8825 (`.WrapDrawWaterEffects`), 9618, 9635 (`.PlainWrapFGTile`), 9728
(`.PlainWrapFGOverlayTile`), 9957, 9982 (`.RedrawScrollGrid`), 27043 (`.BlitEncFaceX`, modes ≥ 0x15). **All seven are
built**: `TileGridRenderer.swift:257` (RedrawScrollGrid), `LightRenderer.swift:447, :490` (the plain-wrap tile and
overlay), `WaterEffects.swift:246` (the Enhanced water face's `0x26c6` read; :79 and :201 are the field and the env),
the blend op's water table (`TileGridRenderer.swift:265`).
No test runs a level with the flag on (`TileGridTests.swift:312` asserts it 0).

**Contract.** Nothing to transcribe. The build proves the seven sites against the dump and adds the proof.

**Seam.** None. **First level / golden.** Inside 6A-RP, on its level-11 fixture: the switch-off check — forcing
`submergedFaces = 0` must change `testLevel11RippleFeatureGolden` and leave levels 1–5's goldens unchanged (`0x26c6`
= 0 on all five, so nothing reads it there). No golden of its own.

**Tests (2).** `testSubmergedTintSitesMatchDump` (the seven readers, synthetic water cell, flag on/off);
`testLevel11SubmergedSwitchOff`. Plan card 6A-T11 shrinks to these two rows, folded into 6A-RP (§7.1). Asserts: none
(the mutation table found no unpinned behaviour).

### 2.7 OmniPx rain (mode 1), thunder, and the side push (6A-RN ⚑)

**What it is.** On Storm Valley the sky backdrop is replaced by two scrolling rain sheets (OmniPx mode 1), particle
rain streaks fall from the top of the view every frame, and every few seconds lightning flashes the screen, thunder
plays and the screen briefly darkens. A constant wind pushes the player left.

**Switch.** hdr `0x26c7` = 1 (level 15 only); `0x272c` = −320 (level 15 only).

**Spans.** `.GenerateRain` M l. 8429–8531 (called M l. 9228–9229, every `.PaintFrameWrap` call, raw
`10011ee4..10011ef0` — before the drawn-frame test `10011fc4`; the extra `.PaintFrameWrap` calls are `.Pause`'s (M l.
3190) and the quit dialogs' in `.CheckGameLoopKeys` (M l. 3918, 3922, 3980, 4005), so each runs the rain — and
`.AnimateCLUT`, §3.6 — once more); the first-call flag's writers `.SetupLevel` (M l. 2541), `.Pause` (M l. 3203) and
`.GameLoop`'s exit (M l. 5300); `.GammaFadeOutAsync` M l. 31893–31915, `.HandleAsyncGammaFade` 31917–31945,
`.GammaFadeInAsync` 31872–31891; `.STPlayLoopedSound` M l. 40978ff (@ `10047e34`); OmniPx mode 1 setup M l. 13261–13277 (built), `.UpdateOmniPx` faces loop
(built); `.TurnOnOmniPx` zeroes the factors for mode 1 (built); the side push in `.HandlePlayerSprite` M l.
46347–46365 (**built**, `Player.sidePush`, `Player.swift:751`; no test with v ≠ 0).

**Today.** `LevelRun.refuseUndrawnHeader` refuses mode 1 (`LevelRun.swift:583`); `OmniPx.setup` already loads 6000 /
6001 and their parameters (`OmniPx.swift:96, :125`); `GenerateRain` is not built; the looped-sound play
(`.STPlayLoopedSound`) has no cue — `SoundCue` (`Seams/SoundCue.swift`) has no loop field, while both shells' mixers
already take `loops:` (`Shared/FerazelAudio.swift:152–153`, `Windows/Sources/FerazelWinKit/WinAudioDriver.swift:59`)
(`Player.swift:161` notes the same routine unbuilt for the level ambience). `Pause.painted` (`Pause.swift:250–265`)
already stops snd 452 and 511 but has no first-call flag to clear. The async gamma fade already exists as
`AsyncGammaFade` held in the world (`LevelRun.swift:536–541`, `s.world.gammaFade`) with `DrawOp.gammaStep`
(`DrawOp.swift:41`, one `.HandleAsyncGammaFade` step).

**Contract** (`.GenerateRain`, re-read line by line; agrees with rendering-omnipx-titles §3.6):
1. First call (`*_DAT_1009fe88 == 0`): set it; T = R(90) + 90 (`sRam100a381c`); `.STPlayLoopedSound(*_DAT_1009fe24,
   1, 0x55)` (snd 452, the rain loop) (M l. 8449–8454). The flag is cleared by `.SetupLevel` after `.SetupOmniPx`
   (M l. 2541), **by `.Pause`** after it stops the rain loop and the ambience voice (M l. 3200–3203) and by
   `.GameLoop`'s exit (M l. 5298–5300). So after every Caps-Lock pause on level 15 the next call draws a fresh R(90)
   (the thunder timer restarts) and replays the loop. `.Pause`'s own `.PaintFrameWrap(1, 0)` (M l. 3190) runs before
   the clear, with the flag still set. `.STPlayLoopedSound` (M l. 40978ff): no `FastRand`; rate fixed 0x10000; plays
   only when sound is on (`*(_DAT_1009fe44 + 0xb)`), volume `param_3 · global >> 8` — no stream draw either way.
2. Thunder (M l. 8456–8480): T > 0 → T − 1. T = 0 → flash `*_DAT_100a00fc = 3` (the built `ScreenFlash`),
   `.STPlayRegSound(*_DAT_1009fd68, 1, 0xab)` (snd 453), T = −1. T = −1 → −2. T = −2 → `.GammaFadeOutAsync(2,
   rgb 100a53ca/53ce, 0xc, 0x10)`, three `.HandleAsyncGammaFade`, `.GammaFadeInAsync(0x6e)`, T = −3. T < −2 → T =
   R(150) + 210. The fade (M l. 31872–31945): `.GammaFadeOutAsync` arms only when the fading preference
   `DAT_100a53c2` is on **and** the screen is not faded (`*_DAT_1009fde8 == 0`); the three `.HandleAsyncGammaFade`
   calls step 0 %, 50 %, 100 % and then (`17ee` 3 > 2) snap to the colour and set faded; `.GammaFadeInAsync(0x6e)`
   arms only when faded; the main loop's `.HandleAsyncGammaFade` (M l. 5282) then carries the 110-step fade-in. With
   fading off, nothing of the fade happens; the flash and the sound do.
3. Drops (M l. 8481–8527): x = H + R(50); while x < H + 660: s = R(2); pos (v = V, h = x); s = 0 (heavy): shape 5,
   vx −1200, vy 3600, kinds 7, 6, 5; s = 1 (light): shape 4, vx −700, vy 2100, kinds 7, 7, 6;
   `.NewParticle(kind, 0, pos, shape, vx, vy, 0, mode 1)` three times; between them: light → R(100) > 50 → h − 1,
   then v + 2; heavy → v + 4 and h − 1. Then x += R(200) + 50. Draw order per drop: R(2), [light: R(100)], [light:
   R(100)], R(200).
4. OmniPx mode 1 on screen: faces 6000 (opaque) and 6001 over it, factors zeroed (the grid fixed to the view), no
   base refresh — Render's `OmniPxOp.update` with no base cell (the port's starting contents are whatever
   `NewBlitPort` leaves; 6000 has no transparent pixel, so it covers it — measured by the build).

**Seam.** Core: `GenerateRain` at its `.PaintFrameWrap` position (every call, drawn or not — the pause's and the quit
dialogs' extra calls included); the first-call flag as a session value cleared at the three writers' positions
(`Pause.painted` gains the clear); the fade is **`AsyncGammaFade` plus three `gammaStep` ops in the same iteration**,
gated on the fading preference and the faded flag (not `ScreenGammaOp.timedFadeToColor`); the refusal of mode 1
removed. **Shared:** a loop field on `SoundCue` (Invariant 9: a field added, default off) and the play path in
`Shared/FerazelAudio.swift` (and the Windows audio test) — lockstep (a), both shells in this task. Design the field so
6B-AS can add a "set the volume of the voice playing snd N" cue later (the auto-scroll ambience, §3.7). Render: mode 1
in `OmniPx` port updates (faces only).

**First level / golden (R3).** Level 15, after 6A-RC, 6A-TR and LL's 6A-BX1a (§7.1). The task removes the mode-1
level-open refusal itself. Fixture: level 15 with the plants (22) left out (§7.2).
`testLevel15RainFeatureGolden`: frame 1 (backdrop sheets + the first drops), Mac and Windows — deleted at level 15's
enterable task (its real first-frame golden is the same frame). `testLevel15ThunderFlashFeatureGolden`: the
mask-port flash frame (`ScreenFlash` count 3, stepped on drawn frames), with the fading preference fixed, Mac and
Windows; its frame is measured from the seed (R4). The fade itself is presentation only — `FrameRenderer` drops
`.screenGamma` in level frames (`FrameRenderer.swift:479`) and `FrameGoldenTests` hashes `r.screen` through
`screenClut` — so no golden can see it; `testRainThunderGammaOps` pins the op list instead. Kept at the enterable task
(frame ≥ 90, never frame 1). **Levels 1–5:** hdr `0x26c7` ≠ 1 on all five, so `GenerateRain` never runs; the new
`SoundCue` field defaults off, so every existing cue plays as before; the Pause's flag clear stores to a value nothing
else reads — no golden moves.

**Tests (13).** `testRainFirstCallTimerAndLoop`; `testRainRestartsAfterPause` (one fresh R(90), the loop cue replayed;
the pause's own paint runs the rain once more before the clear); `testRainThunderSequence` (0, −1, −2, −3 → reset);
`testRainThunderGammaOps` (the op list with fading on and off, and with the screen already faded);
`testRainDropColumnsAndDraws` (RNG order); `testRainHeavyDropParticles`; `testRainLightDropParticles`;
`testRainRunsOnUndrawnFrames`; `testOmniPxModeOneFacesOnly` (Render); `testSidePushOnLevel15` (airborne and
grounded); `DrawModeAuditTests` (`omniPxMode` row: mode 1 drawn; 3, 6, 7, ≥ 8 stay);
`testLevel15RainFeatureGolden` (+ Windows); `testLevel15ThunderFlashFeatureGolden` (+ Windows).

**Asserts the build task adds** (5):
- the first-call flag's two extra clears: `.Pause` (M l. 3203), `.GameLoop`'s exit (M l. 5300).
- the extra `.PaintFrameWrap` callers each run the rain once (M l. 3190, 3918, 3922, 3980, 4005).
- the fade's gates: the fading preference and the faded flag (M l. 31879–31882, 31903).
- the three gamma steps in the same iteration as the thunder's T = −2 (M l. 8456–8480).
- the loop plays only with sound on and draws no number (M l. 40978ff).

### 2.8 Clouds 0xb4a…0xb4d (6A-CL)

**What it is.** Translucent clouds in front of everything, drifting with their own parallax.

**Switch.** Background 0xb4a ×44, 0xb4b ×44, 0xb4c ×32, 0xb4d ×44 on **level 20 only** (all p1 = p2 = 0).

**Spans.** Setup arm M l. 62526–62567; Handle arm 63304–63341.

**Today.** Refused at Setup.

**Contract.**
1. Setup: callbacks 0, empty rect (never collides); the face from its cache (0xb4a `_DAT_100a0b20`, 0xb4b `0b1c`,
   0xb4c `0b18`, 0xb4d `0b14`) and the flag; `+0x88 = 0`; `+0xb8 = 0xb0004` (translucency, table 4); layer 0x7ef4;
   `+0x14c` = p1, 0 → **R(60) + 270**; `+0x150` = p2, 0 → `+0x14c`; `+0x154 = x << 8`, `+0x158 = y << 8`;
   `+0x15c = R(50)` (no reader found). Two draws per cloud on level 20 → 328 draws inside `.SetupLevelSprites`
   before any later Setup's: level 20's whole stream depends on them.
2. Handle (M l. 63304–63341): the face again (M l. 63307–63320); fx = `+0x14c`: > 0 → x256 = H·256 + (`+0x154` −
   (H·256·fx >> 8)); = 0 → x256 = `+0x154`; < 0 → unchanged; the same for y with `+0x150`, V and `+0x158`; then the
   pixel copies (M l. 63340–63341). The Handle reads the scroll **before** this frame's `.FindUpperLeftCorner`.
3. Reachable as shipped: p1 = p2 = 0 on all 164, so fx = fy = R(60) + 270 ∈ 270…329 > 256 — the clouds move faster
   than the camera (true foreground parallax); the fx = 0 / fx < 0 and fy arms are unreachable (pinned as read,
   synthetic). The cloud PICTs are 174 / 197 / 220 / 193 px wide (measured), below the translucency buffer's 301 bytes,
   so `Refusal.translucency`'s width case stays unreachable — the reason on its audit row.

**Seam.** Core only (mode 0xb unrotated is drawn today). New writer rows in
`Tests/FerazelRenderTests/DrawModeAuditTests.swift`: `+0xb8 = 0xb0004` (M l. 62550) and the layer 0x7ef4 (M l. 62551).
Owns types 2890–2893 (R1; LL's 6A-BG1a dissolves).

**First level / golden (R3).** Level 20, after 6A-WD and 6A-RC. Fixture: level 20 with the blade (28) and mace-path
(16) records left out (§7.2) — the 164 clouds' 328 Setup draws are all in. `testLevel20CloudFeatureGolden`: the first
frame with a cloud on screen (measured), Mac. Kept at level 20's enterable task unless that frame is frame 1 (then
deleted). **Levels 1–5:** no cloud type is placed there — no golden moves.

**Tests (7).** `testCloudSetupDrawsTwo` (order R(60) then R(50)); `testCloudSetupFields`; `testCloudParallaxX`;
`testCloudParallaxY`; `testCloudNeverCollides`; `testCloudFxAlwaysAbove256OnLevel20`; `testLevel20CloudFeatureGolden`.

**Asserts the build task adds** (6):
- the face re-read from its cache record on every Handle (M l. 63307–63320).
- fx = 0 → x256 = `+0x154` (M l. 63322–63323), synthetic.
- fx < 0 → x256 unchanged (M l. 63321–63325), synthetic.
- fy = 0 → y256 = `+0x158` (M l. 63331–63332), synthetic.
- fy < 0 → y256 unchanged (M l. 63330–63334), synthetic.
- the pixel copies `+0xc` / `+0xa` from x256 / y256 after both axes (M l. 63340–63341).

### 2.9 The rotating blade 0xbf4 and the segment test (6A-BD)

**What it is.** A spinning arm. It hurts the player only if the arm's line (16 to 88 px from its centre) crosses the
player's body box.

**Switch.** Background 0xbf4 (3060): L20 ×28 (p4 1), L22 ×13 (p4 0), L30 ×3, L62 ×9 (p4 0). All p2 0, p3 0 (→ speed
8). p1 ≠ 0 exists (L20 p1 1 ×1, L30 p1 180 ×1, measured) and **neither arm reads p1**.

**Spans.** Setup M l. 62571–62583; Handle 63511–63530; `.HitPlayerSprite` arm 49684–49724; `.SectRectLineSeg`
39562–39601; `.SectLineSegs` 39507–39561.

**Today.** Refused at Setup; `HitPlayerSprite.swift:159` `// later: 0xbf4`.

**Contract.**
1. Setup: cache flag `_DAT_100a0b0c`; angle `+0x46` = p2; speed `+0x150` = p3, 0 → 8; rect (5, 5, 0xb5, 0xb5);
   callbacks 0. Setup leaves `+0xc0` 0: the face is the Handle's (the level-start draw takes it from `.handle`).
2. Handle (M l. 63511–63530): face (M l. 63512); angle += speed, wrapped into 0…359 (one step each way: ≥ 360 → − 360,
   < 0 → + 360, M l. 63515–63523); rotation `+0x1aa` = angle; `+0x88 = 0`;
   **`+0x89 = 1`** (dynamic light → mode 0xc, draw-effects §1.1 step 4); p4 = 0 → bottom clip `+0x1ba = 0x5e` (the
   lower part of the face not drawn).
3. Player arm (`.HitPlayerSprite`, reached on rect overlap): body = the player's rect at its position with top + 6 and
   bottom − 8; c = (`+0x10`, `+0xe`) of the blade; cos / sin from the 360-entry tables (`_DAT_100a0168` cos,
   `_DAT_100a0164` sin — built in `SpriteBlitter.cosTable`); P1 = (fctiwz(16·cos + cx), fctiwz(cy − 16·sin)), P2 =
   (fctiwz(88·cos + cx), fctiwz(cy − 88·sin)) (f64 16.0 `100a19f8`, 88.0 `100a19f0`); no crossing → return.
   Crossing → save the blade's vx; vx = +0x8fc when the blade's centre x < the player's (strict, M l. 49716), else
   −0x8fc; coins = R(100) < 0x33 ? 0 : 4 — **the R(100) is drawn only on a frame whose segment crosses** (after
   `.SectRectLineSeg` returns 1, M l. 49711–49722), not on every overlap frame; `.HurtPlayer(player, blade, 0x70,
   blood 0, invul 0x3c, coins)`; restore vx.
4. `.SectRectLineSeg(rect, x1, y1, x2, y2)`: the segment against the top edge (left, top)–(right, top), the bottom,
   the left, the right edge, first hit wins; a segment wholly inside the box does **not** hit (no containment test).
   `.SectLineSegs(a, b, c, d, e, f, g, h)`: k = c·b − a·d; s1 = (d − b)·e + (a − c)·f + k, s2 = (d − b)·g + (a − c)·h
   + k; both ≠ 0 and the same sign → 0; then the same with the roles swapped (k = g·f − e·h, s over (a, b), (c, d));
   else 1 — a zero product (touching) counts as a crossing, and so do **collinear segments that do not overlap**
   (both products 0); i32 arithmetic.

**Seam.** Core. Render: a rotated mode-0xc draw with a bottom clip must be drawable; if it is refused today, the
renderer change is part of this task (Invariant 8). New writer rows in `Tests/FerazelRenderTests/DrawModeAuditTests.swift`
(the table is keyed by writer site): rotation `+0x1aa` 0…359 (M l. 63524), dynamic light `+0x89 = 1` (M l. 63526),
clip bottom `+0x1ba = 0x5e` (M l. 63528). Mode 0xb rotated (refused) is unreachable here: it needs light byte −1,
which no level has. Owns type 3060 (R1; LL's 6A-BG1b dissolves).

**First level / golden (R3).** Level 20, after 6A-CL. Fixture: level 20 with the mace-path records (16) left out.
`testLevel20BladeFeatureGolden`: the first frame with a blade on screen (measured), Mac. Kept at level 20's enterable
task unless that frame is frame 1 (then deleted). The p4 0 clip (levels 22, 62) is pinned synthetically here and on
screen by level 22's enterable golden. **Levels 1–5:** no blade is placed there; the new segment routines have no
other caller — no golden moves.

**Tests (13).** `testBladeSetupFields`; `testBladeHandleSpinsAndWraps`; `testBladeBottomClipWhenP4Zero`;
`testSectLineSegsCrossTouchAndMiss`; `testSectLineSegsCollinearDisjointHits`; `testSectRectLineSegEdgesAndInside`;
`testBladeArmEndpoints` (four angles); `testBladeHitKnockbackAndCoins`; `testBladeNoDrawWithoutCrossing`;
`testBladeHitRestoresVx`; `testBladeIgnoresP1`; `testBladeRotatedLitDrawIsDrawable` (a rotated mode-0xc face with
bottom clip 0x5e draws); `testLevel20BladeFeatureGolden`.

**Asserts the build task adds** (7):
- the face taken in every Handle (M l. 63512), none at Setup.
- `+0x88 = 0` every Handle (M l. 63525).
- the body rect: top + 6, bottom − 8 (M l. 49688–49689).
- no stream draw on an overlap frame without a crossing (M l. 49712–49713).
- collinear disjoint segments hit (`.SectLineSegs` M l. 39507–39561).
- the negative wrap (+ 360) as well as the positive one (M l. 63517–63518).
- the strict `<` on the centre x: equal centres push −0x8fc (M l. 49716–49720).

### 2.10 Programmed-path maces, modes 1 and 2 (6A-MP)

**What it is.** A spiked ball that shuttles up and down (mode 1) or left and right (mode 2) on a fixed path instead of
swinging on a chain.

**Switch.** Background 0x5c8…0x5d1 with p1 1 or 2. Measured: **L20** 0x5cd p1 1 ×16; **L22** 0x5cd p1 1 ×23, p1 2 ×6;
L30 0x5ce 1 ×22, 2 ×2; L31 0x5ce 1 ×4; L40 0x5cd 1 ×10, 2 ×7; L62 0x5d0 1 ×26, 2 ×2.

**Spans.** Setup M l. 62338–62361; Handle 63141–63146; `.SetupProgrammedPath` / `.HandleProgrammedPath` (built,
`ProgrammedPath.swift`); `.ApplyGravityAndSeparateFromTiles` (built).

**Today.** `SetupFaces.swift:399` refuses modes 1–2; `BackgroundSprite.mace` returns at once for them (`:173`). The
port's spawn calls `BackgroundSprite.makeRadial` for every type in `BackgroundSprite.maces` (`SetupFaces.swift:888–898`),
but the dump makes `.MakeRadial` / `.MakeRadiusSprites` only for modes 10–14 (M l. 62362–62420): the spawn must skip
modes 1–2.

**Contract.** Setup (after the common mace stores, which are built — including the record write-backs p2 0 → 0x8c and
p3 0 → 0x1e, M l. 62329–62336, which happen **first**, so `.SetupProgrammedPath` reads the written-back record): mode
`+0xb0` ∈ {1, 2} → `+0x170 = 1`, `+0x185 = 0` (not one-way, unlike modes 10–14), `+0x188 = 1` (a write-back flag:
Shared architecture's "a test row in its Setup test per flag the dump writes"), `.SetupProgrammedPath(s, −1, 0)` —
the path bounds come from the position **before** the p4 offset; then mode 1 → y256 += record p4·256; mode 2 → x256 +=
record p4·256; `+0xc = +8 = x256 >> 8`, `+0xa = +6 = y256 >> 8` (M l. 62337–62359). Handle (M l. 63141–63146): the
per-frame face (built), then `.HandleProgrammedPath` and `.ApplyGravityAndSeparateFromTiles`; no radial, no chain, no
spoke update.

**Seam.** Core only. No new draw writer (the face path is the built mace's). Owns the mode-1/2 records of 1485 (and of
0x5c8…0x5d1 on later levels) (R1; LL's 6A-BG1b dissolves).

**First level / golden (R3).** Level 20, after 6A-BD — the last level-20 feature, so its fixture is level 20 with
every record in (only the level's absence from `BuiltLevels` makes it a fixture). `testLevel20MacePathTrace`: one
mace's position per frame over a full shuttle, kept for good. `testLevel20MacePathFeatureGolden`: the trace's last
frame, Mac — deleted at level 20's enterable task (the trace and the real first-frame golden cover it). **Levels
1–5:** only modes 12 and 14 are placed there, and the arm is new code for modes 1–2; but the task edits
`BackgroundSprite.mace` and the spawn used by level 1's pendulums, so level 1's goldens are its switch-off check — none
moves.

**Tests (7).** `testMacePathSetupModeOne` (bounds before the offset); `testMacePathSetupModeTwo`;
`testMacePathHandleMoves` (one shuttle); `testMacePathMakesNoChain`; `testMacePathWriteBackFlag`;
`testLevel20MacePathTrace`; `testLevel20MacePathFeatureGolden`.

**Asserts the build task adds** (5):
- `+0x185 = 0` (M l. 62341).
- `+0x188 = 1` (M l. 62342).
- no chain, no radial for modes 1–2 (the radial is in the mode 10–14 branch, M l. 62362–62420).
- the path bounds read before the p4 offset (`.SetupProgrammedPath` at M l. 62343, the offset at M l. 62344–62353).
- no spoke update in the Handle (M l. 63141–63146).

### 2.11 The magic carpet 0x438 / 0x439 (6A-CP) — read in full

**What it is.** A rolled carpet that unrolls into a flying platform when the player touches it, rises, sinks and
settles, and the player steers it. A carpet placed with a ride count (record p2 > 0) also counts down while ridden,
flashes and bursts into particles at 0 — **but the only shipped carpet has p2 = 0, so on level 22 it never counts
down, flashes or bursts**: it flies for ever.

**Switch.** Box 0x438 (1080) ×1 on **level 22** only (placement 486, p1 = p2 = p3 = p4 = 0, measured); 0x439 (1081)
is reached only by the wake.

**Spans.** Setup M l. 59078–59103; Handle arm M l. 60289–60375 (it ends `goto LAB_1006f948`, the Box Handle's tail,
M l. 61152–61174); `.HitBoxSprite` wake 61470–61476; the player's half: `.HandlePlayerSprite` M l. 44532–44552 (the
"on carpet" flag `*PTR_DAT_100a05a4`, camera latch `*_DAT_1009fd34 = 1`), the `.HandleKeys` carpet block (M l.
47249–47308), the player's tile arm (raw `100550e8..10055174`); `.HitBoxTileSprite`'s ranges stop below 0x438 (M l.
61551, 61592, 61668).

**Today.** The carpet's own half is not built: `BoxSprite.handleBuilt` returns false for 0x438 / 0x439
(`BoxSprite.swift:472–474`; the doc comment is :463–465, and :147 the Setup's `// later`), so the Handle returns at
once; `:1521, :1594` (no wake). The Box tail is built with the carpet's two exclusions (`BoxSprite.swift:605–621`). **The player's half is built and has never met a carpet:** `Player.riding`
(`Player.swift:368–385`: the carpet flag from the ridden type, the camera latch, vx 0), `HandleKeys.swift:44` /
`:502–539` (`carpetSteering` — the keys drive the carpet), `Shots/CastSpell.swift:48`, `HitPlayerSprite.swift:1054–1055`,
`PlayerTiles.swift:158–172` (the carpet wall arm). The task proves that half against the dump and builds the carpet's
Setup, wake and Handle.

**Contract.**
1. Setup (M l. 59078–59103): cache flag `_DAT_100a0a10`; 0x438: `+0x46 = 0`, no tile hit, rect (0x34, 4, 0x35,
   0xc); 0x439: tile hit set, `+0x46 = R(4) + 2`, rect (0x12, 4, 0x5b, 0x12); both: one-way, gravity 0, `+0x138 = 0`,
   `+0xa6 = 0`, `+0x14c` = record p2·30 (0 → **−1**), `+0x150` = record p1, `+0xb8 = p1 + 0x10000`. `+0x15c` is never
   set here (0 from `.MTNewSprite`'s clear, M l. 30703).
2. Wake (`.HitBoxSprite`, the player against 0x438, M l. 61470–61476): `+0x46 = 2`, type → 0x439, tile hit set,
   `+0x15c = 0x1e`, `+0x185 = 0`.
3. Handle (0x438 / 0x439, M l. 60289–60375), in order: `+0x46 > 0` → + 1; > 11 → 2 (the flying ripple loops cells
   1…5); face cell `+0x46 >> 1`. While `+0x15c > 0`: − 1; then < 16 → vy + 0x1e, else vy − 0x1e (rise 14 frames, then
   sink); vx 0; no tile hit. **While `+0x15c == 0`** (every such frame): one-way, the tile hit back — so the rolled
   0x438, whose Setup cleared the tile hit and never set `+0x15c`, gets the tile hit back on its first Handle. 0x439:
   rect re-set (0x12, 4, 0x5b, 0x12). Ridden (`+0x186`) or already riding (`+0x154`) **and `+0x14c ≥ 0`** →
   `+0x154 = 1`, `+0x14c − 1` (floor 0); then on frames with `+0xa6 < 1` and the paint counter `*_DAT_1009fd2c` & 3 = 0
   (+1 per `.PaintFrameWrap` call, drawn or not, M l. 9250; already carried on `LevelCarry.paintCounter`): `+0xa6` =
   10 when `+0x14c` < 91, else 30; `+0x158 = 6`; `+0xb8 = 0x10009`; at `+0x14c` = 0 → dead (`+0xe9 = 1`) and
   `.ExplodeFaceIntoParticles(face, pos, 1, 2, 4, 100, 100)`; other frames: `+0xa6 − 1`, and the flash steps
   (`+0x158` < 1 → `p1 + 0x10000`; else < 4 → 0x10008, else 0x10009, then `+0x158 − 1`). With `+0x14c` = −1 (level
   22) this whole block never runs: `+0x154` stays 0 and the mode stays 0x10000. vx decays: |vx| ≤ 0x80 → 0, else
   0x80 toward 0. Then **`+0x15c < 1` → vy = fctiwz(vy · 0.8)** (f64 `100a1ae8` = 0.8; `100a1af0` is the int → double
   bias) (M l. 60369–60374). There are no "rider flags" in the arm: `+0x182 = 0` is the Box Handle head's (M l. 60091 — review leg 2 cited 60066,
   every Box, every frame) and `+0x182 = 1` is `.HitBoxSprite`'s (M l. 61467–61468, `PlatformBounce`).
4. The Box tail (M l. 61152–61174): `.ApplyFriction(+0x114)`; `.FootPressure` skipped for 0x438 / 0x439;
   `.EnforceMaxSpeed(0x1838)`; y256 += vy; `.ApplyGravityAndSeparateFromTiles` forced for 0x438 / 0x439 even with
   gravity 0; `.BoxCleanUp`.
5. Player (built): while riding a 0x438 / 0x439 the flag `*PTR_DAT_100a05a4 = 1` and the camera latch (M l.
   44532–44552); the keys steer the carpet (M l. 47249–47308: L/R vx ±0x140, cap ±0xc80; UP/DOWN vy ∓0x100, cap
   ∓4000; the centre-gap close while |vx| < 0x100).

**Seam.** Core only. New writer rows in `Tests/FerazelRenderTests/DrawModeAuditTests.swift`: the mode words
`p1 + 0x10000` (Setup M l. 59102 and the flash end M l. 60342), `0x10009` (M l. 60331, 60349), `0x10008` (M l.
60346) — all but the Setup's reachable only with p2 > 0 (synthetic). Owns types 1080 and 1081 (R1; LL's 6A-BX1c dissolves); the cache set
0x438 is marked here on 6A-CF's record-keyed list.

**First level / golden (R3).** Level 22, after 6A-BD, 6A-MP and LL's 6A-BX1b — the last level-22 feature, so its
fixture is level 22 with every record in, plus one test-only change: the player's start moved beside placement 486,
so the wake happens within the run (named as a test stand-in). `testLevel22CarpetFeatureGolden`: the first frame after
the wake (measured), Mac. Kept at level 22's enterable task (the real first-frame golden starts at the real start and
never reaches the carpet). **Levels 1–5:** no carpet is placed or spawned there; the player's built half runs only
with `w.player.carpet` set, which only a ridden 0x438 / 0x439 sets — no golden moves.

**Tests (12).** `testCarpetSetupRolled`; `testCarpetSetupUnrolledDrawsR4`; `testCarpetWakesOnPlayer`;
`testCarpetRiseAndSink`; `testRolledCarpetGetsTileHitOnFirstHandle`; `testCarpetVerticalDampingAfterBob`;
`testCarpetRideCountAndFlash` (synthetic, p2 > 0); `testCarpetBurstsAtZero` (synthetic, p2 > 0);
`testCarpetLevel22NeverCounts` (p2 0 → −1, `+0x154` stays 0, mode stays 0x10000); `testCarpetSteeringMovesCarpet`
(keys → the carpet's vx / vy, the dump's values); `testCarpetExcludedFromBoxTileHits`; `testLevel22CarpetFeatureGolden`.

**Asserts the build task adds** (10):
- the unroll step: + 1 while > 0, > 11 → 2, face cell `+0x46 >> 1` (M l. 60290–60297).
- the rolled carpet's tile hit back on its first Handle (M l. 60309–60312).
- the 0x439 rect re-set every Handle (M l. 60313–60315).
- `+0x14c = −1` never counts down (the test `-1 < +0x14c`, M l. 60316–60317).
- the flash gate on the paint counter & 3 (M l. 60323).
- the vx decay: ≤ 0x80 → 0, else 0x80 toward 0 (M l. 60357–60368).
- vy · 0.8 when `+0x15c < 1` (M l. 60369–60374).
- `.FootPressure` skipped for 0x438 / 0x439 (M l. 61154–61157).
- gravity and tile separation forced for 0x438 / 0x439 with gravity 0 (M l. 61161–61164).
- the wake's `+0x185 = 0` (M l. 61475).

### 2.12 The falling rocks' player arm, 0x433 / 0x434 (6A-FR)

**What it is.** A falling crate or rock hurts the player it lands on and breaks. (BOS §2.7 read it for the Warrior;
re-read here.)

**Switch.** Box 0x433 / 0x434, never placed; spawned by the Warrior (0x433 ×3), the Wizard (0x434, hovering) and
Xichra's rain (0x434). First level 5.

**Spans.** `.HitPlayerSprite` M l. 49170–49188.

**Today.** `HitPlayerSprite.swift:177` `// later: Phase 6`. The Box arms (`BoxSprite.isBoulder`), `.KillBox`,
`.HurtPlayer` are built.

**Contract.** 0x434 with `+0x160 < 0` → return (nothing else in the routine runs). 0x433 with `+0x160 ≥ 0`: its
centre y < the player's (strict) and vy > 599 → `.HurtPlayer(player, rock, 0x38, blood 1, invul 0x1e, coins 0)` +
`.KillBox(rock)`, return; otherwise fall through to the rest of the routine. 0x434 with `+0x160 ≥ 0`: the same with
0x70 / 0x3c. A 0x433 with `+0x160 < 0` matches none of the three arms (M l. 49173, 49181, 49189 all fail) and falls
through. (The spiked-ball arm right after, M l. 49189–49197, is §3.4.) The arm lives in `.HitPlayerSprite`, not
`.HurtPlayer` (§9 P11).

**Seam.** Core only. Owns the rocks' player arm for 0x433 / 0x434 (1075 / 1076; never placed); their Box arms are
built (`isBoulder`).

**First level / golden.** Level 5, which already opens, so R3's fixture is not needed — but no rock exists there until
6A-W1's real Handle spawns the Warrior's crates, so there is no feature golden: the arm is proven by synthetic Core
tests, and 6A-W2's scripted fight (BOS §9.1) is its first frame proof. **Levels 1–5:** no 0x433 / 0x434 exists on any
of them before 6A-W1, so the new arm is never entered — no golden moves.

**Tests (5).** `testRock433HurtsWhenFallingOnPlayer`; `testRock434HurtsHarder`; `testRock434NegativeReturnsEarly`;
`testRockSlowOrBelowFallsThrough`; `testRockBoundaries` (a 0x433 with `+0x160 < 0` falls through; equal centre y falls
through; vy 599 falls through, 600 hurts). Lands before 6A-W1 (BOS §9.1).

**Asserts the build task adds** (3):
- 0x433 with `+0x160 < 0` falls through all three arms (M l. 49173, 49181, 49189).
- the strict `<` on the centre y (M l. 49174, 49182).
- the threshold `599 < vy` (M l. 49175, 49183).

### 2.13 The player's boss-stagger arm (owned here; built inside 6A-CH1)

**What it is.** When the Goblin Chief (or Xichra) knocks the player, the player is stunned for a count of frames:
slowed, shown in a stagger pose, unable to act.

**Switch.** `*_DAT_100a0570 > 0` (written by the Chief and Xichra; BOS §3.3, §6.3). First level 18.

**Spans.** `.HandlePlayerSprite` M l. 45591–45632 (re-read: `iVar32 = *_DAT_100a0570`, vx × 0.5 via f64 `100a1a28`
at M l. 45594–45597, the face index `((c mod 12) >> 1)` at M l. 45596).

**Contract.** BOS §3.7 transcribes it in full (vx × 0.5; face from `*_DAT_100a0784` by (c mod 12) >> 1 → +0, +0x34, +0,
+0x68, +0x9c, +0x68; the standing / cling / spin clears and the spin-sound stop; `_DAT_100a071c = 0`; jump to the end
of the state chain). The count-down, `.HandleKeys`' early return, the shot zeroing and `.ClearPlayerVars`' zero are
built.

**Seam.** Core only (`PlayerStates.swift:372`; that comment cites "l. 45625–45672", but the arm is M l. 45591–45632 —
45625ff is the next arm; BOS P7). **Golden.** The Chief's scripted kill (6A-CH2), on CH's level-18 fixture (R3).
**Levels 1–5:** `_DAT_100a0570` has no writer on them (the Chief and Xichra only) — no golden moves. **Tests (3)**,
inside 6A-CH1's 10 (BOS §9.1): `testStaggerSlowsAndPoses`, `testStaggerClearsStates`, `testStaggerSkipsStateChain`.

**Asserts the build task adds** (2):
- the spin-sound idle test goes through `SoundVoices` (BOS §3.7; M l. 45591–45632).
- `fctiwz` of a negative vx truncates toward zero (vx × 0.5, M l. 45594–45597).

### 2.14 The fireball cache by record (inside 6A-CF, R2)

**What it is.** One picture (0x46a) is cut three ways into three cache records; the shot types read different records.

**Switch.** EnemyShot 0x46a (spawned by the Wizard, the guardians, Xichra); 0x46b / 0x46c are spawned by nothing
(dead types; their arms exist).

**Spans.** `.InitEnemyShotSprite` M l. 51434–51436 (record `_DAT_100a0848` = 0x46a cut 6 × 48×48; `0844` = 6 × 64×64;
`0840` = 6 × 64×64); `.HandleEnemyShotSprite` 0x46a arm M l. 51822–51845 (face cell `+0x46` 0…5 from `0848`; on a
non-flame level R(3) + 5 sparks, each R(36) x, R(36) y, R(2) shape, `.NewParticle(1, 0xbe, …, shape + 1, 0, 0, 0,
1)`), 0x46b 51846–51853 (`0844`), 0x46c 51854–51861 (`0840`).

**Today.** Faces are keyed by picture only (`EnemyShot.swift:381, :400`; `LevelRun.swift:1216–1251`).

**Contract.** Key cached faces by cache record, not picture: three records for 0x46a; each Setup marks its record
(BOS: the Wizard marks only `0848`; the Demon all three). **The two 64×64 cuts are the same pixels** (same picture,
same arguments) — they differ from the 48×48 cut, not from each other (§6 E9).

**Seam.** Core (`CachedFaces`) + Render's face store reads the key; no seam type change if the record is carried in
`FaceRef.pict` space by the existing registration (the build decides; if a case is needed it is a `FaceSetKind`
case, lockstep). **R2:** this is not a task of its own — the record keying is LL's 6A-CF (the whole 285-record
registration list keyed by record), and these three tests join CF's.

**First level.** Level 25 (the Wizard) — **no 6A level needs it** (BOS D15); CF runs before the first 6A level task
(LL §8(b)), which covers the plan's "before 6A-W" order. **Levels 1–5:** no 0x46a…0x46c is spawned on them, and CF
keeps levels 1–5's load-bar steps (LL) — no golden moves. **Tests (3, inside CF's 6).** `testFireballCutsByRecord`
(0x46b / 0x46c draw the 64×64 cut and 0x46a the 48×48 cut, each by its own record; the two 64×64 cuts equal);
`testShot46bReadsRecord0844`; `testCacheMarksPerRecord`.

**Asserts the build task adds** (2):
- 0x46c reads record `0840`, not `0844` (M l. 51854–51861).
- the 0x46a arm's sparks draw R(3) + 5 then three numbers each on a non-flame level (M l. 51822–51845) — the Handle
  arm's, first reached by 6B-WZ; CF pins only the record reads, and 6B-WZ adds this assert.

---

## 3. Phase 6B (levels 25–52) — complete as to span, switch, seam, level, golden, tests

Test counts in §3 and §4 are sizes; the test **names** are owed by the 6B and 6C planning runs, except where a section
names them. Every golden plan in §3 and §4 means Mac **and** the Windows reference (`WinReferenceFramesTests` + the
smoke script copy) unless it says otherwise, and follows R3 when its feature is built before its level opens.

### 3.1 Programmed-path cannons, p1 < 0
Switch: Background 0x442… p1 −1 / −2 — **L40** ×36 (0x442 −1 ×19, −2 ×2; 0x444 −1 ×2; 0x445 −2 ×1; 0x446 −2 ×4; 0x447
−1 ×2; 0x448 −1 ×6), L62 ×13 (p2 200…480, p3 1200…3600). Spans: Setup M l. 62067–62118
(p1 < 1: `+0x188 = 1`, `.SetupProgrammedPath(s, −1, 0)`; |p1| = 1 → p4 == p2 reverses `+0xf8`, vx, vy, then y256 +=
p4·256; |p1| = 2 → the same on x; pixel copies to `+0xc/+8`, `+0xa/+6`; launch speed 0x1fa4); Handle M l. 62975–62981
(`.HandleProgrammedPath`, x256 += vx, y256 += vy). Today: refused at Setup. Seam Core only. Golden: level 40 (its
task; a level-40 fixture by R3 if it is built before level 40's enterable task). Tests (4): setup modes 1 / 2, the
p4 == p2 reversal, the Handle move — named by 6B's planning run. Could ride with §2.10 (one task, the two arms share
`ProgrammedPath`); the plan's 6A-BX1 card mixed this 6B arm (level 40) with the 6A rotating arm (level 10) — they are
separate (§9 P4).

### 3.2 The level-wide liquid flag and ice (6B-ICE — prove)
Switch: hdr `0x26cd` = 1 on L30, L31; `0x2710` 220 there (80 on L11, L18; 100 on L1, L2 — built). Dump readers:
M l. 44858 (player), 59493 (Box 0xb7c), 62004, 62051, 62191, 62203, 62213, 62300, 62482 (Background arms), 70207 (Frog).
Port readers: `PlayerLiquids.swift:27`, `BoxSprite.swift:314`, `BackgroundSprite.swift:280, :882`,
`SetupFaces.swift:636` — the build maps the seven Background sites to their arms (several belong to arms not built
yet, e.g. fire) and pins each. Seam none. Golden: level 30 first frame (its task). Tests (3).

### 3.3 Countdown digits (6B-TM)
Switch: Box 2907 (0xb5b) p1 300 on **L40** only. Spans: `.SetupDigitSprite` M l. 53864–53879; `.UpdateDigits`
53900–54023 (124); the 0x4c4 Effect arm of `.HandleEffectSprite` (FerazelSession.swift:378 notes the faces stay 0
while `iRam100a5110`); the Box 2907 arms (skimmed — re-derive at its planning run). Today: digits `.inert`
(`FerazelSession.swift:388`). Seam: Core + the digit faces in the boot list / cache at the original position. Golden:
level 40, the frame the timer first shows and the frame it reaches 0. Tests (~6).

### 3.4 Spiked balls 0x5c3 / 0x5c4
Switch: Box 0x5c3 (1475) on **L45** ×12, L62 ×1; 0x5c4 spawned by Xichra's rain (BOS §6.6). Player arm M l.
49189–49197 (both types: R(100) < 0x33 → 0 coins else 5; `.HurtPlayer(0xa8, blood 1, invul 0x3c)` — **one R(100) per
contact frame**); Box Setup / Handle arms skimmed — re-derive at its planning run (`BoxSprite.swift:147, :465`). Seam
Core. Golden level 45. Tests (~5).

### 3.5 The snowball 0xbfe
Switch: Box 3070 on **L31** ×3. Spans: Setup M l. 59500ff, Handle 60950ff, `.GenerateSprite` M l. 1741 (excluded from
a list with 0x433); skimmed — re-derive at its planning run. Seam Core. Golden level 31. Tests (~4).

### 3.6 CLUT animation (6B-CA ⚑)
Switch: hdr `0x2730` mode, `0x2732` n, `0x2734` period, `0x2736` amplitude: L50 1 / 48 / 180 / 12000; L51 1 / 48 / 56 /
12000; L67 3 / 16 / 75 / 12000, then rewritten every frame by Xichra (modes 3…7, M l. 76648, 76667, 76697, 76728,
76750, 76790). Spans: `.AnimateCLUT` M l. 8926–9103 (178; raw `1001180c..10011cd4`), called on **every
`.PaintFrameWrap` call** before the drawn test (M l. 9231, raw `10011ef4` — the pause's and the quit dialogs' extra
calls included, M l. 3190, 3918, 3922, 3980, 4005) and once at level entry, before the tint tables (M l. 5206–5208).

The step (re-derived by review leg 1 from the raw; agrees with bosses-3 §9.2 except two points, corrected there):
1. n = hdr `0x2732`; n == 0 → return before anything (so the timer advances only on levels 50, 51 and 67).
2. P = hdr `0x2734`, A = `0x2736`; mode 4 → P = fctiwz(P·0.8); 5 → P·0.6; 6 → P·0.3 and A = fctiwz(A·1.28) (f64
   `100a1620` / `1618` / `1610` / `1608`).
3. t = `*_DAT_100a00e8` + 1; t ≥ P → 0 (raw `10011940..1001195c`). **A data-section global with no other writer** (its
   only accesses are M l. 8961, 8986): never reset by a level load, a death, the map or a new game, so it carries from
   level 50 → 51 → 67, through restarts, and ticks on the pause's and the dialogs' extra paints. It rides `LevelCarry`
   (beside `parity` and `paintCounter`), and every golden of those levels depends on it.
4. Gate (prefs + 6, raw `10011968..100119a4`): 3 → skip; 2 → skip unless `*_DAT_1009fd98 & 3 == 0`; 1 → skip unless
   the parity `*_DAT_1009fd30 == 0` (`fd30` flips only on drawn frames, M l. 9435–9440, after this call). t has already
   advanced. The gate decides both the palette push **and** mode 6's n × R(4000) draws (they are inside it).
5. For i = 255 − n … 254, only when 1 ≤ mode ≤ 7: θ = (t·360)/P (signed `divw`), folded into 0…359; (R, G, B) = entry
   i of the base CLUT `*_DAT_1009ff8c` (+10 / +12 / +14); **w = ((A·S[θ]) / 256, truncating toward zero) >> 8
   (floor)** (raw `10011a74 mullw`, `a78 srawi 8`, `a7c addze`, `a80 srawi 8`) — not `(A·S) >> 16`: a negative
   product that is not a multiple of 256 comes out one higher; S = `_DAT_100a00e0` (`.MakeRadialTables`, built on
   first use). Mode 1: R = max(R + w, 0); 2: d = w − A, R −= d, G −= d, B −= d; 3…7: D = R + (w − A), E = B + D,
   R′ = fctiwz(0.7·D), B′ = fctiwz(0.7·E), G unchanged; 4: G = fctiwz(0.5·B′), B = 0, R = fctiwz(2.1·R′) + 7000; 5:
   G = B = 0, R = fctiwz(2.5·R′); 6: g = (R′ + B′ + G)/3 − R(4000) (one draw per entry), all three = g; 7: R = B = 0,
   G unchanged. Each clamped to 0…0xffff and stored into the working CLUT `*_DAT_1009fe94` (M l. 9010–9093).
6. `SetEntries(0, 255, working + 8)` — all 256 entries, even when the mode is outside 1…7 (M l. 9097).

**The level-start call** (M l. 5206) recolours the working CLUT that `.BuildTintTable` / `.BuildReddenTable` read next
(M l. 5207–5208; `.BuildTintTable` reads `*_DAT_1009fe94`, M l. 17647ff): 6B-CA feeds levels 50 / 51 / 67's tint
tables from that one step (`LevelTables.forLevel` takes a `workingClut` for this, `FerazelRender/Frame/LevelTables.swift:14–17`), not only
the screen palette.

Today: the `FastRand` count is built (`FerazelSession.animateCLUTDraws`, `FerazelSession.swift:292, :353`); the palette
change is not; `LevelTables.swift:16` notes the tables are exact only where n = 0. Seam: Core drives it (it draws from
the stream and `0x2730` must be a **Core-writable** value: `LevelRun` holds a parsed, immutable header today — a
mutable copy of the four fields in Core state, shared by this task and 6C-XI; the timer on `LevelCarry`); Render
applies it. An op that sets screen CLUT entries already exists — `ScreenGammaOp.clut(entries:)` (`.TurnGray`,
`ScreenRenderer.swift:99`) — but `FrameRenderer` ignores `.screenGamma` in level frames (`FrameRenderer.swift:479`):
the planning run weighs teaching `FrameRenderer` to execute it into `screenClut` against **a new shared DrawOp case**
carrying the step (or the new entries); either way both shells' present paths take a palette that changes every frame.
Golden: level 50, frames 1 and P (the build measures); level 51 (the timer carried from 50). Tests (~8):
`testClutStepModesOneToSeven`; `testClutWaveRounding` (a negative A·S not a multiple of 256); `testClutTimerCarriesAcrossLevels`
(50 → 51 → 67, a death, the map); `testClutGateEffectsLevels` (prefs 1 / 2 / 3; t advances when skipped);
`testClutMode6DrawsPerEntry` (n draws, only when the gate passes); `testClutEntryStepFeedsTintTable` (levels 50 / 51 /
67's tables from the one step); `testClutExtraPaintsTick` (pause, quit dialog); the level-50 golden.

### 3.7 Auto-scroll and the fire-wall markers (6B-AS ⚑)
Switch: hdr `0x272a` = 1 with `0x2726` x 768 (L51) or `0x2728` y 640 (L52). Spans: `.SetupLevelSprites` M l. 2055–2099:
`0x272a ≠ 0` → `*_DAT_1009fec8 = 1` and the on flag `*_DAT_1009fec4 = 1` (M l. 2060–2061; 0 otherwise); x > 0 → dir 2, speed x, **4 markers 0x4bb**; x < 0 → dir 1, speed −x, 4 ×
0x4bc; x = 0, y < 1 → dir 3, speed −y, none; y > 0 → dir 4, speed y, **7 markers 0x4bd** — each `.MTNewSprite(type, 0,
0, layer 32000, record 0x1ff, setup)`; the markers are the Background fire arms 0x4bb…0x4bd (Setup M l. 62221–62260,
Handle 63119–63135); `.FindUpperLeftCorner`'s auto-scroll arm (skimmed — re-derive). Two player arms belong here too:
**the auto-scroll death** in `.PlayerConstraints` (raw `1004cd90..1004ce3c`): while `*_DAT_1009fec4` ≠ 0, with mode
`*_DAT_1009fec0` 2 and the player's x < H − 64, 1 and x > H + 672, 4 and y < V − 100, or 3 and y > V + 448 → G+6 = G+4
= 0, the player's `+0xa4 = 0`, `*_DAT_100a0568 = *_DAT_100a0564 = 1` (port: `Player.swift:779, :812`, `// later:
auto-scroll levels`; only the arena lock of that routine is built, LV5); and **the looped ambience** in
`.HandlePlayerSprite` (M l. 44489–44531): while `fec4` is on, if no voice plays `*_DAT_1009fe20` →
`.STPlayLoopedSound(*fe20, 0x14, 0x100)`, the handle kept in `PTR_DAT_100a0534`; mode 2 → volume from the player's x
distance past the scroll (0x300 − d, ÷ 3, capped 0x100; the second channel ÷ 2), mode 4 → from y (0x200 − d, ÷ 2),
each through `FUN_10091a60` (get) / `FUN_10091890` (set) on the playing voice; `.Pause` stops `fe20` too (M l. 3202)
(port: `Player.swift:161–162`). It needs 6A-RN's loop cue plus a "set the volume of a playing loop" cue. Today:
`Camera.swift:58` and `SetupFaces.swift:820` throw. Seam Core (+ the volume cue: shared, both mixers). Golden: levels
51 and 52, first frame and a later frame (measured). Tests (~8 + 2: `testAutoScrollDeathEachDirection`,
`testAutoScrollAmbienceVolume`).

### 3.8 The fire backdrop and flame buffer (+ placed fire 0x4b8) (6B-FI ⚑)
Switch: hdr `0x2722` 1 (L52), 2 (L55). Spans: `.LoadCoolingMap` M l. 275–291; `.FlameCreate` 71745–71805,
`.FlameAddSpark` 71806–71827, `.FlameAddLine` 71828–71870, `.FlameUpdate` 71871–71893, `.FlameDispose` 71894–71914,
`.FlameUp` 71915–72160, `.MyNewPixMap` 72161–72209, `.MyRandomizePixmap` 72210–72245, `.MyRandom` 72266–72275 (its own
generator — never the game stream); `.DoubleBlitPPCParallaxOneLayerFire` 12543–12853 (311); `.DoubleBlitUniversal`
18952–18954; `.CalcPxRowContents` 23163; `.SetupLevel` M l. 2542 (the flame buffer's creation); per `.PaintFrameWrap`
(M l. 9232–9247, every call): mode 2 → `.FlameAddLine(buf, h − 3)`, `.FlameUpdate(buf, 1)`, `.FlameUpdate(buf, 0)`;
mode 1 → `.FlameAddLine(buf, h − 1)`, **R(0x60) then R(0x280)** (game stream), `.FlameAddSpark(buf, x = R(0x280),
y = R(0x60), 0xfe)`, `.FlameUpdate(buf, 1)`; the 0x46a sparks on a flame level (`.HandleEnemyShotSprite` M l. 51883).
Bank: lighting-tables §9, rendering-omnipx-titles §1.6 (not re-derived here — re-derive at its planning run). The
placed fire 0x4b8 (Background, L40 ×1, L50 ×43, L51 ×3, L62 ×38, L67 ×4: Setup M l. 62017ff, Handle 63103ff,
`.HitBackgroundSprite`) belongs with it or with the L40 task. Today: `ParallaxBlitter.swift:129` refuses; `EnemyShot.swift:245`
stub. Seam: Render (the backdrop) + Core (the two game-stream draws a frame, the shot sparks); no new seam type if
the flame spark writes travel in an existing op — the build decides. Golden: level 52 first frame and frame 30; level
55 in 6C. Tests (~12).

---

## 4. Phase 6C (levels 55–70, victory)

### 4.1 OmniPx interlace (mode 6)
Switch: hdr `0x26c7` = 6 on **L70** only. Spans: `.InterlaceBlit128` M l. 13298–13392; `.UpdateOmniPx` M l. 13437–13446
(c + 1, ≥ 58 → 0; cell 1 + (c >> 1) copied over the port on rows c & 1, c & 1 + 2, …; the dump's table is
`0x100a4f18 + (c >> 1)·4` — the cell base is confirmed at the build); **c advances only on drawn frames**
(`.UpdateOmniPx` is called at M l. 9434, inside the drawn test); `.TurnOnOmniPx` keeps the level factors for mode 6. Today: `OmniPx.swift:183` stub; refused at level open. Seam Render + Core's counter `c`
(rides `LevelCarry`). Golden: level 70, two consecutive frames (both parities). Tests (4).

### 4.2 The End key in the guardians' Handle
`.HandleDemonSprite` M l. 74616–74619: `.IsPressed(0x77)` (End) → HP `+0xa4 = −1` — ungated by the debug flag (the
debug keys in `.HandleKeys` M l. 47140ff sit under `*_DAT_100a0064`; this one does not). A shipped cheat: transcribe
it. Seam: Core reads the key; **both shells' key maps must deliver 0x77** (check `KeyState` / the Windows map).
Tests (1): `testEndKeyKillsGuardian`.

### 4.3 The guardians-alive global `*_DAT_1009fecc`
Writers: `.SetupLevelSprites` M l. 2017ff (cleared with the arena globals), `.SetupDemonSprite` M l. 74478 (= 2),
`.KillDemon` M l. 74982ff (counted down). A new Core global beside `BossArena` (the counting window rules apply).
Tests (2).

### 4.4 Conversations started inside a sprite Handle
`.HandleXichraSprite` calls `.Conversation(0xfb / 0xfa / 0xfc = 251 / 250 / 252, record, sprite)` at M l. 76661,
76803, 77131; the rest of that Handle runs after the conversation returns (BOS §6.6). The port suspends conversations
only from the player's hint path; 6C-XI makes the handle pass suspendable at a sprite Handle and resume mid-Handle
(flow state in `LevelRun`, Invariant "nested blocking loops become explicit states"). The sign path (`.HitPlayerSprite`
M l. 49300) is built. Tests (3).

### 4.5 Victory, the stitch and the credits (6C-VI)
Spans: `.CopyVictoryStitch` M l. 5382–5489 (108), `.CreditScreen` 5490–5553 (64), `.Victory` 5554–5703 (150). Flag
`*_DAT_1009ffc4` (cleared `.InitGameGlobals` M l. 615; set by Xichra's death M l. 77190; also by the debug key F8 in
`.HandleKeys` M l. 47150–47153, under the debug flag — not built, by design) and `DAT_100a5106`; read by `.NewGame` /
`.ContinueGame` (M l. 5737 / 6697 locals; the test sites the plan cites). Pictures PICT 4600–4607, music track 29
(resources-classified "future phase"). Today: `NewGame.swift:22, :178` (`// later`). Seam: a `GameFlow` state (Core)
+ the front-end picture ops (built kinds). Golden: one per screen (Mac + Windows). Tests (~6). Full read of the three
routines owed at 6C's planning run (skimmed here: spans and flags only).

---

## 5. Unreachable as shipped (kept refused or not transcribed, each pinned by a data test)

| item | why it never runs | pin |
|---|---|---|
| `.RipplePxBackOffsets` (M l. 8889–8925) | its only call (M l. 9197–9199) needs hdr `0x271e` ≠ 0, 0 on all 24 levels (rendering-omnipx-titles R3 correction 4); levels 11/18's ripple is §2.5 | `testNoLevelSetsParallaxMode` |
| rope bridge 1466 (0x5ba), `.GetRopeBridgeHeight` (M l. 58875–58891) | placed on no level, spawned by nothing (`.GenerateSprite` M l. 1890 handles a placed 0x5ba only) | `testRopeBridgeUnplaced` |
| table 0xb71 (Box Setup M l. 59403, Handle 60794) | placed on no level, no spawner | `testTableUnplaced` |
| water kinds 206–209 | no BG tile of those kinds on any level (census: kinds 200–205 only; 205 first on L22, 202 on L50) — the water tables 6…9 refusal stays | the existing audit row, widened to all 24 levels |
| Background 0x73f / 0x740 (and their `.HitPlayerSprite` arm, M l. 49753–49760) | placed on no level | `testUnplacedBackgroundArms` |
| tree 0xc0f (3087) and its solid 0xc09 branch | placed on no level (§2.4) | in §2.4's tests (`testBranchBoxArm`, synthetic) |
| cannons p1 1…100, ≥ 107 | no shipped record (§2.3) | in §2.3's tests |

---

## 6. Disagreements (dump wins)

| # | where | said | the dump / the data | evidence |
|---|---|---|---|---|
| E1 | BOS §6.6, §9.1 (rotating cannon arm → 6C-XL) | built by the lair task | first placed on **level 10** (records 89, 108, 200, 250), also 15 and 20 — a 6A feature; 6C-XL reuses it | §2.3 census |
| E2 | spec 3.2 / plan 6A-T11 "tinted submerged tiles — not built" | not built | all seven readers are built; only a proof is owed | §2.6 |
| E3 | spec 3.2 / plan 6A-RP / tsv "parallax ripple → `.RipplePxBackOffsets`" | that routine makes the ripple | it is gated on hdr `0x271e` (0 everywhere) and never runs; the ripple of 11/18 is `.PaintFrameWrap`'s inline loops | M l. 9197–9199, 9211–9226, 9255–9425 |
| E4 | spec 3.2 / plan 6A-RN "the side push `0x272c` — not built" | not built | built (`Player.sidePush`), untested with v ≠ 0 | M l. 46347–46365 |
| E5 | tsv rows `.LookupModedImpulse`, `.SetupProgrammedPath`, `.HandleProgrammedPath`, five OmniPx rows, dart traps | not built / partial | built (E1b, BA/GF, OX, ES) — the ledger predates them | §1 |
| E5a | tsv rows `.PlayerConstraints` ("built" at LV5), `.AnimateCLUT` ("built", classified by citation), `.STPlayLoopedSound` ("built", cited) | built | **partial**: the auto-scroll death arm is not built (§3.7); the palette change is not built, only the draw count (§3.6); the looped play has no cue (§2.7) | raw `1004cd90..1004ce3c`; M l. 8926–9103; M l. 40978ff |
| E6 | port comments `WaterEffects.swift:40, :311` "wind exists only on levels 10, 20 and 52" | (not wrong: said of the wind *dust*, o1 < 36) | a precision for the planner: 52's 84 cells are dust-only (o1 27); the **pushing** wind (o1 ≤ 15) is on 10 and 20 only | §2.2 census |
| E7 | world-data-format §3.3 (wind) | (silent on the gates) | on h < 0, v < 0 directions the x and y gates are crossed — appended there as a dated correction | raw `10036a98..10036a9c` |
| E8 | spec 3.2 / plan "level-wide liquid flag — not built" | not built | the player, Box, Frog and built Background readers are built; only arms not yet built remain | §3.2 |
| E9 | plan 6A-FB "a test that the three cuts differ" | three different cuts | two cuts: 48×48 (`0848`) and 64×64 twice (`0844`, `0840`, identical arguments) | M l. 51434–51436 |
| E10 | plan 6A-FB "before 6A-W" as a dependency | prerequisite | not needed by any 6A level (BOS D15 agrees) | §2.14 |
| E11 | spec 3.2 "water kinds 206–209 — later" | a later level needs them | no level has them | §5 |
| E12 | spec 3.2 "rope bridge … table … 10–62" | placed on later levels | 1466 and 0xb71 are placed nowhere; carpet only on 22, snowball only on 31, spiked balls 45 / 62, trees 10 / 11 / 15, clouds 20, blade 20 / 22 / 30 / 62 | §2, §3, §5 |
| E13 | BOS §6.6 "spiked ball 0x5c4 … `.HitPlayerSprite` arm (M l. 49189–49197)" | the 0x5c4 arm | the arm covers 0x5c3 and 0x5c4 (`type − 0x5c3 < 2`) | M l. 49189 |
| E14 | card ENG "the 27 later-level routines" | a literal label | no tsv row says "later-level"; the 27 are nine reason phrases (§1); with the 4 non-boss Phase 6 rows the set is 31 | §1 |
| E15 | plan 6A-WD files "`Player/PlayerTiles.swift`, `Physics/`" | the player's tile code | the branch is `.StandardSpriteHandles`' (`Physics/StandardSprite.swift:60`) and moves every wind-scaled sprite, not only the player | M l. 32489 |
| E16 | rendering-omnipx-titles §3.6 "SetupLevel clears it after SetupOmniPx" | the only clear | `.Pause` (M l. 3203) and `.GameLoop`'s exit (M l. 5300) clear it too; the pause's and the quit dialogs' extra `.PaintFrameWrap` calls run the rain once more | M l. 2541, 3190, 3203, 3918, 3922, 3980, 4005, 5300 |
| E17 | bosses-3 §9.2 step 5 "w = (A·S[θ]) >> 16"; "every painted frame" | a 16-bit shift; painted frames | the first /256 truncates toward zero (`srawi 8; addze`), then `>> 8` floors — one higher for a negative product that is not a multiple of 256; it runs on every `.PaintFrameWrap` call, drawn or not | raw `10011a74..10011a80`; M l. 9231 |
| E18 | port comment `PlayerStates.swift:372` "l. 45625–45672" (the boss grab) | that span | the arm is M l. 45591–45632 (45625ff is the next arm) — BOS P7 | M l. 45591 |
| E19 | the port's mace spawn (`SetupFaces.swift:888–898`) | a chain for every mace | `.MakeRadial` / `.MakeRadiusSprites` only for modes 10–14 — latent until 6A-MP opens modes 1–2 | M l. 62362–62420 |
| E20 | review leg 2 finding 3 "`+0x182 = 0` is the Box Handle head's (M l. 60066)" | M l. 60066 | M l. 60091 (after `.StandardSpriteHandles`); the substance holds | M l. 60091 |

Dated corrections are appended (2026-11-11, this fix round) to `world-data-format.md` §3.3 (E7, the crossed wind gates),
`rendering-omnipx-titles.md` §3.6 (E16) and `bosses-3.md` §9.2 (E17). No disagreement was found with
`lighting-tables.md`, `draw-effects.md` or `particles.md` in what was re-read (the strip blitter §2.5, the mask pass
§1.2, the rain particle rows §5.1 all agree with the dump), so nothing is appended to them.

---

## 7. For the planner

### 7.1 The 6A build order (R1–R3; with LL §7–§8 and BOS §9) — the list the 6A planner starts from

Every 6A task once, in order. "Tests" is the task's new Core tests (G2); **est.** marks a size this bank does not fix
(the planner sets it, sized like the neighbouring files); a level task's count is net of the feature goldens it deletes
(R3). ⚑ = MAJOR (two Opus legs); ◈ = may move a golden, only for its named cause, with the switch-off check. "Shared /
Windows": **shared** = a seam type or shell source changes (both shells in the task, lockstep (a)); "gates" = Core or
Render only, the Windows gates GW1–GW4 + G5 still run (lockstep (b)). The ladder starts at **620** (G2 at run 47,
2026-11-10).

| # | task | what | needs | tests | marks | shared / Windows | Core after |
|---:|---|---|---|---:|---|---|---:|
| 1 | 6A-BL | the built-level list (plan card) | — | 2 est. | | **shared** (`Shared/FerazelDriver.swift`, both scripts) | 622 |
| 2 | 6A-CF | the picture cache in full, keyed by record (LL §8(b)1), **with 6A-FB's three tests (R2, §2.14)** | BL | 6 (3 + 3) | | gates | 628 |
| 3 | 6A-FR | the rocks' player arm (§2.12) | — | 5 | | gates | 633 |
| 4 | 6A-W1 | the Warrior's Handle (BOS §2, §9.1) | FR | 9 | ⚑ ◈ (level 5's goldens, the real Handle) | gates | 642 |
| 5 | 6A-W2 | the Warrior's Hit / Kill / fight (BOS) | W1 | 8 | ⚑ ◈ | gates | 650 |
| 6 | 6A-S8 | the horizon strip (§2.1) — first of the level-10 features | — | 11 | ⚑ | **shared seam type** (`FaceSetKind`; no shell source) + feature golden both shells | 661 |
| 7 | 6A-WD | wind (§2.2) | S8 | 9 | | gates | 670 |
| 8 | 6A-RC | rotating cannons (§2.3) | S8 | 10 | | gates | 680 |
| 9 | 6A-TR | trees + the shared `flipHRect` (§2.4) | S8, CF | 10 | | gates | 690 |
| 10 | 6A-RP | the ripple (§2.5) + the T11 proof (§2.6) | TR | 9 (7 + 2) | ⚑ | gates + feature golden both shells | 699 |
| 11 | 6A-BX1a | Box scenery, 19 types (LL §8(a); reuses TR's flip) | TR, CF | 4 est. | | gates | 703 |
| 12 | 6A-BX1b | Box faces + talkers, 6 types (LL §8(a)) | CF | 4 est. | | gates | 707 |
| 13 | 6A-MC | conversations + chapter cards for 10–22 (plan card) — before the first level task, so each level's goldens follow its card | — | 3 est. | | card goldens both shells | 710 |
| 14 | 6A-L10 + L11 | levels 10 and 11 enterable (the pair, LL §8(c)) | S8, WD, RC, TR, RP, BX1a, BX1b, MC | 6 est. (8 − the WD and RC feature goldens) | | first-frame goldens both shells; bot, sweep | 716 |
| 15 | 6A-RN | rain, thunder, side push (§2.7) | RC, TR, BX1a | 12 | ⚑ | **shared** (`SoundCue` field + `Shared/FerazelAudio.swift` + the Windows audio test) + feature goldens both shells | 728 |
| 16 | 6A-BG1c | plants, 5 types (LL §8(a)) | CF | 3 est. | | gates | 731 |
| 17 | 6A-L15 | level 15 enterable | RN, BG1c | 3 est. (4 − the rain feature golden) | | goldens both shells; bot, sweep | 734 |
| 18 | 6A-CH1 | the Chief's class, Setup, Init, Handle + the stagger arm (BOS §3, §9.1; §2.13) | RP, BG1c | 10 | ⚑ | gates | 744 |
| 19 | 6A-CH2 | the Chief's Hit / Kill / pieces / fight (BOS) | CH1 | 8 | ⚑ | gates | 752 |
| 20 | 6A-L18 | level 18 enterable | CH2 | 4 est. | | goldens both shells; bot, sweep | 756 |
| 21 | 6A-CL | clouds (§2.8) | WD, RC | 7 | | gates | 763 |
| 22 | 6A-BD | the blade (§2.9) | CL | 13 | | gates (+ Render audit rows) | 776 |
| 23 | 6A-MP | mace paths (§2.10) | BD | 7 | | gates | 783 |
| 24 | 6A-L20 | level 20 enterable | CL, BD, MP | 3 est. (4 − the MP feature golden) | | goldens both shells; bot, sweep | 786 |
| 25 | 6A-L21 | level 21 enterable, with the pipes' level-spawn wiring (plan card) | BX1a, BX1b | 4 est. | | goldens both shells; bot, sweep | 790 |
| 26 | 6A-CP | the carpet (§2.11) | BD, MP, BX1b | 12 | | gates | 802 |
| 27 | 6A-L22 | level 22 enterable | CP | 4 est. | | goldens both shells; bot, sweep | 806 |
| 28 | 6A-END | the phase end (plan card) | all | 0 | | both shells | **806** |

Totals: 6A adds **186** Core tests (620 → **806**), of which this document's features are 105 (S8 11, WD 9, RC 10, TR
10, RP 9 with T11's 2, RN 12, CL 7, BD 13, MP 7, CP 12, FR 5 — the `DrawModeAuditTests` entry in S8's, RP's and RN's
lists is a row of an existing test, not a new one, so the §2 counts are one higher there) plus the 3 inside CF
(§2.14); BOS's boss tasks 35 (the stagger's 3, §2.13, inside CH1's 10); LL's type tasks and CF's own 3, the
built-level list, the conversations and the levels 43 est. The ladder assumes each "kept unless frame 1" feature golden
is kept (S8 and TR on 10, RP on 11, CL and BD on 20): each one the build measures at frame 1 is deleted by its level
task instead, so the end can be up to 5 lower (801). Ordering rules behind the list:
S8 is first of the level-10 features because its task removes the strip's level-open refusal (the other level-10
fixtures then open) and shifts the sprite-slot ids they measure; each fixture leaves out only what is still unbuilt
at its place (§7.2), so moving a task changes its fixture and the planner re-reads §7.2; every feature precedes its
first level's enterable task; LL's type tasks precede the levels whose records they set up (LL §7 deps). 6A-W1/W2
are the only ◈ tasks: no feature task moves a golden of levels 1–5 (each section's "Levels 1–5" line).

### 7.2 Refused records per level and what each fixture leaves out

The per-record counts are LL §7's dependency table, re-owned under R1 (401 records on 10–22, unchanged):

| level | refused today | by owner (R1) | header switches (level-open refusals) |
|---|---:|---|---|
| 10 | 31 | TR 13, RC 4, BX1a 14 | strip (S8 removes it), wind (WD; no refusal) |
| 11 | 35 | TR 8, BX1a 26, BX1b 1 | ripple (RP removes `Refusal.ripple`), T11 (built) |
| 15 | 38 | TR 10, RC 3, BG1c 22, BX1a 3 | rain (RN removes the mode-1 refusal), side push (built) |
| 18 | 6 | BG1c 5, CH 1 | ripple (RP), the Chief's arena switches (CH) |
| 20 | 209 | CL 164, RC 1, BD 28, MP 16 | wind (WD) |
| 21 | 30 | BX1a 7, BX1b 17, the L21 pipe wiring 6 | — |
| 22 | 52 | BD 13, MP 29, BX1b 9, CP 1 | — |

What each feature task's fixture leaves out, in the order of §7.1:

| task | fixture level | records left out (still unbuilt there) | refusal the task removes |
|---|---|---|---|
| 6A-S8 | 10 | TR 13, RC 4, BX1a 14 (31) | `LevelOpenRefusal.horizonStrip` |
| 6A-WD | 10 | the same 31 | — |
| 6A-RC | 10 | TR 13, BX1a 14 (27) | `SetupFaces.swift:380` (p1 ≠ 0) |
| 6A-TR | 10 | BX1a 14 | the Background `default` for 0xc08…0xc0f |
| 6A-RP | 11 | BX1a 26, BX1b 1 (27) | `Refusal.ripple` (`ParallaxBlitter.swift:130`) |
| 6A-RN | 15 | BG1c 22 | `LevelOpenRefusal.omniPxMode(1)` |
| 6A-CH1 / CH2 | 18 | none (BG1c built) — the level is a fixture only because it is not yet in `BuiltLevels` | the Chief's stand-in (BOS) |
| 6A-CL | 20 | BD 28, MP 16 (44) | the Background `default` for 0xb4a…0xb4d |
| 6A-BD | 20 | MP 16 | the Background `default` for 0xbf4 |
| 6A-MP | 20 | none | `SetupFaces.swift:399` (modes 1–2) |
| 6A-CP | 22 | none, plus the test-only player start beside placement 486 | the Box Handle / wake for 0x438 / 0x439 |

A fixture is a test stand-in, named as one: the real `Mlvl` with the listed records' placements skipped at spawn
(every other record, the header and the stream as the level has them). Leaving records out changes the stream for the
Setups after them, so a feature golden pins the fixture's frame, never the real level's; the level task's real
first-frame golden is new (R3).

### 7.3 Hazards for the 6A builds
- **The strip shifts every sprite-slot id on levels 10, 30, 40, 45, 62, 67** (§2.1 step 1): any test or golden that
  names a sprite slot on those levels is measured after 6A-S8, never before. The `Mlvl` placement indices (89, 108,
  200, 250 …) do not move.
- **Level 20's stream**: 164 clouds draw two numbers each in `.SetupLevelSprites` (§2.8); a missed or reordered draw
  moves every later number of the level.
- The spiked ball draws R(100) on every contact frame (M l. 49189–49191); the blade only on a frame whose segment
  crosses (M l. 49711–49722) — both before `.HurtPlayer` decides anything (§2.9, §3.4).
- The wind gate crossing (§2.2), the 5th-branch overwrite (§2.4) and the failed strip face load's unrestored CLUT
  pointer (§2.1) are "as written" — tests pin them so no review "fixes" them.
- The rain's draws run on undrawn frames too, and on the pause's and the quit dialogs' extra paints (§2.7); the
  ripple's formula loop only on drawn frames (§2.5); every Caps-Lock pause on level 15 restarts the rain's first call.
- The CLUT timer (§3.6, 6B) never resets: whatever ticks it before level 50 (nothing in 6A: n = 0 everywhere on 1–22)
  is carried.
- 6A-S8 and 6A-RN each change a shared seam type: one task each, both shells built in the same task (Invariant 9).

### 7.4 Read depth
Line by line, re-read in the committed dump: §2.1 (the clipped walk re-read in the raw by review leg 2; its token-2
clip arithmetic is pinned by `testModeEightClipped`), §2.2 (with the raw), §2.3, §2.4 (the 0xc09 arm included), §2.5
(with the raw for the formula), §2.6 (the seven sites), §2.7, §2.8, §2.9, §2.10, §2.11 (in full, to the Box tail),
§2.12, §2.14, §3.6's step (re-derived from the raw by review leg 1). §2.13 from BOS §3.7 with the span re-checked.
**Skimmed — re-derive at its planning run:** §3.3's Box 2907 arm, §3.4 and §3.5's Box arms, §3.7's
`.FindUpperLeftCorner` arm and the fire-wall arms, §3.8's flame routines (lighting-tables §9), §4.5's three routines.
Not derivable on paper (each build measures, then pins, R4): every golden frame's values and frame numbers; whether
level 10's strip, trees and rotating cannons are on screen at frame 1; which frame of level 11 first shows a ripple
row; level 15's first thunder frame; the frame after the carpet's wake; whether the OmniPx port's initial contents ever
show under 6000.

---

## 8. The review fix round (2026-11-11) — every finding, where it went

Leg 1 (spec) — 20 findings: **1** the rain's extra clears and callers → §2.7 (step 1, spans, tests, asserts), §7.3,
rendering-omnipx-titles §3.6 correction; **2** the CLUT step and its four points → §3.6 written out, bosses-3 §9.2
correction; **3** double ownership → R1, §9.1; **4** the auto-scroll death arm → §1, §3.7, E5a; **5** test names
outside §2 → named in §2 and §3.6–§3.7, the §3 header says the rest are owed, and the Windows reference is stated for
every golden plan; **6** an INDEX row — **not applied**: this fix round may not edit `INDEX.md` (the seat's
instruction), so the row is owed by the seat; **7** the 105 / 106 pause sentence → §2.3 step 3; **8** the wider path
branch → §2.3 step 2 and its test; **9** L40 path cannons 36 → §3.1; **10** "record" → sprite slots vs placement indices,
§2.1, §7.3; **11** "first nine allocations" → §2.1; **12** the slot stride → §2.1 step 1 and asserts; **13** the
`0x271a` clamp → §2.1 switch; **14** citation drift → §2.3 (:380), §2.4 (:430), §3.6 (:292, :353), §2.6 (:246), §2.13
(the boss-grab comment, for 6A-CH1); **15** the carpet's tail → read in full, §2.11 (leg 2's reading, below);
**16** the interlace counter → §4.1; **17** the `+0x92` clear → §2.2; **18** the 0x73f / 0x740 arm and `.FlipHRect` →
§1, §5, §2.4; **19** stale "built" rows → E5a; **20** `.ShootSpines` / `.sinDegrees` → §1.

Leg 2 (quality) — 24 findings: **1** `DrawModeAuditTests` writer rows → §2.3, §2.4, §2.8, §2.9, §2.11 (§2.2, §2.10:
no new draw writer, said so); **2** proofs before a level opens → R3, every golden plan, §7.1–§7.2; **3** the carpet
tail → §2.11 step 3–4 (the dump decides between the legs: the unread tail is the vy · 0.8 line, M l. 60369–60374, and
there are no rider flags — leg 2 is right, leg 1 #15's "level 22 needs the rest" is answered by the full read; leg 2's
"M l. 60066" for `+0x182 = 0` is M l. 60091, E20); **4** level 22 never counts → §2.11; **5** the player's half built →
§2.11; **6** branches at layer 2 → §2.4; **7** the 0xc09 arm → §2.4, §5; **8** mirrored trees and widths → §2.4;
**9** the thunder fade → §2.7; **10** the auto-scroll ambience → §3.7, §2.7 seam; **11** the loop cue's facts → §2.7;
**12** the clipped mode-8 walk → §2.1 step 4; **13** blade details → §2.9, §7.3; **14** mace paths → §2.10, E19;
**15** cannon asserts → §2.3; **16** FB / CF → R2, §2.14, §7.1; **17** ownership → R1, §9.1; **18** the Windows column
→ §0, §2.1; **19** citations → §2.1, §2.11, §3.6; **20** clouds → §2.8; **21** golden frames and levels 1–5 → every
section's golden plan; **22** rocks → §2.12; **23** the paint counter → §2.11 (already on `LevelCarry`); **24** the
existing CLUT op → §3.6. Mutation tables (71 unpinned behaviours) → the "asserts the build task adds" list of each 6A
section (strip 7, wind 4, cannon 7, trees 10, ripple 3, rain 5, clouds 6, blade 7, maces 5, carpet 10, rocks 3,
stagger 2, fireball 2). Ownership table → §9.1.

---

## 9. Corrections to the plan's cards (for the 6A planner)

Every error this document and its two review legs found in `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`
(BOS §10 and LL §10 carry their own; overlaps are pointed to, not repeated):

| # | card / place | the card says | the dump / this document | where |
|---|---|---|---|---|
| P1 | ENG card, Contract | "proven by a frame golden on the first level that uses it and built before that level's enterable task" | cannot be met literally: the level refuses at open (strip, OmniPx mode 1, ripple) or throws on its other unbuilt types (`SetupFaces.swift:430`, `:715`) — R3's test-only fixture and feature golden, then the level task's new real golden | R3, §7.2 |
| P2 | 6A-FB | its own task "before 6A-W"; "a test that the three cuts differ and 0x46b draws the 64×64 cut" | absorbed by 6A-CF (R2); two cuts, not three (the two 64×64 records are identical); not a Warrior prerequisite (BOS P4) | §2.14, E9, E10 |
| P3 | 6A-BG1 | one Background card of 42 types, split by LL | trees → 6A-TR, clouds → 6A-CL, the blade → 6A-BD, the rotating cannons 1092 / 1097 (+ 1090's p1 101–106 records) → 6A-RC, the mace paths → 6A-MP; plants → 6A-BG1c (LL); 1091 / 1093–1096 leave 6A (LL finding 10); 1150–1153, 1840 / 1843, 1900–1903 are their levels' (LL §7) | R1, §9.1 |
| P4 | 6A-BX1 | the programmed-path cannon (p1 ≠ 0) and mace (modes 1–2) arms; 1060 / 1061 / 1080 | the path arms are Background, not Box (LL finding 11); the cannon's rotating arm (p1 101–106, level 10) is 6A-RC and its path arm (p1 < 0, level 40) is 6B (§3.1) — the card mixed a 6A and a 6B arm; the carpet 1080 → 6A-CP; what remains is BX1a / BX1b | §2.3, §3.1, §9.1 |
| P5 | 6A-BN1 | Bonus / Platform / Rope types of 10–22 | nothing to build — drop (LL §10.3) | LL |
| P6 | 6A-WD | files `Player/PlayerTiles.swift`, `Physics/`; "level-10 test rows" | the branch is `.StandardSpriteHandles`' (`Physics/StandardSprite.swift:60`) and moves every wind-scaled sprite; level 20 too (LL §10.1); the crossed gates on up-left directions | E15, §2.2 |
| P7 | 6A-RP | "`.RipplePxBackOffsets` for levels 11, 18" | that routine never runs (gated on hdr `0x271e`, 0 everywhere); the ripple is `.PaintFrameWrap`'s inline loops; the refusal to remove is `ParallaxBlitter`'s | E3, §2.5 |
| P8 | 6A-T11 | "tinted submerged tiles", `TileGridRenderer.swift`, level-11 golden | built; two proof tests folded into 6A-RP, no golden of its own (LL §10.2) | E2, §2.6 |
| P9 | 6A-RN | "the side push `0x272c`"; files `World/OmniPx.swift`, `Camera/` | the push is built (a test only, E4); the thunder fade is the existing `AsyncGammaFade` + `gammaStep`, not a new op, and no golden sees it; the loop needs a `SoundCue` field and `Shared/FerazelAudio.swift` (both shells, the Windows audio test); `.Pause` clears the first-call flag; files add `Seams/SoundCue.swift`, `Front/LevelRun.swift` (the refusal), `Front/Pause.swift`, the session's paint step | §2.7 |
| P10 | 6A-S8 | files `ParallaxBlitter.swift`, …; "level-10 first-frame golden" | the strip is sprites, not a parallax layer: `Sprites/PxSprites.swift`, `FerazelRender/Frame/SpriteBlitter.swift` (mode 8), `Front/LevelRun.swift` (`setupLevel` + the refusal), the seam `FaceSetKind`; six levels (LL §10.5); the golden is a feature golden on a level-10 fixture (R3) at the first frame showing the strip | §2.1 |
| P11 | 6A-FR | "the Warrior's crates and the rocks' player arm in `.HurtPlayer`"; "built with 6A-W or just before" | the arm is in `.HitPlayerSprite` (M l. 49170–49188); the crates' Box arms are built (`isBoulder`) and their spawn is 6A-W1's; FR lands before W1 (BOS §9.1) | §2.12 |
| P12 | 6A-CH | the boss grab at `PlayerStates.swift:371` | BOS P7 (the arm is M l. 45591–45632; the comment's cite and both line numbers drifted); the stagger's 3 tests sit inside CH1's 10 | §2.13 |
| P13 | 6A-L10…L22 | "the range/list widens only once its census sets up every record" | true, and the per-record refused counts are LL §10.8's; under R3 each level task also pins its **new** real first-frame golden and deletes or keeps the feature goldens of its level as §2 says (§7.1's net counts) | R3, §7.1 |
| P14 | P6A ("its first task is 6A-BL, then 6A-FB, then the Warrior") | that order | 6A-BL, then 6A-CF (which carries FB, R2), then 6A-FR, then the Warrior's W1 / W2 (BOS) | §7.1 |
| P15 | 6B-CA (and LL's switch rows) | "a Render-side op on the current CLUT" | it draws from the Core stream, needs a writable header and a timer carried on `LevelCarry` (never reset), runs on every paint call (the pause's and dialogs' too), feeds the level-start tint tables, and an op that sets screen entries exists (`ScreenGammaOp.clut`, not executed in level frames today) | §3.6 |
| P16 | 6B-AS | the auto-scroll levels | also the player's auto-scroll death arm (`.PlayerConstraints`) and the looped ambience with its volume updates (needs RN's loop cue + a volume cue) | §3.7 |
| P17 | ENG card, Files | "`docs/ferazel/INDEX.md`" | not updated by this task or its fix round (the fix round may not edit it); the seat owes the INDEX row for this document (and LL's, BOS's if missing) | §8 |
| P18 | 6C-XL / BOS §6.6, §9.1 | the rotating cannon arm with the lair | 6A-RC's, first placed on level 10 (E1; BOS P8 agrees); 6C-XL reuses it | E1 |

### 9.1 Owners of every type on levels 10–22 (R1; review leg 2's table, completed)

LL's split tasks against this document's feature tasks:

| LL split task | types it listed | → moves to | remains with the LL task |
|---|---|---|---|
| 6A-BG1a trees + clouds | 3080–3086 (0xc08–0xc0e), 2890–2893 (0xb4a–0xb4d) | trees 3080–3086 (+ 3087 0xc0f, unplaced) and the Box branch types 0xc08 / 0xc09 they spawn → **6A-TR**; clouds 2890–2893 → **6A-CL** | nothing — **dissolves** (the cache marks go with TR / CL, as LL's CF card says) |
| 6A-BG1b moving hazards | 1092, 1097 (cannon p1 101 / 103), 3060; old-type records 1090 p1 101 / 103 / 105, 1485 modes 1–2 | the p1 101–106 arm for 0x442–0x44a (1090, 1092, 1097 on 10 / 15 / 20) and the unplaced p1 1…100 / > 106 path branch → **6A-RC**; 3060 → **6A-BD**; 1485's mode 1–2 records on 20 / 22 → **6A-MP**; p1 < 0 cannons (none on 10–22) → §3.1 (6B) | nothing — **dissolves** (1092 / 1097 with p1 0 are the built cannon arm; their set mark is CF's) |
| 6A-BG1c plants | 2700, 2701, 2702, 2705, 2711 | — | all five |
| 6A-BX1a Box scenery | 19 decorations / outcrops / mushrooms | — (the `.FlipHRect` helper is built by 6A-TR first, §7.1 #9; BX1a reuses it) | all 19 |
| 6A-BX1b faces + talkers | 1060, 1061, 2921, 2955, 2956, 2962 | — | all six |
| 6A-BX1c carpet | 1080 (0x438 → 0x439) | → **6A-CP** (+ 1081 0x439, reached only by the wake) | nothing — **dissolves** |
| (not in LL: never placed) | Box 0x433 / 0x434 (1075 / 1076) | → **6A-FR** (the player arm); their Box arms are built (`isBoulder`) | — |
| LL 6A-CF | the cache rekey by record | absorbs 6A-FB (R2) | CF keeps the rekey and the marks of built types |

Every census type of levels 10–22 then has exactly one owner:

| owner | types (decimal) / records |
|---|---|
| 6A-TR | 3080, 3081, 3082, 3083, 3084, 3085, 3086 (3087 unplaced); the spawned Box 0xc08 / 0xc09 branches |
| 6A-CL | 2890, 2891, 2892, 2893 |
| 6A-RC | 1092, 1097; the p1 101–106 records of 1090 |
| 6A-BD | 3060 |
| 6A-MP | the mode-1 / mode-2 records of 1485 |
| 6A-CP | 1080 (1081 by the wake) |
| 6A-FR | 1075, 1076 (spawned only) |
| 6A-BG1c | 2700, 2701, 2702, 2705, 2711 |
| 6A-BX1a | 2808, 2816, 2817, 2827, 2831, 2833, 2834, 2836, 2837, 2846, 2847, 2850, 2852, 2857, 2861, 2872, 2873, 2875, 2876 |
| 6A-BX1b | 1060, 1061, 2921, 2955, 2956, 2962 |
| 6A-CH (CH1 / CH2) | 1910 (and the level-18 arena switches, LL §7) |
| 6A-L10…L22 | the 55 types and switches of LL §7's `6A-L10…L22` row, and the level-21 pipe wiring 1490–1493 |
| 6A-S8 / 6A-RP / 6A-RN | the header switches of LL §7 (strip, ripple + T11 inside RP, rain + side push) |
| 6A-CF | no type: the marks of built types and the record keying |
