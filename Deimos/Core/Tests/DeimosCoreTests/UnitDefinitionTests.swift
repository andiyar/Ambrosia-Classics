import XCTest
import HectorResources
@testable import DeimosCore

/// The definition master lists over the shipped data, built once for the suite.
enum RealDefinitions {
    static let loaded: Result<DefinitionLists, Error> = Result { try DefinitionLists(index: RealData.index()) }
    static func lists() throws -> DefinitionLists { try loaded.get() }
}

/// `unde` (bank unit-def-struct.md §2–§6; plan Research note 13).
final class UnitDefinitionTests: XCTestCase {
    private func raw(_ id: String) throws -> [UInt8] {
        let index = try RealData.index()
        let record = try XCTUnwrap(index.record(type: FourCC("unde")!, id: FourCC(id)!), id)
        return [UInt8](try index.data(for: record))
    }

    /// 03p1 decoded to plain text — the base of the synthetic cases (a real, complete unit).
    private func plain03p1() throws -> String {
        String(decoding: DeimosText.decode(try raw("03p1")), as: UTF8.self)
    }

    private let allSprites: (FourCC) -> Bool = { _ in true }

    private func parsePlain(_ s: String) -> (UnitDefinition, errors: [String]) {
        UnitDefinition.parse(id: FourCC("test")!, text: Array(s.utf8), spriteExists: allSprites)
    }

    func testAll386UnitsParseStrictWithZeroErrors() throws {
        let lists = try RealDefinitions.lists()
        XCTAssertEqual(lists.units.count, 386)
        XCTAssertEqual(lists.units.map(\.id), try RealData.index().records(ofType: FourCC("unde")!).map(\.id))
        let unitErrors = lists.errors.filter { $0.hasPrefix("unde ") }
        XCTAssertEqual(unitErrors, [])
        XCTAssertFalse(lists.units.contains { $0.hasDataError })
        XCTAssertEqual(Set(lists.units.map(\.id)).count, 386)
        // Layer derived from isGroundBased (census: 251 ground units).
        XCTAssertEqual(lists.units.filter { $0.layer == UnitDefinition.ground }.count, 251)
        XCTAssertTrue(lists.units.allSatisfy { $0.layer == ($0.isGroundBased ? UnitDefinition.ground : UnitDefinition.air) })
        XCTAssertTrue(lists.units.allSatisfy { $0.version == 10000 })
    }

    func testStateRuleSpawnCensus() throws {
        let units = try RealDefinitions.lists().units
        let states = units.flatMap(\.states)
        XCTAssertEqual(states.count, 1167)
        XCTAssertTrue(units.allSatisfy { $0.states.count == Int($0.numStates) })
        var numStates: [Int: Int] = [:]
        for u in units { numStates[Int(u.numStates), default: 0] += 1 }
        XCTAssertEqual(numStates, [1: 128, 2: 91, 3: 37, 4: 59, 5: 18, 6: 19, 7: 10, 8: 8, 9: 6, 10: 2, 11: 1,
                                   12: 5, 13: 1, 14: 1])
        XCTAssertTrue(states.allSatisfy { $0.numRules == 5 && $0.rules.count == 5 })
        var spawnSets: [Int: Int] = [:]
        for s in states { spawnSets[s.spawnSets.count, default: 0] += 1 }
        XCTAssertEqual(spawnSets, [0: 788, 1: 285, 2: 64, 3: 11, 4: 15, 6: 2, 7: 2])
        // The spawn-set unit references (plan note 13: stateSpawnSetSpawn 532).
        XCTAssertEqual(states.reduce(0) { $0 + $1.spawnSets.count }, 532)
        // The key with the apostrophe is read (C2 finding: 532 items).
        XCTAssertEqual(states.flatMap(\.spawnSets).count, 532)
        // Owner-linked flag (+0x11): 86 units have an owner bool TRUE in some state (python census).
        XCTAssertEqual(units.filter(\.hasOwnerLinkedState).count, 86)
    }

