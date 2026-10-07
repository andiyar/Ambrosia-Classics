import XCTest
import CytheraCore
@testable import CytheraRender

/// C5 (docs/plans/2026-10-06-cythera-phase0.md): portraits, sky strips, pix images and macro icons of
/// data-format §1.5 / §6.2. Numbers: planner probes p03 / p04 (Research notes 3, 4, 6).
final class PixelSegmentTests: XCTestCase {

    private func segmentFile() throws -> SegmentFile {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try SegmentFile(contentsOf: r.segmentFileURL)
    }

    private func ids(_ file: SegmentFile, page: UInt16) -> [UInt16] {
        file.ids.filter { $0 >> 8 == page }
    }

    func testPortraits() throws {
        let file = try segmentFile()
        let present = ids(file, page: 0x88)
        XCTAssertEqual(present.count, 142)
        XCTAssertEqual(present.first, 0x8800)
        XCTAssertEqual(present.last, 0x88FA)
        XCTAssertEqual(0x88FA - 0x8800 + 1 - present.count, 109, "109 gaps (p03)")
        var zeros = 0, maxIndex: UInt8 = 0
        for p in 1...251 {
            let id = try Portrait.segmentID(p)
            XCTAssertEqual(Int(id), 0x87FF + p)
            guard present.contains(id) else {
                XCTAssertThrowsError(try Portrait(number: p, file: file)) {
                    XCTAssertEqual($0 as? PixelError, .absent(id))
                }
                continue
            }
            let portrait = try Portrait(number: p, file: file)
            XCTAssertEqual([portrait.image.width, portrait.image.height, portrait.image.rowBytes], [64, 64, 64])
            XCTAssertEqual(portrait.image.pixels.count, 4_096)
            zeros += portrait.image.pixels.filter { $0 == 0 }.count
            maxIndex = max(maxIndex, portrait.image.pixels.max() ?? 0)
        }
        XCTAssertEqual(zeros, 48_252)
        XCTAssertEqual(maxIndex, 255)
        // Boundaries: 256 is the page's last id (absent); 0 and 257 are refused, never wrapped.
        XCTAssertEqual(try Portrait.segmentID(256), 0x88FF)
        XCTAssertThrowsError(try Portrait(number: 256, file: file)) { XCTAssertEqual($0 as? PixelError, .absent(0x88FF)) }
        for p in [0, 257] {
            XCTAssertThrowsError(try Portrait.segmentID(p)) { XCTAssertEqual($0 as? PixelError, .number("portrait", p)) }
            XCTAssertThrowsError(try Portrait(number: p, file: file)) { XCTAssertEqual($0 as? PixelError, .number("portrait", p)) }
        }
        // Hostile (Invariant 5): every prefix of portrait 1 (0x8800) throws.
        let seg = try XCTUnwrap(file.segment(0x8800))
        for n in 0..<seg.count { XCTAssertThrowsError(try Portrait.decode(seg.prefix(n), id: 0x8800), "prefix \(n)") }
    }

    func testSkyStrips() throws {
        let file = try segmentFile()
        let present = ids(file, page: 0x84)
        XCTAssertEqual(present.count, 18)
        var pixels = 0, zeros = 0
        for id in present {
            let sky = try SkyStrip(number: Int(id - 0x8400), file: file)
            XCTAssertEqual([sky.image.width, sky.image.height, sky.image.rowBytes], [288, 32, 288])
            pixels += sky.image.pixels.count
            zeros += sky.image.pixels.filter { $0 == 0 }.count
        }
        XCTAssertEqual(pixels, 165_888)
        XCTAssertEqual(zeros, 35_806)
        // Hostile (Invariant 5): every prefix of 0x8400 throws.
        let seg = try XCTUnwrap(file.segment(0x8400))
        for n in 0..<seg.count { XCTAssertThrowsError(try SkyStrip.decode(seg.prefix(n), id: 0x8400), "prefix \(n)") }
        XCTAssertThrowsError(try SkyStrip(number: 256, file: file))
    }

