import Foundation
import XCTest
@testable import CytheraCore

/// C9 (docs/superpowers/plans/2026-11-05-cythera-remainder.md, Task C9): the script segment model — kinds,
/// reachability, the gap sweep — against the 958 committed `scriptdis.py` listings, through the canonical parity
/// form whose per-segment sha256 list `docs/cythera/tools/script_canon.py` wrote to
/// `docs/cythera/script-parity.sha256`. A mismatch is a Swift bug by definition (plan Invariant 6: never edit the
/// list). Counts: script-census.md §1–§2 and the plan's contract 4 (re-measured over the listings 2026-11-15).
final class ScriptParityTests: XCTestCase {

    /// Every script-band listing (pages 0x01–0x3F), decoded once per test process; every read and write of the
    /// cache happens under `cacheLock`, so parallel test methods cannot race on it.
    nonisolated(unsafe) private static var cache: [ScriptSegmentListing]?
    private static let cacheLock = NSLock()

    private func listings() throws -> [ScriptSegmentListing] {
        Self.cacheLock.lock()
        defer { Self.cacheLock.unlock() }
        if let c = Self.cache { return c }
        let file = try segmentFile()
        let ids = file.ids.filter { (0x01...0x3F).contains($0 >> 8) }
        let all = try ids.map { id in
            do { return try ScriptDecoder.listing(id, in: file) } catch {
                XCTFail(String(format: "segment %04X: %@", id, "\(error)")); throw error
            }
        }
        Self.cache = all
        return all
    }

    private func segmentFile() throws -> SegmentFile {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try SegmentFile(contentsOf: r.segmentFileURL)
    }

    private func listing(_ id: UInt16) throws -> ScriptSegmentListing {
        try XCTUnwrap(try listings().first { $0.id == id }, String(format: "segment %04X not listed", id))
    }

    // MARK: - Kinds

    func testKindClassification() throws {
        let all = try listings()
        XCTAssertEqual(all.count, 958)
        var byKind: [ScriptSegmentKind: Int] = [:]
        var byPage: [UInt16: Int] = [:]
        var bytes = 0
        for l in all {
            byKind[l.kind, default: 0] += 1
            byPage[l.id >> 8, default: 0] += 1
            bytes += l.length
        }
        XCTAssertEqual(byKind, [.class: 700, .routine: 218, .strtab: 20, .dict: 1, .array: 2, .data: 3, .ai: 14])
        // script-census.md §1, every page.
        XCTAssertEqual(byPage, [0x01: 1, 0x02: 20, 0x03: 2, 0x04: 14, 0x05: 3, 0x08: 22, 0x09: 19, 0x0A: 8,
                                0x0B: 1, 0x0C: 30, 0x0D: 10, 0x0E: 66, 0x0F: 22, 0x10: 180, 0x11: 88, 0x14: 42,
                                0x15: 3, 0x18: 121, 0x19: 29, 0x1A: 87, 0x1B: 111, 0x1C: 38, 0x1E: 1, 0x30: 40])
        XCTAssertEqual(bytes, 491_441)
        let mixed = all.filter { [0x03, 0x05].contains($0.id >> 8) }.map { "\($0.kind)" }.sorted()
        XCTAssertEqual(mixed, ["array", "array", "data", "data", "data"])     // 0x03 array 1 data 1; 0x05 array 1 data 2
        for l in all where (0x10...0x1E).contains(l.id >> 8) { XCTAssertEqual(l.kind, .class, "\(l.id)") }
        for l in all where [0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x30].contains(l.id >> 8) {
            XCTAssertEqual(l.kind, .routine, "\(l.id)")
        }
    }

    func testDictionaryAndMethods0x1802() throws {
        let l = try listing(0x1802)
        XCTAssertEqual(l.kind, .class)
        XCTAssertEqual(l.length, 10_426)
        XCTAssertEqual(l.dictionaryOffset, 0x288E)
        XCTAssertEqual(Set(l.methods), [ScriptMethod(selector: 32, segment: 0x1802, offset: 0x002A),
                                        ScriptMethod(selector: 12, segment: 0x1802, offset: 0x0292)])
        XCTAssertEqual(l.properties, [68])
        let first = try XCTUnwrap(l.instructions.first)
        XCTAssertEqual([first.offset, first.length], [0, 2])
        XCTAssertEqual(first.mnemonic, ".hdr")
        XCTAssertEqual(first.kind, .literal)
        let dict = try XCTUnwrap(l.instructions.first { $0.offset == 0x288E })
        XCTAssertEqual(dict.mnemonic, ".dict")
        XCTAssertEqual(dict.length, 10_426 - 0x288E)
        // A same-segment dictionary pointer into another segment's code is a shared method, not a property.
        let shared = try listings().flatMap { l in l.methods.filter { $0.segment != l.id } }
        XCTAssertFalse(shared.isEmpty)
    }

