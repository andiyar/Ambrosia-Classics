import XCTest
import HectorResources
@testable import DeimosCore

/// `plde` (unit-def-struct.md §9), `wede` (weapons-projectiles.md §1, data-tags.md §6), `leve`
/// (waves-and-enemies.md §1, level-scroll-objects.md §6.1).
final class PlayerWeaponLevelTests: XCTestCase {
    private func raw(_ type: String, _ id: String) throws -> [UInt8] {
        let index = try RealData.index()
        let record = try XCTUnwrap(index.record(type: FourCC(type)!, id: FourCC(id)!), "\(type)/\(id)")
        return [UInt8](try index.data(for: record))
    }

    func testTwoPlayerDefinitions57Keys() throws {
        let lists = try RealDefinitions.lists()
        XCTAssertEqual(lists.players.map(\.id.description), ["pl01", "pl02"])
        XCTAssertEqual(lists.errors.filter { $0.hasPrefix("plde ") }, [])
        XCTAssertEqual(lists.notes.filter { $0.hasPrefix("plde ") }, [])
        for p in lists.players {
            XCTAssertEqual(TokenReader.items(DeimosText.decode(try raw("plde", p.id.description))).count, 57)
        }
        let p1 = lists.players[0], p2 = lists.players[1]
        XCTAssertEqual(p1.name, "Player 1")
        XCTAssertEqual(p2.name, "Player 2")
        // Known delta 5: `<100.000000>` / `<15.000000>` read with %i.
        XCTAssertEqual([p1.defaultShieldPercentage, p1.shieldWarningPercentage, p1.shieldBaseHitPercentage], [100, 15, 15])
        XCTAssertEqual(p1.hitGlowColor, 0x7FFF)
        XCTAssertEqual([p1.lifeMaxNum, p1.lifeNumInitial, p1.lifeInitialRequiredScore, p1.lifeAdditionalRequiredScore],
                       [10, 3, 10000, 30000])
        XCTAssertEqual([p1.entrySoloStartX, p1.entrySoloStartY, p1.entryMultiStartX, p1.entryMultiStartY], [208, 330, 104, 330])
        XCTAssertEqual(p2.entryMultiStartX, 312)
        XCTAssertEqual(p1.entryStartVelocityY, Float(-7.2))
        XCTAssertEqual(p1.entryVelocityDelta, Float(0.05))
        XCTAssertEqual([p1.entryInitialDelay, p1.entryInvulnerabilityTime, p1.deathDuration], [55, 60, 90])
        XCTAssertEqual([p1.waitingTime, p1.filmIntroTime, p1.introTime, p1.gameOverTime, p1.dyingTime, p1.finalDyingTime],
                       [60, 60, 56, 20, 80, 40])
        XCTAssertEqual(p1.activeMoneyCounterSpawn, FourCC("p1mc"))
        XCTAssertEqual(p2.activeMoneyCounterSpawn, FourCC("p2mc"))
        XCTAssertEqual([p1.activeDefaultMaxSpeed, p1.activeVelocityDelta], [Float(7.8), Float(1.6)])
        XCTAssertEqual([p1.powerupOverloadNumWarnings, p1.powerupOverloadInitialTimeBetweenWarnings,
                        p1.powerupOverloadMinimumTimeBetweenWarnings], [8, 8, 3])
        XCTAssertEqual(p1.powerupOverloadSound.id, FourCC("wewa"))
        XCTAssertEqual(p1.powerupOverloadSound.priority, 90)
        // The four sprites (Power read before Shield) exist and are kept.
        XCTAssertEqual([p1.spriteHighScore, p1.spriteScoreBar, p1.spriteScoreBarPower, p1.spriteScoreBarShield].map(\.description),
                       ["play", "play", "shme", "shme"])
        XCTAssertEqual([p1.spriteScoreBarPowerFrame, p1.spriteScoreBarShieldFrame], [1, 0])
        XCTAssertEqual([p2.spriteHighScoreFrame, p2.spriteScoreBarFrame], [1, 1])
        // Strict mode: a missing INT is the fatal load error.
        let plain = String(decoding: DeimosText.decode(try raw("plde", "pl01")), as: UTF8.self)
            .replacingOccurrences(of: "#introTime_INT <56>\n", with: "")
        let (_, errors) = PlayerDefinition.parse(id: FourCC("pl01")!, text: DeimosText.decode(Array(plain.utf8)),
                                                 spriteExists: { _ in true })
        XCTAssertEqual(errors, ["#introTime_INT", "A Player Definition file contained incorrect or missing data."])
    }

