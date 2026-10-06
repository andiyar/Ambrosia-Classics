import XCTest
import HectorResources
@testable import DeimosCore

/// Test-side GIF writer: the shipped shape (GIF89a, global table, one GCE, one full-screen image),
/// with every field overridable for refusal tests. `lzw` is an independent GIF LZW encoder (clear
/// first, end last, no clears when the table fills — the decoder's "deferred clear" path); its
/// width rule was checked against Pillow on the 4×4 vector below and a 128×128 12-bit fill.
enum GIFFixture {
    static func lzw(_ indices: [UInt8], minCodeSize mcs: Int) -> [UInt8] {
        let clear = 1 << mcs, end = clear + 1
        var next = end + 1, width = mcs + 1
        var table: [Int: Int] = [:]                      // (prefixCode << 8 | k) → code
        var acc = 0, accBits = 0
        var out: [UInt8] = []
        func emit(_ code: Int) {
            acc |= code << accBits; accBits += width
            while accBits >= 8 { out.append(UInt8(acc & 0xFF)); acc >>= 8; accBits -= 8 }
        }
        emit(clear)
        var w = -1
        for k in indices.map(Int.init) {
            if w < 0 { w = k; continue }
            if let c = table[w << 8 | k] { w = c; continue }
            emit(w)
            if next < 4096 { table[w << 8 | k] = next; next += 1 }
            w = k
            if next > 1 << width && width < 12 { width += 1 }
        }
        if w >= 0 { emit(w) }
        emit(end)
        if accBits > 0 { out.append(UInt8(acc & 0xFF)) }
        return out
    }

    static func gif(width: Int, height: Int, palette: [(UInt8, UInt8, UInt8)], indices: [UInt8],
                    minCodeSize: Int = 8, lct: Bool = false, interlace: Bool = false, gceFlags: UInt8 = 0,
                    imageOrigin: (Int, Int) = (0, 0), imageSize: (Int, Int)? = nil, secondImage: Bool = false,
                    lzwData: [UInt8]? = nil) -> Data {
        func le(_ v: Int) -> [UInt8] { [UInt8(v & 0xFF), UInt8(v >> 8 & 0xFF)] }
        var sz = 1
        while 1 << sz < palette.count { sz += 1 }
        var b = Array("GIF89a".utf8) + le(width) + le(height) + [0x80 | UInt8(sz - 1), 0, 0]
        for i in 0..<(1 << sz) {
            let c = i < palette.count ? palette[i] : (0, 0, 0)
            b += [c.0, c.1, c.2]
        }
        b += [0x21, 0xF9, 0x04, gceFlags, 0, 0, 0, 0]
        let data = lzwData ?? lzw(indices, minCodeSize: minCodeSize)
        func image() -> [UInt8] {
            let (iw, ih) = imageSize ?? (width, height)
            var flags: UInt8 = 0
            if lct { flags |= 0x80 }
            if interlace { flags |= 0x40 }
            var r: [UInt8] = [0x2C] + le(imageOrigin.0) + le(imageOrigin.1) + le(iw) + le(ih) + [flags]
            if lct { r += [UInt8](repeating: 0, count: 6) }
            r.append(UInt8(minCodeSize))
            var i = 0
            while i < data.count {
                let n = min(255, data.count - i)
                r.append(UInt8(n)); r += data[i..<(i + n)]; i += n
            }
            return r + [0]
        }
        b += image()
        if secondImage { b += image() }
        b.append(0x3B)
        return Data(b)
    }
}

final class GIFImageTests: XCTestCase {

