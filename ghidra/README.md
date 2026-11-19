# ghidra/ — the decompile bank (every game's dumps are committed)

**Where everything lives (Ben 2026-10-06, completed 2026-10-08):**
- `ghidra/<game>/` (committed, in every worktree): the binary, every text dump and its analyze log —
  `aki/` (1.2.0 `Aki12_i386` + 1.1.0 `Aki_ppc`), `btx/`, `ferazel/`, `deimos/`, `cythera/`. Read these.
- `~/Developer/Ghidra/<game>/` (not in git): the same files **plus the Ghidra projects** (`proj/`) and,
  for Deimos, the RE waves' scratch (`$W` in `docs/deimos/`, reached here via the `deimos-proj` symlink).
  Its README has the table. Run Ghidra only against that folder — never inside `.claude/worktrees/…`.
- In this checkout `proj`, `deimos-proj` and the old flat paths (`Cythera_*`, `Aki12_*`, `Deimos_*`) are
  git-ignored symlinks into `~/Developer/Ghidra/`, so older citations still resolve here.

Never leave a dump only in a worktree or a scratchpad: regenerate into `~/Developer/Ghidra/<game>/`
and copy the text dump + log into `ghidra/<game>/` (that is how the Aki 1.2, Deimos and Cythera dumps
were lost and rebuilt). Recipes: `regen-ferazel.sh`, `regen-cythera.sh`, and below. Regenerated
2026-10-08, matching the bank's recorded figures exactly: Aki 1.2 `wrote 566/842`; Deimos
`wrote 2580/2588`, 3,070,632 B (from the untouched 2026-10-03 project, `-process -noanalysis -readOnly`
on a copy).

## Tool
Ghidra 12.1.3 from Homebrew: `/opt/homebrew/Cellar/ghidra/12.1.3/libexec/support/analyzeHeadless`
(OpenJDK 26 from Homebrew). `DumpDecompile.java` is the post-script: it decompiles every function
into one annotated C file with `// ==== <name> @ <addr> ====` separators (`find_func.py` splits on
those).

