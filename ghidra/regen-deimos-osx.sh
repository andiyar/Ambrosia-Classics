#!/bin/sh
# Regenerate the Deimos Rising OS X fragment ("X") listing + symbol dump FROM SCRATCH (fresh import each run).
# The 1.0.6 app's data fork (ghidra/deimos/Deimos_pef) holds three PEF fragments (cfrg 0):
#   "Deimos Rising.PPC" @ 0x0 (1,009,597 B — the Mac OS 9 build, "L", the one the decompile dump describes),
#   "Deimos Rising.OSX" @ 0xf67c0 (1,035,460 B — the Mac OS X / CarbonLib build, "X"),
#   "FATCarbon 1.5.1" stub @ 0x1f3490.
# Homebrew Ghidra 12.2 ships no arm64 decompiler, so X is a disassembly listing + a memory/symbol dump, not C.
# Usage: ghidra/regen-deimos-osx.sh   — idempotent: deletes and recreates its own project
#   ~/Developer/Ghidra/deimos/proj-osx/ (never touches L's project ~/Developer/Ghidra/deimos/proj/).
# Outputs go to ~/Developer/Ghidra/deimos/ and are then copied into the committed ghidra/deimos/.
set -e
AH=/opt/homebrew/Cellar/ghidra/12.2/libexec/support/analyzeHeadless
ROOT=$HOME/Developer/Ghidra/deimos
PROJ=$ROOT/proj-osx
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/deimos"
T="$OUT/tools"
SRC="$OUT/Deimos_pef"            # the whole data fork (committed)
BIN=$ROOT/Deimos_osx_pef
OFF=$((0xf67c0)); LEN=1035460    # cfrg 0 entry "Deimos Rising.OSX"; also the PEF container's last section end
CODE=10000000:100e3a10           # X's code section: 0xe3a10 bytes at 0x10000000 (see the memory-block dump)

# 1. extract the fragment (both offset and length are multiples of 4)
dd if="$SRC" of="$BIN" bs=4 skip=$((OFF / 4)) count=$((LEN / 4)) 2>/dev/null
[ "$(wc -c < "$BIN" | tr -d ' ')" = "$LEN" ] || { echo "bad fragment length"; exit 1; }
[ "$(head -c 8 "$BIN")" = "Joy!peff" ] || { echo "no Joy!peff at fragment start"; exit 1; }

# 2. fresh project, import with the forced Mac language (auto-detect picks PowerPC:BE:64:VLE-32addr), analyze,
#    then dump symbols (before the listing pass, which disassembles the undefined gaps) and the full listing.
rm -rf "$PROJ"; mkdir -p "$PROJ"
set +e
$AH "$PROJ" Deimos_osx -import "$BIN" -processor PowerPC:BE:32:default -cspec macosx \
  -scriptPath "$T" \
  -postScript DumpSymbols.java "$ROOT/Deimos_osx.functions.txt" \
  -postScript DisasmRange.java "$ROOT/Deimos_osx.disasm.txt" "$CODE" \
  > "$ROOT/analyze-Deimos_osx.log" 2>&1
rc=$?
set -e
echo "analyzeHeadless rc=$rc"
grep -h 'REPORT\|DumpSymbols:' "$ROOT/analyze-Deimos_osx.log"
grep -q 'REPORT: Import succeeded' "$ROOT/analyze-Deimos_osx.log" || { echo "import failed"; exit 1; }
! grep -q 'SCRIPT ERROR' "$ROOT/analyze-Deimos_osx.log" || { echo "a post-script failed (see the log)"; exit 1; }
[ -s "$ROOT/Deimos_osx.functions.txt" ] && [ -s "$ROOT/Deimos_osx.disasm.txt" ] || { echo "missing output"; exit 1; }
grep -A12 '==== memory blocks' "$ROOT/Deimos_osx.functions.txt"

# 3. committed copy
cp -p "$BIN" "$ROOT/Deimos_osx.disasm.txt" "$ROOT/Deimos_osx.functions.txt" "$ROOT/analyze-Deimos_osx.log" "$OUT/"
wc -lc "$OUT/Deimos_osx.disasm.txt" "$OUT/Deimos_osx.functions.txt"
shasum "$OUT/Deimos_osx_pef" "$OUT/Deimos_osx.disasm.txt" "$OUT/Deimos_osx.functions.txt"
echo REGEN-DONE
