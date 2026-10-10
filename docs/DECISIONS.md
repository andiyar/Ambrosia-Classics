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
not modelled (walker `1006740c`/`10067760`/`10067780`, every Bonus `1005e8c0`, Xichron `1005db3c/4c/60`, torch
`1005df24` [MED]); `lightFace` uses (0,0,h,w) where the binary reads the light face's +0x58 rect (l. 15179, MED-equal);
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
in the video (classic Mac 1.8 vs 2.2). **Ben: a hidden gamma toggle, off by default** (its own task, unbuilt). The 02:12 table glow is
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
