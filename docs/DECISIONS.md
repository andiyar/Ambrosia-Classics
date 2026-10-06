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
**Added at the session close (two further Opus investigators, independent angles):** no X 1.1 mechanism can draw in FILM 4's
window — the only `calll _Random` is at 0000c4d9, the bundled AmbrosiaTools `_RandomSeed` (called by `_Useless7`) keeps its
own seed, and every `_GetRandomFast` site is gated off there. The FILM headers' level field is a **16-bit** store (`00 0L 00 00`)
where 1.1 writes 32 bits (`000184cc movl %eax, 0x34f48`), so all four FILMs were recorded by an **older build** (bank
correction `data-formats.md` §3 ⚑). Consequence: X 1.1 itself most likely dies in demos 2–4 where the replica does (FILM 4
at frame 447 ≈ 15 s; FILM 2 at 645; FILM 3 at 1097) — if Ben's eyes on the original confirm it (NR-10), the replica is
already faithful and must NOT be changed; the goldens then freeze the deaths as the original's behaviour.

## D9 — Aki Phase 2 gate PASSED (2026-10-04)

**Decided (Ben, on the re-staged build with the Q24 fix, 6603e55):** "the game works fine"; formal gate answers — matched
pairs **fade** ("Yes, it fades"), Phase 2 **Pass** (plays like Aki across Hard / Medium / Easy / Practice).
Ben asked whether difficulty changes the timer: every level starts at 150 s on every difficulty (faithful,
`_AnimationMapScreenToCustom` `b8 = 0x96`); difficulty sets the match bonus (3/6/12/0 s), the hint and reshuffle
penalties, Undo (Easy/Practice only) and Practice's frozen clock (rules.md §10) — all in AkiCore. No change.
Q24 ruling as built: one full-tick wait per present (plan Q24 row ⚑). Next: the iPad version (D7), then Phase 3.
**Approved by:** Ben 2026-10-04.

---

## D10 — Distributing the original game data is fine (2026-10-04)

**Decided (Ben):** "There is also no issue distributing files. All ASW files were full shareware downloads anyway. And ASW
released a key unlock." Public builds may ship each game's original data inside the app (plug-and-play, as EV ARM plans).
The README says so. **Unchanged for now:** the data stays out of git (`Resources/` ignored, invariant 3) — staged apps
carry it; committing data to the repo would be its own ruling.
**Approved by:** Ben 2026-10-04.

---

## D11 — Aki Remaster mode: remacri-4× AI-upscaled art behind a toggle, Original by default (2026-10-04)

