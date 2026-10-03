# Handoff — 2026-10-04 — Aki Phase 1 DONE: Ben's verdict "yes it absolutely is Aki"

**TL;DR.** Phase 1 of the Aki — Mahjong Solitaire 1.2.0 replica (splash, map, menus, level-pick dialogs,
Preferences, fullscreen, lifecycle) is built, every task reviewed MERGEABLE, machine gates green, merged to main.
Ben drove the staged app himself (lanterns, previews, Unavailable, Level Description, Preferences, fullscreen,
Help/Handbook/Release Notes) and gave the honesty-gate verdict in words. Seat: Fable 5.1; every subagent Opus 5.5.

| item | state |
|---|---|
| Branch | `claude/suspicious-tu-1af46f` merged to main this session (fast-forward push after merging origin/main); worktree + branch removed |
| Commits this session | a5cde9a tests · 690716e P1.10 · 3e76424 P1.11 · 5da2bf0 P1.9/P1.10 fix round · d9879c9 plan corrections · 261af67 P1.12 · 65e24c3 P1.13 note · merge + docs |
| Reviews | P1.9 (MAJOR, both legs) · P1.10 · P1.11 · fix round · P1.12 — all MERGEABLE; findings folded or carried (STATE "Carried") |
| Gates at the merge head | AkiCore 31 / 0 · `BUILD SUCCEEDED` · HectorKit `check-zero-skip.sh` PASS floor 167 · staged 50 PNG + Fonts/OsakaMono.ttf |
| Rulings | DECISIONS D4 (Aqua forced; Osaka-Mono bundled — Ben; menu mutations — Ben; Handbook in Preview; dialogOK rule; splashes stay soft — Ben) |
| Questions for Ben | plan S6 Q1–Q18, Q51–Q57; Q52 closed ("fine as is"); the rest open for his play notes, none blocking |

## What the session learned (for the next seat)
- `osascript`/System Events has NO assistive access on this machine; the computer-use `app_*` tools work in the
  background and capture windows; display-scope control makes Ben's screen glow and he interrupts it — he prefers
  to drive the app himself and report. `screencapture` from the shell has no Screen Recording permission.
- Reviewers booting the app concurrently collide (`pkill -x Aki`, shared defaults domain): one booter at a time.
- `review-task.md` recipe: export into `$EX/.claude/worktrees/wt` with the HectorKit symlink beside it, or the two
  relative package paths do not resolve.
- Subagents see a system attribution reminder naming their own model; the plan's invariant 16 (Fable trailer)
  must be stated as overriding it (one commit was amended).
- `request_access("Aki")` resolves to the ORIGINAL 2008 app in the archive mirror (`com.ambrosiasw.aki`); pass the
  bundle id `com.ambrosiaclassics.aki`.
- AkiCore's `GameSettingsStore` tests leak `aki-settings-test-*` plists (25 cleaned by hand) — fix before P2.1.

## Ben's own observations while driving (2026-10-04)
Lanterns, previews + sound, Unavailable, Level Description, Preferences, fullscreen toggle, Help guide, Handbook
(PDF opens), Release Notes all work. He asked about Option-click on a locked lantern (it is the binary's hidden
skip; guide shows first while level 2 is locked — Q14/Q51) and about the picker "not working" after he had turned
descriptions off (Known delta 3 + Q5). He wants the replica's own Release Notes text at the very end.

## Next session (Phase 2 chip)
Fable or Opus seat (say which). Invoke `superpowers:subagent-driven-development`. Read: CLAUDE.md; docs/STATE.md;
THIS handoff; DECISIONS D3–D4; the plan's header + S1–S6 + P2.1–P2.12; `docs/aki/rules.md`. Recreate the
`Resources/Aki/*` + `.claude/worktrees/HectorKit` symlinks (plan Task 0). First: the test-hygiene fix; then P2.1 →
P2.12 per the plan's execution order, with the two shared briefs re-created from this session's conventions.
HectorKit needs (STATE "for Ben's HectorKit session") go to Ben, never to a Classics agent.
