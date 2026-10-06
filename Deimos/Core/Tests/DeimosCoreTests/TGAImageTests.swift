import XCTest
import HectorResources
@testable import DeimosCore

/// Builds a TGA in the shipped shape (type 2, 16 bpp, descriptor attribute bits 1) with the given
/// stored rows; `descriptor` and the other header bytes can be overridden for refusal tests.
private func makeTGA(width: Int, height: Int, storedRows: [[UInt16]],
                     imageType: UInt8 = 2, bpp: UInt8 = 16, descriptor: UInt8 = 0x01,
                     colorMapType: UInt8 = 0, colorMapSpec: [UInt8] = [0, 0, 0, 0, 0],
                     idField: [UInt8] = [], trailer: [UInt8] = []) -> Data {
    var b: [UInt8] = [UInt8(idField.count), colorMapType, imageType]
    b += colorMapSpec
    b += [0, 0, 0, 0]                                            // x/y origin
    b += [UInt8(width & 0xff), UInt8(width >> 8), UInt8(height & 0xff), UInt8(height >> 8)]
    b += [bpp, descriptor]
    b += idField
    for row in storedRows { for p in row { b += [UInt8(p & 0xff), UInt8(p >> 8)] } }
    b += trailer
    return Data(b)
}

final class TGAImageTests: XCTestCase {

    func testSyntheticBottomUpFlippedTopDownStays() throws {
        let stored: [[UInt16]] = [[0x0001, 0x0002, 0x0003], [0x0004, 0x0005, 0x0006]]
        // Bit 5 clear (the shipped 0x01): stored first row is the visual bottom → flipped.
        let footer = Array("TRUEVISION-XFILE.\0".utf8)
        let up = try TGAImage(data: makeTGA(width: 3, height: 2, storedRows: stored,
                                            colorMapSpec: [0, 0, 0, 0, 0x18],          // delta 3: stray byte, map type 0
                                            idField: [0xAA, 0xBB], trailer: [UInt8](repeating: 0, count: 8) + footer))
        XCTAssertEqual(up.width, 3)
        XCTAssertEqual(up.height, 2)
        XCTAssertEqual(up.pixels, [0x0004, 0x0005, 0x0006, 0x0001, 0x0002, 0x0003])
        // Bit 5 set: already top-down → stays.
        let down = try TGAImage(data: makeTGA(width: 3, height: 2, storedRows: stored, descriptor: 0x21))
        XCTAssertEqual(down.pixels, [0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006])
        // Bit 15 (the A1 attribute bit) is cleared → QuickDraw x1R5G5B5.
        let alpha = try TGAImage(data: makeTGA(width: 1, height: 1, storedRows: [[0xFFFF]]))
        XCTAssertEqual(alpha.pixels, [0x7FFF])
        // A slice with a non-zero startIndex decodes the same.
        let padded = Data([9, 9, 9]) + makeTGA(width: 3, height: 2, storedRows: stored)
        XCTAssertEqual(try TGAImage(data: padded.dropFirst(3)), up)
    }

