import XCTest
import CytheraCore
import HectorGraphics
@testable import CytheraRender

/// C5 (docs/plans/2026-10-06-cythera-phase0.md): the 21 PICT resources and the five `* screenshot.pict` files
/// through HectorKit's `PICT.decodePixels` (K1, HectorKit D14), as stored. Numbers: planner probe p14 (Research
/// note 11) with the execution correction "direct modes are {0, 36, 64} as stored".
final class StoredPictureTests: XCTestCase {

    func testStoredPicturesAsStored() throws {
        let dir = try CytheraData.dataDirectory()
        let r = try CytheraResources(directory: dir)
        let pictures = r.app.resources(of: "PICT").map { ("app", $0) } + r.data.resources(of: "PICT").map { ("data", $0) }
        XCTAssertEqual(pictures.count, 21)

        var indexedRect: [String] = [], indexedRgn: [String] = [], direct16: [String] = [], direct32: [String] = []
        for (file, res) in pictures {
            let key = "\(file) \(res.id)"
            let picture = try StoredPicture.decode(res.data)
            switch picture.pixels {
            case .indexed(let image, let table):
                XCTAssertEqual(image.rowBytes, image.width, key)
                XCTAssertEqual(image.pixels.count, image.width * image.height, key)
                XCTAssertEqual([image.width, image.height], [picture.width, picture.height], key)
                XCTAssertNotNil(table, key)
                XCTAssertEqual(picture.transferMode, 0, "\(key): indexed mode as stored")
                if picture.maskRegion == nil {
                    indexedRect.append(key)
                } else {
                    XCTAssertEqual(table?.flags, 0x8000, "\(key): device-relative table")
                    XCTAssertEqual(table?.entries.count, 256, key)
                    indexedRgn.append(key)
                }
            case .direct16(let words):
                XCTAssertEqual(words.count, picture.width * picture.height, key)
                XCTAssertEqual([picture.width, picture.height], [80, 130], key)
                XCTAssertEqual(picture.transferMode, 36, "\(key): mode as stored")
                direct16.append(key)
            case .direct32(let rgb):
                XCTAssertEqual(rgb.count, 3 * picture.width * picture.height, key)
                XCTAssertEqual([picture.width, picture.height], [88, 155], key)
                XCTAssertEqual(picture.transferMode, 0, "\(key): mode as stored")
                direct32.append(key)
            }
            if case .stored(let again) = StoredPicture.record(res.data) {
                XCTAssertEqual(again, picture, key)
            } else {
                XCTFail("\(key) refused")
            }
        }
        XCTAssertEqual(indexedRect.count, 11, "\(indexedRect)")
        XCTAssertEqual(Set(indexedRgn), ["data 131", "data 512", "data 513"])
        XCTAssertEqual(direct16, ["data 129"])
        XCTAssertEqual(Set(direct32), Set((133...138).map { "data \($0)" }))

        // The screenshot files: a 512-byte header, then the PICT (p14).
        func screenshot(_ name: String) throws -> Data {
            try Data(contentsOf: dir.appendingPathComponent("\(name) screenshot.pict"))
        }
        for name in ["Odemia", "Pnyx", "Unicorn", "Catamarca"] {
            guard case .stored(let p) = StoredPicture.record(try screenshot(name), headerBytes: 512) else {
                XCTFail("\(name) refused"); continue
            }
            XCTAssertEqual([p.width, p.height], [640, 480], name)
            XCTAssertEqual(p.transferMode, 0, "\(name): mode as stored (Catamarca = 0 srcCopy, D28 as-built)")
            XCTAssertNil(p.maskRegion, name)
            if name == "Catamarca" {
                guard case .direct16 = p.pixels else { XCTFail("Catamarca is 16-bit direct"); continue }
            } else {
                guard case .indexed(_, let table) = p.pixels else { XCTFail("\(name) is indexed"); continue }
                XCTAssertEqual(table?.flags, 0x8000, name)
            }
        }
        XCTAssertEqual(StoredPicture.record(try screenshot("Land King Hall"), headerBytes: 512),
                       .refused("0x8200 QuickTime"))
        XCTAssertEqual(StoredPicture.record(Data(count: 100), headerBytes: 512), .refused("shorter than its header"))

        // Hostile (Invariant 5): every prefix of one indexed (data 139) and one direct (data 129) PICT throws,
        // and the refusal text is the stable spelling.
        for id: Int16 in [139, 129] {
            let full = try XCTUnwrap(r.data.resource(type: "PICT", id: id)).data
            for n in 0..<full.count {
                XCTAssertThrowsError(try StoredPicture.decode(full.prefix(n)), "PICT \(id) prefix \(n)")
            }
        }
        XCTAssertEqual(StoredPicture.refusalReason(PICT.DecodeError.unsupportedOpcode(0x32)), "unsupportedOpcode 0x0032")
        XCTAssertEqual(StoredPicture.refusalReason(PICT.DecodeError.unsupportedPixels("directMode")),
                       "unsupportedPixels directMode")
    }
}
