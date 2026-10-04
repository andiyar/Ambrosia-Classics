import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// Plan 2026-10-04-btx-playable task A2 (Q16): `crsr 200`, the hand `_LoadHandCursor @ 00025af8` loads with
/// `GetCCursor(200)` and `_SetMyCCursor(200) @ 00025b1d` sets in the menus. Data-gated on `HECTORKIT_DATA_BTX`.
final class ColorCursorTests: XCTestCase {
    func testHandCursorCrsr200Decodes() throws {
        let data = try RenderTestData.gameData()
        let bytes = try XCTUnwrap(data.data(type: "crsr", id: 200))
        let cursor = try ColorCursor(data: bytes)
        XCTAssertEqual(cursor.image.width, 16)
        XCTAssertEqual(cursor.image.height, 16)
        XCTAssertEqual(cursor.hotSpot.h, 1)
        XCTAssertEqual(cursor.hotSpot.v, 0)
        XCTAssertEqual(cursor.pixelDepth, 2)
        // The mask covers 142 pixels: colour-table values 0 (white) ×17, 1 (0xEEEE grey) ×94, 3 (black) ×31; no
        // inverting pixels (mask 0 with a 1-bit data bit set).
        let px = cursor.image.pixels
        XCTAssertEqual(px.filter { $0 >> 24 == 0xFF }.count, 142)
        XCTAssertEqual(px.filter { $0 == 0xFFFF_FFFF }.count, 17)
        XCTAssertEqual(px.filter { $0 == 0xFFEE_EEEE }.count, 94)
        XCTAssertEqual(px.filter { $0 == 0xFF00_0000 }.count, 31)
        XCTAssertEqual(px.filter { $0 == 0 }.count, 256 - 142)
        XCTAssertEqual(cursor.invertedPixels, 0)
        // Row 2: " X##" — black at h 1, grey at h 2…3.
        XCTAssertEqual(cursor.image[1, 2], 0xFF00_0000)
        XCTAssertEqual(cursor.image[2, 2], 0xFFEE_EEEE)
        XCTAssertEqual(cursor.image[0, 2], 0)
    }

    func testCursorRefusesTruncatedData() {
        XCTAssertThrowsError(try ColorCursor(data: Data(repeating: 0, count: 40)))
    }
}