    // MARK: - Reachability

    func testReachabilityFlags() throws {
        let all = try listings()
        var flags: [ScriptInstruction.Flag: Int] = [:]
        for l in all { for i in l.instructions { flags[i.flag, default: 0] += 1 } }
        XCTAssertEqual(flags, [.reached: 16_899, .jumpTarget: 4_665, .dead: 602])

        let l = try listing(0x1802)
        XCTAssertEqual(l.deadCodeRuns, 3)
        func at(_ o: Int) throws -> ScriptInstruction { try XCTUnwrap(l.instructions.first { $0.offset == o }) }
        XCTAssertEqual(try at(0x005C).flag, .jumpTarget)
        XCTAssertEqual(try at(0x0060).flag, .reached)               // reached only by the callsubs @0326, @055F
        XCTAssertEqual(try at(0x0326).subroutineTargets, [0x0060])
        XCTAssertEqual(try at(0x0326).jumpTargets, [])
        XCTAssertEqual(try at(0x055F).subroutineTargets, [0x0060])
        let into0060 = l.instructions.filter { i in
            i.jumpTargets.contains(0x0060) || i.references.contains { r in
                switch r {
                case .subroutine(let t): return t == 0x0060
                case .pointer(let v): return v & 0x7FFF_FFFF == 0x1802_0060
                default: return false
                }
            }
        }
        XCTAssertEqual(into0060.map(\.offset), [0x0326, 0x055F])
        XCTAssertEqual(try at(0x0536).flag, .dead)                  // goto after a return: dead code
        XCTAssertEqual(try at(0x0539).flag, .jumpTarget)
        XCTAssertEqual(try at(0x0063).length, 555)                  // a text: 12 shown + …+543
        // Corpus: 15 local subroutines, 40 callsub sites (none inside an expression).
        let subs = all.flatMap { l in l.instructions.flatMap { i in i.subroutineTargets.map { (l.id, $0) } } }
        XCTAssertEqual(subs.count, 40)
        XCTAssertEqual(Set(subs.map { "\($0.0):\($0.1)" }).count, 15)

        // Hostile input (Invariant 4): every prefix of a routine either lists or throws a named error.
        let file = try segmentFile()
        let routine = try XCTUnwrap(all.first { $0.kind == .routine && (200...600).contains($0.length) })
        let bytes = [UInt8](try XCTUnwrap(file.scriptSegment(routine.id)))
        for cut in 1..<bytes.count {
            do { _ = try ScriptDecoder.listing(routine.id, bytes: Array(bytes.prefix(cut))) } catch {
                XCTAssertTrue(error is ScriptDecodeError || error is ScriptListingError, "cut \(cut): \(error)")
            }
        }
        // Mutations of a class segment with its dictionary intact (prefixes all classify as data): bytes in the code
        // region set to a statement-ending, a jump and a refused opcode, or flipped — each lists or throws by name.
        let cls = [UInt8](try XCTUnwrap(file.scriptSegment(0x1802)))
        for (k, at) in stride(from: 0x002A, to: 0x288E, by: 97).enumerated() {
            var m = cls
            m[at] = [0x40, 0x88, 0xFF, cls[at] ^ 0x80][k % 4]
            do { _ = try ScriptDecoder.listing(0x1802, bytes: m) } catch {
                XCTAssertTrue(error is ScriptDecodeError || error is ScriptListingError, "@\(at): \(error)")
            }
        }

        // The walk's anomaly branches, as `Dis.trace` lists them (they stop the path; no line, no error).
        func shape(_ bytes: [UInt8]) throws -> [String] {
            try ScriptDecoder.listing(0x3000, bytes: bytes).instructions.map { i in
                let f = i.flag == .dead ? "x" : i.flag == .jumpTarget ? ">" : "-"
                return String(format: "%04X %d %@ %@", i.offset, i.length, i.mnemonic, f)
            }
        }
        // A jump into the middle of an instruction (jf @0003 → 0005, inside itself): the path stops.
        XCTAssertEqual(try shape([0x81, 0x00, 0x00, 0x8D, 0x41, 0x01, 0x40, 0x00, 0x05, 0x8B, 0x41, 0x00, 0x40]),
                       ["0000 3 frame -", "0003 6 jf -", "0009 4 return -"])
        // A jump into a literal (jt's pointer books "Hi" @0010; its target 0011 is inside it): the path stops.
        XCTAssertEqual(try shape([0x81, 0x00, 0x00, 0x8C, 0x43, 0xB0, 0x00, 0x00, 0x10, 0x40, 0x00, 0x11,
                                  0x8B, 0x41, 0x00, 0x40, 0x48, 0x69, 0x00]),
                       ["0000 3 frame -", "0003 9 jt -", "000C 4 return -", "0010 3 .string -"])
        // Overlapping decode: goto → 0012 is decoded first (8B 40), then jt → 0010 decodes 8B 41 8B 40 over it;
        // both stay listed, and the bytes after the goto are swept as dead code.
        XCTAssertEqual(try shape([0x81, 0x00, 0x00, 0x8C, 0x41, 0x01, 0x40, 0x00, 0x10, 0x88, 0x00, 0x12,
                                  0x8B, 0x41, 0x00, 0x40, 0x8B, 0x41, 0x8B, 0x40]),
                       ["0000 3 frame -", "0003 6 jt -", "0009 3 goto -", "000C 4 return x",
                        "0010 4 return >", "0012 2 return >"])

        // A literal that points at itself is parsed once; a pointer past the end is ignored, as the tool does.
        // (0xB000_000A = a code pointer to 0x3000:000A; 0xB000_7FFF points past the end.)
        let selfArray: [UInt8] = [0x81, 0x00, 0x00, 0x8B, 0x43, 0xB0, 0x00, 0x00, 0x0A, 0x40,
                                  0x90, 0x02, 0xB0, 0x00, 0x00, 0x0A, 0xB0, 0x00, 0x7F, 0xFF]
        let s = try ScriptDecoder.listing(0x3000, bytes: selfArray)
        XCTAssertEqual(s.instructions.map(\.mnemonic), ["frame", "return", ".array"])
        XCTAssertEqual(s.instructions.map(\.length), [3, 7, 10])
        // A chain of nested literals deeper than the walk allows is refused by name, never a stack overflow.
        var chain: [UInt8] = [0x81, 0x00, 0x00, 0x8B, 0x43, 0xB0, 0x00, 0x00, 0x0A, 0x40]
        for k in 0..<400 {
            let next = 0x0A + 6 * (k + 1)
            chain += [0x90, 0x01, 0xB0, 0x00, UInt8(next >> 8), UInt8(next & 0xFF)]
        }
        chain += [0x90, 0x00]
        XCTAssertThrowsError(try ScriptDecoder.listing(0x3000, bytes: chain)) { e in
            guard case .literalNestingTooDeep = e as? ScriptListingError else { return XCTFail("\(e)") }
        }
        XCTAssertThrowsError(try ScriptDecoder.listing(0x4000, in: file)) { e in
            XCTAssertEqual(e as? ScriptListingError, .notScriptBand(0x4000))
        }
        XCTAssertThrowsError(try ScriptDecoder.listing(0x3FFF, in: file)) { e in
            XCTAssertEqual(e as? ScriptListingError, .missingSegment(0x3FFF))
        }
    }

