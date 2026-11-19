#!/bin/bash
# Regenerate the Deimos Rising OS X fragment ("X") listing, symbol dump and data/TOC dump FROM SCRATCH (fresh import each run).
# The 1.0.6 app's data fork (ghidra/deimos/Deimos_pef) holds three PEF fragments (cfrg 0):
#   "Deimos Rising.PPC" @ 0x0 (1,009,597 B — the Mac OS 9 build, "L", the one the decompile dump describes),
#   "Deimos Rising.OSX" @ 0xf67c0 (1,035,460 B — the Mac OS X / CarbonLib build, "X"),
#   "FATCarbon 1.5.1" stub @ 0x1f3490.
# Homebrew Ghidra 12.2 ships no arm64 decompiler, so X is a disassembly listing + memory/symbol/data dumps, not C.
# Usage: ghidra/regen-deimos-osx.sh   (from any cwd) — idempotent: deletes and recreates its own project
#   ~/Developer/Ghidra/deimos/proj-osx/ (never touches L's project ~/Developer/Ghidra/deimos/proj/).
# Outputs go to ~/Developer/Ghidra/deimos/ (with the raw Ghidra log) and are then copied into the committed
# ghidra/deimos/; the committed log is a sanitised copy (no timings, no personal paths) so a re-run is byte-identical.
set -euo pipefail

fail() { echo "regen-deimos-osx: FAIL: $*" >&2; exit 1; }

GHIDRA_VERSION=12.2                # pinned: Homebrew's Cellar path for this exact version
AH="/opt/homebrew/Cellar/ghidra/$GHIDRA_VERSION/libexec/support/analyzeHeadless"
ROOT="$HOME/Developer/Ghidra/deimos"
PROJ="$ROOT/proj-osx"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
OUT="$HERE/deimos"
T="$OUT/tools"
SRC="$OUT/Deimos_pef"              # the whole data fork (committed)
BIN="$ROOT/Deimos_osx_pef"
FUNCS="$ROOT/Deimos_osx.functions.txt"
DATA="$ROOT/Deimos_osx.data.txt"
DISASM="$ROOT/Deimos_osx.disasm.txt"
LOG="$ROOT/analyze-Deimos_osx.log" # raw log, kept only here
OFF=$((0xf67c0)); LEN=1035460      # cfrg 0 entry "Deimos Rising.OSX"; also the PEF container's last section end
CODE=10000000:100e3a10             # X's code section: 0xe3a10 bytes at 0x10000000 (see the memory-block dump)
DATARANGE=100e3a10:10125484        # X's data section: 0x1a124 initialized + 0x27950 zero-filled bytes
NFUNC=2676                         # functions the analysis finds
NWORDS=26697                       # initialized data words (0x1a124 / 4)

[ -x "$AH" ] || fail "Ghidra $GHIDRA_VERSION not found at $AH"
[ -f "$SRC" ] || fail "missing $SRC"
mkdir -p "$ROOT"

# 0. no stale outputs: anything copied below was written by this run
rm -f "$BIN" "$FUNCS" "$DATA" "$DISASM" "$LOG"

# 1. extract the fragment (both offset and length are multiples of 4)
dd if="$SRC" of="$BIN" bs=4 skip=$((OFF / 4)) count=$((LEN / 4)) 2>/dev/null
[ "$(wc -c < "$BIN" | tr -d ' ')" = "$LEN" ] || fail "bad fragment length"
[ "$(head -c 8 "$BIN")" = "Joy!peff" ] || fail "no Joy!peff at fragment start"

# 2. fresh project, import with the forced Mac language (auto-detect picks PowerPC:BE:64:VLE-32addr), analyze,
#    then dump symbols and data (before the listing pass, which disassembles the undefined gaps) and the full listing.
rm -rf "$PROJ"; mkdir -p "$PROJ"
rc=0
"$AH" "$PROJ" Deimos_osx -import "$BIN" -processor PowerPC:BE:32:default -cspec macosx \
  -scriptPath "$T" \
  -postScript DumpSymbols.java "$FUNCS" \
  -postScript DumpData.java "$DATA" "$DATARANGE" \
  -postScript DisasmRange.java "$DISASM" "$CODE" \
  > "$LOG" 2>&1 || rc=$?
echo "analyzeHeadless rc=$rc"
grep -h 'REPORT\|DumpSymbols:\|DumpData:\|DisasmRange:' "$LOG" || true
[ "$rc" = 0 ] || fail "analyzeHeadless exited $rc (see $LOG)"
grep -q 'REPORT: Import succeeded' "$LOG" || fail "import failed (see $LOG)"
grep -q 'REPORT: Analysis succeeded' "$LOG" || fail "analysis failed (see $LOG)"
! grep -q 'SCRIPT ERROR' "$LOG" || fail "a post-script failed (see $LOG)"
grep -q "DumpSymbols: $NFUNC functions," "$LOG" || fail "DumpSymbols did not report $NFUNC functions (see $LOG)"
grep -q "DumpData: $NWORDS initialized words," "$LOG" || fail "DumpData did not report $NWORDS words (see $LOG)"
grep -q 'DisasmRange: [0-9]* instructions,' "$LOG" || fail "DisasmRange did not finish (see $LOG)"
grep -q "^// $NFUNC functions\$" "$FUNCS" || fail "$FUNCS lacks the $NFUNC-function footer"
grep -q "^// $NWORDS initialized words" "$DATA" || fail "$DATA lacks the $NWORDS-word footer"
[ -s "$DISASM" ] || fail "missing $DISASM"
grep -A6 '==== memory blocks' "$FUNCS"

# 3. committed copy; the log is sanitised: repo root -> <repo>, $HOME -> ~, user name -> <user>,
#    JVM object ids -> <id>, every timing -> #
cp "$BIN" "$DISASM" "$FUNCS" "$DATA" "$OUT/"
perl -pe 'BEGIN { ($r, $h, $u) = splice(@ARGV, 0, 3) }
  s/\Q$r\E/<repo>/g; s/\Q$h\E/~/g; s/\b\Q$u\E\b/<user>/g;
  s/ @[0-9a-f]+ / @<id> /g;
  s/\(\d+ ms\)/(# ms)/g; s/\b\d+(\.\d+)? secs\b/# secs/g;' \
  "$REPO" "$HOME" "${USER:-$(id -un)}" < "$LOG" > "$OUT/analyze-Deimos_osx.log"
! grep -q '/Users/' "$OUT"/Deimos_osx* "$OUT/analyze-Deimos_osx.log" || fail "a committed output still carries /Users/"
wc -lc "$OUT/Deimos_osx.disasm.txt" "$OUT/Deimos_osx.functions.txt" "$OUT/Deimos_osx.data.txt"
shasum "$OUT/Deimos_osx_pef" "$OUT/Deimos_osx.disasm.txt" "$OUT/Deimos_osx.functions.txt" \
  "$OUT/Deimos_osx.data.txt" "$OUT/analyze-Deimos_osx.log"
echo REGEN-DONE
