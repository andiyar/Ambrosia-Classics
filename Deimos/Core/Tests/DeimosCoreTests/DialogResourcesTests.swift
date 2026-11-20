import XCTest
@testable import DeimosCore
import HectorResources

/// The app fork's dialog resources, read from the committed `Resources/Deimos/Deimos Rising.rsrc` with Core's own
/// Foundation-only reader (Phase 4 S6 DG; grounding C §2). The expectations are the resource bytes as stored (rects
/// t, l, b, r; item types with the 0x80 disabled bit), read independently of this reader.
final class DialogResourcesTests: XCTestCase {
    /// DITL 190 "Game - Preferences", item by item: kind, enabled, rect, text (or the control's CNTL id).
    private static let ditl190: [(DialogItem.Kind, Bool, MacRect, String?, Int16?)] = [
        (.button, true, MacRect(top: 344, left: 290, bottom: 364, right: 360), "Save", nil),
        (.button, true, MacRect(top: 344, left: 212, bottom: 364, right: 282), "Cancel", nil),
        (.button, true, MacRect(top: 344, left: 14, bottom: 364, right: 90), "Defaults", nil),
        (.button, true, MacRect(top: 344, left: 97, bottom: 364, right: 167), "Revert", nil),
        (.control, true, MacRect(top: 17, left: 22, bottom: 78, right: 356), nil, 200),
        (.control, true, MacRect(top: 85, left: 22, bottom: 195, right: 356), nil, 201),
        (.control, true, MacRect(top: 202, left: 22, bottom: 279, right: 356), nil, 202),
        (.checkBox, true, MacRect(top: 34, left: 49, bottom: 52, right: 331), "Full Screen (Takes Effect on Relaunch)", nil),
        (.checkBox, true, MacRect(top: 54, left: 49, bottom: 72, right: 331), "Interlacing  (Faster but lower quality)", nil),
        (.checkBox, true, MacRect(top: 138, left: 49, bottom: 156, right: 251), "Bypass System Volume", nil),
        (.staticText, false, MacRect(top: 162, left: 66, bottom: 176, right: 154), "Sound Volume:", nil),
        (.control, true, MacRect(top: 162, left: 158, bottom: 184, right: 298), nil, 2000),
        (.staticText, false, MacRect(top: 162, left: 301, bottom: 176, right: 335), "100%", nil),
        (.staticText, false, MacRect(top: 110, left: 51, bottom: 125, right: 136), "Music Volume:", nil),
        (.control, true, MacRect(top: 108, left: 138, bottom: 130, right: 278), nil, 2001),
        (.staticText, false, MacRect(top: 109, left: 281, bottom: 123, right: 315), "100%", nil),
        (.checkBox, true, MacRect(top: 253, left: 49, bottom: 271, right: 331),
         "ESC Key Delay  (Requires key to be held down)", nil),
        (.button, true, MacRect(top: 225, left: 51, bottom: 245, right: 151), "Set Controls\u{2026}", nil),
        (.button, true, MacRect(top: 225, left: 169, bottom: 245, right: 331), "Set Gamepad Controls...", nil),
        (.staticText, false, MacRect(top: 302, left: 38, bottom: 338, right: 361),
         "(Hold down Option during launch to display this dialog)", nil),
    ]

