#!/bin/sh
# Regenerate every Cythera dump from the existing Ghidra project (no re-import), into the committed copy
# ghidra/cythera/ (Ben 2026-10-07: committed like Ferazel's, so the dumps can't be lost with a worktree),
# then refresh the working copy in ~/Developer/Ghidra/cythera/ (Ben's root decompile folder).
# Usage: ghidra/regen-cythera.sh   — expect wrote 1955/1955, 95/95, 37/37, 840/840; tb 1,994; 958 listings.
# Project made once by: GHIDRA_PROJ=~/Developer/Ghidra/cythera/proj ghidra/decompile.sh Cythera_pef \
#   -processor PowerPC:BE:32:default -cspec macosx   (with the PEF at ghidra/Cythera_pef)
set -x
AH=/opt/homebrew/Cellar/ghidra/12.1.3/libexec/support/analyzeHeadless
ROOT=$HOME/Developer/Ghidra/cythera
PROJ=$ROOT/proj
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/cythera"
T="$HERE/../docs/cythera/tools"
mkdir -p "$OUT"
$AH "$PROJ" Cythera_pef -process Cythera_pef -noanalysis -readOnly -scriptPath "$HERE" \
  -postScript DumpDecompile.java "$OUT/Cythera_pef.decompiled.c" > "$OUT/analyze-Cythera_pef.log" 2>&1
$AH "$PROJ" Cythera_pef -process Cythera_pef -noanalysis -readOnly -scriptPath "$T" \
  -postScript CyDecompBuiltins.java "$OUT/Cythera_builtins.decompiled.c" > "$OUT/analyze-Cythera_builtins.log" 2>&1
$AH "$PROJ" Cythera_pef -process Cythera_pef -noanalysis -readOnly -scriptPath "$T" \
  -postScript CyDecompAt.java "$OUT/Cythera_extra.decompiled.c" @"$T/extra-addrs.txt" > "$OUT/analyze-Cythera_extra.log" 2>&1
$AH "$PROJ" Cythera_pef -process Cythera_pef -noanalysis -readOnly -scriptPath "$T" \
  -postScript CyDecompAt.java "$OUT/Cythera_missing.decompiled.c" @"$T/missing-addrs.txt" > "$OUT/analyze-Cythera_missing.log" 2>&1
python3 "$T/tb.py" > "$OUT/Cythera_pef.tb.txt"
python3 "$T/scriptdis.py" --out "$OUT/cythera-scripts"
grep -h 'wrote' "$OUT"/analyze-Cythera_*.log
wc -l "$OUT"/*.decompiled.c "$OUT/Cythera_pef.tb.txt"
cp -p "$OUT"/*.decompiled.c "$OUT/Cythera_pef.tb.txt" "$OUT"/analyze-Cythera_*.log "$ROOT/"
rsync -a "$OUT/cythera-scripts/" "$ROOT/cythera-scripts/"
echo REGEN-DONE