    func testPixImages() throws {
        // Research note 6 (p04): (id, w, h) for all 59.
        var dims: [UInt16: (Int, Int)] = [
            0x8F00: (128, 128), 0x8F01: (352, 352), 0x8F02: (256, 252), 0x8F03: (256, 256), 0x8F04: (215, 223),
            0x8F05: (210, 259), 0x8F06: (210, 259), 0x8F07: (256, 272), 0x8F08: (200, 150), 0x8F09: (249, 249),
            0x8F0A: (252, 238), 0x8F0B: (248, 250), 0x8F0C: (258, 257), 0x8F0D: (254, 254), 0x8F0E: (256, 183),
            0x8F0F: (256, 256), 0x8F10: (256, 251), 0x8F11: (253, 253), 0x8F12: (160, 256), 0x8F13: (256, 256),
            0x8F14: (280, 292), 0x8F15: (256, 256), 0x8F16: (248, 247), 0x8F17: (248, 247), 0x8F18: (250, 247),
            0x8F19: (256, 256), 0x8F1A: (210, 259), 0x8F20: (64, 128), 0x8F34: (128, 128), 0x8F35: (12, 12),
            0x8F36: (12, 12), 0x8F37: (12, 8), 0x8F38: (12, 8), 0x8F50: (144, 144), 0x8F51: (144, 144),
            0x8F80: (128, 128), 0x8F81: (86, 128), 0x8F82: (38, 44), 0x8F83: (64, 128), 0x8F84: (304, 128),
            0x8F85: (72, 50), 0x8F86: (36, 48), 0x8F87: (304, 128),
        ]
        for id in UInt16(0x8F21)...0x8F30 { dims[id] = (24, 17) }
        XCTAssertEqual(dims.count, 59)
        let padded: [UInt16: Int] = [0x8F04: 216, 0x8F05: 212, 0x8F06: 212, 0x8F1A: 212, 0x8F09: 252, 0x8F0C: 260,
                                     0x8F0D: 256, 0x8F11: 256, 0x8F18: 252, 0x8F81: 88, 0x8F82: 40]

        let file = try segmentFile()
        let present = ids(file, page: 0x8F)
        XCTAssertEqual(Set(present), Set(dims.keys))
        var total = 0, odd: [UInt16: Int] = [:]
        for id in present {
            let pix = try PixImage(number: Int(id - 0x8F00), file: file)
            let (w, h) = try XCTUnwrap(dims[id])
            XCTAssertEqual([pix.image.width, pix.image.height], [w, h], String(id, radix: 16))
            XCTAssertEqual(pix.image.rowBytes, (w + 3) & ~3)
            XCTAssertEqual(pix.image.pixels.count, pix.image.rowBytes * h)
            if w % 4 != 0 { odd[id] = pix.image.rowBytes }
            total += pix.image.pixels.count
        }
        XCTAssertEqual(odd, padded)
        XCTAssertEqual(total, 1_838_728)

        // Hostile: every prefix of a small pix segment throws (never traps), and a lying header is refused.
        let small = try XCTUnwrap(file.segment(0x8F35))
        for n in 0..<small.count {
            XCTAssertThrowsError(try PixImage.decode(Data(small.prefix(n)), id: 0x8F35), "prefix \(n)")
        }
        for n in 0..<4 {
            XCTAssertThrowsError(try PixImage.decode(Data(small.prefix(n)), id: 0x8F35)) {
                XCTAssertEqual($0 as? PixelError, .shortHeader(0x8F35), "short header \(n)")
            }
        }
        var lying = [UInt8](small)
        lying[1] = 13                                     // width 13 → rowBytes 16 ≠ the stream's 12 × 12
        XCTAssertThrowsError(try PixImage.decode(Data(lying), id: 0x8F35)) {
            XCTAssertEqual($0 as? PixelError, .length(id: 0x8F35, expected: 192, actual: 144))
        }
        var shrunk = [UInt8](small)
        shrunk[1] = 4; shrunk[3] = 4                      // 4 × 4 = 16 B < the stream's 144: refused at the limit
        XCTAssertThrowsError(try PixImage.decode(Data(shrunk), id: 0x8F35)) {
            XCTAssertEqual($0 as? PixelError, .lz(id: 0x8F35, .outputLimit(16)))
        }
        var huge = [UInt8](small)
        huge[0] = 0xFF; huge[1] = 0xFF; huge[2] = 0xFF; huge[3] = 0xFF   // 65,535² claimed: nothing allocated from it
        XCTAssertThrowsError(try PixImage.decode(Data(huge), id: 0x8F35)) {
            XCTAssertEqual($0 as? PixelError, .length(id: 0x8F35, expected: 65_536 * 65_535, actual: 144))
        }
        var zero = [UInt8](small)
        zero[0] = 0; zero[1] = 0
        XCTAssertThrowsError(try PixImage.decode(Data(zero), id: 0x8F35)) { XCTAssertEqual($0 as? PixelError, .header(0x8F35)) }
        // IndexedImage refuses a size whose rowBytes × height overflows, and a buffer of the wrong length.
        XCTAssertThrowsError(try IndexedImage(width: Int.max / 2, height: 4, rowBytes: Int.max / 2, pixels: []))
        XCTAssertThrowsError(try IndexedImage(width: 3, height: 2, rowBytes: 4, pixels: [0, 0, 0, 0, 0, 0, 0]))
        XCTAssertThrowsError(try IndexedImage(width: 5, height: 1, rowBytes: 4, pixels: [0, 0, 0, 0]))
        XCTAssertThrowsError(try PixImage(number: 0x40, file: file)) { XCTAssertEqual($0 as? PixelError, .absent(0x8F40)) }
    }

    func testMacroIcons() throws {
        let file = try segmentFile()
        let present = ids(file, page: 0x8A)
        XCTAssertEqual(present.count, 62)
        var maxIndex: UInt8 = 0
        for id in present {
            XCTAssertEqual(file.segment(id)?.count, 512)
            let icon = try MacroIcon(number: Int(id - 0x8A00), file: file)
            XCTAssertEqual([icon.image.width, icon.image.height, icon.image.rowBytes], [32, 16, 32])
            XCTAssertEqual(icon.image.pixels, [UInt8](try XCTUnwrap(file.segment(id))), "raw, as stored")
            maxIndex = max(maxIndex, icon.image.pixels.max() ?? 0)
        }
        XCTAssertEqual(maxIndex, 255)
        XCTAssertThrowsError(try MacroIcon.decode(Data(count: 511), id: 0x8A00)) {
            XCTAssertEqual($0 as? PixelError, .length(id: 0x8A00, expected: 512, actual: 511))
        }
    }
}
