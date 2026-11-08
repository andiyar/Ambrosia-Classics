import XCTest
import HectorResources
@testable import FerazelCore
@testable import FerazelRender

/// OX (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, wave 3): OmniPx modes 2 / 4 / 5 — level 5's moving
/// backdrop (rendering-omnipx-titles §1, §3.1–§3.5; M l. 13019–13547). Core's `OmniPx` (`.SetupOmniPx`,
/// `.TurnOnOmniPx`, `.UpdateOmniPx`) and the renderer's 128×128 port as PxBack slot 0. Level 5 is not in `BuiltLevels`
/// yet (its arena bound refuses a session until LV5): it is loaded directly, as the audit loads headers. A missing data
/// file is a FAILURE, never a skip.
final class OmniPxTests: XCTestCase {
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func level(_ n: Int16, omniPxMode: UInt8? = nil) throws -> LevelFile {
        let res = try Self.resources.get()
        let mlvl = try XCTUnwrap(res.world.resource(type: "Mlvl", id: n))
        var d = mlvl.data
        if let m = omniPxMode { d[d.startIndex + 0x26c7] = m }
        return try LevelFile(id: n, data: d)
    }

    /// `.SetupOmniPx` (M l. 13125–13297) on level 5 (mode 2), then its mode 4 / 5 / 0 arms on the same level patched.
    func testOmniPxSetupMode2() throws {
        var L = try level(5)
        XCTAssertEqual(L.header.omniPxMode, 2)
        var g = GameGlobals(header: L.header)
        var o = OmniPx()
        o.setup(level: &L, globals: &g)
        XCTAssertEqual(o.omniPxMode, 2)
        XCTAssertEqual(g.omniPxActive, 1, "`.TurnOnOmniPx` sets G+0x174")
        XCTAssertEqual(o.faces, [0x1839, 0x1838] + [Int16?](repeating: nil, count: 14), "faces 6201 / 6200")
        XCTAssertEqual(o.fx, [0x40, 0x80] + [Int16](repeating: 0, count: 14))
        XCTAssertEqual(o.fy, [0x40, 0x80] + [Int16](repeating: 0, count: 14))
        XCTAssertEqual(o.vx, [-0x80, 0x80] + [Int16](repeating: 0, count: 14), "0xff80, 0x80")
        XCTAssertEqual(o.vy, [-0x200, 0x400] + [Int16](repeating: 0, count: 14), "0xfe00, 0x400")
        XCTAssertEqual(o.accX, [Int16](repeating: 0, count: 16))
        XCTAssertEqual(o.accY, [Int16](repeating: 0, count: 16))
        XCTAssertEqual(o.counter, 0, "the setup leaves the counter alone")

        // Mode 4: mode 2's faces and parameters; mode 5: 6301 / 6300 with the same parameters.
        let modeFaces: [(UInt8, [Int16])] = [(4, [0x1839, 0x1838]), (5, [0x189d, 0x189c])]
        for (m, faces) in modeFaces {
            var Lm = try level(5, omniPxMode: m)
            var gm = GameGlobals(header: Lm.header)
            var om = OmniPx(counter: 9)
            om.setup(level: &Lm, globals: &gm)
            XCTAssertEqual(Array(om.faces.prefix(2)), faces.map { Optional($0) }, "mode \(m)")
            XCTAssertEqual(om.faces.dropFirst(2).compactMap { $0 }, [], "mode \(m)")
            XCTAssertEqual([om.fx[0], om.fx[1], om.fy[0], om.fy[1]], [0x40, 0x80, 0x40, 0x80], "mode \(m)")
            XCTAssertEqual([om.vx[0], om.vx[1], om.vy[0], om.vy[1]], [-0x80, 0x80, -0x200, 0x400], "mode \(m)")
            XCTAssertEqual(gm.omniPxActive, 1, "mode \(m)")
            XCTAssertEqual(om.counter, 9, "mode \(m)")
        }
        XCTAssertEqual(OmniPx.facePicts(omniPxMode: 3), [], "mode 3 loads no face")
        XCTAssertEqual(OmniPx.facePicts(omniPxMode: 6), [])
        XCTAssertEqual(OmniPx.facePicts(omniPxMode: 1), [0x1770, 0x1771])

        // Mode 0 (levels 1–4): `G+0x174 = 0` and return — no faces, nothing on.
        var L1 = try level(1)
        var g1 = GameGlobals(header: L1.header)
        g1.omniPxActive = 1
        let before = L1
        var o1 = OmniPx()
        o1.setup(level: &L1, globals: &g1)
        XCTAssertEqual(g1.omniPxActive, 0)
        XCTAssertEqual(o1.faces.compactMap { $0 }, [])
        XCTAssertEqual(L1, before, "mode 0 leaves the header's factors")
        XCTAssertNil(o1.update(globals: g1, h: 100, v: 100), "no op while OmniPx is off")
    }

