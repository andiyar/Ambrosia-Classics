import Foundation

/// Why a GIF (`im08`) was refused. Every refused feature is one the 250 shipped plates never use
/// (plan Research note 16: all `GIF89a`, global table, one full-screen image at (0,0), no local
/// table, no interlace, one GCE with transparency off, LZW minimum code size 8) — plan invariant 4.
public enum GIFError: Error, Equatable, Sendable {
    /// Not `GIF87a` / `GIF89a`.
    case notGIF
    /// The data ends inside the named structure.
    case truncated(String)
    /// No global colour table (the plates' palettes are global; QuickTime would use a default).
    case noGlobalColorTable
    /// A block introducer other than image (`0x2C`), extension (`0x21`) or trailer (`0x3B`).
    case unknownBlock(UInt8)
    /// Graphic Control Extension with the transparency flag set.
    case transparency
    /// The image descriptor carries a local colour table.
    case localColorTable
    /// The image is interlaced.
    case interlaced
    /// The image is not at (0,0) with the logical screen's size.
    case imageNotFullScreen(left: Int, top: Int, width: Int, height: Int)
    /// Zero width or height.
    case emptyImage(width: Int, height: Int)
    /// A second image descriptor.
    case secondImage
    /// No image descriptor before the trailer.
    case noImage
    /// LZW minimum code size outside 2…8.
    case badMinimumCodeSize(UInt8)
    /// An LZW code that is neither in the table nor the next free code.
    case invalidCode(Int)
    /// The LZW stream ended (end code or data) before `width × height` pixels.
    case truncatedLZW(decoded: Int, expected: Int)
    /// The LZW stream produced more than `width × height` pixels.
    case excessLZW
    /// A pixel index at or above the palette's entry count.
    case indexOutOfPalette(index: UInt8, paletteCount: Int)
}

/// An `im08` tag: a GIF decoded to palette indices, the way the original's QuickTime `'GIF '`
/// graphics importer saw it (sprite-sound-containers.md §1–§2; plan Research notes 15–16).
///
/// The decoder is a textbook GIF reader restricted to what the census shows: one image, global
/// palette only, no interlace, no transparency. Colour conversion is not done here — the original
/// drew the same file into an 8-bit GWorld (alpha-plate scan, `QuickDrawColor.systemIndex`) and into
/// 16-bit GWorlds (`QuickDrawColor.rgb555`); `SpriteGroup` applies both.
///
/// LZW: minimum code size 2–8, clear and end codes, code width grows to a 12-bit cap; when the
/// table is full the decoder keeps reading 12-bit codes without adding entries until a clear
/// ("deferred clear"). Data sub-blocks are bounds-checked; the stream must yield exactly
/// `width × height` pixels (fewer → `truncatedLZW`, more → `excessLZW`); codes after the last pixel
/// other than the end code are refused the same way.
public struct GIFImage: Sendable {
    public let width: Int
    public let height: Int
    /// The global colour table (2…256 entries, as declared by the header).
    public let palette: [(r: UInt8, g: UInt8, b: UInt8)]
    /// `width × height` palette indices, row-major, row 0 = top.
    public let indices: [UInt8]

