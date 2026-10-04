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

## D4 — Phase 1 fidelity rulings under modern macOS: Aqua forced, Osaka-Mono bundled, AppKit menu mutations, dialogOK (2026-10-04)

**Decided:**
1. The app forces the Aqua (light) appearance (`NSApp.appearance`): the 2008 binary never drew dark mode, and AppKit
   would otherwise paint white labels on the parchment dialogs. Fidelity, not an affordance (plan Q56).
2. `Release Notes.rtf` names Osaka-Mono, which modern macOS only offers as a download; parsing it froze the app behind
   a FontRegistryUIAgent prompt (~1 min, measured). **Ben's ruling:** ship the font. `tools/stage-aki.sh` copies Apple's
   downloaded `OsakaMono.ttf` into `Contents/Resources/Fonts` (`ATSApplicationFontsPath`); the RTF is parsed with Menlo
   substituted only when `CTFontManagerCopyAvailablePostScriptNames()` lacks the face (cannot prompt). The font is for
   Ben's machine; it is never committed (Q55).
3. AppKit rewrites an installed menu bar. **Ben's ruling:** suppress what it allows — "Preferences…" re-set a run-loop
   turn later and in validation; Dictation/Emoji via `NSDisabledDictationMenuItem` / `NSDisabledCharacterPaletteMenuItem`
   registered defaults; the Edit items the nib did not build removed after they appear — and list the rest (⌥ alternates,
   Window tiling items, "Clear Current Layer" losing its duplicate ⌘X) as Questions rows Q53/Q54.
