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
**As built (C0, 2026-10-06):** `Resources/Ferazel/` holds Ferazel's Wand 1.0.3 byte-identical (`cp -p`, `cmp` clean)
from the archive mirror's installed `files/`: six resource forks as data-fork `.rsrc` — `Ferazel's Wand.rsrc` 264,712 B
`5d1165339d64b4dd360043e62e1baa888762bac69d3555e985a9ce54ec7b401a` · `World Data.rsrc` 5,511,430 B
`c1b208543ee501219a631ce0a5a0151c818ff15f9aa41090afb5586c8500d541` · `Backgrounds.rsrc` 15,821,213 B
`110db531084f970473497f25541736906fa621970c654758b46a28d2ffcf9b1b` · `Sprites.rsrc` 10,028,422 B
`795ac20d2a5a61ac2f18a31802a76ebd871e028f4bacd1e5bdaa38493e6608f4` · `Sounds.rsrc` 2,448,841 B
`39cd36d5bd56908afa6bc607d360592db2172e140be231bbfeaecb8c61c5893f` · `Titles.rsrc` 4,005,325 B
`b1d30e7720f8b30d782824216fea52527a78c2bff761ba744a227d98d210df9b` (SHA-256 re-measured, equal to the plan's Research
note 1) — and `Ferazel's Wand Music/` with the 28 extensionless AIFC tracks `01`..`30` minus `21` and `27`. Totals
38,079,943 + 47,201,968 = 85,281,911 B; largest file 15,821,213 B (under GitHub's 50 MB warning). Stays out: the PEF
binary `Ferazel's Wand`, the `Ferazel's Wand Documentation` app, the 28 `NN.rsrc` SoundEdit leftovers, the five zero-byte data-fork stubs
(`Ferazel's Wand Backgrounds` etc. — the resources live in the `.rsrc` forks), the 1.0.3 Notes / License / Ambrosia FAQ /
Ambrosia Products FAQ texts, the web-site link files, `Icon_*`, the InputSprocket / USBHID files, the `.pict`
files, `.DS_Store`. `.gitignore` re-includes `!/Resources/Ferazel/` (other games' data stays ignored);
`.gitattributes` `Resources/Ferazel/** binary`. `FERAZEL_DATA` overrides the folder. Rejected as in D24: Git LFS
(breaks anonymous clones of the public repo past the free quota) · data out of git behind symlinks.
**As built (C4, 2026-10-06) — Color2Index measured:** `FerazelCore.TableRequests` computes every table's requested
16-bit RGB (lighting-tables §3–§7, HIGH) and `FerazelRender.ColorSearch` maps it: `.exactNearest` (least squared
distance, ties → lowest; black in CLUT 202 → 0x60), `.inverseTable(bits:)` (bit-replicated cells), `.ruled` (exact
match → lowest, else 4-bit; the default). Measured by `ColorSearchTests` on the committed data: `.ruled` and
`.exactNearest` disagree on **75,461 of 211,731** requests on CLUT 202 (tint 1,168/3,603 · water 397/1,280 · redden
1,885/6,144 · ambient 1,887/4,096 · pairs 0154+015c+0158 70,124/196,608) and on **1,178,146 of 3,387,696** over all
sixteen level CLUTs (with the overflow ruling below; 1,178,143 before it) (202 75,461 · 210 77,037 · 212 73,640 ·
214 72,846 · 216 78,302 · 218 74,684 · 220 71,105 · 222 63,104 · 224 68,552 · 228 67,849 · 236 79,478 · 238 73,737 · 240
78,219 · 242 73,026 · 246 77,463 · 248 73,643) — about a third,
dominated by the blend pair tables. The bit-replicated inverse table reproduces lighting-tables §1.2 exactly (agreement
with exact over sprite indices 0..0x9f: 39..153 of 160 at 4 bits, 66..157 at 5) and §1.4's level spread (1:138 … 0x16:71),
and water table 0 @0x9e = 0x84 exact / 0x49 4-bit. Every chosen index stays LOW. Ben (2026-10-07): follow the binary —
water 1, glow 014c and grey-pull 0144 transcribe the original's 32-bit overflow; fused multiply-adds as the PPC code has
them (lighting-tables ⚑ Corrections). (Glow 014c and grey-pull 0144 are now in `TableRequests.Pair`, outside the census.) **Dither ruling (plan Research note 10):**
every 32-bit PICT says `ditherCopy` (mode 64), so the conversion uses `.errorDiffusion` — Floyd–Steinberg, top-down,
left-to-right, in 16-bit RGB, quantised by the active `ColorSearch` model — as the default, `.none` selectable; LOW; on
the gate card. Rejected: silently ignoring mode 64 (would drop a visible property of 290 sprite sheets).

**As built (C5, 2026-10-07):** `FerazelRender` faces (PICT → indices through `ColorSearch`, `.EncodeRect` RLE, face /
plain / water / blend sheets, tile sets). Two conversion-CLUT corrections to the plan, seat ruling under Ben's
follow-the-binary precedent (bank ⚑ Corrections in sprites-backgrounds-sounds): **FG and FG-water convert under the
level CLUT `0x285c`** (201 for level 1), not level+base — `.LoadLevelTilesets` sets it on entry and only BG and pattern
switch to `0x285e` (decompile l. 1576–1577, 950–955, 970–1031, 1049); **the fixed sets 183/185 convert under clut
199** (`.InitAppGlobals` l. 412–413, `.InitGameGlobals` l. 827/840), so the §8 blend mapping is in CLUT-199 indices.
Measured: FG 200 under 201 — 239 colours, 30 exact, `.ruled`/`.exactNearest` differ on 44 colours / 5,400 px; BG 203
and pattern 206 under 202 — 234/28/67/13,898 and 200/30/73/8,606; blend 185 under 199, weights 0/1/2/3 =
27,701 / 3,181 / 5,601 / 1,528 with 60,293 transparent (`.ruled`), 27,659 / 3,253 / 5,571 / 1,538 with 60,283
(`.exactNearest`). The ditherCopy model as built: `.errorDiffusion` default, `.none` selectable; PICT 2922 under 200
`.ruled` — the two models differ on 704 of 3,360 px. The water loader leaves face +0x30 unwritten (built 0); the
`.single` loader refuses a picFrame not at (0, 0). **Open hazard (gate card):** the plain loader's reused
`NewBlitPort` may hold stale bytes where a cell reaches past the frame (PICT 257 PxBack cells 30..35); built as 0
(design §11).

**As built (C6, 2026-10-07):** `ferazel-census` (thin `main` over framework-free `FerazelRender.FerazelCensus`;
ImageIO only in `Sources/ferazel-census`, for `--render`) — its stdout is `docs/ferazel/data-census.md` below the rule:
`Totals: items 1,108 decoded, failures 0` (770 PICT · 79 clut · 172 `snd ` · 24 `Mlvl` · 29 `Mcnv` · 28 music · `Mwld` ·
`Mmap` · 4 `STR#`), every plan C6 summary line reproduced except the two Ben's follow-the-binary rulings move
(16-CLUT Color2Index 1,178,146 of 3,387,696; FG 200 under clut 201 44/239 colours 5,400 px). `Ferazel/Core` tests
**60/0** (C5 56 + 4 `CensusTests`). Built on HectorKit main `4ca2e18` (`v0.3.0` + 8; the plan expected `522feb8`,
an ancestor — HectorKit main moved on with the Cythera K1 work).
**Ben, 2026-10-07 — duplicate-colour tie-break decided at the gate:** clut 201 holds 162 pure blacks (1..160, 254,
255); `.ruled`'s "exact match → lowest index" sends FG 200's 8,443 black pixels (FG converts under 201) to index 1,
which the screen clut 202 shows as light yellow (FFFF,FFFF,7F7F) — yellow specks on every FG edge (C6 review). Which
duplicate QuickDraw's `Color2Index` picks is the open LOW. Ruling: build both tie-breaks selectable (lowest, the
current default, and highest — 255 here, black in both cluts) and show Ben both at the Phase 1 gate; not built in C6/R1.
**As built (R1, 2026-10-07):** LOCKED S3 seam types + `FerazelPrefs` (`.InitPrefs` defaults), `InputActions`, `KeyState`;
`LevelTables` (C4's requests resolved through the chosen model, built against clut 202 = level+base — 1001ad04 → `ff8c`,
1001ff34/10020408/10020a8c → `fe94`); ports `000c`/`0008`/`0004`; `TileGridRenderer`. Follow-the-binary readings, both
Opus review legs CONFIRMED at the addresses (bank sprites-backgrounds ⚑ Corrections 4–6, plan Bank corrections item 9):
`.RedrawScrollGrid` is **strip-incremental** (`.SetScrollLocation @10012848`) and draws tiles into **port `0004`**, copied
to `000c` by `.WrapRectBlitX`; the whole window is `.RedrawEntireScrollGrid @10013fd0`, so S3 gains the case
`DrawOp.redrawEntireScrollGrid(h:v:)` (a case added, nothing renamed); mask `0008` has no per-frame fill, 0xFF per redrawn
cell, 0x00 under the FG stamp; blend cells read the 80..95-overwritten kind table → **1,560** on level 1 (plan said
1,335, raw table); overlay pattern only for o2 == 95, never tinted. Measured: 5,482 of 44,473 FG-face pixels in the
start window land on 0x01..0x9f where clut 201 ≠ 202 (the tie-break item above). Open, carried: table `0148` (the
`.BuildTintTable` brightness table, read only by `.BlitEncFaceTrans*`) not in `LevelTables` — R4; levels 50, 51, 67 skip
one `.AnimateCLUT` step in `LevelTables.forLevel` (documented, Phase 1 draws level 1 only); ring helpers floor-mod
negatives where the binary truncates, and the wrap checks use the face size where the binary passes 0x20 — unreachable on
shipped data. `Ferazel/Core` **69/0**.
**As built (R2 + R3, 2026-10-09; Opus implementers, Opus-only legs — R2 one leg with dump re-read, R3 two legs):**
R2 — per-cell darkness reaches tiles **inside `.RedrawScrollGrid`**: after each cell's tile draws it calls
`.LightAnyBGTile/FGTile/FGOverlayFGTile/FGOverlayBGTile(…, 10)` (bl `100137c8`, `10013c70`, `10013d64`,
`10013ec0`/`10013ee4`), each gated `prefs+6 != 3` → `.WrapLightTile` → `.DrawLightOverTile @1001c934` (no light and
D ≠ 0 → ambient remap of the copy-run pixels in port 0004). `.DrawLightsOntoTiles` only redraws op-marked cells (none at
level-1 start). Seat ruling (follow the binary): R2 also edited `TileGridRenderer` for those call sites + an Effects
parameter (default 1 = lit; R1's tests pass Effects 3 and keep their hashes). Follow-the-binary corrections (bank
lighting-tables ⚑ Phase-1 note): `.BlitLightOverFaceClip` uses ambient on the light face's first and last rows;
`.DrawLightOpOverTile`'s ambient fallback is gated on hdr+0x2706 > 0, so it remaps at D = 0 too; `.PlainWrapFGTile`
draws FG-water before the blend and `.PlainWrapFGOverlayTile` tints in water without the 0x26c6 test. Measured: level-1
start frame darkened FNV `97fa2462814fd12a` (199,164 of 266,240 px change); light tables `.ruled` vs `.exactNearest`
on clut 202 differ on **151,568 of 450,560**. Light face 806 (84×84 cells of a 192×192 PICT, QuickDraw scaling) is
refused by name. R3 — `.DoubleBlitPPCParallaxOneLayer` as written (§1.1–§1.5), `PxSprites` in FerazelCore. Follow the
binary, both legs CONFIRMED: strip sprites are **N + 1** copies (k = 0…min(N, 31 − count), `1003372c..10033740`, slots
count + k), so 9/12/12/3/9/2 sprites on levels 10/30/40/45/62/67, effective cap 16 per call; the corner piece is always
composited through `.DoubleBlitUniversal` (`100178b8 b 100178c8` — the CopyBits at `100178bc` is unreachable); in
line-skip mode an odd-top call starts one screen row lower but reads its first source row (`10017a6c..10017a78`,
`10017fb0..10017fcc`). The plan's level-1 probe "re-decided at 273→274 and 410→411" is half wrong: one call reaches view
row 383, so only 273→274 occurs. Header 0x271e is 0 on all 24 levels. Refused by name (not built in Phase 1): the Fire
variant (levels 52, 55) and the ripple flag hdr 0x26ca (levels 11, 18). Open, carried: the strip face's conversion CLUT
when 0x26cc is unset (R4); op-grid 8-entry overflow and the stale-r21 overlay o2 not modelled (MED); the per-call byte
toggle `_DAT_100a00c8` not modelled (no reader found). `Ferazel/Core` **81/0**.

**As built (R4, 2026-10-09; Opus implementer, two Opus legs + one re-review, all ACCEPT):** `SpriteSlot`, `ActiveList`
(`.MTInsertSprite` l. 30556: a new sprite goes after every equal-or-lower signed layer), `IdleSprites`
(`.HandleIdleSprites @100081ac`: window h−0x18..h+0x278 × v−0x18..v+0x198 ∪ player hot rect, outset 0x60, 511
entries, `+0x1c6` gate; all level-1 margins 0), ◇ `SetupFaces` (42 level-1 types), and `SpriteBlitter`
(`.WrapDrawSprites` + `.WrapDrawFace` dispatch, mask pass, `.DrawLightOverFace` via `.WrapLightFace` on R2's tables,
and `.WrapEraseSprites @10014a58`, which R1's precondition assigned to R4; the op itself is R5's). Level 1: 162 active
records; 10 spawn now and 13 activate at scroll (0, 10) (Research note 16 holds). Setup modes 0 ×148, 0x10006 ×8,
0x10007, 0x10010 ×3, 0x10016 ×2. Follow-the-binary readings, CONFIRMED at the addresses (bank draw-effects, lighting-tables,
physics ⚑ R4, sprites-backgrounds item 7): `.GameLoop` playerX = (x−32)+50 = 133 before `.SetupLevel` (l. 5150–5165)
mirrors every Walker; the draw cull never culls (`10014544..7c`), right clip h+0x280; erase offsets by the scroll, not
the sprite (`10014c08..14`), and an empty SectRect re-stamps cell (0,0); sprite sheets convert under clut 200 (boot /
cached-flag 0) or 202 (cached-flag 1, `1008901c`); the strip face with 0x26cc unset converts under 200 (l. 2273, closes
the R3 carry); **level-1 Setups add 68 lights** at Effects 1 (24 at Effects 3; torches 801, Xichrons/money bag 822,
sphere + item 810). R2's "no level-1 lights" premise is wrong: `SetupFaces` exposes them, wiring is R5/R6. Seat rulings:
mode 0xb is refused by name (no level-1 `+0x89` sprite, never reached), so table `0148` is still not built; the Crawler
1712 Setup face (PICT 1500) is absent from the data, so the Handle's face 1712 is drawn. Gate card: 22 types draw the
first face of the sheet their Handle uses; types 1485, 2710, 2713, 2714, 3002, 2842, 1700, 1705, 1760 and 1720 are left
with the PICT 150 placeholder at Setup, and Phase 1 draws the loaded face (what re-faces them in the binary is not read);
platform radial placement, siblings and the 1485 spokes are not spawned. Open, carried: the Setups' `FastRand` calls are
not modelled (⚑ modelled on level 1 by Phase 2 F1, 883b493) (walker `1006740c`/`10067760`/`10067780`, every Bonus `1005e8c0`, Xichron `1005db3c/4c/60`, torch
~~`1005df24`~~ `1005e110` [MED]; ⚑ F1 2026-10-10: `1005df24` −R(10)−5 is the money bag 0x50c, the torch is R(10)); `lightFace` uses (0,0,h,w) where the binary reads the light face's +0x58 rect (l. 15179, MED-equal);
light 810's face behind `PTR_DAT_100a088c` is unresolved; the lit path refuses D = −1 where the ambient path accepts it.
`Ferazel/Core` **88/0**.

**As built (R5, 2026-10-10; Opus implementer, one Opus leg MERGEABLE + one fix round):** `FerazelSession.step` = one
`.GameLoop` iteration (l. 5224–5290): `.FindUpperLeftCorner`, then `.PaintFrameWrap @10011cf8`, then the status bar.
`Camera` transcribes `.FindUpperLeftCorner @1000b5ec`, and ◇ `PlayerPose` / `CameraFocusDriver` are the Phase-1 stubs.
Follow-the-binary readings, all CONFIRMED by the reviewer at the addresses:
(1) **The first scroll is (0, 0) and the view pans in**; the plan's "(0, 10), no pan-in" was wrong. The camera starts
at origin − 0xd0 (l. 5168–5195). It reads the focus (fd44/fd40) at l. 5932, which `.SetupPlayerSprite` sets to the
sprite origin (83, 143) (l. 42825–42840). `.PlayerScroll @1004c528` moves the focus to (133, 202) only from inside the
player Handle (l. 46423), after the first draw. The eased pair is never clamped (only the scroll point is, l. 6170–6191).
v first reaches 10 on the 24th call, and the eased h settles at −176. This is a new measurement (plan ⚑ note 10).
(2) **A skipped "Reduce frame rate" iteration drops only `copyToScreen`.** The tiles, lights, sprites and erase still
run (l. 9254–9450). With prefs[0] set, the FIRST iteration is the skipped one (l. 5241–5245).
(3) `.SetupLevel` already draws the whole grid at (0, 0) (l. 2577–2582). At level start the strip op comes before the
entire-grid op (l. 5210–5211); SeamTests `levelStart()` was reordered to match. The level-start status bar is at l. 5216.
(4) The first walk frame shows 1020[7], i.e. 0xc + 2 in the same frame (handlers l. 2134–2187); the turn sequence is
handlers l. 2207–2238.
(5) Facing comes from the held key. `.HandleKeys` sets it from the sign of vx (l. 47377–47431), and on the first frame
that sign follows the key.
(6) The menu bar is hidden by `.main` (l. 8280) and `.MainMenu` (l. 7349); `.ContinueGame` hides it on resume (l. 6877).
Added: `DrawOp.wrapEraseSprites`. The 68 Setup lights are exposed as `session.lights`; R6 fills the light slots from
them. Not built (stubs): the camera look-ahead, the `FastRand` fidget reset, sprite 0x4c4, the chapter screen, music
fades. `.statusBar` carries no full/incremental flag, so the level-start (0,0,0) and per-frame (1,0,0) calls look the
same [LOW]. `Ferazel/Core` **94/0**.

**As built (R6, 2026-10-10; Opus implementer, one Opus leg MERGEABLE + one fix round):** `StatusBar`, `TextRasterizer`
(with a box-drawing test stub), `FrameRenderer` (executes R5's `FrameOps`, including the skipped-draw rule and the erase;
it fills the light slots from `session.lights` first-free after `RemoveAllLights`, l. 2269, so it is the only source of
the lights), and `IndexedFrame.rgba(through:)`. Follow-the-binary readings, all CONFIRMED by the reviewer at the addresses
(bank spells-items §6 ⚑ Phase-1 note):
- The **magic bar is at x 419** (0x1ab − 8, l. 4527–4567), not the plan's 214. At the start value 560, what shows at
  x 214 is the 70-px breath overlay.
- The text is font 20, size 12, bold, white on black rects (`10008cac..cd0`, `10008d30..d64`).
- PICT 132 is converted under **clut 199** (l. 470–472). `.UpdateItemStat` also draws at level start (l. 4911).
- `.CopyBitsCT @1000001c` copies keep raw indices (the bars and the status-port copies); the icon copies translate [MED].
- `.HandleLights` runs between `.DrawLightsOntoTiles` and `.WrapDrawSprites` (l. 9205).
- The PICT 129 rect at `DAT_100a266c` is (0, 0, 480, 640), read from pidata.
- **Frame 1 has no player face**: `.SetupPlayerSprite` leaves +0xc0 = 0, and the Handle sets the face after
  `.WrapDrawSprites`.
Goldens, NEW measurements (`.ruled` colour search, error diffusion, the 68 lights, box-text stub), deterministic over two
reviewer runs:

| Golden | Scroll | FNV-1a |
|---|---|---|
| frame 1 | (0, 0) | `9db8f32f7e3d88b4` |
| right held, frame 30 | (4, 10) | `f6296c7e706130f3` |
| right held, frame 60 | (226, 10) | `e7a951e3eafca30a` |
| hash of all 60 frame hashes | — | `3c5aee2b87819db6` |

Seat changes: `FrameRenderer.apply` throws; the max values and the start inventory are StatusBar constants, because
`StatusBarState` has no fields for them. The item-stat redraw trigger is simplified (the binary's is l. 4885–4918; the
seam carries no key or flash state) [LOW]. The duplicate-black tie-break (Ben 2026-10-07) is still unbuilt and goes to
A1. `Ferazel/Core` **100/0** — Phase 1 core complete.

**As built (A1, 2026-10-10; Opus implementer, two Opus legs MERGEABLE + one fix round, re-reviewed):** the `Ferazel` app
target on HectorShell (`Ferazel/App`: Main, Controller, Assets, Audio, CoreTextRasterizer, Info.plist, AppIcon.icon) and
the project.yml merge. Seat rulings: the package path is the symlink `Ferazel/FerazelCore → Core` (D13.8 precedent;
`Aki/Core` already owns the name "core"); the window uses Deimos's style (no close box), `.integerFit`, content exactly
640k × 480k with k = 3/2/1 by whether the visible frame holds the whole window (title bar included). Measured: 2560×1440
screen → k 2, window 1280×992, backing draw rect (0,0,2560,1920) edge to edge. The black border Ben saw on first sight is
the game's own screen (PICT 129's frame around the 608×384 view at (16,8), engine §3), not the shell.
Follow-the-binary readings (`.GameLoop` l. 5244–5291, both legs CONFIRMED): with prefs[0] set, the non-drawing
iteration has **no wait** and the drawing one waits 4 ticks from **its own** start (the plan's "pair capped at 4 ticks"
paraphrased it). Clock: a 240 Hz `ShellIdleTimer` (a 1/60 s timer beat against the tick counter into 3-tick gaps; Deimos
precedent) runs one step when ≥ 2 ticks have passed since the last step's start; missed steps are dropped. `.SetAIFFMusic`
(l. 41869–41921): track outside 1..32 → 1, missing file → n−1 (21, 27 absent); decoded before step 1. Right Shift/Option/⌘
fold to the left codes (classic KeyMap). Font 20 = Times (no FOND/NFNT in the game files). Icon = `icl8`/`ICN#` 128 ×16
nearest-neighbour (0 mismatched pixels vs the system palette + mask); previews go to Ben at A2.
**Ben, 2026-10-10 — duplicate-black tie-break in A1, hidden switch:** `ColorSearch` takes a tie-break (`lowest`
default, `highest`) governing the `.ruled` exact-match scan, `.exactNearest` equal distances and the inverse table's
cell ties; caches key on it. The app reads `UserDefaults` `ColorTieBreak` (`defaults write com.ambrosiaclassics.ferazel
ColorTieBreak highest`, or launch arg `-ColorTieBreak highest`). Clut 201 black → 1 (lowest) / 255 (highest). Default
goldens unchanged; NEW measurement: level-1 frame 1 under `highest` = `b80b0efd384ffdb9`.
Not built: the level-start music fade-in (`_FadeAIFFMusic(1,4)`, l. 5222) — music starts at full volume [LOW]; the
DEBUG data-missing alert names `tools/stage-ferazel.sh` (A2). Debug builds cannot hold 30 Hz; A2 stages Release.
`Ferazel/Core` **102/0**; census 1,108/0; G5 Ferazel, Aki, BubbleTroubleX, Deimos BUILD SUCCEEDED. Ben's first look
(2026-10-10): level 1 on screen, music heard.
**Measured against the Let's Play (2026-10-10; `docs/ferazel/colour-measurement-2026-10-10.md`):** 7 static level-1 LP frames
(bt709 TV range, 5-frame medians, scroll found by edge NCC), scored as 8×8-block CIE76 ΔE over 4 models × 2 tie-breaks × 2 dithers ×
Effects 1/2/3. Tie-break **highest** HIGH; the dither is **error-diffused** HIGH (on 32-bit sprites at full video resolution; FS-specific
LOW); the video runs **Effects 1/2** HIGH. The model only matters inside the lighting tables: `.exactNearest` beats `.ruled` in 7/7 frames
(fitted ΔE 1.21 vs 2.19), and `.inverseTable(5)` ties with exact. **Ben ruled the app default `.exactNearest`** (FerazelController; the
Core default and goldens are unchanged). The "darker" look is display gamma: the HUD art, which is model-invariant, is γ ≈ 0.76 brighter
in the video (classic Mac 1.8 vs 2.2). **Ben: a hidden gamma toggle, off by default** — built 2026-10-10: `UserDefaults`
`MacGamma` (`defaults write com.ambrosiaclassics.ferazel MacGamma -bool true`, or launch arg `-MacGamma YES`), read once at
launch; when on, `FerazelController.present()` maps each 8-bit channel of the 256-entry screen palette through a LUT
v' = round(255·(v/255)^(1.8/2.2)) (γ ≈ 0.818; the LP measured ≈ 0.76, range 0.71–0.90 — 1.8/2.2 kept unless Ben says
otherwise). Presentation only: FerazelCore, the goldens and the 102 tests are untouched; off is byte-identical to before. The 02:12 table glow is
light 24 (the potion item 0xc84, light PICT 810, not gated by Effects). On the wall tiles it matches the video, but our sprite light pass
over-lights the table by about L* 17. Open [MED]: re-read `.WrapLightFace` for that case.
**As built (A2, 2026-10-10; Opus implementer, one Opus leg MERGEABLE + two fix rounds):** `tools/stage-ferazel.sh` (stage-btx shape:
xcodegen → Release into `.build/xcode-ferazel` → `out/Ferazel/Ferazel's Wand.app`, `Resources/Ferazel/` or `FERAZEL_DATA` into
`Contents/Resources/Ferazel/`, `xattr -cr`, ad-hoc sign + `--strict` verify, build stamp written into the staged WHAT-TO-EXPECT only,
Icon Composer `ictool` previews (Xcode's `xcrun ictool` is actool's and cannot export) into `out/Ferazel/icon-previews/`, all to
`~/Desktop/` unless `FERAZEL_STAGE_NO_DESKTOP=1`) and `Ferazel/WHAT-TO-EXPECT.md`. The gate card corrects the plan: line 7 magic bar
x 419 + Times bold [MED]; line 8 the camera opens at (0, 0) and pans in (v 10 on step 24); frame 1 has no player face; lines 14–16
added (black border = PICT 129 frame, confirmed by the Let's Play; tie-break; gamma + light-24 table glow as known deviations).
**Ben, 2026-10-10 — the app's duplicate-black tie-break default is `highest`** (Let's Play 02:12: FG rock edges clean light grey,
no yellow specks; confirmed by the measurement above). `FerazelController` reads `ColorTieBreak lowest` as lowest, anything else as
highest; `ColorSearch`'s API default stays `.lowest`, so Core goldens are unchanged. Seat-ruled scope: that one controller edit is
outside A2's Files list. G1 HK main 328 == floor 328; G2 **102/0**; G3 1,108/0; G4 6 + 28; G5 ×4 BUILD SUCCEEDED; G9 both copies
pid + clean quit, no crash report. Ben's Phase 1 gate pending.

