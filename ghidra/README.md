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
