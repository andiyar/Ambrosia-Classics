#!/bin/sh
# Regenerate the three Ferazel dumps from the existing Ghidra project (no re-import).
# Usage: ghidra/regen-ferazel.sh   (project: ~/Developer/Ghidra/ferazel/proj — Ben 2026-10-06: all decompile work lives under ~/Developer/Ghidra/<game>/)
set -x
AH=/opt/homebrew/Cellar/ghidra/12.1.3/libexec/support/analyzeHeadless
PROJ=$HOME/Developer/Ghidra/ferazel/proj
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/ferazel"   # committed copy (Ben 2026-10-06); mkdir -p "$OUT"
mkdir -p "$OUT"
T="$HERE/../docs/ferazel/tools"
$AH "$PROJ" Ferazel_pef -process Ferazel_pef -noanalysis -readOnly \
  -scriptPath "$HERE" -postScript DumpDecompile.java "$OUT/Ferazel_pef.decompiled.c" > "$OUT/analyze-main.log" 2>&1
echo "main rc=$?"
$AH "$PROJ" Ferazel_pef -process Ferazel_pef -noanalysis \
  -scriptPath "$T" -postScript FzDecompTargets.java "$T/targets.txt" "$OUT/Ferazel_handlers.decompiled.c" > "$OUT/analyze-handlers.log" 2>&1
echo "handlers rc=$?"
$AH "$PROJ" Ferazel_pef -process Ferazel_pef -noanalysis -readOnly \
  -scriptPath "$T" -postScript FzDisasm.java "$OUT/Ferazel_pef.disasm.txt" 10000000:1009f83c > "$OUT/analyze-disasm.log" 2>&1
echo "disasm rc=$?"
wc -l "$OUT"/Ferazel_pef.decompiled.c "$OUT"/Ferazel_handlers.decompiled.c "$OUT"/Ferazel_pef.disasm.txt
grep -h 'wrote\|REPORT' "$OUT"/analyze-*.log
cp -p "$OUT"/Ferazel_pef.decompiled.c "$OUT"/Ferazel_handlers.decompiled.c "$OUT"/Ferazel_pef.disasm.txt "$OUT"/analyze-*.log "$HOME/Developer/Ghidra/ferazel/"   # keep the root copy current
echo REGEN-DONE