    func testWorkedExample03p1() throws {
        let u = try XCTUnwrap(RealDefinitions.lists().unit(FourCC("03p1")!))
        XCTAssertEqual(u.id, FourCC("03p1"))
        XCTAssertEqual(u.layer, FourCC("grnd"))
        XCTAssertTrue(u.isGroundBased)
        XCTAssertEqual(u.version, 10000)
        XCTAssertFalse(u.hasDataError)
        XCTAssertFalse(u.hasOwnerLinkedState)
        XCTAssertEqual(u.numStates, 5)
        XCTAssertEqual(u.name, "Level 3 - Pause 1")
        XCTAssertEqual(u.familyName, "Level")
        XCTAssertEqual(u.description.count, 80)
        XCTAssertTrue(u.harmlessToPlayers)
        XCTAssertEqual([u.numInGroupMin, u.numInGroupMax, u.appearsPercent], [1, 1, 100])
        XCTAssertEqual([u.initialScalePercent, u.initialVisibilityPercent], [0, 0])
        XCTAssertEqual(u.editorPreviewSpriteFace, FourCC("edpr"))
        XCTAssertEqual(u.editorPreviewSpriteFrame, 26)
        XCTAssertEqual(u.drawLayer, FourCC("defa"))
        XCTAssertEqual([u.entryNoticeSound.priority, u.shieldSound.priority, u.unshieldedSound.priority,
                        u.destructSound.priority], [50, 50, 50, 50])
        XCTAssertEqual([u.shieldsBaseAmount, u.shieldsLevelIncrement, u.shieldsMaxAmount], [0, 0, 0])

        let names = ["Wait Until Pausing", "Pause Scrolling, Spawn Buzzsaws", "Wait before Pausing Tank", "Pause Tank",
                     "Spawn Buzzsaws Again"]
        XCTAssertEqual(u.states.map(\.stateName), names)
        XCTAssertEqual(u.states.map { [$0.stateOnTimerMin, $0.stateOnTimerMax] },
                       [[180, 180], [400, 400], [140, 150], [170, 180], [500, 500]])
        XCTAssertEqual(u.states.map(\.stateOnTimerChangeTo), Array(names.dropFirst()) + ["Delete"])
        XCTAssertEqual(u.states.map(\.statePauseVerticalScrolling), [false, true, true, true, true])
        XCTAssertEqual(u.states.map(\.spawnSets.count), [0, 1, 0, 1, 1])

        let r = u.states[1].spawnSets[0]
        XCTAssertEqual(r.stateSpawnSetName, "Buzzsaw Groups - Top of Screen")
        XCTAssertEqual(r.stateSpawnSetSpawn, FourCC("bu02"))
        XCTAssertEqual([r.stateSpawnSetXOffset, r.stateSpawnSetYOffset], [208, -100])
        XCTAssertEqual([r.stateSpawnSetRateMin, r.stateSpawnSetRateMax], [90, 100])
        XCTAssertEqual([r.stateSpawnSetNumInVolleyMin, r.stateSpawnSetNumInVolleyMax], [1, 1])
        XCTAssertEqual([r.stateSpawnSetDelayBetweenEntitiesMin, r.stateSpawnSetDelayBetweenEntitiesMax], [0, 0])
        XCTAssertTrue(r.stateSpawnSetAbsoluteCoordinates)
        XCTAssertTrue(r.stateSpawnSetRepeatSpawns)
        XCTAssertFalse(r.stateSpawnSetAdjustOffsetForUnitRotation || r.stateSpawnSetDontSpawnOffscreen
                       || r.stateSpawnSetPauseAnyRotationWhileSpawning || r.stateSpawnSetSpawnIfFleeing
                       || r.stateSpawnSetSetHeading || r.stateSpawnSetStationaryOption
                       || r.stateSpawnSetTerrainEffectsOption)
        XCTAssertEqual([r.stateSpawnSetTimeToPauseRotationAfterSpawning, r.stateSpawnSetHeadingDegrees], [0, 0])
        let tank = u.states[3].spawnSets[0]
        XCTAssertEqual(tank.stateSpawnSetSpawn, FourCC("tala"))
        XCTAssertEqual([tank.stateSpawnSetXOffset, tank.stateSpawnSetYOffset, tank.stateSpawnSetRateMin,
                        tank.stateSpawnSetRateMax], [480, 101, 0, 0])

        for (s, state) in u.states.enumerated() {
            XCTAssertTrue(state.rules.allSatisfy { $0.stateRuleUnit == .none }, "state \(s)")
            XCTAssertEqual(state.activeRuleCount, 0)
            let expected = s == 0 ? ("Is Tracking Player", "Delete") : ("", "")
            XCTAssertTrue(state.rules.allSatisfy { ($0.stateRuleCondition, $0.stateRuleAction) == expected }, "state \(s)")
        }
        XCTAssertEqual(u.notes, [])
    }