    /// `.UpdateOmniPx`'s base (M l. 13429–13437): modes 2 / 4 / 5 copy PxBack cell 6 + (c >> 1), c reset to 0 when
    /// above 0x11 before the copy; c + 1 per active face inside the face loop (M l. 13469–13471).
    func testUpdateCyclesBaseCells() throws {
        var L = try level(5)
        var g = GameGlobals(header: L.header)
        var o = OmniPx()
        o.setup(level: &L, globals: &g)
        var cells: [Int] = [], counters: [Int16] = []
        for _ in 0..<20 {
            let f = try XCTUnwrap(o.update(globals: g, h: 0, v: 0))
            XCTAssertEqual(f.omniPxMode, 2)
            XCTAssertEqual(f.faces.map(\.pict), [0x1839, 0x1838])
            cells.append(try XCTUnwrap(f.baseCell))
            counters.append(o.counter)
        }
        // Two faces: + 2 a drawn frame, one cell a frame, a 9-frame cycle.
        XCTAssertEqual(cells, [6, 7, 8, 9, 10, 11, 12, 13, 14, 6, 7, 8, 9, 10, 11, 12, 13, 14, 6, 7])
        XCTAssertEqual(counters, [2, 4, 6, 8, 10, 12, 14, 16, 18, 2, 4, 6, 8, 10, 12, 14, 16, 18, 2, 4])

        // One face: + 1 a drawn frame, each cell two frames; 17 → 18 is reset only at the next base.
        o.faces[1] = nil
        o.counter = 15
        var one: [Int] = [], oneCounters: [Int16] = []
        for _ in 0..<6 {
            let f = try XCTUnwrap(o.update(globals: g, h: 0, v: 0))
            XCTAssertEqual(f.faces.count, 1)
            one.append(try XCTUnwrap(f.baseCell))
            oneCounters.append(o.counter)
        }
        XCTAssertEqual(one, [13, 14, 14, 6, 6, 7])
        XCTAssertEqual(oneCounters, [16, 17, 18, 1, 2, 3])

        // No faces: the base still copies, the counter stays.
        o.faces = [Int16?](repeating: nil, count: 16)
        let f0 = try XCTUnwrap(o.update(globals: g, h: 0, v: 0))
        XCTAssertEqual(f0.baseCell, 7)
        XCTAssertEqual(f0.faces, [])
        XCTAssertEqual(o.counter, 3)

        // Mode 5 takes the same base path; a mode with no base (3) copies none and still counts its faces.
        var L5 = try level(5, omniPxMode: 5)
        var g5 = GameGlobals(header: L5.header)
        var o5 = OmniPx(counter: 18)
        o5.setup(level: &L5, globals: &g5)
        XCTAssertEqual(o5.update(globals: g5, h: 0, v: 0)?.baseCell, 6)
        XCTAssertEqual(o5.counter, 2)
        var L3 = try level(5, omniPxMode: 3)
        var g3 = GameGlobals(header: L3.header)
        var o3 = OmniPx(counter: 4)
        o3.setup(level: &L3, globals: &g3)
        let f3 = try XCTUnwrap(o3.update(globals: g3, h: 0, v: 0))
        XCTAssertNil(f3.baseCell)
        XCTAssertEqual(f3.faces, [])
        XCTAssertEqual(o3.counter, 4)
    }

