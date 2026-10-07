# Handoff — Cythera Phase 0, tranche 2 (C3 + C4 + C5) — 2026-10-07

Orchestrator: Claude Opus 5.5; every implementer and reviewer Opus (Ben 2026-10-07). Plan
`docs/plans/2026-10-06-cythera-phase0.md` — read both correction blocks at its top. Rulings: D28 "As built — tranche 2".

- **C3** LZ (minor, one leg MERGEABLE): 6 tests; reviewer's differential matched `lz.py` on all 378 streams; 200k fuzz, no trap.
- **C4** ⚑ World records (two legs + fix round + re-review): 14 tests. STOPPED once under Invariant 10 — the plan's map
  0x8002 chunk-0 words and the 0xF001 "2 tail bytes" were wrong; seat re-measured and ruled.
- **C5** ⚑ CytheraRender pixels (two legs + fix round + re-review): 10 tests; `Package.swift` now has CytheraRender +
  CytheraRenderTests. `StoredPicture` is a struct (S3 correction); `compoTile` takes `CompoTileRecord`; `LZ.decode(_:limit:)` added.
- Suite **44/0/0**; layering greps empty; only `Cythera/Core` + docs changed; HectorKit untouched (4ca2e18, floor 322).
- **Carried minors (re-review, not blockers):** `LevelMap.init(file:)` takes `SegmentFile` (needs header maxMapDimension)
  while `PropSegment` takes any `SegmentStore` — reconcile when Phase 4's save overlay reads maps (pass the dimension);
  `AnimationRecord.tile(forFrame:)` has no 0…7 frame guard; `LZ.decode(_:limit:)` accepts a negative limit; one
  F007 length check is still partly tautological; kit carry — a `PICT` error naming the first unsupported *bits* opcode
  would let CytheraRender drop its opcode walk (Land King Hall). Test files import CryptoKit (Windows test build: later).
- Ferazel carry unchanged (not ours): `PictureSource.swift:42` 16-bit/region PICT with mode 64 latent trap.
- No WIP. Next tranche: C8 ⚑ → C9 ⚑ (plan wave B lane C), then wave C (C6, C7 ⚑, C10); ladder 44 → C8 50 … per plan
  (canonical numbers assume C6/C7 first — use previous + N).
