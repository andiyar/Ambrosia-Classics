import BubbleTroubleCore
import Foundation
import XCTest

/// Plan 2026-10-04-btx-playable §C1 (+ amendments R2, R9) — all five resource files, the sprite index,
/// the `Rect` resources and the per-level background/music table. Oracles: data-formats §4 (SpIL/SpIc),
/// the T0 correction of §7 (`Rect` stored L,T,R,B — `TMPL 128`, `_GetRectRsrc @ 0000c9e9`), the
/// front-end inventory FI §6a (background/music by level) and FI §7 / `_LoadMusic @ 0001b23c` (music names).
final class GameDataTests: XCTestCase {

    private func gameData() throws -> BTXGameData {
        try BTXGameData(resourcesDirectory: BTXTestData.resourcesDirectory())
    }

    func testOpensAllFiveFiles() throws {
        let data = try gameData()
        XCTAssertEqual(data.fileNames, ["Bubble Trouble X.rsrc", "BT Levels.rsrc", "BT Sprites.rsrc",
                                        "BT Sounds.rsrc", "BT Titles.rsrc"])
        // One resource from each file, found by type + id across all five (R9: cicn 1000–1002/128 and
        // snd 9047 live in the app file, not the sprite/sound files).
        XCTAssertEqual(data.fileName(containingType: "snd ", id: 9047), "Bubble Trouble X.rsrc")
        XCTAssertEqual(data.fileName(containingType: "cicn", id: 1000), "Bubble Trouble X.rsrc")
        XCTAssertEqual(data.fileName(containingType: "cicn", id: 128), "Bubble Trouble X.rsrc")
        XCTAssertEqual(data.fileName(containingType: "PICT", id: 912), "Bubble Trouble X.rsrc")
        XCTAssertEqual(data.fileName(containingType: "PICT", id: 13000), "BT Levels.rsrc")
        XCTAssertEqual(data.fileName(containingType: "cicn", id: 25000), "BT Sprites.rsrc")
        XCTAssertEqual(data.fileName(containingType: "snd ", id: 9000), "BT Sounds.rsrc")
        XCTAssertEqual(data.fileName(containingType: "PICT", id: 9100), "BT Titles.rsrc")
        XCTAssertNil(data.fileName(containingType: "PICT", id: 1))
        XCTAssertNil(data.data(type: "snd ", id: 9048))
        // snd 9000 "Squish": format 1 header, 8-bit PCM (data-formats §6 worked decode).
        let squish = try XCTUnwrap(data.data(type: "snd ", id: 9000))
        XCTAssertEqual([UInt8](squish.prefix(4)), [0x00, 0x01, 0x00, 0x01])
        XCTAssertEqual(data.resource(type: "snd ", id: 9000)?.name, "Squish")
        XCTAssertEqual(data.ids(of: "snd ").count, 52)          // 51 in BT Sounds + 9047 in the app file
        // The existing level/FILM loaders ride along unchanged (R2).
        XCTAssertEqual(data.levels.levelIDs, Array(1...50))
        XCTAssertEqual(data.levels.filmIDs, [1, 2, 3, 4])
        XCTAssertEqual(try data.levels.film(1).seed, try BTXTestData.files().film(1).seed)
        // A missing file is reported by name.
        let empty = FileManager.default.temporaryDirectory.appendingPathComponent("btx-empty-\(UUID())")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: empty) }
        XCTAssertThrowsError(try BTXGameData(resourcesDirectory: empty)) { error in
            XCTAssertEqual(error as? BTXDataError, .missingFile("Bubble Trouble X.rsrc"))
        }
    }

    func testSpriteIndex52Sets() throws {
        let sprites = try gameData().sprites
        XCTAssertEqual(sprites.dataSetIDs, [1000])               // SpIL 128 lists SpIc 1000 only
        XCTAssertEqual(sprites.setCount, 52)                     // SpIc count field stored n−1 = 0x33 (R9)
        XCTAssertEqual(sprites.cicnID(set: 1, frame: 1), 25000)
        XCTAssertEqual(sprites.cicnID(set: 1, frame: 4), 25003)
        XCTAssertEqual(sprites.frameCount(set: 1), 4)
        XCTAssertEqual(sprites.cicnID(set: 2, frame: 1), 25100)
        XCTAssertEqual(sprites.frameCount(set: 7), 16)
        XCTAssertEqual(sprites.cicnID(set: 0x0f, frame: 10), 26709)   // LEVEL digits (FI §6a notices)
        XCTAssertEqual(sprites.cicnID(set: 0x34, frame: 1), 31700)
        XCTAssertEqual(sprites.frameCount(set: 0x34), 24)

        // Synthetic: SpIc = i16 (n−1), then n × {i16 start, i16 count}.
        let spic = Data([0x00, 0x01, 0x61, 0xa8, 0x00, 0x04, 0x62, 0x0c, 0x00, 0x08])
        let index = try SpriteIndex(spilData: Data([0x00, 0x00, 0x03, 0xe8]), spicData: { id in
            id == 1000 ? spic : nil
        })
        XCTAssertEqual(index.setCount, 2)
        XCTAssertEqual(index.cicnID(set: 2, frame: 3), 25102)
        XCTAssertThrowsError(try SpriteIndex(spilData: Data([0x00, 0x00, 0x03, 0xe9]), spicData: { _ in nil })) {
            XCTAssertEqual($0 as? BTXDataError, .missingResource(type: "SpIc", id: 1001))
        }
    }

    func testRectsLeftTopRightBottom() throws {
        let rects = try gameData().rects
        XCTAssertEqual(rects.ids, Array(1...7))
        // "Interface - New Button": bytes 00a5 00e4 013b 0106 = L165 T228 R315 B262.
        XCTAssertEqual(rects.rect(1), QDRect(top: 228, left: 165, bottom: 262, right: 315))
        XCTAssertEqual(rects.rect(RectResources.newGame), rects.rect(1))
        XCTAssertEqual(rects.name(1), "Interface - New Button")
        // "Interface - Quit Button": 0199 0144 01dc 0166 = L409 T324 R476 B358.
        XCTAssertEqual(rects.rect(6), QDRect(top: 324, left: 409, bottom: 358, right: 476))
        XCTAssertNil(rects.rect(8))

        let synthetic = try RectResources.decode(Data([0x00, 0x01, 0x00, 0x02, 0x00, 0x03, 0x00, 0x04]))
        XCTAssertEqual(synthetic, QDRect(top: 2, left: 1, bottom: 4, right: 3))
        XCTAssertThrowsError(try RectResources.decode(Data(count: 7)))
    }

    func testLevelBackgroundAndMusicTable() throws {
        let data = try gameData()
        let table = data.presentation
        // FI §6a: 1–3 912/m1 · 12 13002/m4 · 21 912/m3 · 50 13004/m1.
        XCTAssertEqual(try table.background(level: 1), 912)
        XCTAssertEqual(try table.musicSet(level: 1), 1)
        XCTAssertEqual(try table.background(level: 12), 13002)
        XCTAssertEqual(try table.musicSet(level: 12), 4)
        XCTAssertEqual(try table.background(level: 21), 912)
        XCTAssertEqual(try table.musicSet(level: 21), 3)
        XCTAssertEqual(try table.background(level: 50), 13004)
        XCTAssertEqual(try table.musicSet(level: 50), 1)
        XCTAssertThrowsError(try table.background(level: 51)) {
            XCTAssertEqual($0 as? BTXDataError, .missingResource(type: "LEVL", id: 51))
        }
        // Every level's background resolves to a PICT in one of the five files, every music set to 1…4.
        for level in 1...50 {
            XCTAssertNotNil(data.data(type: "PICT", id: try table.background(level: level)), "level \(level)")
            XCTAssertTrue((1...4).contains(try table.musicSet(level: level)), "level \(level)")
        }
    }

    func testNamedMusicLookup() throws {
        let data = try gameData()
        XCTAssertEqual(data.resourceID(type: "snd ", named: "Level set 1 music.1"), 11001)
        XCTAssertNil(data.resourceID(type: "snd ", named: "Level set 5 music.1"))
        XCTAssertEqual(data.resourceID(type: "Rect", named: "Interface - Quit Button"), 6)
        for set in 1...4 {
            XCTAssertEqual(try data.musicName(set: set), "Level set \(set) music.1")
            XCTAssertEqual(try data.musicResourceID(set: set), 11000 + set)
        }
        XCTAssertThrowsError(try data.musicResourceID(set: 5))
    }

    func testTitleMusicIsSet3() throws {
        let data = try gameData()
        // `_LoadMusic(0)`: STR# 131 item 2 "Title music" is replaced by "Level set 3 music", then ".1".
        XCTAssertEqual(try data.titleMusicName(), "Level set 3 music.1")
        XCTAssertEqual(try data.titleMusicResourceID(), 11003)
        XCTAssertEqual(try data.titleMusicResourceID(), try data.musicResourceID(set: 3))
        XCTAssertEqual(BTXGameData.titleMusicSet, 3)
        XCTAssertEqual(try data.strings(131), [":BT Music:", "Title music", "Level set ", " music", "BT Music"])
    }
}