    func testRefusals() {
        let one: [[UInt16]] = [[0x1234]]
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 1, height: 1, storedRows: one, imageType: 10))) {
            XCTAssertEqual($0 as? TGAError, .unsupportedImageType(10))
        }
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 1, height: 1, storedRows: [[0x3412, 0x0056]], bpp: 24))) {
            XCTAssertEqual($0 as? TGAError, .unsupportedPixelDepth(24))
        }
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 1, height: 1, storedRows: one, descriptor: 0x11))) {
            XCTAssertEqual($0 as? TGAError, .rightToLeft)
        }
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 1, height: 1, storedRows: one, colorMapType: 1))) {
            XCTAssertEqual($0 as? TGAError, .unsupportedColorMapType(1))
        }
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 1, height: 1, storedRows: one, descriptor: 0x41))) {
            XCTAssertEqual($0 as? TGAError, .unsupportedInterleave(0x41))
        }
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 1, height: 1, storedRows: one, descriptor: 0x08))) {
            XCTAssertEqual($0 as? TGAError, .unsupportedAttributeBits(8))
        }
        XCTAssertNoThrow(try TGAImage(data: makeTGA(width: 1, height: 1, storedRows: one, descriptor: 0x00)))
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 0, height: 4, storedRows: []))) {
            XCTAssertEqual($0 as? TGAError, .emptyImage(width: 0, height: 4))
        }
        // Truncated pixels: 2×2 needs 18 + 8 bytes; one row short.
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 2, height: 2, storedRows: [[1, 2]]))) {
            XCTAssertEqual($0 as? TGAError, .truncatedPixels(needed: 26, available: 22))
        }
        // Truncated header; ID field running past the end; a huge declared size never allocates.
        XCTAssertThrowsError(try TGAImage(data: Data([0, 0, 2]))) {
            XCTAssertEqual($0 as? TGAError, .truncatedHeader(3))
        }
        XCTAssertThrowsError(try TGAImage(data: makeTGA(width: 0xFFFF, height: 0xFFFF, storedRows: one,
                                                        idField: [1, 2, 3]))) {
            XCTAssertEqual($0 as? TGAError, .truncatedPixels(needed: 18 + 3 + 2 * 0xFFFF * 0xFFFF, available: 23))
        }
    }

    // MARK: - Real data (the committed Resources/Deimos/Data; never skips)

    func testAll45DecodeToCensusSizes() throws {
        let all = try ShippedTGAs.all()
        XCTAssertEqual(all.count, 45)
        var sizes: [String: Int] = [:]
        var footers = 0, strayMapSpec = 0
        for t in all {
            sizes["\(t.image.width)x\(t.image.height)", default: 0] += 1
            let body = 18 + 2 * t.image.width * t.image.height          // idLen 0 in all 45
            if t.bytes.count == body + 26 {
                footers += 1
                XCTAssertEqual(Array(t.bytes.suffix(18)), Array("TRUEVISION-XFILE.\0".utf8), t.name)
            } else {
                XCTAssertEqual(t.bytes.count, body, t.name)
            }
            // Raw header: type 2, map type 0, 16 bpp, descriptor 0x01 (bit 5 clear = bottom-up rows).
            XCTAssertEqual(t.bytes[0..<3].map { $0 }, [0, 0, 2], t.name)
            XCTAssertEqual(t.bytes[16], 16, t.name)
            XCTAssertEqual(t.bytes[17], 0x01, t.name)
            if t.bytes[7] == 0x18 { strayMapSpec += 1 }                 // Known delta 3
            // No stored pixel has bit 15 set (so clearing it loses nothing).
            let raw = t.bytes.dropFirst(18).prefix(2 * t.image.width * t.image.height)
            var bit15 = 0
            var i = raw.startIndex + 1
            while i < raw.endIndex { if raw[i] & 0x80 != 0 { bit15 += 1 }; i += 2 }
            XCTAssertEqual(bit15, 0, t.name)
        }
        XCTAssertEqual(sizes, ["480x3600": 12, "96x720": 12, "146x306": 12, "640x480": 5,
                               "160x480": 1, "112x480": 1, "260x342": 1, "284x173": 1])
        XCTAssertEqual(footers, 14)
        XCTAssertEqual(strayMapSpec, 18)
    }

    func testMediaMaskCensus() throws {
        let masks = try ShippedTGAs.all().filter { $0.name.hasSuffix(" Media") }
        XCTAssertEqual(masks.count, 12)
        var water = 0, land = 0
        var other: [String] = []
        for m in masks {
            XCTAssertEqual(m.image.width, 96)
            XCTAssertEqual(m.image.height, 720)
            for (i, p) in m.image.pixels.enumerated() {
                switch p {
                case 0x7FFF: land += 1
                case 0x001F: water += 1
                default: other.append("\(m.id) \(String(p, radix: 16)) x\(i % 96) y\(i / 96)")
                }
            }
        }
        XCTAssertEqual(land + water + other.count, 829_440)
        XCTAssertEqual(land, 712_245)
        XCTAssertEqual(water, 117_194)
        // The one stray pixel is in Industrial 3 Media [int3] (plan note 19 says `ist3`; the bytes say int3),
        // stored row 367 → top-down row 352.
        XCTAssertEqual(other, ["int3 256b x32 y352"])
    }

    func testCanyon1MaskOrientation() throws {
        let cat1 = try XCTUnwrap(try ShippedTGAs.all().first { $0.id == "cat1" }).image
        let rows = (0..<cat1.height).filter { cat1.pixels[$0 * cat1.width + 5] == 0x001F }
        // Stored (file-order) water rows in column 5 are 371–389 and 600–633 (bank §6.3); top-down
        // (h − 1 − stored) they are 330–348 and 86–119.
        XCTAssertEqual(rows, Array(86...119) + Array(330...348))
    }

    func testBackgroundRectMatchesMaps() throws {
        let index = try RealData.index()
        let images = Dictionary(uniqueKeysWithValues: try ShippedTGAs.all().map { ($0.id, $0.image) })
        let levels = index.records(ofType: FourCC("leve")!)
        XCTAssertEqual(levels.count, 12)
        var maps = Set<String>()
        for level in levels {
            let text = try LeveKeys(index.data(for: level))
            // #background_RECT is text order (left, top, right, bottom).
            XCTAssertEqual(text["background_RECT"], "0, 0, 480, 3600", "\(level.id)")
            let mapID = try XCTUnwrap(text["backgroundImage_ID"]), maskID = try XCTUnwrap(text["mediaMask_ID"])
            let map = try XCTUnwrap(images[mapID], mapID), mask = try XCTUnwrap(images[maskID], maskID)
            XCTAssertEqual([map.width, map.height], [480, 3600], mapID)
            // The mask lookup reads mask[y/5][x/5] (bank §6.2): same aspect, ratio 5 on both axes.
            XCTAssertEqual([map.width, map.height], [mask.width * 5, mask.height * 5], maskID)
            maps.insert(mapID)
        }
        XCTAssertEqual(maps.count, 12)
    }

    func testMenuFirstStoredRowIsBottom() throws {
        let menu = try XCTUnwrap(try ShippedTGAs.all().first { $0.id == "menu" })
        let w = menu.image.width, h = menu.image.height
        XCTAssertEqual([w, h], [640, 480])
        func storedRow(_ r: Int) -> [UInt16] {
            (0..<w).map { x in
                let o = menu.bytes.startIndex + 18 + 2 * (r * w + x)
                return (UInt16(menu.bytes[o]) | UInt16(menu.bytes[o + 1]) << 8) & 0x7FFF
            }
        }
        XCTAssertEqual(storedRow(0), Array(menu.image.pixels[(h - 1) * w ..< h * w]))
        XCTAssertEqual(storedRow(h - 1), Array(menu.image.pixels[0 ..< w]))
        XCTAssertNotEqual(storedRow(0), storedRow(h - 1))   // the check is not vacuous
    }
}

