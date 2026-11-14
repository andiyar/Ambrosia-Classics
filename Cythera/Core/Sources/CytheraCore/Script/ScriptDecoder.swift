import Foundation

/// A script-band segment the listing cannot be made for. Statement decode errors propagate as
/// `ScriptDecodeError` (plan Invariant 3: `scriptdis.py` would list them as `??`; no shipped segment has one).
public enum ScriptListingError: Error, Equatable, Sendable {
    /// Not on pages 0x01–0x3F.
    case notScriptBand(UInt16)
    /// Absent from the file.
    case missingSegment(UInt16)
    /// A page-0x04 id outside the combat-AI band 0x0410–0x0436 (`SegmentFile.storedPlaintextBand`): it would be
    /// read decrypted, and the census has never shown one.
    case aiOutsideBand(UInt16)
    /// Literal blocks pointing into literal blocks deeper than `ScriptDecoder.maxLiteralDepth` (the tool would
    /// hit Python's recursion limit; the shipped data nests a few levels).
    case literalNestingTooDeep(offset: Int)
    /// A literal block (a pointer's target, a 0x45 block, a dictionary or array header) whose header lies past
    /// the end of the bytes (the tool's `IndexError`).
    case truncatedLiteral(offset: Int)
}

/// Classifies a script-band segment and lists it the way `docs/cythera/tools/scriptdis.py` does (`Store._probe`,
/// `Dis.run`, `Dis.trace`, `Dis.gaps`, `Dis.listing`; `ai_listing`, `data_listing`): statements reached from the
/// dictionary entries, the routine entry, jumps, code pointers and local-subroutine calls; then a gap sweep that
/// decodes unreached bytes as dead code; literal blocks booked as bytes. Script-census.md §1–§2, plan C9.
public enum ScriptDecoder {
    /// The deepest literal nesting the walk follows before refusing.
    public static let maxLiteralDepth = 256

    /// The listing of script-band segment `id` (pages 0x01–0x3F), read with `scriptSegment` (decrypted except
    /// 0x0101, 0x0210 and the combat-AI band, which are stored plain).
    ///
    /// A census and parity tool, never a gate for running a segment: a decode error anywhere refuses the whole
    /// segment — including one met by the speculative dead-code sweep over bytes nothing reaches. Throws
    /// `ScriptListingError` (band, absence, literal nesting or truncation), `ScriptDecodeError` (a statement or
    /// expression the decoder refuses) and `CombatAIError` (a combat-AI shape the census has not shown). Shapes
    /// the tool lists with an "ANOMALY" note are listed the same way and recorded in `anomalies`.
    public static func listing(_ id: UInt16, in file: SegmentFile) throws -> ScriptSegmentListing {
        guard (0x01...0x3F).contains(id >> 8) else { throw ScriptListingError.notScriptBand(id) }
        guard let data = file.scriptSegment(id) else { throw ScriptListingError.missingSegment(id) }
        if id >> 8 == 0x04 && !SegmentFile.storedPlaintextBand.contains(id) {
            throw ScriptListingError.aiOutsideBand(id)
        }
        var seen: [UInt16: (ScriptSegmentKind, [UInt8])?] = [:]
        return try listing(id, bytes: [UInt8](data)) { other in
            if let hit = seen[other] { return hit }
            var found: (ScriptSegmentKind, [UInt8])?
            if (0x01...0x3F).contains(other >> 8), let d = file.scriptSegment(other) {
                let b = [UInt8](d)
                found = (kind(of: other, bytes: b), b)
            }
            seen[other] = found
            return found
        }
    }

