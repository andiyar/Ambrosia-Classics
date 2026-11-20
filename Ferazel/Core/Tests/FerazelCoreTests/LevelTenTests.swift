import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-L10L11 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-L10L11`): level 10 "Unemployed In
/// Greenland" enterable — every one of its 312 records sets up (54 types; LL §4 "Level 10"), its header switches as
/// read, its music cue, the picture cache's marks, `BuiltLevels.list` = [1…5, 10, 11], and the parent / child links
/// of the swarms (record 0x200 members, never idled) and the path bats across idling (Hazards "Idle children").
/// The parameter trace ("Every level task"): every built type placed here whose p1…p4 take a value no level 1–5
/// record of that type has is traced through its Setup / Handle arm in the dump and pinned by one assert inside
/// `testLevel10SetsUpEveryRecord`. Against the committed `Resources/Ferazel` (D26); a missing data file is a FAILURE,
/// never a skip. Proof-B rules: plain Swift, no `@MainActor` class, no Foundation string search.
final class LevelTenTests: XCTestCase {

    func testLevel10SetsUpEveryRecord() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 10)
        let census = try TenEleven.census(r, level: 10)
        XCTAssertEqual(census.records, 312)
        XCTAssertEqual(census.types, 54)
        XCTAssertEqual(census.refused, [], "every record sets up — no `notTranscribed`, per record")
        XCTAssertEqual(census.created, 312)
        XCTAssertEqual(census.refusedSpawns, 0, "no spawn dropped for want of a record (known deviation 6)")

        // The header switches new against levels 1–5 (LL §4 "Level 10" item 1), as read.
        let h = L.header
        XCTAssertEqual(h.name, "Unemployed In Greenland")
        XCTAssertEqual(h.waterSurfaceEffect, 1, "0x26c9")
        XCTAssertEqual([h.stripPict, h.stripFactor, h.stripBaseY], [265, 128, 222], "0x2716 / 0x2718 / 0x271a")
        XCTAssertEqual(h.music, 4, "0x284a")
        XCTAssertEqual(h.darknessEnable, 1, "0x2706, as on a built level")
        XCTAssertEqual(h.chapter, 2, "0x273c: chapter card 2 on entry")
        XCTAssertEqual([Int(h.submergedFaces), Int(h.parallaxRipple), Int(h.startFacingLeft)], [0, 0, 0])
        XCTAssertEqual([h.autoScrollEnable, h.sidePush, h.arenaBound, h.flameMode, Int16(h.omniPxMode)],
                       [0, 0, 0, 0, 0])
        // The music cue: New Game at level 10 (the hidden `FerazelLevel` switch) plays the level's own track 4.
        let rig = TenElevenRig(r, start: 10)
        rig.newGame(level: 10)
        XCTAssertEqual(rig.plays, [4])
        XCTAssertEqual(rig.flow.levelRun?.music.currentTrack, 4)

        try traceLevel10(r, L)
    }

    /// The parameter trace of level 10 (the values no level 1–5 record of the type has; the script's list is in the
    /// commit body). One assert each.
    private func traceLevel10(_ r: FerazelResources, _ L: LevelFile) throws {
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 10)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        func rec(_ i: Int) -> Placement { L.placements[i] }
        func setup(_ i: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(rec(i), context: c) }

        // 1062 teleporters 203 ↔ 204 (p1 203 / 204; levels 1–5 p1 0…149): the teleport moves the player to every in-use
        // idle entry whose record is the teleporter's live p1 (M l. 49418–49462) — each names the other, one entry each.
        XCTAssertEqual([rec(203).type, rec(203).p1, rec(204).type, rec(204).p1], [1062, 204, 1062, 203])
        for (a, b) in [(203, 204), (204, 203)] {
            XCTAssertEqual(s.world.idle.inUseEntries(record: Int16(b)).count, 1, "teleporter \(a) → record \(b)")
        }
        // 2900 passages, p1 the partner record (7 ↔ 8, 40 ↔ 46, 192 ↔ 193, 254 ↔ 255, 271 ↔ 272), p2 0: the scan of
        // M l. 49594–49683 finds the partner; the p2 ≠ 0 darkness arm (`// later`) is not reached.
        for (a, b) in [(7, 8), (40, 46), (192, 193), (254, 255), (271, 272)] {
            XCTAssertEqual([rec(a).type, rec(a).p1, rec(a).p2, rec(b).type, rec(b).p1, rec(b).p2],
                           [2900, Int16(b), 0, 2900, Int16(a), 0], "passages \(a) ↔ \(b)")
        }
        // Leg 2 (N1): the passage arm's partner scan itself (M l. 49594–49683) on 192 → 193: on the 0x16th transit
        // frame the player moves to the idle entry of record p1, his offset from the passage kept.
        do {
            XCTAssertEqual(s.world.idle.inUseEntries(record: 193).count, 1)
            let e = try XCTUnwrap(s.world.idle.entries[s.world.idle.inUseEntries(record: 193)[0]])
            let id = s.world.active.insert(try setup(192).slot)
            let pid = try XCTUnwrap(s.world.playerID)
            let p0 = try XCTUnwrap(s.world.active.record(id: pid)), o = try XCTUnwrap(s.world.active.record(id: id))
            s.world.player.doorTransit = 0x15
            HitPlayerSprite.passage(s.world, player: pid, passage: id, keys: InputActions())
            let p1 = try XCTUnwrap(s.world.active.record(id: pid))
            XCTAssertEqual([p1.x - e.saved.x, p1.y - e.saved.y], [p0.x - o.x, p0.y - o.y], "passage 192 → 193")
            XCTAssertEqual(s.world.player.doorTransit, -0x16)
            s.world.player.doorTransit = 0
            _ = s.world.active.remove(id: id)
            s.world.active.update(id: pid) { $0 = p0 }
        }
        // 2940 gates p1 201 / 270 (levels 1–5: −1, 90): `.HandleBoxSprite`'s gate opens on record[p1].p4 == 1 (M l.
        // 61000ff; `BoxSprite.gate`), and both name a button 1322, whose press writes its record's p4 = 1.
        for (g, b) in [(202, 201), (266, 270)] {
            XCTAssertEqual([rec(g).type, rec(g).p1, rec(b).type], [2940, Int16(b), 1322], "gate \(g)")
            // Leg 2 (N1): the gate arm itself — shut with the button's p4 0 (no move at its start), open with p4 1
            // (`+0x1c −= 0x200` while under 100 above its start).
            for (p4, dy) in [(Int16(0), Int32(0)), (1, -0x200)] {
                let b0 = s.world.records[b]
                s.world.records[b] = Placement(index: b0.index, flag: b0.flag, byte1: b0.byte1, type: b0.type, p1: b0.p1,
                                               p2: b0.p2, p3: b0.p3, p4: p4, y: b0.y, x: b0.x)
                let id = s.world.active.insert(try setup(g).slot)
                let y0 = try XCTUnwrap(s.world.active.record(id: id)).y256
                BoxSprite.gateArm(s.world, id: id)
                XCTAssertEqual(try XCTUnwrap(s.world.active.record(id: id)).y256 - y0, dy, "gate \(g), button p4 \(p4)")
                _ = s.world.active.remove(id: id)
                s.world.records[b] = b0
            }
        }
        // 1307 torches p3 1 (levels 1–5: 0): `.SetupBonusSprite` M l. 52556–52561 — the light colour 0x58, not 0x16.
        for i in [10, 11, 12, 13, 14, 15, 16, 54, 55, 194, 195, 206, 207, 208, 209, 246, 247, 248, 289] {
            XCTAssertEqual([rec(i).type, rec(i).p3], [1307, 1], "torch \(i)")
            XCTAssertEqual(try setup(i).light?.colour, 0x58, "torch \(i)")
        }
        // 1401 blinking platforms p1 52 (mode 0x34; levels 1–5 p1 1 / 10), p2 25, p3 125, p4 0…100: the first Handle's
        // `.DoSetupPlatformSprite` (the 0x34 arm, M l. 54890–54906) — `+0x14c` = p1, `+0x150` = p2, `+0x154` = p3, `+0xa6` = p4,
        // `+0x46` 0 inside the on-time (p4 < p2) else 0x14.
        for i in [57, 99, 100, 101, 102, 103, 104, 105] {
            let p = rec(i)
            XCTAssertEqual([p.type, p.p1, p.p2, p.p3], [1401, 52, 25, 125], "platform \(i)")
            let id = s.world.active.insert(try setup(i).slot)
            PlatformSprite.doSetup(s.world, id: id)
            let q = try XCTUnwrap(s.world.active.record(id: id))
            XCTAssertEqual([Int(q.subtype), Int(q.classTimer), Int(q.classWord150), Int(q.classWord154),
                            Int(q.counterA6), Int(q.phase)],
                           [0x34, 52, 25, 125, Int(p.p4), p.p4 < 25 ? 0 : 0x14], "platform \(i)")
            _ = s.world.active.remove(id: id)
        }
        // 1410 catapult p1 1 (levels 1–5: 2): only p1 == 2 makes it walk-through in `.HitPlayerSprite`'s Platform arm
        // (M l. 49124–49147) — this one is solid.
        XCTAssertEqual([rec(278).type, rec(278).p1], [1410, 1])
        // Leg 2 (N1): the arm itself — the player standing into the catapult's top is bounced off it (p1 1: solid);
        // the same contact with the record's p1 2 leaves him where he was (walk-through).
        do {
            let pid = try XCTUnwrap(s.world.playerID)
            let p0 = try XCTUnwrap(s.world.active.record(id: pid))
            let saved = s.world.records[278]
            var moved: [Bool] = []
            for p1 in [Int16(1), 2] {
                s.world.records[278] = Placement(index: saved.index, flag: saved.flag, byte1: saved.byte1, type: saved.type,
                                                 p1: p1, p2: saved.p2, p3: saved.p3, p4: saved.p4, y: saved.y, x: saved.x)
                let id = s.world.active.insert(try setup(278).slot)
                PlatformSprite.doSetup(s.world, id: id)
                let c = try XCTUnwrap(s.world.active.record(id: id))
                s.world.active.update(id: pid) { p in
                    p = p0
                    p.x = c.x + c.hotRect.left; p.y = c.y + c.hotRect.top - p0.hotRect.bottom + 4
                    p.x256 = Int32(p.x) << 8; p.y256 = Int32(p.y) << 8; p.vx = 0; p.vy = 0x200
                }
                let before = try XCTUnwrap(s.world.active.record(id: pid))
                HitPlayerSprite.hit(s.world, player: pid, other: id)
                let after = try XCTUnwrap(s.world.active.record(id: pid))
                moved.append([after.y256, after.vy] != [before.y256, before.vy])
                _ = s.world.active.remove(id: id)
            }
            XCTAssertEqual(moved, [true, false], "1410 p1 1 solid, p1 2 walk-through")
            s.world.records[278] = saved
            s.world.active.update(id: pid) { $0 = p0 }
        }
        // 1485 balls p1 12 / 14, p2 100 / 150, p3 90 / 100 / 1400, p4 0 / 210 (levels 1–5: p1 12, p2 120, p3 0, p4 190 /
        // 350): `.SetupBackgroundSprite` M l. 62312–62427 — mode p1; 12 → `.MakeRadial(r p2, speed 0, angle p4, g p3,
        // persp 1)`, 14 → `(r p2, speed p3, angle p4, g 0, persp 2)` with the spokes 0x59c; p2 / 16 spokes.
        let sp = try SetupFaces.spawnLevelSprites(context: c) { _ in .noFace }
        func spawned(_ i: Int) throws -> SpriteSlot {
            try XCTUnwrap(sp.active.sprites.first { $0.recordIndex == Int16(i) } ?? sp.idle.entries.compactMap { $0?.saved }
                .first { $0.recordIndex == Int16(i) }, "record \(i)")
        }
        for (i, mode, radius, speed, angle, g, persp) in [(32, 12, 150, 0, 190, 90, 1), (33, 12, 150, 0, 210, 100, 1),
                                                         (50, 14, 100, 1400, 0, 0, 2)] {
            let b = try spawned(i)
            let radial = try XCTUnwrap(b.radial, "ball \(i)")
            XCTAssertEqual([Int(b.subtype), Int(radial.radius >> 8), Int(radial.speed), Int(radial.angle >> 8),
                            Int(radial.gravity), Int(radial.persp)], [mode, radius, speed, angle, g, persp], "ball \(i)")
            let spokes = sp.active.sprites.filter { $0.siblings.first != nil && $0.type == (mode == 14 ? 0x59c : 0x59a) }
            XCTAssertFalse(spokes.isEmpty, "ball \(i)'s spokes")
        }
        // 1700 p3 3, 1705 p3 5 (levels 1–5: 0 / 1): the Walker tier (`.SetupWalkerSprite` M l. 57008–57078) —
        // cooldown 0xd / 10, HP 0x3b6 / 0x352, mode 0x10012 / 0x10014. 1705 p3 ≥ 3 also reaches the spear guard
        // Handle's friction 0.7 arm (`.HandleWalkerSprite` M l. 57818: p3 < 3 → 0.9, else 0.7; pinned on level 11).
        let w236 = try setup(236).slot, w44 = try setup(44).slot
        XCTAssertEqual([Int(w236.classWord158), Int(w236.hp), Int(w236.mode)], [0xd, 0x3b6, 0x10012])
        XCTAssertEqual([Int(w44.classWord158), Int(w44.hp), Int(w44.mode)], [10, 0x352, 0x10014])
        // 2000 scroll p1 5 (levels 1–5: 1): `.HitPlayerSprite` M l. 48939–48976 — the spell is the record's p1 for 2000.
        XCTAssertEqual([rec(263).type, rec(263).p1], [2000, 5])
        let scroll = s.world.active.insert(try setup(263).slot)
        let pid = try XCTUnwrap(s.world.playerID)
        HitPlayerSprite.hit(s.world, player: pid, other: scroll)
        XCTAssertTrue(s.world.globals.inventory.contains { $0.id == 5 && $0.isSpell != 0 }, "the scroll teaches spell 5")
        // 2848 decorations p1 1 (levels 1–5: 0): `+0x17e` = 1 (`.SetupBoxSprite` M l. 59665–59668; its rect is empty,
        // so the flip leaves it empty — D53.2); p3 1 → layer 10000 (M l. 59676–59678), else −1 (M l. 59644).
        XCTAssertTrue(try setup(18).slot.mirrored)
        XCTAssertFalse(try setup(17).slot.mirrored)
        XCTAssertEqual([try setup(17).slot.layer, try setup(19).slot.layer], [-1, 10000])
        // 3022 / 3020 ropes: the geometry (p1, p2) → (p3, p4) — `.SetupRopeSegArray` M l. 71245–71455 — nSeg = (span +
        // seg/2) / seg, dy = p4 − p2 (negative: the rect's top).
        for (i, seg) in [(219, 24), (220, 24), (235, 24), (237, 24), (238, 24), (265, 24), (98, 20), (106, 20), (107, 20)] {
            let p = rec(i)
            let id = s.world.active.insert(try setup(i).slot)
            RopeSprite.setupSegArray(s.world, id: id)
            let q = try XCTUnwrap(s.world.active.record(id: id))
            let span = Int32(p.p3) - Int32(p.p1)
            XCTAssertEqual([q.classWord150, q.rope.map { Int32($0.dy) }], [(span + Int32(seg) / 2) / Int32(seg),
                                                                           Int32(p.p4) - Int32(p.p2)], "rope \(i)")
            for case let k? in q.rope?.segments ?? [] { _ = s.world.active.remove(id: k) }
            _ = s.world.active.remove(id: id)
        }
        // 1090 cannons 251–253: p1 0, p4 1 (levels 1–5: p4 0) — the p1 ≤ 0 arm (M l. 62067–62118) reads p4 only for
        // |p1| 1 / 2; the Handle reads p1 / p2 only: the same Setup as p4 0.
        for i in [251, 252, 253] {
            let p = rec(i)
            XCTAssertEqual([p.type, p.p1, p.p4], [1090, 0, 1])
            let zero = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: 0, p2: 0, p3: 0, p4: 0,
                                 y: p.y, x: p.x)
            XCTAssertEqual(try setup(i).slot, try SetupFaces.setup(zero, context: c).slot, "cannon \(i)")
        }
        // The rotating cannons 89 (1090 p1 101), 200 / 250 (1090 p1 103) and 108 (1097 p1 101, p2 10, p3 1): the p1 ≥ 1
        // arm (M l. 62120–62170) — the pause p2, the step and `+0x158` by p3, `+0x164` by p4 (250: p4 1 → 0x1c20).
        for (i, pause, step, period, speed) in [(89, 15, 1, 16, 9000), (200, 8, 2, 4, 9000), (250, 15, 2, 8, 0x1c20),
                                                (108, 10, 1, 8, 9000)] {
            let q = try setup(i).slot
            XCTAssertEqual([Int(q.counterA6), Int(q.classWord15c), Int(q.classWord158), Int(q.launchSpeed)],
                           [pause, step, period, speed], "rotating cannon \(i)")
        }
        // The new types with p1 0: the cannons 1091, 1093…1096 (launch speed 9000), the Bonus 1330 / 3217, the
        // geysers 1440 — set up above with the rest. The swarm 1869 (p1 0 → members 0x74c, p2 the count 6 / 8 / 12, p3
        // 0 → radius 0x4b; M l. 68167–68203).
        for (i, n) in [(170, 8), (268, 6), (276, 12)] {
            let e = try setup(i)
            XCTAssertEqual([e.slot.swarm?.total, Int16(e.children.count)], [Int16(n), Int16(n)], "swarm \(i)")
            XCTAssertEqual(Set(e.children.map(\.type)), [0x74c], "swarm \(i)")
            XCTAssertEqual(e.slot.classWord154, 0x4b)
        }
        // The platforms 1407 p1 3: the raft arm (M l. 54641–54648).
        for i in [256, 258] {
            let id = s.world.active.insert(try setup(i).slot)
            PlatformSprite.doSetup(s.world, id: id)
            let q = try XCTUnwrap(s.world.active.record(id: id))
            XCTAssertEqual([Int(q.subtype), Int(q.buoyancy), Int(q.gravity)], [3, 0x50, 0x15e], "raft \(i)")
            // Leg 2: the rest of the raft arm (M l. 54641–54648): sag 0x2d, push mass 0x3c, the rect (5, 6, 0x1e, 0x4c).
            XCTAssertEqual([Int(q.sag), Int(q.pushMass), q.hotRect.top, q.hotRect.left, q.hotRect.bottom, q.hotRect.right],
                           [0x2d, 0x3c, 5, 6, 0x1e, 0x4c], "raft \(i)")
            _ = s.world.active.remove(id: id)
        }
        // Leg 2: the geysers 121 / 307 (1440, p1…p4 all 0 — first placed here): the defaults of the geyser arm of
        // `.SetupBoxSprite` — target 0x6400 (p1 0), on / off 0x3c (p2 / p3 0), `+0xa6` = p4, the top margin target >> 8,
        // a single base (kind 0, type 0x5a0).
        for i in [121, 307] {
            XCTAssertEqual([rec(i).type, rec(i).p1, rec(i).p2, rec(i).p3, rec(i).p4], [1440, 0, 0, 0, 0], "geyser \(i)")
            let g = try setup(i).slot
            XCTAssertEqual([Int(g.geyserTarget), Int(g.geyserOn), Int(g.geyserOff), Int(g.counterA6), g.margins.top,
                            Int(g.geyserKind), Int(g.geyserTriple), Int(g.type)],
                           [0x6400, 0x3c, 0x3c, 0, 0x64, 0, 0, 0x5a0], "geyser \(i)")
        }
        // Leg 2 (N3): the cannons 1091 (88), 1094 (90), 1095 (144), 1093 (145), 1096 (153, 154), p1 0: launch speed
        // 9000 (M l. 62113–62118).
        for i in [88, 90, 144, 145, 153, 154] {
            XCTAssertEqual(rec(i).p1, 0, "cannon \(i)")
            XCTAssertEqual(try setup(i).slot.launchSpeed, 9000, "cannon \(i)")
        }
        // Leg 2: the sphere 1330 (227) — the sphere arm of `.SetupBonusSprite` (M l. 52710–52720): its own face 1330
        // for the Handle, rect (0, 0, 0x20, 0x1b); the item 3217 (310), p1 0 — gravity kept (only p1 ≠ 0 zeroes it,
        // M l. 52703–52706).
        let sphere = try setup(227).slot
        XCTAssertEqual(sphere.face, FaceRef(pict: 1330, index: 0, set: .encoded), "the face the Handle draws, cell 0")
        XCTAssertEqual([sphere.hotRect.top, sphere.hotRect.left, sphere.hotRect.bottom, sphere.hotRect.right],
                       [0, 0, 0x1b, 0x20])
        XCTAssertEqual([rec(310).type, rec(310).p1], [3217, 0])
        XCTAssertNotEqual(try setup(310).slot.gravity, 0, "item 3217 p1 0: gravity kept")
        // Leg 2 (N1): the teleporter's live p1 chooses the entry `.TeleportPlayer` moves the player to (M l. 49416ff.):
        // 203 → the idle entry of record 204, the player's offset from the teleporter kept.
        do {
            let tel = s.world.active.insert(try setup(203).slot)
            let pid = try XCTUnwrap(s.world.playerID)
            let p0 = try XCTUnwrap(s.world.active.record(id: pid)), o = try XCTUnwrap(s.world.active.record(id: tel))
            s.world.player.teleportTail = tel
            let matched = HitPlayerSprite.teleportMove(s.world, player: pid) {}
            XCTAssertEqual(matched.map { s.world.idle.entries[$0]?.saved.recordIndex }, [204])
            let e = try XCTUnwrap(s.world.idle.entries[try XCTUnwrap(matched.first)])
            let p1 = try XCTUnwrap(s.world.active.record(id: pid))
            XCTAssertEqual([p1.x - e.saved.x, p1.y - e.saved.y], [p0.x - o.x, p0.y - o.y], "the offset kept")
            s.world.player.teleportTail = nil
            _ = s.world.active.remove(id: tel)
        }
        // The Walkers 1750 (p1 0 / 1, p3 0 / 1): p1 is read by no Setup or Handle arm of the 1750 (`.SetupWalkerSprite`
        // M l. 56898–57100; `.AxGoblinCoreLogic` M l. 57101–57344 reads no record word; `.HandleWalkerSprite` reads a
        // record's p1 only in the 1700 arm, M l. 57663, and the 1760 arm, M l. 58052); p3 1 → the tier's HP 500 (the
        // 1750 column).
        for i in [30, 31, 41, 42, 43, 159, 160, 161] where rec(i).p3 == 1 {
            XCTAssertEqual(try setup(i).slot.hp, 500, "1750 \(i)")
        }
    }

    func testLevels10And11CacheMarks() throws {
        let r = try TenEleven.resources()
        // LL §4 item 6 (the new types' marks, 1-based list positions) — every one is marked; the level's whole mark set
        // (old types too) is what the opened session needs; the bar on a fresh cache, measured.
        let expected: [Int: [CachedFaces.RecordKey]] = [
            10: [.set(14), .set(15), .set(16), .set(17), .set(23), .set(24), .set(25), .set(28), .set(45), .single(1),
                 .single(20), .single(21), .single(41), .single(50), .single(51), .single(91), .single(136),
                 .single(137), .single(138), .single(139)],
            11: [.set(14), .set(15), .set(16), .set(17), .set(27), .set(28), .set(45), .set(46), .set(47), .single(1),
                 .single(20), .single(21), .single(35), .single(41), .single(59), .single(87), .single(102),
                 .single(103), .single(105), .single(106), .single(127), .single(128), .single(136), .single(137),
                 .single(138), .single(139)],
        ]
        for level in [10, 11] {
            let L = try LevelFile.load(from: r, level: Int16(level))
            let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
            let setUp = SetupFaces.spawnOrder(L.placements).filter { (try? SetupFaces.setup($0, context: c)) != nil }
            XCTAssertEqual(setUp.count, L.activePlacements.count, "level \(level)")
            let marks = Set(setUp.flatMap { CachedFaces.markedRecords(type: $0.type, p1: $0.p1) })
            for k in try XCTUnwrap(expected[level]) { XCTAssertTrue(marks.contains(k), "level \(level): \(k)") }
            let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: level)
            let needed = CachedFaces.needed(by: s)
            XCTAssertEqual(Set(needed.records), marks, "level \(level): the opened session needs the Setups' marks")
            var cache = CachedFaces()
            cache.enterLevel(screenClut: L.header.screenClut)
            let bars = cache.load(needed: needed)
            let q = Int(bars.first?.1 ?? 0)
            // Measured (needed records, n, q, steps): one step per record.
            XCTAssertEqual([marks.count, q / 2, q, bars.count], level == 10 ? [38, 145, 290, 38] : [50, 191, 382, 50])
        }
    }

    func testBuiltLevelsTenEleven() throws {
        XCTAssertEqual(BuiltLevels.list, [1, 2, 3, 4, 5, 10, 11])
        for n in [10, 11] { XCTAssertTrue(BuiltLevels.contains(n)) }
        for n in [6, 9, 12, 15] { XCTAssertFalse(BuiltLevels.contains(n)) }
        let r = try TenEleven.resources()
        // `startLevel` 10 / 11 (the hidden `FerazelLevel` switch) is accepted: New Game there, nothing asked.
        for n in [10, 11] {
            let rig = TenElevenRig(r, start: n)
            rig.newGame(level: n)
            XCTAssertEqual(rig.flow.levelNumber, n)
            XCTAssertEqual(rig.levels.prepared, [n])
            XCTAssertEqual(rig.asked, [])
        }
        // Level 5's exit p1 1 (record 26) → node 10 → Return → level 10 entered (before 6A-L10L11: the not-built report).
        let five = TenElevenRig(r, start: 5)
        five.newGame(level: 5)
        try five.exit(26, toNode: 10)
        five.drive { f in f.levelRun?.levelNumber == 10 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(five.asked, [])
        XCTAssertEqual(five.levels.prepared, [5, 10])
        // A save made on level 10 (a save point's block, the level's own records) continues there through
        // `.ContinueGame`: level 10 runs, nothing asked.
        let L = try LevelFile.load(from: r, level: 10)
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 10, x: L.header.startX, y: L.header.startY,
                           stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g, records: L.placements)
        let cont = TenElevenRig(r, start: 1)
        cont.files.block = save
        cont.drive { $0.state == .mainMenu }
        cont.drive({ _ in [0x0f] }) { _ in true }                          // R: Continue
        cont.drive { _ in cont.askedFile }
        cont.flow.fileDone(.chosen(SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/ten"), displayName: "ten")))
        cont.drive { f in f.levelRun?.levelNumber == 10 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(cont.asked, [])
        XCTAssertEqual(cont.flow.levelNumber, 10)
        XCTAssertEqual(cont.levels.prepared, [10])
    }

    func testLevels10And11IdleChildLinks() throws {
        let r = try TenEleven.resources()
        // Level 10's swarms 1869 (records 170, 268, 276; p2 8 / 6 / 12 members of type 0x74c). The level start idles the
        // three parents (all far from the player); their members — `MTNewSprite` children with record 0x200 (M l.
        // 68196–68199) — are never idled and keep running around the centre the Setup gave them (`+0x14c` / `+0x150`).
        // The dump links them through the parent's member block `+0x9c` and those two centre words only: no store to a
        // member's `+0x1d4` (M l. 68160–68213).
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 10, seed: 1)
        let L10 = try LevelFile.load(from: r, level: 10)
        func swarm(_ rec: Int16) throws -> (parent: SpriteSlot, members: [SpriteSlot]) {
            XCTAssertNil(s.world.active.sprites.first { $0.recordIndex == rec }, "swarm \(rec): its parent is not active")
            let e = try XCTUnwrap(s.world.idle.entries.compactMap { $0 }.first { $0.saved.recordIndex == rec })
            XCTAssertNil(e.activeID, "swarm \(rec): idle")
            let ids = try XCTUnwrap(e.saved.swarm).members
            return (e.saved, try ids.map { try XCTUnwrap($0.flatMap { s.world.active.record(id: $0) }, "swarm \(rec)") })
        }
        var before: [[Int]] = []
        var stepped = 0
        for frame in [0, 30, 60] {
            while stepped < frame { _ = s.step(keys: KeyState()); stepped += 1 }
            var positions: [[Int]] = []
            for (rec, n) in [(Int16(170), 8), (268, 6), (276, 12)] {
                let (parent, members) = try swarm(rec)
                XCTAssertEqual([members.count, Int(parent.swarm?.alive ?? 0), Int(parent.swarm?.total ?? 0)], [n, n, n])
                for m in members {
                    XCTAssertEqual([Int(m.recordIndex), Int(m.type)], [0x200, 0x74c], "swarm \(rec)")
                    XCTAssertEqual(m.handler, .swarmMember)
                    XCTAssertEqual([Int(m.classTimer), Int(m.classWord150)], [parent.x, parent.y], "the centre words")
                    XCTAssertNil(m.siblings.first, "no `+0x1d4` link")
                    positions.append([m.x, m.y])
                }
            }
            if frame == 60 {
                // Measured (seed 1): the 26 members' pixel positions after 60 frames, in member order.
                XCTAssertEqual(String(TenEleven.fnv(positions.flatMap { $0 }), radix: 16), "f61c08a2d6d9bfa2")
                XCTAssertEqual(Array(positions.prefix(2)), [[9431, 1619], [9417, 1587]])
            }
            if !before.isEmpty { XCTAssertNotEqual(positions, before, "frame \(frame): the members still move") }
            before = positions
        }
        // Leg 2 (S4): the parent ACTIVE, then idled by the player leaving its margins. Swarm 170 brought in (the player
        // put on its centre): while it runs, its Handle re-writes every member's `+0x14c` / `+0x150` to its own x, y each
        // frame; one member killed → alive 7 of 8, its slot dropped; the player gone again → the parent idles with that
        // block, the members (record 0x200) are never idle entries, never counted (`countIfWindow` is the centre's
        // only), and keep moving while it is idle.
        do {
            let (parent0, members0) = try swarm(170)
            let ids = try XCTUnwrap(parent0.swarm?.members)
            XCTAssertTrue(members0.allSatisfy { !$0.countedInTotals }, "members never counted")
            XCTAssertTrue(parent0.countedInTotals, "the centre is counted (`countIfWindow`, M l. 68210–68213)")
            let live0 = s.world.enemies.live
            let pid = try XCTUnwrap(s.world.playerID)
            func put(_ x: Int, _ y: Int) {
                s.world.active.update(id: pid) { p in
                    p.x = x; p.y = y; p.x256 = Int32(x) << 8; p.y256 = Int32(y) << 8; p.vx = 0; p.vy = 0
                }
            }
            func active170() -> SpriteSlot? { s.world.active.sprites.first { $0.recordIndex == 170 } }
            func noMemberIdle() -> Bool { !s.world.idle.entries.contains { $0?.saved.recordIndex == 0x200 } }
            put(parent0.x, parent0.y)
            var k = 0
            while active170() == nil && k < 200 { _ = s.step(keys: KeyState()); k += 1 }
            XCTAssertEqual(k, 1, "measured: brought in on the first frame")
            var centres: Set<[Int]> = []
            for _ in 0..<10 {
                // The Handle writes the centre before its own move (step 6, `+0x14 += vx`): the members carry the
                // parent's position as the frame found it.
                let q = try XCTUnwrap(active170())
                _ = s.step(keys: KeyState())
                let p = try XCTUnwrap(active170())
                XCTAssertEqual(p.swarm?.members, ids)
                for id in ids {
                    let m = try XCTUnwrap(id.flatMap { s.world.active.record(id: $0) })
                    XCTAssertEqual([Int(m.classTimer), Int(m.classWord150)], [Int(Int16(truncatingIfNeeded: q.x)),
                                                                               Int(Int16(truncatingIfNeeded: q.y))],
                                   "the active parent's Handle re-centres its members")
                    centres.insert([Int(m.classTimer), Int(m.classWord150)])
                }
                XCTAssertTrue(noMemberIdle())
            }
            XCTAssertGreaterThan(centres.count, 1, "the parent moved, its members' centre with it")
            XCTAssertEqual(s.world.enemies.live, live0, "no member counted on the way in")
            let victim = try XCTUnwrap(ids[0])
            s.world.active.update(id: victim) { $0.dead = true }
            for _ in 0..<2 { _ = s.step(keys: KeyState()) }
            let p = try XCTUnwrap(active170())
            XCTAssertEqual([Int(p.swarm?.alive ?? -1), Int(p.swarm?.total ?? -1)], [7, 8])
            XCTAssertNil(p.swarm?.members.first ?? nil, "the dead member's slot dropped")
            put(Int(L10.header.startX), Int(L10.header.startY))
            k = 0
            while active170() != nil && k < 200 { _ = s.step(keys: KeyState()); k += 1 }
            XCTAssertLessThan(k, 200, "idled again")
            func idleMembers() throws -> (SpriteSlot, [SpriteSlot]) {
                let e = try XCTUnwrap(s.world.idle.entries.compactMap { $0 }.first { $0.saved.recordIndex == 170 })
                XCTAssertNil(e.activeID)
                return (e.saved, (e.saved.swarm?.members ?? []).compactMap { $0.flatMap { s.world.active.record(id: $0) } })
            }
            let (parent1, members1) = try idleMembers()
            XCTAssertEqual([Int(parent1.swarm?.alive ?? -1), members1.count], [7, 7])
            XCTAssertEqual(parent1.swarm?.members.dropFirst().map { $0 }, ids.dropFirst().map { $0 })
            let at = members1.map { [$0.x, $0.y] }
            for _ in 0..<5 { _ = s.step(keys: KeyState()) }
            XCTAssertNotEqual(try idleMembers().1.map { [$0.x, $0.y] }, at, "members run on while the parent idles")
            XCTAssertTrue(noMemberIdle())
        }
        // Leg 2 (S4): level 11's swarms 60 / 61 (p1 8: member type 8) are linked the same way — eight members each,
        // record 0x200, the member Handle, the centre words the parent's x, y, no `+0x1d4` link.
        do {
            let s11 = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 11, seed: 1)
            for rec in [Int16(60), 61] {
                let parent = try XCTUnwrap(s11.world.active.sprites.first { $0.recordIndex == rec }
                    ?? s11.world.idle.entries.compactMap { $0?.saved }.first { $0.recordIndex == rec }, "swarm \(rec)")
                let ids = try XCTUnwrap(parent.swarm?.members)
                XCTAssertEqual(ids.count, 8)
                for id in ids {
                    let m = try XCTUnwrap(id.flatMap { s11.world.active.record(id: $0) }, "swarm \(rec)")
                    XCTAssertEqual([Int(m.recordIndex), Int(m.type), Int(m.classTimer), Int(m.classWord150)],
                                   [0x200, 8, parent.x, parent.y], "swarm \(rec)")
                    XCTAssertEqual(m.handler, .swarmMember)
                    XCTAssertNil(m.siblings.first)
                    XCTAssertFalse(m.countedInTotals)
                }
            }
        }

        // Level 11's path bat 201 (1851 = 0x73b, p1 −2: path mode 2, p2 360, p3 700, p4 200 — p4 read by no Bat arm):
        // brought in by the player, idled when he leaves, brought back — `.IdleToActiveSprite` (M l. 4215–4275) re-runs
        // no Setup: the 0x220-byte snapshot comes back (path bounds, direction, speed, HP), `+0xe9` cleared.
        let e = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 11, seed: 1)
        func put(_ x: Int, _ y: Int) throws {
            let pid = try XCTUnwrap(e.world.playerID)
            e.world.active.update(id: pid) { p in
                p.x = x; p.y = y; p.x256 = Int32(x) << 8; p.y256 = Int32(y) << 8; p.vx = 0; p.vy = 0
            }
        }
        func bat() -> SpriteSlot? { e.world.active.sprites.first { $0.recordIndex == 201 } }
        _ = e.step(keys: KeyState())
        try put(7900, 640)
        var k = 0
        while bat() == nil && k < 200 { _ = e.step(keys: KeyState()); k += 1 }
        let woke = try XCTUnwrap(bat(), "bat 201 brought in")
        // `ProgrammedPath.setup` mode 2 (M l. 39288–39381): low x256 + 8·p3, high x256 + 256·p2 − 8·p3, vx = p3.
        let x256 = Int32(7997) << 8
        XCTAssertEqual([woke.pathMode, woke.pathLow, woke.pathHigh, Int32(woke.pathDirection), woke.pathSpeed],
                       [2, x256 + 8 * 700, x256 + 256 * 360 - 8 * 700, 1, 700])
        XCTAssertEqual([k, woke.x, Int(woke.hp)], [1, 8002, 100], "measured: in on the first frame")
        for _ in 0..<20 { _ = e.step(keys: KeyState()) }
        try put(1200, 640)
        k = 0
        while bat() != nil && k < 200 { _ = e.step(keys: KeyState()); k += 1 }
        let entry = try XCTUnwrap(e.world.idle.entries.compactMap { $0 }.first { $0.saved.recordIndex == 201 })
        let idled = entry.saved
        XCTAssertNil(entry.activeID)
        XCTAssertEqual([k, idled.x, Int(idled.x256)], [2, 8117, 2078032], "measured: idled on the second frame")
        for _ in 0..<30 { _ = e.step(keys: KeyState()) }
        try put(7900, 640)
        k = 0
        var back: SpriteSlot?
        while back == nil && k < 200 {
            _ = e.step(keys: KeyState()); k += 1
            back = bat()
        }
        let b = try XCTUnwrap(back)
        // The path state across the idling is the snapshot's; the bat flies on from where it idled.
        XCTAssertEqual([b.pathMode, b.pathLow, b.pathHigh, Int32(b.pathDirection), b.pathSpeed, Int32(b.hp)],
                       [idled.pathMode, idled.pathLow, idled.pathHigh, Int32(idled.pathDirection), idled.pathSpeed,
                        Int32(idled.hp)])
        XCTAssertFalse(b.dead)
        XCTAssertEqual([k, b.x, Int(b.x256)], [20, 8122, 2079352], "measured: back on the 20th frame, two Handles on")
    }
}

