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

---

## 0. At a glance

| § | feature | phase | first level (all levels) | switch | lines to transcribe | tests | seam | Windows |
|---|---|---|---|---|---:|---:|---|---|
| 2.1 | horizon strip (draw mode 8) | 6A | 10 (30, 40, 45, 62, 67) | hdr `0x2716/18/1a` | ~470 | 12 | Core + Render + **shared** (`FaceSetKind` case) | reference frame only |
| 2.2 | wind cells | 6A | 10 (20) | overlay o1 0…15 | 85 | 8 | Core only | — |
| 2.3 | rotating cannon arm (p1 101…106) + shot steering | 6A | 10 (15, 20, 40, 50, 51, 52, 62; Xichra 67) | Background 0x442…0x44a p1 | 110 | 9 | Core only | — |
| 2.4 | trees and their branches | 6A | 10 (11, 15) | Background 0xc08…0xc0f | 250 | 7 | Core only | — |
| 2.5 | parallax ripple (the river) | 6A | 11 (18) | hdr `0x26ca` | ~190 | 8 | Render only | reference frame only |
| 2.6 | tinted submerged tiles | 6A | 11 | hdr `0x26c6` | **0 (built)** | 2 | none | reference frame only |
| 2.7 | OmniPx rain (mode 1) + thunder; side push | 6A | 15 | hdr `0x26c7` = 1; `0x272c` | ~110 (push built) | 12 | Core + Render + **shared** (looped-sound cue, if absent) | reference frame + loop on both mixers |
| 2.8 | clouds | 6A | 20 | Background 0xb4a…0xb4d | 80 | 5 | Core only | — |
| 2.9 | rotating blade + segment test | 6A | 20 (22, 30, 62) | Background 0xbf4 | 170 | 9 | Core (+ one Render audit row) | — |
| 2.10 | programmed-path maces (modes 1, 2) | 6A | 20 (22, 30, 31, 40, 62) | Background 0x5c8…0x5d1 p1 1/2 | 30 | 4 | Core only | — |
| 2.11 | magic carpet 0x438 / 0x439 | 6A | 22 | Box 0x438 | ~150 | 8 | Core only | — |
| 2.12 | falling rocks' player arm | 6A | 5 (the Warrior's crates) | Box 0x433 / 0x434 at run time | 20 | 4 | Core only | — |
| 2.13 | the player's boss-stagger arm | 6A | 18 (67) | `_DAT_100a0570 > 0` | 42 | in 6A-CH1 (3 rows) | Core only | — |
| 2.14 | fireball cache by record | 6A by the plan (first need 6B) | 25 (55, 67) | EnemyShot 0x46a…0x46c | 40 | 3 | Core | — |
| 3.1 | programmed-path cannons (p1 < 0) | 6B | 40 (62) | Background 0x442… p1 < 0 | 45 | 4 | Core only | — |
| 3.2 | level-wide liquid flag + ice | 6B | 30 (31) | hdr `0x26cd`, `0x2710` 220 | 0–20 (prove) | 3 | none | — |
| 3.3 | countdown digits | 6B | 40 | Box 2907 (0xb5b) | 140 | 6 | Core (+ faces) | — |
| 3.4 | spiked balls 0x5c3 / 0x5c4 | 6B | 45 (62; 0x5c4 from Xichra's rain on 67) | Box 0x5c3 | skimmed | ~5 | Core only | — |
| 3.5 | snowball 0xbfe | 6B | 31 | Box 0xbfe | skimmed | ~4 | Core only | — |
| 3.6 | CLUT animation | 6B | 50 (51, 67) | hdr `0x2730…0x2736` | 178 | ~8 | Core + Render + **shared** (a DrawOp case) | palette path, both shells |
| 3.7 | auto-scroll + the fire-wall marker sprites | 6B | 51 x (52 y) | hdr `0x2726…0x272a` | ~120 + arms | ~8 | Core | — |
| 3.8 | fire backdrop + flame buffer (+ placed fire 0x4b8) | 6B | 52 mode 1 (55 mode 2; fire 0x4b8 on 40) | hdr `0x2722`; Background 0x4b8 | ~1,000 | ~12 | Render + Core (`.MyRandom` stream, sparks) | reference frame only |
| 4.1 | OmniPx interlace (mode 6) | 6C | 70 | hdr `0x26c7` = 6 | 95 + 10 | 4 | Render (+ Core counter) | reference frame only |
| 4.2 | the End key in the guardians' Handle | 6C | 55 | key 0x77 | 3 | 1 | Core + both shells' key maps | yes (key map) |
| 4.3 | the guardians-alive global | 6C | 55 | `*_DAT_1009fecc` | 6 | 2 | Core only | — |
| 4.4 | conversations started inside a sprite Handle | 6C | 67 | Xichra's `.Conversation` calls | flow only | 3 | Core (`LevelRun` / flow) | — |
| 4.5 | victory + stitch + credits | 6C | after 67 | `*_DAT_1009ffc4` | 322 | ~6 | Core flow + Render (pictures) | reference frames |
| 5 | unreachable as shipped: rope bridge 1466, table 0xb71, water kinds 206–209, `.RipplePxBackOffsets`, 0x73f / 0x740 | — | none | — | 0 | 1 each (data pin) | none | — |

Sizes are dump lines still to transcribe, read from the spans below; test counts are sized like the neighbouring
movers and renderer tests (4–12). Every 6A feature is Core-only or Render-only except the strip and the rain, which
each add one shared seam case (§2.1, §2.7) and so change both shells in lockstep (they compile against the same
`FerazelCore` seam; the Windows shell draws through the same `FerazelRender`).

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
the ledger's LL owners, not engine features), `.PlayerConstraints` (built at LV5, BOS §7). `.FlipHRect`'s note
(decoration p1 ≠ 0) is not an engine feature (LL).

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

**Spans.** `.SetupLevel` M l. 2252–2268 (fast path: `.MTKillPxSprites`, then `.MTAddPxSprite` with the Backgrounds
file open) and M l. 2350–2356 (long path); `.MTKillPxSprites` 30820–30852; `.MTAddPxSprite` 30853–30927;
`.SetupPxSprite` 30798–30819; `.HandlePxSprite` 30771–30797; `.MTHandlePxSprites` 30928–30948 (called from
`.FindUpperLeftCorner` M l. 6235); `.KillAllSprites` M l. 30958; `.BlitEncFaceBehindTilesClip` 22251–22449;
`.BlitEncFaceBehindTilesNoClip` 22450–22548; `.BlitEncFaceX` dispatch raw `1002cf5c..1002cfa4` (no flip test) and the
mask pass raw `1002d18c..1002d2c0` (draw-effects §1.2).

**Today.** `Sprites/PxSprites.swift` models `.MTAddPxSprite`'s copies and `.HandlePxSprite`'s position (built R4,
unused: nothing creates the sprites); `LevelRun.refuseUndrawnHeader` refuses the level (`LevelRun.swift:584`,
`LevelOpenRefusal.horizonStrip`); `SpriteBlitter` refuses mode 8 by name (`SpriteBlitter.swift:43`);
`DrawModeAuditTests` row `LevelOpenRefusal.horizonStrip` (`.headerZero`).

**Contract.**
1. Creation (`.SetupLevel`, before `.SetupLevelSprites` M l. 2526 and after `.KillAllSprites` M l. 2246): the strip
   sprites are the **first records of the level** — every later record number on levels 10, 30, 40, 45, 62, 67 is
   shifted by the strip's count. `.MTAddPxSprite`: N = ⌊((fx·W·32) >> 8) / 768⌋ + 1 (C division); one face
   `.Load1EncFaceFromPICT(PICT)` (under `*_DAT_1009ff8c` when hdr `0x26cc` ≠ 0, restored after); fail →
   `.ReportError`; then k = 0, 1, … while k ≤ min(N, 31 − count): `.MTNewSprite(0, 0, 0, layer −500, record −1,
   .SetupPxSprite)`; on success `+0xc0` = the face, `+0x14c` = 768·k, `+0x150` = y, `+0x154` = fx, `+0x158` = yb;
   count + 1 each pass (also on a failed spawn); the face pointer is appended to the face table (`_DAT_100a01d0`).
   As in `PxSprites.init` (already exact).
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
   decompile (`in_r11` / `in_r12`): **the build re-reads raw `100269c4..10026d34`** for where a clipped literal run's
   4-byte groups start (the unclipped variant groups from the run start).
5. The add equals a copy only where the frame byte is 0 under a 0xFF mask byte. The port must implement the add as
   written (with carries) rather than assume it; one test pins that on level 10's first frame every frame byte under a
   0xFF mask byte is 0 before the sprite pass (draw-effects §2.5's MED inference, made checkable).

**Seam.** Core: the strip sprites become real `SpriteWorld` records created in `LevelRun.setupLevel` at the
`.SetupLevel` position, their Handle in the sprite pass, a second `.HandlePxSprite` pass after the camera; the level
refusal removed. Render: `SpriteBlitter` mode 8 (both variants), the audit row moved to drawn. **Shared seam:** the
strip's face is a Backgrounds-file PICT and the Sprites file also holds a PICT 265 (measured), so `FaceRef(pict: 265,
set: .encoded)` would name the wrong picture — add one `FaceSetKind` case (e.g. `.backgroundsSingle`; Invariant 9:
cases may be added). Both shells compile against it; the loaders are Render's.

**First level / golden.** Level 10, first frame, Mac (`FrameGoldenTests` style) and Windows (`WinReferenceFramesTests`
+ the smoke script copy, plan "Goldens"). If the strip is off-screen on frame 1, the build takes the first frame it
shows and says which. No golden of levels 1–5 moves (no strip there).

**Tests (12).** `testStripSpritesAreTheFirstRecords` (L10: records 0…8, layer −500); `testStripCopiesPerLevel` (9,
12, 12, 3, 9, 2); `testHandlePxSpriteRunsTwice` (positions after the sprite pass and after the camera);
`testStripFaceUsesBackgroundsFile` (265 ≠ Sprites 265); `testStripFaceClutOnLevel62` (`0x26cc`);
`testModeEightWordAddCarries`; `testModeEightTailBytes`; `testModeEightClipped` (raw re-read);
`testModeEightMaskPassZeroes`; `testFrameIsZeroUnderOpenMaskOnLevel10`; `DrawModeAuditTests` row moved
(`horizonStrip` gone, mode 8 drawn); `testLevel10FirstFrameGolden` (+ the Windows reference).

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

**Contract** (after the water current, before the ride carry; only while `+0x90 > 0`):
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
   o1 = 10 cells and L20's 36 o1 = 12 cells**. (The decompile shows it too, M l. 32514–32527, through `uVar8`/`uVar9`.)
5. Neither gate → done. Else (v′, h′) = `.LookupModedImpulse(m, 14·o2)` — the **push** impulse; scale = `+0x90`:
   below 0xff → h′ = (h′·scale) >> 8, v′ = (v′·scale) >> 8 (arithmetic shifts).
6. Ramp: `+0x96 < 33` → `+0x96 + 1`, push = (h′·`+0x96`) / 33 (C division); else push = h′. `+0x98 = h′`;
   `+0x92 = 1`; x-gate → `+0x14 += push`; y-gate → `+0x2c += v′` (no ramp on the vertical).
7. No random draw anywhere (the wind dust's draws are `.WrapDrawWaterEffects`', built).

**Seam.** Core only. No draw changes; no golden of levels 1–5 moves (no wind cell there).

**First level / golden.** Level 10. A Core trace pin rather than a frame golden of its own: 60 frames of the player
held in the first o1 = 9 column of level 10 (x256, vy, `+0x96` per frame), seed fixed; level 10's enterable task
carries the frame goldens.

**Tests (8).** `testWindGatesEachQuadrant` (four rows of the table, synthetic cells); `testWindCrossedGatesOnDiagonalUpLeft`
(o1 10); `testWindRampUpAndOff` (33 frames each way, the C division); `testWindScaleBelow255`;
`testWindNeedsPositiveStrength`; `testWindSetsInWindFlag` (and the air counter reads it); `testWindCellCensus` (103 /
2,899 / 0 elsewhere); `testLevel10WindTrace`.

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

**Today.** `SetupFaces.swift:377` refuses any p1 ≠ 0 (`notTranscribed`); `BackgroundSprite.cannon` stubs the rest
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
   built). p1 ≥ 107 or p1 < 0 (other than 0) → `.HandleProgrammedPath` + `x256 += vx`, `y256 += vy` (§3.1). Then the
   common aim fold and face (built).
3. `.HitBackgroundSprite`, the other is a player shot (`+0x4c == PTR_PTR_100a04e8`) and the cannon's p1 is 105 or
   106 (M l. 63689–63709): `.KillPlayerShot(shot, 0, 1)`; `.STPlay3DSoundRand(*_DAT_100a041c, 1, 0xab, +0xe)`; if
   `+0xa6 ≠ 0`: shot vx < 0 → (aim > 24 or aim < 12 or p1 106) → step −1, `+0x160 = +0x158`, `+0xa6 = 0`; shot vx ≥
   0 → (aim > 23 or aim < 8 or p1 106) → step +1, the same. Any other qualifying sprite → `.TurnIntoCannoned` +
   `+0x154 = 6` (built). The record-p2 write of step 1 makes the 105 / 106 pause 4 frames.

**Seam.** Core only (the sound cue is an ordinary `SoundCue`).

**First level / golden.** Level 10 (records 89, 108, 200, 250). Core trace: the aim and face per frame for two full
turns of records 89 (101) and 200 (103); the frame golden is level 10's enterable task's.

**Tests (9).** `testRotatingCannonSetupFields` (each p1, p3, p4 value); `testCannon105WritesRecordP2`;
`testRotatingCannonPauseAndStep`; `testRotatingCannonClickNeedsSilentVoice`; `testCannon105DoesNotSelfTurn`;
`testShotSteersCannonLeftAndRight` (the 12/24 and 8/23 windows); `testShotSteeringOnlyWhilePaused`;
`testCannonP1OutsideRangeTakesPath` (unplaced; pinned as read); `testLevel10CannonTrace`.

### 2.4 Trees and their branches (6A-TR)

**What it is.** Big tree pictures; the first time each runs it plants invisible one-way branch platforms on itself
that the player can stand on.

**Switch.** Background 0xc08…0xc0f. Measured: L10 0xc08 ×2, 0xc09 ×4, 0xc0a ×4, 0xc0b ×3; L11 0xc08 ×2, 0xc09, 0xc0a,
0xc0b ×4; L15 0xc0c ×4, 0xc0d ×4, 0xc0e ×2 (p1 0/1 = mirror).

**Spans.** Setup arm M l. 62597–62617; `.SetupTree` 62679–62886; Handle arm 63538–63546; the branch Box arm
`.HandleBoxSprite` M l. 60941–60947 (type 0xc08).

**Today.** Refused at Setup (`SetupFaces.swift:458` default); `BackgroundSprite.swift:10` `// later`.

**Contract.**
1. Setup (M l. 62597–62617): margins `+0x1ca = +0x1c8 = +0x1cc = 0x80`, `+0x1ce = 0xa0`; the cache record flag of
   `_DAT_100a0ae0[type − 0xc08]`; `+0x17c = 0`; layer 30000 (0xc0f: −10); mirror `+0x17e` = (byte) p1; `+0x88 = 0`;
   callbacks 0; empty rect.
2. Handle (M l. 63538–63546): `+0x17c == 0` → `.SetupTree`; the face from the cache; mirror = p1 again.
3. `.SetupTree` (M l. 62683–62886): `+0x17c = 1`; the face; then per type a list of branch rects (top, left, bottom,
   right), each mirrored by `.FlipHRect(rect, face width +6)` when `+0x17e`, offset by the tree's position, spawned
   `.MTNewSprite(0xc08, rect.left, rect.top, layer 0xb, record −1, .SetupBoxSprite)` (`_DAT_1009ff34` =
   `.SetupBoxSprite`), stored in a slot, and given the rect back at the origin as its hot rect `+0x34/+0x38`:
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
   gravity `+0x110 = 0`, one-way `+0x185 = 1`. The 0xc09 child (0xc0f's) runs whatever `.HandleBoxSprite` does for
   0xc09 — **not read here; re-derive at the build** (no shipped level places 0xc0f).
5. Spawned in the sprite pass → Invariant 3's insert order; never counted (record −1), never written back.

**Seam.** Core only (the cache marks of `_DAT_100a0ae0` join `CachedFaces` at `.InitBackgroundSprite`'s position).

**First level / golden.** Level 10 (frame goldens from L10's task); Core pins below.

**Tests (7).** `testTreeSetupFields`; `testTreePlantsBranchesOnFirstHandle` (counts 3/4/4/5/0/1);
`testTreeFifthBranchOverwritesFirstSlot`; `testTreeBranchesMirror`; `testBranchBoxArm` (one-way, no face, no gravity);
`testTreeNoFreeRecordDropsStores`; `testTreeCacheMarks`.

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
1. Every `.PaintFrameWrap` (M l. 9211–9226): rows 0x200…0x47f: table[r] += `_DAT_1009ffbc`[r] (i16). ffbc has no
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

**First level / golden.** Level 11, the first frame whose view shows a PxBack row ≥ 512 (the build measures which,
from V and yb; frame 1 if it does), Mac and Windows references; the same on level 18 in its own task.

**Tests (8).** `testRippleSineTable55`; `testRippleRowsShallow` (r 0x200, 0x27f); `testRippleRowsDeep` (0x280,
0x47f); `testRippleDriftsTwoPerFrame`; `testRippleAddIsNoOp` (ffbc 0); `testRippleOnlyOnDrawnFrames`;
`DrawModeAuditTests` (`Refusal.ripple` row gone); `testLevel11RippleGolden` (+ Windows reference).

### 2.6 Tinted submerged tiles (6A-T11 — built; prove only)

**What it is.** On level 11 every tile under water is drawn through the water tint instead of having a tinted water
face laid over it.

**Switch.** hdr `0x26c6` = 1 on level 11 only.

**Spans / today.** Readers M l. 8825 (`.WrapDrawWaterEffects`), 9618, 9635 (`.PlainWrapFGTile`), 9728
(`.PlainWrapFGOverlayTile`), 9957, 9982 (`.RedrawScrollGrid`), 27043 (`.BlitEncFaceX`, modes ≥ 0x15). **All seven are
built**: `TileGridRenderer.swift:257` (RedrawScrollGrid), `LightRenderer.swift:447, :490` (the plain-wrap tile and
overlay), `WaterEffects.swift:79, :201` (the Enhanced water face), the blend op's water table (`TileGridRenderer.swift:265`).
No test runs a level with the flag on (`TileGridTests.swift:312` asserts it 0).

**Contract.** Nothing to transcribe. The build proves the seven sites against the dump and adds the proof.

**Seam.** None. **First level / golden.** Level 11's first frame (shared with §2.5's golden; run the switch-off check:
forcing `submergedFaces = 0` must change the level-11 golden and leave levels 1–5's).

**Tests (2).** `testSubmergedTintSitesMatchDump` (the seven readers, synthetic water cell, flag on/off);
`testLevel11SubmergedSwitchOff`. Plan card 6A-T11 shrinks to these two rows (fold into §2.5's task or L11's).

### 2.7 OmniPx rain (mode 1), thunder, and the side push (6A-RN ⚑)

**What it is.** On Storm Valley the sky backdrop is replaced by two scrolling rain sheets (OmniPx mode 1), particle
rain streaks fall from the top of the view every frame, and every few seconds lightning flashes the screen, thunder
plays and the screen briefly darkens. A constant wind pushes the player left.

**Switch.** hdr `0x26c7` = 1 (level 15 only); `0x272c` = −320 (level 15 only).

**Spans.** `.GenerateRain` M l. 8429–8531 (called M l. 9228, every `.PaintFrameWrap`, raw `10011ee4..10011ef0` —
before the drawn-frame test `10011fc4`); OmniPx mode 1 setup M l. 13261–13277 (built), `.UpdateOmniPx` faces loop
(built); `.TurnOnOmniPx` zeroes the factors for mode 1 (built); the side push in `.HandlePlayerSprite` M l.
46347–46365 (**built**, `Player.sidePush`, `Player.swift:751`; no test with v ≠ 0).

**Today.** `LevelRun.refuseUndrawnHeader` refuses mode 1 (`LevelRun.swift:583`); `OmniPx.setup` already loads 6000 /
6001 and their parameters (`OmniPx.swift:96, :125`); `GenerateRain` is not built; the looped-sound play
(`.STPlayLoopedSound`) has no cue (`Player.swift:161` notes the same routine unbuilt for the level ambience).

**Contract** (`.GenerateRain`, re-read line by line; agrees with rendering-omnipx-titles §3.6):
1. First call of the level (`*_DAT_1009fe88 == 0`, cleared by `.SetupLevel` after `.SetupOmniPx`): set it; T =
   R(90) + 90 (`sRam100a381c`); `.STPlayLoopedSound(*_DAT_1009fe24, 1, 0x55)` (snd 452, the rain loop) (M l.
   8449–8454).
2. Thunder (M l. 8456–8480): T > 0 → T − 1. T = 0 → flash `*_DAT_100a00fc = 3` (the built `ScreenFlash`),
   `.STPlayRegSound(*_DAT_1009fd68, 1, 0xab)` (snd 453), T = −1. T = −1 → −2. T = −2 → `.GammaFadeOutAsync(2,
   rgb 100a53ca/53ce, 0xc, 0x10)`, three `.HandleAsyncGammaFade`, `.GammaFadeInAsync(0x6e)`, T = −3. T < −2 → T =
   R(150) + 210.
3. Drops (M l. 8481–8527): x = H + R(50); while x < H + 660: s = R(2); pos (v = V, h = x); s = 0 (heavy): shape 5,
   vx −1200, vy 3600, kinds 7, 6, 5; s = 1 (light): shape 4, vx −700, vy 2100, kinds 7, 7, 6;
   `.NewParticle(kind, 0, pos, shape, vx, vy, 0, mode 1)` three times; between them: light → R(100) > 50 → h − 1,
   then v + 2; heavy → v + 4 and h − 1. Then x += R(200) + 50. Draw order per drop: R(2), [light: R(100)], [light:
   R(100)], R(200).
4. OmniPx mode 1 on screen: faces 6000 (opaque) and 6001 over it, factors zeroed (the grid fixed to the view), no
   base refresh — Render's `OmniPxOp.update` with no base cell (the port's starting contents are whatever
   `NewBlitPort` leaves; 6000 has no transparent pixel, so it covers it — measured by the build).

**Seam.** Core: `GenerateRain` at its `.PaintFrameWrap` position (every iteration, drawn or not); the gamma sequence
through `ScreenGammaOp` (`timedFadeToColor` exists; the build checks the async pair maps to it — if not, a case is
added); the refusal of mode 1 removed. **Shared:** the looped play needs a cue the shells' mixers loop (a `SoundCue`
field or case, Mac and Windows mixers in lockstep) — unless the build finds one already. Render: mode 1 in
`OmniPx` port updates (faces only).

**First level / golden.** Level 15: the first frame (backdrop sheets + the first drops), Mac and Windows; and the
thunder frame (T measured from the seed) for the flash and fade.

**Tests (12).** `testRainFirstCallTimerAndLoop`; `testRainThunderSequence` (0, −1, −2, −3 → reset);
`testRainThunderGammaOps`; `testRainDropColumnsAndDraws` (RNG order); `testRainHeavyDropParticles`;
`testRainLightDropParticles`; `testRainRunsOnUndrawnFrames`; `testOmniPxModeOneFacesOnly` (Render);
`testSidePushOnLevel15` (airborne and grounded); `DrawModeAuditTests` (`omniPxMode` row: mode 1 drawn; 3, 6, 7, ≥ 8
stay); `testLevel15FirstFrameGolden` (+ Windows); `testLevel15ThunderFrameGolden`.

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
2. Handle: the face again; fx = `+0x14c`: > 0 → x256 = H·256 + (`+0x154` − (H·256·fx >> 8)); = 0 → x256 = `+0x154`;
   < 0 → unchanged; the same for y with `+0x150`, V and `+0x158`; then the pixel copies.

**Seam.** Core only (mode 0xb unrotated is drawn today).

**First level / golden.** Level 20 first frame (in L20's task); Core pins below.

**Tests (5).** `testCloudSetupDrawsTwo` (order R(60) then R(50)); `testCloudSetupFields`; `testCloudParallaxX`;
`testCloudParallaxY`; `testCloudNeverCollides`.

### 2.9 The rotating blade 0xbf4 and the segment test (6A-BD)

**What it is.** A spinning arm. It hurts the player only if the arm's line (16 to 88 px from its centre) crosses the
player's body box.

**Switch.** Background 0xbf4 (3060): L20 ×28 (p4 1), L22 ×13 (p4 0), L30 ×3, L62 ×9 (p4 0). All p2 0, p3 0 (→ speed
8).

**Spans.** Setup M l. 62571–62583; Handle 63511–63530; `.HitPlayerSprite` arm 49684–49724; `.SectRectLineSeg`
39562–39601; `.SectLineSegs` 39507–39561.

**Today.** Refused at Setup; `HitPlayerSprite.swift:159` `// later: 0xbf4`.

**Contract.**
1. Setup: cache flag `_DAT_100a0b0c`; angle `+0x46` = p2; speed `+0x150` = p3, 0 → 8; rect (5, 5, 0xb5, 0xb5);
   callbacks 0.
2. Handle: face; angle += speed, wrapped into 0…359 (one step each way); rotation `+0x1aa` = angle; `+0x88 = 0`;
   **`+0x89 = 1`** (dynamic light → mode 0xc, draw-effects §1.1 step 4); p4 = 0 → bottom clip `+0x1ba = 0x5e` (the
   lower part of the face not drawn).
3. Player arm (`.HitPlayerSprite`, reached on rect overlap): body = the player's rect at its position with top + 6 and
   bottom − 8; c = (`+0x10`, `+0xe`) of the blade; cos / sin from the 360-entry tables (`_DAT_100a0168` cos,
   `_DAT_100a0164` sin — built in `SpriteBlitter.cosTable`); P1 = (fctiwz(16·cos + cx), fctiwz(cy − 16·sin)), P2 =
   (fctiwz(88·cos + cx), fctiwz(cy − 88·sin)) (f64 16.0 `100a19f8`, 88.0 `100a19f0`); no crossing → return.
   Crossing → save the blade's vx; vx = +0x8fc when the blade's centre x < the player's, else −0x8fc; coins = R(100)
   < 0x33 ? 0 : 4; `.HurtPlayer(player, blade, 0x70, blood 0, invul 0x3c, coins)`; restore vx.
4. `.SectRectLineSeg(rect, x1, y1, x2, y2)`: the segment against the top edge (left, top)–(right, top), the bottom,
   the left, the right edge, first hit wins; a segment wholly inside the box does **not** hit (no containment test).
   `.SectLineSegs(a, b, c, d, e, f, g, h)`: k = c·b − a·d; s1 = (d − b)·e + (a − c)·f + k, s2 = (d − b)·g + (a − c)·h
   + k; both ≠ 0 and the same sign → 0; then the same with the roles swapped (k = g·f − e·h, s over (a, b), (c, d));
   else 1 — a zero product (touching) counts as a crossing; i32 arithmetic.

**Seam.** Core. Render: a rotated mode-0xc draw with a bottom clip — the build checks `DrawModeAuditTests` has
(0xc, rotated, clipped) as drawn; if it is refused today, the renderer task is part of this one (Invariant 8). Mode
0xb rotated (refused) is unreachable here: it needs light byte −1, which no level has.

**First level / golden.** Level 20 first frame (L20's task); level 22 for the p4 0 clip.

**Tests (9).** `testBladeSetupFields`; `testBladeHandleSpinsAndWraps`; `testBladeBottomClipWhenP4Zero`;
`testSectLineSegsCrossTouchAndMiss`; `testSectRectLineSegEdgesAndInside`; `testBladeArmEndpoints` (four angles);
`testBladeHitKnockbackAndCoins`; `testBladeHitRestoresVx`; `testBladeRotatedLitDrawIsDrawable` (audit).

### 2.10 Programmed-path maces, modes 1 and 2 (6A-MP)

**What it is.** A spiked ball that shuttles up and down (mode 1) or left and right (mode 2) on a fixed path instead of
swinging on a chain.

**Switch.** Background 0x5c8…0x5d1 with p1 1 or 2. Measured: **L20** 0x5cd p1 1 ×16; **L22** 0x5cd p1 1 ×23, p1 2 ×6;
L30 0x5ce 1 ×22, 2 ×2; L31 0x5ce 1 ×4; L40 0x5cd 1 ×10, 2 ×7; L62 0x5d0 1 ×26, 2 ×2.

**Spans.** Setup M l. 62338–62361; Handle 63141–63146; `.SetupProgrammedPath` / `.HandleProgrammedPath` (built,
`ProgrammedPath.swift`); `.ApplyGravityAndSeparateFromTiles` (built).

**Today.** `SetupFaces.swift:399` refuses modes 1–2; `BackgroundSprite.mace` returns at once for them (`:173`).

**Contract.** Setup (after the common mace stores, which are built): mode `+0xb0` ∈ {1, 2} → `+0x170 = 1`, `+0x185 =
0`, `+0x188 = 1`, `.SetupProgrammedPath(s, −1, 0)`; mode 1 → y256 += record p4·256; mode 2 → x256 += record p4·256;
`+0xc = +8 = x256 >> 8`, `+0xa = +6 = y256 >> 8`. Handle: the per-frame face (built), then `.HandleProgrammedPath`
and `.ApplyGravityAndSeparateFromTiles`; no radial, no chain.

**Seam.** Core only. **First level / golden.** Level 20 (frame goldens from L20's task; Core trace below).

**Tests (4).** `testMacePathSetupModeOne`; `testMacePathSetupModeTwo`; `testMacePathHandleMoves` (one shuttle);
`testLevel20MacePathTrace`.

### 2.11 The magic carpet 0x438 / 0x439 (6A-CP) — read to M l. 60372; the tail re-derived at the build

**What it is.** A rolled carpet that unrolls into a flying platform when the player touches it, bobs, and after its
ride count runs out flashes and bursts into particles.

**Switch.** Box 0x438 (1080) ×1 on **level 22** only.

**Spans.** Setup M l. 59078–59103; Handle 60289–~60390 (read to 60372); `.HitBoxSprite` wake 61470–61476; the
player's "on carpet" flag `.HandlePlayerSprite` M l. 44534–44545 (`*PTR_DAT_100a05a4`, camera latch `*_DAT_1009fd34
= 1`); the Box Handle's tail exclusions M l. 61154–61162; `.HitBoxTileSprite`'s ranges stop below 0x438 (M l. 61551,
61592, 61668).

**Today.** `BoxSprite.swift:147, :465` (Handle returns at once), `:1521, :1594` (no wake), `PlayerTiles.swift:164`.

**Contract (as far as read).**
1. Setup: cache flag `_DAT_100a0a10`; 0x438: `+0x46 = 0`, no tile hit, rect (0x34, 4, 0x35, 0xc); 0x439: tile hit
   set, `+0x46 = R(4) + 2`, rect (0x12, 4, 0x5b, 0x12); both: one-way, gravity 0, `+0x138 = 0`, `+0xa6 = 0`, `+0x14c`
   = record p2·30 (0 → −1), `+0x150` = record p1, `+0xb8 = p1 + 0x10000`.
2. Wake (`.HitBoxSprite`, the player against 0x438): `+0x46 = 2`, type → 0x439, tile hit set, `+0x15c = 0x1e`,
   `+0x185 = 0`.
3. Handle (0x438 / 0x439): the unroll frames (`+0x46` + 1 while > 0; > 11 → 2; face cell `+0x46 >> 1`); while
   `+0x15c > 0`: − 1, vy ± 0x1e (rise for 14 frames, then sink), vx 0, no tile hit; at 0 → one-way, tile hit back;
   0x439 rect re-set; ridden (`+0x186`) or already riding (`+0x154`) with `+0x14c ≥ 0` → `+0x154 = 1`, `+0x14c − 1`
   (floor 0); on frames with `+0xa6 < 1` and frame count & 3 = 0: `+0xa6` = 10 below 91 left, else 30; `+0x158 = 6`,
   `+0xb8 = 0x10009`; at `+0x14c` = 0 → dead and `.ExplodeFaceIntoParticles(face, pos, 1, 2, 4, 100, 100)`; else the
   flash steps (`+0x158` < 4 → 0x10008, else 0x10009) back to `p1 + 0x10000`; vx decays by 0x80 toward 0; then (M l.
   60365ff) the vertical settle and the rider flags `+0x182` — **re-derive from M l. 60365 to the arm's end**.
4. Player: while riding a 0x438 / 0x439 the flag `*PTR_DAT_100a05a4 = 1` and the camera latch (M l. 44538–44545).

**Seam.** Core only. **First level / golden.** Level 22 (L22's task).

**Tests (8).** `testCarpetSetupRolled`; `testCarpetSetupUnrolledDrawsR4`; `testCarpetWakesOnPlayer`;
`testCarpetRiseAndSink`; `testCarpetRideCountAndFlash`; `testCarpetBurstsAtZero`; `testCarpetPlayerFlag`;
`testCarpetExcludedFromBoxTileHits`.

### 2.12 The falling rocks' player arm, 0x433 / 0x434 (6A-FR)

**What it is.** A falling crate or rock hurts the player it lands on and breaks. (BOS §2.7 read it for the Warrior;
re-read here.)

**Switch.** Box 0x433 / 0x434, never placed; spawned by the Warrior (0x433 ×3), the Wizard (0x434, hovering) and
Xichra's rain (0x434). First level 5.

**Spans.** `.HitPlayerSprite` M l. 49170–49188.

**Today.** `HitPlayerSprite.swift:177` `// later: Phase 6`. The Box arms (`BoxSprite.isBoulder`), `.KillBox`,
`.HurtPlayer` are built.

**Contract.** 0x434 with `+0x160 < 0` → return (nothing else in the routine runs). 0x433 with `+0x160 ≥ 0`: its
centre y < the player's and vy ≥ 600 → `.HurtPlayer(player, rock, 0x38, blood 1, invul 0x1e, coins 0)` +
`.KillBox(rock)`, return; otherwise fall through to the rest of the routine. 0x434 with `+0x160 ≥ 0`: the same with
0x70 / 0x3c. (The spiked-ball arm right after, M l. 49189–49197, is §3.4.)

**Seam.** Core only. **First level / golden.** Level 5: the Warrior fight (6A-W's scripted kill covers it).

**Tests (4).** `testRock433HurtsWhenFallingOnPlayer`; `testRock434HurtsHarder`; `testRock434NegativeReturnsEarly`;
`testRockSlowOrBelowFallsThrough`. Lands before or with 6A-W (BOS §2.7).

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

**Seam.** Core only (`PlayerStates.swift:371`). **Golden.** The Chief's scripted kill (6A-CH2). **Tests (3)** in
6A-CH1: `testStaggerSlowsAndPoses`, `testStaggerClearsStates`, `testStaggerSkipsStateChain`.

### 2.14 The fireball cache by record (6A-FB)

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
case, lockstep).

**First level.** Level 25 (the Wizard) — **no 6A level needs it** (BOS D15); the plan places it before 6A-W as an
order choice. **Tests (3).** `testFireballCutsByRecord` (48 vs 64; the two 64s equal); `testShot46bReadsRecord0844`;
`testCacheMarksPerRecord`.

---

## 3. Phase 6B (levels 25–52) — complete as to span, switch, seam, level, golden, tests

### 3.1 Programmed-path cannons, p1 < 0
Switch: Background 0x442… p1 −1 / −2 — **L40** ×37, L62 ×13 (p2 200…480, p3 1200…3600). Spans: Setup M l. 62067–62118
(p1 < 1: `+0x188 = 1`, `.SetupProgrammedPath(s, −1, 0)`; |p1| = 1 → p4 == p2 reverses `+0xf8`, vx, vy, then y256 +=
p4·256; |p1| = 2 → the same on x; pixel copies to `+0xc/+8`, `+0xa/+6`; launch speed 0x1fa4); Handle M l. 62975–62981
(`.HandleProgrammedPath`, x256 += vx, y256 += vy). Today: refused at Setup. Seam Core only. Golden: level 40 (its
task). Tests (4): setup modes 1 / 2, the p4 == p2 reversal, the Handle move. Could ride with §2.10 (one task, the
two arms share `ProgrammedPath`).

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
76750, 76790). Spans: `.AnimateCLUT` M l. 8926–9103 (178), called every `.PaintFrameWrap` before the drawn test (M l.
9231, raw `10011ef4`) and once at level entry before the tint tables (M l. 5206–5208). Algorithm: bosses-3 §9.2 (read
in full there; **not re-derived here** — re-derive at its planning run; ENG's review leg 1 re-derives the step).
Today: the `FastRand` count is built (`FerazelSession.animateCLUTDraws`, `:287, :350`); the palette change is not;
`LevelTables.swift:16` notes the tables are exact only where n = 0. Seam: Core drives it (it draws from the stream and
`0x2730` must be a **Core-writable** value: `LevelRun` holds a parsed, immutable header today — a mutable copy of the
four fields in Core state, shared by this task and 6C-XI); Render applies it — **a shared DrawOp case** carrying the
step (or the new entries), executed on the level CLUT, and both shells' present paths take a palette that changes
every frame. Golden: level 50, frames 1 and P (the build measures); level 51. Tests (~8).

### 3.7 Auto-scroll and the fire-wall markers (6B-AS ⚑)
Switch: hdr `0x272a` = 1 with `0x2726` x 768 (L51) or `0x2728` y 640 (L52). Spans: `.SetupLevelSprites` M l. 2055–2099:
`0x272a ≠ 0` → `*_DAT_1009fec8 = 1`, on; x > 0 → dir 2, speed x, **4 markers 0x4bb**; x < 0 → dir 1, speed −x, 4 ×
0x4bc; x = 0, y < 1 → dir 3, speed −y, none; y > 0 → dir 4, speed y, **7 markers 0x4bd** — each `.MTNewSprite(type, 0,
0, layer 32000, record 0x1ff, setup)`; the markers are the Background fire arms 0x4bb…0x4bd (Setup M l. 62221–62260,
Handle 63119–63135); `.FindUpperLeftCorner`'s auto-scroll arm (skimmed — re-derive). Today: `Camera.swift:58` and
`SetupFaces.swift:820` throw. Seam Core. Golden: levels 51 and 52, first frame and a later frame (measured). Tests (~8).

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
(c + 1, ≥ 58 → 0; cell 1 + (c >> 1) copied over the port on rows c & 1, c & 1 + 2, …); `.TurnOnOmniPx` keeps the
level factors for mode 6. Today: `OmniPx.swift:183` stub; refused at level open. Seam Render + Core's counter `c`
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
| Background 0x73f / 0x740 | placed on no level | `testUnplacedBackgroundArms` |
| cannons p1 1…100, ≥ 107 | no shipped record (§2.3) | in §2.3's tests |

---

## 6. Disagreements (dump wins)

| # | where | said | the dump / the data | evidence |
|---|---|---|---|---|
| E1 | BOS §6.6, §9.1 (rotating cannon arm → 6C-XL) | built by the lair task | first placed on **level 10** (records 89, 108, 200, 250), also 15 and 20 — a 6A feature; 6C-XL reuses it | §2.3 census |
| E2 | spec 3.2 / plan 6A-T11 "tinted submerged tiles — not built" | not built | all seven readers are built; only a proof is owed | §2.6 |
| E3 | spec 3.2 / plan 6A-RP / tsv "parallax ripple → `.RipplePxBackOffsets`" | that routine makes the ripple | it is gated on hdr `0x271e` (0 everywhere) and never runs; the ripple of 11/18 is `.PaintFrameWrap`'s inline loops | M l. 9197–9199, 9211–9226, 9255–9425 |
| E4 | spec 3.2 / plan 6A-RN "the side push `0x272c` — not built" | not built | built (`Player.sidePush`), untested with v ≠ 0 | M l. 46347–46365 |
| E5 | tsv rows `.LookupModedImpulse`, `.SetupProgrammedPath`, `.HandleProgrammedPath`, five OmniPx rows, dart traps, `.PlayerConstraints` | not built / partial | built (E1b, BA/GF, OX, ES, LV5) — the ledger predates them | §1 |
| E6 | port comments `WaterEffects.swift:40, :311` "wind exists only on levels 10, 20 and 52" | (not wrong: said of the wind *dust*, o1 < 36) | a precision for the planner: 52's 84 cells are dust-only (o1 27); the **pushing** wind (o1 ≤ 15) is on 10 and 20 only | §2.2 census |
| E7 | world-data-format §3.3 (wind) | (silent on the gates) | on h < 0, v < 0 directions the x and y gates are crossed | raw `10036a98..10036a9c` |
| E8 | spec 3.2 / plan "level-wide liquid flag — not built" | not built | the player, Box, Frog and built Background readers are built; only arms not yet built remain | §3.2 |
| E9 | plan 6A-FB "a test that the three cuts differ" | three different cuts | two cuts: 48×48 (`0848`) and 64×64 twice (`0844`, `0840`, identical arguments) | M l. 51434–51436 |
| E10 | plan 6A-FB "before 6A-W" as a dependency | prerequisite | not needed by any 6A level (BOS D15 agrees) | §2.14 |
| E11 | spec 3.2 "water kinds 206–209 — later" | a later level needs them | no level has them | §5 |
| E12 | spec 3.2 "rope bridge … table … 10–62" | placed on later levels | 1466 and 0xb71 are placed nowhere; carpet only on 22, snowball only on 31, spiked balls 45 / 62, trees 10 / 11 / 15, clouds 20, blade 20 / 22 / 30 / 62 | §2, §3, §5 |
| E13 | BOS §6.6 "spiked ball 0x5c4 … `.HitPlayerSprite` arm (M l. 49189–49197)" | the 0x5c4 arm | the arm covers 0x5c3 and 0x5c4 (`type − 0x5c3 < 2`) | M l. 49189 |
| E14 | card ENG "the 27 later-level routines" | a literal label | no tsv row says "later-level"; the 27 are nine reason phrases (§1); with the 4 non-boss Phase 6 rows the set is 31 | §1 |
| E15 | plan 6A-WD files "`Player/PlayerTiles.swift`, `Physics/`" | the player's tile code | the branch is `.StandardSpriteHandles`' (`Physics/StandardSprite.swift:60`) and moves every wind-scaled sprite, not only the player | M l. 32489 |

No disagreement was found with `rendering-omnipx-titles.md`, `lighting-tables.md`, `draw-effects.md` or
`particles.md` in what was re-read (rain §3.6, the strip blitter §2.5, the mask pass §1.2, the rain particle rows §5.1
all agree with the dump), so no correction is appended to them. E7 belongs in `world-data-format.md` §3.3, which this
task may not edit: the seat may append it.

---

## 7. For the planner

### 7.1 Proposed 6A build order (each feature task before its level's "enterable" task)

| order | task | needs | tests | Windows / shared |
|---:|---|---|---:|---|
| 1 | 6A-BL (the plan's first) | — | — | both scripts |
| 2 | 6A-FR rocks' player arm (§2.12) | — | 4 | — |
| 3 | 6A-W Warrior (BOS) | FR | 8 + 8 | — |
| 4 | 6A-WD wind (§2.2) | — | 8 | — |
| 5 | 6A-RC rotating cannons (§2.3) | — | 9 | — |
| 6 | 6A-TR trees (§2.4) | — | 7 | — |
| 7 | 6A-S8 strip ⚑ (§2.1) | — | 12 | **shared seam** + reference frame |
| 8 | L10 enterable | 4–7 (+ LL's types) | — | reference frames |
| 9 | 6A-RP ripple ⚑ (§2.5) + the T11 proof (§2.6) | — | 8 + 2 | reference frame |
| 10 | L11 enterable | 6, 9 | — | — |
| 11 | 6A-RN rain ⚑ (§2.7) | — | 12 | **shared** (loop cue) + reference frames |
| 12 | L15 enterable | 5, 6, 11 | — | — |
| 13 | 6A-CH1 / CH2 Chief (BOS) with the stagger arm (§2.13) | — | 9 + 8 | — |
| 14 | L18 enterable | 9, 13 | — | — |
| 15 | 6A-CL clouds (§2.8) | — | 5 | — |
| 16 | 6A-BD blade (§2.9) | — | 9 | (audit row) |
| 17 | 6A-MP mace paths (§2.10) (+ §3.1 if the planner folds it) | — | 4 (+ 4) | — |
| 18 | L20 enterable | 4, 5, 15–17 | — | — |
| 19 | L21 enterable (pipes' level spawn, plan card) | — | — | — |
| 20 | 6A-CP carpet (§2.11) | — | 8 | — |
| 21 | L22 enterable | 16, 17, 20 | — | — |
| any | 6A-FB fireball cache (§2.14) — or move to 6B before the Wizard | — | 3 | — |

6A engine tests: 4 + 8 + 9 + 7 + 12 + 10 + 12 + 5 + 9 + 4 + 8 + 3 = **91** (plus the stagger's 3 inside CH1), close to
the spec's "~+90" for the whole of 6A before the level and boss tasks — the planner should expect 6A to grow past
that once LL's per-type rows and the level tests are added.

### 7.2 Hazards for the 6A builds
- **The strip shifts every record number on levels 10, 30, 40, 45, 62, 67** (§2.1 step 1): any test or golden that
  names a record index on those levels is measured after 6A-S8, never before.
- **Level 20's stream**: 164 clouds draw two numbers each in `.SetupLevelSprites` (§2.8); a missed or reordered draw
  moves every later number of the level.
- The spiked ball and blade arms draw R(100) on contact frames before `.HurtPlayer` decides anything (§2.9, §3.4).
- The wind gate crossing (§2.2) and the 5th-branch overwrite (§2.4) are "as written" — tests pin them so no review
  "fixes" them.
- The rain's draws run on undrawn frames too (§2.7); the ripple's only on drawn frames (§2.5).
- 6A-S8 and 6A-RN each change a shared seam type: one task each, both shells built in the same task (Invariant 9).

### 7.3 Read depth
Line by line, re-read in the committed dump: §2.1 (the clipped walk excepted — raw re-read owed), §2.2 (with the raw),
§2.3, §2.4 (the 0xc09 child's Box arm excepted), §2.5 (with the raw for the formula), §2.6 (the seven sites), §2.7,
§2.8, §2.9, §2.10, §2.12, §2.14. §2.11 read to M l. 60372; the rest of the carpet's Handle arm is owed. §2.13 from BOS
§3.7 with the span re-checked. Skimmed — re-derive at its planning run: §3.3's Box 2907 arm, §3.4 and §3.5's Box arms,
§3.6's algorithm (bosses-3 §9.2), §3.7's `.FindUpperLeftCorner` arm and the fire-wall arms, §3.8's flame routines
(lighting-tables §9), §4.5's three routines. Not derivable on paper (each build measures, then pins): the golden
frames' values; whether level 10's strip is on screen at frame 1; which frame of level 11 first shows a ripple row;
level 15's first thunder frame; whether the OmniPx port's initial contents ever show under 6000.