    // MARK: - Literal, data and combat-AI segments

    func testLiteralAndDataSegments() throws {
        let file = try segmentFile()
        let names = try listing(0x0201)
        XCTAssertEqual(names.kind, .strtab)
        XCTAssertEqual(names.instructions.first?.mnemonic, ".strtab")
        XCTAssertEqual(names.instructions.first?.length, 2 + 4 * 256)
        let alaric = try XCTUnwrap(names.instructions.first { $0.offset == 0x0409 })
        XCTAssertEqual(alaric.mnemonic, ".string")
        XCTAssertEqual(alaric.length, 7)
        let b = [UInt8](try XCTUnwrap(file.scriptSegment(0x0201)))
        XCTAssertEqual(Array(b[0x0409..<0x0410]), Array("Alaric".utf8) + [0])
        XCTAssertEqual(Int(b[2 + 4 * 2 + 2]) << 8 | Int(b[2 + 4 * 2 + 3]), 0x0409)   // entry [2] → @0409

        let symtab = try listing(0x0101)
        XCTAssertEqual(symtab.kind, .dict)
        XCTAssertEqual(symtab.instructions.first?.mnemonic, ".dict")
        XCTAssertEqual(symtab.instructions.first?.length, 2 + 6 * 127)
        let sym = [UInt8](try XCTUnwrap(file.scriptSegment(0x0101)))
        let slots = (Int(sym[0]) << 8 | Int(sym[1])) & 0xFFF
        XCTAssertEqual(slots, 127)
        let keys = (0..<slots).filter { i in
            let o = 2 + 6 * i
            return sym[o..<(o + 4)].elementsEqual([0x50, 0x00, 0xFF, 0xFF]) == false     // non-Nil value
        }
        XCTAssertEqual(keys.count, 55)

        XCTAssertEqual(try listing(0x0301).kind, .array)
        for (id, length, lines) in [(UInt16(0x033F), 4, [4]), (0x0500, 20, [16, 4]), (0x0540, 4, [4])] {
            let d = try listing(id)
            XCTAssertEqual(d.kind, .data, "\(id)")
            XCTAssertEqual(d.length, length, "\(id)")
            XCTAssertEqual(d.instructions.map(\.length), lines, "\(id)")
            XCTAssertEqual(Set(d.instructions.map(\.mnemonic)), [".data"], "\(id)")
        }
    }