    func testSyntheticLZWVectors() throws {
        // 4×4, min code size 2: clear 4, end 5, widths 3 → 4 → 5. Bytes from an independent Python
        // encoder, decoded identically by Pillow.
        let hex = "47494638396104000400810000ff000000ff000000ffffffff21f90400000000002c0000000004000400000208841119c232134001003b"
        let bytes = stride(from: 0, to: hex.count, by: 2).map { i -> UInt8 in
            let s = hex.index(hex.startIndex, offsetBy: i)
            return UInt8(hex[s..<hex.index(s, offsetBy: 2)], radix: 16)!
        }
        let g = try GIFImage(data: Data(bytes))
        XCTAssertEqual([g.width, g.height], [4, 4])
        XCTAssertEqual(g.indices, [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 1, 0])
        XCTAssertEqual(g.palette.count, 4)
        XCTAssertEqual([g.palette[2].r, g.palette[2].g, g.palette[2].b], [0, 0, 255])
        // A slice with a non-zero startIndex decodes the same.
        XCTAssertEqual(try GIFImage(data: (Data([1, 2, 3]) + Data(bytes)).dropFirst(3)).indices, g.indices)

        // 128×128 LCG noise, min code size 8: the table fills (4096) and the stream keeps 12-bit codes
        // without a clear (13,788 of 15,580 codes are 12-bit — Pillow agrees).
        var x: UInt32 = 12345
        var noise: [UInt8] = []
        for _ in 0..<(128 * 128) {
            x = (x &* 1_103_515_245 &+ 12345) & 0x7FFF_FFFF
            noise.append(UInt8(x >> 16 & 0xFF))
        }
        let pal = (0..<256).map { (UInt8($0), UInt8($0), UInt8($0)) }
        let n = try GIFImage(data: GIFFixture.gif(width: 128, height: 128, palette: pal, indices: noise))
        XCTAssertEqual(n.indices, noise)
        // Round trip at every legal minimum code size.
        for mcs in 2...8 {
            let count = 1 << mcs
            let idx = (0..<300).map { UInt8(($0 * 7 + $0 / 13) % count) }
            let p = (0..<count).map { (UInt8($0), UInt8(0), UInt8(0)) }
            XCTAssertEqual(try GIFImage(data: GIFFixture.gif(width: 20, height: 15, palette: p, indices: idx,
                                                             minCodeSize: mcs)).indices, idx, "mcs \(mcs)")
        }
    }

