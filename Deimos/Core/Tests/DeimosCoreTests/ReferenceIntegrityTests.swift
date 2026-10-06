import XCTest
import HectorResources
@testable import DeimosCore

/// Every cross-reference the shipped data makes resolves through the tag index (plan Task C7,
/// Research note 13): the permanent ID lists, the level resources, the unit-ID references inside
/// `unde`, and every sprite face / sound ID a unit names. "Resolves" = the original's own lookup
/// (`TagIndex.record(type:id:)`, first in list order) finds a tag; a sprite face resolves when the
/// group's colour plate AND its alpha plate (`upper(id)`) are both `im08` tags.
final class ReferenceIntegrityTests: XCTestCase {
    private let im08 = FourCC("im08")!, im16 = FourCC("im16")!, soun = FourCC("soun")!
    private let unde = FourCC("unde")!, plde = FourCC("plde")!, tefo = FourCC("tefo")!

    private func idList(_ id: String) throws -> [FourCC] {
        let index = try RealData.index()
        let r = try XCTUnwrap(index.record(type: FourCC("idli")!, id: FourCC(id)!), id)
        return try IDList(data: index.data(for: r)).items.map(\.id)
    }

    private func isSpriteGroup(_ id: FourCC, _ index: TagIndex) -> Bool {
        index.record(type: im08, id: id) != nil
            && index.record(type: im08, id: SpriteGroup.alphaPlateID(for: id)) != nil
    }

    func testPermanentListsResolve() throws {
        let index = try RealData.index()
        let gasp = try idList("gasp")
        XCTAssertEqual(gasp.count, 8)
        XCTAssertTrue(gasp.allSatisfy { isSpriteGroup($0, index) }, "\(gasp)")
        let gaso = try idList("gaso")
        XCTAssertEqual(gaso.count, 24)
        // `none` = "no resource" (the engine's sentinel): those slots name no sound by design.
        XCTAssertEqual(gaso.filter { $0 != .none && index.record(type: soun, id: $0) == nil }, [])
        XCTAssertEqual(gaso.indices.filter { gaso[$0] == .none }, [9, 17, 19])     // 21 name a soun tag
        let gaob = try idList("gaob")
        XCTAssertEqual(gaob.count, 40)
        let gaobUnits = gaob.filter { index.record(type: unde, id: $0) != nil }
        let gaobPlayers = gaob.filter { index.record(type: plde, id: $0) != nil }
        XCTAssertEqual(gaobUnits.count, 38)
        XCTAssertEqual(gaobPlayers.map(\.description), ["pl01", "pl02"])
        XCTAssertEqual(gaobUnits.count + gaobPlayers.count, gaob.count)
        let gate = try idList("gate")
        XCTAssertEqual(gate.count, 54)
        XCTAssertEqual(gate.filter { index.record(type: tefo, id: $0) == nil }, [])
        XCTAssertEqual(Set(gate).count, 54)                       // every text format named once
        let tesp = try idList("tesp")
        XCTAssertEqual(tesp.map(\.description), ["tesm", "tesm", "tesm"])
        XCTAssertTrue(isSpriteGroup(tesp[0], index))
    }

    func testLevelResourcesResolve() throws {
        let index = try RealData.index()
        let levels = try RealDefinitions.lists().levels
        XCTAssertEqual(levels.count, 12)
        for l in levels {
            for image in [l.backgroundImage, l.previewImage, l.mediaMask] {
                XCTAssertNotNil(index.record(type: im16, id: image), "\(l.id) → im16 '\(image)'")
            }
            XCTAssertNotNil(index.record(type: soun, id: l.music), "\(l.id) → soun '\(l.music)'")
        }
        // 36 distinct images (a map, a preview and a mask per level).
        XCTAssertEqual(Set(levels.flatMap { [$0.backgroundImage, $0.previewImage, $0.mediaMask] }).count, 36)
    }

