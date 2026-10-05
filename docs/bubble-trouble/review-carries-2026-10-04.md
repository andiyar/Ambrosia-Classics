# BTX playable lane — review carries (2026-10-04/06). Most are DONE (merged); the ones still open are listed in the next chip.

# Carries from reviews (orchestrator) — hand to the named task
- C4/A1: prefs+scores MUST be saved at every `_LoadLevel` (C4 emits `.savePrefs`; A1 honours it) — the original's first save happens at level load before any score exists; BTXPrefsStore.save swaps in factory scores on the first-ever save (faithful first-session score loss, decompile 1178/25541/8929). Also save at quit (not ⌘Q in play).
- A4: high-score name dialog beeps at 10 typed chars unless text selected (`_HiScoreNameFilter`); storage holds 11.
- A1: K3 mixer pause semantics: original pause = stop SFX (`_ST_HaltSound(0)`) → pause music voice only → snd 22; `_SuspendGame @ 00008888` pauses music only. Use pause(voice:) not pauseAll.
- A1: ShellView.pollKeyState() once per frame (Caps Lock/modifiers); modifier keys appear in `held` by left/right codes; original tests left codes only.
- R1/A1: cicnID frame ≤0 → frame 1; frame past count indexes the flat loaded-sprite array; bad set must not crash.
- A1: CoreTextRasterizer MUST write alpha 0xFF (opaque-buffer contract; 1:1 srcCopy no longer forces alpha).
- Low (C4 re-review): an event during the very first wipe acts one frame early (orig reads events at end of iteration 1, _NewLevel 000185d4); first fade tick baseline may start one tick late. Not blocking.
- Minor (C3 re-review): deactivation during wipe/countdown swallowed when a pause carried over from the end-of-level frame is entered (GameSession afterLevelChecks deactivated=false); fresh GameState per game drops stale prevRect carried between games (only C8 cheat 0x20a59aa reaches it).
- A2 (from C8 review): App must call `frame(keys:now:)` (FPS needs ticks); read `limitFrames` (false → run frames back to back, 0.001 s timer); forward key-DOWN only (no auto-repeat) as MacRoman char + ⌘ flag to `pauseKeyTyped(_:command:)` while paused; carry `showFPS` from one session into the next (demos too). A2's "keyDown + autoKey both" applies to menus only, NOT the cheat buffer.
- A2/C7: GameSession.swift:39 wipeAdvances=(24+240)/12 duplicates DrawOp.wipeSteps — call the Core function; levelSelectChoice / FrontEndDialogAnswer public leftovers → internal.