    /// The listing of `bytes` as segment `id`. `lookup` gives another segment's kind and bytes, for the class
    /// dictionaries' shared methods; without it every pointer into another segment counts as a property.
    static func listing(_ id: UInt16, bytes: [UInt8],
                        lookup: (UInt16) -> (ScriptSegmentKind, [UInt8])? = { _ in nil }) throws
        -> ScriptSegmentListing {
        let kind = kind(of: id, bytes: bytes)
        switch kind {
        case .ai:
            let ai = try CombatAISegment(bytes: bytes)
            return ScriptSegmentListing(id: id, kind: .ai, length: bytes.count, instructions: ai.instructions,
                                        combatAI: ai)
        case .data:
            let lines = stride(from: 0, to: bytes.count, by: 16).map {
                ScriptInstruction(offset: $0, length: min(16, bytes.count - $0), mnemonic: ".data", kind: .literal)
            }
            return ScriptSegmentListing(id: id, kind: .data, length: bytes.count, instructions: lines)
        case .class, .routine, .strtab, .dict, .array:
            var walk = Walk(id: id, kind: kind, bytes: bytes)
            return try walk.run(lookup: lookup)
        }
    }

    /// `Store._probe` (page 0x04 → `.ai` first, as `Store._classify`).
    public static func kind(of id: UInt16, bytes b: [UInt8]) -> ScriptSegmentKind {
        let page = id >> 8
        if page == 0x04 { return .ai }
        if (0x10...0x1F).contains(page) && probeClass(b) { return .class }
        if b.first == 0x81 { return .routine }
        if probeStrtab(b) { return .strtab }
        if probeDict(b) { return .dict }
        if b.count >= 2, (0x90...0x9F).contains(b[0]), 2 + 4 * (u16(b, 0) & 0xFFF) <= b.count { return .array }
        return .data
    }

    /// `probe_class`: a u16 dictionary offset whose target is a 0xA0–0xAF dictionary that fits.
    static func probeClass(_ b: [UInt8]) -> Bool {
        guard b.count >= 4 else { return false }
        let off = u16(b, 0)
        guard off + 2 <= b.count, (0xA0...0xAF).contains(b[off]) else { return false }
        return off + 2 + 6 * (u16(b, off) & 0xFFF) <= b.count
    }

    /// `probe_dict`: a bare dictionary that fits.
    static func probeDict(_ b: [UInt8]) -> Bool {
        guard b.count >= 2, (0xA0...0xAF).contains(b[0]) else { return false }
        return 2 + 6 * (u16(b, 0) & 0xFFF) <= b.count
    }

    /// `probe_strtab`: an array whose non-Nil entries' low 16 bits point at NUL-terminated strings (first byte
    /// below 0x80) after the table; at least one such entry.
    static func probeStrtab(_ b: [UInt8]) -> Bool {
        guard b.count >= 2, (0x90...0x9F).contains(b[0]) else { return false }
        let n = u16(b, 0) & 0xFFF
        guard n != 0, 2 + 4 * n <= b.count else { return false }
        var good = 0
        for i in 0..<n {
            let v = u32(b, 2 + 4 * i)
            if v == nilValue { continue }
            let off = Int(v & 0xFFFF)
            guard off >= 2 + 4 * n, off < b.count, b[off] < 0x80, b[off...].contains(0) else { return false }
            good += 1
        }
        return good > 0
    }

    static let nilValue: UInt32 = 0x5000_FFFF

    static func u16(_ b: [UInt8], _ o: Int) -> Int { Int(b[o]) << 8 | Int(b[o + 1]) }

    static func u32(_ b: [UInt8], _ o: Int) -> UInt32 {
        UInt32(b[o]) << 24 | UInt32(b[o + 1]) << 16 | UInt32(b[o + 2]) << 8 | UInt32(b[o + 3])
    }
}

/// One `Dis` run over a code or literal segment. Byte maps are arrays (-1 = none); every index is checked.
private struct Walk {
    let id: UInt16
    let kind: ScriptSegmentKind
    let b: [UInt8]
    var n: Int { b.count }

