import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-L10L11 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-L10L11`): level 11 "River of Fears"
/// enterable — every one of its 397 records sets up (59 types; LL §4 "Level 11"), its header switches as read (the
/// submerged tint, the ripple, the camera offset, the landing damage, the ice, the current, the facing), its music cue,
/// and Nimbo (2955, record 135) opening Mcnv 206 on contact while record 283 (2956, flag 99, Mcnv 220) stays dormant.
/// The parameter trace ("Every level task") is pinned inside `testLevel11SetsUpEveryRecord`, one assert a value.
/// Against the committed `Resources/Ferazel` (D26); a missing data file is a FAILURE, never a skip. Proof-B rules.
final class LevelElevenTests: XCTestCase {

    func testLevel11SetsUpEveryRecord() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 11)
        let census = try TenEleven.census(r, level: 11)
        XCTAssertEqual(census.records, 397)
        XCTAssertEqual(census.types, 59)
        XCTAssertEqual(census.refused, [], "every record sets up — no `notTranscribed`, per record")
        XCTAssertEqual(census.created, 397)
        XCTAssertEqual(census.refusedSpawns, 0, "no spawn dropped for want of a record (known deviation 6)")

        // The header switches new against levels 1–5 (LL §4 "Level 11" item 1), as read.
        let h = L.header
        XCTAssertEqual(h.name, "River of Fears")
        XCTAssertEqual([Int(h.submergedFaces), Int(h.parallaxRipple), Int(h.startFacingLeft)], [1, 1, 1],
                       "0x26c6 / 0x26ca / 0x26c8")
        XCTAssertEqual([h.cameraOffsetY, h.landingDamage, h.iceSlipperiness, h.waterCurrent, h.music],
                       [-30, 150, 80, -512, 6], "0x270c / 0x270e / 0x2710 / 0x2714 / 0x284a")
        XCTAssertEqual([h.stripPict, h.autoScrollEnable, h.sidePush, h.arenaBound, h.flameMode, h.chapter],
                       [0, 0, 0, 0, 0, 0])
        XCTAssertEqual(h.omniPxMode, 0)
        // The music cue and the facing: New Game at level 11 plays track 6; the player starts facing left (game
        // globals +0x16 from hdr 0x26c8, `.SetupPlayerSprite`'s `+0x17e`).
        let rig = TenElevenRig(r, start: 11)
        rig.newGame(level: 11)
        XCTAssertEqual(rig.plays, [6])
        let run = try XCTUnwrap(rig.flow.levelRun)
        XCTAssertEqual(run.music.currentTrack, 6)
        let session = try XCTUnwrap(run.session)
        XCTAssertEqual(session.globals.startFacing, 1)

        try traceLevel11(r, L)
    }

    /// The parameter trace of level 11 (the values no level 1–5 record of the type has; the script's list is in the
    /// commit body). One assert each.
    private func traceLevel11(_ r: FerazelResources, _ L: LevelFile) throws {
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 11)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        func rec(_ i: Int) -> Placement { L.placements[i] }
        func setup(_ i: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(rec(i), context: c) }

        // 1250 switch blocks p1 2, p2 162 (levels 1–5: p2 57 / 63): `.HandleBoxSprite`'s arm (M l. 61042ff;
        // `BoxSprite.switchBlock`) — p1 == 2 → solid while record[p2].p4 == 1; record 162 is a button 1322.
        for i in [158, 164, 165, 166, 168] {
            XCTAssertEqual([rec(i).type, rec(i).p1, rec(i).p2], [1250, 2, 162], "switch block \(i)")
        }
        XCTAssertEqual(rec(162).type, 1322)
        // 2940 gate p1 142 (levels 1–5: −1, 90): opens on record[142].p4 == 1 — a button 1322.
        XCTAssertEqual([rec(138).type, rec(138).p1, rec(142).type], [2940, 142, 1322])
        // 2900 passages 102 ↔ 103, 136 ↔ 137, p2 0 (the darkness arm `// later` not reached).
        for (a, b) in [(102, 103), (136, 137)] {
            XCTAssertEqual([rec(a).type, rec(a).p1, rec(a).p2, rec(b).type, rec(b).p1, rec(b).p2],
                           [2900, Int16(b), 0, 2900, Int16(a), 0], "passages \(a) ↔ \(b)")
        }
        // 1307 torches p3 1 (levels 1–5: 0): light colour 0x58 (`.SetupBonusSprite` M l. 52556–52561); p3 0 → 0x16.
        for i in [104, 106, 143, 144] { XCTAssertEqual(try setup(i).light?.colour, 0x58, "torch \(i)") }
        for i in [249, 250, 251, 354] { XCTAssertEqual(try setup(i).light?.colour, 0x16, "torch \(i)") }
        // 1485 ball 210, p1 12, p3 90 (levels 1–5: p3 0 → 0x1e written back): mode 12 → `.MakeRadial(r p2 120, speed
        // 0, angle p4 190, g p3 90, persp 1)` (M l. 62312–62427).
        let sp = try SetupFaces.spawnLevelSprites(context: c) { _ in .noFace }
        let ball = try XCTUnwrap(sp.active.sprites.first { $0.recordIndex == 210 }
                                 ?? sp.idle.entries.compactMap { $0?.saved }.first { $0.recordIndex == 210 })
        let radial = try XCTUnwrap(ball.radial)
        XCTAssertEqual([Int(ball.subtype), Int(radial.radius >> 8), Int(radial.speed), Int(radial.angle >> 8),
                        Int(radial.gravity), Int(radial.persp)], [12, 120, 0, 190, 90, 1])
        XCTAssertEqual(sp.records[210].p3, 90, "p3 ≠ 0 is kept, not defaulted")
        // 1705 p3 3 (levels 1–5: 0 / 1): tier 3 — cooldown 0xd, HP 0x3b6, mode 0x10012 (M l. 57008–57078).
        for i in [203, 262, 357] {
            let w = try setup(i).slot
            XCTAssertEqual([Int(w.classWord158), Int(w.hp), Int(w.mode)], [0xd, 0x3b6, 0x10012], "1705 \(i)")
        }
        // 1750 p3 5 (record 167): tier 5 in the 1750 column — cooldown 10, HP 0x5dc, mode 0x10014.
        let ax = try setup(167).slot
        XCTAssertEqual([Int(ax.classWord158), Int(ax.hp), Int(ax.mode)], [10, 0x5dc, 0x10014])
        // 2812 decoration p1 1 (levels 1–5: 0): `+0x17e` = 1 (M l. 59665–59668); p2 11 → mode 0x1000b; p3 1 → layer
        // 10000.
        let d93 = try setup(93).slot, d90 = try setup(90).slot
        XCTAssertEqual([d93.mirrored, d90.mirrored], [true, false])
        XCTAssertEqual([Int(d93.mode), Int(d93.layer)], [0x1000b, 10000])
        // The ropes (geometry (p1, p2) → (p3, p4)): `.SetupRopeSegArray` (M l. 71245–71455). Record 76 (3020, p1 10750
        // > p3 10512) is reversed: span −238 → nSeg (−238 + 10) / 20 = −11 (C division), no segment made, and its
        // sample stores fall outside the block (dropped — platforms-ropes-radial §3.6).
        for (i, seg) in [(75, 20), (76, 20), (366, 20), (371, 20), (100, 24)] {
            let p = rec(i)
            let id = s.world.active.insert(try setup(i).slot)
            RopeSprite.setupSegArray(s.world, id: id)
            let q = try XCTUnwrap(s.world.active.record(id: id))
            let span = Int32(p.p3) - Int32(p.p1)
            XCTAssertEqual([q.classWord150, q.rope.map { Int32($0.dy) }], [(span + Int32(seg) / 2) / Int32(seg),
                                                                           Int32(p.p4) - Int32(p.p2)], "rope \(i)")
            if i == 76 {
                XCTAssertEqual(q.classWord150, -11)
                XCTAssertEqual(q.rope?.segments.count, 0)
            }
            for case let k? in q.rope?.segments ?? [] { _ = s.world.active.remove(id: k) }
            _ = s.world.active.remove(id: id)
        }
        // The swarms 1869 records 60 / 61, p1 8 (level 10: 0): the member type is the record's p1 — 8, not 0x74c —
        // and p2 0 → 8 members, p3 0 → radius 0x4b (M l. 68167–68203).
        for i in [60, 61] {
            let e = try setup(i)
            XCTAssertEqual(Set(e.children.map(\.type)), [8], "swarm \(i)")
            XCTAssertEqual([e.slot.swarm?.total, Int16(e.children.count)], [8, 8], "swarm \(i)")
            XCTAssertEqual(e.slot.classWord154, 0x4b)
        }
        // The path bats 1851 (= 0x73b) p1 ±2: path mode 2 (`ProgrammedPath.setup`, M l. 39288–39381), bounds from p2,
        // speed p3; p4 (200 on record 201) is read by no Bat arm (M l. 68108–68316): the same Setup as p4 0.
        let bat = rec(201)
        XCTAssertEqual([bat.type, bat.p1, bat.p2, bat.p3, bat.p4], [1851, -2, 360, 700, 200])
        let b0 = Placement(index: bat.index, flag: bat.flag, byte1: bat.byte1, type: bat.type, p1: bat.p1, p2: bat.p2,
                           p3: bat.p3, p4: 0, y: bat.y, x: bat.x)
        XCTAssertEqual(try setup(201).slot, try SetupFaces.setup(b0, context: c).slot)
        XCTAssertEqual(try setup(201).slot.pathMode, 2)
        // The cannons 1092 (record 284) and 1096 (78, 79), p1 0: launch speed 9000 (M l. 62113–62118).
        for i in [284, 78, 79] { XCTAssertEqual(try setup(i).slot.launchSpeed, 9000, "cannon \(i)") }
        // Nimbo 2955 (record 135): p1 206 is the conversation the NPC arm opens (`testLevel11NimboConversationOnContact`).
        XCTAssertEqual([rec(135).type, rec(135).p1], [2955, 206])
    }

    func testLevel11NimboConversationOnContact() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 11)
        // Record 283 (2956, flag 99, Mcnv 220) is dormant: `.SetupLevelSprites` spawns flag-1 records only (M l.
        // 1940–2101) — no sprite stands for it on the level.
        XCTAssertEqual([Int(L.placements[283].flag), Int(L.placements[283].type), Int(L.placements[283].p1)], [99, 2956, 220])
        let rig = TenElevenRig(r, start: 11)
        rig.newGame(level: 11)
        let run = try XCTUnwrap(rig.flow.levelRun)
        let s = try XCTUnwrap(run.session)
        func stands(_ rec: Int16) -> Bool {
            s.world.active.sprites.contains { $0.recordIndex == rec }
                || s.world.idle.entries.contains { $0?.saved.recordIndex == rec }
        }
        XCTAssertTrue(stands(135))
        XCTAssertFalse(stands(283), "Mcnv 220's record is dormant")
        XCTAssertNil(run.conversation)
        // The player put on Nimbo (6906, 174): the NPC arm (`.HitPlayerSprite` M l. 49304ff, `HitPlayerSprite.npc`) →
        // `.Conversation(206, 135, the sprite)`.
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.active.update(id: pid) { p in
            p.x = 6906; p.y = 174 - 0x20; p.x256 = 6906 << 8; p.y256 = Int32(174 - 0x20) << 8; p.vx = 0; p.vy = 0
        }
        rig.drive { _ in run.conversation != nil }
        let conv = try XCTUnwrap(run.conversation)
        guard case .conversation(let id, let record, _) = conv.kind else { return XCTFail("a conversation") }
        XCTAssertEqual([Int(id), record], [206, 135])
        XCTAssertFalse(stands(283), "still dormant")
    }
}