    func testUnitReferencesResolve() throws {
        let index = try RealData.index()
        let units = try RealDefinitions.lists().units
        let states = units.flatMap(\.states)
        func refs(_ ids: [FourCC]) -> [FourCC] { ids.filter { $0 != .none } }
        let families: [(String, [FourCC], Int)] = [
            ("stateSpawnSetSpawn", refs(states.flatMap(\.spawnSets).map(\.stateSpawnSetSpawn)), 532),
            ("destructSpawn", refs(units.map(\.destructSpawn)), 99),
            ("stateRuleUnit", refs(states.flatMap(\.rules).map(\.stateRuleUnit)), 93),
            ("destructCoin", refs(units.map(\.destructCoin)), 28),
            ("destructCoinOnGroupKill", refs(units.map(\.destructCoinOnGroupKill)), 15),
            ("collision_Spawn", refs(states.map(\.collisionSpawn)), 5),
        ]
        var total = 0
        for (name, ids, expected) in families {
            XCTAssertEqual(ids.count, expected, name)
            XCTAssertEqual(ids.filter { index.record(type: unde, id: $0) == nil }, [], name)
            total += ids.count
        }
        XCTAssertEqual(total, 772)
    }

    func testUnitFacesAndSoundsResolve() throws {
        let index = try RealData.index()
        let lists = try RealDefinitions.lists()
        let units = lists.units, states = units.flatMap(\.states)
        // 1,553 sprite faces = 1,167 state faces + 386 editor preview faces; every one names a group or
        // is `none`, and the parse-time MISSING SPRITE reset never fired.
        let faces = states.map(\.stateSpriteFace) + units.map(\.editorPreviewSpriteFace)
        XCTAssertEqual(faces.count, 1553)
        XCTAssertEqual(faces.filter { $0 != .none && !isSpriteGroup($0, index) }.map(\.description), [])
        XCTAssertEqual(faces.filter { $0 == .none }.count, 675)                  // 878 name a group
        XCTAssertFalse(lists.notes.contains { $0.contains("MISSING SPRITE") })
        // 2,711 sound IDs = 4 records per unit (destruct, entry notice, shield, unshielded) + 1 per state.
        let sounds = units.flatMap { [$0.destructSound.id, $0.entryNoticeSound.id, $0.shieldSound.id,
                                      $0.unshieldedSound.id] } + states.map(\.stateEntrySound.id)
        XCTAssertEqual(sounds.count, 2711)
        XCTAssertEqual(sounds.filter { $0 != .none && index.record(type: soun, id: $0) == nil }, [])
        XCTAssertEqual(sounds.filter { $0 == .none }.count, 2320)                // 391 name a soun tag
    }

    func testGlyphFontHas91Frames() throws {
        // data-tags.md §5 glyph order: A–Z 0–25, a–z 26–51, "1234567890" 52–61, punctuation 62–89
        // (`( [ {` share 69, `) ] }` share 70), any other byte → 90 (the invisible 4-px space).
        var glyph: [Character: Int] = [:]
        for (i, c) in "ABCDEFGHIJKLMNOPQRSTUVWXYZ".enumerated() { glyph[c] = i }
        for (i, c) in "abcdefghijklmnopqrstuvwxyz".enumerated() { glyph[c] = 26 + i }
        for (i, c) in "1234567890".enumerated() { glyph[c] = 52 + i }
        for (i, c) in "!\"#$%&'(".enumerated() { glyph[c] = 62 + i }
        glyph["["] = 69; glyph["{"] = 69
        for (i, c) in ")*+,-./:;<=>?@\\^_`|~".enumerated() { glyph[c] = 70 + i }
        glyph["]"] = 70; glyph["}"] = 70
        XCTAssertEqual(Set(glyph.values), Set(0...89))
        let tesm = try SpriteGroup.load(id: FourCC("tesm")!, index: RealData.index())
        XCTAssertEqual(tesm.frames.count, 91)
        // Every mapped glyph (0–89) is a visible frame; the default/space frame 90 has no alpha map.
        XCTAssertEqual((0...89).filter { tesm.frames[$0].alphaMap == nil }, [])
        XCTAssertNil(tesm.frames[90].alphaMap)
        XCTAssertEqual(tesm.frames[90].width, 4)
        // One strip: every glyph shares the plate's text height band (13 rows, top 3).
        XCTAssertEqual(Set(tesm.frames.map(\.rect.top)), [3])
    }
}
