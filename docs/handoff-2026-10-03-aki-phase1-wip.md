# Handoff — 2026-10-03 — Aki Phases 1–3: plan REVIEWED, Phase 1 built through P1.9 (WIP)

**TL;DR.** The Aki plan (`docs/plans/2026-10-03-aki-phases-1-3.md`, 2,475 lines, **contracts not code** — Ben's
ruling) is committed REVIEWED (Fable-grade adversarial review ACCEPT_WITH_FIXES, 25 findings, fix pass applied).
Phase 1 is built and reviewed MERGEABLE through **P1.8**; **P1.9 (menus) is committed `fb70b62` but NOT yet
reviewed** and has three open concerns (below). Branch `claude/suspicious-tu-1af46f`, pushed; **not merged to main**.
Session stopped at the usage limit. Seat: Fable 5.1; every subagent Opus 5.5.

| item | state |
|---|---|
| HectorKit | **built by the peer session** (Ben: "you build Aki, it builds HectorKit") — main `8287ddb`, HectorShell, floor **139**; no Classics agent writes there |
| Classics branch | Task 0 (D3) · P1.2 `7e875b0` · P1.3 `97182cd` · P1.4 `23ed04d` · P1.5 `0d3c56b` · P1.6 `98f914c` · P1.7 `9109802` · P1.8 `b54ef5c` — all MERGEABLE · P1.9 `fb70b62` unreviewed |
| AkiCore | 31 tests, 0 skips (with the git-ignored `Resources/Aki/*` symlinks; a fresh worktree must recreate them — plan Task 0) |
| App | `xcodegen generate && xcodebuild -scheme Aki build` → BUILD SUCCEEDED; `tools/stage-aki.sh` → `out/Aki/Aki.app` (50 PNG) |

## Open on P1.9 (rulings recorded, fixes NOT yet made)
1. **Release Notes freezes the app**: `Release Notes.rtf` names Osaka-Mono (not installed); parsing it triggers the
   macOS font-download prompt on the main thread. Fix round: load the RTF with font substitution that cannot prompt
   (e.g. strip/replace the font attribute after parsing with `NSAttributedString(rtf:documentAttributes:)` off a
   pre-sanitised copy, or set the attributed string's fonts to the system monospace) — Ben's eyes decide the look.
2. **A `FontRegistryUIAgent` font-download prompt was left open on Ben's secondary display** by the implementer's
   smoke test — Ben: cancel it.
3. **macOS mutates the built menu bar**: "Preferences…" → "Settings…" (re-set the title after `setMainMenu` — sticks);
   hidden "Close All" alternate under Close; Edit gains AutoFill / Start Dictation / Emoji & Symbols (suppress with the
   `NSDisabledDictationMenuItem` / `NSDisabledCharacterPaletteMenuItem` defaults where they exist; AutoFill: find the
   key or accept + Questions row); "Clear Current Layer" loses ⌘X to Cut (the original nib had both? → Questions row).
   The P1.9 acceptance bar ("match the nib") is therefore not yet met.
4. Implementer stubs: `toggleFullscreen` (P1.12 fills), validation cases returning false until their fields exist.

## Carried from reviews (not blockers)
- GameSettingsTests migration test should use nonzero losses[0]/giveUps[0]; AkiMapTests should pin the remaining art rects.
- **HectorKit note for Ben** (HectorKit lane owns it): `ShellSoundBank.start` on a track at its end replays from 0; QuickTime left
  `IsMovieDone` true for `_LoopMusic` — Phase-2 effect only (theme alternation in a ~0.1 s window).
- P2.12 check-step: after a proverb times out, `stopModal` from a timer may leave hover frozen until a click (faithful).
- Gate smoke: the modal welcome splash refuses AppleScript quit on first launch — `pkill -x Aki`.
- Window size 720×570 reported by CGWindowList is an artefact for never-fronted windows (real frame 800×632) — confirm visually.

## Next session (Trigger D — paste from RESUME.md once written; until then this block)
Fable or Opus seat (say which). Invoke `superpowers:subagent-driven-development`. Read: CLAUDE.md; docs/STATE.md; THIS
handoff; the plan's header + S1–S6 + the P1.9–P1.13 sections; scratch briefs are gone — re-create `impl.md`/`review-task.md`
from the plan's conventions (implementer: TDD, explicit paths, Fable trailer, never write under HectorKit, own
`-derivedDataPath`; reviewer: spec leg then quality leg, run the harness yourself). Then: (1) P1.9 review + fix round for
the four items above; (2) P1.10 → P1.11 → P1.12 serial (shared `AkiController`); (3) P1.13 gate: stage, orchestrator
drives the app with desktop tools (one Accessibility grant from Ben), `screencapture -l`, WHAT-TO-EXPECT, SendUserFile,
**STOP for Ben's verdict** "that is Aki's splash and map screen"; merge the branch to main + push only when every task is
reviewed MERGEABLE and the three machine gates pass from the merge head. Do NOT start Phase 2 before Ben's verdict.
