# Handoff — 2026-10-03 — RE-bank lane (all five hit-list games)

**TL;DR.** Every game on Ben's final list now has a confidence-labelled reverse-engineering bank on
`main`, each built by an Opus implementer, reviewed by a Fable-grade reviewer that re-derived every
replica-bearing HIGH claim from raw disassembly or real data bytes, and fixed by a fresh Opus fix pass.
All five verdicts were ACCEPT_WITH_FIXES. Nothing is behaviour-verified: every claim is a code reading
until Ben plays the originals against the replicas.

| bank | commit | lines | HIGH / MED / LOW | open items (INDEX) | review's sharpest catch |
|---|---|---|---|---|---|
| `docs/aki/` | 3a14b37 (+ ruling 90d993a) | 1477 | 83 / 11 / 18 | 6 | wording only; 12 layouts identical in 1.1 and 1.2 confirmed by a reviewer-written PPC listing decoder |
| `docs/bubble-trouble/` | dc35b59 | 1648 | 233 / 26 / 11 | 2 | edge-clipped stars skip an RNG draw (replay hazard); dynamite double-counts a row (original quirk to reproduce) |
| `docs/cythera/` | f737747 | 3108 | 123 / 17 / 1 | 14 | two Critical: `!=`/`==` opcodes swapped, args/locals reversed; then all 95 builtin opcodes decompiled |
| `docs/deimos/` | 3bde975 | 2509 | 114 / 39 / 8 | 6 | RNG caller census wrong; float RandomRange missing; seed = srand(TickCount()) = film seed |
| `docs/ferazel/` | 01cb120 | 1950 | 204 / 76 / 13 | 11 | save flag also set at save points; sprite physics (ropes, platforms, flotation) uncovered — now §8 |

Counts are `grep -o '\[HIGH'` etc. over `docs/<game>/*.md` and `grep -c 'NOT RESOLVED\|NOT-RESOLVED'
INDEX.md` at commit 01cb120 (the INDEX count is lines mentioning the phrase, not items; each INDEX has
its own numbered list).

**Ruling recorded this session (Ben, in chat): 1.2.0 is the aim for Aki.** Every 1.1↔1.2 delta row
resolves to the 1.2 column (`docs/aki/delta-1.1-vs-1.2.md` header, `INDEX.md` headline). To be entered
in `docs/DECISIONS.md` when the Aki build session seeds that ledger.

**Scope corrections during the session (Ben via the bootstrap session):** pop-pop dropped before any
bank work started (binary + log deleted, README row removed); Maelstrom dropped from the hit list on
`main` by that session. The final list is exactly the five above.

## Tooling landed (`ghidra/`, tracked)
`README.md` (recipe + hazards), `decompile.sh` (headless launcher, `GHIDRA_PROJ`), generic `read_const.py`
(any thin Mach-O, byte order from magic), `find_func.py`. Per-bank `docs/<game>/tools/` hold the
resource-map parsers, PEF/TOC readers, Ghidra post-scripts (`FzDecompTargets.java`, `FzDisasm.java`,
`CyDecompBuiltins.java`, `DisasmFuncs.java`, `DumpMemory.java`) and format decoders the banks cite.
Dumps (git-ignored, regenerate with the README): `ghidra/Aki12_i386`, `Ferazel_pef` (+
`Ferazel_handlers`), `Deimos_pef`, `Cythera_pef` (+ `Cythera_builtins`) `.decompiled.c`; Aki 1.1 and
BTX dumps live in the EV repo's `ghidra/`.

## Ruled out / do not re-chase
- Ghidra auto-detects PEF as `PowerPC:BE:64:VLE-32addr` — wrong; force `-processor PowerPC:BE:32:default
  -cspec macosx` (the VLE dumps were discarded).
- Ghidra refuses a project path with a dot-prefixed element (`.claude/worktrees/…`) — use `GHIDRA_PROJ`.
- `otool -tV` and `objdump` refuse the Aki 1.1 PPC binary on this machine (truncated symtab); raw
  disasm for it needs a Ghidra post-script or a listing decoder (the Aki reviewer wrote one).
- Ferazel's numbered files `01`..`30` are AIFC music, not levels; levels are `Mlvl` in World Data.
- Deimos is a classic (InterfaceLib) app, not Carbon; its paks are stored-only ZIPs; `COST` is a
  translucent-rect draw type, not a cost table.
- The agent harness refuses subagent writes to files named `REPORT-*.md`; the orchestrator saved each
  implementer's report from the hand-back text.

## What remains (optional deepening; none blocks a build)
1. **Deimos** — gameplay code still unread: movement, spawn sets, weapons, damage (INDEX items; four
   heavy functions named by the review); the starting-bonus rule; what writes the alpha on/off global.
   Best done with the game running under emulation to label functions by behaviour.
2. **Cythera** — combat arithmetic lives in script bytecode (no builtin touches HP); the 12 reworded
   open items; the ~29 KB gap is now functions, so a disassembly-driven read of combat scripts is next.
3. **Ferazel** — INDEX item 14 (radial geometry, rope types 3023–3039, platform mode 4, …); glider
   physics; `.HandleBreathing`'s suspicious formula (LOW).
4. **Aki** — 6 small UI items (fullscreen branch of `showPreferences:`, grey vs black overtime stones).
5. **Bubble Trouble X** — Carbon `Random()` 0x8000 adjustment and process-start seed (documented fact,
   cite at LOW); confirm with a FILM replay once the replica exists.

## Decisions owed by Ben (listed in each INDEX)
Bubble Trouble: which registration state the remake assumes (branches + RNG use depend on it); whether to
expose the two prefs (stars, air bubbles) that change RNG use. Aki: none blocking (1.2 ruling covers all).

## Next session
The Aki build chip ("Build Aki (1.2.0 target) end to end") is queued; it waits on Phase 0 (Trigger B2)
landing HectorKit v0.1.0. The RE lane itself is complete; `docs/RESUME.md` Trigger A2 carries the
optional deepening list above.