**Decided (Ben, brainstormed after the P2 gate):** add AI-upscaled art — Ben picked **remacri-4x** (Upscayl's local
Real-ESRGAN engine) from samples of five models vs crisp pixels. **Both modes ship, behind a "Remaster" toggle** ("Can we
not create a remaster mode toggle? So we have both options?"): a checkable menu item AND a Preferences checkbox; a fresh
install starts in **Original**. Remaster changes pixels only; geometry, timing, rules and the original prefs blob are
untouched; the toggle has its own UserDefaults key. Upscaled art is generated from the originals and stays out of git
(D10). Plan: `docs/plans/2026-10-04-aki-remaster-art.md`; sequenced after the iPad session (D7) merges.
**Rejected:** replacing the art outright (Ben's first pick, superseded by the toggle); live MetalFX frame upscaling
(softer, smears the fade dither and text); upscaling whole sheets (sprite bleed, smeared masks); upscayl-standard /
ultrasharp / digital-art / high-fidelity (Ben's eye). Open for U4: plain vs de-dithered backgrounds (remacri hatching).
**Approved by:** Ben 2026-10-04.

---

## D12 — Bubble Trouble X playable: architecture split, time bases, transcribed draw ops, data out of git (2026-10-04)

**Decided (plan `docs/plans/2026-10-04-btx-playable.md`, after its Opus review; recorded by task T0):**
1. **Three layers** (plan Invariant 1, S1): `BubbleTroubleCore` stays Foundation + HectorResources only (rules, session,
   front-end state, sound cues, draw ops); a new library target **`BubbleTroubleRender`** in the same package
   (Foundation + HectorGraphics + HectorAudio, no AppKit) owns pixels and PCM — a headless, golden-tested compositor; the
   **App** (`BubbleTroubleX/App`) is the only code importing AppKit/HectorShell and only presents a finished 640×480
   buffer, plays PCM and translates events. Seam types (S2 + R1: `SoundCue`, `MusicCue`, `DrawOp`, `HeldKeys`,
   `KeyModifiers`, `SessionOutput`, `ShellRequest`, `SessionEnd`, `GameMode`, `DrawTarget`, `MousePoint`, `FrameReport.sounds/.drawOps`) are LOCKED:
   cases may be added, never renamed.
2. **Transcribe, don't reinvent** (Invariant 2): the core records the original's `_PlayMySnd` calls and QuickDraw calls
   (`_AddRectToBgnd`, `_RestoreBgnd`, `_SpriteToComp`, …) as ordered op lists **at the original's call sites**; the
   renderer executes them on persistent bgnd/comp/screen buffers as QuickDraw did, artefacts included. The simulation is
   frozen (Invariant 3): FILM replay must not change (gate G4).
3. **Two time bases** (Invariant 4): in-game time is frames of the 0.033 s Carbon timer (`_PlayGame @ 00018247`, nominal
   30.3 fps, missed fires dropped, never caught up); front-end and blocking sequences (countdown, music fade, wipes,
   splashes, menus, scores) run on TickCount (1/60 s). The session API takes both explicitly; the App owns the clocks.
4. **Data stays out of git — this lane's brief from Ben (2026-10-04)**, not a standing rule (plan R13): the staged
   `.app` carries the five `.rsrc` files + `AboutCredits1.rtf` copied at staging (D10 permits shipping).
**Rejected:** "redraw the world from state" each frame (loses the original's dirty-rect artefacts and free-frame draws);
all logic + pixels in one Core target (Aki's shape — BTX's QuickDraw sprite pipeline needs a tested headless compositor,
and HectorGraphics/HectorAudio must stay out of Core); a single frame clock for menus too (the original's front end is
TickCount-paced).
**Approved by:** orchestrator (Opus 5.5) under the plan review; Ben's yes to the full playable game 2026-10-04.

---

## D13 — Bubble Trouble X playable lane: rulings closed during the build (2026-10-04/06)

**Decided (orchestrator, Opus 5.5, under the plan's invariants; Ben's yes to "the full playable game"):**
1. **Replicate the OS X branch of `_PlayGame`** (draws to the window via `_SetToScreen`, `_RestoreBgndRect`→`_BgndToScreen`,
   HUD through comp, conditional `_ScreenToComp`) — not the OS 9 comp path; seam: `restoreBgnd/sprite(target:)`, `screenToComp`.
2. **Pause is checked inside the frame** at 00018a7e (after the hero state machine), so PAUSED survives a same-frame
   appear/respawn; the session reacts after the frame.
3. **Quit:** ⌘Q in play is the GAME's (injected ⌘+0x0C → `_StopMusic` fade → quit, no prefs save); quitting while paused
   saves (`_PauseGame` case 0x17); idle-menu quit saves then fades title music.
4. **Faithful quirks kept:** first-session high scores are lost on the second launch (bool 0x3e, decompile 1178/25541/8929);
   score pads to 5 digits; time bonus counts past zero for non-multiples of 50; every key typed while paused sets gHacked.
5. **Audio:** cues play immediately (`delayFrames` provenance only); requests apply before sounds; `.start` resets music
   volume from pref 0x35; K3 voices are AVAudioSourceNodes (sample-exact volume/loops) with linear resampling — Ben's ear.
6. **Dialogs:** stop the game clocks while shown (ModalDialog); in full screen all dialogs sit above the game window
   (evidence for hiding them was a coin flip — Q18 for Ben).
7. **Text** antialiased (2008 QuickDraw smoothed ≥ 9 pt); hand cursor decoded from crsr 200; CURS 256–263 unbuilt (no caller).
8. **SwiftPM identity:** `BubbleTrouble/BubbleTroubleCore → Core` symlink (both games' packages were named "core").

**Because:** each follows the decompile (anchors in the plan, banks and code) or removes a trap with no evidence for it.
**Open for Ben:** plan Questions Q1–Q18 (title/pause pictures, cheat codes now recovered, ⌘M/⇧⌘A, channel stealing,
speed, full-screen fill, info texts, first demo = FILM 1, pattern-4 overlay, Q18 dialogs), NR-10, sound feel once K3 lands.
**Approved by:** orchestrator rulings under the plan review; Ben 2026-10-06: "playable on desktop awesome".

## D14 — Bubble Trouble X sound: the Sound Tool's volume law, music carries on, one mixer for both (2026-10-06)

**Decided (orchestrator, Opus 5.5, from the original binary; Ben's ear still the gate):**
1. **K3 `ShellMixer` is the BTX output** (HectorKit d9fdfa4): 4 effect voices (`ST_Open(4,0)`) + 1 music voice
   (`gMusicChannel`) behind `BTXAudioOutput`; `SilentAudioOutput` stays only as the no-device fallback. A failed engine
   restart after a device change is logged and retried (3×, 250 ms) instead of silently dropped.
2. **Effects follow the AmbrosiaTools Sound Tool's law, not the Sound Manager's:** `ST_PlaySoundParam` (000e5598) clamps
   volume to 0x80 and `ADPCM_Mixer` scales `sample*vol>>7` → 0x80 = unity, so `_PlayMySnd`'s 0x10/0x40/0x100 play at
   0.125/0.5/1.0 (we had 0.0625/0.25/1.0 — effects half as loud, masked by the music). Music keeps the Sound Manager's
   0x100 = unity.
3. **`_StartMusic` on a busy channel carries on** (its 50 segments queue behind the current one, no flush): ours sets the
   volumeCmd's volume and does not restart. Paused stays paused.
4. **Channel stealing is the original's** (`ST_PlaySoundParam` recovered — plan Known delta 8 / Q6 closed). snd 9029 and
   9012 are reachable (Q14 corrected).
5. **Carried, not fixed (rare):** the core's `musicPlaying` is a flag, the original's `_MusicPlaying` asks the channel
   (`SndChannelStatus`) — they differ only after the 50 music loops run out (~53 min on one screen) or when the Music
   toggle restarts stopped title music; then the original restarts/fades where ours may not.

**Because:** sound audit `docs/bubble-trouble/sound-audit-2026-10-06.md` (151 `_PlayMySnd` sites: 146 match, 5 unregistered-
only by ruling, 0 missing/wrong; music per level set matches for every level).
**Approved by:** orchestrator rulings from the decompile; Ben 2026-10-06 playtesting ("feels so close", speed right).
**Ben's playtest verdicts (2026-10-06, after 3 levels with sound):** effects good; music right and changes at level 4;
Caps Lock pause, title/pause pictures, high-score overlay, smoothed text, hand cursor — all yes (Q1, Q3, Q12, Q16, text);
⇧⌘A / ⌘M fine (Q4/Q5 kept as the nib); full screen and dialogs over the game fine (Q8, Q18). **Demos: "who cares about
demos?"** — NR-10 is waived: the demos stay as they replay now and are not checked against the original (which cannot run
on his Apple Silicon Mac). Freezing the current replay as regression goldens (core Task 11.5) is allowed but not owed.
**App icon (Ben 2026-10-06, "can we get the icon macos27 compliant - so it's not in squiqle jail"):** the original goldfish
(BubbleTrouble.icns 512 px) as an Icon Composer document `BubbleTroubleX/App/AppIcon.icon` — Ben's pick from three previews:
light tile, bigger fish (scale 1.75); macOS renders the dark/clear variants itself. A shell-level exception to the 100 %
rule, by Ben's ask.

## D15 — Bubble Trouble X on Windows: cross-compiled, drawn Mac UI, bundled data, Mac app untouched (2026-10-06)

**Decided (Ben in chat, 2026-10-06, "windows port!" → "build it from end to end"):**
1. **Bubble Trouble X is the first Windows game** (Aki later).
2. **Built on this Mac:** open-source Swift toolchain + Swift's Windows SDK (x86_64) + Microsoft's SDK/CRT via `xwin`
   (Ben accepted Microsoft's licence for it); tested in CrossOver. A Windows PC build is the fallback only if the
   cross-compile proof fails.
3. **The Mac UI is drawn in-window** on Windows — menu bar and Carbon dialogs from the original DLOG/DITL — Ctrl for ⌘.
4. **Original data bundled** beside the `.exe` (D10). BTX's OS X data is already data-fork `.rsrc` — no extraction.
5. **The Mac app is not touched:** Windows gets its own port of the controller logic (`BubbleTroubleX/Windows`);
   shared engine pieces are new files only (HectorKit `PCMMixer`, separate `HectorKit/SDL` package with SDL3).
**Because:** keeps Ben's playtest build stable; HectorKit D6 already shaped the cores for this.
**Rejected:** extracting a shared driver out of `BTXController` (Ben: don't touch the Mac app while he playtests) ·
native Win32 menus/dialogs (less faithful) · user-supplied data.
**Plan:** `docs/plans/2026-10-06-btx-windows.md`. **Approved by:** Ben in chat.

## D16 — Windows port: toolchain proven; three parity rulings from the first Windows test run (2026-10-06)

**Facts (W0):** Swift 6.4.0 (swift.org macOS toolchain, extracted) + its Windows SDK + xwin 0.10.0 (MSVC 14.44, SDK
10.0.26100) + SDL3 3.4.16 cross-build x86_64 Windows from this Mac; CrossOver runs it. BTX core tests on Windows:
250 / 258 first run; the 8 misses have three causes.
**Decided (orchestrator, Opus 5.5 — no change to how the game plays or looks; Ben ruled the font licence himself):**
1. **JPEG without ImageIO:** BTX's 8 QuickTime-JPEG PICTs are decoded ONCE on the Mac at staging time by the same
   `CodecImage` and shipped as exact RGBA (`Data/Decoded/`), looked up off-Apple by content key. Pixel-identical to
   the Mac; a portable JPEG decoder is deferred until a game needs arbitrary JPEGs at run time (Aki/Ferazel ports).
2. **`.macOSRoman` is mis-tabled in Foundation on Windows:** HectorKit owns the table (`MacRoman`), used by HectorKit
   and the BTX core — HectorKit D6 rule 4 ("faithful decoding is our code, not the OS's"). Mac bytes identical.
3. **`UserDefaults` crashes under Wine:** additive `BTXPrefsBacking` protocol in the core; the Mac app's call stays
   `UserDefaults`; Windows stores the same blob in a file under `%APPDATA%`.
4. **Font licence (Ben, 2026-10-06):** ship the baked Apple Geneva / SF glyphs in the Windows build (private copy);
   swap for an open font only if it is ever shared wider.
**Approved by:** Ben (4); orchestrator rulings (1–3) under D15's "seat may settle" list.

---

## D17 — Aki Remaster mode: Ben's gate passed; smooth backgrounds, grain-free tile body, ⌘G (2026-10-06)

**Decided (Ben, after playing the staged Mac app and the iPad mini):**
- **Gate: PASSED** — "Looks right — done"; ⌘G "works" both ways (map, mid-level, paused, fullscreen).
- **Backgrounds:** the de-dithered set ("smooth background looks better in level") — Gaussian 0.7 before remacri; the plain
  remacri backgrounds (diagonal hatching from the 1990s dither) are dropped from the tool (plan C3).
- **Tiles:** "the remaster does look the best but the grain is a bit much" → option A1: `tile_pictures.png` faces stay remacri;
  `tiles.png`'s body/selected/hint/grey rows use a plain Lanczos 4× (remacri invented wood grain on them). Faint grain inside
  each face's own rectangle remains (reviewer note; Ben passed it).
- **⌘G** on the "Remastered Art" item (Mac menu + iPad menu bar): in fullscreen the menu bar is hidden (as in the original),
  so the toggle needs a key equivalent; ⌘G is free in both nibs.
- **Merge order:** the code lives on branch `aki-remaster` (cut from `aki-ipad`, Ben: "build on the iPad branch") and merges to
  main only after `aki-ipad` lands.

**Seat rulings during the build (within D11):** colour back-projection on every AI region (remacri lightened art, e.g. the pause
scroll); the live switch draws only — no game/clock writes ("pixels only" over the plan's full-redraw sketch) and discounts its
decode time from a running clock; hd art validated as exactly 4× and any bad file falls back to its original; HectorShell
presents k > 1 frames through triple-buffered IOSurfaces (k = 4 present ~0.4 ms; the CGImage path cost ~20 ms); masks stay
nearest (bit-exact) — tile outlines show 1-logical-pixel steps as in the original.
**Rejected:** plain backgrounds; full-AI tiles (A); AI tiles softened first (B); no-AI tiles (C); half-and-half tiles (A3).
**Approved by:** Ben 2026-10-06, in his words above.

## D18 — Windows port W0.5 + W3: parity landed, Proof B 260/0/0, HectorSDL; rulings closed during the build (2026-10-06)

**Facts:** HectorKit owns MacRoman (`MacRoman.decode/encode`, 7622be6) and a precomputed-RGBA registry in `CodecImage`;
the BTX core routes its four MacRoman sites through it; `btx-predecode` (Mac) decodes the 8 QuickTime-JPEG PICTs (20
bands) once; `BTXPrefsBacking` keeps the Mac's `UserDefaults` call. BTX core tests cross-built and run in CrossOver:
**260 passed / 0 failed / 0 skipped / 0 crashed**; Mac 261/0/0. HectorSDL (separate package `HectorKit/SDL`) smoke
in CrossOver byte-identical to the Mac.
**Decided (orchestrator, Opus 5.5 — none changes how the game plays or looks):**
1. **Windows test bar is 260, not 261:** the one test that exercises `UserDefaults` itself is Mac-only (D16.3); the two
   prefs tests that used a `UserDefaults` suite run over the in-memory backing off Apple, same assertions.
2. **MacRoman lossy encode** matches macOS Foundation exactly (checked over every scalar, ~1.2M combining sequences,
   ~4M random strings) except where Foundation itself raises (unencodable base + trailing combining marks) — ours
   returns `?`. No game string reaches it.
3. **Pre-decoded JPEG RGBA matches the Mac that ran `btx-predecode`** (ImageIO output is not promised identical across
   macOS versions); staging always regenerates it.
4. **CrossOver strips every `SDL_*` environment variable.** SDL drivers are chosen with `HECTOR_SDL_AUDIO_DRIVER` /
   `HECTOR_SDL_VIDEO_DRIVER`; automated runs must pass `dummy` (no real-time audio from automation — standing rule).
5. **HectorSDL key map = physical US/ANSI positions → Carbon `kVK_*`** (Ctrl→⌘ 0x37, Alt→⌥ 0x3A, Windows key→⌃
   0x3B, right-hand modifiers → the Mac's right-hand codes). Typed characters follow the US layout; layout-aware text
   for high-score name entry is W6's (SDL text input).
6. `HectorAudio` depends on `HectorResources` (both Foundation-only, no cycle) so `SndSound` can use `MacRoman`.
   HectorSDL declares macOS 26 (brew's SDL3 dylib); only Windows-port packages depend on it.
**Approved by:** orchestrator rulings under D15's "seat may settle" list.

## D19 — Windows port W4–W7: playable, staged for Ben's brother; rulings closed during the build (2026-10-06)

**Facts:** W4 `WinGameDriver` + `BubbleTroubleXWin` (attract demo = FILM 1 trace; Mac SDL and CrossOver dumps
identical), W5 in-window menu bar, W6 in-window DLOG/DITL dialogs + prefs, W4.5 integration (text input, full screen,
live resize, idle sleep), W7 `tools/windows/stage-btx.sh` → `~/Desktop/Bubble Trouble X (Windows)/` + `.zip` (87 MB /
37 MB; exe + 19 DLLs + `Data/`; GUI subsystem, icon, DPI manifest; stamp 83febbe / HectorKit 0467025). Fresh CrossOver
bottle: main menu, level 1, every dialog reachable by script — no crash, all dumps = the Mac SDL build.
**Decided (orchestrator, Opus 5.5; Ben lifted the cap and asked for a bundle his brother can test):**
1. **Window ▸ Minimize/Zoom stay greyed as on the Mac** (the Windows title bar has its own buttons).
2. **Menu shortcuts match the physical key only** (D18.5); typed text comes only from SDL text input while a field is
   focused (dead keys/AltGr/IME compose; no US fallback then).
3. **Omitted macOS-only menu items:** Services, Hide/Hide Others/Show All, Edit ▸ Special Characters…, AppKit
   additions, the Window menu's window list. About stays open behind a dialog as on the Mac.
4. **Window opens at integer-fit scale** (HectorShell D7): 1× on a Windows 11 1080p screen (taskbar), Ctrl+F gives 2×
   full screen. Non-integer windowed scaling would be Ben's call.
5. **Foundation on Windows traps in `String.replacingOccurrences`** on non-ASCII strings ≳64 bytes (probe-proven;
   `components`/`range(of:)` fine): Windows code uses a pure-Swift replace. The core's only use is the Mac-only census tool.
6. **The zip holds the files at its root** (Windows "Extract All" adds the folder). Unsigned private build; SmartScreen
   "Run anyway" documented. No installer, no signing (standing).
**Carried:** M5 (mouse in the same poll as a resize uses the old layout), M6 (menu shortcuts ignore key repeat),
DLOG 3000/3001 not script-reachable (date-gated), the missing-data box says "unzip the whole folder".
**Approved by:** orchestrator rulings under D15's "seat may settle" list; sound and feel are Ben's (and his brother's).

## D20 — Ambrosia-Classics is public; Windows test build shared as a GitHub release (2026-10-06)

**Decided (Ben in chat, 2026-10-06):** "let's just make ambrosia-classic a public repo instead and leave it there."
The repo `andiyar/Ambrosia-Classics` is PUBLIC (history scanned first: no secrets, no font files). The Windows zip is the
pre-release `btx-windows-test-1` (tag on 859ee35):
https://github.com/andiyar/Ambrosia-Classics/releases/download/btx-windows-test-1/Bubble-Trouble-X-Windows.zip —
anonymous download verified byte-identical to the staged zip. **Supersedes D16.4's "private copy":** the four baked
Apple-glyph `.btxfont` files (menu bar/dialog text only) now ship publicly, Ben's call knowing it. Original game data
public per D10. Ben reports the Windows build **plays with sound in CrossOver** (first ear check).
**Approved by:** Ben.

## D21 — Windows build has no menu bar; Ctrl shortcuts kept; window 640×480 (2026-10-06)

**Decided (Ben in chat, 2026-10-06):** "it looks silly. just get rid of it entirely. it doesn't need it. ctrl-f full
screen can be as given." **Supersedes D15.3 for the menu bar only** — the original Carbon dialogs stay drawn in-window
(DLOG/DITL, D15.3). The drawn bar, its tracker and the Alt alternates are deleted; D19.1 and D19.3 (about the
bar's items) lapse with it. The window is the 640×480 game screen alone, windowed and in full screen (no 20 px strip, no
offsets); at the integer-fit opening scale (D19.4, unchanged rule) that is now **2× on a 1080p screen** (Windows 10/11,
taskbar at the bottom) and 1× on 1366×768.
**Kept:** the Mac bar's key equivalents with its enable rules (`WinShortcuts`): Ctrl+F full screen, Ctrl+, preferences
(both off in play), Ctrl+M music, Ctrl+Shift+A sound effects, Ctrl+Q quit, Ctrl+Alt+M eaten (Minimize All: nothing
happens, as on the Mac); all off while a dialog is up. Physical keys only (D19.2).
**Dropped with the bar:** About (no shortcut, no other way in — `WinAboutPanel` deleted); Options ▸ Key Sets (no
shortcut; Preferences ▸ Keys still chooses the set); the check marks.
**Carried:** Geneva 10 and System Bold 12 (drawn only by the bar and About) are still baked, shipped and checked at
start-up — read by nothing; dropping them is a staging change for another day.
**Approved by:** Ben (the removal); orchestrator brief (shortcut list, About's fate).

## D22 — Deimos Rising builds next, ahead of Ferazel's Wand (2026-10-06)

**Decided (Ben in chat, 2026-10-06):** "my assumption is deimos will be 'Easier' than ferazel … let's let ferazel do
its own thing in its own session and move on to steps 2 and then 3 for deimos." The Deimos RE bank is closed (100 % of
game code read, 938 rows = 716/222/0), so Deimos goes straight to build work: **step 2** = Phase 0 for Deimos (HectorKit
decoders for its data — stored-ZIP paks, im08/im16 images, soun audio — and a `Deimos/Core` census proving every
original file opens), then **step 3** = the build plan (contracts from the bank → playable app on HectorShell). Ferazel's
RE wave 2 continues in its own session; Ferazel's build waits. Ben's list order (CLAUDE.md) otherwise unchanged.
**Approved by:** Ben.

## D23 — Aki 1.0 public release: notarized DMG, Remaster art in, macOS 26+ icon; iPad merged first (2026-10-06)

**Decided (Ben in chat, 2026-10-06):**
1. Merge order "iPad first, then Remaster" — both on main (5e6755d, then 9bd0e56).
2. First public Aki release is **1.0** (Ben chose 1.0 over a 0.9 pre-release, knowing Phase 3 — Level Editor, `.aki` levels
   — is not built), a **notarized + stapled DMG** with the **Remastered art included** (hd-4x, ~207 MB). "Need to notarize
   and stamp builds of course — look for notarisekit for the method": `tools/package-aki-release.sh` builds Release,
   assembles the original 1.2.0 data verbatim (pinned sha256 manifest, checked on the assembly, after signing and again
   inside the mounted DMG), signs with Developer ID + hardened runtime + timestamp, then calls notarize-kit's
   `notarize-bundle.sh` + `package-dmg.sh` (profile `oniarm64-notarize`). Tag `aki-1.0`, notes `docs/release/aki-1.0.md`.
3. **macOS 26+ app icon** (Ben: "not in squircle jail"; picked green felt from four Icon Composer renders):
   `Aki/App/Mac/AppIcon.icon` — the original aki.icns tile stack, upscaled 4× (Upscayl high-fidelity-4x), glass off, on a
   green-felt gradient. A deliberate departure from 100 % on an OS-owned surface, Ben's call. The upscaled derivative
   `Assets/tiles.png` is committed to the public repo (Ben's standing "shareware data may live in git" overrule, D10's
   exception recorded here). The original aki.icns still ships in Contents/Resources with the data; iPad icon unchanged.
**Seat rulings (inside the standing 100 % ruling):**
- (a) Apple's OsakaMono.ttf is NOT in the public build (Apple's font, not redistributable): Release Notes show in Menlo
  unless the Mac has Osaka-Mono installed — an exception to D4.2 for the public build only; stage-aki.sh still bundles it.
- (b) `CFBundleShortVersionString` stays **1.2.0** (the replicated game); `CFBundleVersion` = the release (**1.0**), so the
  About panel reads "Version 1.2.0 (1.0)"; the notes explain the two numbers.
- (c) The GitHub release is created as a **draft**; Ben tries the downloaded DMG, then it is published.
- (d) Tested only on this Mac (macOS 27.0.1, Apple Silicon); the binary is universal and the notes say Intel and macOS
  15/26 are untested. The Menlo Release-Notes path cannot be exercised here (Osaka-Mono installed system-wide).
- (e) Noted, not changed: the iPad build scales to fill the height, smoothed (WHAT-TO-EXPECT-iPad, Ben on the mini), which
  supersedes D7 R3's integer scaling — recorded here as as-built.
**Approved by:** Ben (1–3); seat (a)–(e).

## D24 — Deimos Rising data in git; Phase 0 layering (2026-10-06)

(Planned as D23; D23 was taken on main by the Aki 1.0 release while this branch was cut, so this is D24. The Phase 0
plan's "D23.n" references mean D24.n.)

**Decided:**
1. **Deimos original data is committed** at `Resources/Deimos/Data/{Paks,Local}` (Ben's standing "shareware data goes in
   git" ruling, over D10's "unchanged for now"; D20 public repo). Exactly five files, byte-identical to the archive copy
   (`Deimos Rising 1.0.6 (volume)/Deimos Rising/ Data`), SHA-256:
   - `Paks/Audio.pak` 1,702,614 B `b46ce0711faca7ce0cd33c850c41e88bd3be7f7289eee9d80fe03c7013bb1039`
   - `Paks/Game.pak` 54,956,985 B `3ae865a9ee3b005dc10368de847e4a3dea402dc1a911bbd09f0728153aceee09`
   - `Paks/Interface.pak` 2,849,896 B `de7d2dd349f208f72eae156820c48c791f06e46b24ec5816e1a1bed0dfea0d93`
   - `Paks/Music.pak` 13,601,894 B `3ee906a6f885ba466645ea53bab6aebba54840d756a63212f895364cebadc455`
   - `Local/film/Last Film[last].film` 40,296 B `cf5f42cc475c011e750d3fe268e06f890ee0aac4b1678d79bcf2dca5b3e1b897`

   The original folder ` Data` (leading space) is renamed `Data` — the space is a Windows/shell hazard. Not committed:
   `HID.bundle`, `Icon\r`, `.DS_Store`, the PEF binaries. GitHub's 50 MiB warning on `Game.pak` is accepted (below the
   100 MB hard limit). `.gitignore` `/Resources/` → `/Resources/*` + `!/Resources/Deimos/` (Aki's `Resources/Aki/*.app`
   symlinks and anything else under `Resources/` stay ignored); `.gitattributes` `Resources/Deimos/** binary`.
2. **Layering** (refines D22's parenthetical; plan Q2): STORED-ZIP + AIFF/AIFC/WAVE decoders go in HectorKit (generic);
   GIF/TGA, tag naming/index, text, film, sprite plates in `Deimos/Core` — no other Ambrosia title ships GIF/TGA (kit
   two-game rule). Promote GIF/TGA to the kit only if a second game needs them.
3. **DeimosCore tests read the committed data** — no env var needed, never skip; `DEIMOS_DATA` overrides the location.

**Rejected:** Git LFS (breaks anonymous clones of the public repo past the free quota; no hard limit forces it) · data out
of git behind symlinks (the Aki/BTX pattern — superseded for new games by Ben's ruling) · keeping ` Data` with the space.
**Approved by:** Ben (standing ruling, data in git; D22 scene); layering per the orchestrator's Phase 0 brief (plan Q2: orchestrator's call — Ben, 2026-10-06, left it to us; not his ruling). Plan Q1 (app resource fork: 12 PICT, 6 DITL incl. the config dialog) → **yes, C8 runs** — orchestrator's call, Ben told.

**Addendum — C8, the app resource fork (2026-10-06):** Q1 yes — orchestrator's call, Ben told. The application's
resource fork is committed as the data-fork file `Resources/Deimos/Deimos Rising.rsrc` (151,602 B, SHA-256
`9fb61088c4d97d1b35117c82a44a0f1f848fb78eb7561b6e3964df623410d3f5`, = the archive's `Deimos Rising/..namedfork/rsrc`;
binary per `.gitattributes`). Census section 9: 39 types · 140 resources · PICT 12 (decoded 12) · DITL 6 (decoded 6,
items 76). Nine PICTs (130 135 190–193 195–197) are 0x009B DirectBitsRgn, 16-bit packType 3/1 — decoded since
HectorKit `c4a8866` (HectorKit D11; doc minors + floor 301 at `33d4dee`). HectorGraphics is a dependency of the census
executable and the test target only, never of the Foundation-only `DeimosCore` library.

**As built — Phase 0 DONE (2026-10-06):** HectorKit main `33d4dee` (tag `v0.3.0` = `13c8f9b` + PICT 0x009B `c4a8866`
+ doc minors), zero-skip gate floor **301**, PASS. `Deimos/Core`: DeimosCore + `deimos-census` + two test targets,
**104 / 0 / 0** (DeimosCoreTests 99 · DeimosCensusTests 5). Census Totals `entries 872 (pak 871 + local 1), decoded
872, failures 0`; section 9 `rsrc 39 types · 140 resources · PICT 12 (decoded 12) · DITL 6 (decoded 6, items 76)`;
`docs/deimos/data-census.md` = stdout (golden test). Reviews R-A…R-E all fixed; the GIF no-end-code leniency is
invariant 4's one deliberate exception (plan As built). MED items carried to Phase 1: 24→16 truncation and the 8-bit
inverse-table mapping (plan note 15), the game's own continuous-IMA effect decode + mixer (note 21); Ben's eyes: INDEX
#10 — `deimos-census --render out/deimos-render` → `menu.png` upright.

## D25 — Bubble Trouble X 1.0 public release: Mac (notarized DMG) + Windows (zip) in one release (2026-10-06)

(D24 is taken on the unmerged `deimos-phase0` branch.)
**Decided (Ben in chat, 2026-10-06):** "BTX - done for now. V1.0. notarise as per notarise kit process, and get it on
github, with a readme update" and "should publish windows as download not test build right? it's done?" — yes: the
Windows build was played to level 20 with sound on a real PC (D19 lane), and its source carries the D14 volume law.
1. One GitHub release `btx-1.0` (tag on 47d7c98, the commit the DMG was built from) with both downloads:
   `BubbleTroubleX-1.0.dmg` (`tools/package-btx-release.sh`, the Aki script's shape — pinned 7-file data manifest checked
   before signing and inside the mounted DMG, universal, Developer ID + hardened runtime, notarize-kit notarize + DMG) and
   `BubbleTroubleX-1.0-Windows.zip` (`tools/windows/stage-btx.sh`, stamp 6832da1, not code-signed — SmartScreen asks once).
2. Versions as Aki (D23 b): `CFBundleShortVersionString` 1.1.0 (the game), `CFBundleVersion` 1.0 → About "1.1.0 (1.0)".
3. Created as a **draft**; Ben downloads and tries it, then it is published (D23 c). The `btx-windows-test-1`
   pre-release is superseded (its notes point to btx-1.0 once published).
4. The Windows WHAT-TO-EXPECT drops "private test build" / "we could not listen to it" wording.
**Approved by:** Ben (1, 3); seat (2, 4). Ben tried the downloaded DMG and said "publish" — published 2026-10-06;
`btx-windows-test-1` notes now point to btx-1.0.

---

## D26 — Ferazel's Wand build: Ben's five brainstorm rulings + the seat's design rulings (2026-10-06)

**Decided (Ben, in the brainstorm of 2026-10-06, orchestrator Claude Fable 5.1; design `docs/plans/2026-10-06-ferazel-design.md`):**
1. **Done = the whole game, Windows included** — all 24 levels, map, chapters, saves, bosses, Xichra, victory; on the Mac
   (HectorShell) and Windows (the SDL shell BTX proved). Not a first slice.
2. **First gate = level 1 "A Scent Of Peril" look-and-feel** — drawn exactly as the original's frame order, camera on the
   keys, Ferazel standing/walking in place, **no physics**; Ben judges "does it look like Ferazel".
3. **Gate order = front end early:** look → Ferazel moves → title/menus/world map/saves/conversations → spells and items →
   enemies → bosses → Windows + notarized release. One plan per phase, written when its turn comes.
4. **Screen = 640×480 at whole-number scale**, fullscreen the largest whole multiple with a black border (D3/D7 R3 shape);
   the 8-bit palette, parallax strips and lighting tables reproduced as computed. Rejected: smooth fit (Aki's rule),
   widescreen view.
5. **Feel oracle = YouTube longplays + a Let's Play of part one Ben will link + his eyes at each gate.** Rejected:
   running the original in SheepShaver, the demo build.
**Seat's rulings under the standing 100 % rule (design §3–§7, plan `docs/plans/2026-10-06-ferazel-phase1.md`):**
- Three layers (BTX D12 shape): `FerazelCore` (Foundation + HectorResources), `FerazelRender` (+ HectorGraphics/Audio,
  headless 8-bit compositor, frame goldens), `Ferazel/App` on HectorShell; later `Ferazel/Windows` on HectorSDL. The
  kit gains only PICT pixels-as-stored + a public ColorTable (K1) and uses the Deimos session's `AIFFAudio`.
- Original data in git at `Resources/Ferazel/` by the Deimos D24 shape (six `.rsrc` forks + 28 AIFC tracks; the PEF
  binary, the Documentation app and the SoundEdit leftovers stay out); tests never skip; `FERAZEL_DATA` overrides.
- **Colour search (the bank's one LOW, widened by the planner's probes):** every face pixel AND every computed table
  goes through QuickDraw's `Color2Index` at load time (the sheets carry their own palettes; 326 are 32-bit with
  `ditherCopy`). Ruled model: exact match → that entry (ties → lowest), else the 4-bit inverse-table rule;
  32-bit sheets Floyd–Steinberg-dithered through the same search; 1-bit masks bypass it (0/0xff). Both the exact and
  5-bit searches and "no dither" stay selectable in tests; measured disagreement on CLUT 202: 75,461 of 211,731 table
  entries, ~1 % of the player's pixels. On every gate card until Ben's eyes or a capture from a real Mac settle it.
- PICT 257's short last row reads 0 (design §11 said "whatever the port held" — the alternative). Phase 1's camera stub
  accepts arrow keys as well as the keypad (a stub; the game proper keeps the original defaults + Options dialog).
**Rejected:** the Aki two-layer shape (no headless pixel tests, Windows would duplicate the compositor) · one engine
target with pixels in Core (D6) · data out of git behind symlinks (superseded by D24).
**Approved by:** Ben (items 1–5, in his words, 2026-10-06); seat rulings recorded for the executors, Ben told.

## D27 — Deimos Rising build: Ben's four rulings (2026-10-06)

**Decided (Ben, 2026-10-06, answering the orchestrator's four forks after Phase 0 closed; same shape as Ferazel D26):**
1. **Done = the whole game, Mac + Windows** — every level, title/menus, high scores, demo films, Options/controls
   dialogs, every weapon and boss; Mac on HectorShell, Windows on the SDL shell BTX proved. Built in gated phases.
2. **First gate = level 1 look, no gameplay** — level 1's scrolling background, the ship drawn in place, HUD/score bar,
   drawn exactly in the original's frame order; Ben judges "does it look like Deimos".
3. **Screen = 640×480 at whole-number scale**, window and full screen the largest whole multiple with a black border
   (the original: DrawSprocket 640×480×16 full screen). Rejected: smooth fit (Aki's rule).
4. **Feel oracle = YouTube longplays + Ben's eyes at each gate**; the RE bank is the logic oracle. Rejected: running the
   original in an emulator; eyes only.
**Approved by:** Ben.