// MARK: - shared by LevelTenTests and LevelElevenTests

enum TenEleven {
    /// FNV-1a 64 over the values' low 32 bits, big-endian.
    static func fnv(_ values: [Int]) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for v in values { for sh in [24, 16, 8, 0] { h = (h ^ UInt64(UInt8(truncatingIfNeeded: v >> sh))) &* 0x100000001b3 } }
        return h
    }

    static func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The level's census: active records, their types, the records `SetupFaces.setup` refuses (by type), the records
    /// the level spawn creates, and `SpriteWorld.refusedSpawns` after 120 frames of a fresh session.
    static func census(_ r: FerazelResources, level: Int) throws
        -> (records: Int, types: Int, refused: [Int16], created: Int, refusedSpawns: Int) {
        let L = try LevelFile.load(from: r, level: Int16(level))
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        var refused: [Int16] = []
        for p in L.activePlacements {
            do { _ = try SetupFaces.setup(p, context: c) } catch { refused.append(p.type) }
        }
        let sp = try SetupFaces.spawnLevelSprites(context: c) { _ in .noFace }
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: level)
        for _ in 0..<120 { _ = s.step(keys: KeyState()) }
        return (L.activePlacements.count, Set(L.activePlacements.map(\.type)).count, refused, sp.created.count,
                s.world.refusedSpawns)
    }
}

