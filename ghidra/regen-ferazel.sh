#!/bin/sh
# Regenerate the three Ferazel dumps from the existing Ghidra project (no re-import).
# Usage: ghidra/regen-ferazel.sh   (project: ~/Developer/ghidra-proj/ferazel-rhodes)
set -x
AH=/opt/homebrew/Cellar/ghidra/12.1.3/libexec/support/analyzeHeadless
PROJ=$HOME/Developer/ghidra-proj/ferazel-rhodes
HERE="$(cd "$(dirname "$0")" && pwd)"
T="$HERE/../docs/ferazel/tools"
$AH "$PROJ" Ferazel_pef -process Ferazel_pef -noanalysis -readOnly \
  -scriptPath "$HERE" -postScript DumpDecompile.java "$HERE/Ferazel_pef.decompiled.c" > "$HERE/analyze-main.log" 2>&1
echo "main rc=$?"
$AH "$PROJ" Ferazel_pef -process Ferazel_pef -noanalysis \
  -scriptPath "$T" -postScript FzDecompTargets.java "$T/targets.txt" "$HERE/Ferazel_handlers.decompiled.c" > "$HERE/analyze-handlers.log" 2>&1
echo "handlers rc=$?"
$AH "$PROJ" Ferazel_pef -process Ferazel_pef -noanalysis -readOnly \
  -scriptPath "$T" -postScript FzDisasm.java "$HERE/Ferazel_pef.disasm.txt" 10000000:1009f83c > "$HERE/analyze-disasm.log" 2>&1
echo "disasm rc=$?"
wc -l "$HERE"/Ferazel_pef.decompiled.c "$HERE"/Ferazel_handlers.decompiled.c "$HERE"/Ferazel_pef.disasm.txt
grep -h 'wrote\|REPORT' "$HERE"/analyze-*.log
echo REGEN-DONE
