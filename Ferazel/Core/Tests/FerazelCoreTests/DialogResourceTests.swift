import XCTest
import HectorResources
@testable import FerazelCore

/// R1 (docs/plans/2026-10-14-ferazel-phase3.md): DLOG/ALRT/DITL/CNTL/MENU/MBAR parsers over the app fork, against
/// the committed `Resources/Ferazel` (D26). Data: digest A §3, §5, §6. A missing data file is a FAILURE naming the
/// path, never a skip.
final class DialogResourceTests: XCTestCase {

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    private func rect(_ t: Int16, _ l: Int16, _ b: Int16, _ r: Int16) -> MacRect {
        MacRect(top: t, left: l, bottom: b, right: r)
    }

    func testAbortWarningDialog() throws {
        let r = try resources()
        let dlog = try DialogTemplate.load(from: r, type: "DLOG", id: 202)
        XCTAssertEqual(dlog.bounds, rect(114, 144, 256, 439))
        XCTAssertEqual(dlog.itemsID, 202)
        let ditl = try DialogItemList.load(from: r, id: 202)
        XCTAssertEqual(ditl.items.count, 4)
        XCTAssertEqual(ditl.items[0].kind, .button)
        XCTAssertEqual(ditl.items[0].text, "OK")
        XCTAssertEqual(ditl.items[0].rect, rect(113, 226, 133, 284))
        XCTAssertEqual(ditl.items[1].kind, .button)
        XCTAssertEqual(ditl.items[1].text, "Cancel")
        XCTAssertEqual(ditl.items[1].rect, rect(113, 161, 133, 219))
        XCTAssertEqual(ditl.items[2].kind, .picture)
        XCTAssertEqual(ditl.items[2].resourceID, 145)
        XCTAssertNil(ditl.items[2].text)
        XCTAssertEqual(ditl.items[2].rect, rect(10, 10, 42, 42))
        XCTAssertEqual(ditl.items[3].kind, .staticText)
        XCTAssertEqual(ditl.items[3].text, "^0")
        XCTAssertNil(ditl.items[3].resourceID)
        XCTAssertEqual(ditl.items[3].rect, rect(10, 53, 97, 264))
    }

    func testPrefsPanels() throws {
        let r = try resources()
        let dlog = try DialogTemplate.load(from: r, type: "DLOG", id: 6900)
        XCTAssertEqual(dlog.bounds, rect(56, 20, 330, 471))
        let main = try DialogItemList.load(from: r, id: dlog.itemsID)
        XCTAssertEqual(main.items.count, 6)
        let popup = main.items[2]
        XCTAssertEqual(popup.kind, .control)
        XCTAssertEqual(popup.resourceID, 600)
        let cntl600 = try ControlTemplate.load(from: r, id: 600)
        XCTAssertEqual(cntl600.menuID, 600)
        let menu600 = try MenuTemplate.load(from: r, id: cntl600.menuID)
        XCTAssertEqual(menu600.items.map(\.name), ["Game Options", "Controls", "Sound & Music"])

        // CNTLs 600–605: value 1, max 0, procID 1008 (popup), refCon 0; min = MENU id (605 → 601).
        for (id, menu) in [(600, 600), (601, 601), (602, 602), (603, 603), (604, 604), (605, 601)] as [(Int16, Int16)] {
            let c = try ControlTemplate.load(from: r, id: id)
            XCTAssertEqual(c.value, 1, "CNTL \(id) value")
            XCTAssertEqual(c.max, 0, "CNTL \(id) max")
            XCTAssertEqual(c.procID, 1008, "CNTL \(id) procID")
            XCTAssertEqual(c.refCon, 0, "CNTL \(id) refCon")
            XCTAssertEqual(c.min, menu, "CNTL \(id) min")
        }

        // Panel DITLs are appended after DITL 6900's six items: dialog item n = panel item n − 6.
        let base = main.items.count
        let controls = try DialogItemList.load(from: r, id: 6903)
        for n in [9, 10, 15] {
            XCTAssertEqual(controls.items[n - base - 1].kind, .control, "dialog item \(n)")
            XCTAssertEqual(controls.items[n - base - 1].resourceID, 601, "dialog item \(n)")
        }
        let menu601 = try MenuTemplate.load(from: r, id: 601)
        XCTAssertEqual(menu601.items.map(\.name), ["9", "8", "7", "6", "5", "4", "3", "2", "1"])

        let keys = try DialogItemList.load(from: r, id: 6902)
        let edits: [(Int, Int16, Int16)] = [(7, 67, 132), (8, 93, 132), (9, 119, 132), (10, 145, 132), (11, 171, 132),
                                            (12, 67, 342), (13, 93, 342), (14, 119, 342), (15, 145, 342)]
        for (n, top, left) in edits {
            let item = keys.items[n - base - 1]
            XCTAssertEqual(item.kind, .editText, "dialog item \(n)")
            XCTAssertEqual(item.rect.top, top, "dialog item \(n) top")
            XCTAssertEqual(item.rect.left, left, "dialog item \(n) left")
            XCTAssertEqual(item.rect.width, 85, "dialog item \(n) width")
        }
        let sprocket = keys.items[26 - base - 1]
        XCTAssertEqual(sprocket.kind, .checkBox)
        XCTAssertEqual(sprocket.text, "Use InputSprocket")
        XCTAssertEqual(sprocket.rect, rect(197, 34, 215, 185))
    }

    func testMenuBar() throws {
        let r = try resources()
        let mbar = try MenuBarTemplate.load(from: r, id: 128)
        XCTAssertEqual(mbar.menuIDs, [128, 129, 130])

        let file = try MenuTemplate.load(from: r, id: 129)
        XCTAssertEqual(file.items.map(\.name), ["New Game", "Restore Game...", "-", "Abort Game", "-", "Quit"])
        XCTAssertEqual(file.items.map(\.keyEquivalent), ["N", "O", nil, "W", nil, "Q"])

        let options = try MenuTemplate.load(from: r, id: 130)
        XCTAssertEqual(options.items.map(\.name), ["Music", "Sound Effects", "-", "Preferences…"])
        XCTAssertEqual(options.items.map(\.keyEquivalent), ["M", "F", nil, "P"])

        let apple = try MenuTemplate.load(from: r, id: 128)
        XCTAssertEqual(apple.id, 128)
        XCTAssertEqual(apple.items.first?.name, "About Ferazel's Wand…")
    }

    func testStandardFileDitls() throws {
        let r = try resources()
        let save = try DialogItemList.load(from: r, id: 1003)
        XCTAssertEqual(save.items[12].kind, .staticText)
        XCTAssertEqual(save.items[12].text,
                       "Your saved game will reflect your position as of the most recent checkpoint.")
        let open = try DialogItemList.load(from: r, id: 1500)
        XCTAssertEqual(open.items[9].text, "^0")
        XCTAssertEqual(open.items[9].rect, rect(166, 11, 203, 334))
        XCTAssertTrue(open.items[9].disabled)
        XCTAssertFalse(open.items[0].disabled)
    }
}
