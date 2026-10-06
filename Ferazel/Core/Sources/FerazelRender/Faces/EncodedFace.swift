import Foundation

public enum FaceDecodeError: Error, Equatable {
    /// A token whose op is ≥ 4 (`DebugStr "Encountered a bad token in sprite RLE data!"`, sprites-backgrounds §2.2;
    /// plan invariant 6). `offset` is the token's byte offset in `EncodedFace.data`.
    case badToken(op: Int, offset: Int)
    /// The stream ends before an end token, a literal, or a token's 4 bytes.
    case truncated(offset: Int)
    /// A run reaches past the face's frame, a copy/skip comes before the first row token, or a row token's
    /// length disagrees with the bytes that follow it.
    case malformed(offset: Int, String)
}

/// One face: the 0x34-byte face record of sprites-backgrounds §2.1 (the fields the replica uses) and the RLE
/// token stream of §2.2 that `.EncodeRect @ 1002dd70` writes and ~60 blitters read.
///
/// Record: `+0x00` frame rect (0,0,h,w) · `+0x08` tight bounds of the opaque pixels (top, left−1, bottom+1,
/// right+2; top and left clamped ≥ 0) · `+0x10` the encoded data handle (here `data`, the tokens from the
/// handle's `+0x10`; the handle's own `+0x00`/`+0x08` repeat frame and bounds) · `+0x14` mask region (only for
/// faces in `[maskFirst, maskLast]`; not modelled — no Phase-1 sheet asks for one) · `+0x18` 1 if any pixel 0 was
/// seen · `+0x1a`, `+0x1e` 0 · `+0x1c` 0x100 · `+0x20..0x2c` 0 · `+0x30` source PICT id.
public struct EncodedFace: Sendable, Equatable {
    /// A QuickDraw `Rect` (top, left, bottom, right).
    public struct Rect: Hashable, Sendable {
        public var top: Int16
        public var left: Int16
        public var bottom: Int16
        public var right: Int16

        public init(top: Int16, left: Int16, bottom: Int16, right: Int16) {
            self.top = top; self.left = left; self.bottom = bottom; self.right = right
        }
    }

    /// One token of the stream (big-endian u32: op = t >> 24, n = t & 0xffffff).
    public enum Token: Equatable, Sendable {
        /// op 1: a new row; `length` = byte length of this row's tokens that follow.
        case row(length: Int)
        /// op 3: skip n pixels (transparent; pixel value 0).
        case skip(Int)
        /// op 2: copy n pixel bytes (stored after the token, padded to a 4-byte boundary).
        case copy([UInt8])
        /// op 0: end of face.
        case end
    }

    /// `+0x00`.
    public var frame: Rect
    /// `+0x08`.
    public var bounds: Rect
    /// The token stream (handle `+0x10` onward).
    public var data: [UInt8]
    /// `+0x18`.
    public var hasTransparentPixel: Bool
    /// `+0x1c` (0x100 on every loader path) [MED: meaning].
    public var scale: Int16
    /// `+0x30`.
    public var sourceId: Int16

    public init(frame: Rect, bounds: Rect, data: [UInt8], hasTransparentPixel: Bool, scale: Int16 = 0x100,
                sourceId: Int16) {
        self.frame = frame; self.bounds = bounds; self.data = data
        self.hasTransparentPixel = hasTransparentPixel; self.scale = scale; self.sourceId = sourceId
    }

    /// `+6` (frame right − left).
    public var width: Int { Int(frame.right) - Int(frame.left) }
    /// `+4` (frame bottom − top).
    public var height: Int { Int(frame.bottom) - Int(frame.top) }

    /// The stream parsed to its end token. Refuses op ≥ 4.
    public func tokens() throws -> [Token] {
        var out: [Token] = []
        try walk { out.append($0) }
        return out
    }

    /// The face's `width × height` indices, row-major: copied bytes where the tokens put them, 0 elsewhere
    /// (skips, the unwritten trailing skip of each row). Refuses op ≥ 4.
    public func decode() throws -> [UInt8] {
        let w = width, h = height
        var out = [UInt8](repeating: 0, count: max(0, w) * max(0, h))
        var row = -1, x = 0
        var offset = 0
        try walk(position: { offset = $0 }) { token in
            switch token {
            case .row:
                row += 1; x = 0
                guard row < h else { throw FaceDecodeError.malformed(offset: offset, "row \(row) past height \(h)") }
            case .skip(let n):
                guard row >= 0 else { throw FaceDecodeError.malformed(offset: offset, "skip before a row") }
                x += n
                guard x <= w else { throw FaceDecodeError.malformed(offset: offset, "skip past width") }
            case .copy(let bytes):
                guard row >= 0 else { throw FaceDecodeError.malformed(offset: offset, "copy before a row") }
                guard x + bytes.count <= w else { throw FaceDecodeError.malformed(offset: offset, "copy past width") }
                for (k, b) in bytes.enumerated() { out[row * w + x + k] = b }
                x += bytes.count
            case .end:
                break
            }
        }
        return out
    }

    /// Walks the stream as the blitters do: u32 tokens; a copy's bytes follow it, padded to 4. Checks each row
    /// token's length against the bytes up to the next row/end token. Stops after the end token.
    func walk(position: (Int) -> Void = { _ in }, _ body: (Token) throws -> Void) throws {
        var p = 0
        var rowStart = -1, rowLength = 0
        func closeRow(at q: Int) throws {
            if rowStart >= 0, q - rowStart != rowLength {
                throw FaceDecodeError.malformed(offset: rowStart - 4, "row length \(rowLength) ≠ \(q - rowStart)")
            }
        }
        while true {
            guard p + 4 <= data.count else { throw FaceDecodeError.truncated(offset: p) }
            let t = UInt32(data[p]) << 24 | UInt32(data[p + 1]) << 16 | UInt32(data[p + 2]) << 8 | UInt32(data[p + 3])
            let op = Int(t >> 24), n = Int(t & 0xffffff)
            let at = p
            position(at)
            p += 4
            switch op {
            case 0:
                try closeRow(at: at)
                try body(.end)
                return
            case 1:
                try closeRow(at: at)
                rowStart = p; rowLength = n
                try body(.row(length: n))
            case 2:
                let padded = n + (n & 3 == 0 ? 0 : 4 - (n & 3))
                guard p + padded <= data.count else { throw FaceDecodeError.truncated(offset: at) }
                try body(.copy(Array(data[p ..< p + n])))
                p += padded
            case 3:
                try body(.skip(n))
            default:
                throw FaceDecodeError.badToken(op: op, offset: at)
            }
        }
    }
}