    /// Decoded statements by start.
    var insns: [Int: ScriptInstruction] = [:]
    /// Byte → the statement that owns it (`Dis.owner`).
    var owner: [Int]
    /// Literal blocks by start: end and kind (`Dis.blocks`).
    var blocks: [Int: (end: Int, kind: String)] = [:]
    /// Byte → the first block that claimed it (`Dis.blk_owner`).
    var blockOwner: [Int]
    /// Offsets some jump targets (`Dis.labels` 'jump').
    var jumpLabels: Set<Int> = []
    /// Pending walk starts, last in first out (`Dis.entries`).
    var entries: [Int] = []
    /// Statements decoded by the gap sweep.
    var dead: Set<Int> = []
    /// Bytes neither decoded nor referenced: [start, end).
    var rawGaps: [(start: Int, end: Int)] = []
    /// What the tool notes as "ANOMALY", in the order met.
    var anomalies: [ScriptAnomaly] = []

    init(id: UInt16, kind: ScriptSegmentKind, bytes: [UInt8]) {
        self.id = id
        self.kind = kind
        self.b = bytes
        owner = Array(repeating: -1, count: bytes.count)
        blockOwner = Array(repeating: -1, count: bytes.count)
    }

    // MARK: Literal blocks and references (`Dis.vaddr`, `Dis.target`, `Dis.block`, `Dis.word`)

    mutating func addBlock(_ start: Int, _ end: Int, _ kind: String) {
        blocks[start] = (end, kind)
        for i in max(start, 0)..<max(start, min(end, n)) where blockOwner[i] < 0 { blockOwner[i] = start }
    }

    /// A VAddr literal: only a code pointer (tag −1) into this segment has a structural effect.
    mutating func vaddr(_ v: UInt32, depth: Int) throws {
        guard v & 0x8000_0000 != 0, UInt16((v >> 16) & 0x7FFF) == id else { return }
        try target(Int(v & 0xFFFF), depth: depth)
    }

    /// A same-segment code pointer: code when the target byte is 0x80–0x8F, else a literal block; past the
    /// end it is the tool's anomaly (recorded, not followed).
    mutating func target(_ off: Int, depth: Int) throws {
        guard off < n else { anomalies.append(ScriptAnomaly(.pointerPastEnd, at: off)); return }
        if (0x80...0x8F).contains(b[off]) { entries.append(off) } else { _ = try block(off, length: nil, depth: depth) }
    }

    /// Parses the literal block at `off` once: a string (< 0x80), an array (0x90–0x9F), a dictionary
    /// (0xA0–0xAF, values followed in key order), anything else one byte (or `length`) of "odd" block.
    mutating func block(_ off: Int, length: Int?, depth: Int) throws -> Int {
        if let known = blocks[off] { return known.end }
        guard depth < ScriptDecoder.maxLiteralDepth else { throw ScriptListingError.literalNestingTooDeep(offset: off) }
        guard off >= 0, off < n else { throw ScriptListingError.truncatedLiteral(offset: off) }
        let c = b[off]
        switch c {
        case 0x00..<0x80:
            var e = off
            while e < n && b[e] != 0 { e += 1 }
            addBlock(off, e < n ? e + 1 : e, "string")
        case 0x90...0x9F:
            guard off + 2 <= n else { throw ScriptListingError.truncatedLiteral(offset: off) }
            var count = ScriptDecoder.u16(b, off) & 0xFFF
            var end = off + 2 + 4 * count
            if end > n { end = n; count = (end - off - 2) / 4; anomalies.append(ScriptAnomaly(.arrayPastEnd, at: off)) }
            addBlock(off, end, "array")
            for i in 0..<count { try vaddr(ScriptDecoder.u32(b, off + 2 + 4 * i), depth: depth + 1) }
        case 0xA0...0xAF:
            guard off + 2 <= n else { throw ScriptListingError.truncatedLiteral(offset: off) }
            var count = ScriptDecoder.u16(b, off) & 0xFFF
            var end = off + 2 + 6 * count
            if end > n { end = n; count = (end - off - 2) / 6; anomalies.append(ScriptAnomaly(.dictPastEnd, at: off)) }
            addBlock(off, end, "dict")
            var slots: [(key: Int, value: UInt32, at: Int)] = []
            for i in 0..<count {
                let at = off + 2 + 6 * i
                let v = ScriptDecoder.u32(b, at)
                if v != ScriptDecoder.nilValue { slots.append((ScriptDecoder.u16(b, at + 4), v, at)) }
            }
            slots.sort { ($0.key, $0.value, $0.at) < ($1.key, $1.value, $1.at) }    // `sorted(ents)`
            for s in slots { try vaddr(s.value, depth: depth + 1) }
            return end
        default:
            let l = length ?? 0
            addBlock(off, off + (l == 0 ? 1 : l), "odd")                          // `length or 1`
            anomalies.append(ScriptAnomaly(.oddLiteral, at: off))
        }
        return blocks[off]?.end ?? off
    }

