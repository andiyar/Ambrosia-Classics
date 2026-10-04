import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// Plan 2026-10-04-btx-playable task A2 (Q16): `crsr 200`, the hand `_LoadHandCursor @ 00025af8` loads with
/// `GetCCursor(200)` and `_SetMyCCursor(200) @ 00025b1d` sets in the menus. Data-gated on `HECTORKIT_DATA_BTX`.
///
/// Expectations come from the resource bytes read by Inside Macintosh's `CCrsr` layout (crsrType @0, crsrMap @2,
/// crsrData @6, crsrXData @10, crsrXValid @14, crsrXHandle @16, crsr1Data @20, crsrMask @52, crsrHotSpot @84), not
/// from the decoder: the mask's set bits are counted straight from bytes 52…83.
final class ColorCursorTests: XCTestCase {
    func testHandCursorCrsr200Decodes() throws {
        let data = try RenderTestData.gameData()
        let bytes = [UInt8](try XCTUnwrap(data.data(type: "crsr", id: 200)))
        XCTAssertEqual(Array(bytes[0..<2]), [0x80, 0x01], "crsrType")
        XCTAssertEqual(Array(bytes[84..<88]), [0, 1, 0, 1], "crsrHotSpot (v 1, h 1)")
        let maskBits = bytes[52..<84].reduce(0) { $0 + $1.nonzeroBitCount }
        XCTAssertEqual(maskBits, 142)

        let cursor = try ColorCursor(data: Data(bytes))
        XCTAssertEqual(cursor.image.width, 16)
        XCTAssertEqual(cursor.image.height, 16)
        XCTAssertEqual(cursor.hotSpot.h, 1)
        XCTAssertEqual(cursor.hotSpot.v, 1)
        XCTAssertEqual(cursor.pixelDepth, 2)
        // Every mask pixel opaque; the 2-bit pixels there are value 3 (black) ×48 and 1 (0xEEEE grey) ×94 — no
        // white; no inverting pixels (mask 0 with a crsr1Data bit set).
        let px = cursor.image.pixels
        XCTAssertEqual(px.filter { $0 >> 24 == 0xFF }.count, maskBits)
        XCTAssertEqual(px.filter { $0 == 0xFF00_0000 }.count, 48)
        XCTAssertEqual(px.filter { $0 == 0xFFEE_EEEE }.count, 94)
        XCTAssertEqual(px.filter { $0 == 0xFFFF_FFFF }.count, 0)
        XCTAssertEqual(px.filter { $0 == 0 }.count, 256 - maskBits)
        XCTAssertEqual(cursor.invertedPixels, 0)
        // Mask bit ⇔ opaque pixel, pixel by pixel.
        for y in 0..<16 {
            for x in 0..<16 {
                let bit = (bytes[52 + y * 2 + x / 8] >> (7 - x % 8)) & 1
                XCTAssertEqual(cursor.image[x, y] >> 24 == 0xFF, bit == 1, "(\(x), \(y))")
            }
        }
        // Row 1 is the fingertip outline " XXX"; row 2 " X##X".
        XCTAssertEqual(cursor.image[1, 1], 0xFF00_0000)
        XCTAssertEqual(cursor.image[3, 1], 0xFF00_0000)
        XCTAssertEqual(cursor.image[2, 2], 0xFFEE_EEEE)
        XCTAssertEqual(cursor.image[0, 0], 0)
    }

    func testCursorRefusesTruncatedData() {
        XCTAssertThrowsError(try ColorCursor(data: Data(repeating: 0, count: 40)))
    }
}
