import XCTest
import CytheraCore
@testable import CytheraRender

/// C5 (docs/plans/2026-10-06-cythera-phase0.md): `clut 256` → `Palette`, `pltt 130`, `Lite` light masks
/// (engine-classes §3.3) and `FILT` displacement filters (data-format §3.4). Numbers: planner probes p07 / p19
/// (Research notes 10, 12).
final class PaletteAndMasksTests: XCTestCase {

    private func resources() throws -> CytheraResources {
        try CytheraResources(directory: try CytheraData.dataDirectory())
    }

    private func assertEveryPrefixThrows(_ data: Data, _ parse: (Data) throws -> Void, _ what: String) {
        for n in 0..<data.count {
            XCTAssertThrowsError(try parse(Data(data.prefix(n))), "\(what) prefix \(n)")
        }
    }

    func testPaletteFromDataClut() throws {
        let r = try resources()
        let dataClut = try XCTUnwrap(r.data.resource(type: "clut", id: 256))
        let appClut = try XCTUnwrap(r.app.resource(type: "clut", id: 256))
        XCTAssertEqual(r.resource(type: "clut", id: 256)?.data, dataClut.data, "data file first (note 12)")

        let data = try ColorTableRecord(data: dataClut.data)
        XCTAssertEqual(data.seed, 0)
        XCTAssertEqual(data.flags, 0)
        XCTAssertEqual(data.entries.count, 256, "ctSize 255")
        XCTAssertEqual(data.entries.map(\.value), (0...255).map { UInt16($0) })
        XCTAssertEqual(data.entries[0], .init(value: 0, r: 0xFFFF, g: 0xFFFF, b: 0xFFFF))
        XCTAssertEqual(data.entries[1], .init(value: 1, r: 0, g: 0, b: 0xA800))
        XCTAssertEqual(data.entries[255], .init(value: 255, r: 0, g: 0, b: 0))
        func replicated(_ c: UInt16) -> Bool { c >> 8 == c & 0xFF }
        let notReplicated = data.entries.filter { !(replicated($0.r) && replicated($0.g) && replicated($0.b)) }
        XCTAssertEqual(notReplicated.count, 251)
        XCTAssertTrue(data.rgb8(1)! == (0, 0, 0xA8), "rgb8 = high byte")
        XCTAssertNil(data.rgb8(256))

        let app = try ColorTableRecord(data: appClut.data)
        let differ = (0..<256).filter { app.entries[$0] != data.entries[$0] }
        XCTAssertEqual(differ, [0, 16, 252, 253])
        XCTAssertEqual(app.entries.filter { !(replicated($0.r) && replicated($0.g) && replicated($0.b)) }.count, 250)
        // Refused shapes: ctSize −1 and 256 (> the 8-bit range), and a table with one trailing byte.
        for ctSize: [UInt8] in [[0xFF, 0xFF], [0x01, 0x00]] {
            XCTAssertThrowsError(try ColorTableRecord(data: Data([0, 0, 0, 0, 0, 0] + ctSize))) {
                guard case .shape = $0 as? ArtRecordError else { return XCTFail("\($0)") }
            }
        }
        XCTAssertThrowsError(try ColorTableRecord(data: dataClut.data + [0])) {
            XCTAssertEqual($0 as? ArtRecordError, .length("clut", expected: 2_056, actual: 2_057))
        }

        let palette = try Palette.clut256(r)
        XCTAssertEqual(palette.origin, .dataFile)
        XCTAssertEqual(palette.origin.rawValue, "Cythera Data.rsrc clut 256")
        XCTAssertEqual(palette.argb[0], 0xFFFF_FFFF)
        XCTAssertEqual(palette.argb[1], 0xFF00_00A8)
        XCTAssertEqual(palette.argb[255], 0xFF00_0000)
        XCTAssertEqual(try Palette.clut256(r, from: .appFile).origin, .appFile)
        let image = try IndexedImage(width: 3, height: 1, rowBytes: 4, pixels: [0, 1, 255, 7])
        XCTAssertEqual(palette.rgba(image), [0xFFFF_FFFF, 0xFF00_00A8, 0xFF00_0000], "index 0 opaque; padding dropped")

        assertEveryPrefixThrows(dataClut.data, { _ = try ColorTableRecord(data: $0) }, "clut")

        // pltt 130 (app fork): u16 count, 14 reserved bytes, 16-byte entries (p07, p19).
        let pltt = try PaletteResource(data: try XCTUnwrap(r.app.resource(type: "pltt", id: 130)).data)
        XCTAssertEqual(pltt.count, 256)
        XCTAssertEqual(pltt.entries.count, 256)
        XCTAssertEqual([pltt.entries[0].r, pltt.entries[0].g, pltt.entries[0].b], [0xFFFF, 0xFFFF, 0xFFFF])
        XCTAssertEqual([pltt.entries[1].r, pltt.entries[1].g, pltt.entries[1].b], [0xC6C6, 0xC6C6, 0xC6C6])
        XCTAssertNil(r.data.resource(type: "pltt", id: 130))
        XCTAssertThrowsError(try PaletteResource(data: Data(count: 16))) {
            XCTAssertEqual($0 as? ArtRecordError, .shape("pltt pmEntries 0"))
        }
        assertEveryPrefixThrows(try XCTUnwrap(r.app.resource(type: "pltt", id: 130)).data,
                                { _ = try PaletteResource(data: $0) }, "pltt")
    }