    mutating func word(_ off: Int) {
        guard off + 4 <= n else { anomalies.append(ScriptAnomaly(.wordPastEnd, at: off)); return }
        guard blocks[off] == nil else { return }
        addBlock(off, off + 4, "word")
    }

    // MARK: Traversal (`Dis.trace`, `Dis.gaps`)

    mutating func trace(dead isDead: Bool) throws {
        while let start = entries.popLast() {
            var pc = start
            while pc < n {
                if insns[pc] != nil { break }
                if owner[pc] >= 0, insns[owner[pc]]?.mnemonic != "text" {
                    anomalies.append(ScriptAnomaly(.midInstruction, at: pc)); break
                }
                if blockOwner[pc] >= 0, blocks[blockOwner[pc]]?.kind != "word" {
                    anomalies.append(ScriptAnomaly(.intoLiteral, at: pc)); break
                }
                let ins = try InstructionDecoder.statement(in: b, at: pc)
                let end = pc + ins.length
                for r in ins.references {
                    switch r {
                    case .subroutine(let t): entries.append(t)
                    case .pointer(let v): try vaddr(v, depth: 0)
                    case .inlineBlock(let range):
                        // An empty 0x45 block parses nothing (the tool would book the following byte as a
                        // literal; no shipped block is empty).
                        if !range.isEmpty, try block(range.lowerBound, length: range.count, depth: 0) > range.upperBound {
                            anomalies.append(ScriptAnomaly(.inlineBlockOverrun, at: range.lowerBound))
                        }
                        for i in range where i < n && blockOwner[i] < 0 { blockOwner[i] = range.lowerBound }
                    case .word(let o): word(o)
                    }
                }
                for t in ins.jumpTargets {
                    guard t < n else { anomalies.append(ScriptAnomaly(.jumpPastEnd, at: t)); continue }
                    entries.append(t)
                    jumpLabels.insert(t)
                }
                insns[pc] = ins
                if isDead { dead.insert(pc) }
                for i in pc..<min(end, n) {
                    let o = owner[i]
                    if o >= 0 && o != pc {
                        if ins.mnemonic == "text" && insns[o]?.mnemonic == "text" { continue }  // a shared text tail
                        anomalies.append(ScriptAnomaly(.overlappingDecode, at: i))              // keeps its owner
                    }
                    owner[i] = pc
                }
                if [0x88, 0x8B, 0x92].contains(b[pc]) { break }  // goto, return, raise end the path
                pc = end
            }
        }
    }

    /// Unowned bytes: words in literal segments (when they come in fours), dead code in code segments (a run
    /// from each gap start, rescanned), raw bytes otherwise.
    mutating func gaps() throws {
        var i = 0
        while i < n {
            if owner[i] >= 0 || blockOwner[i] >= 0 { i += 1; continue }
            var j = i
            while j < n && owner[j] < 0 && blockOwner[j] < 0 { j += 1 }
            let literal = kind == .array || kind == .dict || kind == .strtab
            if literal && (j - i) % 4 == 0 {
                for k in stride(from: i, to: j, by: 4) {
                    try vaddr(ScriptDecoder.u32(b, k), depth: 0)   // evaluated before the word is booked
                    addBlock(k, k + 4, "word")
                }
            } else if kind == .class || kind == .routine {
                entries.append(i)
                try trace(dead: true)
                if owner[i] < 0 { rawGaps.append((i, j)); i = j }
                continue                                       // rescan: the sweep may cover part of the gap
            } else {
                rawGaps.append((i, j))
            }
            i = j
        }
    }