    func testRefusals() {
        let pal: [(UInt8, UInt8, UInt8)] = [(0, 0, 0), (255, 255, 255), (255, 0, 0)]   // 4-entry table
        let idx: [UInt8] = [0, 1, 2, 1]
        func expect(_ d: Data, _ e: GIFError, line: UInt = #line) {
            XCTAssertThrowsError(try GIFImage(data: d), line: line) { XCTAssertEqual($0 as? GIFError, e, line: line) }
        }
        XCTAssertNoThrow(try GIFImage(data: GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx)))
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx, lct: true), .localColorTable)
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx, interlace: true), .interlaced)
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx, gceFlags: 0x01), .transparency)
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx, imageOrigin: (1, 0)),
               .imageNotFullScreen(left: 1, top: 0, width: 2, height: 2))
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: [0], imageSize: (1, 1)),
               .imageNotFullScreen(left: 0, top: 0, width: 1, height: 1))
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx, secondImage: true), .secondImage)
        // A 2-entry table with LZW min code size 2 can carry index 3.
        expect(GIFFixture.gif(width: 2, height: 2, palette: [(0, 0, 0), (255, 255, 255)], indices: [0, 1, 3, 1],
                              minCodeSize: 2), .indexOutOfPalette(index: 3, paletteCount: 2))
        // Truncated LZW: the end code arrives after 3 of 4 pixels; and a stream cut off mid-codes.
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx,
                              lzwData: GIFFixture.lzw([0, 1, 2], minCodeSize: 8)),
               .truncatedLZW(decoded: 3, expected: 4))
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx,
                              lzwData: Array(GIFFixture.lzw(idx, minCodeSize: 8).prefix(3))),
               .truncatedLZW(decoded: 1, expected: 4))
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx,
                              lzwData: GIFFixture.lzw(idx + [0], minCodeSize: 8)), .excessLZW)
        // A first code that is not a literal; a code beyond the next free one.
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx, minCodeSize: 2,
                              lzwData: [0x04 | 0x07 << 3, 0x00]), .invalidCode(7))
        expect(GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx, minCodeSize: 9,
                              lzwData: []), .badMinimumCodeSize(9))
        // Header damage.
        expect(Data("GIF88a".utf8) + Data(repeating: 0, count: 20), .notGIF)
        expect(Data("GIF89a".utf8) + Data([2, 0, 2, 0, 0x00, 0, 0, 0x3B]), .noGlobalColorTable)
        let good = GIFFixture.gif(width: 2, height: 2, palette: pal, indices: idx)
        expect(good.prefix(good.count - 6), .truncated("image data"))
        expect(good.prefix(20), .truncated("global colour table"))
    }

    // MARK: - Real data

    func testAll250DecodeToHeaderSizes() throws {
        let index = try RealData.index()
        let records = index.records(ofType: FourCC("im08")!)
        XCTAssertEqual(records.count, 250)
        var maxW = 0, maxH = 0
        var paletteSizes: [Int: Int] = [:]
        for r in records {
            let d = try index.data(for: r)
            XCTAssertEqual(Array(d.prefix(6)), Array("GIF89a".utf8), r.displayName)
            let w = Int(d[6]) | Int(d[7]) << 8, h = Int(d[8]) | Int(d[9]) << 8
            let g = try GIFImage(data: d)
            XCTAssertEqual([g.width, g.height], [w, h], r.displayName)
            XCTAssertEqual(g.indices.count, w * h)
            XCTAssertEqual(d.last, 0x3B, r.displayName)
            // LZW minimum code size byte (right after the 10-byte image descriptor) is 8 in all 250.
            let imageStart = 13 + 3 * g.palette.count + 8           // header, table, one 8-byte GCE
            XCTAssertEqual(d[imageStart], 0x2C, r.displayName)
            XCTAssertEqual(d[imageStart + 10], 8, r.displayName)
            paletteSizes[g.palette.count, default: 0] += 1
            maxW = max(maxW, w); maxH = max(maxH, h)
        }
        XCTAssertEqual([maxW, maxH], [1400, 131])
        // Global table sizes (plan note 16 says "2–256"; the bytes say 8–256).
        XCTAssertEqual(paletteSizes, [8: 5, 16: 4, 32: 3, 64: 3, 256: 235])
    }

    func testBombCraterPlates() throws {
        let index = try RealData.index()
        let ic = try GIFImage(data: index.data(for: XCTUnwrap(index.record(type: FourCC("im08")!, id: FourCC("bocr")!))))
        let ia = try GIFImage(data: index.data(for: XCTUnwrap(index.record(type: FourCC("im08")!, id: FourCC("BOCR")!))))
        XCTAssertEqual([ic.width, ic.height], [55, 21])
        XCTAssertEqual([ia.width, ia.height], [55, 21])
        // Colour plate: 8 entries (flags 0xf2).
        XCTAssertEqual(ic.palette.map { [$0.r, $0.g, $0.b] },
                       [[0, 222, 0], [255, 0, 255], [0, 0, 255], [16, 16, 16], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]])
        // Alpha plate: 16 entries; 0 white, 8 (140,140,140), 9 magenta, 12 blue, 13 black.
        XCTAssertEqual(ia.palette.count, 16)
        for (i, c) in [(0, [255, 255, 255]), (8, [140, 140, 140]), (9, [255, 0, 255]), (12, [0, 0, 255]), (13, [0, 0, 0])] {
            XCTAssertEqual([Int(ia.palette[i].r), Int(ia.palette[i].g), Int(ia.palette[i].b)], c, "IA \(i)")
        }
        func row(_ y: Int) -> String { ic.indices[(y * 55)..<(y * 55 + 55)].map { String($0) }.joined() }
        XCTAssertEqual(row(0), "2102222222222222222222222222222222222222222222222222222")
        XCTAssertEqual(row(1), "1111111111111111111111111111111111111111111111111111111")
        XCTAssertEqual(row(2), "2122222222222222222212222222222222222212222222222222221")
        XCTAssertEqual(row(3), "2120000000033330000212000000330030000212222222222222221")
        XCTAssertEqual(row(4), "2120000033333330000212000000033333000212222222222222221")
        XCTAssertEqual(row(18), "2120000333330000000212000000000000000212000003300000021")
        XCTAssertEqual(row(19), "2122222222222222222212222222222222222212222222222222221")
        XCTAssertEqual(row(20), "1111111111111111111111111111111111111111111111111111111")
    }
}