/// A flow with the hidden `FerazelLevel` switch at `start`, collecting the dialogs and music cues it puts out (the
/// `LevelFiveTests` rig, shared by the level 10 / 11 tests).
final class TenElevenRig {
    final class Files: FrontFiles {
        var block: SaveBlock?
        func loadPrefs() -> Data? { nil }
        func storePrefs(_ record: Data) throws {}
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock {
            guard let block else { throw SavedGameError.notASavedGame }
            return block
        }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
    }

    final class Levels: LevelServices {
        var prepared: [Int] = []
        func prepare(level: Int) throws -> LevelFaces { prepared.append(level); return LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    let levels = Levels()
    let files = Files()
    let flow: GameFlow
    var t: UInt32 = 1000
    var asked: [FerazelDialog] = []
    /// Whether the last tick asked for a file (`.getFile`).
    var askedFile = false
    var music: [MusicCue] = []
    var plays: [Int] { music.compactMap { if case .play(let n) = $0 { n } else { nil } }.filter { $0 != 0 } }

    init(_ r: FerazelResources, start: Int) {
        flow = GameFlow(resources: r, prefs: FerazelPrefs(), seed: 1, files: files, levels: levels)
        flow.startLevel = start
    }

    func drive(_ keys: (GameFlow) -> [Int] = { _ in [] }, until: (GameFlow) -> Bool,
               file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<8000 {
            if case .loading = flow.state { flow.loadFinished() }
            let out = flow.tick(now: t, input: FrontInput(keys: KeyState(pressed: keys(flow))))
            asked += out.requests.compactMap { if case .dialog(let d) = $0 { return d }; return nil }
            askedFile = out.requests.contains { if case .getFile = $0 { return true }; return false }
            if flow.levelRun != nil { music += out.music }
            t &+= 1
            if until(flow) { return }
        }
        XCTFail("the flow did not reach the condition (state \(flow.state))", file: file, line: line)
    }

    func newGame(level n: Int) {
        drive { $0.state == .mainMenu }
        drive({ _ in [0x2d] }) { _ in true }
        drive { f in f.levelRun?.levelNumber == n && (f.levelRun?.iterations ?? 0) >= 45 }
    }

    /// The level's exit `record` touched → the map's auto-walk to the node of `level` → Return.
    func exit(_ record: Int, toNode level: Int) throws {
        try touchExit(try XCTUnwrap(flow.levelRun?.session), record: record)
        drive { f in (f.worldMap.map { $0.iterations >= 2 && $0.walkStep == 0 && $0.result == nil }) ?? false }
        let m = try XCTUnwrap(flow.worldMap)
        XCTAssertEqual(m.cur, try XCTUnwrap(m.map.findCurrNode(level: Int16(level))).index)
        let before = asked.count
        drive({ f in f.worldMap?.result == nil ? [0x24] : [] }) { f in f.worldMap == nil || self.asked.count > before }
    }
}