    // MARK: The run and the listing (`Dis.run`, `Dis.listing`)

    mutating func run(lookup: (UInt16) -> (ScriptSegmentKind, [UInt8])?) throws -> ScriptSegmentListing {
        var dictionaryOffset: Int?
        var methods: [ScriptMethod] = []
        var properties: [UInt16] = []
        switch kind {
        case .class:
            let off = ScriptDecoder.u16(b, 0)
            addBlock(0, 2, "hdr")
            dictionaryOffset = off
            _ = try block(off, length: nil, depth: 0)
            for i in 0..<(ScriptDecoder.u16(b, off) & 0xFFF) {
                let v = ScriptDecoder.u32(b, off + 2 + 6 * i)
                let key = UInt16(ScriptDecoder.u16(b, off + 6 + 6 * i))
                if v == ScriptDecoder.nilValue { continue }
                let seg = UInt16((v >> 16) & 0x7FFF), to = Int(v & 0xFFFF)
                let code = v & 0x8000_0000 != 0
                if code && seg == id && to < n && (0x80...0x8F).contains(b[to]) {
                    methods.append(ScriptMethod(selector: key, segment: id, offset: to))
                } else if code && seg != id, let (k, tb) = lookup(seg), k == .class || k == .routine,
                          to < tb.count, (0x80...0x8F).contains(tb[to]) {
                    methods.append(ScriptMethod(selector: key, segment: seg, offset: to))   // shared method
                } else {
                    properties.append(key)
                }
            }
        case .routine:
            entries.append(0)
        case .strtab:
            let count = ScriptDecoder.u16(b, 0) & 0xFFF
            addBlock(0, 2 + 4 * count, "strtab")
            for i in 0..<count {
                let v = ScriptDecoder.u32(b, 2 + 4 * i)
                if v == ScriptDecoder.nilValue { continue }
                let o = Int(v & 0xFFFF)
                if blocks[o] == nil, o < n {
                    var e = o
                    while e < n && b[e] != 0 { e += 1 }
                    addBlock(o, e + 1, "string")
                }
            }
        case .dict, .array:
            _ = try block(0, length: nil, depth: 0)
        case .data, .ai:
            break
        }
        try trace(dead: false)
        try gaps()

        var runs = 0
        var runEnd: Int?
        for o in insns.keys.sorted() {
            if dead.contains(o) {
                let end = o + (insns[o]?.length ?? 0)
                if runEnd == o { runEnd = end } else { runs += 1; runEnd = end }
            } else {
                runEnd = nil
            }
        }

        var lines: [ScriptInstruction] = []
        let starts = Set(insns.keys).union(blocks.keys).union(rawGaps.map(\.start)).sorted()
        for o in starts {
            if var ins = insns[o] {
                ins.flag = dead.contains(o) ? .dead : jumpLabels.contains(o) ? .jumpTarget : .reached
                lines.append(ins)
            } else if let bl = blocks[o] {
                if owner[o] >= 0 { continue }
                lines.append(ScriptInstruction(offset: o, length: min(bl.end, n) - o, mnemonic: "." + bl.kind,
                                               kind: .literal))
            } else {
                for g in rawGaps where g.start == o {
                    for k in stride(from: g.start, to: g.end, by: 16) {
                        lines.append(ScriptInstruction(offset: k, length: min(g.end, k + 16) - k,
                                                       mnemonic: ".bytes", kind: .literal))
                    }
                }
            }
        }
        return ScriptSegmentListing(id: id, kind: kind, length: n, instructions: lines,
                                    dictionaryOffset: dictionaryOffset, methods: methods,
                                    properties: properties.sorted(), deadCodeRuns: runs, anomalies: anomalies)
    }
}
