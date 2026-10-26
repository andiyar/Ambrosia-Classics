import XCTest
@testable import FerazelCore

/// TP (docs/plans/2026-10-24-ferazel-phase4.md): the teleporters — `.HitPlayerSprite`'s Box arm for 0x424…0x426 (M l.
/// 49407–49470), row 36's charge and fire pulse (M l. 46242–46346), the two `.MosaicTransition`s (M l. 12944–13018) run
/// by `LevelRun` inside the frame; pickups-boxes §2.4.7 (BC40, BC50). Level 1: records 148 ↔ 149, 126 (p1 0) → record
/// 0, the type-2922 furniture at (5455, 666). Driven against the committed `Resources/Ferazel` (D26). A missing data
/// file is a FAILURE, never a skip.
final class TeleporterTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The player's start standing on the teleporter of record `p`: his hot rect (38, 34)–(62, 85) one pixel into the
    /// teleporter's (0, −4)–(0x20, 0x1a), centred over it.
    private func onTeleporter(_ p: Placement) -> (x: Int, y: Int) { (Int(p.x) + 0x10 - 50, Int(p.y) - 4 - 85 + 1) }

    private func session(_ r: FerazelResources, record: Int) throws -> FerazelSession {
        let L = try LevelFile.load(from: r, level: 1)
        return try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1, start: onTeleporter(L.placements[record]))
    }

    /// Steps until the frame suspends; the teleporter charge after each whole step before it.
    private func stepToSuspension(_ s: FerazelSession, max: Int = 300) -> (charges: [Int16], ops: FrameOps?) {
        var charges: [Int16] = []
        for _ in 0..<max {
            let ops = s.step(keys: KeyState())
            if ops.suspension != nil { return (charges, ops) }
            charges.append(s.player.teleporterCharge)
        }
        return (charges, nil)
    }

    private func playerSlot(_ s: FerazelSession) throws -> SpriteSlot {
        try XCTUnwrap(s.world.playerID.flatMap { s.world.active.record(id: $0) })
    }

    /// The teleporter sprite of `record` on the active list.
    private func teleporter(_ s: FerazelSession, record: Int16) throws -> SpriteSlot {
        try XCTUnwrap(s.world.active.sprites.first { $0.recordIndex == record && (0x424...0x426).contains($0.type) })
    }

    private func snds(_ ops: FrameOps) -> [Int16] { ops.sounds.map(\.snd) }

    /// Runs the two stages of a fired teleporter from the stage-1 suspension; checks the move to `partner`'s idle
    /// entry (x, y) + d, the sounds, the second stage and the tail. `beforeMove` runs at the stage-1 suspension.
    private func runTeleport(_ s: FerazelSession, first: FrameOps, record: Int, partner: (x: Int, y: Int),
                             beforeMove: () throws -> Void = {}, file: StaticString = #filePath,
                             line: UInt = #line) throws {
        XCTAssertEqual(first.suspension, .teleport(record: record, stage: 1), file: file, line: line)
        XCTAssertEqual(snds(first).last, 421, file: file, line: line)          // `_DAT_100a03dc`, before the mosaic
        XCTAssertFalse(snds(first).contains(420), file: file, line: line)
        let p0 = try playerSlot(s), t = try teleporter(s, record: Int16(record))
        let d = (x: p0.x - t.x, y: p0.y - t.y)
        XCTAssertTrue(s.player.teleporterTouch || s.player.teleporterFire, file: file, line: line)
        XCTAssertEqual(s.player.idle, 0, file: file, line: line)
        try beforeMove()
        // Stage 1 answered: the move, the camera re-seat, `.HandleIdleSprites`, `.WrapDrawSprites`, snd 420 — then the
        // in-mosaic.
        let second = s.resume(.teleport(keys: KeyState(), capsLock: false))
        XCTAssertEqual(second.suspension, .teleport(record: record, stage: 2), file: file, line: line)
        XCTAssertEqual(snds(second), [420], file: file, line: line)
        let p1 = try playerSlot(s)
        XCTAssertEqual([p1.x, p1.y], [partner.x + d.x, partner.y + d.y], file: file, line: line)
        XCTAssertEqual([p1.x256, p1.y256], [Int32(p1.x) << 8, Int32(p1.y) << 8], file: file, line: line)
        XCTAssertNil(p1.ridden, file: file, line: line)                         // `+0xdc = 0`
        XCTAssertEqual([s.player.pixelX, s.player.pixelY], [Int16(p1.x), Int16(p1.y)], file: file, line: line)
        XCTAssertEqual([s.player.focusX, s.player.focusY], [s.player.centreX, s.player.centreY], file: file, line: line)
        XCTAssertEqual([Int(s.player.centreX), Int(s.player.centreY)], [p1.centre.x, p1.centre.y], file: file, line: line)
        // The re-seat's `.RedrawEntireScrollGrid` at the scroll point the 120 passes left, then the sprites.
        let kinds = second.draws.map { op -> String in
            switch op {
            case .redrawEntireScrollGrid(let h, let v): return "entire \(h) \(v)"
            case .wrapDrawSprites: return "sprites"
            default: return "other"
            }
        }
        XCTAssertEqual(kinds, ["entire \(s.camera.scrollH) \(s.camera.scrollV)", "sprites"], file: file, line: line)
        XCTAssertEqual(s.player.teleporterCharge, 80, file: file, line: line)  // unchanged until the tail
        XCTAssertTrue(s.player.teleporterFire, file: file, line: line)
        // Stage 2 answered: `.RedrawEntireScrollGrid`, `0708 = 0`, the charge −59, the rest of the frame.
        let third = s.resume(.teleport(keys: KeyState(), capsLock: false))
        XCTAssertNil(third.suspension, file: file, line: line)
        XCTAssertEqual(third.draws.first, .redrawEntireScrollGrid(h: s.camera.scrollH, v: s.camera.scrollV),
                       file: file, line: line)
        XCTAssertTrue(third.draws.contains { if case .wrapEraseSprites = $0 { true } else { false } },
                      file: file, line: line)
        XCTAssertEqual(s.player.teleporterCharge, -59, file: file, line: line)
        XCTAssertFalse(s.player.teleporterFire, file: file, line: line)
        XCTAssertNil(s.player.teleportTail, file: file, line: line)
        // The next frame's row 36 climbs the negative charge by 1 (touching or not) — no second fire (on level 1 the
        // landing by record 0 may meet an NPC's conversation later in that frame).
        let next = s.step(keys: KeyState())
        if case .teleport? = next.suspension { XCTFail("a second teleport", file: file, line: line) }
        XCTAssertEqual(s.player.teleporterCharge, -58, file: file, line: line)
    }

    // MARK: -

    /// Record 148 (p1 149): standing on it charges 1 … 59 a frame, 60 → 79, 80 → the fire pulse; the landing with the
    /// pulse set plays snd 421 and stops the frame (stage 1); after it the player is at 149's idle entry (x, y) + d,
    /// snd 420, stage 2; after it charge −59, `0708` 0. The same when 149's sprite is active (the search tests only
    /// the in-use byte, BC50).
    func testTeleportPair() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 1)
        let partner = L.placements[149]
        XCTAssertEqual([L.placements[148].type, L.placements[148].p1, partner.type, partner.p1], [1062, 149, 1062, 148])
        for activePartner in [false, true] {
            let s = try session(r, record: 148)
            let (charges, first) = stepToSuspension(s)
            let ops = try XCTUnwrap(first, "active partner \(activePartner)")
            // The touch of frame k is charged by row 36 of frame k + 1: 1 … 59, then 60 → 79, then 80 fires.
            let tail = Array(charges.suffix(3))
            XCTAssertEqual(tail, [58, 59, 79], "active partner \(activePartner)")
            XCTAssertEqual(Array(charges.drop { $0 == 0 }), Array(1...59) + [79])
            XCTAssertEqual(s.player.teleporterCharge, 80)
            XCTAssertTrue(s.player.teleporterFire)
            let entry = try XCTUnwrap(s.world.idle.entries.firstIndex { $0?.saved.recordIndex == 149 })
            try runTeleport(s, first: ops, record: 148, partner: (Int(partner.x), Int(partner.y)), beforeMove: {
                guard activePartner else {
                    XCTAssertNil(s.world.idle.entries[entry]?.activeID)
                    return
                }
                // 149 brought in: a `.HandleIdleSprites` window over it and the player (the union keeps 148 in).
                let p = try playerSlot(s)
                let rect = IdleSprites.Rect(top: p.y + p.hotRect.top, left: p.x + p.hotRect.left,
                                            bottom: p.y + p.hotRect.bottom, right: p.x + p.hotRect.right)
                s.world.idle.handle(h: Int(partner.x) - 0x140, v: Int(partner.y) - 0xc0, playerHotRect: rect,
                                    active: &s.world.active, faceRect: { _ in .noFace })
                XCTAssertNotNil(s.world.idle.entries[entry]?.activeID)
                XCTAssertEqual(s.world.idle.inUseEntries(record: 149), [entry])
            })
        }
    }

    /// Record 126 (p1 0) sends the player to record 0's idle entry — the type-2922 furniture at (5455, 666) — plus d
    /// (BC50: the search does not care what the entry is).
    func testTeleporterToRecordZero() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 1)
        XCTAssertEqual([L.placements[126].type, L.placements[126].p1], [1062, 0])
        XCTAssertEqual([L.placements[0].type, L.placements[0].x, L.placements[0].y], [2922, 5455, 666])
        let s = try session(r, record: 126)
        XCTAssertEqual(s.world.idle.inUseEntries(record: 0).count, 1)
        let e = try XCTUnwrap(s.world.idle.entries[s.world.idle.inUseEntries(record: 0)[0]])
        XCTAssertEqual([Int(e.saved.type), e.saved.x, e.saved.y], [2922, 5455, 666])
        let first = try XCTUnwrap(stepToSuspension(s).ops)
        try runTeleport(s, first: first, record: 126, partner: (5455, 666))
    }

    /// `LevelRun` at graphics mode 3: the out-mosaic's 20 blits (cells 1…20) over 57 ticks, the move, the in-mosaic's
    /// 20 blits (20…1) over 57 ticks, then the same frame resumed on the last blit's tick. Each transition first draws
    /// the sprites and copies the frame with mode 2 (the demotion), every `.mosaic` carries `graphicsMode3` false, and
    /// mode 3 comes back with `.DrawBlackLines` after the last blit.
    func testMosaicTicks() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 1)
        var prefs = FerazelPrefs()
        prefs.graphics = 3
        final class Services: LevelServices {
            func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
            func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
            func deathEffectStep(_ k: Int) throws {}
        }
        let run = try LevelRun(resources: r, prefs: prefs, level: 1, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                               fade: ScreenFade(), music: MusicFade(), services: Services(),
                               sounds: StageSounds(prefs: prefs, lengths: [:]), start: onTeleporter(L.placements[148]))
        var blits: [(t: UInt32, cell: Int)] = []
        var ticks: [UInt32: FrontOutput] = [:]
        var t: UInt32 = 0
        var moved: (x: Int, y: Int)?
        var d: (x: Int, y: Int)?
        for _ in 0..<6000 {
            let o = try run.tick(now: t, input: FrontInput()).merged
            ticks[t] = o
            if run.mosaic != nil, d == nil, let s = run.session {
                // The out-mosaic has started: the frame stopped at stage 1, the player not yet moved.
                XCTAssertEqual(s.suspension, .teleport(record: 148, stage: 1))
                let p = try playerSlot(s), tp = try teleporter(s, record: 148)
                d = (p.x - tp.x, p.y - tp.y)
            }
            for op in o.draws { if case .mosaic(let cell, let m3) = op { blits.append((t, cell)); XCTAssertFalse(m3) } }
            if blits.count >= 21, moved == nil, let s = run.session {          // the tick of both 20s
                let p = try playerSlot(s)
                moved = (p.x, p.y)
            }
            if blits.count == 40 { break }
            t &+= 1
        }
        XCTAssertEqual(blits.count, 40)
        let t0 = try XCTUnwrap(blits.first?.t)
        XCTAssertEqual(blits.map(\.cell), Array(1...20) + Array((1...20).reversed()))
        XCTAssertEqual(blits.map(\.t), (0..<20).map { t0 + 3 * UInt32($0) } + (0..<20).map { t0 + 57 + 3 * UInt32($0) })
        // The move between them (the stage-1 resume on tick t0 + 57): 149's entry (2493, 1523) + d.
        let dd = try XCTUnwrap(d), m = try XCTUnwrap(moved)
        XCTAssertEqual([m.x, m.y], [2493 + dd.x, 1523 + dd.y])
        let s = try XCTUnwrap(run.session)
        func kind(_ op: DrawOp) -> String {
            switch op {
            case .mosaic(let c, _): return "mosaic \(c)"
            case .copyToScreen(_, _, let g, _): return "copy \(g)"
            case .wrapDrawSprites: return "sprites"
            case .drawBlackLines: return "black"
            case .redrawEntireScrollGrid: return "entire"
            case .wrapEraseSprites: return "erase"
            default: return "other"
            }
        }
        // Tick t0: the frame so far, snd 421, then the out-mosaic's prelude and its first blit.
        let first = try XCTUnwrap(ticks[t0])
        XCTAssertEqual(Array(first.draws.map(kind).suffix(3)), ["sprites", "copy 2", "mosaic 1"])
        XCTAssertEqual(first.sounds.map(\.snd).last, 421)
        // Tick t0 + 57: the last out-blit, mode 3 back, the move (its grid, the sprites, snd 420), the in-mosaic's
        // prelude and first blit.
        let mid = try XCTUnwrap(ticks[t0 + 57])
        XCTAssertEqual(mid.draws.map(kind), ["mosaic 20", "black", "entire", "sprites", "sprites", "copy 2", "mosaic 20"])
        XCTAssertEqual(mid.sounds.map(\.snd), [420])
        // Tick t0 + 114: the last in-blit, mode 3 back, then the same frame's rest — its grid redraw first, the erase.
        let last = try XCTUnwrap(ticks[t0 + 114])
        XCTAssertEqual(Array(last.draws.map(kind).prefix(3)), ["mosaic 1", "black", "entire"])
        XCTAssertTrue(last.draws.contains { if case .wrapEraseSprites = $0 { true } else { false } })
        XCTAssertNil(run.mosaic)
        XCTAssertNil(s.suspension)
        XCTAssertEqual(s.player.teleporterCharge, -59)
        // Nothing between the blits but the blits (and the copies before the firsts).
        for k in 1..<57 where k % 3 != 0 { XCTAssertEqual(ticks[t0 + UInt32(k)]?.draws ?? [], [], "tick +\(k)") }
    }
}
