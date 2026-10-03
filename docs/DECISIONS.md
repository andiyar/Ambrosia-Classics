# DECISIONS.md — Ambrosia Classics

> Append-only. Numbered. Never re-litigate a locked decision — supersede it with a new numbered
> entry that references the old one. Record rejected alternatives with the reason.
> Two rules that were paid for (fable-kit): a ledger line is NOT consent to remove something Ben uses;
> record the rejected alternatives — they stop the next session proposing them again.

---

## D1 — Phase 0 rulings: census numbers, tool placement, local paths (2026-10-03)

**Decided:**
1. **Aki 1.1.0 has 71 QuickTime-JPEG PICTs and 11 raw, not 70/12** (design §4). The opcode-stream census
   and the `aki-census` tool agree; `docs/aki/data-census.md` states the tool's numbers. The design doc is
   left as Ben approved it; this entry is the correction.
2. **Aki 1.1.0 has 0 `'snd '` resources** — its sounds are 10 AIFF (ima4) + 4 MP3 files (1.2.0: 10 + 5).
   The design §5 "every snd opens" gate is vacuous for Aki; HectorKit's `snd` decoder keeps EV's Override
   Sounds as its oracle; Aki's sounds are gated by `AVAudioFile` opening every file.
3. **The census tool lives in `Aki/Core` (`aki-census` executable target), not in HectorKit** — it knows
   the word "Aki" (HectorKit rule). HectorKit carries only the Aki PICT census as a *test*.
4. **Local paths.** `Aki/Core/Package.swift` depends on HectorKit at `../../../HectorKit` (design §3). In a
   `.claude/worktrees/<name>` session that resolves to `.claude/worktrees/HectorKit`, an untracked symlink
   to `~/Developer/HectorKit` (the main checkout's `.git/info/exclude` already ignores `.claude/worktrees/`).
   The originals are reached through git-ignored symlinks `Resources/Aki/1.1.0.app` and
   `Resources/Aki/1.2.0.app` (archive copies; paths in `docs/aki/data-census.md`); the Aki tests default
   to them and `AKI_DATA_11` / `AKI_DATA_12` override.
5. **A decoded composite must match its 1.2.0 twin**, not just its size: 1.2.0 re-shipped the same art as
   PNG, so `AkiCensusTests` pins five QuickTime PICTs against their PNGs (mean |ΔRGB| < 6).

**Because:** numbers come only from tool output; game knowledge stays out of the kit; one checkout layout
must work in both the main checkout and agent worktrees without editing `Package.swift`.
**Rejected:** editing the design doc's 70/12 in place (it is Ben's reviewed text) · an Aki census tool inside
HectorKit (kit rule) · absolute paths in `Package.swift` (breaks every other machine) · size-only gates for
QuickTime art (a band swap keeps the size).
**Approved by:** Phase-0 orchestrator rulings R4/R5/B7 (2026-10-03) under the design doc; Ben's review pending.

## D2 — Phase 0 review-driven HectorKit rulings: gate log path, banded-QuickTime hardening (2026-10-03)

**Decided:**
1. **The zero-skip gate's log path is overridable.** `tools/check-zero-skip.sh` writes its `swift test` log
   to `${HECTORKIT_TEST_LOG:-/tmp/hectorkit-test.log}` (HectorKit `afc00bb`): two gate runs in parallel
   sessions must not share one `/tmp` file. Gate commands in plans and handoffs may set it per checkout.
2. **The banded QuickTime walk is hardened** (HectorKit D2 "Hardened 2026-10-03", commit `46161b9`), four
   items from the Task 5 quality review: (a) a band past the frame's right edge (x + width > frame width)
   throws `bandOutOfFrame` — pinned by a test; (b) a band matrix whose w is not exactly 1.0 (Fract
   0x4000_0000) is refused (`unsupportedOpcode(0x8200)`) — pinned; (c) a second 1-bit placeholder straight
   after one band is refused (`unsupportedOpcode(0x0098)`) — pinned; (d) new `PICT.DecodeError.unsupportedBand
   (String)`: `decodeQuickTime` refuses a band carrying a matte (`"matteSize"`), a mask (`"maskSize"`), a srcRect
   other than (0, 0, height, width) (`"srcRect"`), or a mode other than srcCopy 0 / ditherCopy 64 (`"mode"`;
   every Aki band is 64), instead of compositing it wrong. The refusal sits in the compositor and
   `QuickTimeBand` reports the four fields, because EV ship PICT 5027's band carries a 10-byte mask and the
   walk must still reach its pinned 0x0007 boundary. HectorKit zero-skip floor 112 → 119.

**Because:** concurrent agent sessions are the normal way this project runs; and every field the composite
would ignore must either be pinned by a test or refused by name (robustness over minimalism — Ben's standing
preference), so a mutant or a new data shape can never pass silently.
**Rejected:** a fixed `/tmp/hectorkit-test.log` (parallel runs overwrite each other's evidence) · ignoring
srcRect/matte/mask/mode because Aki never sets them (a future game's band would composite wrong, silently) ·
refusing them inside `quickTimeBands` (moves EV 5027's pinned refusal from 0x0007 to `maskSize`).
**Approved by:** Phase-0 orchestrator rulings on the Task 5 quality review (2026-10-03); Ben's review pending.

## D3 — Phase 1 present path: CoreGraphics canvas through a CALayer-backed NSView, measured (2026-10-03)

**Decided:**
1. HectorShell draws into a CPU `ShellBitmap` (a `CGContext` over a once-allocated BGRA buffer, 800×600
   logical) and presents it as a CALayer's `contents` (`makeImage()`), letterboxed: exact integer multiple of
   the logical size → crisp (nearest-neighbour, `integerScale = k`); otherwise smooth fit (design §4a items
   1–2). Retina: 800×600 logical → 2x/3x in backing pixels.
2. HectorShell's render-smoke test asserts the present cost at 3× stays **< 4 ms/frame median over 60
   frames**. Metal is adopted only if that budget is missed. Design §7's open question ("Metal vs CALayer,
   decide by measuring") is closed by this measurement: the plan's scratch replica measured 1.34 ms median.
3. Aki 1.2's `_enterFullscreen` switched the display to 800×600; the replica instead fills the main screen
   (crisp at an exact multiple, smooth fit otherwise) per design §4a — listed for Ben as Q3 in the plan.

**Because:** 800×600 at ≤ 20 presents/s is a 1.9 MB copy; the original's QuickDraw call sites transcribe 1:1
onto CPU blits; no per-frame allocation; nothing to shade.
**Rejected:** Metal up front (no measured need; a second present path to keep correct) · per-pixel NSImage
drawing (allocates per frame) · integer-letterbox fullscreen (orchestrator ruling under §4a; Q3 open for Ben).
**Approved by:** Phases 1–3 orchestrator ruling 2026-10-03 (`docs/plans/2026-10-03-aki-phases-1-3.md` Task 0);
Ben's review pending.
