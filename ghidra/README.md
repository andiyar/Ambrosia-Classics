# ghidra/ — decompile recipe (everything but the scripts is git-ignored)

**Where everything lives (Ben 2026-10-06):** `~/Developer/Ghidra/<game>/` — binary, Ghidra project (`proj/`), every dump and log, for ferazel, cythera, deimos, aki, btx, ev-nova, ev-override (its README has the table). This directory keeps the scripts; `proj`, `deimos-proj` and the Cythera files here are symlinks into that folder; `ferazel/` is a committed copy of the Ferazel text dumps + binary (the exception to the rule below).

The originals are copyrighted; binaries, Ghidra projects, logs and `*.decompiled.c` dumps never
enter git. Only `*.py`, `*.java`, `*.sh` and this README are tracked.

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

## Reading the dumps
- `python3 ghidra/find_func.py '<regex>' [--names] [--file <dump>]` — whole functions that match.
- `python3 ghidra/read_const.py <thin-mach-o> [vaddr …]` — resolve `FLOAT_`/`DOUBLE_` symbols
  (reads `__literal4/8` via `otool -l`, byte order from the magic; PPC is big-endian).
- Raw disassembly for HIGH-claim evidence: `otool -tV <thin-mach-o>` works for the i386 slices. It does
  NOT work on the Aki 1.1 PPC binary on this machine (`otool`/`objdump` refuse it: truncated symtab /
  obsolete load command) — use a Ghidra disassembly post-script (`docs/ferazel/tools/FzDisasm.java` is a
  reusable one) or a listing decoder. For PEF, likewise Ghidra post-script, or cite decompile + data bytes.
