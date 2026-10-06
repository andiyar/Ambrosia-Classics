import XCTest
@testable import DeimosCore

/// `DeimosAssets` and `LevelOrder` over the committed data (plan C1; probes p01, p02, p04, p05).
final class AssetsTests: XCTestCase {
    /// One load per test process (the definitions parse every unde/leve).
    static let loaded: Result<DeimosAssets, Error> = Result { try DeimosAssets.load(index: RealData.index()) }
    private func assets() throws -> DeimosAssets { try Self.loaded.get() }

    /// `FUN_1001fcf0`/`FUN_1001fe60`/`FUN_100204a0`/`FUN_1000ed60` (data-tags §2–§5, hud-scorebar §9; p04, p05).
    func testPermanentLists() throws {
        let a = try assets()
        XCTAssertEqual(a.floats.count, 220)
        XCTAssertEqual(a.floats[18], 2)
        XCTAssertEqual(a.floats[33], 2)
        XCTAssertEqual(a.floats[54], 416)
        XCTAssertEqual(a.floats[55], 480)
        XCTAssertEqual(a.floats[59], 32)
        XCTAssertEqual(a.floats[166], 1)
        XCTAssertEqual(a.floats[183], 13)
        XCTAssertEqual(a.formats.count, 54)
        XCTAssertEqual(a.formatIDs.count, 54)
        XCTAssertEqual(a.formatIDs[41], FourCC("sbsh"))
        XCTAssertEqual(a.formatIDs[43], FourCC("sbs1"))
        XCTAssertEqual(a.formatIDs[45], FourCC("sbl1"))
        XCTAssertEqual(a.formatIDs[47], FourCC("sll1"))
        XCTAssertEqual(a.formats[43].locX, 494)
        XCTAssertEqual(a.formats[43].locY, 83)
        XCTAssertEqual(a.gameStrings.count, 37)
        XCTAssertEqual(a.gameString(0), "Press Caps Lock")
        XCTAssertEqual(a.objects.count, 40)
        XCTAssertEqual(a.sounds.count, 24)
        XCTAssertEqual(a.sprites.map(\.description), ["vigr", "edut", "pl1o", "mebu", "mebh", "galo", "mebu", "mebh"])
        XCTAssertEqual(a.fonts.map(\.description), ["tesm", "tesm", "tesm"])
        XCTAssertEqual(a.rects.count, 22)
        XCTAssertEqual(a.colors.count, 1)
        // The sprite-group cache returns the same group twice.
        let g = try a.spriteGroup(FourCC("pl1o")!)
        XCTAssertEqual(g.frames.count, 7)
        XCTAssertEqual(try a.spriteGroup(FourCC("pl1o")!).frames, g.frames)
    }

    /// engine-loop §6 (HIGH): the 12 identifiers matched against `#indentifier_STR`.
    func testLevelOrder() throws {
        let order = try assets().levelOrder
        let expected = ["le07", "le06", "le02", "le08", "le11", "le04", "le12", "le03", "le05", "le01", "le10", "le09"]
        XCTAssertEqual((1...12).map { order.level(sector: $0).description }, expected)
        XCTAssertEqual(order.level(sector: 0), .none)
        XCTAssertEqual(order.level(sector: 13), .none)
        for (i, id) in expected.enumerated() { XCTAssertEqual(order.sector(of: FourCC(id)!), i + 1, id) }
        XCTAssertNil(order.sector(of: .none))
    }

    /// p01: le07 "Mariner Valley".
    func testLevelOneDefinition() throws {
        let a = try assets()
        let id = a.levelOrder.level(sector: 1)
        let level = try XCTUnwrap(a.definitions.levels.first { $0.id == id })
        XCTAssertEqual(level.id, FourCC("le07"))
        XCTAssertEqual(level.name, "Mariner Valley")
        XCTAssertEqual(level.backgroundImage, FourCC("jum2"))
        XCTAssertEqual(level.mediaMask, FourCC("jut2"))
        XCTAssertEqual(level.music, FourCC("mu03"))
        XCTAssertEqual(level.background, MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        XCTAssertEqual(level.objects.count, 38)
        XCTAssertFalse(level.objects.contains { $0.yLoc >= 3056 })
    }

    /// p02: the PEAA weapons available in sector 1.
    func testSectorOneWeapons() throws {
        let a = try assets()
        let peaa = FourCC("PEAA")!
        let sectorOne = a.definitions.weapons.filter {
            $0.type == peaa && $0.minimumLevelAvailable <= 1 && 1 <= $0.maximumLevelAvailable
        }
        XCTAssertEqual(sectorOne.map(\.id.description), ["aiic"])
        let w = try XCTUnwrap(sectorOne.first)
        XCTAssertEqual(w.player1AppearanceFace, FourCC("pl1o"))
        XCTAssertEqual(w.player2AppearanceFace, FourCC("pl2o"))
        XCTAssertEqual(w.scoreBarPreviewFace, FourCC("wesy"))
        XCTAssertEqual(w.scoreBarPreviewFrame, 0)
    }
}