    func testFiveWeaponsInIndexOrder() throws {
        let lists = try RealDefinitions.lists()
        let w = lists.weapons
        XCTAssertEqual(w.map(\.id.description), ["aibg", "aiic", "aipb", "airg", "plbo"])
        XCTAssertEqual(lists.errors.filter { $0.hasPrefix("wede ") }, [])
        XCTAssertEqual(lists.notes.filter { $0.hasPrefix("wede ") }, [])
        XCTAssertEqual(w.map(\.spawns.count), [8, 3, 1, 1, 2])
        XCTAssertEqual(w.reduce(0) { $0 + $1.spawns.count }, 15)
        XCTAssertEqual(w.map(\.type.description), ["PEAA", "PEAA", "PEAA", "PEAA", "PEAG"])
        XCTAssertEqual(w.map(\.default.description), ["none", "DEAA", "none", "none", "DEAG"])
        XCTAssertEqual(w.map(\.minimumLevelAvailable), [2, 1, 5, 3, 0])
        XCTAssertEqual(w.map(\.maximumLevelAvailable), [9999, 3, 9999, 9999, 9999])
        XCTAssertEqual(w.map(\.delayBetweenLaunches), [5, 4, 8, 8, 4])
        XCTAssertEqual(w.map(\.powerupAir.maxPowerLevel), [20, 20, 22, 12, 0])
        XCTAssertEqual(w.map(\.powerupAir.overloadTime), [180, 180, 0, 180, 0])
    }

