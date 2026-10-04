import Foundation

/// A QuickDraw colour cursor (`'crsr'`, `CCrsr`) decoded to a 16 × 16 straight-alpha image and its hot spot — the
/// hand `crsr 200` that `_LoadHandCursor @ 00025af8` loads (`GetCCursor(200)`) and `_SetMyCCursor(200) @ 00025b1d`
/// sets in the menus, dialogs and the pause (plan Q16: the kit has no `crsr` decoder; this one lives in Render).
///
/// Layout (Inside Macintosh: Imaging With QuickDraw, "CCrsr", handles flattened to offsets in the resource):
/// crsrType @0 (0x8001) · crsrMap @2 (offset of a 50-byte PixMap) · crsrData @6 (offset of the pixels) · crsrXData,
/// crsrXValid, crsrXHandle @10…19 · crsr1Data @18 (16 × 16 1-bit) · crsrMask @50 (16 × 16 1-bit) · crsrHotSpot @82
/// (v, h). The PixMap's pmTable field holds the offset of its ColorTable (seed, flags, ctSize, then
/// `ctSize + 1` × (value, r, g, b)). Indexed 1/2/4/8-bit pixels, most-significant bits first, looked up by value.
///
/// Mask 1 → the pixel's colour, opaque. Mask 0 → transparent; where the 1-bit data is also 1 QuickDraw inverts the
/// screen under the cursor — counted in `invertedPixels` (none in `crsr 200`) and drawn transparent (an `NSCursor`
/// cannot invert).
public struct ColorCursor: Sendable, Equatable {
    public enum DecodeError: Error, Equatable {
        case truncated
        case notAColourCursor(Int)
        case unsupported(String)
        case colorIndexMissing(Int)
    }

    /// 16 × 16, 0xAARRGGBB, alpha 0xFF (mask on) or the whole pixel 0 (mask off).
    public let image: RGBAImage
    /// The hot spot in image pixels.
    public let hotSpot: (h: Int, v: Int)
    public let pixelDepth: Int
    /// Mask-off pixels whose 1-bit data bit is set (QuickDraw's "invert under the cursor").
    public let invertedPixels: Int

    public static func == (a: ColorCursor, b: ColorCursor) -> Bool {
        a.image == b.image && a.hotSpot == b.hotSpot && a.pixelDepth == b.pixelDepth
            && a.invertedPixels == b.invertedPixels
    }

    public init(data: Data) throws {
        let b = [UInt8](data)
        func u16(_ o: Int) throws -> Int {
            guard o >= 0, o + 2 <= b.count else { throw DecodeError.truncated }
            return Int(b[o]) << 8 | Int(b[o + 1])
        }
        func i16(_ o: Int) throws -> Int { Int(Int16(bitPattern: UInt16(try u16(o)))) }
        func u32(_ o: Int) throws -> Int { try u16(o) << 16 | u16(o + 2) }
        func bit(_ o: Int, _ x: Int, _ y: Int) -> Int { Int(b[o + y * 2 + (x >> 3)] >> (7 - (x & 7))) & 1 }

        guard b.count >= 96 else { throw DecodeError.truncated }
        let type = try u16(0)
        guard type == 0x8001 else { throw DecodeError.notAColourCursor(type) }
        let map = try u32(2), pixels = try u32(6)
        let hotV = try i16(82), hotH = try i16(84)

        // PixMap: rowBytes @4 (bit 15 = PixMap), bounds @6, pixelType @30, pixelSize @32, cmpCount @34, pmTable @42.
        let rowBytesField = try u16(map + 4)
        guard rowBytesField & 0x8000 != 0 else { throw DecodeError.unsupported("rowBytes") }
        let rowBytes = rowBytesField & 0x3FFF
        let top = try i16(map + 6), left = try i16(map + 8), bottom = try i16(map + 10), right = try i16(map + 12)
        guard bottom - top == 16, right - left == 16 else { throw DecodeError.unsupported("bounds") }
        let depth = try u16(map + 32)
        guard [1, 2, 4, 8].contains(depth), try u16(map + 30) == 0, try u16(map + 34) == 1 else {
            throw DecodeError.unsupported("pixelSize \(depth)")
        }
        guard rowBytes * 8 >= 16 * depth else { throw DecodeError.unsupported("rowBytes") }
        let table = try u32(map + 42)
        let entries = try i16(table + 6) + 1
        guard entries > 0, table + 8 + entries * 8 <= b.count else { throw DecodeError.truncated }
        var lookup: [Int: UInt32] = [:]
        for i in 0..<entries {
            let e = table + 8 + i * 8
            let value = try u16(e)
            lookup[value] = 0xFF00_0000 | UInt32(b[e + 2]) << 16 | UInt32(b[e + 4]) << 8 | UInt32(b[e + 6])
        }
        guard pixels >= 0, pixels + rowBytes * 16 <= b.count else { throw DecodeError.truncated }

        var image = RGBAImage(width: 16, height: 16, fill: 0)
        var inverted = 0
        for y in 0..<16 {
            for x in 0..<16 {
                guard bit(50, x, y) == 1 else {
                    inverted += bit(18, x, y)
                    continue
                }
                let bitOffset = x * depth
                let byte = Int(b[pixels + y * rowBytes + bitOffset / 8])
                let index = (byte >> (8 - depth - bitOffset % 8)) & ((1 << depth) - 1)
                guard let rgb = lookup[index] else { throw DecodeError.colorIndexMissing(index) }
                image[x, y] = rgb
            }
        }
        self.image = image
        hotSpot = (hotH, hotV)
        pixelDepth = depth
        invertedPixels = inverted
    }
}
