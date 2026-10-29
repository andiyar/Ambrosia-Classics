#!/bin/bash
# Port-gap ledger, part 1b: which resources does the port actually ask for?
#
# Copies HectorKit (Sources + Package.swift) into a temp folder, adds an env-gated trace to
# ResourceCollection.resource(type:id:) and .resources(of:) — never touching the real HectorKit — then runs the whole
# Ferazel/Core test suite against that copy with its own scratch build folder. Every distinct
# (type, id, found?, caller frames) is appended to the trace file; tools/ferazel/gap-resources.py reads it.
# The game app is never launched; the suite is the usual headless one (levels 1–4, front end, map, stage screens).
#
# Usage: tools/ferazel/gap-trace.sh <out.trace>      (≈ 10–15 min; HECTORKIT_SRC overrides ~/Developer/HectorKit)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$(cd "$(dirname "${1:?usage: gap-trace.sh <out.trace>}")" && pwd)/$(basename "$1")"
SRC="${HECTORKIT_SRC:-$HOME/Developer/HectorKit}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ferazel-gap-trace.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/HectorKit"
cp "$SRC/Package.swift" "$TMP/HectorKit/"
cp -R "$SRC/Sources" "$TMP/HectorKit/"
[ -d "$SRC/Tests" ] && mkdir -p "$TMP/HectorKit/Tests" && cp -R "$SRC/Tests/." "$TMP/HectorKit/Tests/"
F="$TMP/HectorKit/Sources/HectorResources/Resource.swift"
python3 - "$F" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old_one = "public func resource(type: String, id: Int16) -> Resource? { byType[type]?.first { $0.id == id } }"
old_all = "public func resources(of type: String) -> [Resource] { byType[type] ?? [] }"
assert old_one in s and old_all in s, "HectorKit Resource.swift changed shape; update gap-trace.sh"
s = s.replace(old_one, """public func resource(type: String, id: Int16) -> Resource? {
        let r = byType[type]?.first { $0.id == id }
        ResourceTrace.note(type, Int(id), r != nil)
        return r
    }""")
s = s.replace(old_all, """public func resources(of type: String) -> [Resource] {
        ResourceTrace.note(type, Int.min, byType[type] != nil)
        return byType[type] ?? []
    }""")
s += '''

/// Gap-ledger trace (tools/ferazel/gap-trace.sh only; never in the real HectorKit).
enum ResourceTrace {
    nonisolated(unsafe) static var seen = Set<String>()
    static let lock = NSLock()
    static let path = ProcessInfo.processInfo.environment["FERAZEL_RES_TRACE"]
    static func note(_ type: String, _ id: Int, _ found: Bool) {
        guard let path else { return }
        let frames = Thread.callStackSymbols.dropFirst(2).filter { !$0.contains("HectorResources") }.prefix(14)
            .map { line -> String in
                let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                guard parts.count >= 4 else { return line }
                return parts[1] + ":" + parts[3]
            }.joined(separator: " ")
        let proc = ProcessInfo.processInfo.processName
        let key = "\\(proc)\\t\\(type)\\t\\(id == Int.min ? "ALL" : String(id))\\t\\(found ? 1 : 0)\\t\\(frames)"
        lock.lock(); defer { lock.unlock() }
        guard seen.insert(key).inserted else { return }
        if let h = FileHandle(forWritingAtPath: path) ?? { FileManager.default.createFile(atPath: path, contents: nil); return FileHandle(forWritingAtPath: path) }() {
            h.seekToEndOfFile(); h.write((key + "\\n").data(using: .utf8)!); try? h.close()
        }
    }
}
'''
open(p, 'w').write(s)
PY
: > "$OUT"
cd "$ROOT/Ferazel/Core"
echo "trace → $OUT (build in $TMP)" >&2
HECTORKIT_PATH="$TMP/HectorKit" FERAZEL_RES_TRACE="$OUT" swift test --scratch-path "$TMP/build" 2>&1 | tail -5
echo "distinct trace rows: $(wc -l < "$OUT")" >&2