    func testCombatAISegments() throws {
        let ai = try listings().filter { $0.kind == .ai }
        XCTAssertEqual(ai.map(\.id), [0x0410, 0x0411, 0x0412, 0x0413, 0x0414, 0x0415, 0x0416,
                                      0x0430, 0x0431, 0x0432, 0x0433, 0x0434, 0x0435, 0x0436])
        XCTAssertEqual(ai.map(\.length), [128, 128, 128, 168, 88, 176, 120, 128, 128, 128, 88, 168, 176, 120])
        for l in ai {
            let seg = try XCTUnwrap(l.combatAI, "\(l.id)")
            XCTAssertEqual(seg.entries.count, (l.length - 32) / 8, "\(l.id)")
            XCTAssertTrue(seg.entries.allSatisfy { $0.count == 8 })
            XCTAssertEqual(l.instructions.map(\.mnemonic), ["name"] + Array(repeating: "entry", count: seg.entries.count))
            XCTAssertEqual(l.instructions.map(\.offset), [0] + (0..<seg.entries.count).map { 0x20 + 8 * $0 })
            XCTAssertTrue(l.instructions.allSatisfy { $0.length == 0 && $0.flag == .reached })
        }
        let first = try XCTUnwrap(ai.first?.combatAI)
        XCTAssertEqual(first.name, "Attack Nearest")
        XCTAssertEqual(first.entries.first, [0x65, 0x82, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00])

        // Shapes the census has not shown are refused by name (Invariant 3).
        let raw = [UInt8](try XCTUnwrap(try segmentFile().scriptSegment(0x0410)))
        XCTAssertThrowsError(try CombatAISegment(bytes: Array(raw.prefix(0x1F)))) { e in
            XCTAssertEqual(e as? CombatAIError, .truncated(length: 0x1F))
        }
        XCTAssertThrowsError(try CombatAISegment(bytes: Array(raw.prefix(0x25)))) { e in
            XCTAssertEqual(e as? CombatAIError, .raggedEntries(length: 0x25))
        }
        var long = raw
        long[0] = 0x18
        XCTAssertThrowsError(try CombatAISegment(bytes: long)) { e in
            XCTAssertEqual(e as? CombatAIError, .nameTooLong(0x18))
        }
    }

    // MARK: - Parity

    func testCanonicalParityAll958() throws {
        let golden = try goldenHashes()
        XCTAssertEqual(golden.count, 958)
        let all = try listings()
        var lines = 0
        var histogram: [String: Int] = [:]
        var mismatches: [String] = []
        for l in all {
            lines += l.instructions.count
            for i in l.instructions { histogram[i.mnemonic, default: 0] += 1 }
            let text = ScriptCanonical.text(l)
            let id4 = String(format: "%04X", l.id)
            guard let want = golden[id4] else { mismatches.append("\(id4): not in the golden list"); continue }
            if SHA256.hex(Array(text.utf8)) != want { mismatches.append(firstDifference(id4, text)) }
        }
        XCTAssertEqual(mismatches.count, 0, mismatches.prefix(10).joined(separator: "\n"))
        XCTAssertEqual(lines, 22_166)
        XCTAssertEqual(histogram, [
            "text": 3785, "goto": 2611, "jf": 2509, "return": 2283, "match": 1556, "set": 1480, "builtin": 1417,
            "frame": 1271, ".array": 853, ".string": 828, ".dict": 701, ".hdr": 700, "setfield": 554, "call": 552,
            "print": 289, "entry": 178, "jt": 161, "input": 108, "prompt": 95, "send": 70, "callsub": 40,
            "atput": 26, ".strtab": 20, "setglobal": 18, "release": 17, "name": 14, "sysnew": 10, "gstore": 5,
            ".word": 4, ".data": 4, "raise": 3, "switch": 2, "callx": 1, "store": 1,
        ])
        XCTAssertEqual(ScriptCanonical.text(try listing(0x0410)).split(separator: "\n").prefix(3),
                       ["seg 0410 kind ai len 128", "0000 0 name -", "0020 0 entry -"])
    }