4. `Aki Handbook.pdf` opens in Preview (the original's `openFile:withApplication:@"Preview"`, DC:587), default handler
   only when Preview is absent — the plan's "names no viewer" was corrected by review.
5. One rule for every Carbon dialog: `g.dialogOK` true on `ok  `, false on `not!` (DC:2083/DC:1911); the plan's
   P1.10 wording ("sets for ok") would have left the flag latched after "Level Unavailable" (Q57).
6. Splash windows stay AppKit panels at 1× (slightly soft over the crisp canvas) — **Ben: "fine as is"** (Q52 closed).

**Because:** each is the behaviour the original showed on its own OS, reproduced under an OS that now intervenes.
**Rejected:** drawing splashes through the canvas (Ben) · Menlo-only Release Notes (Ben wants the real face) ·
fighting AppKit's ⌥ alternates and tiling items (no switch exists) · leaving dark mode to AppKit.
**Approved by:** Ben 2026-10-04 (items 2, 3, 6 explicitly); orchestrator ruling for 1, 4, 5 under invariant 1.

---

## D5 — Bubble Trouble X core + decoder lane: forks closed during the build-out (2026-10-03/04)

**Decided:**
1. **FILM oracle, restated honestly.** The bank derives no end state for any FILM. The machine bar is: each of the four
   demos replays to count exhaustion (hero never caught before the final frame; a level completed inside the last 70
   frames is a FLAGGED pass printed `end = count,level`), with self-consistent numbers (frames, samples, score, lives,
   total RNG draws) frozen as self-derived goldens after a Fable plausibility review. "Matches the original" is Ben's
   gate only (NR-10, his eyes on the original demo once the shell exists).
2. **`PixPat` → `PixelPattern`** in HectorKit (the SDK's legacy QuickDraw struct `PixPat` collides).
3. **`btSP` dropped from the kit** (kit plan R2) — no consumer, no census evidence of use.
4. **NR-6 carried, not modelled.** The hero-balloon `_PopEnemy(-1)` reads outside the enemy array (level ≥ 6 only;
   C12 narrows the release path). The replica treats slot −1 as a no-op and records the quirk; no attempt to emulate
   the neighbouring globals.
5. **Tag numbering.** HectorKit's BTX-decoder milestone (locator, snd census, CIcon, PixelPattern, masked PICT 4a/4b)
   is tagged `v0.2.0` on the commit that includes it; the tag covers HectorShell D4 too since it is on the same main.
   Ben's Aki map-screen verdict stays an honesty gate independent of the tag (a tag marks a kit API milestone, not a
   screen sign-off). `v0.3.0` would have been used only if `v0.2.0` had already been taken.
6. **Seat rulings from the review rounds (2026-10-04):** (a) `_GetDistantObject` keeps the original's flat-array read
   inside the 176 maze bytes (col 15 right wraps to the next row's col 1, col 0 left to the previous row's col 14);
   only a read that leaves the array returns 50 — the original would read neighbouring globals there (undefined;
   unreachable from the push table because `_GetNextObject` hits the edge first). (b) Sound/redraw-only parameters
   are dropped from `addHero`, `multiplierReset`; they touch no state and no RNG. (c) QuickDraw regions that never
   close are refused (`unsupportedRegion("unclosed")`): Inside Macintosh regions close and both real region PICTs do.
   (d) `PICT.decodeMasked` on a QuickTime-only (0x8200) stream throws `.noMask`, per the 4a contract.
   (e) Implementer commits carry the executing model's trailer (`Claude Opus 5.5`); orchestrator merges and docs
   carry `Claude Fable 5.1`. (f) Merge-head test totals run **+12** over the plan's table (the T3 fix round added 6
   tests, kit Task 7's census added 6): W4 56, W5 72, W6 96, W7 122, W8 128, W9 130/131.

**Because:** every one of these was a real fork a worker hit; writing the ruling down stops the next lane re-deciding it.
**Rejected:** modelling NR-6's out-of-array read (depends on runtime memory layout; no oracle) · refusing the flat
wrap in `_GetDistantObject` (it IS the original's behaviour, reachable or not) · accepting unclosed regions (no census
evidence; Invariant 4) · tagging `v0.3.0` to leave `v0.2.0` for the shell session (version order would invert).
**Approved by:** BTX orchestrator (Fable 5.1), 2026-10-04; Ben's review pending on items 1 and 5.

---

## D6 — Aki Phase 2 first play: the fade must show, Esc keeps Cancel, Give Up clock left as is (2026-10-04)

**Decided (Ben, after his first game of Aki "in a decade", on the staged P2.12 build):**
1. **Q24 — matched pairs must fade.** On the staged build they just vanish (the 11 fade frames land inside one display
   refresh). Fix: one display-refresh wait per fade frame in `runFade`, so each frame reaches the screen — fidelity with the
   2008 Mac (beam-synced QuickDraw flushes), not an affordance.
2. **Esc presses Cancel in the Carbon dialogs** (P1.10's mapping of Esc to every `not!` button) — kept, although the original
   set no cancel button. The carried P2.11 review Minor (held Esc can re-open Give Up) is accepted with it.
3. **Q25 — Give Up clock:** Ben's instinct is that the clock should pause under "Are you sure…?", but that "sorta cheats" —
   not ruled. The replica keeps the current reading (clock runs under the modal; the time-out-then-OK edge stays copied).
   Re-ask only if new evidence about the original appears.

**Still open:** the formal P2 gate (each of Hard / Medium / Easy / Practice start to finish, "it plays like Aki") — re-stage
after the fade fix and ask Ben then.
**Approved by:** Ben 2026-10-04 (items 1–3, in his words).

---

## D7 — Aki on iPad: Ben's six rulings, sequencing, cap (2026-10-04)

**Decided (Ben, answering `docs/plans/2026-10-04-aki-ipad.md` §0):**
- **Sequencing:** the iPad version comes BEFORE Phase 3 ("custom levels are much less exciting for me").
- **R1 — menu-only commands:** "undo doesn't actually work in Aki, that would be cheating" (true on Hard/Medium: the
  original enables Undo only when difficulty > 1, i.e. Easy/Practice — rules.md §10). Undo gets NO on-screen control; it
  stays the original menu command (iPadOS 26 menu bar + ⌘Z on a hardware keyboard, enabled exactly as on the Mac). **Give
  Up gets an on-screen control: an X at the top left** — placed in the black border outside the 800×600 canvas (R3), so
  the drawn screen is untouched. Every other menu command lives in the iPadOS 26 menu bar from the same nib XML.
- **R2 — map hover preview:** first tap on a lantern previews it (the hover state + `Preview.aiff`), a second tap on the
  same lantern enters; a tap on another lantern moves the preview.
- **R3 — scaling:** borders — the largest INTEGER scale that fits, black border (mini 2×, Air 2×, 13" Pro 3×). Crisp.
- **R4 — Quit:** drawn, non-functional on iPad ("oh well").
- **R5 — device:** doesn't matter; **iPadOS 26+** floor. The paired iPad mini (A17 Pro) is the first install target.
- **R6 — HectorKit:** "fork" it — do the work on a HectorKit branch, merge back. Ruled mechanics: branch `ipad` in a
  HectorKit worktree, reviewed, macOS floor (167) unchanged + HectorShell builds for iOS, then ff-merged to HectorKit main
  (Classics sees HectorKit through the shared `.claude/worktrees/HectorKit` symlink, so it consumes merged HectorKit only).
- **Cap:** Opus seat, cap lifted, one session, "just go for it".

**Rejected:** on-screen Undo (cheating, and disabled on Hard/Medium anyway); tap-hover via trackpad only (Ben chose
tap-to-preview); fit scaling (soft); Aki-local shell (Ben chose the fork-and-merge-back).
**Approved by:** Ben 2026-10-04, in his words.

---

## D8 — Bubble Trouble X: the playable app goes next; the FILM-replay bug becomes a side lane (2026-10-04)

**Decided (Ben, 2026-10-04 evening, when told the core rules engine is done but nothing is playable yet):**
1. **Start the playable Bubble Trouble X on HectorShell next** (screen, sound, input, menus, level-to-level play — the
   plan's deferred Known delta 7 included). It no longer waits on FILMs 2–4 replaying to count exhaustion.
2. **The FILM-replay diagnosis is a side lane, not a gate on the shell.** The two Opus investigators already running
   finish; the orchestrator does no further digging this session. The golden freeze (plan Task 11.5) waits until the
   diagnosis closes or Ben rules on it.
3. **Harness format rulings in force (orchestrator, this session):** `testAllFourFilmsEndByCountExhaustion` pins FILMs
   2–4 in `knownDiverging` and asserts they are NOT accepted (a fix forces the set to be updated); `end` prints
   `gameover` after `death` and `max-frames` when no stop fired; `btx-replay` exits 64 on usage / missing data, 66 on a
   data-load failure; a non-default `--rng-variant` is announced on the first line.

**Evidence carried to the side lane:** the hero side of every FILM stays in sync up to its catch (every fresh push lands);
the RNG 0x8000 variant is moot (no such draw in any FILM — NR-3 untested by these FILMs, not refuted); prefs ON confirmed
(off is worse); FILM 1 is a FLAGGED pass (`count,level`: level completed 1167, samples out 1227); FILM 4's original makes
one more `Random()` between frame 212's eel roll and frame 213's piranha roll; FILM 3 has a similar window (473–512);
FILM 2's catch is a 1-pixel overlap. Four Opus audits found no code discrepancy against the decompile.
**Approved by:** Ben 2026-10-04 (items 1–2, his choice "Start the playable app"); item 3 orchestrator (Opus 5.5).