    /// The faces' drift (M l. 13472–13497): `accX += vx`, `accY −= vy` as 16-bit shorts, > 0x7fff → − 0x8000 (dead on a
    /// short) and negative → − 0x8000 as a 16-bit short; x = −(((accX >> 8) + (H·fx >> 8)) rem 128), y likewise with
    /// V·fy; drawn at (x, y) and, unless both are 0, at (x+128, y), (x+128, y+128), (x, y+128). And `.TurnOnOmniPx`
    /// (M l. 13019–13060): modes ∉ 4…7 back up and zero the header's PxBack factors — Core's copy.
    func testFaceWrapToroidal() throws {
        var L = try level(5)
        if L.header.pxBackYFactor == 0 { L.header.pxBackYFactor = 0x40 }  // a non-zero yb to back up
        let factors = L.backFactors, yb = L.header.pxBackYFactor
        XCTAssertTrue(factors.contains { $0 != 0 }, "level 5 has backdrop factors to zero")
        XCTAssertNotEqual(yb, 0)
        var g = GameGlobals(header: L.header)
        var o = OmniPx()
        o.setup(level: &L, globals: &g)
        XCTAssertEqual(L.backFactors, [Int16](repeating: 0, count: LevelFile.factorRows), "hdr+0x326c zeroed")
        XCTAssertEqual(L.header.pxBackYFactor, 0, "hdr+0xb26c zeroed")
        XCTAssertEqual(L.midFactors, try level(5).midFactors, "the PxMid table is not touched")

        // Positive overflow: 0x7f80 + 0x100 = 0x8080 → the short −0x7f80 → − 0x8000 → 0x0080.
        // Negative: 0x100 − 0x200 = −0x100 → − 0x8000 as a short → 0x7f00.
        o.accX[0] = 0x7f80; o.vx[0] = 0x100
        o.accY[0] = 0x100; o.vy[0] = 0x200
        o.accX[1] = 0; o.vx[1] = 0; o.accY[1] = 0; o.vy[1] = 0
        let f = try XCTUnwrap(o.update(globals: g, h: 300, v: 50))
        XCTAssertEqual(o.accX[0], 0x80)
        XCTAssertEqual(o.accY[0], 0x7f00)
        // x: (0x80 >> 8) + (300·0x40 >> 8) = 75 → −75; y: (0x7f00 >> 8) + (50·0x40 >> 8) = 127 + 12 = 139 → −11.
        XCTAssertEqual(f.faces[0], OmniPxFrame.Face(pict: 0x1839, x: -75, y: -11))
        XCTAssertEqual(f.faces[0].draws, [(-75, -11), (53, -11), (53, 117), (-75, 117)].map { [$0.0, $0.1] })
        // Face 1: acc 0; x = −((300·0x80 >> 8) rem 128) = −(150 rem 128) = −22; y = −(50·0x80 >> 8) = −25.
        XCTAssertEqual(f.faces[1], OmniPxFrame.Face(pict: 0x1838, x: -22, y: -25))

        // Exactly one offset 0 still wraps: the test is x ≠ 0 or y ≠ 0 (M l. 13498).
        XCTAssertEqual(OmniPxFrame.Face(pict: 0x1839, x: 0, y: -11).draws, [[0, -11], [128, -11], [128, 117], [0, 117]])
        XCTAssertEqual(OmniPxFrame.Face(pict: 0x1839, x: -75, y: 0).draws, [[-75, 0], [53, 0], [53, 128], [-75, 128]])

        // Both 0: one draw only.
        o.accX = [Int16](repeating: 0, count: 16); o.accY = o.accX; o.vx = o.accX; o.vy = o.accX
        let z = try XCTUnwrap(o.update(globals: g, h: 0, v: 0))
        XCTAssertEqual(z.faces.map(\.draws), [[[0, 0]], [[0, 0]]])

        // The remainder truncates (a negative sum gives a positive offset), and the arithmetic is 16-bit.
        o.vx[0] = -0x100                       // accX 0 → −0x100 → 0x7f00: (0x7f) + (−128·0x40 >> 8 = −32) = 95
        let n = try XCTUnwrap(o.update(globals: g, h: -128, v: 0))
        XCTAssertEqual(o.accX[0], 0x7f00)
        XCTAssertEqual(n.faces[0].x, -95)
        XCTAssertEqual(n.faces[1].x, -(-64 % 128), "−128·0x80 >> 8 = −64 → +64")

        // Modes 4…7 keep the factors (`.TurnOnOmniPx`'s test, M l. 13041); turning on twice does nothing.
        var L4 = try level(5, omniPxMode: 4)
        var g4 = GameGlobals(header: L4.header)
        var o4 = OmniPx()
        o4.setup(level: &L4, globals: &g4)
        XCTAssertEqual(L4.backFactors, factors)
        XCTAssertEqual(L4.header.pxBackYFactor, try level(5).header.pxBackYFactor)
        XCTAssertFalse(OmniPx.turnOnZeroesFactors(omniPxMode: 5))
        XCTAssertTrue(OmniPx.turnOnZeroesFactors(omniPxMode: 2))
        XCTAssertTrue(OmniPx.turnOnZeroesFactors(omniPxMode: 8))

        // `.TurnOffOmniPx` (M l. 13063–13121): off, and the backup copied back — the x-factors as they were, `yb` as 0
        // (`.TurnOnOmniPx` re-saves the zeroed field on every pass, M l. 13048–13050); `.KillOmniPx`: no faces.
        o.turnOff(level: &L, globals: &g)
        XCTAssertEqual(g.omniPxActive, 0)
        XCTAssertEqual(L.backFactors, factors)
        XCTAssertEqual(L.header.pxBackYFactor, 0, "yb comes back 0, as the binary restores it")
        XCTAssertNil(o.update(globals: g, h: 0, v: 0))
        o.kill()
        XCTAssertEqual(o.faces.compactMap { $0 }, [])
    }

