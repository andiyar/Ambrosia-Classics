import Foundation

/// Why an LZ stream did not decode (Invariant 5: malformed input throws, never traps).
public enum LZError: Error, Equatable, Sendable {
    /// The input ended before the terminator op `11111xxx`, or inside an op's operands or literals.
    case truncated
    /// A match's distance reaches before the first output byte (the stray segment 0x8EFF does this — note 5).
    case matchBeforeStart
}

/// The Delver LZ codec, `FUN_1007573c @ 1007573c` (docs/cythera/data-format.md §2, HIGH; oracle
/// `docs/cythera/tools/lz.py`). Used for tile sheets, portraits, sky and pixmaps. There is no length header:
/// decoding runs until the terminator op, and the number of input bytes consumed (terminator included) is
/// returned so callers can check it against the segment length, as the census does.
///
/// | first byte `b` | bytes | action |
/// |---|---|---|
/// | `0xxxxxxx` | b, b1 | `(b1>>3)&3` literals, then match len `(b1&7)+3`, distance `1 + (b&0x7f | (b1&0xe0)<<2)` |
/// | `10xxxxxx` | b, b1, b2 | `b2&3` literals, then match len `(b1&0x1f)+3`, distance `1 + ((b2&0xfc)<<7 | b&0x3f | (b1&0xe0)<<1)` |
/// | `110 0xxxx` | 1+n | literal run, n = `((b&0xf)+1)*4` |
/// | `110 1xxxx` | 1+n | literal run, n = `b&0xf` |
/// | `1110 xxxx` | 2 | RLE: byte b1 × `(b&0xf)+3` |
/// | `11110 xxx` | 3 | RLE: byte b2 × `b1+3` |
/// | `11111 xxx` | 1 | end of stream |
///
/// Matches copy byte by byte, so a distance shorter than the length repeats (as the original's loop does).
public enum LZ {

    /// Per-op counts over one or more streams, in the table's row order (A = `0xxxxxxx` … F = `11110xxx`,
    /// `end` = terminators). Internal: the census test's hook (plan C3, p04), not part of the S2 surface.
    struct OpCensus: Equatable {
        var a = 0, b = 0, c = 0, d = 0, e = 0, f = 0, end = 0
    }

    /// Decodes one stream starting at `src.startIndex`; trailing bytes after the terminator are not read.
    public static func decode(_ src: Data) throws -> (bytes: [UInt8], consumed: Int) {
        var census = OpCensus()
        return try decode(src, census: &census)
    }

    static func decode(_ src: Data, census: inout OpCensus) throws -> (bytes: [UInt8], consumed: Int) {
        try src.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let input = raw.bindMemory(to: UInt8.self)
            let count = input.count
            var out: [UInt8] = []
            var i = 0

            func byte(_ at: Int) throws -> Int {
                guard at < count else { throw LZError.truncated }
                return Int(input[at])
            }
            func literals(_ n: Int) throws {
                guard n <= count - i else { throw LZError.truncated }
                out.append(contentsOf: input[i..<(i + n)])
                i += n
            }
            func match(length: Int, distance: Int) throws {
                let start = out.count - distance
                guard start >= 0 else { throw LZError.matchBeforeStart }
                for k in 0..<length { out.append(out[start + k]) }
            }

            while true {
                let b = try byte(i)
                if b & 0x80 == 0 {
                    census.a += 1
                    let b1 = try byte(i + 1)
                    i += 2
                    try literals((b1 >> 3) & 3)
                    try match(length: (b1 & 7) + 3, distance: 1 + ((b & 0x7F) | ((b1 & 0xE0) << 2)))
                } else if b & 0x40 == 0 {
                    census.b += 1
                    let b1 = try byte(i + 1), b2 = try byte(i + 2)
                    i += 3
                    try literals(b2 & 3)
                    try match(length: (b1 & 0x1F) + 3,
                              distance: 1 + (((b2 & 0xFC) << 7) | (b & 0x3F) | ((b1 & 0xE0) << 1)))
                } else if b & 0x20 == 0 {
                    let n: Int
                    if b & 0x10 == 0 { census.c += 1; n = ((b & 0xF) + 1) * 4 } else { census.d += 1; n = b & 0xF }
                    i += 1
                    try literals(n)
                } else if b & 0x10 == 0 {
                    census.e += 1
                    let v = try byte(i + 1)
                    i += 2
                    out.append(contentsOf: repeatElement(UInt8(v), count: (b & 0xF) + 3))
                } else if b & 0x08 == 0 {
                    census.f += 1
                    let n = try byte(i + 1), v = try byte(i + 2)
                    i += 3
                    out.append(contentsOf: repeatElement(UInt8(v), count: n + 3))
                } else {
                    census.end += 1
                    return (out, i + 1)
                }
            }
        }
    }
}