## Binary forms on the hit list
| game | file | form | thin with |
|---|---|---|---|
| Aki 1.1.0 | `…/Aki 1.1.0/Aki - Mahjong Solitaire` (data fork) | Mach-O **ppc**, Carbon C++, unstripped | nothing (already thin) → EV repo `ghidra/Aki_ppc` |
| Aki 1.2.0 | `Aki 1.2 UB/Aki.app/Contents/MacOS/Aki` | Mach-O UB ppc+i386, Cocoa/ObjC | `lipo <bin> -thin i386 -output ghidra/Aki12_i386` |
| Bubble Trouble X 1.1 | `Bubble Trouble X.app/Contents/MacOS/Bubble Trouble X` | Mach-O UB, Carbon C, named symbols | `lipo … -thin i386 -output …` → EV repo `ghidra/BTX_i386` |
| Ferazel's Wand 1.0.3 | `…/files/Ferazel's Wand` | **PEF** (`Joy!peffpwpc`), CFM Carbon | copy as-is to `ghidra/Ferazel_pef` |
| Deimos Rising 1.0.6 | `…/Deimos Rising/Deimos Rising` | PEF | copy to `ghidra/Deimos_pef` |
| Cythera 1.0.4 | `…/files/Cythera` | PEF | copy to `ghidra/Cythera_pef` |

`lipo` wants `-output` (not `-o`) in this form; `file` and `xxd -l 48` confirm the form.

## Run
```sh
# Mach-O slices: loader + language are auto-detected correctly.
GHIDRA_PROJ=/path/without/dot-dirs ghidra/decompile.sh Aki12_i386
# PEF: auto-detection picks the WRONG language (PowerPC:BE:64:VLE-32addr). Force the Mac one:
GHIDRA_PROJ=… ghidra/decompile.sh Ferazel_pef -processor PowerPC:BE:32:default -cspec macosx
```
Output: `ghidra/<name>.decompiled.c` + `ghidra/analyze-<name>.log` (check for `DumpDecompile: wrote
N/M functions` and `REPORT: Import succeeded`). Functions that fail to decompile (external stubs,
mostly) get no block in the dump, so the dump's block count is the "ok" number, not the total.

Hazards: Ghidra refuses a project path with a dot-prefixed element (`.claude/worktrees/…`), hence
`GHIDRA_PROJ`; running several headless instances at once is fine (separate project names).
Parallel readers need their own project copy (Ghidra locks a project): make it under `~/Developer/Ghidra/<game>/`,
never in `~` itself, and delete the copies when the wave closes (Deimos's 31 reader copies are zipped in
`~/Developer/Ghidra/deimos/proj/project-copies-backup.zip`).

## Reading the dumps
- `python3 ghidra/find_func.py '<regex>' [--names] [--file <dump>]` — whole functions that match.
- `python3 ghidra/read_const.py <thin-mach-o> [vaddr …]` — resolve `FLOAT_`/`DOUBLE_` symbols
  (reads `__literal4/8` via `otool -l`, byte order from the magic; PPC is big-endian).
- Raw disassembly for HIGH-claim evidence: `otool -tV <thin-mach-o>` works for the i386 slices. It does
  NOT work on the Aki 1.1 PPC binary on this machine (`otool`/`objdump` refuse it: truncated symtab /
  obsolete load command) — use a Ghidra disassembly post-script (`docs/ferazel/tools/FzDisasm.java` is a
  reusable one) or a listing decoder. For PEF, likewise Ghidra post-script, or cite decompile + data bytes.

## Deimos OS X fragment (X)
The Deimos Rising 1.0.6 data fork (`deimos/Deimos_pef`) holds three PEF fragments (its `cfrg 0` lists them):
"Deimos Rising.PPC" at 0x0 (1,009,597 B, the Mac OS 9 build — **L**, the one `Deimos_pef.decompiled.c` and
`docs/deimos` describe), **"Deimos Rising.OSX" at 0xf67c0, 1,035,460 B** (the CarbonLib build Mac OS X runs —
**X**), and a "FATCarbon 1.5.1" stub at 0x1f3490. The length is both the cfrg entry's and the PEF container's
last-section end.

Regenerate from scratch, from any directory (fresh import each run, ~15 s; deletes and recreates only
`~/Developer/Ghidra/deimos/proj-osx/`):
```sh
ghidra/regen-deimos-osx.sh
```
It extracts X with `dd`, imports it with Ghidra 12.2 (`-processor PowerPC:BE:32:default -cspec macosx`; the script
pins 12.2's Homebrew Cellar path, `/opt/homebrew/Cellar/ghidra/12.2/`, and stops if it is missing), analyzes, runs
`deimos/tools/DumpSymbols.java`, `deimos/tools/DumpData.java` over the data section 100e3a10–10125484, then
`deimos/tools/DisasmRange.java` over the code section 10000000–100e3a10, writes into `~/Developer/Ghidra/deimos/`
(with the raw Ghidra log, which stays there) and copies into `deimos/`:
- `Deimos_osx_pef` — the extracted fragment;
- `Deimos_osx.disasm.txt` — the full listing, one instruction per line (`<addr>  <instruction>`, `// -- <function>`
  before each function entry). Bytes that do not decode print as `??`; data that happens to decode as a valid
  instruction prints as one, so an instruction line is not proof of code. TOC loads stay raw (`lwz rX,-0x77a0(r2)`):
  look the slot up in the data dump;
- `Deimos_osx.functions.txt` — memory blocks, the r2 (TOC) value Ghidra records (100eba10), every function
  (entry, body size, **span**, body bounds, name), the named symbols and the imports. Span is the distance to the next
  function entry (the last one: to the code section end 100e3a10). Body size undercounts functions with a switch
  table, because without the decompiler the jump table (`bctr`) is not followed — compare span as well;
- `Deimos_osx.data.txt` — the data/TOC dump: every 4-byte word of the data section as Ghidra loaded it (PEF unpacked,
  relocations applied), with its r2 slot written as the listing writes it (`-0x77a0(r2)`) for the 16,384 words
  within reach of r2, its value, what the value points at (import, function, label, transition vector, or the
  memory block) and the labels, strings and data Ghidra defined in the word; in the zero-filled part only labelled
  words are listed. So `grep -F ' -0x77a0(r2) ' deimos/Deimos_osx.data.txt` resolves a TOC load;
- `analyze-Deimos_osx.log` — the Ghidra log, sanitised (repo root → `<repo>`, home → `~`, user name → `<user>`,
  timings → `#`), so it carries no personal paths.

Homebrew Ghidra 12.2 ships **no arm64 decompiler** (`os/mac_arm_64/decompile does not exist` in the log), so X is a
listing, not C. In `docs/`, an address written "X 1xxxxxxx" means this listing; a bare `FUN_1xxxxxxx` means L.
Every committed output, the log included, is byte-identical across re-runs; the script checks the expected counts
(2,676 functions, 26,697 initialized data words) and stops loudly on any post-script error.