    func testDITL190Parse() throws {
        let fork = try DialogFork.loaded.get()

        // DLOG 190: t30 l16 b407 r395 (379 × 377), procID 1 (dBoxProc), invisible, no close box, items 190, empty
        // title, position 0x280A (centre on the main screen).
        let dlog = try DialogTemplate.load(190, from: fork)
        XCTAssertEqual(dlog.bounds, MacRect(top: 30, left: 16, bottom: 407, right: 395))
        XCTAssertEqual(dlog.procID, 1)
        XCTAssertFalse(dlog.visible)
        XCTAssertFalse(dlog.goAway)
        XCTAssertEqual(dlog.itemsID, 190)
        XCTAssertEqual(dlog.title, [])
        XCTAssertEqual(dlog.position, 0x280A)

        // DITL 190: twenty items as stored.
        let ditl = try DialogItemList.load(dlog.itemsID, from: fork)
        XCTAssertEqual(ditl.items.count, 20)
        for (i, e) in Self.ditl190.enumerated() where i < ditl.items.count {
            let item = ditl.items[i]
            XCTAssertEqual(item.number, i + 1)
            XCTAssertEqual(item.kind, e.0, "item \(i + 1) kind")
            XCTAssertEqual(item.enabled, e.1, "item \(i + 1) enabled")
            XCTAssertEqual(item.rect, e.2, "item \(i + 1) rect")
            if let text = e.3 {
                XCTAssertEqual(MacRoman.decode(item.text), text, "item \(i + 1) text")
                XCTAssertNil(item.resourceID)
            }
            if let id = e.4 { XCTAssertEqual(item.resourceID, id, "item \(i + 1) CNTL id") }
        }
        XCTAssertEqual(ditl[18]?.text.last, 0xC9, "Set Controls… ends in the Mac Roman ellipsis")
        XCTAssertNil(ditl[0], "items are numbered from 1: no item 0")
        XCTAssertNil(ditl[21], "nor past the last")
        XCTAssertNil(fork[ShellResourceKey(FourCC("CNTL")!, 2000)], "CNTL 2000 is absent from the fork (C §2)")
        XCTAssertNil(fork[ShellResourceKey(FourCC("CNTL")!, 2001)])

        // The three group boxes' CNTLs: proc 164 (group box, text title), their titles.
        for (id, title) in [(Int16(200), "Video"), (201, "Audio"), (202, "Controls")] {
            let c = try ControlTemplate.load(id, from: fork)
            XCTAssertEqual(c.procID, 164, "CNTL \(id)")
            XCTAssertEqual(MacRoman.decode(c.title), title)
        }
        // S7's resources through the same reader: the tab control's tab# 6000, STR# 130's key names.
        let cntl191 = try ControlTemplate.load(191, from: fork)
        XCTAssertEqual(cntl191.procID, 128)
        XCTAssertEqual(cntl191.value, 6000)
        XCTAssertEqual(try TabList.load(6000, from: fork).tabs.map { MacRoman.decode($0.name) }, ["Player 1", "Player 2"])
        let str130 = try ResourceStringList.load(130, from: fork)
        XCTAssertEqual(str130.count, 128)
        XCTAssertEqual(MacRoman.decode(str130[0x31]), "Space")
        XCTAssertEqual(MacRoman.decode(str130[0x7E]), "Arrow Up")
        XCTAssertEqual(try ResourceStringList.load(131, from: fork).count, 2)

        // A malformed DITL and a missing DLOG throw; they do not trap.
        XCTAssertThrowsError(try DialogItemList(bytes: [0x00, 0x13], id: 190))
        XCTAssertThrowsError(try DialogTemplate.load(190, from: [:]))

        // A hand-built fork whose four types all name the same four references (16 reads from 48 bytes of
        // references): more references than the fork has room for (130 / 12 = 10) — refused, never spun over.
        var bad = [UInt8](repeating: 0, count: 130)
        func put32(_ at: Int, _ v: UInt32) { for i in 0..<4 { bad[at + i] = UInt8(truncatingIfNeeded: v >> (24 - 8 * i)) } }
        func put16(_ at: Int, _ v: UInt16) { bad[at] = UInt8(v >> 8); bad[at + 1] = UInt8(v & 0xFF) }
        put32(0, 16)                                                // data at 16 (one 0-length resource)
        put32(4, 20)                                                // map at 20
        put16(20 + 24, 28)                                          // the type list at 48
        put16(48, 3)                                                // four types
        for t in 0..<4 {
            put32(50 + t * 8, 0x5445_5330 + UInt32(t))              // 'TES0'…'TES3'
            put16(50 + t * 8 + 4, 3)                                // four references each
            put16(50 + t * 8 + 6, 34)                               // all at 82
        }
        for k in 0..<4 { put16(82 + k * 12, UInt16(k)); put16(82 + k * 12 + 2, 0xFFFF) }
        XCTAssertThrowsError(try DialogResources.readFork(bad)) { error in
            XCTAssertEqual(error as? DialogResourceError, .notAResourceFile)
        }
    }
}

/// The committed app fork, read once for the suite with `DialogResources.readFork`.
enum DialogFork {
    static let loaded: Result<[ShellResourceKey: [UInt8]], Error> = Result {
        let url = try DeimosData.dataDirectory().deletingLastPathComponent().appendingPathComponent("Deimos Rising.rsrc")
        return try DialogResources.readFork(Array(Data(contentsOf: url)))
    }
}