    func testShieldsMaxFixUpSixUnits() throws {
        let units = try RealDefinitions.lists().units
        let ids = ["bagb", "bgpb", "cair", "icpb", "icb ", "jgbu"]
        // The shipped files write max 0 < base for exactly these six; after the parse max == base.
        var fixed: [String] = []
        for u in units {
            let rawMax = TokenReader.findAnywhere(DeimosText.decode(try raw(u.id.description)), key: "#shields_MaxAmount_FLOAT")
                .flatMap { TokenReader.parseFloat($0) }
            if let m = rawMax, m < u.shieldsBaseAmount { fixed.append(u.id.description) }
            XCTAssertGreaterThanOrEqual(u.shieldsMaxAmount, u.shieldsBaseAmount, u.id.description)
        }
        XCTAssertEqual(fixed.sorted(), ids.sorted())
        for id in ids {
            let u = try XCTUnwrap(units.first { $0.id == FourCC(id) })
            XCTAssertGreaterThan(u.shieldsBaseAmount, 0, id)
            XCTAssertEqual(u.shieldsMaxAmount, u.shieldsBaseAmount, id)
            XCTAssertEqual(u.shieldsLevelIncrement, 0, id)
        }
    }

    func testNoMissingSpriteResets() throws {
        let lists = try RealDefinitions.lists()
        // No unit logs anything at parse: no missing sprite, no unused timer, no spawn set with spawn none.
        XCTAssertEqual(lists.notes.filter { $0.hasPrefix("unde ") }, [])
        let faces = lists.units.flatMap { $0.states.map(\.stateSpriteFace) }
        XCTAssertEqual(faces.count, 1167)
        // Synthetic: an unknown face is reset to none with the original's line.
        var text = try plain03p1()
        text = text.replacingOccurrences(of: "#editorPreviewSpriteFace_ID <edpr>", with: "#editorPreviewSpriteFace_ID <zzzz>")
        let (u, errors) = UnitDefinition.parse(id: FourCC("test")!, text: Array(text.utf8),
                                               spriteExists: { $0 != FourCC("zzzz") })
        XCTAssertEqual(errors, [])
        XCTAssertEqual(u.editorPreviewSpriteFace, .none)
        XCTAssertEqual(u.notes, ["MISSING SPRITE RESOURCE:  A reference was found to an unknown Sprite Group ('zzzz')."])
    }

    func testPlainTextUnitParsesWithoutDecode() throws {
        let encoded = try raw("03p1")
        let plain = try plain03p1()
        let fromEncoded = UnitDefinition.parse(id: FourCC("03p1")!, text: encoded, spriteExists: allSprites)
        let fromPlain = UnitDefinition.parse(id: FourCC("03p1")!, text: Array(plain.utf8), spriteExists: allSprites)
        XCTAssertEqual(fromEncoded.errors, [])
        XCTAssertEqual(fromPlain.errors, [])
        XCTAssertEqual(fromPlain.0, fromEncoded.0)
        // Without `#name_STR` the plain text is "decoded" into noise: every key missing.
        let noName = plain.replacingOccurrences(of: "#name_STR <Level 3 - Pause 1>", with: "")
        let (garbled, errors) = parsePlain(noName)
        XCTAssertTrue(garbled.hasDataError)
        XCTAssertEqual(errors.last, "A Unit Definition file contained incorrect or missing data.")
        XCTAssertEqual(garbled.states.count, 0)
    }

    func testMissingIntIsAnErrorMissingStringIsNot() throws {
        let plain = try plain03p1()
        let noFamily = plain.replacingOccurrences(of: "#familyName_STR <Level>\n", with: "")
        let (a, ea) = parsePlain(noFamily)
        XCTAssertEqual(ea, [])
        XCTAssertEqual(a.familyName, "")
        XCTAssertFalse(a.hasDataError)
        let noGroupMax = plain.replacingOccurrences(of: "#numInGroupMax_INT <1>\n", with: "")
        let (b, eb) = parsePlain(noGroupMax)
        XCTAssertEqual(eb, ["#numInGroupMax_INT", "A Unit Definition file contained incorrect or missing data."])
        XCTAssertTrue(b.hasDataError)
        XCTAssertEqual(b.numInGroupMax, 1) // default kept
        // A malformed ID (not 4 chars) is an error too, default kept.
        let badID = plain.replacingOccurrences(of: "#drawLayer_ID <defa>", with: "#drawLayer_ID <def>")
        let (c, ec) = parsePlain(badID)
        XCTAssertEqual(ec.first, "#drawLayer_ID")
        XCTAssertEqual(c.drawLayer, .none)
        // `<>` for a string overrides a default.
        XCTAssertEqual(UnitState.defaults(index: 0).stateName, "State 1")
        let emptyName = plain.replacingOccurrences(of: "#stateName_STR <Wait Until Pausing>", with: "#stateName_STR <>")
        XCTAssertEqual(parsePlain(emptyName).0.states[0].stateName, "")
    }