    func testWeaponWorkedExample() throws {
        let w = try XCTUnwrap(RealDefinitions.lists().weapons.first { $0.id == FourCC("aiic") })
        XCTAssertEqual(w.name, "Air - Ion Cannon")
        XCTAssertEqual(w.description1, "Basic pairs of bullets.")
        XCTAssertEqual(w.description2, " ")
        XCTAssertEqual(w.scoreBarPreviewFace, FourCC("wesy"))
        XCTAssertEqual([w.player1AppearanceFace, w.player2AppearanceFace].map(\.description), ["pl1o", "pl2o"])
        XCTAssertEqual(w.playerGlow, 0x7F60) // F8D800
        XCTAssertEqual(w.selectionSound.priority, 50)
        XCTAssertEqual(w.ammoWarning, "none")
        XCTAssertFalse(w.autoRepeat)
        XCTAssertEqual(w.spawns.map(\.unit.description), ["icb ", "icbf", "icb "])
        XCTAssertEqual(w.spawns.map(\.name), ["Left", "Bullet Flash", "Right"])
        XCTAssertEqual(w.spawns.map { [$0.xLoc, $0.yLoc, $0.angle] }, [[-5, 0, 0], [0, -8, 0], [4, 0, 0]])
        let air = w.powerupAir
        XCTAssertEqual([air.timeUntilActivation, air.timeBetweenPowerLevelChanges, air.maxPowerLevel, air.overloadTime,
                        air.timeBetweenReleaseSpawns], [15, 2, 20, 180, 1])
        XCTAssertEqual([air.activationSpawn, air.releaseSpawn].map(\.description), ["icpo", "icps"])
        XCTAssertFalse(air.doReleaseOnMaxPowerLevel)
        XCTAssertEqual(w.powerupGround, WeaponDefinition.PowerUp())

        let bomb = try XCTUnwrap(RealDefinitions.lists().weapons.first { $0.id == FourCC("plbo") })
        XCTAssertEqual([bomb.crosshairFace, bomb.crosshairLockedFace].map(\.description), ["pbta", "pbta"])
        XCTAssertEqual([bomb.crosshairFrame, bomb.crosshairLockedFrame, bomb.crosshairYOffset, bomb.delayBetweenLoadLaunches],
                       [0, 1, -121, 1])
        XCTAssertEqual(bomb.spawns.map { "\($0.unit) \($0.xLoc),\($0.yLoc)" }, ["plbo 0,0", "pblf 0,-6"])

        // Synthetic (plain text keeps `#type_ID`, so it is not decoded): max level < 1 → 9999, angles
        // brought into [0, 360), unknown sprites → none.
        var text = String(decoding: DeimosText.decode(try raw("wede", "aiic")), as: UTF8.self)
        text = text.replacingOccurrences(of: "#maximumLevelAvailable_INT <3>", with: "#maximumLevelAvailable_INT <0>")
        text = text.replacingOccurrences(of: "#spawn_XLoc_INT <-5>\n    #spawn_YLoc_INT <0>\n    #spawn_SetHeading_BOOL <FALSE>\n    #spawn_Angle_INT <0>",
                                         with: "#spawn_XLoc_INT <-5>\n    #spawn_YLoc_INT <0>\n    #spawn_SetHeading_BOOL <TRUE>\n    #spawn_Angle_INT <-10>")
        text = text.replacingOccurrences(of: "#spawn_YLoc_INT <-8>\n    #spawn_SetHeading_BOOL <FALSE>\n    #spawn_Angle_INT <0>",
                                         with: "#spawn_YLoc_INT <-8>\n    #spawn_SetHeading_BOOL <FALSE>\n    #spawn_Angle_INT <400>")
        text = text.replacingOccurrences(of: "#spawn_XLoc_INT <4>\n    #spawn_YLoc_INT <0>\n    #spawn_SetHeading_BOOL <FALSE>\n    #spawn_Angle_INT <0>",
                                         with: "#spawn_XLoc_INT <4>\n    #spawn_YLoc_INT <0>\n    #spawn_SetHeading_BOOL <FALSE>\n    #spawn_Angle_INT <800>")
        let (s, errors) = WeaponDefinition.parse(id: FourCC("aiic")!, text: Array(text.utf8),
                                                 spriteExists: { $0 != FourCC("pl2o") })
        XCTAssertEqual(errors, [])
        XCTAssertEqual(s.maximumLevelAvailable, 9999)
        XCTAssertEqual(s.spawns.map(\.angle), [350, 40, 0])
        XCTAssertTrue(s.spawns[0].setHeading)
        XCTAssertEqual(s.player2AppearanceFace, .none)
        XCTAssertEqual(s.notes, ["MISSING SPRITE RESOURCE:  A reference was found to an unknown Sprite Group ('pl2o')."])
    }

    func testTwelveLevels565Objects() throws {
        let lists = try RealDefinitions.lists()
        let levels = lists.levels
        // Tag-index order = Game.pak central-directory order (python list_paks.py): le09/le10 were
        // added to the pak last. The play order comes from the level-order table, not from this list.
        XCTAssertEqual(levels.map(\.id.description), ["le01", "le02", "le03", "le04", "le05", "le06", "le07", "le08",
                                                      "le11", "le12", "le09", "le10"])
        XCTAssertEqual(lists.errors.filter { $0.hasPrefix("leve ") }, [])
        XCTAssertEqual(lists.notes.filter { $0.hasPrefix("leve ") }, [])
        XCTAssertEqual(levels.map(\.objects.count), [46, 44, 44, 43, 51, 43, 38, 49, 40, 40, 67, 60])
        XCTAssertEqual(levels.map(\.numObjects), levels.map { Int32($0.objects.count) })
        XCTAssertEqual(levels.reduce(0) { $0 + $1.objects.count }, 565)
        for l in levels {
            XCTAssertEqual(l.background, MacRect(top: 0, left: 0, bottom: 3600, right: 480), l.name)
            XCTAssertEqual(l.music, FourCC("mu03"), l.name)
            XCTAssertEqual(l.briefing, .none, l.name)
        }
        XCTAssertEqual(levels.map(\.name).first, "Kepler Massif")
        XCTAssertEqual(levels.map(\.name).last, "Thermopylae")
        // Placement layers (waves-and-enemies.md §1 census): grnd 353, air 212.
        let layers = levels.flatMap { $0.objects.map(\.layer.description) }
        XCTAssertEqual(layers.filter { $0 == "grnd" }.count, 353)
        XCTAssertEqual(layers.filter { $0 == "air " }.count, 212)
    }

