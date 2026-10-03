#!/bin/sh
# Usage: ghidra/decompile.sh <binary-basename-in-ghidra/> [loader-opts...]
# Runs Ghidra headless (Homebrew 12.1.3) on ghidra/<name>, writes ghidra/<name>.decompiled.c
# and ghidra/analyze-<name>.log. Project lives in ghidra/proj/<name>.gpr. All git-ignored.
set -e
NAME="$1"; shift
HERE="$(cd "$(dirname "$0")" && pwd)"
AH=/opt/homebrew/Cellar/ghidra/12.1.3/libexec/support/analyzeHeadless
PROJ="${GHIDRA_PROJ:-$HERE/proj}"; mkdir -p "$PROJ"
"$AH" "$PROJ" "$NAME" -import "$HERE/$NAME" -overwrite \
  -scriptPath "$HERE" -postScript DumpDecompile.java "$HERE/$NAME.decompiled.c" "$@" \
  > "$HERE/analyze-$NAME.log" 2>&1
echo "done $NAME rc=$?"
