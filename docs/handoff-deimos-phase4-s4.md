# Handoff — Deimos Rising Phase 4, section S4: settings file, high scores, name entry (closed 2026-11-20)

Seat: Claude Opus 5.5 (the plan's seat tag). Helpers: Opus 5.5 (`fk-implementer`, `fk-reviewer`), foreground. Section
S4 of `docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. With S2 also closed, **S3a may start**
(it needs S2 and S4).

## What a player would notice
Nothing yet. The pieces exist but nothing calls them: the menu (S2) and starting-and-returning from a game (S3a) wire
them in. When they do, the game reads and writes its settings file exactly as the original did, shows the original's
high-score table, and asks for names the original's way, quirks included.

## What landed

| Commit | What |
|---|---|
| `180fe0d` | PF: the settings-file codec (`Core/Game/PrefsFile.swift`) and the folder-based store (`Host/PrefsStore.swift`); 7 tests |
| `0d29a14` | PF fix round: an unreadable existing file is never replaced; saves in order; the name cuts and the key guard pinned |
| `bb2ea03` | HS: the table (`Core/Game/HighScoreTable.swift`), name entry, the scores screen; 7 tests |
| `8af3cc9` | HS fix round: the erase question moved to the menu; keys queued behind player 1's entry reach player 2; guards; pinned edges |
| `6178512` | HS fix round 2: the Backspace cursor test made real; `player2Slot` checked when set; one doc comment |

Each task had one implementer and two review legs (spec, then quality); the HS fix round had a third check of its own.

## Gates, measured by the seat at the merge head (main had moved only with Ferazel work, merged in)

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **406 / 0 / 0** (392 + 14) |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 |
| G5 Deimos Debug and Release | both `** BUILD SUCCEEDED **` (Aki, BubbleTroubleX not built: no `project.yml` or kit change) |
| G3 census, G7 layering, G10 clean tree | empty diff; prints nothing; clean |
| G6 scope | S4's files, plus a four-line removal in `FrontEndSkeletonTests.swift` (below) |
| G1, G8 | not run (no kit change; G8 runs at S1b, S5, S8b only) |

**G2 base after S4 alone: 406.** S2 adds its own; whoever merges second measures the sum.

## The seat's ruling (for the gate-4 card)

**The "erase high scores?" question is asked by the menu, not by the scores screen.** The plan's S4 card put it in the
scores screen; the original asks it in the menu's SCORES action (`docs/deimos/front-end.md` §2 row 4: Option held, mouse
path only → suspend, ask, Erase → defaults routine, resume; then the SCORES action's present and fade; then the
screen), and S1b's frozen doc says the same. With the question inside the screen the menu could not keep that order.
S4 provides the pieces; **the menu (S2, or S3a if S2 closed without it) runs the ask:**
- `HighScoreTable.eraseQuestion(_ assets:)` → the `ShellQuestion` built from `inte` 24–27 (the frame's question has one
  message field, so the title and message are joined by a line break; first button "Erase").
- `HighScoreTable.erase(_ prefs:, answer:)` → on Erase, the default table and both player names reset to "Player %i";
  Cancel leaves the prefs alone. `HighScoreTable.erase(_:)` is the bare defaults routine.
The Coordinator was told; a note for S2/S3a is in the session group's shared notes folder.

## Hooks added for later sections (stored properties, as the frozen rules allow)

- **`NameEntry.player2Slot`** (S3a): set it on player 1's `NameEntry` when both players made the table. Player 2's entry
  then runs inside the same screen and receives the keys queued behind the one that ended player 1's — the original
  calls name entry twice back to back and never flushes the event queue in between. Checked when set (a table row,
  never player 1's row: the insertion always separates them).
- **Insertion** for S3a: `HighScoreTable` (the original's `FUN_100214c0`).
- **The settings store** for S8a: `PrefsStore` is given a folder; the app chooses the real one (ruling 6).

## How it was built (what the next reader needs)

- **Settings file.** The 0x34f0-byte record is kept as a raw image, so bytes the replica does not read survive. Names
  and scores are scrambled as the original; names are decoded before the version test (`PrefsFile.decodedImage` pins
  the order, since nothing in the output can show it). Missing or wrong-version file → fresh record, written at once.
  **A short file with the right version is accepted; the rest reads as zeros** — in the OS X build the block sits in
  zero-filled memory (pointer slot 100e4844 → 100fdbf4, next symbol at 101010e4, exactly 0x34f0 on), and the read's
  arithmetic still runs on those zeros, so missing scores read as −0x24A8903. An existing file that cannot be read is
  never overwritten, at load or at save (the original's open fails, then its create fails on the existing file).
- **Name entry.** Characters accepted: 0x20–0x7E and 0x80–0xFE (the original's character table, identical in both
  builds; accented letters count toward the 20 but draw at zero size). Only keys that change the name hide the cursor
  (the dump; grounding B §2c said any key). Blink 30/10 ticks; the eggs; an empty name becomes "Jar Jar Must Die".
- **The two two-player table quirks:** (a) if player 2 places above player 1 in a different row, the row just below
  player 1's first slot is lost and the next row is listed twice; (b) if both scores fall between the same two rows,
  player 1 is listed first even when lower. A tie ranks below.

## Departures and known differences (none blocks the next sections)

1. **`FrontEndSkeletonTests.swift`** (not in S4's file list): S4 removed the two stub checks for Scores and NameEntry
   (they would fail now) and left a comment line. S2 likely removes the Credits check next to it: a one-hunk conflict;
   keep both removals.
2. **`testEraseResetsPlayerNames` lives in `ScoresScreenTests`**, not `HighScoreTests`.
3. **Fresh names in memory:** after a fresh file or an erase the original holds "Mars" + 16 bytes of 0xFF + NUL; the
   replica (and the locked `DeimosPrefs.fresh`) holds "Mars" + zeros. Disk bytes match; nothing visible (those bytes
   draw at zero size, invisibly); only the draw-command list differs by 16 invisible glyphs per row in that session.
4. **The PYTHOS egg is 23 characters and overflows** into the next row ("00") and sets player 2's remembered name to
   "00" — kept. Three edges are not followed, recorded in doc comments: typed by player 1 in the last row, the
   original's overlapping copy runs away (a crash), the replica's copy is defined; on a row shift the original copies
   names with `strcpy`, so a 23-character row spills "00" into player 1's remembered name, the replica moves whole
   strings; a 23-character name reads back as 20 after a relaunch (the disk field is cut at 20).
5. **The scores screen drops keys queued after the one that leaves it** (the original leaves them for the next screen);
   the frame lets only the first chained step see queued input, so this cannot be carried across screens.
6. A failed write of the fresh record, or a save skipped for an unreadable file, is silent (the original only logged it).
7. Unencodable characters in a name are written as '?' one by one (the original had no such case).

## Worktree

`.claude/worktrees/busy-hertz-cd3018` (branch `claude/busy-hertz-cd3018`), removed at the close; it held this
section's five commits and one merge of main (all merged). Build products were in the session scratch folder.