    func testNumStatesOver20Reported() throws {
        let plain = try plain03p1()
        let (u21, e21) = parsePlain(plain.replacingOccurrences(of: "#numStates_INT <5>", with: "#numStates_INT <21>"))
        XCTAssertEqual(u21.states.count, 21) // no cap: the parse loops as read
        XCTAssertTrue(e21.contains("ERROR:  incorrect number of states (21) in Unit Def \"Level 3 - Pause 1\""))
        XCTAssertTrue(e21.contains("unitPtr->fileData.numStatesUsed > 0 and unitPtr->fileData.numStatesUsed <= kG_UnitDef_MaxNumStates"))
        let (u20, e20) = parsePlain(plain.replacingOccurrences(of: "#numStates_INT <5>", with: "#numStates_INT <20>"))
        XCTAssertEqual(u20.states.count, 20)
        XCTAssertFalse(e20.contains { $0.hasPrefix("ERROR:  incorrect number of states") })
        // 0 is accepted silently (the check fires only for < 0 or > 20).
        let (u0, e0) = parsePlain(plain.replacingOccurrences(of: "#numStates_INT <5>", with: "#numStates_INT <0>"))
        XCTAssertEqual(u0.states.count, 0)
        XCTAssertEqual(e0, [])
        let (_, eNeg) = parsePlain(plain.replacingOccurrences(of: "#numStates_INT <5>", with: "#numStates_INT <-1>"))
        XCTAssertTrue(eNeg.contains("ERROR:  incorrect number of states (-1) in Unit Def \"Level 3 - Pause 1\""))
    }

    func testUnusedStateTimerZeroed() throws {
        let plain = try plain03p1()
        // State 0's timer (180/180) loses its target → note, both timers 0.
        let noTarget = plain.replacingOccurrences(of: "#stateOnTimerChangeTo_STR <Pause Scrolling, Spawn Buzzsaws>",
                                                  with: "#stateOnTimerChangeTo_STR <>")
        let (u, errors) = parsePlain(noTarget)
        XCTAssertEqual(errors, [])
        XCTAssertEqual([u.states[0].stateOnTimerMin, u.states[0].stateOnTimerMax], [0, 0])
        XCTAssertEqual(u.notes, ["    NOTE: A Unit Definition has an unused State Change Timer."])
        XCTAssertEqual([u.states[1].stateOnTimerMin, u.states[1].stateOnTimerMax], [400, 400])
        // max < min → max = min (state 2: 150/140 → 150/150).
        let swapped = plain.replacingOccurrences(of: "#stateOnTimerMin_INT <140>\n#stateOnTimerMax_INT <150>",
                                                 with: "#stateOnTimerMin_INT <150>\n#stateOnTimerMax_INT <140>")
        let s2 = parsePlain(swapped).0.states[2]
        XCTAssertEqual([s2.stateOnTimerMin, s2.stateOnTimerMax], [150, 150])
    }

    func testForwardCursorMisparseFollowsOriginal() throws {
        var plain = try plain03p1()
        // Remove state 0's stateOnCounter and make state 1's distinctive: state 0 then reads state 1's
        // value (strstr from the cursor runs into the next block) and the rest of state 0 misparses.
        let key = "#stateOnCounter_INT <0>\n"
        plain = plain.replacingOccurrences(of: key, with: "", options: [], range: plain.range(of: key))
        plain = plain.replacingOccurrences(of: key, with: "#stateOnCounter_INT <77>\n", options: [], range: plain.range(of: key))
        let (u, errors) = parsePlain(plain)
        XCTAssertEqual(u.states[0].stateOnCounter, 77)
        XCTAssertEqual(u.states[0].stateName, "Wait Until Pausing")
        // State 0's later keys came from state 1's block; the last state runs out of keys → errors.
        XCTAssertEqual(u.states[0].statePauseVerticalScrolling, true)
        XCTAssertFalse(errors.isEmpty)
        XCTAssertEqual(errors.last, "A Unit Definition file contained incorrect or missing data.")
        XCTAssertTrue(u.hasDataError)
    }
}
