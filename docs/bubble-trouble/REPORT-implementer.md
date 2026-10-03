# Bubble Trouble X RE bank — implementer report (2026-10-03, Opus implementer; saved by the orchestrator)

Status: DONE_WITH_CONCERNS. Files: INDEX 147, engine-loop 187, hero-and-input 172, enemies-ai 258,
bubbles-items-scoring 213, data-formats 310, replay-oracle 146 lines. Claim counts (`cat *.md | grep -o
'\[HIGH\]' | wc -l`, same for MED/LOW; `grep -c '^- NR-' INDEX.md`): HIGH 223, MED 21, LOW 3, NOT RESOLVED 11.

Concern: five enemy functions (spawn, movement, random walk) are missing from the dump as separate
functions — Ghidra merged them into their callers; read from raw disassembly instead.

Least sure: (1) the QuickDraw `Random()` algorithm and its launch seed — exact replay depends on both and
neither is in the binary; (2) chasing enemies compare signed row/column differences, never absolute ones;
(3) enemy eggs are laid on back-to-back frames until the on-screen maximum, with no spawn delay.

Reviewer should attack first: FILM input sampling (a sample is consumed only when the hero reads input,
not once per frame — appearing/dying/pushing/trapped frames use none); replay randomness (stars and air
bubbles consume RNG and depend on two prefs, both on by default); multiplier stepping (once per squish
from the third onward within one push); big dynamite (from level 12, 5×5 minus corners).

Key findings: frame timer 0.033 s (~30.3 fps); FILM = 10,012 B (12-byte header: sample count, random
seed, unused level field; then five 2,000-byte arrays up/down/left/right/push); FILM n plays level n;
record mode exists but is unreachable; weapon functions are dead code (dynamite is a maze cell); the
sprite file's two TMPLs describe `SpIc` and `SpIL`, not `btSP`; on OS X every sprite is drawn from `cicn`
and the `btSP` path is unused; level checksums all match but nothing reads the result.

(⚑ corrected (review 2026-10-03): the orbit-stars item below is demoted to a note — orbit stars come only from the
"star burst" pause cheat, so the bug is invisible in play/demo/replay; see INDEX.)
Decisions for Ben (also in INDEX): orbit stars — the Intel build reads that table in the wrong byte order
so they are never drawn (keep the bug or show the intended orbit?); which registration state the remake
assumes (branches and RNG use depend on it); whether to expose the two prefs that change RNG use.