    /// The counter `c` (`0x100f97e8`, BSS) is never reset between levels: it rides `LevelCarry`, untouched by a mode-0
    /// level, and the next OmniPx level's first base reads it. Levels 1–4 emit no `.omniPx`.
    func testCounterCarriesAcrossLevels() throws {
        XCTAssertEqual(LevelCarry().omniPxCounter, 0, "BSS: 0 at launch")
        let res = try Self.resources.get()
        var carry = LevelCarry()
        carry.omniPxCounter = 7
        let s = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: 1, carry: carry)
        XCTAssertEqual(s.omniPx.counter, 7)
        XCTAssertEqual(s.world.globals.omniPxActive, 0)
        for _ in 0..<12 {
            let ops = s.step(keys: KeyState())
            XCTAssertFalse(ops.draws.contains { if case .omniPx = $0 { true } else { false } }, "level 1: no OmniPx op")
        }
        let next = s.carry
        XCTAssertEqual(next.omniPxCounter, 7, "a mode-0 level leaves c")

        // Level 5 from that carry: the first base is cell 6 + (7 >> 1) = 9, then c = 9.
        var L = try level(5)
        var g = GameGlobals(header: L.header)
        var o = OmniPx(counter: next.omniPxCounter)
        o.setup(level: &L, globals: &g)
        XCTAssertEqual(o.update(globals: g, h: 0, v: 0)?.baseCell, 9)
        XCTAssertEqual(o.counter, 9)
        o.turnOff(level: &L, globals: &g)
        o.kill()
        XCTAssertEqual(o.counter, 9, "turning off and killing leave c")
    }

    /// A level-5 `FrameRenderer` with its tint table built. Level 5's placements of six types have no transcribed Setup
    /// until LV5 (the Warrior 1820; 2822, 2826, 2829, 2840, 2841), so it is built with exactly those switched off (their
    /// records' flag byte 0) — the backdrop reads no placement. The audit's OmniPx row builds the same renderer.
    static func level5Renderer() throws -> (renderer: FrameRenderer, resources: FerazelResources) {
        let data = try resources.get()
        let mlvl = try XCTUnwrap(data.world.resource(type: "Mlvl", id: 5))
        let L5 = try LevelFile(id: 5, data: mlvl.data)
        let ctx = SetupFaces.Context(level: L5, playerX: SetupFaces.Context.levelStartPlayerX(L5.header),
                                     effects: FerazelPrefs().effects)
        var bytes = mlvl.data
        var off: [Int16] = []
        for p in L5.activePlacements where (try? SetupFaces.setup(p, context: ctx)) == nil {
            bytes[bytes.startIndex + 4 + 16 * p.index] = 0
            off.append(p.type)
        }
        XCTAssertEqual(Set(off), [1820, 2822, 2826, 2829, 2840, 2841], "only the untranscribed types are switched off")
        var world = data.world
        world.add(Resource(type: "Mlvl", id: 5, name: mlvl.name, data: bytes))
        let res = FerazelResources(app: data.app, world: world, backgrounds: data.backgrounds, sprites: data.sprites,
                                   sounds: data.sounds, titles: data.titles, musicDirectory: data.musicDirectory)
        let r = try FrameRenderer(resources: res, level: 5, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                  dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
        try r.buildTintTable([Int16](repeating: 0, count: 0xff * 2))
        return (r, res)
    }

    /// A level-5 `FrameRenderer`: the level start's `.omniPx(.turnOn)` (`.SetupOmniPx(0)`, M l. 2540) turns OmniPx on
    /// before any frame — `.GetPxBackTile` answers 0, the factors are zeroed (mode 2), the 0-filled port is PxBack slot
    /// 0; then a first frame's ops with the `.omniPx(.update)` op: no refusal, the port is cell 6 under faces 6201 then
    /// 6200, each wrapped toroidally, and every backdrop pixel of the copy is the port's at (view x mod 128, view row
    /// mod 128).
    func testLevel5FirstFrameDraws() throws {
        let (r, res) = try Self.level5Renderer()
        XCTAssertFalse(r.parallax.omniPxActive)
        let cell6 = Array(r.parallax.faces[(6 * 0x4000)..<(7 * 0x4000)])
        var L = try level(5)
        var g = GameGlobals(header: L.header)
        var o = OmniPx()
        o.setup(level: &L, globals: &g)

        // The level start: on before the first sprite pass.
        XCTAssertNoThrow(try r.apply(FrameOps(draws: [.omniPx(.turnOn(omniPxMode: 2))])))
        XCTAssertEqual(r.executed, [.omniPxOn(2)])
        XCTAssertTrue(r.parallax.omniPxActive)
        XCTAssertEqual(r.parallax.pxBackTile(3, 7), 0)
        XCTAssertEqual(r.parallax.backFactors, [Int16](repeating: 0, count: LevelFile.factorRows))
        XCTAssertEqual(r.parallax.backYFactor, 0)
        XCTAssertEqual(Array(r.parallax.faces[0..<0x4000]), [UInt8](repeating: 0, count: 0x4000), "the new port")
        XCTAssertTrue(r.parallax.slotLoaded[0])

        let h = 0x123, v = 0x45
        let frame = try XCTUnwrap(o.update(globals: g, h: h, v: v))
        XCTAssertEqual(frame.baseCell, 6)
        let ops = FrameOps(draws: [
            .redrawEntireScrollGrid(h: h, v: v), .redrawScrollGrid(h: h, v: v), .wrapDrawWaterEffects([]),
            .wrapDrawSprites([]), .drawParticles([]), .omniPx(.update(frame)),
            .copyToScreen(h: h, v: v, graphicsMode: 1, backdrop: true), .eraseParticles,
        ])
        XCTAssertNoThrow(try r.apply(ops))
        XCTAssertTrue(r.executed.contains(.omniPx(2)))
        XCTAssertFalse(r.executed.contains(.omniPxOn(2)), "the frame turns nothing on")

        // The port, built independently: cell 6, then each face's opaque pixels (index 0 is transparent).
        func buildPort(clut: ColorLUT) throws -> [UInt8] {
            var port = cell6
            for face in frame.faces {
                let sheet = try FaceSheet.load(.single(pict: face.pict), from: res, chain: .frontEnd, clut: clut,
                                               search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                               dither: .errorDiffusion)
                let f = sheet.faces[0], px = try f.decode()
                for d in face.draws {
                    for row in 0..<min(f.height, 128) {
                        for col in 0..<min(f.width, 128) where px[row * f.width + col] != 0 {
                            let x = d[0] + col, y = d[1] + row
                            guard (0..<128).contains(x), (0..<128).contains(y) else { continue }
                            port[y * 128 + x] = px[row * f.width + col]
                        }
                    }
                }
            }
            return port
        }
        let port = try buildPort(clut: try ColorLUT.load(id: ColorLUT.screenClutId(L.header), from: res, chain: .level))
        XCTAssertNotEqual(port, cell6, "the faces drew")
        XCTAssertEqual(Array(r.parallax.faces[0..<0x4000]), port, "slot 0 = the port")
        XCTAssertTrue(r.parallax.slotLoaded[0])
        // Pinned values, recorded once (not re-derived through the CLUT the code picks): level 5's CLUT id (236), the
        // port's FNV-1a hash, how many port pixels the faces drew over cell 6, and the first three of them (offset,
        // index). Faces loaded under the sprite CLUT 801 instead give a different port, so a wrong CLUT choice in the
        // renderer fails here.
        func fnv(_ b: [UInt8]) -> UInt32 { b.reduce(2166136261) { ($0 ^ UInt32($1)) &* 16777619 } }
        let slot0 = Array(r.parallax.faces[0..<0x4000])
        XCTAssertEqual(ColorLUT.screenClutId(L.header), 236)
        XCTAssertEqual(fnv(slot0), 2847859016)
        let drawnAt = slot0.indices.filter { slot0[$0] != cell6[$0] }
        XCTAssertEqual(drawnAt.count, 6985)
        XCTAssertEqual(drawnAt.prefix(3).map { [$0, Int(slot0[$0])] }, [[4, 74], [5, 215], [6, 226]])
        XCTAssertNotEqual(try buildPort(clut: try ColorLUT.load(id: 801, from: res, chain: .level)), slot0)

        // The copy: where the mask is 0xFF over an empty frame pixel, the screen shows the port (factors zeroed:
        // the grid is fixed to the view).
        var shown = 0
        for y in 0..<384 {
            for x in 0..<608 {
                let off = FramePorts.ringOffset(x: h + x, y: v + y)
                guard r.ports.mask[off] == 0xff, r.ports.frame[off] == 0 else { continue }
                XCTAssertEqual(r.screen[16 + x, 8 + y], port[(y % 128) * 128 + x % 128], "view (\(x), \(y))")
                shown += 1
                if shown > 50_000 { break }
            }
        }
        XCTAssertGreaterThan(shown, 0, "some backdrop shows")
    }
}