    func testLevel07Header() throws {
        let l = try XCTUnwrap(RealDefinitions.lists().levels.first { $0.id == FourCC("le07") })
        XCTAssertEqual(l.name, "Mariner Valley")
        XCTAssertEqual(l.indentifier, "Lucena")
        XCTAssertEqual(l.description, "Jungle combat over the Mariner Valley forestation project.")
        XCTAssertEqual(l.copyright, "Map by Sheryn Wareing.")
        XCTAssertEqual([l.backgroundImage, l.previewImage, l.music, l.mediaMask, l.briefing].map(\.description),
                       ["jum2", "jup2", "mu03", "jut2", "none"])
        XCTAssertEqual(l.numObjects, 38)
        XCTAssertEqual(l.objects.count, 38)
        let first = l.objects[0]
        XCTAssertEqual(first.unit, FourCC("plla"))
        XCTAssertEqual(first.layer, FourCC("grnd"))
        XCTAssertEqual([first.xLoc, first.yLoc], [126, 2563])
        // Header-only variant: same header, no objects.
        let (h, errors) = LevelDefinition.parseHeaderOnly(id: l.id, text: try raw("leve", "le07"))
        XCTAssertEqual(errors, [])
        XCTAssertEqual(h.objects, [])
        XCTAssertEqual(h.numObjects, 38)
        var header = l
        header.objects = []
        XCTAssertEqual(h, header)
    }

    func testEveryPlacedUnitExists() throws {
        let lists = try RealDefinitions.lists()
        let objects = lists.levels.flatMap(\.objects)
        XCTAssertEqual(objects.count, 565)
        XCTAssertTrue(objects.allSatisfy { lists.unit($0.unit) != nil })
        XCTAssertEqual(Set(objects.map(\.unit)).count, 114)
    }

    func testUnknownUnitDropsAndDecrements() throws {
        func object(_ unit: String, _ x: Int) -> String {
            "#unit_ID <\(unit)>\n#layer_ID <grnd>\n#xLoc_INT <\(x)>\n#yLoc_INT <10>\n#headingDegrees_INT <0>\n"
                + "#isStationary_BOOL <FALSE>\n#enableTerrainEffects_BOOL <TRUE>\n"
        }
        let header = "#name_STR <Test>\n#indentifier_STR <T>\n#description_STR <>\n#copyright_STR <>\n"
            + "#background_RECT <0, 0, 480, 3600>\n#backgroundImage_ID <jum2>\n#previewImage_ID <jup2>\n"
            + "#music_ID <mu03>\n#mediaMask_ID <jut2>\n#briefing_ID <none>\n#numObjects_INT <3>\n"
        let text = header + object("zzzz", 1) + object("plla", 2) + object("plla", 3)
        let encoded = DeimosText.decode(Array(text.utf8))
        let (l, errors) = LevelDefinition.parse(id: FourCC("test")!, text: encoded, unitExists: { $0 != FourCC("zzzz") })
        XCTAssertEqual(errors, [])
        // Object 0 dropped AND the count decremented while the index advances: object 2 is lost too.
        XCTAssertEqual(l.numObjects, 2)
        XCTAssertEqual(l.objects.map(\.xLoc), [2])
        XCTAssertTrue(l.objects[0].enableTerrainEffects)
        XCTAssertEqual(l.notes.count, 1)
        // Header only: nothing dropped, nothing built.
        let (h, _) = LevelDefinition.parseHeaderOnly(id: FourCC("test")!, text: encoded)
        XCTAssertEqual(h.numObjects, 3)
        XCTAssertEqual(h.objects, [])
    }

    func testLayerIdAgreesWithGroundFlag() throws {
        let lists = try RealDefinitions.lists()
        let objects = lists.levels.flatMap(\.objects)
        let agreeing = objects.filter { o in lists.unit(o.unit).map { $0.layer == o.layer } ?? false }
        XCTAssertEqual(agreeing.count, 565)
    }
}
