# docs/cythera/tools — Cythera 1.0.4 RE tools

Run everything from the repo root. Inputs: `ghidra/Cythera_pef` (copy of `…/files/Cythera`, PEF),
`Cythera Data` (path `$G` in the banks, default in `seg.py`). Outputs go to git-ignored `ghidra/`.
Address map used everywhere: code = PEF section 0, file offset 0x3470, loaded at 0x10000000; data
section loaded at 0x100CD280; TOC r2 = 0x100D5280. Python tools are stdlib only.

| tool | purpose | run |
|---|---|---|
| `pef.py` | PEF container: section table + pattern-unpacker for the data section (imported by `toc.py`) | `python3 docs/cythera/tools/pef.py <out.bin>` (prints sections, writes the unpacked data section) |
| `toc.py` | read TOC/data words and the C strings they point to | `python3 docs/cythera/tools/toc.py 100ce90c 100ce85c` |
| `tb.py` | traceback-table parser: entry, length, mangled name of every function (incl. those Ghidra dropped) | `python3 docs/cythera/tools/tb.py > ghidra/Cythera_pef.tb.txt`; `--cxx-only`, `--at HEX`, `--grep RE`, `--missing <dump>`, `--tb` |
| `ppcdis.py` | small PPC32 BE decoder (loads/stores, branches, lis/ori/addi, compares, rotates, X/XO-form, FP); unknown words print `.long` | `python3 docs/cythera/tools/ppcdis.py 10043c58 10043ff0`; `… 100c50e8 +5`; `--func 'DoMove__14'`; `--hex` |
| `CyDecompAt.java` | Ghidra postScript: create (if needed) + decompile functions at listed addresses, r2 pinned, DumpDecompile-style separators | header recipe → `ghidra/Cythera_extra.decompiled.c` from `extra-addrs.txt` |
| `extra-addrs.txt` | the address list for `CyDecompAt.java` (functions the wave-1 banks cite as missing from the main dump) | input: `@docs/cythera/tools/extra-addrs.txt` |
| `missing-addrs.txt` | the 840 traceback-named functions absent from BOTH the main dump and `Cythera_extra.decompiled.c` (toward 100 % coverage, Ben 2026-10-04); header holds the regenerate command | `CyDecompAt.java … "$PWD/ghidra/Cythera_missing.decompiled.c" @"$PWD/docs/cythera/tools/missing-addrs.txt"` → log `CyDecompAt: wrote 840/840`; then `tb.py --missing <(cat ghidra/Cythera_pef.decompiled.c ghidra/Cythera_extra.decompiled.c ghidra/Cythera_missing.decompiled.c)` = 0 lines |
| `CyDecompBuiltins.java` | Ghidra postScript: create + decompile the 96 script-VM builtins 0xA0–0xFF from the TVector table at 0x100D7270 | header recipe → `ghidra/Cythera_builtins.decompiled.c` |
| `seg.py` | `TSegFile` reader (`Cythera Data`): TOC pages, segment table, id-keyed XOR decrypt (`toc()`, `dec()`) | `python3 docs/cythera/tools/seg.py ["$G/Cythera Data"]` (page census) |
| `lz.py` | LZ decompressor for pixel data (`unlz(bytes)`; library only) | `python3 -c "import sys; sys.path.insert(0,'docs/cythera/tools'); import lz; …"` |
| `rsrc.py` | classic Mac resource-fork parser + type census | `python3 docs/cythera/tools/rsrc.py "$G/Cythera.rsrc"` |
| `scriptdis.py` | script-bytecode disassembler + census for segment pages 0x01–0x3F | `python3 docs/cythera/tools/scriptdis.py --out ghidra/cythera-scripts --census` (`--help`) |
| `demangle.py` | Metrowerks C++ demangler over a `NAME @ ADDR` list | `grep -o '^// ==== .* @ [0-9a-f]*' ghidra/Cythera_pef.decompiled.c \| sed 's,^// ==== ,,' > names.txt; python3 docs/cythera/tools/demangle.py names.txt [counts\|full]` |
| `tileflag_census.py` | ⚑ wave 3 (2026-10-06): count tiles 0..0x9FF by 0xF002 flag mask, with the commonest 0xF004 tile names (`--eq` = all mask bits set); used by render.md §2.4/§5 | `python3 docs/cythera/tools/tileflag_census.py 0x10 0x200 0x100000 0x10000000`; `… --eq 0xc0` |
| `gen_classmap.py` | writes `engine-classmap-{1,2,3}.md` from `names.txt` via `demangle.py` | run inside `docs/cythera/tools` with `names.txt` there; **edit its hard-coded `D=` output dir** (points at the focused-darwin worktree) first |

Ghidra: 12.1.3 Homebrew `analyzeHeadless`; the project path must not contain a dot-prefixed element
(`.claude/worktrees/…`), so copy the analysed project (`/tmp/ghidra-proj-cythera`, made by
`ghidra/decompile.sh Cythera_pef -processor PowerPC:BE:32:default -cspec macosx`) somewhere else and
run the postScripts `-process Cythera_pef -noanalysis -readOnly` (see each header).
The builtins/extra/missing dumps are read with `python3 ghidra/find_func.py '<regex>' --file <dump>` (the default `--file` is Aki's dump; the header regex accepts the builtins dump's ` (name)` suffix ⚑ corrected (wave 1 2026-10-03)).

Recipes (⚑ corrected (wave 1 2026-10-03)):
```sh
python3 docs/cythera/tools/tb.py > ghidra/Cythera_pef.tb.txt              # 1,994 tables (wc -l)
python3 docs/cythera/tools/tb.py --missing ghidra/Cythera_pef.decompiled.c  # 877 entries with no
                                     # `// ==== … @ addr` block in the main dump (37 of them are in the extra dump)
cp -R /tmp/ghidra-proj-cythera "$P/proj-extra"                              # $P: a dir with no dot-prefixed element
/opt/homebrew/Cellar/ghidra/12.1.3/libexec/support/analyzeHeadless "$P/proj-extra" Cythera_pef \
  -process Cythera_pef -noanalysis -readOnly -scriptPath docs/cythera/tools \
  -postScript CyDecompAt.java "$PWD/ghidra/Cythera_extra.decompiled.c" \
  @"$PWD/docs/cythera/tools/extra-addrs.txt" > ghidra/analyze-Cythera_extra.log 2>&1
grep 'CyDecompAt: wrote' ghidra/analyze-Cythera_extra.log                  # "CyDecompAt: wrote 37/37 functions …"
grep -c '^// ==== ' ghidra/Cythera_extra.decompiled.c                      # 37
```