/// The 45 shipped `im16` tags, decoded once for the suite.
private enum ShippedTGAs {
    struct Entry: Sendable { let id: String; let name: String; let bytes: Data; let image: TGAImage }
    static let loaded: Result<[Entry], Error> = Result {
        let index = try RealData.index()
        return try index.records(ofType: FourCC("im16")!).map { r in
            let bytes = try index.data(for: r)
            return Entry(id: r.id.description, name: r.displayName, bytes: bytes, image: try TGAImage(data: bytes))
        }
    }
    static func all() throws -> [Entry] { try loaded.get() }
}

/// Test-local reader for a level's header keys: de-obfuscates (`~rotl8(c, 4)`, bank pak-format §3) and
/// takes the first `#key <value>` per key. Enough for the TGA cross-check without the C2/C3 parsers.
private struct LeveKeys {
    private var values: [String: String] = [:]
    init(_ data: Data) throws {
        let plain = data.map { ~(($0 << 4) | ($0 >> 4)) }
        let text = MacRoman.decode(Array(plain))
        for item in text.split(separator: "#").dropFirst() {
            guard let lt = item.firstIndex(of: "<"), let gt = item[lt...].firstIndex(of: ">") else { continue }
            let key = item[..<lt].trimmingCharacters(in: .whitespacesAndNewlines)
            if values[key] == nil { values[key] = String(item[item.index(after: lt)..<gt]) }
        }
    }
    subscript(_ key: String) -> String? { values[key] }
}