    /// `docs/cythera/script-parity.sha256`, found by walking up from this file; missing = a failure naming the path.
    private func goldenHashes() throws -> [String: String] {
        var dir = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
        while dir.pathComponents.count > 1 {
            let url = dir.appendingPathComponent("docs/cythera/script-parity.sha256")
            if FileManager.default.fileExists(atPath: url.path) {
                var out: [String: String] = [:]
                for line in try String(contentsOf: url, encoding: .utf8).split(separator: "\n") {
                    let f = line.split(separator: " ", omittingEmptySubsequences: true)
                    if f.count == 2 { out[String(f[1])] = String(f[0]) }
                }
                return out
            }
            dir = dir.deletingLastPathComponent()
        }
        XCTFail("docs/cythera/script-parity.sha256 not found above \(#filePath)")
        return [:]
    }

    /// The first canonical line that differs from `$CYTHERA_CANON_DIR/<ID4>.canon` (script_canon.py --out), when
    /// that directory is given; otherwise the segment id and its first lines.
    private func firstDifference(_ id4: String, _ text: String) -> String {
        let got = text.split(separator: "\n", omittingEmptySubsequences: false)
        guard let dir = ProcessInfo.processInfo.environment["CYTHERA_CANON_DIR"],
              let want = try? String(contentsOfFile: "\(dir)/\(id4).canon", encoding: .utf8)
                  .split(separator: "\n", omittingEmptySubsequences: false) else {
            return "\(id4): hash differs; first lines \(got.prefix(3))"
        }
        for k in 0..<max(got.count, want.count) {
            let g = k < got.count ? String(got[k]) : "<end>", w = k < want.count ? String(want[k]) : "<end>"
            if g != w { return "\(id4) line \(k): swift '\(g)' vs listing '\(w)'" }
        }
        return "\(id4): hash differs, lines equal"
    }
}

/// SHA-256 (FIPS 180-4), enough to hash the canonical texts without CryptoKit (Windows-portable tests).
private enum SHA256 {
    private static let k: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ]

    static func hex(_ message: [UInt8]) -> String {
        var h: [UInt32] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                           0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
        var m = message
        let bits = UInt64(message.count) * 8
        m.append(0x80)
        while m.count % 64 != 56 { m.append(0) }
        for s in stride(from: 56, through: 0, by: -8) { m.append(UInt8(truncatingIfNeeded: bits >> UInt64(s))) }
        func rotr(_ x: UInt32, _ n: UInt32) -> UInt32 { (x >> n) | (x << (32 - n)) }
        var w = [UInt32](repeating: 0, count: 64)
        for chunk in stride(from: 0, to: m.count, by: 64) {
            for t in 0..<16 {
                let b = chunk + 4 * t
                w[t] = UInt32(m[b]) << 24 | UInt32(m[b + 1]) << 16 | UInt32(m[b + 2]) << 8 | UInt32(m[b + 3])
            }
            for t in 16..<64 {
                let s0 = rotr(w[t - 15], 7) ^ rotr(w[t - 15], 18) ^ (w[t - 15] >> 3)
                let s1 = rotr(w[t - 2], 17) ^ rotr(w[t - 2], 19) ^ (w[t - 2] >> 10)
                w[t] = w[t - 16] &+ s0 &+ w[t - 7] &+ s1
            }
            var (a, b, c, d, e, f, g, hh) = (h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7])
            for t in 0..<64 {
                let t1 = hh &+ (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) &+ ((e & f) ^ (~e & g)) &+ k[t] &+ w[t]
                let t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) &+ ((a & b) ^ (a & c) ^ (b & c))
                (hh, g, f, e, d, c, b, a) = (g, f, e, d &+ t1, c, b, a, t1 &+ t2)
            }
            for (i, v) in [a, b, c, d, e, f, g, hh].enumerated() { h[i] = h[i] &+ v }
        }
        return h.map { String(format: "%08x", $0) }.joined()
    }
}