    func testLightMasks() throws {
        let r = try resources()
        XCTAssertTrue(r.data.resources(of: "Lite").isEmpty, "all 25 in the app fork")
        let lites = r.app.resources(of: "Lite").sorted { $0.id < $1.id }
        XCTAssertEqual(lites.map(\.id), Array(128...133) + Array(140...158))
        let sizes = [10, 12, 14, 16, 18, 22, 8, 14, 20, 26, 32, 38, 44, 50, 58, 64, 70, 76, 82, 88, 94, 100, 106, 114, 120]
        for (res, n) in zip(lites, sizes) {
            let mask = try LightMask(data: res.data)
            XCTAssertEqual(mask.size, n, "Lite \(res.id)")
            XCTAssertEqual(res.data.count, 1 + n * n, "Lite \(res.id)")
            XCTAssertEqual(mask.intensities.count, n * n)
            XCTAssertEqual(mask.intensity(x: n - 1, y: n - 1), res.data.last)
            XCTAssertNil(mask.intensity(x: n, y: 0))
        }
        assertEveryPrefixThrows(lites[6].data, { _ = try LightMask(data: $0) }, "Lite 140")
        XCTAssertThrowsError(try LightMask(data: lites[6].data + [0]))
        XCTAssertThrowsError(try LightMask(data: Data([0]))) { XCTAssertEqual($0 as? ArtRecordError, .shape("Lite size 0")) }
    }

    func testDisplacementFilters() throws {
        let r = try resources()
        let filts = r.data.resources(of: "FILT").sorted { $0.id < $1.id }
        XCTAssertEqual(filts.map(\.id), Array(128...134))
        XCTAssertTrue(r.app.resources(of: "FILT").isEmpty)
        let frames = [6, 6, 6, 6, 8, 8, 6], holds: [UInt8] = [0, 0, 0, 0, 1, 1, 1]
        let maskBits = [28, 79, 8, 50, 50, 12, 43]
        for (k, res) in filts.enumerated() {
            let f = try DisplacementFilter(data: res.data)
            XCTAssertEqual(f.frames.count, frames[k], "FILT \(res.id)")
            XCTAssertTrue(f.frames.allSatisfy { $0.count == 1_024 })
            XCTAssertEqual(f.holdCount, holds[k], "FILT \(res.id)")
            XCTAssertEqual(f.counter, 0, "FILT \(res.id)")
            XCTAssertEqual(f.colorMask.count, 32)
            XCTAssertEqual((0...255).filter { f.displaces(UInt8($0)) }.count, maskBits[k], "FILT \(res.id)")
            XCTAssertEqual(0x24 + f.frames.count * 0x400, res.data.count)
        }
        // Mask bit order is the reader's: bit (i & 7) of byte (i >> 3) (`DisplacementFilterTile @ 100053e8`).
        var synthetic = [UInt8](repeating: 0, count: 0x24 + 0x400)
        synthetic[4 + 1] = 0x04                          // colour index 8 + 2 = 10
        synthetic[0x24] = 0xFF                           // frame 0, offset 0 = −1
        let f = try DisplacementFilter(data: Data(synthetic))
        XCTAssertEqual((0...255).filter { f.displaces(UInt8($0)) }, [10])
        XCTAssertEqual(f.frames[0][0], -1)
        XCTAssertThrowsError(try DisplacementFilter(data: Data(synthetic.prefix(0x24))), "no frame")
        XCTAssertThrowsError(try DisplacementFilter(data: Data(synthetic + [0])), "partial frame")
        // Hostile (Invariant 5) over EVERY prefix of FILT 128: the layout has no frame count (the reader runs to
        // the end of the handle), so a prefix ending on a frame boundary is itself a well-formed filter of k
        // frames; every other prefix throws.
        let real = filts[0].data
        for n in 0..<real.count {
            if n > 0x24, (n - 0x24) % 0x400 == 0 {
                XCTAssertEqual(try DisplacementFilter(data: real.prefix(n)).frames.count, (n - 0x24) / 0x400)
            } else {
                XCTAssertThrowsError(try DisplacementFilter(data: real.prefix(n)), "prefix \(n)")
            }
        }
    }
}
