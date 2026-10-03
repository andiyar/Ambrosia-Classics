import Foundation

/// P2.1 — an independent Swift reader of `docs/aki/levels-layouts.md`, the banked source the generated
/// `LayoutTables.swift` comes from (via `tools/gen-aki-layouts.py`). The tests compare the two, so two
/// parsers in two languages guard each other. The bank is in the repo: always present, never skipped.
enum LayoutMarkdown {
    struct Section {
        var level: Int
        var functionName: String
        var offsetX: Int
        var offsetY: Int
        var background: Int
        var tuples: [(x2: Int, y2: Int, layer: Int)]
    }

    struct ParseError: Error, CustomStringConvertible { let description: String }

    /// The repo's `docs/aki/levels-layouts.md`, found the way `akiResources` finds the repo root.
    static var url: URL {
        var repo = URL(fileURLWithPath: #filePath)                 // …/Aki/Core/Tests/AkiCoreTests/<file>
        for _ in 0..<5 { repo.deleteLastPathComponent() }          // → the repo (or worktree) root
        return repo.appendingPathComponent("docs/aki/levels-layouts.md")
    }

    /// Every `### Level N — `_LayoutK`` section in file order: the header line's g+0x94 / g+0x98 / g+0x8e
    /// values and every `(x, y, L)` table tuple in call order, with x and y doubled to half-units.
    static func load() throws -> [Section] {
        let text = try String(contentsOf: url, encoding: .utf8)
        var sections: [Section] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if line.hasPrefix("### ") {
                guard line.hasPrefix("### Level ") else { continue }
                let rest = line.dropFirst("### Level ".count)
                guard let level = Int(rest.prefix(while: \.isNumber)) else { throw ParseError(description: "level number: \(line)") }
                let ticks = line.split(separator: "`", omittingEmptySubsequences: false)
                guard ticks.count >= 3, ticks[1].hasPrefix("_Layout") else { throw ParseError(description: "function name: \(line)") }
                sections.append(Section(level: level, functionName: String(ticks[1]), offsetX: .min, offsetY: .min,
                                        background: .min, tuples: []))
            } else if line.hasPrefix("## ") {
                continue
            } else if line.hasPrefix("draw offset "), !sections.isEmpty {
                sections[sections.count - 1].offsetX = try value(after: "g+0x94 = ", in: line)
                sections[sections.count - 1].offsetY = try value(after: "g+0x98 = ", in: line)
                sections[sections.count - 1].background = try value(after: "g+0x8e = ", in: line)
            } else if line.hasPrefix("| "), !sections.isEmpty {
                let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                guard cells.count >= 2, cells[0].first?.isNumber == true else { continue }   // data rows: "| 1–8 | … |"
                for chunk in cells[1].split(separator: ")") {
                    let body = chunk.trimmingCharacters(in: .whitespaces)
                    guard body.hasPrefix("(") else { throw ParseError(description: "tuple '\(chunk)' in: \(line)") }
                    let parts = body.dropFirst().split(separator: ",")
                    guard parts.count == 3, let x = Double(parts[0]), let y = Double(parts[1]), let l = Int(parts[2]),
                          (2 * x).rounded() == 2 * x, (2 * y).rounded() == 2 * y
                    else { throw ParseError(description: "tuple '\(body))' in: \(line)") }
                    sections[sections.count - 1].tuples.append((x2: Int(2 * x), y2: Int(2 * y), layer: l))
                }
            }
        }
        return sections
    }

    private static func value(after key: String, in line: String) throws -> Int {
        guard let r = line.range(of: key) else { throw ParseError(description: "no '\(key)' in: \(line)") }
        let tail = line[r.upperBound...]
        let digits = tail.prefix { $0 == "-" || $0.isNumber }
        guard let v = Int(digits) else { throw ParseError(description: "value after '\(key)' in: \(line)") }
        return v
    }
}