**As built (light-24 table glow, 2026-10-10; Opus seat, one Opus review leg):** the [MED] open item above is closed, and the
cause was not `.WrapLightFace`. `.DrawLightOverFace`, its blitters and the `+0x88` gate were already transcribed right (the table 0xb6f
keeps `.InitSprite`'s `+0x88 = 1`). The binary does light the table, but with a twinkling face. Every frame `.HandleBonusSprite`
(LAB_1005f808, decompile l. 53295–53416, raw `1005f808..1005f914`) takes each active Bonus sprite of type ≥ 2000 with prefs+6 ≠ 3
through `+0x46 += 1`, k = (`+0x46` >> 2) mod 6, and calls `.ChangeLightFace(+0x9a, PTR_DAT_100a088c[0,1,2,3,2,1][k])`. Those four faces
are 0x32a–0x32d, 72×72 (`.InitEffectSprite` l. 53662–53668), and 0x32b–0x32d are much dimmer (sums of k: 19,936 / 13,039 / 7,992 / 3,812).
The replica held the Setup's 0x32a forever. Built: `SpriteSlot` `+0x9a` light (each Bonus `.AddLight` stores its slot) and `+0x46`
phase (the Setup's `FastRand(0x10)` is not modelled, so 0 [MED]). `BonusHandle.twinkle` runs for the items 0xc80…0xcb0, in
`FerazelSession.step` after `.HandleIdleSprites` (the `.HandleSprites` position, between the copy and the erase). The seam gains the
case `DrawOp.changeLightFace(slot:pict:width:height:)` (a case added, nothing renamed), which `FrameRenderer` executes as
`.ChangeLightFace @ 1001bdbc`. Re-scored with `fzcolour … --twinkle k` (exactNearest/highest/FS/E1, HUD-γ): the table pixels light 24
touches went from ΔE 21.6 (dL −17.7) with 0x32a held to 13.4 / **6.9** / 9.6 at 0x32b / 0x32c / 0x32d. The LP frame sits on the 0x32c
phase, level with the plain table's 6.6. The light-24 wall pixels went from 5.0 to 2.8–5.4, and the other six LP frames are
byte-identical. **Goldens re-measured** (NEW measurement; frame 1 `9db8f32f7e3d88b4` and A1's `highest` frame 1 unchanged): right held,
frame 30 = `686024aba05c6660`, frame 60 = `18c4e45ebeee8e88`, hash of all 60 = `51d5f367bd111589` (were `f6296c7e706130f3` /
`e7a951e3eafca30a` / `3c5aee2b87819db6`). `Ferazel/Core` **104/0**. Not built, carried: the torch flicker (`ChangeLightFace` 0x321 ↔
0x322 and particles, l. 53260–53285), and the sphere and 0x53c/0x53d light cycles (they also set mode 0xb, which is refused). With `+0x46` = 0 every item light twinkles in step (the original's start phases are random) [MED]. Review leg: MERGEABLE, 0 Critical / 0 Important / 7 Minor; the comment cite and the stale `LightSlot` doc were fixed, and the rest are carried or noted.

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

## D28 — Cythera build: Ben's brainstorm rulings + the seat's design rulings (2026-10-06)

**Decided (Ben, brainstorm of 2026-10-06, orchestrator Claude Opus 5.5; design `docs/plans/2026-10-06-cythera-design.md`
APPROVED "merge, and chip."):**
1. **Done = the whole game, Mac + Windows** — every level, both endings, start screen, saves, prefs, the party-AI
   strategy editor + debugger; Mac on HectorShell, Windows on the SDL shell BTX proved.
2. **First gate = walking Catamarca** — full desktop, Map window drawing a new game's Catamarca exactly, Alaric walks,
   roofs lift; no talk, no scripts; side by side with the 1999 Catamarca screenshot.
3. **Screen = like the original** — backdrop fills the display, the game's own windows float on it, drawn by the
   replica, one original pixel per point; windowed mode treats the window as the monitor. Rejected: a fixed 1999
   monitor at whole-number scale; real macOS windows.
4. **Feel oracle = longplays + Ben's memory + his eyes**; the five 1999 screenshots for the look. Rejected: emulator.
5. **Gate order = world → talk → start/saves → items/shops → fights/magic → whole story → Windows + docs viewer +
   release.** Rejected: front end first; fights early.
6. **Extras IN: cheat/debug keys, the Cythera Documentation viewer.** Out: registration screens, InputSprocket.
7. **Saves = the original format both ways.**
8. **Music = Apple's General-MIDI synth live on the Mac; each tune recorded once from it for Windows.** Rejected: a
   bundled SoundFont; deciding later.
9. **Process:** the Phase 0 plan is written by a Fable planner directly from the design, no separate review (Ben:
   "seems token silly" to have Opus write and Fable review). Done: `docs/plans/2026-10-06-cythera-phase0.md`, 14 tasks.
**Seat's rulings under the 100 % rule (design §5–§10):** three layers (CytheraCore Foundation-only incl. the VM and the
window-system model; CytheraRender composites the whole desktop to one 8-bit screen; thin shells); the original's
three cooperative threads as real threads taking strict turns (rejected: re-entrant VM state machines, Swift async);
HectorShell gains a resizable 1:1 canvas (Phase 1); data in git by the D24 shape; deviations list §8 (no monitor
picker/depth dialog, host file dialogs, real Mac menu bar, one display, baked Apple glyphs per D16.4/D20).
**Approved by:** Ben (1–9, in his words, 2026-10-06); seat rulings recorded, Ben shown the design.
**As built — C0, data in git (2026-10-07):** `Resources/Cythera/` holds the installed Cythera 1.0.4 folder's game data
byte-identical (`cp -p`, `cmp` clean) from the archive mirror's `RPG/Cythera/Cythera (installed)/files`, 20 files,
**11,570,723 B**, largest 5,608,688 B (under GitHub's 50 MB warning); SHA-256 re-measured with `shasum -a 256`, equal to
the planner's p01 list (plan Research note 1; its abbreviated suffixes for `Attack Weakest.ai` and `Dummy.ai` are typos):
- `Cythera Data` 5,608,688 B `8f45758d8f3024f3ee0bd7bd16717803fae43874b56bf27472e2cef2ccbefa59`
- `Cythera Data.rsrc` 1,247,331 B `824d8a1d532419b7d2cddf97e93fba753645435e57bbaeabff01f7593cee35e7`
- `Cythera.rsrc` 1,008,484 B `333416124a74a18bd07ee19c1fb8a602c014046220a3324491e0449875f170f1`
- `Cythera Documentation.rsrc` 2,420,779 B `00fe7c752206f3d7d78e0aa21362d1841b90d487d46677f178ea5348a9382726`
- `AI Scripting Document` 10,331 B `66456bf781731508bf40acdb5fe81c01f254e353745d76e2ba45d81446d6103d`
- `Attack Nearest.ai` 428 B `46331b2b5f6dcf8a9ed3b2c6eb3ff22b1bfb8f2b6ea9242ce337ae7581474976`
- `Attack Strongest.ai` 437 B `6a01b1914196b3d041add32be516ee078df80e11f3b4d5b9ee34cb611b04178a`
- `Attack Weakest.ai` 432 B `4123411c92096832de032381ec4186a360d7fe3f6178c358538d8fb8fe634be5`
- `Beserk.ai` 317 B `95472845dfcf75e58639df2a1617bd3af2bfbaafc8c998bd5d331c488e827a14`
- `Defend.ai` 712 B `532cbbe7c2dcf8b05d70d0df4945e237284fd3b1c709176700edd2048a2537d5`
- `Dummy.ai` 310 B `b56a7a70e93057b5082dc1fc6e0d2a184ce376e502e730018fb0602a1fc7c3a7`
- `Healer.ai` 526 B `ccbb73a3363e47b2a4227c53e41a609f0c9f6561221386712baa2f75fc18a281`
- `Missile User.ai` 715 B `3111734a8b1082e930d523f4522be29836a2cf7088ca342646c4d6cd3ca7dc00`
- `Catamarca screenshot.pict` 397,738 B `bcdafd33fabfb487382fec0ffb866d12784764815a7bed64cf56a37e37802f86`
- `Land King Hall screenshot.pict` 164,900 B `73f0d1306ffe03e6a166714f6b1abe12681bb6125eee879456f649e25369149b`
- `Odemia screenshot.pict` 250,384 B `092bd628eb19cfd04e8f57c6aa8157b2bac99d72a4f44e6c31bf9e6f4be9db6b`
- `Pnyx screenshot.pict` 210,220 B `30b01e83d99229b127737cfd982900d14540e93c0166e08dd380080342330234`
- `Unicorn screenshot.pict` 240,490 B `f44862d61f897223b23de79a959e2cd237d75a19e7a3e030cdc01d7885a739cf`
- `Cythera 1.0.4 Notes.text` 5,056 B `57c7ad31d96c7b41dc3fb3c8c86beb8a53c77f962768918d3c922fb6cc685910`
- `Cythera License.text` 2,445 B `2d129e3c8de301348ae2885178218fba8d938b592b305c7a7852d96f472fa250`

`.gitignore` adds `!/Resources/Cythera/` after `!/Resources/Ferazel/` (other games' data stays ignored);
`.gitattributes` adds `Resources/Cythera/** binary`. Tests read the committed folder and never skip; `CYTHERA_DATA`
overrides its location (D24.3 shape). Kit decisions (plan Architecture paragraph):
- `clut` → CytheraCore `ColorTableRecord` (the kit's `ColorTable` is PICT-internal; promote when a third game parses `clut`).
- `NFNT`/`FOND`/`sfnt` → CytheraRender `BitmapFont` / CytheraCore `FontFamily` / sfnt table directory only (one game ships them).
- `Lite`, `FILT`, `nrct`, `Pref`, `TxSt` → CytheraCore records (Delver-engine private layouts).
- `DLOG`/`DITL`/`WIND`/`CNTL`/`ALRT`/`MENU`/`MBAR` → CytheraCore records; `HectorGraphics.Ditl` is a test-only oracle.
- `snd ` → HectorAudio `SndSound` (exists); the `'asnd'` form and the snd→asnd rule → CytheraRender `SoundSegment`.
- Segment file, XOR, LZ, maps/props/globals/CharEntry, the script decoder → CytheraCore; tiles/portraits/sky/pix/macro
  icons/compo tiles/PICT-as-indices/QTMA → CytheraRender.

**Rejected (C0):** Git LFS (breaks anonymous clones of the public repo past the free quota) · data out of git behind
symlinks (D24 reasons) · committing the PEF `Cythera`, the InputSprocket files or the `*.ai.rsrc` editor-state forks.

**As built — Phase 0 tranche 1 (2026-10-07, K1 + C0–C2):** K1 on HectorKit main `4ca2e18`, HectorKit **D14**
(floor 316 → **322**; the plan's 313 → 319 and "D13" were stale). **Plan correction (seat, re-measured):** the direct-colour
PICTs do not all carry mode 64 — PICT 129 (16-bit paper doll) = 36 `transparent`, 133–138 and the Catamarca screenshot =
0 `srcCopy`; `decodePixels` returns the mode as stored and accepts exactly {0, 36, 64}. What `transparent` did to the paper
doll is a Phase 1 gate-card item. Research note 1's abbreviated hash tails for `Attack Weakest.ai` / `Dummy.ai` are typos
(full hashes + `cmp` agree). Script-band AI segments 0x0410–0x0436 are stored unencrypted (`PerformAI` →
`GetSegment(0x360+n)`): read them with `segment(_:)`, never `scriptSegment(_:)` — C8/C9 route them.

**As built — Phase 0 tranche 2 (2026-10-07, C3 + C4 + C5; all-Opus implementers + reviewers, two legs per ⚑):**
`Cythera/Core` suite **44/0/0** (ladder 14 → 20 → 34 → 44 exact). C3 LZ (all 378 shipped streams byte-identical to
`lz.py` per reviewer differential; op census as planned) + additive `LZ.decode(_:limit:)` / `.outputLimit` (decompression
bound; locked signature unchanged). C4 World records (42 maps, 14,485 props, 20 globals typed). C5 CytheraRender (tile
store SHA, portraits/sky/pix/macro, Palette with `origin`, compo tiles via `CompoTileRecord`, Lite/FILT, PICTs as stored).
HectorKit untouched (main 4ca2e18, floor 322). **Seat rulings (re-measured, Invariant 10 STOP by the C4 implementer):**
(1) map 0x8002 chunk 0 begins `0000 0000 01F6 01E4`; (2) 0xF001 = 8 records + zero i16, no tail bytes (Bank correction 3
wrong); (3) max tile 0x429 all cells / 0x32C non-compo — both asserted; (4) map side capped by the segment header's
maxMapDimension (+0x48, 0x200), 0x400 only when it is 0, as `CreateGlobals__Fs @ 10004d0c`; (5) F001 refusals (frames or
divisor ≤ 0, base/tile ≥ 0xA00) are Invariant-4 census refusals the original does not make — documented in code; (6)
S3 `StoredPicture` adopted as a struct around the locked cases; (7) Land King Hall: the kit throws `unsupportedOpcode(0x32)`
(a rect op precedes 0x8200), so CytheraRender names the refusal "0x8200 QuickTime" with a bounded opcode walk — kit
carry: a kit error naming the first unsupported *bits* opcode would remove it; (8) FILT has no frame count, so a prefix
ending on a frame boundary is a valid shorter filter (as the loader reads to the handle's end). Measured: Catamarca and
the other screenshots mode 0, PICT 129 = 36, 133–138 = 0 (agrees with tranche 1); app `clut 256` 250 non-replicated.

## D29 — Deimos Rising build: design + Phase 1 rulings (seat) (2026-10-06)

**Decided (seat, under D27 and the 100 % rule; design `docs/plans/2026-10-06-deimos-design.md`, plan
`docs/plans/2026-10-06-deimos-phase1.md`, Fable review ACCEPT_WITH_FIXES, fixes applied):**
1. **Layers (design §3):** `DeimosCore` (Foundation + HectorResources + HectorAudio: rules, seams, session) →
   `DeimosRender` (Foundation + Core: RGB555 buffers, blitters, presents, fades) → `DeimosHost` (Foundation + Core +
   Render: the shell-neutral driver — Mac-tick clock, limiter, fade/blocking waits, key table) → thin shells
   (`Deimos/App` AppKit + HectorShell; `Deimos/Windows` HectorSDL later). Rejected: the Aki two-layer shape, pixels in
   Core, a per-shell controller (the BTX Windows re-port cost, D15). Seam types (`HeldKeys` … `DeimosPrefs`) are LOCKED
   once Phase 1 lands: cases may be added, never renamed.
2. **Render model (design §5):** 16-bit RGB555 persistent buffers; Core records the original's draw calls in order as
   `RenderOp`s, Render executes them (artefacts included). To the display by bit replication `(c << 3) | (c >> 2)` (the
   kit's PICT rule); **whole-frame presents** — the original's tearing is not reproduced.
3. **Disclosed deviations (design §7):** whole-frame presents, no OS volume writes, no InputSprocket (keys from the
   prefs key table — the input source), registered build, prefs file in Application Support with the 0x34f0 layout
   (never `UserDefaults`), `Last Film` in the user's Local override folder, DEBUG-only data-missing alert.
4. **Phases (design §8)** 1 look → 2 level 1 plays → 3 campaign → 4 front end → 5 Windows + release: a proposal,
   pending Ben's Q7.
5. **TickCount rate (Q1):** default **60.15 Hz** (classic Mac OS; Deimos 1.0.6 is an InterfaceLib app), pending Ben;
   the build proceeds on the default (`TickRate.classic`; `.osx` 60.0 kept).
6. **Phase-1 stubs (plan S2 ◇, on the gate card):** `Player.updatePhase1` (life states 2 → 4, appear/glow, size refresh,
   crosshair, banking, view shift — no velocity, firing, power-ups); no entities (`plen`, multiplier unit, `no01`).
7. **Kit:** `ShellView.scalingPolicy` (`.integerFit` for D27.3) landed as HectorKit D13 (522feb8, floor 316).
**Approved by:** seat (orchestrator); Ben told.

**As built — Phase 1 (2026-10-07; seat rulings from the per-wave Fable reviews):**
- **`KeyTable` lives in DeimosCore**, not DeimosHost: the LOCKED `pass(keys: HeldKeys)` maps inside Core (C6 review).
- **`Player.updatePhase1(…, scoreBar: inout)`** keeps `FUN_10031710` at its original call site (`1002a1dc`); input bytes
  are untouched outside state 4 (`1002a3c4`) — the plan text was corrected to the listing (C4 review).
- **`COST` rects** are only rejected by the command clip; `FUN_1001ec80` clips to the port and addresses from the
  unclamped top/left (R2 review; plan corrected). The same unclipped-addressing quirk is reproduced in the blend
  kernel `FUN_1001e9d0`, and the interlaced copy clips the last field row (`100450e0`) — bank ⚑ note added.
- **`TextFormat` defaults = the runtime template** (spacing 1, strip 3/3/16, colourise 0x7fff); no shipped `tefo` changes.
- **Driver (◇ Phase-1 stand-in):** Esc restarts level 1 with seed = ticks; the Esc that ended a session is latched
  until released, and each `idle` call does bounded work (one restart, one present, one limiter release) — the H1 review
  found a hang on a held Esc and at tick wrap, both fixed with regression tests. `.hideCursor` is emitted on a session's
  first pass (the original hid it in the front end, `10023550`, before the game call).
- **App:** `Deimos/DeimosCore → Core` symlink (SwiftPM identity clash with `Aki/Core`; BTX D13.8 shape). Window
  `[.titled, .miniaturizable]` (the original's windowed variant: title bar, no close box, collapsible — `FUN_1000a640`).
  **Suspends while in the background or miniaturised** (display-window-present §7); on resume it shows the held screen
  rather than the original's black window until the next present (disclosed).

## D30 — Deimos Rising gate 1 PASSED; TickCount 60 Hz (2026-10-07)

**Decided (Ben, in chat, after playing the staged Phase 1 build):** "it looks okay!" — **gate 1 ("level 1 look", D27.2)
passed.** Q1 (design §11.1, INDEX #42): "i'm playing on osx. let's try 60" → the replica runs at **Mac OS X's 60 Hz
TickCount** (`TickRate.osx`: the limiter's 2 ticks = 30.00 fps), not the classic 60.15 Hz default D29.5 proceeded on.
`TickRate.classic` stays in DeimosHost. The MED gate-card items (24→16 colour cut, TGA orientation, `tesm` digit
widths) raised no objection — they stay MED in the bank, unchallenged by Ben's eyes.
**Approved by:** Ben.

## D32 — Ferazel's Wand Phase 1 gate PASSED (2026-10-10)

**Decided (Ben, in chat, after looking at the staged Phase 1 build `~/Desktop/Ferazel's Wand.app`, build 51ed68b = main
ee5af2a):** "it looks good" — **the Phase 1 gate ("does it look like Ferazel", D26 / design §8) passed.** He asked "no
animations yet?" first and was told that by design only Ferazel's breathe/walk-in-place stub and the camera move; every
placed sprite stays in its Setup face until the sprite Handles run (Phases 2, 4, 5). He did not ask for scenery animation
in Phase 1. The gate card's LOW/MED items raised no objection and stay labelled as they are in the bank. Defaults as staged:
colour model `.exactNearest`, tie-break `highest` (D26 as-built A2 + LP measurement). **Icon: Ben picked the Default render** ("default icon is fine") — `Ferazel/App/AppIcon.icon` stays as A1
built it. **Still open:** the hidden Mac-gamma toggle (off by default, unbuilt); the light-24 table over-light
[MED]; the level-start music fade-in [LOW]. (D31 is taken on the unmerged `deimos-phase2` branch, so this is D32.)
**Approved by:** Ben.

## D33 — Ferazel's Wand Phase 2 "Ferazel moves": planning rulings (2026-10-10)

**Decided (Ben, in chat, during planning):** (1) **Reaching level 2 before the world map exists:** touching level 1's
exit loads the level it unlocks straight away, **and** a hidden launch switch `FerazelLevel` (`-FerazelLevel 2` or
`defaults write com.ambrosiaclassics.ferazel FerazelLevel 2`) starts on that level — both ◇ stubs, replaced by Phase 3's
stage-complete screen + world map (Ben asked whether the map is being built: yes, Phase 3, the D26 order). (2) **Death:**
the dying animation and the original border wipe (`.DeathEffect`), then **restart the current level from its start
with fresh globals** — ◇ stub for Phase 3's menu/Continue; no invented checkpoints.
**Seat's rulings (plan `docs/plans/2026-10-10-ferazel-phase2.md`, under the 100 % rule):** everything that moves or hurts
the player on levels 1–2 is Phase 2 (platforms of every mode, 1480–1489 radial bars/balls, cannons, trampolines,
passages, wall tunnels, Box solids, damaging floors, liquids, drowning); ropes and springs are built with synthetic tests
(none placed on levels 1–2). Enemies and Bonus sprites stay `inert` (Setup face, no Handle, no contact damage) until
Phases 4–5; crate/boulder **pushing** stays in Phase 4 with the boxes (design §8) — they are solids now. Phase 2 loads
levels 1 and 2 only: level 2's exits (to 3 and 4) restart level 2, `FerazelLevel` outside 1…2 → 1. Keys are the
original defaults only (keypad 4/6/8/5, Shift, Option, ⌘, keypad 7/9); Phase 1's arrow-key stub goes with
`CameraFocusDriver`. Sound effects through a Foundation-only Sound Tool mixer as read (16-entry list, **8 audible
voices**, ±127 clip, 8-bit 22,050 Hz; `ST_Open(8, 1, 22050)`), attached with `ShellMixer.attachStream` — HectorKit
untouched. `FastRand` seeded from the clock in the app (as `.InitAppGlobals`), fixed in tests. Follow-the-binary bank
corrections found by the planning legs (no JUMP gate by teleporter charge; no mid-air spin refill; un-clamped shuttles;
the pendulum's harmful band; the layer-change guard and double-handled frame; 8 voices) are listed in the plan and
appended to the bank by the task that first relies on each.
**Rejected:** pulling the world map into Phase 2 (Ben: map stays Phase 3); arrow keys kept alongside the keypad;
float mixing instead of the Sound Tool's 8-bit path.
**Approved by:** Ben (rulings 1–2, 2026-10-10); **the plan itself approved by Ben 2026-10-10** (start of the first
execution session: "Sure").

**As built (wave 2.0: F1, F2, F3 — 2026-10-10; Opus 5.5 orchestrator, Opus implementers, Opus legs: F1 one, F2/F3 two
each + fix rounds + one re-review leg MERGEABLE):** `Ferazel/Core` **104 → 140/0** (ladder base was 104, not the
plan's 102: the light-24 twinkle landed after planning). **F1** `FastRand` (Park–Miller, lo 0x8000 → 0, `next(0)`
reseeds via an injected clock, `soundRate()`); the level-1 Setups draw **256** times under any seed (Bonus + Walker
only), first coin `+0x46` = 3, the item's twinkle phase = 6 under seed 1. Orchestrator ruling (follow the binary): the
twinkle phase is drawn, so expectations pinned to the Phase-1 phase-0 stub were updated (pan goldens
`686024aba05c6660 → e493fc8b09f84ed5`, `18c4e45ebeee8e88 → 3ec51d436e278776`, `51d5f367bd111589 → 6e034d02ef78d7fb`;
first-frame goldens unchanged; cause proven by forcing the phase to 0). Torch draw is `1005e110` R(10), `1005df24` is
the money bag (plan + D32 carry corrected). After the Setups, level start draws **510** more for tint table 0xa plus
the diffuse blits (twice) — carried to **E2** (before any per-frame RNG number is measured). **F2** `SpriteWorld`
(handle pass with next preloaded, a killed saved next still handled; layer-change guard; SSH/Cleanup; PlatformBounce
+ RectBounce; carry from the drawn copy `drawnX/drawnY` +0xc6/+0xc4, recorded for every sprite; `.MTNewSprite`'s
pixel-copy quirk as written; the Bonus Handle runs SSH then the twinkle at its list position; O(1) id→index lookups,
list order unchanged — fuzzed against a pointer model). Review caught a Swift precedence bug in the side push
(`>>` binds tighter than `&*`): fixed + tested. **F3** `TileSolver` (SeparateFromTiles2, full WallBounce/WallBounceBG,
ApplySpeedAndSeparate, slope f32 factors); follow the binary: kind 3 sets a rising sprite's bottom to Y+16 without
landing; ice slide once per **separation call**; climb is read **after** the separation (raw 1004b9b0..bc); one tile
map owned by `SpriteWorld`. Bank corrections A3, A5, A6, A10, A12 (now HIGH), A13, B3, C6 + a WallBounceBG §10.1
correction landed. Carries: plan W1 precondition (ActiveToIdle unlink, review M2/M3/M6/M7). HectorKit untouched.

**As built (wave 2.1: S2, E2 — 2026-10-11; Opus 5.5 orchestrator, Opus implementers in parallel (S2 in a scratch
clone, cherry-picked), two Opus legs each, one fix round each, one Opus re-review leg over both fix rounds):**
`Ferazel/Core` **140 → 154/0** (E2 carry +1, E2 +8, S2 +5); census 1,108/0; Ferazel builds; **no golden moved**;
HectorKit untouched. **S2** `SoundTool` (FerazelRender, `PCMPullSource`, `Synchronization.Mutex`): 16-entry list, 8
mixed, insert rule (unsigned priority compare, L/R clamp 0x80), `(s8·vol) >> 7` per side, ±127 clip, 22,050 Hz,
1024-frame blocks. Follow the binary (bank correction C1 in sprites-backgrounds-sounds §6.2): every sound loses its
first sample (raw `100917c8`); request L/R are +0x16/+0x18 (bank had +0x18/+0x1a); entries past 8 advance silently;
play/stop land on block boundaries. FixMul/FixDiv round-to-nearest [MED] (today's Carbon FixMul is `(p+0xC000)>>16` —
not the OS 8/9 library; only the one 22,254 Hz sound can differ). Not built (carried to S1/A3): stop/count by id with
0 = all, completion procs / looped sounds, mono. **E2** draw modes 3/4 (hurt flash), 6 + water split/ripple, 9, 0xc
scale, rotation, occluder (applied in Core cleanup as the binary — no draw-time read), `DeathEffect` +
`FrameRenderer.deathEffectStep(k)`, `ScreenGamma` + `presentedClut`; `DrawOp.gammaStep` gained a defaulted `toward:`
(the dump's fade target — plan S3 amended); seam fields `waterKind` (+0x128), +0x18c/+0x18d (erase split from the
previous draw). **Level-start draws (F1 carry):** the two `.RedrawEntireScrollGrid` passes draw **0** (diffuse only in
mode 5; the grid never passes it — the F1 note over-counted from the call graph), `.AnimateCLUT` 0 on L1/L2,
`.BuildTintTable` 510 (B before R) → seed 1 = 0x2c1b1519 after level start; tint table 0xa now comes from the session
stream (`apply` refuses until it is built). Carries: the underwater light variant (draw-effects §3) is refused by
name → P4; the per-frame 0x4c4 direct handler call may draw FastRand → P1a reads it first. Re-review minors (low,
carried): `deathEffectStep` paints before the `tintTableNotBuilt` throw; `DeathEffect.frame` traps where the renderer
throws on a bad step; new `Refusal.ripplePhase` (a negative signed back-scratch index on a drawn row — the original
reads memory before the table; ~2²³ frames on one level; A3 rebuilds the renderer per level so it resets) has no unit
test (census covers the skipped-row exemption); the frames-clamp test does not prove no write past the end.

**As built (wave 2.2, first half: P1a, P1b, P2, P3 — 2026-10-13; Opus 5.5 orchestrator, Opus implementers, two Opus
legs per task (P3 given two though minor: it carried the session wiring), one fix round each, one Opus re-review leg
over the P1a/P1b/P2 fix rounds MERGEABLE; the P3 fix round (6fd7484) was not re-reviewed — the next session's first
reviewer reads it):** `Ferazel/Core` **154 → 185/0** (P1a +6 → 160, P1b +6 → 166, P2 +9 → 175, P3 +10 → 185; review
fixes added asserts only); census 1,108/0; Ferazel builds. **P1a** `PlayerState`/`Player.handle(world:keys:)` (42 rows
in the binary's order; the plan's digest-A row numbers map 13/22/35/36 → code 19/27/40/40, table in the plan) +
`.HandleKeys` vertical; the per-frame 0x4c4 direct call is the countdown-digits Effect sprite and draws no FastRand;
exertion +1/+3 lives in the L/R block (moved to P1b). **P1b** the L/R block; its gate is five terms (glider, carpet,
climb, crouch, |charge 0700| ≤ 0x14 — the plan omitted charge); `.FootPressure @100431ec` built (both ground paths).
**P2** `.HitPlayerTileSprite` + `.CheckGroundCeilingHitEffects` + `.CrunchTile` (reshape table hand-traced, 48 arms),
dust Effect Handle, `DrawOp.setTile`; follow the binary: the (16,16) add before `.RectBounceFake2` is disasm-only (raw
`100552cc..f0`), the crumble overlay is layer 0xb (not 50), 603 priority 1; frame outputs drain once per frame
(`PlayerState.drainFrameOutputs`), crunch log on `GameGlobals`. **P3** state selection + faces, breathing, footsteps,
invulnerability blink on the drawn-iteration parity; `PlayerPose` deleted; the player, held item, five trails and
the 0x4c4 countdown are wired into the session; setTile ops follow the Handle that wrote the map (`.ChangedTile
@10012a50` redraws at once). **Orchestrator ruling (Invariant-10 STOP, follow the binary):** real rows 30/33 changed
numbers P1a–P2 had measured against stubs — only exertion (breathing −2/frame, raw `1004bb8c..90`) and cue lists (the
grounded per-frame stop 427, raw `1005074c/60`) were re-measured; no kinematic number moved. Level 1 spawns at
(83,143) 20 px inside the floor and frame 1 lifts him to y 123 (original behaviour, kind-4 floor arm); walking right
from the start drops him into the column-5 pit and he clings to its wall (6,6) — SessionTests' face sequences
re-measured on L1; the flat-floor sequences are pinned by PlayerStateTests. ◈ pan golden frame 30
`e493fc8b09f84ed5 → be2b8e2e6631b1a7`, chain `6e034d02ef78d7fb → 967803e69d2ceaf6`, frame 60 unchanged (camera still the
◇ stub until P5). Bank corrections A1, A2, A4, A7, A8, A9, A11, A14, C7 + triggers-background-2 §2.3 notes landed.
**Carries:** `.ExplodeFaceIntoParticles` (4 FastRand per emitted pixel at each crunch destroy) and `.ParticleGlow`
(invulnerability > 60) → **E1a** — until then the session stream diverges from the original after the first crunch
destroy or a long invulnerability; parity and crunch log across level loads → W4; app arrow keys still pan the ◇
focus driver (they no longer move Ferazel) → P5; `FrameRenderer.setTile` re-parses the level per op (0.145 ms
release) → A3 if it hitches; held-item faces 0x2ee..0x308 unloaded.

**As built (wave 2.2, second half: P4, P5 — 2026-10-13, loop run 2; Opus 5.5 orchestrator, Opus implementers, one Opus
leg each + fix round; P5's behaviour-changing fix round re-reviewed MERGEABLE):** `Ferazel/Core` **185 → 203/0** (P4 +10
→ 195, P5 +8 → 203); census 1,108/0; Ferazel builds. **P4** liquids (`.HandleUnderWater`, `.HandleFlotation`), acid /
healing / drowning / breath, damaging surfaces, below-map death, the death trigger, bubble 0x410, and the E2 carry:
the underwater light variant in `SpriteBlitter`. **P5** `.PlayerScroll` (freeze / follow / ease, look-ahead L) replaces
the ◇ focus driver; Camera snap vetoes read the live player `*_DAT_1009fdd8`, as does `.HandleIdleSprites`' window.
**Orchestrator ruling (Invariant-10 STOP, follow the binary):** the real camera changes which sprites the level-1
crunch fixture activates, so `testCrunchKind3Collapses`' session section was re-measured (setTiles iteration 18 → 17,
potion idle); ◈ pan goldens re-derived (frame 30 → 172596fa2f3b6c58, frame 60 → cc9786ba763d383a, chain →
b4230ba5a643c5b5). The P3 fix round (6fd7484) was reviewed and confirmed. **Carries:** material-2 stop as a
`PlayerCue .stopIfPlaying` → S1 reconciles with `soundStops`; `playerDead` set after the loop exits → W4; idle rect via
`sprite(id:)` (linked only) → W1 with the `.ActiveToIdleSprite` carry. Loop note: run 1 ended its turn while a
background implementer ran (the headless session exits at end of turn, killing the agent) and merged nothing; its
dirty worktree `loop-1-20261013-180951` was kept by the looper. Runs dispatch subagents in the foreground.

**As built (wave 2.3, first part: W1, W2a — 2026-10-13, loop run 3; Opus 5.5 orchestrator, Opus implementers, two Opus
legs each (⚑ MAJOR) + asserts-only fix rounds):** `Ferazel/Core` **203 → 215/0** (W1 +8 → 211, W2a +4 → 215); census
1,108/0; Ferazel builds. **W1** the Platform class in every mode as read, radial tables/`.UpdateRadialPos`, wheel
siblings, chain spokes, the Platform arm of `.HitPlayerSprite`; the `.ActiveToIdleSprite` carry settled (record stays
listed, `.UpdateSprites` kills at step end), M2/M3 and P5's idle rect settled; M6/M7 open. **Rulings (follow the
binary):** ◈ goldens did not move (no platform in the start/pan views) — "frame 1 draws no platform" moved two draw
counts instead (10 → 3, 22 → 15); the level-1 wheel (rec 21) bounces on frame 1 because the stored radial centre is 0
until its first Handle (real per both legs; turns ≈ 28° off-screen); mode 0xb is not reachable through the L2 raft
light path (rafts → mode 0xc), so E2's 0xb/table 0148 stays unbuilt. **W2a** 1480–1489 radial bars/balls (harmful band
0x60 ≤ D < 0x80, double-handled frame, per-frame re-face), mace chains made at Setup (four level-start counts moved,
traced), `.HurtPlayer` with the attacker gate as the dump has it (EnemyShot/Box exempt — the plan said
Platform/Background) and coins `FastRand(3)+4` capped (the plan's "5" is the argument); seams `HurtPlayer.bloodSpray`
(E1a) and `PlayerCue.Call.regPitched` (S1). Carry: the RNG stream drifts from the first pendulum hit until E1a and the
Phase-4 coin spawn land.

**As built (wave 2.3, second part: W2b, W3, W4 — wave 2.3 CLOSED; 2026-10-13/14, loop run 4; Opus 5.5 orchestrator,
Opus implementers; W2b two Opus legs (⚑ MAJOR), W3/W4 one leg each; every fix round that changed behaviour got a short
Opus re-review):** `Ferazel/Core` **215 → 234/0** (W2b +5 → 220, W3 +8 → 228, W4 +6 → 234); census 1,108/0; Ferazel
builds; HectorKit untouched (0c65dcb, floor 328); no golden moved. **W2b** cannons 1090–1098 (hold 15, aim-mod-4 fire,
launch 9000, 415 smoke draws per launch), wall tunnels 3000–3009, springs 1150–1153, passages 2900/2901 with the
`DrawOp.gammaStep` fade, freeze, partner jump, camera snap + 90 passes. **W3** Box solids standing still (Phase 4 owns
the push/fall tail — crates rest 2–6 px off the binary's settle, gate-card item), trampoline 1470, bridges, ropes
3020–3022 and the rope state; NPCs are never solid (the arm returns before `.PlatformBounce`). **W4** every level-2
Setup (stalactite children made at Setup: L2 starts 33 active / 196 idle; 212 records, 40 spokes + 4 siblings after
frame 1, as planned), `LevelFlow` (exit → `Mmap` link → `loadLevel`; targets outside 1…2 restart the current level ◇),
death → `deathEffect` → `deathEffectDone()` → `loadLevel(current)` with fresh G (◇ Ben), `LevelCarry` (parity always).
**Rulings (follow the binary):** cannon rotation from the raw aim (the fold only mirrors; first pins corrected);
passage-jump erase at the live scroll; **globals carry across a level exit** (`_InitGameGlobals` only from `_NewGame`,
M l. 5747/6707; the next-level loop writes only G `+0x16`) — the plan had every load reset G; the exit cue 421 is handed
out on the loop-ending frame. Carries: music fade + sound stops after the loop → A3/S1; G fields not yet modelled →
Phase 3/4; 0x420 tint is a Handle write → Phase 4.

**As built (wave 2.4, first part: E1a, E1b — 2026-10-14, loop run 5; Opus 5.5 orchestrator, Opus implementers, two Opus
legs each (⚑ MAJOR), each behaviour-changing fix round re-reviewed):** `Ferazel/Core` **234 → 243/0** (E1a +5 → 239, +1
`testParticleRendererRowsAndErase` → 240 (the plan's Files named `ParticleRenderTests.swift`), E1b +3 → 243); census
1,108/0; Ferazel builds; HectorKit untouched (0c65dcb, floor 328); no golden moved (golden frames show rows 0–13; L1's
liquid starts at row 17). **E1a** particle pool (2000 × 32 B, hint/count/hwm, count drift copied), `.NewParticle`,
`.HandleParticles`, `.DrawParticles` (colour-0 kill −2, drawn iterations only), `.EraseParticles`, `.Splash`,
`.BloodSpray @100425f8`, `.ExplodeFaceIntoParticles`, `.ParticleGlow`, the three S3 `DrawOp` cases, `ParticleRenderer`.
**E1b** `.FillCachedTileArray`, `.WrapDrawWaterEffects @10010fac` (bubbles, motes, wind dust, 36 `.LookupModedImpulse`
cases) and the Enhanced water faces (`WaterFaceBlitter`). **Rulings (follow the binary):** E1a fills every `// later:
E1a` emitter site L1/L2 reach, not only the plan's files (the RNG stream drifts otherwise); RNG-dependent test numbers
moved with revert-verified causes (pendulum rates, bubbleTimer); the particle counters and the water-tile cache/origin/
flag are globals no level start resets → `LevelCarry` carries them; `.WrapDrawWaterEffects` runs outside the drawn block,
so Enhanced faces appear on skipped iterations with parity set (plan said drawn only); `.HandleLights` precedes the water
op. Unreachable-on-shipped-data deviations (recorded, not copied): `.Splash`'s infinite loop at x ≥ ≈0x7fd0;
`FastRand(0)`'s return value r30 in wind dust of strength 0; wind dust's uninitialised shape (port 0, persists). Carries:
`ParticleLife` ≠ rows on CLUT 222 under highest (levels 52/55); face-walk emitters need the renderer's faces (Core tests
emit none); a test carrying a non-zero water-origin column through `.carry` (re-review minor).

**As built (wave 2.4 close + wave 2.5 first part: S1, GD, A3 — 2026-10-14, loop run 6; Opus 5.5 orchestrator, Opus implementers; S1/GD one Opus leg, A3 two; every behaviour-changing fix round re-reviewed):** `Ferazel/Core` **243 → 254/0** (S1 +7 → 250, GD +4 → 254; fix rounds asserts/test-content only); census 1,108/0; Ferazel builds; HectorKit untouched (0c65dcb, floor 328); no existing golden moved. **S1** `SoundCues` (Reg/Pitched/3D/3DPitched/Rand arithmetic, global volume 7 → 196), `CalcStereoVolume`, `PEDistance`, `SoundSlots` (144 handles = `.InitSounds`, 602 not loaded); every cue site calls `PlayerState.cue(_:)`, which stamps the scroll at the call; the session converts once per frame in call order. `.UpdateDynamicSounds` re-pans nothing (its table is never armed) → not built. Both `.stop` and `.stopIfPlaying` → `soundStops`. **Ruling (follow the binary):** the binary's mixer processes play/stop calls in order (a play then a stop still takes a voice first, M l. 78217–78310), which two lists lose → ADDED `FrameOps.soundStopAt: [Int]` (each stop's index in `sounds`; append via `FrameOps.stopSound`), the app interleaves. After-loop stops 452/511 (+452/453/511 on level complete with health ≥ 1, M l. 5298–5310) are Core's. Bank corrections 8–9 in `sprites-backgrounds-sounds.md`. **GD** (`Phase2GoldenTests`, first measurements, seed 1): L2 frame 1 `565e867a02736c18` + iteration 2 `df22325e851e782d` (iteration 1 is never copied to screen, so it lacks player and lights); jump-and-land **40** frames (the plan's 30 never land; lands iteration 33, y 123) `e4f4bf977dd98eaa`; swim `95ff5176412df650` — **walking right cannot reach water** on L1 (breakable walls seal the start rooms), so the test drives a 357-frame route (lower room, col-24 wall broken by a spin-jump fall, run right) into the plan's pool cols 56–81 row 19, entry splash 96 + snd 405, then 40 frames; 600-frame scripted play starts with that route: chain `9532d65a42d39666`, cues `a875a96c2801dbe9`, final scroll (1353, 309). Not covered: swimming (the first pool is wading depth; the deep pool cols 146–156 rows 23–26 was not reached). **A3** (app): keys unchanged (already `FerazelPrefs.keys` only); `SoundTool` on `ShellMixer.attachStream` once per launch; stops/plays interleaved by `soundStopAt`, `onlyIfIdle` against the mixer; end of level: `.FadeAIFFMusic(0,2)` (24 steps × 2 ticks), on death the wipe `deathEffectStep(0…49)` ≥ 1 tick each, then music shutdown and reload with `seed:` = old `rngSeed` (+ `LevelCarry` on an exit; death = fresh G); the ending waits out the last frame's own wait (M l. 5285–5294). **Ruling:** no stop-all on a level load — the plan said "stop sounds", the dump has none on that path (stop-all only at M l. 78109/78153; `_LoadLevelSounds` disposes only when hdr+0x26d0, 0 in all 24 levels), so the exit cue 421 plays out. Clock seed now local time like `LMGetTime` (FastRand, one Core line outside A3's Files). Stand-ins/carries: no `GammaFadeInAsync(0x28)` after the death restart (M l. 5227; restarted level shows at full brightness), `.StageCompleteEffect`/`GammaFadeOut(6)`/`.EndLevelSGUpdate` skipped on exit (gate card 16), no music fade-in (M13), music tracks never unloaded, no ⌘W item; cosmetic: FastRand doc cites M l. 334 (seed read is `LMGetTime` M l. 31295–31298), `beginEnding` placeholder phase, redundant `stopEffects` in `stopAll`, `soundStopAt` of the jump frame unasserted in `SoundCueTests` l. 69; some later-phase `3DSoundRand` sites draw only when the sound is idle (M l. 62997, 63199–63257, 61047–61057) — conflicts with Invariant 4 when those phases come.

**As built (wave 2.5 close — A4 + the Phase 2 phase-end review; 2026-10-14, loop run 7; Opus 5.5 orchestrator, Opus implementers, one Opus leg on A4, one FABLE-GRADE leg over `4edb92e..HEAD`, Opus re-review of the code fixes):** `Ferazel/Core` **254 → 256/0**; census 1,108/0; Ferazel builds; HectorKit untouched (0c65dcb, floor 328); no golden moved. **Phase 2 machine gates green; Ben's gate pending (QUESTIONS Q2).** A4: `Ferazel/WHAT-TO-EXPECT.md` rewritten as the Phase 2 gate card (MacGamma built, keys, routes in player terms, every as-built gap). Fable re-ran G2/G3/G5/G7 and confirmed against the dump: walk 4/8 + run overshoot, jump 100.6/43.6 px landing frame 24, spin no-refill, HurtPlayer gate/order/cues, cue arithmetic + CalcStereoVolume, breath 560 (18.7 s), drown −112 / 70 frames, acid every 60, death wipe + fade. **Fixes:** (1) `.PlayerConstraints @1004cb4c` (M l. 43991–44123) was a no-op labelled 'later: W4' that neither plan nor D33 named — built (x ∈ [−64, 32·W−32], y ≥ −128 zeroing vy < −0x100, glider vy floor −0x9c4; called at raw `100513b0`); the arena lock (hdr 0x2724) → Phase 6 and the auto-scroll death → auto-scroll levels stay named stubs (both 0 on L1/L2). (2) The coin-loss hit makes the 0x516 Setup's draws per coin: R(9) R(6) R(3) + the shared tail R(0x3c) (`LAB_1005e8bc`) → **nine draws per coin** (two hand-built draw loops in the HurtPlayer tests corrected, no measured number moved; bank note in `pickups-boxes.md`). (3) Card/plan data: level 2 acid **114** cells (74 = damaging floor; plan gate card l. 1191 corrected), acid has no knock-back stun (M l. 44901–44906 vs 45106–45123), deep pool cols 144–160 rows 23–27, a cannon captures on touch. Open minors (unowned): the PlayerConstraints frame test cannot tell row 38 from a call after row 39, and its glider-after-y order is unasserted; lost coins draw even when `MTNewSprite` would find no free record (Phase 4).

## D34 — Ferazel's Wand goes to the unattended session loop: Ben's authorizations + the Fable cross-check rule (2026-10-13)

**Decided (Ben, AskUserQuestion in the setup session, 2026-10-13; he is away in Fiji for a few days and wants to come
back to a playable or at least testable game):** (1) **Scope:** the loop takes the whole game, phases 2 → 7 in design §8
order, as far as it gets; **phase gates queue, they do not block** — at each phase end it stages the build to
`~/Desktop`, writes the gate card into `docs/QUESTIONS.md`, and plans the next phase in the next run; Ben's later
verdict can re-open a phase. (2) **Phase plans 3–7:** the loop writes each plan when its turn comes (Opus planner), two
Opus review legs, **one Fable review leg**, fixes applied, rulings in a new D-number, listed in QUESTIONS for Ben's
read — **execution does not wait for his approval** (an exception to the standing "Ben approves plans first" rule,
for the loop only). (3) **Run / stage:** the loop may launch the staged `.app` for the G9 boot check and replace
`~/Desktop/Ferazel's Wand.app` (+ notes, icon previews); never delete `com.ambrosiaclassics.*` prefs; no notarization,
no release packaging, no installs. (4) **HectorKit:** the loop may commit to HectorKit's LOCAL `main` when a phase needs
it — own HK worktree, zero-skip floor may only rise, HK D-number, Classics STATE pins the SHA; never push either repo.
**Also Ben (chat, same session): "a Fable review for each phase ending (or major step like that); Opus 5.5 as the
primary otherwise — Fable is our cross-check for each major work."** Recorded in CLAUDE.md "Model policy": Fable legs =
each phase plan after its Opus legs, each phase end over the whole phase's diff + gate card before staging, and (seat's
reading of "major step") a tie-break when two Opus legs contradict each other on a MAJOR finding after one fix round.
Nothing else runs on Fable. This supersedes the 2026-10-07 "no Fable anywhere" tightening (memory
`feedback-no-fable-gate-every-task`) for those three cases only. The kit's generic `standing-prompt.md` (written the
same day) lists "a task the plan marks MAJOR" among its Fable triggers; for this project the chip narrows it to the
three cases above — Ben flips that by editing one line of `docs/NEXT.md` if he wants Fable on every MAJOR task.
**Seat's rulings (setup session):** the adapter is `.looper/config.sh` (REPO, local main, `docs/NEXT.md` chip,
`docs/QUESTIONS.md`, `docs/LOOP-LOG.md`, `STOP` + `.looper/logs/` git-ignored, `MODEL=claude-opus-5-5`,
`STALL_LIMIT=3`, `MAX_RUNS=0`, a `pre_run` that waits for this project's xcodebuild/SwiftPM processes and the staged
game apps to be idle, 30-min cap). One run = the next 2 ladder tasks (3 if ≤ 1 MAJOR), or a phase-end run, or a
planning run — the 300k cap sized at "2 MAJOR ≈ 190k". The loop never writes `STATUS: DONE` (Ben's word) and never
spawns chips; `STATUS: BLOCKED` only when nothing on the ladder can proceed without him (his brother's Windows test,
the notarized DMG, a remote). Gate numbers in the first chip were run from main 1aedbf4 on 2026-10-13: `Ferazel/Core`
154/0, census 1,108/0, Ferazel BUILD SUCCEEDED, HectorKit 0c65dcb clean, floor 328.
**Rejected:** blocking at each phase gate (Ben chose queued gates); waiting for plan approval per phase; HectorKit
read-only for the loop.
**Approved by:** Ben, 2026-10-13.

## D35 — Ferazel's Wand Phase 3 "Front end + saves": planning rulings (2026-10-14, loop run 8)

**Decided (seat, under D34's plan authorization — execution does not wait for Ben; his read is QUESTIONS Q3):** the plan
is `docs/plans/2026-10-14-ferazel-phase3.md` (Opus planner; Opus leg 1 plan-vs-dump SOUND WITH FIXES with four dump
verifiers; Opus leg 2 plan-vs-code SOUND WITH FIXES; Opus fix round; FABLE-GRADE plan leg PASS WITH FIXES — re-ran G2
256/0 in an archive, 1 MAJOR (L2 must run before L1) + 6 MINOR; Opus fix round 2). 17 Core tasks with tests (X1 R1 SV1
SV2 FE0 O1 L2 L1 M1 M2 F1a D1 F1b S1 P1 C1 C2), two app tasks (A1a A1b), phase end A2; 7 ⚑ MAJOR; ladder 256 → **345**;
nine runs ([X1 R1 SV1], [SV2 FE0 O1], [L2 L1], [M1 M2], [F1a D1 F1b], [S1 P1], [C1 C2], [A1a A1b], phase end). The
plan's "Rulings" section (17 items) is the full text; in short:
1. **Scope** = design §8 row 3 + §9 (d); out: inventory/pickups (Phase 4), enemies (5), bosses + `.Victory` (6),
   InputSprocket, resolution switching, CD check, debug keys (F4 is not debug-gated and is built).
2. ◇ **`BuiltLevels = 1...2`**: the map behaves as the original; a level without transcribed Setups shows a stand-in
   report and stays on the map. `-FerazelLevel N` kept as hidden New-Game-at-level-N within `BuiltLevels`.
3. **Front end = Core state machines on 60 Hz ticks** (`GameFlow`, `LevelRun`, `WorldMapRun`); the 2/4-tick level
   cadence moves from App to Core; ms fades → ticks rounded up [MED]. **Modal moments run inside a resumable frame**
   (`FrameSuspension`: save point, conversation, sign; Esc/⌘Q/⌘W/⌘P/Caps Lock at `.CheckGameLoopKeys`). One RNG stream
   for the whole game, owned by `GameFlow` between levels.
4. **Byte-exact persistence:** G 0x19978, save block **0xebe58 = 966,232** bytes (the bank's 965,208 was wrong —
   `save-continue.md` correction owed by SV1), prefs 0x942, big-endian; never-initialised bytes written as 0.
5. **Files:** prefs + saves under `~/Library/Application Support/Ambrosia Classics/Ferazel's Wand/`; a saved game is a
   classic resource map written into the **data fork** (type 'FWSg' / creator 'Msct'), the reader also takes a real
   resource fork; macOS save/open panels replace Standard File; the macOS system volume is never set (fields kept).
6. **No HectorKit change** (the draft's K1 was dropped: HK already has `ClassicResourceMap.serialize(_:)`, and
   `ShellMixer.load(id:)` under one fixed music id bounds memory like the original's dispose). HK stays 0c65dcb, floor 328.
7. **Menus/dialogs:** MBAR 128 transcribed, items live only in the main-menu and pause loops; windowed the macOS menu
   bar stays visible (changes design §7.4 for the windowed case — Q3); DLOG/DITL dialogs on AppKit adapted from BTX's
   `CarbonDialog` into `Ferazel/App/Dialogs/`.
8. **Design §9 (d):** a save naming a missing level shows "An unexpected error occurred -- the level could not be
   loaded from the world file!" (0x100a2e76, the original's only displayed text for it) and returns to the menu.
9. **Settled by the binary (were draft questions):** death without a save returns to the main menu (D33's restart
   stub retires with the App's `Ending`); the Controls panel refuses the A key as "already used" (zeroed slot 9).
10. **Bank corrections** BC1–BC30 (plan section) are appended to the named bank files by the tasks that rely on them.
**Rejected:** a HectorKit resource writer (exists); "Tried to open a level that wasn't there!" (never shown by the
original); a real resource fork by default (stripped by zip/git/Windows — Ben may choose it, Q3); restart-after-death.
**Approved by:** seat under D34 (Ben reads later, Q3).
**As built (loop run 9, 2026-10-14) — wave 3.0 + SV1:** X1 (6c32f4e) — `stopAll` left as is (the plan's "redundant
stopEffects" premise was wrong: the mixer's `stopAll` does not stop the Sound Tool stream) and the glider order ruled
unobservable (test pins row 38 → 39 instead); R1 (5c91bd3) — DLOG/ALRT/DITL/CNTL/MENU/MBAR parsers, plan's DITL 6902
numbers are dialog item numbers; review fixes ebed14e; SV1 (ebbd7aa + d8f2ebe) — G image (0x19978) and save block
(966,232) byte-exact; the writers take the live G `inout` (the binary flags `hasSnapshot[L]` in it before the copy —
S2 amended); BC7 corrected (the four 200-byte rows are zeroed by InitGameGlobals), +0x174 u8. Ferazel/Core 256 → 266/0,
census 1,108/0, Ferazel builds, HectorKit untouched (0c65dcb, 328).

**As built (loop run 10, 2026-10-14) — rest of wave 3.1, wave CLOSED:** SV2 (d88a7f1) prefs record 0x942 + `PrefsFile` +
`SavedGameFile` ('FWSg' 0 in the data fork, resource-fork read and HFS type/creator under `#if os(macOS)`) + `SaveName`;
FE0 ⚑ (9bd5d1e) every S3 case, `ScreenSurface`/`ScreenRenderer`, `ScreenFade`, `MusicFade`; O1 (0810ff3) Options dialog
model, `.MakeCurrPrefs`, ⌘M/⌘F; review fixes 6d919da. **Rulings (follow the binary):** the async music fade-in clears
the music-faded flag at its start (raw 10049c5c); `.stop` only when music is loaded (M l. 41943), so ⌘M on emits
`.play`, `.volume(V)`; the slow fade-in is linear and non-compounding through the ADDED `ScreenGammaOp.timedFadeToColor`
(Invariant 9 — a case added; not in the S3 list); `PutFileRequest {prompt, defaultName, message}` defined by FE0
(the plan named, never defined it); an unreadable prefs file falls back to defaults. Ferazel/Core 266 → 284/0, census
1,108/0, Ferazel builds, HectorKit untouched (0c65dcb, 328).

**As built (loop run 11, 2026-10-14) — wave 3.2 CLOSED (L2, L1):** L2 (d144872 + fix a5c1beb) `StageScreens`: popup +
load bar, chapter card, stage-complete panel, `CalcPercent`/`FillPercent` as `FrontTimeline`s; L1 ⚑ (6db035d + fixes
6615728, aa78964) `LevelRun` + `LevelServices`: level entry (`.SetupLevel` first visit / restart fast path / snapshot
restore, load bars, fades, one `.play` + 96-tick music fade-in, chapter gate, async fade-in every entry), the 2-tick
cadence, died/completed/aborted exits → `LevelEnd`; session seams `start:`/`refreshFacing:`/`records:`/
`hostedByLevelRun:` + `startOps()`, defaulted to Phase-2 behaviour. **Rulings (follow the binary):** "any key" =
`.IsAnyKeyDown` (keycodes 1–127 + a locked Caps Lock; M l. 31579); the completion save stores the player's exit position
(`*fe68/*fe64` per frame, M l. 46367–46376); `FadeAIFFMusic(0,4)` + shutdown are inside `.GameLoop` so Continue runs them
(the plan said skipped); F4 clears the snapshot flag ungated; `LevelRun` output is ordered segments tagged `.level` /
`.screen` (ADDED shape, so A1a can route ops to FrameRenderer vs ScreenRenderer); per-iteration `HideCursorSafe`
(M l. 5233) + the fade-end `ShowCursorSafe` (M l. 31945) only for hosted sessions — the Phase-2 direct path keeps its
expectations (Invariant 10) until A1a moves the app onto LevelRun; `PlatformSprite` reads live records. **Named task
added:** RX (Roach Setup p3 0 → 0xaa write-back, M l. 64940–64944; changes one named BackgroundMoverTests expectation),
first in the next run. Ferazel/Core 284 → 297/0, census 1,108/0, Ferazel builds, HectorKit untouched (0c65dcb, 328).

**As built (loop run 12, 2026-10-14) — wave 3.3 CLOSED (RX, M1, M2):** RX (83786a7) Roach p3 0 → 0xaa write-back (the
named BackgroundMoverTests expectation; other Setups' write-backs listed in the plan, none on L1/L2). M1 ⚑ (072bf8b + fix
70384af) `WorldMapRun`: entry, unlocks by target level, node sprites + `FastRand(15)` per visible node, `.DrawNewLink` (snd
420, 50 × ≥ 2 ticks, 150 draws), the 29-frame walk, `.CheckPlayerNodeMovement`, exit keys + confirms, exit resets. M2
(b79e58e + fix 548019f) `MapRenderer`: PICT 7000, slop-8 node faces, links, flashes, first-frame golden
`38563faaa2276f05`. **Rulings (follow the binary, BC31):** the map loop's walking test is `step ≠ 0`; entry order clut 700 →
PICT 129 → status bar → graphics → PICT 7000; a second status-bar update after the first frame; a clear level-complete flag
or a nil/empty Mmap returns 1; no current node → ExitToShell (a quit request, no result); FlushEvents + ShowCursorSafe only
inside the Q and W/Esc branches; the node-sprite list is emptied on exit (and by `.InitPlayerMapData`), not on entry; the
plan's `testLinkPixels` geometry was impossible (stepped line) → each flat pair checked; lines rasterised from the upper
end point [MED]. Ferazel/Core 297 → 308/0, census 1,108/0, Ferazel builds, HectorKit untouched (0c65dcb, 328).

**As built (loop run 13, 2026-10-24) — wave 3.4 CLOSED (F1a, D1, F1b):** F1a (24330a0 + fix 75c6052) `GameFlow` part 1:
boot (logo PICT 131, title music 24, F1 / N+F boot keys, the 3-D load bar), main menu (hot rects, button tracking by mouse
and keys, the X joke), Quit, Credits scroll timing, and `.Options` in Core (A1b only renders it). D1 (b63332e + fix
75c6052) `DeathScreen`: AskToContinue, death buttons, WandGlow, TurnGray. F1b ⚑ (9cc9d01 + test fix 4593041) New
Game and Continue loops, level ⇄ map, death → AskToContinue → Continue from the last save, the refusals, the missing-level
report, `BuiltLevels` 1…2, `FerazelLevel` as `startLevel`. **Rulings (follow the binary):** `.Quit` sets clut 801 and shows
the menu bar before quitting; the menu button sounds 4803/4804 play even with sound loading off (`.InitAppGlobals` loads
them unconditionally — the App must too); after TurnGray no CLUT op (the original only copies the level table back — the
screen stays black until the menu return draws; the plan was wrong); Continue's normal path sends no menu-bar hide and no
fade-out on the death screen's Continue (both are in the never-taken fallback branch); New Game's per-level music fade runs
before `.GameLoop`'s own (which then finds nothing); `.InitGameGlobals` empties the map node sprites for both New Game and
Continue; New Game clears `fd54` after the missing-level check; a refused save still leaves G loaded. Accepted deviations
(low): F4 held at Continue does not keep Continue's own snapshot copy; a non-save file keeps the old save block (the
original nils it — undefined behaviour later). Ferazel/Core 308 → 323/0, census 1,108/0, Ferazel builds, HectorKit 35a85ba
untouched (floor 361).

**Addendum — Ben's Q3 answer (written by his attended session, commit 8b318d3; recorded by loop run 13):** the
defaults, all four — (1) saved games in the data fork; (2) the macOS save/open panels; (3) the menu bar visible in a
window, hidden in full screen; (4) keep the hidden `-FerazelLevel N` switch for now ("probably" — he may revisit). The
plan already builds exactly these; no task changes. Q1 (the leftover loop-1 worktree) was done by the same session.

**As built (loop run 14, 2026-10-24) — wave 3.5 CLOSED (S1, P1):** S1 ⚑ (8f37a71 + fix 18ecb64 + tests bde40b6) the
resumable frame (`FrameOps.suspension`, `FerazelSession.resume(_:)`, the special pass continues from the next contact)
and the save point: the 0x429 landing hold (fires on the 15th landing, re-fires on the 65th after a cancel),
`.SavePointSave` / `.SaveSG` (reuse, prompt, delete, name, prefs, write; cancel restores the name; a write error keeps the
original's half-done state), the white success flash (420/421, 3 + 46 fade steps), statue faces. P1 (9daa907 + fixes
57a76c2, fb0d565) `.CheckGameLoopKeys` (⌘Q/⌘W/⌘P/Esc confirms, a second suspension point before `.UpdateSprites`) and
`.Pause` (Caps Lock counter 10/5, snd 198, banner PICT 4921, music out/in, menus, from the map too); new draw op
`drawBlackLines` for graphics mode 3. **Rulings (follow the binary):** the stored save prefs become the live prefs
(`.UpdateSGString` runs `.MakeCurrPrefs`), and a save or ⌘P re-applies them to the running level; `.PaintFrameWrap(1,x)`
in the confirm and pause paths is a whole frame pass (sprites, collisions, save point), not a redraw; pause exit restarts
the music before fading it in; the pause banner has no offset; `DrawBlackLines` covers rows 9–389 (191 rows) and also
runs in the save point's `RedrawGameArea`. **Plan gap ruled by the seat:** the `GameFlow` side of saving had no task —
S1 took it (`GameFlow` carries the file seam and the three save flags into each level and reads them back), because a
save point inside a real game would otherwise wait forever. **Stand-in ◇ (A1a removes it):** the current app answers any
suspension "cancelled" at once, so a save point does nothing in today's app instead of crashing. **Named follow-up EC:**
every save-error report carries the code (dump raw `1004851c`); SV2's test says three carry none — moved by name next
run. Ferazel/Core 323 → 335/0, census 1,108/0, Ferazel builds, HectorKit 35a85ba untouched (floor 361).

**As built (loop run 15, 2026-10-24) — wave 3.6 CLOSED (C1, C2, EC):** EC (353f76a) every save-error report carries the
code. C1 ⚑ (cfdfc43 + fix 837619d + tests 888be68) conversations and signs: the NPC arm (cooldown 150) and sign arm
(cooldown 90, p4 auto-read, UP re-read, 2902/2907/graves fall-through), `ConversationRun` (the Mcnv interpreter as a tick
machine: typing 2 ticks/char, trail, menu, conditions, actions 0–10) run by `LevelRun` inside the suspended frame. C2
(42df853 + fix 7c31c36) `ConversationRenderer`: frame PICT 4000 see-through, portraits, Times 18 text, trail greys,
response rows; `TextRasterizer` widths/metrics. **Rulings (follow the binary):** signs include type 2902; Escape stops the
reply text before every chunk; input after a talk is read live (the outcome carries the polled keys + Caps Lock); the
conversation GWorld is built at boot on the Mac default 8-bit clut, so PICT 4000 and portraits are dithered through it
and then copied by colour (36,590 of 119,196 frame pixels differ from a one-step conversion). **Seat rulings:** (1) Core
owns the 214-px wrap through a measures seam (`ConversationText`) because a line break changes the typing timeline —
A1a sets the real measures; (2) plan gap — three test drivers that walk onto L1's first sign now answer the talk at once
(no expected value or golden moved). Ferazel/Core 335 → 345/0, census 1,108/0, Ferazel builds, HectorKit 35a85ba
untouched (floor 361).

**As built (loop run 16, 2026-10-24) — wave 3.7 CLOSED (A1a, A1b): the app runs on `GameFlow`.** A1a ⚑ (7d64447 + fixes
9566578, b692dd8): the 240 Hz timer drives `GameFlow.tick`; segments routed in order to the screen/frame/map/conversation
renderers on one shared surface; real text measures for conversations; music on one mixer id with the 0…256 volume;
`FerazelFiles` (prefs file + saved-game panels, Finder open, 'FWSg' document type); the ◇ suspension stand-in and the
Phase-2 ◇ helpers are gone. A1b ⚑ (2902f93 + fixes e7545cd + tests 771625d): Dialog Manager windows from the original
templates (DLOG 202 confirm, 200 report and error, 6900 Options with key capture, 600 Credits) and the MBAR 128 menus,
live only where the original read menu events (main menu, pause loop). **Rulings (follow the binary):** the quit and
open-document Apple events are queued first-in-first-out and handled only at the main menu's event check and the pause
loop; the in-play fetch (only with "Allow background tasks") throws them away; a Finder open during a game is therefore
continued after it, not ignored; report and error share DLOG 200; the confirm has no cancel item (Esc does nothing); at
the main menu ⌘N/⌘O/⌘P/⌘Q act as the plain letters; each main-menu button flushes events first. **Seat rulings:** a
system Quit (Dock, logout, app menu) is queued and the terminate is cancelled at once — no terminate stays pending through
play — and the flow's own Quit then terminates unasked (QUESTIONS Q5, Ben's later read); the boot idle keeps queued
events for the menu pass; 4803/4804 are sounds, and 198/4801 load even with F1. Ferazel/Core 345/0 (unchanged by
design), census 1,108/0, Ferazel builds, HectorKit 35a85ba untouched (floor 361).

**As built (loop run 17, 2026-10-24) — PHASE 3 MACHINE-CLOSED (GP + A2); Ben's gate = QUESTIONS Q6.** GP (325d2e4 +
88a0809): the pad acts as the original keys per D37, with three contexts the plan's table lacked — conversations (d-pad
= the prefs move keys, as `ConversationRun` reads them), the world map and the death screen (− is the 1 s hold there
too: a seat ruling under D37's own reason — on the map Esc opens an abort confirm whose OK any face button presses, and
on the death screen Esc gives up unasked). A2: staged, two clean boots (the first launch of the GameFlow app), the
gate card rewritten (`Ferazel/WHAT-TO-EXPECT.md`), Fable phase-end leg "stage as is after doc fixes" (dump fidelity
MATCH across the front end, saves, map, pause, stage panel; 9/9 mutations killed) → doc/comment fixes 3553392, restaged.
Ferazel/Core **349/0**, census 1,108/0, Ferazel builds, HectorKit 35a85ba untouched (floor 361). Next: plan Phase 4
(design §8; next free D38).

## D36 — A game controller acts as Bubble Trouble X's original keys (2026-10-22)

**Decided (Ben, 2026-10-22 — his kids play on a Nintendo Switch and find BTX's keyboard hard):** a controller (their
Switch Pro Controller first; Xbox / PlayStation / Joy-Con as GameController delivers them) works out of the box and
acts as the ORIGINAL keys. The Mac shell around the game changes; game behaviour stays 100 % the original's (the standing
ruling carried from EV D30/D67) — BTX Core is untouched and never sees a pad. Mechanism: HectorKit **D16** (`HectorInput` translator,
`ShellGamepad`, `ShellView.padMapping` — pad keys merged into the polled key state, the pause latch ORed into Caps
Lock, pad key-down edges delivered to the app). Plan `docs/plans/2026-10-22-gamepad.md` (Fable review record folded in).
**The layout** (`BubbleTroubleX/Shared/BTXPadLayout.swift`, Foundation + HectorInput + `KeySet` only, so W1 compiles it):
1. **In play** (a play-mode session in its game, no dialog): d-pad / left stick → the CURRENT key set's left / right /
   up / down; all four face buttons → its push (Nintendo and Xbox swap A/B and X/Y labels — no "which one is A");
   + / Menu → Caps Lock toggle (BTX pauses on the lock state, so a latch, not a held key); − / View → Esc only after a
   1 s hold (a stray press must not end a kid's game). Remapping a key in Preferences remaps the button.
2. **In play with a dialog up:** + stays the Caps Lock toggle (the pause survives the dialog); face → Return; − → Esc.
3. **Everywhere else** (splash, menu, screens, demo, dialogs): face and + → Return (start, continue, OK); − → Esc at
   once (Cancel); d-pad → the fixed arrows 0x7B–0x7E, never the key set — the menu acts on characters, so the J/L/I/K,
   Z/X, Q/W/E/R sets would fire menu commands (L level select, Q quit, X/Z poem/quote…).
4. Shoulders, triggers, stick clicks unmapped.
**Wiring (Mac):** `BTXController` assigns the mapping before every poll; pad key-downs go to `FrontEnd.key` like a
keyboard key-down (US characters per key code, `ShellKeyCharacters`); while a dialog is modal (every game clock stopped)
the dialogs' 1/60 null timer polls, and Return / Esc reach the front panel as a synthesized key-down + key-up posted to
the event queue (the dialog keys live in a local event monitor; `sendEvent` would bypass it).
**Known limits** (GAMEPAD.md): − works only un-paused (Esc is read in play, not in the pause); with "Hold Escape to
exit" the hold is ≈ 2 s; no pad typing — face = OK accepts the default high-score name.
**Windows (W1, built):** HectorSDL opens every SDL3-recognised gamepad (XInput pads, Switch Pro, PlayStation) and
reports `padState()`; `WinGameDriver` compiles the SAME `BTXPadLayout.swift` (git symlink into BTXWinKit), merges pad
keys by union at each read (never into the keyboard's held set, so neither releases the other), ORs the latch into Caps
Lock, polls on the dialog tick too, treats focus loss as the Mac's inactive app. A device SDL has no gamepad mapping
for is not opened. Not yet in a published Windows zip (needs Ben's word).
**Later:** Ferazel adopts via its own plan (play keys; no pointer emulation for its mouse-driven map/dialogs).
**Rejected:** d-pad = key set outside play (fires menu commands, review record #2); per-button labels (A ≠ B) — kids
cannot tell them apart across Nintendo / Xbox; a pad-configuration UI (not in the original; the key set already
remaps); `window.sendEvent` for dialog keys (bypasses the monitor).
**Approved by:** Ben, 2026-10-22.

## D37 — Ferazel's Wand gets game-controller support in Phase 3 (Ben's Q4 answer, 2026-10-24; recorded by loop run 13)

**Decided (Ben, 2026-10-24, QUESTIONS Q4 (a) — "let's go" after BTX's pad passed; his kids play on a Switch and the
keypad defaults are hard):** Ferazel adopts the D36 / HectorKit D16 mechanism as a named Phase 3 task, **GP**, landed
before the Phase 3 gate build so Ben's next play test can use a pad. The pad only presses keys the original reads (held
keys merged into the polled key state, + as a Caps Lock latch), so game behaviour stays the original's — the same class
as Q3's shell-only choices. Remapping a key in Options remaps the button.
**Default layout (Ben delegated it in Q4 (a); the seat chose, loop run 13):** in a level — d-pad/left stick = the four
move keys of the current prefs, south + east = jump, west = run, north = use, L/R shoulders = previous/next item, ZL/ZR
= run, + = Caps Lock toggle (pause), − = Esc after a 1 s hold (a stray press must not abort a kid's game); paused — only
+; main menu — south/east and + = N (New Game); everywhere else — d-pad = arrows, face and + = Return, − = Esc. Full
table: plan `docs/plans/2026-10-14-ferazel-phase3.md` task GP. Positions, not labels (Nintendo/Xbox swap A/B, X/Y).
Jump on the bottom/right pair follows the platformer convention kids know (Mario: B/A jump, Y run).
**Not done:** no pointer emulation (Continue/Options/Credits on the menu, the Options dialog and the file panels stay
mouse/keyboard); no pad configuration UI (the key remap already exists). HectorKit unchanged — Classics pins HK main
**35a85ba**, zero-skip floor **361** (moved from 0c65dcb / 328 by the BTX gamepad work; Ferazel/Core 308/0 against it).
**Ladder:** Phase 3 345 → **349** (GP, 4 tests); run 9 = [GP] + the phase end.
**Approved by:** Ben, 2026-10-24 (the ruling); layout by the seat under his delegation — his pad play at the Phase 3
gate is the check.

## D38 — Ferazel's Wand Phase 4 "Spells + items": planning rulings (2026-10-24, loop run 18)

**Decided (seat, under D34's plan authorization — execution does not wait for Ben; his read is QUESTIONS Q7):** the plan
is `docs/plans/2026-10-24-ferazel-phase4.md` (Opus planner; Opus leg A plan-vs-dump SOUND WITH FIXES — ~10 important
dump disagreements, e.g. the cast press moves the spell to the front, 14 power-up warning marks from 210, the second
scroll's slot search, the pickup bounce argument, the dagger cannot crunch; Opus leg B plan-vs-code SOUND WITH FIXES —
1 critical: the teleporter search tests only the in-use byte, so level 1's teleporter 126 sends the player to record 0;
the teleport is two suspension stages; missing seam files; run-time-spawned faces need sheet-table entries; SW moved
after BX1; Opus fix round f8d250c; FABLE-GRADE plan leg PASS WITH FIXES — re-ran G2 349/0 in an archive, ~25
independent samples agree, 1 important (CS's same-frame stab assertion belongs to IU) + 8 minor; seat ruled LV3 back to
⚑ MAJOR; Opus fix round 2 b55e7c5). 24 tasks + phase end A4; 12 ⚑ MAJOR (LT US BN PK EF CS SH IU SD BX1 TP LV3); ladder
349 → **481**; ten runs: [X1 VS LT] 357, [US IV HU] 374, [BN PK] 390, [EF CS] 406, [SH GL PU] 425, [IU MS] 438, [SD BX1]
451, [BX2 BT TP] 467, [SW LV3 LV4] 481, [A4 + Fable phase review]. Bank corrections BC35–BC50. The plan's "Rulings"
section (16 items) is the full text; in short:
1. **Scope** = design §8 row 4 + §9 (c); out: enemy Handles/Hits/Kills + enemy shots + geysers (Phase 5), bosses +
   `.Victory` (6), Box/Background types first placed on levels ≥ 5 (the phase that widens past 4), the debug kit.
2. **`BuiltLevels` → 1...3 (LV3), 1...4 (LV4); level 5 (first boss) stays refused**; report text "(Phases 5-6)".
3. **Enemies on levels 3–4 keep the Phase-1 Setup-face stub** (drawn, inert); `.SmiteEnemies` still finds them by class.
4. **The light table moves into Core** (`LightTable`, single source of truth; renderer gets it per frame).
5. **Idle-only sound calls decided in Core** (`SoundVoices` from the shell's playing set + the iteration's own cues);
   gate (BT) and spikes (LV3) owned here, cannon site M l. 62997 → Phase 6.
6. **Three new in-frame modal moments:** the upgrade animation, the teleport (two stages), the USE hints (a resumable
   player Handle, including the nested pass inside `.PaintFrameWrap`).
7. **`.UpdateSprites` in full** (four-pass kill, record write-back): saves persist pickups, doors, chests, torches, latches.
8. **Boulder spouts' boulders are ◇ until Phase 5.**
9. **§9 (c)** copied as the code permits; enemy drops are Phase 5's Kill routines.
10. **No HectorKit change** (HK 35a85ba, floor 361).
11. **Unreachable player systems built now** (spells 2–7, items, glider, Mist potion, necklace), pinned by synthetic tests.
12. Arms inside routines transcribed whole are built where they sit even if first used on level ≥ 5.
13. **Status-bar call parameters come from Core** (`StatusBarCall`); the HUD shows G's inventory and maxima.
14. **The Effect class gains every id Phase 4 spawns**; the 1207 explosion hurts the player (enemy damage Phase 5).
15. **Carried follow-ups:** stale later-stubs + M7 adopted (X1); Phase 3 front-end polish left to Ben's Q6 verdict.
16. **No free record:** a spawn with all 700 records in use runs no Setup and no draws; caller stores dropped (BC46's rule).
**Rejected:** keeping levels 3–4 closed until Phase 5 (Ben can still choose it in Q7); deferring unreachable spells/items
to the phases that open their levels (no later phase owns player systems).
**Approved by:** the seat under D34; Ben's later read = QUESTIONS Q7.

**As built — wave 4.0 (loop run 19, 2026-10-24; main 18e00de):** X1 (stale Phase-2 stubs relabelled, `TileHotRects(level:)`
deleted) → 349; VS (`SoundVoices`, `FrontInput.playing` from the Sound Tool; nil-handle query/stop = every voice, Core and
Render, follow the binary M l. 78341) → 352; LT ⚑ (Core `LightTable` + `DrawOp.lightTable`; nil-face add returns the free
slot — follow the binary, bank corrected; **seat ruling: `.lightTable` goes before `.redrawScrollGrid`**, not after, so the
renderer's strip lights read the current table) → **357/0**, census 1,108/0, Ferazel builds, no golden moved, HK 35a85ba
untouched. Details: the plan's "As executed" notes for X1, VS, LT.

**As built — wave 4.1 (loop run 20, 2026-10-25; main 38b144b):** US ⚑ (`.UpdateSprites` in full: kill passes, record
write-back, keep-record flags; `dead` computed over `killCount` +0xe9) → 362; IV (`Inventory` on `GameGlobals`) → 368; HU
(the status bar from the game globals; `StatusBarCalls`) → **374/0**, census 1,108/0, Ferazel builds, no golden moved, HK
35a85ba untouched. **Seat rulings (follow the binary):** (1) the write-back flags `+0x188/+0x189/+0x18a/+0x18b/+0xea` are
set by every Setup already built in Core at the dump's sites (Platform M l. 54530, Rope 71107/71136, Background modes
10–14) — each later task sets them for the Setups it builds (BN, BX1, Phase 5 enemies); (2) `dead = true` stores the
literal 1; `.IdleToActiveSprite` clears +0xe9 and rebuilds the 24.8 position (M l. 4262–4264); (3) `.UpdateHealthMagic`'s
clamps, caches, skips and the suffocation tick snd 442 are Core state; (4) the status-bar globals (the 12-call repeat
counter, the four bar caches, the five flash globals) are ONE flow-wide instance carried through map and levels, never
reset, not saved; (5) a status-bar call outside the frame loop emits its sound in its own output. Details: the plan's "As
executed" notes for US, IV, HU.

**As built — wave 4.2 (loop run 21, 2026-10-25; main 92419b6):** TB (seat-inserted: sprite draw mode 0xb, translucency,
`.BlitEncFaceTransClip`/`…FlipClip` + `.CalcPxRowContents` + table 0148) → 377; BN ⚑◈ (the Bonus class: Setup, Handle,
rest on boxes, tile bounce, KillBonus totals, write-back flags, M6) → 385; PK ⚑◈ (the pickup arm, the 120-tick upgrade
suspension, the hurt coins) → **393/0**, census 1,108/0, Ferazel builds, HK 35a85ba untouched. **Seat rulings:** (1) BN
hit Invariant 10 — the level-1 sphere writes mode 0xb, which the renderer refused (a plan gap): **mode 0xb is built as its
own task TB before BN, following the binary, rather than stubbed** (blinks, trails and spirit form need it later); the
ladder shifts +3 from BN on (wave ends 393 · 409 · 428 · 441 · 454 · 470 · 484); (2) a flipped translucent sprite over the
view's left edge reads what the binary's truncating divide reads (previous cell row, 0 before the pixel base) — never a
refusal that stops the app; (3) the upgrade resume carries the resume tick's keys like the conversation resume; the
async fade's arm sends the cursor hide. **◈ goldens moved, causes confirmed by switch-off:** BN pan 30/60/chain, jump, swim,
600-frame (+ cues, seed, particles); PK swim and 600-frame again (level 1's route now collects a potion and five
Xichrons). New values: STATE / the plan's "As executed" notes for TB, BN, PK.

**As built — wave 4.3 (loop run 23, 2026-10-25/26; main 03a2c52):** EF ⚑ (the Effect ids: explosion package, light
schedule, 1207 big-explosion hurt via `.HurtSprite`, 3099 debris; `ScreenFlash` + `DrawOp.copyMaskToScreen`; the camera
shake) → 403; CS ⚑ (casting: the USE gate, the wand steps, `.CastSpell`; the player shots in flight: followers, lights,
Boomerang, V Blade, liquids) → **412/0**, census 1,108/0, Ferazel builds, HK 35a85ba untouched, no golden moved. **Seat
rulings:** (1) the flash count/toggle, the paint counter and the plume count ride `LevelCarry` (data-section globals,
never reset); the shake rides it too, zeroed only by `.InitGameGlobals` (New Game, Continue); (2) a player shot touching a
spring runs `.KillPlayerShot` as the binary — built in full by CS in SH's file `Shots/PlayerShotHits.swift`, because a
stub skipping its sound/Effect draws would desynchronise the RNG (Invariant 6); (3) the stale-r29 recolour at the spring
site is built as a no-op [MED]. Details: the plan's "As executed" notes for EF and CS.

**As built — wave 4.4 (loop run 24, 2026-10-26; main e67a795):** SH ⚑ (player-shot impacts: `.HitPlayerShotSprite`,
the rest of `.HitPlayerShotTileSprite`, the container arm of `.HitBonusSprite`, the stalactite's shot case; seed explosions,
Boomerang refund, 2941 ice wall, crunch cells) → 420; GL (the hang glider: deploy, pitch gravity + wind, steering, dive,
landing, stow) → 425; PU (`.TickTock` warnings and expiry, Featherfall/High Jump/Double Speed/solid liquids/Invincibility/
Death timers, the Double-Speed trail) → **431/0**, census 1,108/0, Ferazel builds, HK 35a85ba untouched, no golden moved.
**Seat rulings:** (1) SH's hit routines treat an idled record as matching nothing wherever the dump compares the other
sprite's Handle (`runs()`), and keep type tests where the dump compares the type; (2) the enemy-shot and Crawler arms stay
named Phase 5 stubs (no handler exists); the Statue arm is SW's (Phase 4) — noted in SW's section; (3) the stale r29 is
transcribed per call site (container → inventory slot 12's count, built; crate arm → the shot's own light, noted for BX1);
(4) GL: an older test row that pinned the steering stub (vx 0 on the glider) now expects the dump's steering step 0x96 —
a named stub's placeholder, not an expectation edited to agree; (5) PU: tests that set a power-up flag directly also set
its timer (row 14 now clears a flag whose timer is 0). Dump-over-plan corrections (glide vy −839, steering cap 0xce4,
Featherfall clamp before gravity, 0x4b7 layer 0xb …) are in the plan's "As executed" notes for SH, GL, PU and the bank BCs.

**As built — wave 4.5 (loop run 25, 2026-10-26; main a3512db):** IU ⚑ (USE with an item: the item gate and switch, the
held weapon — dagger, Ice Pick, Vorpal Dirk stabs — thrown seeds, health/magic potions, the Smiting and Escape Rings, the
three hint conversations raised **inside the player's Handle** with a resumable handle pass, top-level and nested in a
pause redraw; the shield raise needs a shield) → 439; MS (the Mist potion's spirit form and the way back into the body,
the Resurrection Necklace, the Fire Charm, the Multi Crystal loss) → **444/0**, census 1,108/0, Ferazel builds, HK
35a85ba untouched, no golden moved. **Seat rulings:** (1) IU: two existing tests adapted to M l. 47543–47550 (the item
branch sets both latches and zeroes idle/fidgets) — `CastTests`' same-frame stab, `PauseKeysTests`' ⌘Q twin holds ⌘ alone;
(2) the nested-hint flag is a session property, the locked seam keeps `.hint(text:)`; (3) MS: the spirit timer is a
halfword — `PlayerTiles` read it wrong, fixed (the Mist form now passes through tiles). Dump-over-plan corrections (melee
faces 1021, necklace in row 33 not 41, no lava immunity, spirit form 12 frames after the drink's 40) are in the plan's
"As executed" notes for IU and MS and the bank BCs.

**As built — wave 4.6 (loop run 26, 2026-10-26; main d6958e2):** SD ⚑ (the Shadow Double — row 11 makes it, its Handle
replays the player's pose 14 frames behind from the 14-entry ring row 42 writes, cast copies take its pose; the
Pentashield orbs `.UpdatePentSprites` — record 0x1ff, 360°/n at radius 0x30, 3 hits; the Shadow Double flag clears in
row 33's two state branches) → 449; the ring's mirror bytes ride `LevelCarry` (never reset by the binary). BX1 ⚑ ◈ (the
Box common tail — friction, foot pressure, max speed, gravity + separation, BoxCleanUp; `.HitBoxSprite` in full but the
Statue (SW) and carpet (Phase 6); `.HitBoxTileSprite`; `.KillBox`; `.KillCrate` drops and the explosive crate; boulders
roll and bounce; mine carts and their children; stalactites shake and fall; the 2941 death arm; the spin stomp — DOWN keeps
the spin, M l. 49378) → **457**. No golden moved (no Box is awake on the golden routes). Seat ruling: the BoxRope push
assertion pinned the pre-tail placeholder → the dump's (3011, 1456). Both tasks two Opus legs, MERGEABLE WITH FIXES →
tests rounds; two small behaviour changes seat-read (mirror carry; `+0x182` cleared before unbuilt arms return).

**As built — wave 4.6Q + wave 4.7 part 1 (loop run 27, 2026-10-26; main 3efd22f):** QT (Ben's Q5, D40 — see D40's
as-built) → 460; BX2 ◈ (chests, doors and keys, the thought balloons; the 2907 timer's contact; a chest drop no Bonus arm
handles takes the Bonus Setup's item arm as the binary does — light + R(16) + R(60); no golden moved) → 466; BT (Buttons —
a new `.button` handler, pressed **twice a frame** by a player standing on one, as the binary's two collision passes do;
gates 2940 with idle-only sounds via `SoundVoices`; switch blocks; boulder spouts with the shot ◇ Phase 5; no golden
moved) → **472**. Census 1,108/0, Ferazel builds, HK 35a85ba untouched. Details in the plan's "As executed" notes.

**As built — wave 4.7 end + wave 4.8 part 1 (loop run 28, 2026-10-26; main b0af49b):** TP ⚑ (teleporters: a landing
sets the touch flag and resets the idle counter every time; at charge 80 the pulse fires → snd 421, a 57-tick mosaic out
inside the frame (`.teleport(record:stage:)` + `DrawOp.mosaic`), the player moved to the last in-use idle entry — active
ones included — whose record index is the teleporter's p1, the camera re-seated by 120 passes, snd 420, the mosaic back in,
charge −59; the transition's copy goes to an offscreen port as the binary's does, routed by the copy-before-`.mosaic` rule
since the seam is LOCKED; no golden moved) → 476 — **wave 4.7 closed** (G3 1,108/0, G5 SUCCEEDED); SW (Ice Wall floes in
water and ledges on walls (layer −1 per the dump), Tree Trunk segments that grow and blink out, the Statue spell freezing
a platform for 120 frames then HP −200; **seat ruling:** SW also builds the player's Statue arm in `.HitPlayerSprite` (M
l. 49506–49513 — a bounce, then return), a file beyond the task's list, so the player can stand on a statue; no golden
moved) → **482**. HK 35a85ba untouched. Details in the plan's "As executed" notes.

**As built — wave 4.8 end (loop run 29, 2026-10-26; main 3f9b391):** LV3 ⚑ (level 3 "Western Reaches" enterable: all 216
records set up; the retracting spikes — frame 0 fully out, per the dump, against the plan's text; the hurt stores the climb
reset and no-cling before the invulnerability check (bank corrected); the five level-palette face groups follow the level's
palette; the level-load picture cache gained level 3's marks incl. the mine cart's two sets — 30 bar steps; the enemy stubs
set counted-in-totals) → 486; LV4 (level 4 "Eastern Reaches" enterable, `BuiltLevels` 1...4, "Level n is not built yet
(Phases 5-6).", the sheet table gained 0xbea, 0x514/0x515, 0x4bf; drops checked per level's renderer) → **490** — **wave 4.8
closed** (G3 1,108/0, G5 SUCCEEDED, no golden moved, HK 35a85ba untouched). Next: the Phase 4 end run (A4 + Fable phase review),
then the Windows plan (D41).
**As built — Phase 4 end (loop run 30, 2026-10-26):** A4 (2f01491, 28ebcab, 4bca4bd): the `later: Phase 4` sweep (comment-only,
every leftover relabelled to its owner or rewritten as built), `Ferazel/WHAT-TO-EXPECT.md` = the Phase 4 gate card as built,
staged to `out/Ferazel/` + `~/Desktop/Ferazel's Wand.app` (G9: two clean boots per staging). **FABLE-GRADE phase review: PASS
WITH FIXES** (gates re-run 490/0, census 1,108/0, SUCCEEDED; ten high-risk ports read against the dump, no divergence; card
wording fixed). Seat rulings: the Magical Shield crouch face → Phase 5 with `.ShieldBlock`; the unbuilt underwater screen
tint (`.TintScreen`, a Phase 2 carry) → a named task in the Phase 5 plan. **Phase 4 machine-closed; Ben's gate = QUESTIONS
Q11.** Next (D41): the Ferazel Windows plan, before the Phase 5 plan.

## D39 — Ben's Phase 2 + 3 play-test verdicts (pass with notes) and Apple system fonts may ship (2026-10-25; recorded by loop run 22)

**Decided (Ben, QUESTIONS Q2, Q6, Q8 answers, 2026-10-25):**
1. **Phase 2 "Ferazel moves" and Phase 3 "Front end + saves" PASS WITH NOTES.** Ben played the Phase 3 build 3553392 with
   the keypad and a controller: no crash or hang; movement, damage, drowning and breaking the environment work; spells
   and interaction missing is expected (Phase 4). His two notes become wave **4.2F** of the Phase 4 plan (planned first,
   per the chip rule): **TX** — text is hard to read (the App's CoreText rasterizer thresholds coverage at half; Mac OS 9
   smoothed screen text — keep the coverage and blend it into the palette); **SP** — the game runs very fast (the timing
   code was built to the binary, so measure the port against the Let's Play first, then fix only a measured cause).
2. **Apple system fonts may ship** — supersedes the font part of D23 (Ben: "I didn't make that rule. happy to override
   it."). For Ferazel: smooth today's Times/Geneva first (TX); only if it still looks off against the Let's Play, source
   the classic fonts (Ben's Mac OS 9 setup, or github.com/pjobson/Apple-Fonts) and bundle them. Release scripts that
   assert "no fonts bundled" change only when a font actually ships.

**As built — wave 4.2F (loop run 22, 2026-10-25):** TX cdcb8b8 + 480d46e — text smoothed as Mac OS 9 drew it (coverage
blended into the palette; 14 pt threshold read from the Let's Play: conversation text smoothed, status-bar and item-count
text crisp) → Ferazel/Core **396/0**, no golden moved; SP — measured, no change: the port runs at the binary's cap (30
steps/s, `.GameLoop` M l. 5229–5292); the LP shows ~25 steps/s during play (SheepShaver CPU-bound; its text reveal runs
at the true 30 characters/s) → Ben's call, QUESTIONS Q9. Ladder from EF on +3 more (Phase 4 end **487**).

**Addendum — Q9 (Ben, 2026-10-26; recorded by loop run 25):** game speed **(a) keep the original's top speed, for now.**
Ben's attended session measured the running app on his Mac (a screen recording of level-1 play): a steady 30 new frames a
second, never more — the port matches the binary's cap. Ben: "huh. let's keep it for now." No code change; he may revisit
(b) (a hidden slower cap) later.

## D40 — Ben's Q5 + Q7 answers: a system Quit during a level asks at once; Phase 4 defaults stand (2026-10-26; recorded by loop run 26)

**Decided (Ben, QUESTIONS Q5 and Q7, answered in his attended session 2026-10-26):**
1. **Q5 — quitting from the Dock / app menu / logout during a level.** Ben: "quit from dock should always behave … or it
   can trigger the game quit dialogue." Build: a Dock or app-menu Quit while a level runs shows the game's own "Are you
   sure you want to quit?" box at once, exactly as ⌘Q does in a level (OK quits, Cancel plays on); a logout, restart or
   shutdown quits at once from anywhere without a dialog, so macOS never reports "cancelled logout". Everywhere else the
   original's queued quit event is unchanged. **A deliberate departure from the original's wait — Ben's call** (it
   overrides D35 as built run 16 for this one case; not a precedent for other affordances). Planned by loop run 26 as
   task **QT** (wave 4.6Q of the Phase 4 plan, +3 tests; every later total +3, ladder end 490).
2. **Q7 — the Phase 4 plan's three choices: the defaults stand.** Ben: "levels don't care. spells yes. item counts yes."
   Levels 3–4 open in Phase 4 with enemies still until Phase 5; the later-level spells and items are built and tested now;
   item counts are drawn in Geneva by the Mac's font engine. No change to the plan.


**As built (loop run 27, 2026-10-26) — task QT:** `GameFlow.systemQuit()` → `LevelRun.systemQuit()` → a session flag
(`FerazelSession.requestSystemQuit`) taken at the session's next `.CheckGameLoopKeys`, where ⌘Q's `.confirmQuit` is
raised (no ⌘ key faked). A level counts as free when it plays with no suspension, keys modal, save, conversation,
upgrade or pause up; a Quit during the level's opening (stage load, chapter card, fades — seat ruling after review, so
"Allow background tasks" cannot drop it) is held and asked once play starts; a level that ends before asking queues the
old quit event; a second request while one is pending or the confirm is up adds nothing. A logout/restart/shutdown
(`kAEQuitReason`) returns `.terminateNow` from anywhere; `.Quit` writes no prefs (M l. 7447–7482), so nothing runs first.
Carry [LOW]: a level that fails to load while a request is held loses the quit.

## D41 — Ben's Q10 answer: a Windows build straight after Phase 4, then Windows kept in lockstep (2026-10-26; recorded by loop run 27)

**Decided (Ben, QUESTIONS Q10, written and answered by his attended session 2026-10-26):** (a) after Phase 4's end run
(stage + gate card), the loop plans and builds Ferazel's Windows twin as its own short phase **before the Phase 5 plan**,
on the BTX W-plan shape (D15–D21, `tools/windows/`, HectorSDL), staged as a zip under `out/` — **stage only, never
publish** (D34 holds: no releases or uploads without Ben; he hands it to his tester). Then, Ben: "Then we do a windows
build in lockstep with the Mac build." From then on every task that changes what the Mac app shows or does carries its
Windows side in the same task, and every phase end stages both builds (Mac app + Windows zip) with one gate card; the
Phase 5+ plans are written that way. This moves the design §8 Phase 7 Windows work forward; Phase 7 keeps only what is
left.

## D42 — Ben's Q12 ruling: the loop launches a build only muted, and never at night (2026-10-26; recorded by loop run 31)

**Decided (Ben, QUESTIONS Q12, written, answered and twice amended by his attended session 2026-10-26, after the Phase 4
end run's G9 boot checks opened the staged app with sound at ~22:00 and woke his household):** (1) first ruling: no
launches by the loop at all. (2) **Amended minutes later ("Muted launches is fine to test"):** launching a build IS
allowed for boot checks, but **only with the game's sound fully off**. Before any launch the loop adds, and tests
headlessly, a **mute switch** (a launch argument or environment variable that stops the app opening any audio output on
the Mac; for the Windows build in CrossOver a no-sound audio driver passed through the `HECTOR_SDL_*` passthrough, since
CrossOver strips `SDL_*`) and uses it on every launch. **No muted switch → no launch.** Launches few and short.
(3) **Night rule (Ben, 22:10):** **no launches of any kind, muted or not, between 21:00 and 09:00 Mac local time** —
check `date` right before any launch; a run that reaches a launch step in those hours skips it, stages only, and writes
"boot check owed (night rule)" in its LOOP-LOG line and the gate card; the first daytime run does it, muted.
**Supersedes the launch half of D34 (3)** and every earlier G9 / boot step; staging (copying a build to `out/` or
`~/Desktop`) stays allowed at any hour; headless tests that make no sound and open no window (`swift test`, the census,
`xcodebuild build`, cross-compiling) are fine at any hour. Seat's reading (run 31): a CrossOver run of a cross-built
test executable (Proof B) counts as a launch — it runs muted (no-sound driver) and only in daytime hours.
**Approved by:** Ben, 2026-10-26.

## D43 — Ferazel's Wand "Phase W" (the Windows twin): planning rulings (2026-10-26, loop run 31)

**Plan:** `docs/plans/2026-10-26-ferazel-windows.md` (contracts, not code; Opus planner; two Opus review legs — A against
BTX's Windows code + `tools/windows/`, B against Ferazel's App + design + rulings — both PASS WITH FIXES, round applied
with Ben's amended Q12; FABLE-GRADE gate PASS WITH FIXES (re-ran G2 490/0 and GW1, seven findings), round applied).
Seven tasks + phase end: **WF0** Core + tests cross-compile, Proof B script; **WF1 ⚑** the shared shell half
(`Ferazel/Shared`, symlinked into a new `Ferazel/Windows` package) + the Mac mute switch; **WF2** text from BTX's baked
format, baked from the Mac's own CoreText path, byte-compared; **WF3 ⚑** the game on HectorSDL + the Windows mute
switch; **WF5** saved games (native Windows dialogs); **WF4a** / **WF4b ⚑** the original's dialogs drawn in-window;
**WF6** stage both + phase end. Ladder: Ferazel/Core stays **490**; the Windows package's macOS-hosted tests 0 → **77**;
Proof B 490/0/0/0 in CrossOver. No HectorKit change (G1 35a85ba, floor 361). Execution: run 32 = WF0 + WF1, 33 = WF2 +
WF3, 34 = WF5 + WF4a + WF4b, 35 = WF6 phase end, then the Phase 5 plan.
**Rulings (the plan's "Rulings" section is the full text; one line each):** (1) one neutral driver shared by symlink,
the Mac keeps only AppKit work; (2) text = BTX's baked format + rasterizer, baked from `CoreTextRasterizer` (made
public), 0/255 cut after composing, byte-for-byte tests; dialog face = font 0 face 1; (3) saved games = native Windows
Open/Save dialogs (WQ2); (4) the original's dialogs drawn in-window, scaled with the game (WQ7); (5) no menu bar, MBAR
commands by Ctrl alone, keys from the MENU resources; (6) keys Ctrl = ⌘, Alt = ⌥ (D18.5); (7) gamepad through
`ShellPadTranslator` + `FerazelPadLayout`; (8) clock = SDL nanoseconds → 60 Hz ticks, the 2-tick step and the 30-step cap
unchanged; (9) the window's close / Alt+F4 = the Mac's Dock Quit (D40), logoff quits at once; (10) prefs + saves in
`%APPDATA%\Ambrosia Classics\Ferazel's Wand\`; (11) hidden switches on the command line with the Mac's parse; (12) data
folder beside the exe = `Resources/Ferazel/` unchanged; (13) audio through `PCMMixer` + `SDLAudioOut`; (14) 640×480
window, whole-number scale, Alt+Enter full screen (WQ3/WQ4); (15) launches per D42 (muted, 09–20 only, guard in
every launch script); (16) **lockstep (D41) standing contract for Phase 5+**: every task that changes what the Mac app
shows or does carries its Windows side in the same task; every task (Core-only too) runs G2 + GW1 + GW2 + GW3 + G5;
every phase end stages both builds with one gate card; (17) no HectorKit change; (18) the Foundation-on-Windows and
GUI-subsystem traps (no `replacingOccurrences`, no stderr/`NSLog` in the GUI build, live redraw during drag); (19) a
dedicated `WIN_BUILD_ROOT` for every Ferazel cross-build; (20) mute + determinism: `-FerazelMute YES` / `FERAZEL_MUTE=1`
(Mac: no `ShellMixer`, no beeps) and `--mute` (Windows: SDL dummy audio, no `MessageBeep`); headless `--frames` dumps
open no audio device, drain the Sound Tool silently at 367/368 frames per tick, and fix the seed and clock.
**Owner choices** (QUESTIONS Q13, non-blocking, defaults = (a)): WQ2 save dialogs, WQ3 full-screen key, WQ4 resizable
window, WQ5 key names, WQ6 save-file extension, WQ7 dialog scaling.
**Approved by:** the seat under D34's plan authority; Ben reads later (Q13).
**As built — WF0 + WF1 (loop run 32, 2026-10-26/27; main 59047f4):** Core + its tests cross-build for Windows (GW1 0/2);
`tools/windows/proof-b-ferazel.sh` written and guard-checked, **Proof B not yet run (night rule — owed to the first
daytime run)**. `Ferazel/Shared/FerazelDriver.swift` + `FerazelAudio.swift` carry the neutral shell half (Mac behaviour
unchanged — two legs read it as a move, symbol diff clean); `-FerazelMute YES` / `FERAZEL_MUTE=1` built (no
`ShellMixer`, no beeps); the driver's `headless` option (Ruling 20's frames mode) always uses the silent mixer, muted or
not. Measured and recorded: UserDefaults' argument domain reads "2abc" as **0** (not 2 as Ruling 11's text guessed),
"y"/"t" false, a value starting with "-" is a new key; boot → main menu 360 ticks FNV `0xae2b1ee08c089b2a`, New Game →
level 1 first frame 107 ticks FNV `0xc99ce8e85b4bd8f7` (stub text; WF2 re-measures with real glyphs). `Ferazel/Windows`
package: FerazelWinKit 17/0.
**As built — WF2 (loop run 33, 2026-10-27; main b992809):** Windows text = five baked faces (`Ferazel/Windows/Resources/Fonts/*.fzfont`:
Times 12 bold, Geneva 9, Geneva 8 bold, Times 18, and the dialog face font 0 face 1 12 pt, baked early for WF4a), equal
byte for byte to the Mac's `CoreTextRasterizer` on every character, the level names, score strings over the full 32-bit
range, every item count, the level-1 route and the sign route; the 0/255 cut after composition. **No whole-string
fallback was needed (◇W8 unused).** WF1's two pinned frames draw no text (their FNVs stand unchanged); **WF3's text
reference = the first presented frame with text, 414 ticks after level 1's first frame (N held), RGBA FNV
`0x908483fb603623e8`** (baked = CoreText; the surface first carries text at +46, indices `0xf1a8b25e2094a097`). Ligatures
longer than two characters are not modelled (no shipped game string has one; WF4a tests its dialog strings as a closed
set). FerazelWinKit 27/0.
**As built — WF3 (loop run 33, 2026-10-27):** `FerazelWin` = the game on HectorSDL (Rulings 5–14, 18–20), Windows-only
logic in FerazelWinKit (`WinGame`, input, Ctrl-alone shortcuts from the MENU key equivalents, pad, files, args with the
Mac's measured parse, start-up, key scripts, stub dialogs/file panels), `Ferazel/Shared/FerazelMenuRules.swift` (the
Mac's menu rules moved, behaviour identical — symbol diff clean); cross-builds and links for Windows (GW3 0/1),
FerazelWinKit **46/0**. Rulings refined as built: the launch line reports SDL's real drivers, so headless runs print
`audio=none` (HectorSDL starts audio only with an output) — GW4R expects `video=dummy audio=none`; `-FerazelMute YES`
also forces the dummy driver on Windows; held Ctrl shortcuts repeat like AppKit's ⌘ equivalents; **Windows logoff:** SDL
3.4.16 hands `WM_QUERYENDSESSION`/`WM_ENDSESSION` to Windows' default handling (read from the DLL) — no event, no
confirm, the process ends, nothing lost (◇W11); new **◇W14** (shortcut letters by US key position). **GW4R and Proof B
owed by day (night rule).**
**As built — WF5 (loop run 34, 2026-10-27; a11e39b + 034a283):** the native Open / Save dialogs (comdlg32
`GetSaveFileNameW` / `GetOpenFileNameW` in `FerazelWin/WinFileDialogs.swift`, linked through `import WinSDK` — the exe
imports COMDLG32.dll; compiled and linked, never run: launch rule) over a one-method `WinFilePanels.run(request) -> URL?`;
the testable half `WinFileRequests` (title = prompt, Windows-legal default name — reserved names also with an extension,
"nul.txt" → "nul_.txt", DEL counts as a control character — Save's folder created first, Open's used only when it exists).
Seat-accepted refinements: the Save dialog's name field is pre-filled with the **full path** `<saves folder>\<name>` so it
always opens in the saves folder (Windows 7+ may otherwise prefer the last-used folder); the Open dialog keeps
`lpstrInitialDir` only and may open in the last-used folder (◇, no workaround); after a dialog the held keys, the mouse
button and held pad buttons are cleared; `--save-as FILE` / `--open FILE` answer the panels on the Mac SDL build only;
`--frames` runs always cancel. FerazelWinKit **54/0**.
**As built — WF4a (loop run 34, 2026-10-27; a21dc30 + 38239c0):** DLOG 202 / 200 drawn in-window (adapted
`DialogRenderer` / `DialogWindow` / `DialogSystem`), text in the baked dialog face. **Seat ruling (dump-checked by the
review leg): Esc does nothing on DLOG 202** — the original calls `ModalDialog(nil)` with no filter and no cancel item, so
only Return / Enter answer (the plan's "Esc → Cancel" was wrong; the Mac transcription `FerazelCarbonDialog.swift:298–306`
agrees); the pad's Esc reaches it and likewise does nothing. **◇W13 not kept:** the bake equals the Mac's `ClassicFont` pick
on this machine (`.AppleSystemUIFont`; widths 0.0 px apart over 45 lines and 32,773 code strings; every line
byte-identical to CoreText — the closed-set test). New stand-in noted under ◇W10: the dialog text below 14 pt is cut to two
levels like the game's text, where the Mac app's separate dialog windows draw it smoothed (arguably nearer Mac OS 9).
Keys pressed while a button is held down are dropped (the Mac would queue them); no drop shadow (classic frames had none);
a right-click outside does not beep (HectorSDL passes left clicks only). `--frames` runs draw the real dialogs (a scripted
Return answers); the reference FNVs did not move. FerazelWinKit **65/0**.
**As built — WF0b (loop run 34, 2026-10-27; dc52e5e + 1d75574) — Proof B, first daytime run:** Wine (CrossOver) lacks
`ADVAPI32.SaferiIsExecutableFileType` (Foundation's `attributesOfItem` / `isExecutableFile` / `Process.run`), which
aborted the suite after 3 tests. File sizes now come from a `FileHandle` on Windows; `CensusTests` searches in pure Swift
on Windows (`String.contains` traps on the long non-ASCII census text); **skip rule (exact): `CensusTests.testExitCodes`
skips under Wine only** — Proof B's bar is now **489 passed / 0 failed / 1 skipped / 0 crashed (of 490)** (measured, ~4 min
40 s), the script accepting only that named skip; on a real PC the test runs. GW4R measured the same morning: identical.
**As built — WF4b (loop run 34, 2026-10-27; 689c551 + f8b36d0 + b62f1a8):** Options (6900) and Credits (600) drawn in-window over
the flow's own models (`WinPrefsDialog`, `WinCreditsDialog`, popup / checkbox / key-capture items). Seat rulings ("follow
the binary", dump-checked): the Options filter is the original's (Esc / Ctrl+. → Cancel, Return / Enter → OK at once on
the Game Options and Sound panels; captured as bindings on Controls); Cancel restores only the system volume; Credits read
the live button each 3-tick check (no click latch); key fields hit-test their exact rect; no null events while a popup is
open or a control is held (b62f1a8). New ◇ notes: the open popup menu is a drawn classic stand-in; **Alt+Return cannot be bound** (it is Windows'
full-screen key). Mac carries [LOW]: the Mac key field's 4 px click outset; the original's null-event pause while a
button is held (Windows models it; the Mac app does not). FerazelWinKit **77/0** — the Phase W ladder's top.

**As built — WF6 + Phase W END (loop run 35, 2026-10-27; cd32864 + 08c30f3 + 5481d97 + 4387e2b + 589a900):** `tools/windows/stage-ferazel-win.sh` (zsh; fixed folders `$WIN_CROSS/{work,build}/stage-ferazel`, Ruling 19; GUI subsystem — llvm-objdump prints `00000002`; manifest + icon + version info; 19 DLLs by the import walk; `Data\` = the original data + `Fonts`; WHAT-TO-EXPECT.txt BOM + CRLF; MANIFEST.txt; zip ≈ 92 MB, 60 files) and the CrossOver half of `tools/windows/smoke-ferazel-win.sh` (three headless muted runs of the staged exe in a clean bottle, each `cmp`-ed with the Mac SDL build's dump, whose FNV is checked against the recorded one: A menu 1,437 wakes `0xae2b1ee08c089b2a`, B level 1's first frame 1,865 `0xc99ce8e85b4bd8f7`, **C level 1 text at full brightness, step 959, 3,833 wakes `0xfbb2dd7a1d289726`** — the Fable phase leg found step 881's first text frame is nearly black; every run log must say `video=dummy audio=none` and carry no `BakedTextRasterizer:` line; the smoke refuses a zip not stamped with HEAD). Seat ruling: exact frame counts (4 × (T − 1) + 1) instead of the plan's 4 × (ticks + 60) margin, so each reference FNV is checked too. Gate card `Ferazel/WINDOWS-WHAT-TO-EXPECT.md` (→ QUESTIONS Q14, for Ben and Andrew; asks for a real save + restore — the Windows Open/Save code has never run). **Launch gates by day, muted:** G9M clean; Proof B **489/0/1/0** (4 min 48 s); GW6 three "identical" lines. Reviews: one Opus leg PASS WITH FIXES, FABLE-GRADE phase leg PASS WITH FIXES (re-ran G2 490/0, GW2 77/0, GW6; the Mac app's diff is a move plus the gated mixer/beeper) → one round, seat-read. **Phase W is machine-closed:** Ferazel/Core 490/0, FerazelWinKit 77/0, census 1,108/0, HK 35a85ba untouched (Ruling 17). From here every task carries its Windows side (lockstep, Ruling 16).

## D44 — Ferazel's Wand Phase 5 "Enemies": planning rulings (2026-10-30, loop run 36)

Plan `docs/plans/2026-10-30-ferazel-phase5.md` (Opus planner 8b4e63a; two Opus review legs ACCEPT_WITH_FIXES, 27 findings →
fix round 1dfffd0; FABLE-GRADE leg ACCEPT_WITH_FIXES, 9 findings → fix round 1911e48; the seat checked the one partly
rejected finding against the dump: `.KillWarrior` sets the screen shake `_DAT_1009ffa0 = 30`, not the music track). Seat
rulings under D34's plan authority; Ben reads them later (QUESTIONS Q16). The plan's "Rulings" section is the full text:

1. **Scope:** design §8 row 5 in full — every non-boss enemy class (placed on levels 1–5 or not), the EnemyShot class,
   pipes, geysers (§9 (b)), damage both ways, the burn-away, enemy Effects; plus the underwater tint and the Magical
   Shield crouch face (Phase 2/4 carries), Ben's Q15 follow-ups (wave 5.0, its default (a); item 5 = the random-play bot),
   gap-ledger #3 (follow the binary). Out: bosses' Handles/Hits/Kills, level features first used on levels ≥ 10, `.Victory`.
2. **"Through the first boss door" = levels 1–4 with every enemy alive, plus level 5 up to the Warrior's arena**
   (`BuiltLevels` → 1...5 at task LV5; the moving backdrop OmniPx modes 2/4/5 built first, task OX).
3. **The Warrior is a stand-in:** Setup transcribed in full (RNG draws, write-backs, layer before the insert), Handle
   only stands, contact damage as read, no Hit/Kill, its three falling-crate children not spawned (Phase 6). 3a: it stays
   a Ring-of-Smiting target (faithful list; can reach HP < 1 with no Kill — harmless, gate stays shut, Esc leaves).
4. **Draw refusals stay quits;** every phase end runs the visit sweep, the random-play bot and the load-every-face tests
   on both shells plus the draw-mode audit — **a phase cannot close while any fails** (Ben's Q15 (5)).
5. **Test bars with opt-in skips:** G2 = ladder total, 0 failed, skipped exactly the named opt-in tests
   (`VisitSweepTests.testVisitEveryObject`; + the bot's at RB); GW2 the same with the Windows names; Proof B =
   `(N − 1 − k) passed / 0 / (1 + k) skipped / 0 crashed (of N)` (task PB fixes the script: today it fails on the sweep's
   skip, and it must unset `FERAZEL_VISIT_SWEEP` / `FERAZEL_BOT*`).
6. Gap #4 (16-voice eviction) a recorded deviation; the QuickDraw shrink rule a QUESTIONS item (needs a capture); the
   dark-level lit-sprite over-read (light table runs into the ambient table) built from the binary (task DK).
7. No HectorKit change (35a85ba, floor 361). Lockstep (Phase W Ruling 16) verbatim in the preamble.
8. **Ladder:** Ferazel/Core 502 (501 + 1 opt-in skip) → **617**; FerazelWinKit 79 (78 + 1 opt-in skip) → **81**; 22 tasks +
   phase end A5, 13 ⚑, ten runs (run 37 = PB → SP → RV).

**As built — loop run 37 (2026-10-30), wave 5.0 part 1 [PB SP RV], merged 0b02d31.** (a) **Ladder +1:** Ben's attended
commit 3cf72df (world-map status bar matched into clut 700) added one Core test mid-run, so every later Core total is one
higher than the plan's table: PB 503, SP 506, RV **509**, DK 511, UT 514, DA 516, RB 518 … LV5/A5 **618**; Proof B at
the phase end **615 / 0 / 3 / 0 (of 618)**. FerazelWinKit 79 → **80** (PB), RB → 81 unchanged. (b) **PB** (09cccce +
three fix rounds 7a6fadc, 56883b7, 3bf6882): the opt-in skip list; `unset -m 'FERAZEL_BOT_*' || true` (zsh returns 1
when nothing matches — under `set -e` the script died silently; the seat caught it, the leg had exported the vars);
the `--frames` loop is one public `WinGame.runFrames(_:scripted:)` shared by `FerazelWin/main.swift` and
`WinReferenceFramesTests` (leg finding); the first real Proof B then showed two Wine gaps in Ben's 2026-10-29 tests that
had never run under CrossOver — **a `@MainActor` XCTestCase crashes swift-corelibs-xctest's test listing** (VisitSweepTests
now nonisolated, body via `MainActor.assumeIsolated`; every FerazelWinKit test class is `@MainActor` too — harmless while
they run only macOS-hosted), and **`FileManager.enumerator` / `NSRegularExpression` find nothing under Wine**
(BootFacesTests' source scan is pure Swift on every platform; same 20 PICTs on the Mac). Proof B measured by the seat:
500/0/2/0 of 502 at PB, **507/0/2/0 of 509** at RV; GW4R menu identical. Seat ruling: a test that runs under Proof B must
avoid Foundation's enumerator, regex and file-attribute calls and must not be actor-isolated. (c) **SP** (7be824a): the
mode-5 walk takes the renderer's own scroll and drawn pair (`DiffuseRandomsAt`, the session tracks the last scroll op
it emitted); **the plan's Q15-item-1 drift was not happening at 6a70bce** — every sprite pass follows a grid redraw at the
camera; the leg confirmed by forcing the old walk (both real routes still agree). The change is a guarantee, not a
visible fix; the drawn pair cannot change the random count (the cull offsets both rects) [LOW]; scroll ops made outside
the session (Pause, SaveGame, LevelRun's start redraw) are untracked, safe today [LOW]. (d) **RV** (0b02d31): the
empty-inventory box reads G+0x1a / G+0x22 / G+0x1c as `.UpdateItemStat` does (a count is drawn only when > 1; seam
field `StatusBarState.gapSlot`, filled in `GameGlobals.statusBar` — every shell path); computed face ids (key icons
3201–3226, held items 750/756/768/771) checked loaded; the plan's boulder `0x6e1 + p1` is not in the code yet (its task
adds a range row); 3,257 hot-rect/emitter rows identical before and after the boot faces (12 hash pins; the leg
re-derived them from `b535527^`); BC51 corrected (the squash row counter starts at 0, raw 10027328). Carried [LOW]: the
face scan misses variable ids and ternary literals (covered by the class sheet lists today); hash pins cannot name the
changed row; the pin renderer uses ruled/lowest colour settings.

**Seat ruling — loop run 38 (2026-10-30): how Q15 item 7 is carried** (Ben's 13:01 addition with 3cf72df; his Q15 is
unanswered, so its default (a) holds). (1) The `StatusBar.swift` header comment ("black / white are 255 / 0 under 200
and 700 alike" — black is index 96 in clut 200 under the lowest tie-break) and the `MapRenderTests` reference that is
rebuilt with the fix's own model are **folded into DA** as a comment fix + asserts inside DA's or the existing map test
functions (independent pins of a few clut-700 indices) — **ladder unchanged**, scope fence of DA widened to those two
files. (2) The map text smoothing / flash colours in clut 700 (latent: map text is pure black/white) needs a capture of
the original — stays with Ben (Q15 item 7, beside Q16 (3)); no task. (3) The screen-vs-Let's-Play comparison check is
an idea for Ben to rule (Q15); not planned.

**As built — loop run 38 (2026-10-30), wave 5.0 part 2 [DK UT DA].** Ladder (+1 vs the plan, as run 37): DK **511**,
UT **514**, DA **516**; FerazelWinKit 80 unchanged; Proof B **514 / 0 / 2 / 0 (of 516)** at 78f9231 (seat, by day); GW4R
menu identical at c49bbd4; census 1,108/0. (a) **DK** (e65087c, one leg PASS): mode 0xc reads past the light table into
the ambient table that follows it in the data section (light 0x100a0134 → data+0x5c52c, 0x6e000 bytes; ambient
0x100a0130 → data+0xca52c), ambient row `(index − 0x6e000) >> 8`; ≥ 0x6f000 stays a refusal. **F max over the built
levels = 110** (`.GetFakeLight` intensity 0…11 — the bank said 10; every live colour writer ≤ 99, incl. a 0x58 writer at
M l. 52562 the bank lacked; the only level-data colour read, M l. 54143, is the dead 0x726 path) — bank ⚑ note appended.
(b) **UT ◈** (c49bbd4 + fix round e573236, one leg PASS WITH FIXES): the underwater tint as row 41 has it, through the
existing `.fadeToColor` ops; the flag is a `.ClearPlayerVars` global (reset on every player setup). **No golden moved** —
legitimately: `+0x11c` is the head's height above the surface (1 = submerged/clamp, 2…9 = head 2–9 px out), the swim
golden's route only wades (69), no golden route enters the band (the leg's probe: zero hits over all 124 render tests),
and the goldens hash pixels + sounds while the frame renderer drops gamma ops. The plan's "swim golden moves" was wrong;
the commit says "no golden moved (recorded)". Windows references not moved. (c) **DA** (991f924 + fix rounds fe2d9d9,
78f9231; leg PASS WITH FIXES, then a re-review leg): `DrawModeAuditTests` — 99 throws in 47 rows, each with a code-checked
reason; no refusal reachable in levels 1–4; ~120 s of the suite. **The seat's Proof B found the audit crashing the whole
Windows test process** (86 tests lost): on Windows `String.contains(String)` resolves to Foundation's, which traps
(illegal instruction) under Wine — symbolized with the toolchain's `llvm-symbolizer` on the test exe, proved by a
`--class` re-run in a scratch copy; the audit now searches and trims in plain Swift. **Seat ruling (extends run 37's):
a test that Proof B runs must also avoid Foundation's string search and trim (`contains(String)`, `range(of:)`,
`components(separatedBy:)`, `trimmingCharacters`, CharacterSet).** The review found the first audit's Setup draws culled before the mode read (placement
coordinates) — the re-review leg showed its table probes did read the mode, so the check was weak, not empty — round 2 draws on
screen with a drawn-not-culled check, checks the writer table against the cited source lines, adds clip/face rows, the
floe/raft and orb/rotation arguments and the ripple increment/reset in code, a whitespace-tolerant writer scan, and the
FerazelCore throws a level frame can propagate. Q15 item 7 carried as ruled above (StatusBar comment verified correct by
the leg from the clut data; map pins independent). Carried [LOW]: `try!` at `PlayerStates.swift:291` would crash rather
than refuse on a refused bonus type; the orb argument checks gravity writers inside Shots/ only; the gap ledger still
names the tint unbuilt at l. 38 and its l. 170 count; aborting a level while tinted leaves the tint until the next fade
(probably the original's too); the tint's on-screen strength unchecked by eye (MED); the audit's `try!` check accepts any
`try!` (the four sites are fixed-type, unreachable, prose only); the water-row probes have no water-free control; the
audit takes ~125 s, not "fast". Re-review leg PASS (nine mutations, all caught).

**As built — loop run 39 (2026-10-30/31, by night), RB ⚑ + EC ⚑.** Ladder (+1 vs the plan): RB **518** / 2 opt-in skips,
EC **526** / 2; FerazelWinKit **81** / 2 skips; census 1,108/0; no golden moved; **Proof B owed (night rule)** — expected
523 / 0 / 3 / 0 (of 526), run 40 runs it first by day. (a) **RB** (f5fb48e + 34290ad + fe7b20c; two Opus legs
MERGEABLE / MERGEABLE WITH FIXES, fix round, re-review MERGEABLE): `tools/ferazel-random-play.sh both` — 4 levels × 4
seeds × 3 min per path, 86,400 steps, 0 failures, identical counts on the Core and Windows paths; every failure kind
injected and caught on both. **Seat rulings:** after the first level end → map → re-enter, later level ends start a
fresh New Game at the level (level 3 starts ~156 px from an exit; re-entry resumes there); the runner fails on a
failed / missing run, has a watchdog, clears only its own files; **Ben's 8f7746f memory limits (after his Mac ran out
of RAM under the visit sweep) copied into the bot's runner** (4 workers, 6 max, `-j 4`, 30 %-free wait). (b) **EC**
(8180742 + a2d1fa9; two Opus legs both MERGEABLE WITH FIXES, fix round, re-review MERGEABLE): the S2 handler cases
(named no-ops), `EnemyCounting` (the window; the run-29 `+0x1b5` carry fixed; level-1 total 0xf unchanged), the Kill
idiom, contact damage rows keyed on the handler cases (dormant until each class task), goblin voices, the enemy statue
wrapper, hazards and liquids, `Burn` from `.StandardSpriteCleanup`, Smite at the stored centre over the enemy Handles.
**Both legs caught the implementer's Gremlin reading backwards** (`.KillGremlinSprite` returns when `+0xe9 ≠ 0`,
M l. 69736–69738) and the burn's Kill on a held slot copy (landmine (o)) — fixed; 38 surviving mutations now fail.
BC52: enemies drop only 0x50d / 0x50c / 0x516. The Ring of Smiting hits nothing on levels 1–4 until each class task maps
its handler (plan-mandated). Carried [LOW]: Dillo coin count asserted as a range; the bot reaches a save once per 16 runs.

**As built — loop run 40 (2026-10-31, 02:22 → day), ES ⚑ + WK1 ⚑◈.** Ladder (+1 vs the plan): ES **537** / 2 opt-in
skips, WK1 **546** / 2; FerazelWinKit **81** / 2 skips; census 1,108/0 (wave 5.1 end). (a) **ES** (067d570 + 8bc8cf7; two
Opus legs MERGEABLE, tests-and-as-read fix round seat-read): `World/Enemies/EnemyShot.swift` — every §1.2 type (boss
arms built as read), the step-7 enemy-shot rows, `.ShieldBlock` (enemy shots only; the dart / spine reflection, the
Wraith shot reflected once with the Magical Shield), the Magical Shield crouch face, boulder spouts fire on level 4,
orbs / Buttons vs enemy shots, the dart traps 0x76c…0x76f built as read (first placed on level 22). **Dump over plan:**
cannons never capture an enemy shot (M l. 63684); Wraith homing 19 frames not 20; the Warrior shot mirrors when vx > 0
(bank §1.2 corrected); spout speed draws only with a record, layer 9. Seat ruling in advance applied to
`ButtonGateTests`' spout row (the shot Setup's draws enter the stream; count +1 per firing). 0x46a ×3 / 0x77b in
`CachedFaces` (`.InitEnemyShotSprite`; marked only by Phase 6's bosses). (b) **WK1** (0efe8e2 + b8d56c5; two Opus legs
MERGEABLE, tests-and-faces fix round seat-read): `World/Enemies/Walker.swift` — Setup by tier, the 1700 thrower and
1705 spear guard, hits / knockback, death, coins (`.PopupGoblinCoins`, each drop's Handle run at once, M l. 57498),
score, the corpse raft under the Platform Handle keeping the Walker's callbacks; `forClass` → `.walker` (1750 / 1760 arms
`// later: WK2`); Walker sheets loaded as the original's level cache (`CachedFaces.handleSets` +
`sheets(markedBy:)`, M l. 56757–56763). **◈ — one golden moved:** Phase 2 level-2 iteration-2 frame
`df22325e851e782d` → `b310ef334de49c00` (the 1705 at record 12 wakes and settles); every level-1 golden stays — **no
Walker is awake on any level-1 golden route** (leg 1 logged all 1,037 steps; the plan's "every level-1/2 golden moves"
was wrong); Windows references unchanged; BootFaces hot-rect FNVs, four continue write-backs and two crunch light counts
moved for the same cause; switch-off check done by the implementer and independently by leg 1 — every old value
returns. Stub-pinning retargets (seat ruling in advance): BonusSprite 0x6a4 row, the cannoned walker → `.walker`,
level-4 record 119 → `.walker`. **Launch gates by day (09:00, after the merge, muted):** Proof B **543 / 0 / 3 / 0 (of 546)** at b8d56c5 — the run-39 owed check is closed too; GW4R main menu identical.

**As built — loop run 41 (2026-10-31, 09:09 → day), CR ⚑◈ + WK2 ⚑◈ (wave 5.2 end).** Ladder (+1 vs the plan): CR
**554** / 2 opt-in skips, WK2 **560** / 2; FerazelWinKit **81** / 2 skips (unchanged). (a) **CR** (a0b0401 + fix round
7c2b880; two Opus legs MERGEABLE / MERGEABLE WITH FIXES, tests-only fix round seat-read): `World/Enemies/CrawlerRoach.swift`
— both Setups (the Roach's `+0x154 = x`, speed 0x4b0 — the run-29 carry), both Handles (the Crawler's ceiling, drop,
wind-up and leap with the live `+0xa6` cooldown from 3, the shared hop-flee, death), both Hits (shot arm, Statue, crush
`+0x150 = 0x16`, Smite / geyser hazards as read), both Kills (`+0xea`; Crawler 500, Roach 600), the tile callback;
`forClass` → `.crawler` / `.roach`; the player shot's Crawler arm. **Dump over plan / bank** (enemies-ground
Corrections #10): no Kill proc stored at `+0x50` by either Setup (`EnemyCommon.killProc`'s Crawler / Roach arm is
unreachable, left as EC built it); the Roach's death has no × 0.97 friction; the stale r29 in both Hit routines is the
shot itself; neither class stores `+0x188…+0x18b`. **◈:** only the two level-1 routes on which a Crawler wakes moved —
swim `[67, 321]` / `c1dd428a3f146d77` → `[67, 322]` / `3e99f74fa10e87e2`; 600-frame `a8dda9cf3e448016` / 3114 /
`28a48762cfff1b2b` / seed 1574122804 / 156 → `0cce4b0446e2a48e` / 3160 / `1b06b8a4117cf9dc` / 1361095401 / 150
(Crawler records 39 and 9; **no Roach wakes on any golden route, nothing on level 2's** — the plan's "level 1 and 2
goldens move" was wrong, as WK1's); BootFaces hot-rect FNVs, two continue write-backs and the crunch Roach positions
moved for the same cause; Windows references unchanged; switch-off check by the implementer and independently by leg 1
— every old value returns. (b) **WK2** (2627d80 + fix round 891811e; two Opus legs MERGEABLE / MERGEABLE WITH FIXES,
tests-only fix round seat-read): `World/Enemies/AxGoblin.swift` (`.AxGoblinCoreLogic`) and the 1750 / 1760 arms of
`Walker.swift` (no `// later: WK2` left), the 1750 Setup (was still `notTranscribed`), 1750's cache rows (the dump's
0x6d6…0x6df, not the plan's "1750–1754"). **Dump over bank** (Corrections #11): any chasing call clears the flee
lockout; a second R(20) and the jump cry's own R(4000); no draw during the blink. **◈ — no golden moved** (neither type
wakes on any golden route; level 1's 1760, record 73, wakes only in non-golden tests, state 5); switch-off check by the
implementer and leg 1. Leg 2's mutation tables (CR 174 mutants / ~21 real survivors; WK2 271 / 22) drove the two
tests-only rounds; the implementers' own "≤ 9 survivors" counts were overstated both times.

**As built — attended run 43 (2026-11-07, Fable seat, D45), BA ⚑◈ finished (the remainder plan's RC + BAf).** Ladder: BA
**569** / 2 opt-in skips (441 rules + 128 render; the seat's whole-suite number at the cherry-picked head e605eb0 and at
the fix round 60d92f7). Run 42's Bat class (005058f) cherry-picked, its fix round run as asserts inside the nine tests, the
`ProgrammedPath` pair moved to `World/Movers/ProgrammedPath.swift` with the mode-10/11 Handle body and the 1xx-form flag
(**the flag zeroes the swing speed, not the radius** — the audit's ruling 3 corrected from the dump; plan "As executed"
under BA has the lines). Re-review MERGEABLE (26/26 mutants killed; switch-off by stubbing the Handle returns the two L3
BootFaces values). ◈ none moved. The draw-mode audit's line-anchored rows for `Bat.swift` re-anchored (+1…+5 lines).

**As built — attended run 43 (2026-11-07, Fable seat, D45), FR ⚑◈ (Frogs and Salamanders).** Ladder: FR **577** / 2 opt-in
skips (449 rules + 128 render; the seat's whole-suite number at the fix-round head 8fa5ca2). `World/Enemies/FrogSalamander.swift`
(both classes; the session's Handle/hit dispatch in `FerazelSession.swift`; `killProc` routes the two classes to their own
Kills), 8 tests. Two Opus legs: leg 1 found **the Frog's launch aim following the bank instead of the binary** — the
original compares the player's **x** (the playerX global, raw 100824bc through TOC slot −0x7aac) with the frog's centre y −
0x28, while its idle state reads player y (slot −0x7ab0): a quirk of the original, ported as written (bank
enemies-water-cave §1.3 corrected ⚑); leg 2's mutation table: 87 mutants, 24 real survivors. Fix round (8fa5ca2): the aim
fix with a failing assert first, two asserts re-derived from the dump (the far scenario's "above" branch; landing gravity
0x5a per M l. 70400, 400 only on a solid-floor hit M l. 70622–70624), all 24 pinned, the `freezing` → `inLiquid` rename.
Re-review MERGEABLE (25/25 mutants killed; the "16 px lower" worry did not reproduce — a test comment's wrong threshold,
corrected by the seat). Write-back flags: `+0xea` in the two Kills only (M l. 70575, 70934); neither class writes
`+0x188…+0x18b`. **◈ none moved** — no Frog Handle runs on a golden route (the level-2 Frogs start idled); Windows
references untouched. Carried [LOW]: a headless session has no face pixels, so the burn — and every Frog/Salamander death —
never ends there (EC's burn rule; shells pass the renderer); the Salamander's stale register on `.KillPlayerShot` is nil
(unverified); two bank omissions noted in "As executed" (`+0x46 = 0` at M l. 70839; the spit restart M l. 70771/70784).

**As built — attended run 44 (2026-11-07, Fable seat, D45.7 chain), BL ⚑ (Blobs and Crabs; the Multi Crystal's Blob
exception; audit deltas 4 + 20) — wave 5.3 END.** Ladder: BL **584** / 2 opt-in skips (456 rules + 128 render; the seat's
whole-suite number at the fix-round head 71b1431, rules re-run at a515415). `World/Enemies/BlobCrab.swift` (both classes;
the session's Handle/hit dispatch; the Crab's 0x762 set and 0x767 link face in the level-load cache), 7 tests. Two Opus
legs: leg 1 MERGEABLE (no departure from the binary; independent switch-off check held), leg 2 MERGEABLE WITH FIXES (282
mutants, 253 killed, 17 real gaps) → tests-only fix round 71b1431 + the re-review's one row a515415 (the strike's y
truncation pinned at angle 50, since the binary's table stores sin 70° as exactly 0.94). **Seat ruling — a moved pin:**
`BootFacesTests` level 3 f30 / f120 moved because the level-3 Blob (rec 15) now runs one Handle at level start then idles
— the class turning on, the switch-off check held twice (implementer, leg 1), run 42's Bat precedent; no golden moved
(probe), Windows references unchanged. Audit 4 landed: `killProc` has no Crawler / Roach / Bat / Blob arm (default `+0xe9
= 1`), the Frog / Salamander arms kept; audit 20's five cites fixed; bank: enemy-shots §3.6 (a reflected dart ends with
`+0xe9 = 1`), enemies-water-cave §4 (links on layer 8). Dump over plan: the Blob has no Smite "0x4b7 arm" — Smiting seeds
hit as player shots; types 0x768–0x76b take the claw Handle. Wave 5.3 end gates: G3 1,108/0; GE core levels 1–4 (visit
sweep 3,360 visits 0 rows; bot 86,400 steps 0 failures); GWB **581 / 0 / 3 / 0 of 584** (16:3x, muted); GW4R main menu
identical. Carried [LOW]: see the plan's "As executed" (five leg-1 minors).

**As built — attended run 44 (2026-11-07, Fable seat), GF ⚑ (Gremlins — body, back layer, rider — and Wraiths; wave 5.4
start).** Ladder: GF **591** / 2 opt-in skips (463 rules + 128 render; the seat's whole-suite number at the fix-round head
b6afbc6). `World/Enemies/GremlinFloater.swift`, 7 tests. Two Opus legs: leg 1 MERGEABLE (every field, random draw and
phase as the binary; the rider-shot prediction d 22 → dir 4 / `+0x1aa` 0xdc / `+0x17e` 1, d 32 → 14 / 0x140 / 0 matched),
leg 2 MERGEABLE WITH FIXES (324 mutants, 276 killed, 33 real gaps) → tests-only fix round b6afbc6 (30 pinned; re-review
MERGEABLE). **Seat rulings:** (1) path modes 10/11 are admitted for the Gremlin — `.SetupProgrammedPath` filters nothing
(M l. 39302–39378), `ProgrammedPath.makeRadial` gets its first caller (audit ruling 3 closed); (2) the unplaced Wraith
variant 0x6fe–0x707 is refused at Setup (no sheets 1790/1791 in the data; `FastRand(0)` in its Handle) — a named ◇, not a
port gap, revisited only if a later level census places it. Not ◈ (first placed on levels 15 / 62): no golden moved.
Bank §7.7 corrections as the plan's "As executed" lists. Carried [LOW]: the Floater aim's `P.y + 8` at a direction boundary
and the slope-grounded rider's halving (both test gaps with a known setup), the early return after `.KillPlayerShot` (Bat
pattern), `pef.py`'s default path, the stale "refused" comment in `ProgrammedPath.swift`.

**As built — attended run 45 (2026-11-07, Fable seat, D45.7 chain), DL (the Dillo) and GY ⚑ (geysers; wave 5.4
continues).** Ladder: DL **596** (8fd9fe8; one Opus leg MERGEABLE WITH FIXES — 67 mutants, 64 killed, 3 real gaps → 2 pinned
by 8431831, the jump's `+0xce = 0` indistinguishable), GY **603** / 2 opt-in skips (475 rules + 128 render; the seat's
whole-suite number at the fix-round head 4639d9a; two Opus legs MERGEABLE WITH FIXES — leg 1 every routine as the binary,
leg 2 305 mutants / 250 killed / 21 equivalent / 34 real gaps → all pinned by 4639d9a; re-review on a clean copy).
`World/Enemies/Dillo.swift` (5 tests), `World/Movers/Geyser.swift` (7 tests). **Seat rulings:** (1) the unplaced Dillo
types 1872–1879 (HP 0, max HP 0) are refused at Setup — the original always dies on frame 1 but a `FastRand(10)` timer of
0 or 1 divides by max HP 0 first (raw 10086a48, undefined) — a named ◇, the Wraith-variant precedent; (2) §9 (b) NR 2–4
land as settled (no Setup re-run on reactivation, the `+0x9c` block reused, kinds 3/4 draw no base face, p4 inert, no
sound); (3) the geyser head sorts at layer 2 and only the segments hurt enemies — the bank's "layer 11" and "base or
segment" were wrong (`geysers.md` run-45 corrections 1, 3), `EnemyCommon.environmentalHazard` unchanged; (4) a Ruling-16
guard that skips a null-pointer write (missing head / segment / child record, a zero period) stays silent — none is reachable
from the 27 shipped placements. Neither task is ◈ (the Dillo is placed on levels 15 / 22, geysers on 10 / 50 / 51): no golden
or BootFaces value moved; the quick bot does not apply. Bank corrections: `enemies-ground.md` item 12, `geysers.md` run-45
corrections. Carried [LOW]: the Dillo's stale `KillPlayerShot` register (nil), the crush's ground side pinned only through
the Crawler tests; the geyser segment's session row indistinguishable from the old no-op (empty handler, correct as read),
the stale-head comment in `Geyser.swift`; the re-review (305 mutants on a clean copy: 285 killed, 20 survivors all equivalent — leg 2's
table was not contaminated) confirmed the clip-row cite as 59844–59850 (fixed in the docs-close commit).

**As built — attended run 46 (2026-11-08, Fable seat, D45.7 chain), PI (the enemy pipes) and PT (the renderer's traps into
the refusal census; wave 5.4 CLOSED).** Ladder: PI **607** (43b2842 + tests-only fix round cab8d5c; one Opus leg MERGEABLE WITH
FIXES — 42 mutants, 28 killed, 4 equivalent, 10 real gaps → all 10 pinned), PT **607** (178788f (abf08f9 in the pt-lane clone), asserts only; one Opus leg
MERGEABLE). `World/Movers/BoxSprite.swift` pipe arm + `generate` grew Walker and Blob arms (4 tests, `EnemyPipeTests`).
**Dump over card/bank (PI):** `.SetupBoxSprite` spawns a first child and kills it at once (M l. 59347–59353; ported as the
Setup's field stores only, the throwaway spawn deferred to level 21's spawn code); the release does NOT clear the pipe's child
link `+0x1d4` — it clears only when the child dies (`+0xe9`/`+0xea`, M l. 60758–60767), so a pipe waits for its child to die
before the next; `+0x150` is 2 after the spawn frame (the step runs in the same frame); the child keeps its own Setup's layer
(Walker 4, Blob 8), not pipe + 1; cue 459 at step 3. **PT:** 18 trap sites (17 `precondition(` + 1 `preconditionFailure()`
`SpriteBlitter.swift:486`); 7 became refusals (water table w ≥ 6, status-bar PICT size, parallax face slot, light-pass darkness
×2, light-table index, overlay face), 11 stay traps with census rows "unreachable from any data" (the census now scans traps as
well as throws); `LevelRun` refuses a level whose header has OmniPx mode ∉ {0, 2, 4, 5} or a horizon strip (`0x2716` ≠ 0),
caught by GameFlow as "level could not be loaded" (asserted in `GameFlowGameTests.testNewGameStartsLevel1`). **Wave 5.4 end
gates:** G2 607 = 479 + 128, 0 failed, 2 opt-in skips by name; G3 1,108/0; GE core levels 1–4 visit sweep 3,360/0, bot
86,400/0; GWB Proof B **604/0/3/0 of 607** (10:00, muted); GW4R main menu identical; GW1 0/2, GW3 0/1, GW4 ok, GW2 81/0/2,
G5 ok, greps empty, G1 ef2c341/370. **Method rulings (Ben, 2026-11-08, in chat):** (1) STATE.md and NEXT.md hold only the
current state / current run; history moves out at every close; (2) the re-plan must be one self-contained plan file, not
pointers at the October plan + the audit (the repair session owns this and the chip rebuild); (3) the seat hands a leg the
card + a line RANGE, never pre-reads source (fable-kit orchestrator.md §3 corrected, c5f706d); (4) the superpowers skill line
in the chip was for the planning session only — drop it; (5) the visit sweep + bot run after level tasks and at phase ends,
not every wave end; (6) run 47 is NOT chained by this session (Ben's word; the repair session starts it).

## D45 — Cythera re-planning pass: Ben's five answers + the seat's rulings (2026-11-05)

**Context.** Phase 0 half built (K1, C0–C5, 44 tests) and stalled since 2026-10-07; nothing planned beyond it. Fable
5.1 in the seat ran `~/Developer/Toolkits/fable-kit/replan.md` (the lighter case): review, spec
`docs/superpowers/specs/2026-11-05-cythera-remainder-design.md`, plan `docs/superpowers/plans/2026-11-05-cythera-remainder.md`,
audit `docs/superpowers/audits/2026-11-05-cythera-phase0-audit.md` (two Opus 5.5 reviewers, 15 rulings, 0 redo).
Nothing built. Seat's own runs: Cythera/Core 44/0/0 on HectorKit main ef2c341; HectorKit gate PASS 370 at ef2c341 and
322 at the pin 4ca2e18 (with `HECTORKIT_DATA_AKI11` overridden — the script's default Aki path is stale).

**Decided (Ben, 2026-11-05, "Accept all five"):**
1. **HectorKit re-base:** Cythera's pin moves 4ca2e18 → **ef2c341 (floor 370)**; from now on a later clean HectorKit
   main is accepted at ≥ the recorded floor and the new SHA/floor is recorded at the merge (the Ferazel rule of
   2026-11-04). C12 records the pin.
2. **Text:** glyph sheets **baked once on the Mac** from the shipped `sfnt`/`NFNT` and the system fonts at exactly the
   requested sizes and styles (TxSt), committed as data beside the port with a census test; the anti-aliased path
   read in R1; the 1999 screenshots judge. Rejected: an own TrueType/NFNT rasteriser.
3. **Next wave's shape:** three Opus 5.5 orchestrator sessions — A: C8 → C9; B: C6 ∥ C7 ∥ C10; C: C13 → C11 → C12 —
   each one implementer + one reviewer per task, two legs per ⚑; Fable only on a contraindication, after asking Ben.
4. **D28 ruling 2 wording:** "Alaric walks" → **"the player walks"** (Alaric is character 2, the ruler; the player is
   character 1, default name Bellerophon). Nothing else in D28 changes.
5. **The first gate is split:** **1a** the still picture, side by side with the Catamarca screenshot; **1b** the player
   walks Catamarca, roofs lift. Each its own gate card.

**Seat's rulings (under the 100 % rule; spec §5, audit rulings 1–15):** one state model = what the save holds, all
else derived (spec §3); one instruction walker shared by the C8 decoder and the Phase 2 VM; the VM proven by decoder
parity, headless shape runs and the bank's worked examples as goldens (spec §7); the ladder re-cut for the C8-first
order: C8 50 → C9 57 → C6 63 → C7 71 → C10 80 → C13 86 → C11 91; new minor task **C13** (the overlay becomes a
`SegmentStore` with a decrypted read, a store-based map initialiser, the carried minors, comments, two pinning
tests); C9 extends `scriptSegment` so the combat-AI band 0x0410–0x0436 is returned as stored; compo tiles are built
from frame 0's tile table (faithful; Phase 1 passes the table); the four differing `clut 256` entries are named on
the 1a gate card; the Phase 0 plan's "Fable reviewers" legend is superseded by the all-Opus policy.
**Approved by:** Ben (1–5, 2026-11-05); the seat's rulings shown to him in the same message.

## D45 — Deimos Rising re-planning pass: Ben's answers and the seat's rulings (2026-11-05)

**Decided (Ben, in chat, 2026-11-05, answering the re-planning pass's six questions — spec
`docs/superpowers/specs/2026-11-05-deimos-remainder-design.md` §10; seat Claude Fable 5.1 per `replan.md`):**
1. **Merge `deimos-phase2` after the audit's fix round, before C12** (Q-A): the audit (five Opus reviewers,
   `docs/superpowers/audits/2026-11-05-deimos-phase2-audit.md`) discharges the three review legs wave 2.6 owed; once its
   23 "change" rows land, the whole branch is reviewed work and is merged to local main (Task 2.2 of the plan).
2. **HectorKit: current main from now on** (Q-B); the pin e595472 was only K2's landing commit. Measured 2026-11-05: the
   branch suite is 313/0/0 against both; kit zero-skip 370 executed at ef2c341 (4 Aki 1.1 census skips are a machine
   data-path matter, not Deimos's).
3. **`Deimos/Core` is live; `Deimos/DeimosCore` is its symlink** (Q-C); no action.
4. **Phase order: 3 campaign → 4 front end → 5 Windows** (Q-D; design Q7 answered): the de02–de04 films prove the campaign
   by machine.
5. **A game controller for Deimos in Phase 4** (Q-E), with the controls window, as the original's keys (D36/D37 shape).
6. **Reviews stay Opus-only** (Q-F, his 7 Oct rule restated); the seat for the next wave is his call on the pass's
   recommendation — **Ben, 2026-11-05: "I am generally happy with fable orchestrators and opus agents" → Fable 5.1
   holds the seat for both waves 2a and 2b; every implementer and reviewer leg is Opus 5.5.**
**Seat rulings under the 100 % rule (spec §7):** the audit discharges the owed legs; bank corrections are applied in
the next wave as a docs task (Task 2.3), not at the end of the phase (changes D31.11); the next wave is fenced to
waves 2a (fix round, merge, bank corrections) and 2b (C12, C18a). **Audit outcome:** every re-derived rule matches the
oracle; 0 redo, 23 change, 12 missing (seams written into the C12/C18a/H2 briefs); two shipped units (`bocr`, `tatr`)
draw to terrain every tick, so C12 builds the +0x36 draw path and the +0x90 stamp-time field; no cyclic state has a
max speed below 1.
**Approved by:** Ben (1–5 "yes", 6 Fable seat + Opus agents, 2026-11-05); seat rulings shown to him in the same message.

## D45 — Ferazel's Wand re-planning pass: Ben's answers and the seat's rulings (2026-11-07)

**Decided (Ben, in chat, 2026-11-07, answering the re-planning pass's five questions — spec
`docs/superpowers/specs/2026-11-04-ferazel-remainder-design.md` §6; seat Claude Fable 5.1 per `replan.md` §5; the
pass itself landed 2026-11-04 at f07e2f8 with nothing built):**
1. **The three queued gates (Q-A):** Q11 Phase 4 (spells + items, levels 1–4) — **pass on what he could test**: "spells
   seemed to work (fireball is all I had)"; no notes, no fix wave. Q14 Windows — **pass on Andrew's word** ("AJ told me
   Windows was working"; Andrew had already saved, restored and played level 1 → map → level 2 on a real PC,
   2026-10-29/30). Q16 Phase 5's five defaults — **not read yet; the defaults stand** (1a, 2a, 5a; 3 and 4 when
   convenient), as D34 allows; Q16 stays open for his later read.
2. **HectorKit: Ferazel follows HectorKit main from now on (Q-B a).** The pin 35a85ba is retired; each run records the
   kit SHA and zero-skip floor at reconcile, and "no HectorKit change" means "by a Ferazel task". Measured at this
   reconcile (2026-11-07): HectorKit main **ef2c341**, tree clean, `tools/check-zero-skip.sh` **370 executed = 366
   passed + 4 skipped / 0 failed** (floor 370). The 4 skips are the Aki 1.1 census tests: the Aki 1.1.0 app is no
   longer at the kit's default path on this Mac and the repo's `Resources/Aki/1.1.0.app` symlink points at that same
   missing folder — a machine data-path matter, not Ferazel's (the Deimos pass recorded the identical result on
   2026-11-05). Accepted as the recorded floor; restoring the Aki 1.1 copy is a note for Ben (QUESTIONS Q17).
3. **The Bat class is resumed, not rebuilt (Q-C a):** run 42's 005058f cherry-picked onto run 43's branch; the fix
   round, re-review and merge are plan task BAf.
4. **Phase 6 is three gated phases (Q-D a):** 6A levels 10–22 + the Goblin Chief; 6B levels 25–52 + the Wizard; 6C
   levels 55–70 + the Fire Guardians, Xichra, victory — each ends in something Ben can play.
5. **Release shape (Q-E a):** one GitHub release `ferazel-1.0` with a notarized Mac DMG and a Windows zip, BTX's recipe
   (D25), copied to `releases/ferazel-1.0/` in the main checkout.
6. **Seat for the remainder (Ben, 2026-11-07, "let's resume Ferazel from the replan and fable-kit"):** Fable 5.1 holds
   the seat for wave 1 (run 43) attended, in this session, under the remainder plan
   `docs/superpowers/plans/2026-11-04-ferazel-remainder.md`; every implementer and reviewer leg is Opus 5.5
   (`fk-implementer` / `fk-reviewer`, D34). The unattended loop stays stopped (STOP file in place) until Ben says go.
**Seat rulings:** the switch-off recipe is "stub the class's Handle body" (audit ruling 1); G2 runs as two commands
with the skipped tests checked by name (rulings 11, 15); D44's ladder (+1) stands: BA 569, FR 577.
**Rejected:** pinning HectorKit through a worktree (one kit, one truth; the drift is Shell-only); rebuilding the Bat
(two review legs already passed it); one whole-game gate for Phase 6 (too long between things Ben can play).
7. **Sessions chain automatically (Ben, 2026-11-07, mid-run 43): "as long as no hard stop questions for me at the end of
   this session, happy for next session to start … auto trigger new sessions as we go as well pending hard stop questions
   for me." — and, after the seat restarted the LOOP: "I didn't say loop. I said trigger a new session."** Rule
   (CLAUDE.md "Workflow"): a session that closes a run or a wave re-seeds `docs/NEXT.md` and **starts the next attended
   session itself** (`start_session`, same seat model, fresh context, brief "read docs/NEXT.md and run it"), without
   asking. The unattended loop is NOT restarted by this rule — it stays stopped until Ben says "start the loop" (the
   loop the seat started at run 43's close was stopped a minute in, nothing landed). It leaves no new session only when
   a question only Ben can answer blocks the next step (`STATUS: BLOCKED` + a `Blocks: everything` item in QUESTIONS,
   named in the closing message). Non-blocking questions queue and never stop the chain. Run 43 applies it at its
   close: NEXT → run 44 [BL GF], the next attended session started.
**Approved by:** Ben (1 in his words, 2–5 "yes, all recommended", 6 by his resume request, 7 in his words, 2026-11-07).