    public init(data: Data) throws {
        let bytes = [UInt8](data)
        var pos = 0
        func need(_ n: Int, _ what: String) throws {
            guard n >= 0, pos + n <= bytes.count else { throw GIFError.truncated(what) }
        }
        func le16(_ i: Int) -> Int { Int(bytes[i]) | Int(bytes[i + 1]) << 8 }

        // Header + logical screen descriptor.
        try need(13, "header")
        let magic = Array(bytes[0..<6])
        guard magic == Array("GIF89a".utf8) || magic == Array("GIF87a".utf8) else { throw GIFError.notGIF }
        let screenW = le16(6), screenH = le16(8)
        let flags = bytes[10]
        pos = 13
        guard flags & 0x80 != 0 else { throw GIFError.noGlobalColorTable }
        let paletteCount = 1 << (Int(flags & 0x07) + 1)
        try need(3 * paletteCount, "global colour table")
        var pal: [(r: UInt8, g: UInt8, b: UInt8)] = []
        pal.reserveCapacity(paletteCount)
        for i in 0..<paletteCount {
            pal.append((bytes[pos + 3 * i], bytes[pos + 3 * i + 1], bytes[pos + 3 * i + 2]))
        }
        pos += 3 * paletteCount

        // Concatenates data sub-blocks up to the zero-length terminator.
        func subBlocks(_ what: String) throws -> [UInt8] {
            var out: [UInt8] = []
            while true {
                try need(1, what)
                let n = Int(bytes[pos]); pos += 1
                if n == 0 { return out }
                try need(n, what)
                out.append(contentsOf: bytes[pos..<(pos + n)])
                pos += n
            }
        }

        var image: (w: Int, h: Int, indices: [UInt8])?
        blocks: while true {
            try need(1, "block introducer")
            let introducer = bytes[pos]; pos += 1
            switch introducer {
            case 0x3B:
                break blocks
            case 0x21:
                try need(1, "extension label")
                let label = bytes[pos]; pos += 1
                let body = try subBlocks("extension")
                if label == 0xF9, let packed = body.first, packed & 0x01 != 0 {
                    throw GIFError.transparency
                }
            case 0x2C:
                guard image == nil else { throw GIFError.secondImage }
                try need(9, "image descriptor")
                let left = le16(pos), top = le16(pos + 2), w = le16(pos + 4), h = le16(pos + 6)
                let imageFlags = bytes[pos + 8]
                pos += 9
                guard imageFlags & 0x80 == 0 else { throw GIFError.localColorTable }
                guard imageFlags & 0x40 == 0 else { throw GIFError.interlaced }
                guard left == 0, top == 0, w == screenW, h == screenH else {
                    throw GIFError.imageNotFullScreen(left: left, top: top, width: w, height: h)
                }
                guard w > 0, h > 0 else { throw GIFError.emptyImage(width: w, height: h) }
                try need(1, "LZW minimum code size")
                let minCodeSize = bytes[pos]; pos += 1
                guard (2...8).contains(minCodeSize) else { throw GIFError.badMinimumCodeSize(minCodeSize) }
                let stream = try subBlocks("image data")
                let out = try Self.lzwDecode(stream, minCodeSize: Int(minCodeSize), pixelCount: w * h)
                image = (w, h, out)
            default:
                throw GIFError.unknownBlock(introducer)
            }
        }
        guard let image else { throw GIFError.noImage }
        for i in image.indices where Int(i) >= paletteCount {
            throw GIFError.indexOutOfPalette(index: i, paletteCount: paletteCount)
        }
        width = image.w
        height = image.h
        palette = pal
        indices = image.indices
    }

    /// GIF variable-width LZW (LSB-first codes). `pixelCount` is the exact expected output size.
    static func lzwDecode(_ stream: [UInt8], minCodeSize: Int, pixelCount: Int) throws -> [UInt8] {
        let clear = 1 << minCodeSize, end = clear + 1
        var prefix = [Int](repeating: -1, count: 4096)
        var suffix = [UInt8](repeating: 0, count: 4096)
        var first = [UInt8](repeating: 0, count: 4096)
        for i in 0..<clear { suffix[i] = UInt8(i); first[i] = UInt8(i) }
        var next = end + 1
        var codeSize = minCodeSize + 1
        var prev = -1
        var out = [UInt8](repeating: 0, count: pixelCount)
        var outCount = 0
        var stack = [UInt8](repeating: 0, count: 4096)

        var bytePos = 0
        var acc: UInt32 = 0, accBits = 0
        func readCode() -> Int? {
            while accBits < codeSize {
                guard bytePos < stream.count else { return nil }
                acc |= UInt32(stream[bytePos]) << UInt32(accBits)
                bytePos += 1
                accBits += 8
            }
            let code = Int(acc & ((1 << UInt32(codeSize)) - 1))
            acc >>= UInt32(codeSize)
            accBits -= codeSize
            return code
        }

        while true {
            guard let code = readCode() else {
                throw GIFError.truncatedLZW(decoded: outCount, expected: pixelCount)
            }
            if code == clear {
                next = end + 1
                codeSize = minCodeSize + 1
                prev = -1
                continue
            }
            if code == end { break }

            // Resolve the string for `code` (pushed in reverse onto `stack`).
            var depth = 0
            if prev == -1 {
                guard code < clear else { throw GIFError.invalidCode(code) }
                stack[0] = UInt8(code); depth = 1
            } else if code < next {
                var c = code
                while c >= clear { stack[depth] = suffix[c]; depth += 1; c = prefix[c] }
                stack[depth] = UInt8(c); depth += 1
                if next < 4096 {
                    prefix[next] = prev; suffix[next] = first[code]; first[next] = first[prev]; next += 1
                }
            } else if code == next && next < 4096 {
                prefix[next] = prev; suffix[next] = first[prev]; first[next] = first[prev]; next += 1
                var c = code
                while c >= clear { stack[depth] = suffix[c]; depth += 1; c = prefix[c] }
                stack[depth] = UInt8(c); depth += 1
            } else {
                throw GIFError.invalidCode(code)
            }
            guard outCount + depth <= pixelCount else { throw GIFError.excessLZW }
            while depth > 0 { depth -= 1; out[outCount] = stack[depth]; outCount += 1 }
            if next == 1 << codeSize && codeSize < 12 { codeSize += 1 }
            prev = code
        }
        guard outCount == pixelCount else { throw GIFError.truncatedLZW(decoded: outCount, expected: pixelCount) }
        return out
    }
}
