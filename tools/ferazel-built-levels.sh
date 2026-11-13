#!/bin/bash
# Ferazel's Wand — the built-level list (6A-BL), printed for the scripts from its one source line.
#
# Prints `BuiltLevels.list` (Ferazel/Core/Sources/FerazelCore/Front/BuiltLevels.swift) as one comma-separated line,
# e.g. `1,2,3,4,5`. It reads exactly one line of the shape
#     public static let list: [Int] = [1, 2, 3, 4, 5]
# (leading and trailing blanks allowed, nothing else on the line); `BuiltLevelsTests.testBuiltLevelsSourceLineParses`
# pins the same parse in Swift, so the scripts and the code cannot drift. The visit sweep and the random-play bot take
# their level scope from here and check FERAZEL_VISIT_LEVELS / FERAZEL_BOT_LEVELS against it.
#
# Usage: tools/ferazel-built-levels.sh
# Exit 0 = the list printed; 2 = no such line, more than one, or an entry that is not a plain positive whole number
# (a message on stderr, nothing on stdout).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Ferazel/Core/Sources/FerazelCore/Front/BuiltLevels.swift"
fail() { echo "built levels: $1" >&2; exit 2; }
[ -f "$SRC" ] || fail "cannot read $SRC"
LINES="$(sed -nE 's/^[[:space:]]*public static let list: \[Int\] = \[([0-9, ]*)\][[:space:]]*$/<\1>/p' "$SRC")"
COUNT=$(printf '%s' "$LINES" | grep -c '^')
[ "$COUNT" = 1 ] || fail "expected exactly one 'public static let list: [Int] = [...]' line in $SRC, found $COUNT"
LINES="${LINES#<}"; LINES="${LINES%>}"; LINES="${LINES// /}"
case "$LINES" in ,*|*,|*,,*) fail "an empty entry in '$LINES'" ;; esac
LIST=""
IFS=',' read -ra PARTS <<< "$LINES"
for l in ${PARTS[@]+"${PARTS[@]}"}; do
    case "$l" in ''|0*|*[!0-9]*|??????????*) fail "entry '$l' is not a plain positive whole number" ;; esac
    LIST="$LIST${LIST:+,}$l"
done
[ -n "$LIST" ] || fail "the list in $SRC is empty"
printf '%s\n' "$LIST"
