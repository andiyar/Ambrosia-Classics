# Handoff — Cythera Phase 0, tranche 1 (K1 + C0 + C1 + C2) — 2026-10-07

Orchestrator: Claude Opus 5.5; every implementer and reviewer Opus (Ben 2026-10-07: Fable only on a major
contraindication, and only after asking him). Plan `docs/plans/2026-10-06-cythera-phase0.md` (see its new
"Execution corrections" block).

- **K1** (⚑, two Opus legs, both MERGEABLE + one fix round) → HectorKit main `4ca2e18`, D14, floor **322**. STOPPED once
  under Invariant 10: direct PICT modes measured 36/0, not 64 — seat re-measured and ruled {0, 36, 64} as stored.
- **C0** data in git (20 files, 11,570,723 B, `cmp`-clean; D28 as-built) · **C1** package + locator + three resource
  files (5 tests) · **C2** SegmentFile/Cipher/Overlay (9 tests; reviewer cross-checked all 1,558 segments against
  `seg.py`/`scriptdis.py`, 0 mismatches). One Opus leg each, all MERGEABLE, minors fixed. Suite **14/0/0**.
- **Carried:** Ferazel `PictureSource.swift:42` checks only `transferMode == 64`; a 16-bit or region PICT with mode 64
  would now reach `Dither.convert` with an empty `rgb` and trap — latent (no such Ferazel picture); Ferazel's session
  should add `depth == 32 && maskRegion == nil` guards. `FerazelPICTCensusTests.swift:34` XCTUnwrap-wrapped skip (pre-existing).
  K1: a frame much larger than its bounds is still allocated whole (D12 follow-up, documented in code).
- No WIP. Next tranche: C3 (LZ) → C5 ⚑ (needs K1 — now on main) and C4 ⚑, C8 ⚑ → C9 ⚑ (plan wave B); size per fable-kit §5.
