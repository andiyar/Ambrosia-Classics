/// Literal find-and-replace in pure Swift (W7 review). Foundation-on-Windows' `String.replacingOccurrences(of:with:)`
/// traps (`ud2` inside Foundation.dll) on non-ASCII strings past a few dozen UTF-8 bytes — measured in CrossOver
/// 2026-10-06 (`tools/windows/README.md`, "W7 results"); `components(separatedBy:)`, `range(of:)`, `contains`,
/// `trimmingCharacters` and `hasPrefix` passed the same probe. Every run-time replace in this package goes through here.
///
/// Matching is on Unicode scalars, left to right, non-overlapping — as Foundation's literal search over UTF-16
/// matches, and unlike `Character` matching, which would not find "\r" inside a "\r\n" grapheme.
extension String {
    public func replacingEvery(_ target: String, with replacement: String) -> String {
        let needle = Array(target.unicodeScalars)
        guard !needle.isEmpty else { return self }
        let hay = Array(unicodeScalars)
        guard hay.count >= needle.count else { return self }
        var out = String.UnicodeScalarView()
        var i = 0
        var replaced = false
        while i < hay.count {
            if hay[i] == needle[0], i + needle.count <= hay.count, hay[i ..< i + needle.count].elementsEqual(needle) {
                out.append(contentsOf: replacement.unicodeScalars)
                i += needle.count
                replaced = true
            } else {
                out.append(hay[i])
                i += 1
            }
        }
        return replaced ? String(out) : self
    }
}
