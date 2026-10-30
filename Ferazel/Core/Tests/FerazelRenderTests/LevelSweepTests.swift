import XCTest
import FerazelCore
@testable import FerazelRender

/// Levels 1–4 (`BuiltLevels.range`) through the renderer as the shells drive it: any refusal here is a game that quits
/// ("the screen could not be drawn"). Each level's full set-up — every face set and light face, the Setup lights, the
/// tint table — then frames of the real session applied with no refusal, the player pressing a changing mix of the
/// game's keys, the modals answered at once. Starts: the level start, and beside every rope (whose segments carry the
/// rope face sets, PICT 0x28a / 0x28c / 0x292). A missing data file is a FAILURE, never a skip.
final class LevelSweepTests: XCTestCase {
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func renderer(level: Int) throws -> FrameRenderer {
        try FrameRenderer(resources: try Self.resources.get(), level: level,
                          search: ColorSearch(model: .ruled, tieBreak: .lowest), dither: .errorDiffusion,
                          text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
    }

    /// `frames` frames from `start` (nil = the level start); the keys change every 8 frames (each of the nine prefs keys
    /// down with chance 1/3, from a fixed stream). Fails with the first refusal, naming the frame.
    private func play(level: Int, start: (x: Int, y: Int)?, frames: Int, label: String) throws {
        let r = try renderer(level: level)
        let s = try FerazelSession(resources: try Self.resources.get(), prefs: FerazelPrefs(), level: level, seed: 1,
                                   faceBounds: r.faceBounds, particleFaces: r.particleFaces,
                                   diffuseRandoms: r.diffuseRandoms, diffuseRandomsAt: r.diffuseRandomsAt,
                                   start: start)
        try r.addLights(s.lights)
        try r.buildTintTable(s.tintTableDraws)
        var rng = FastRand(seed: 8)
        var keys = KeyState()
        for k in 0..<frames {
            if k % 8 == 0 {
                keys = KeyState()
                for c in FerazelPrefs.defaultKeys where rng.next(3) == 0 { keys.press(Int(c)) }
            }
            var ops = s.step(keys: keys)
            var modals = 0
            while let pending = ops.suspension {
                do { try r.apply(ops) } catch { return XCTFail("\(label) frame \(k) before \(pending): \(error)") }
                modals += 1
                guard modals < 8 else { return }
                let none = KeyState()
                switch pending {
                case .savePoint: ops = s.resume(.savePoint(saved: false))
                case .conversation: ops = s.resume(.conversation(keys: none, capsLock: false))
                case .sign: ops = s.resume(.sign(keys: none, capsLock: false))
                case .upgrade: ops = s.resume(.upgrade(keys: none, capsLock: false))
                case .hint: ops = s.resume(.hint(keys: none, capsLock: false))
                case .teleport: ops = s.resume(.teleport(keys: none, capsLock: false))
                case .gameLoopKeys: return   // a hosted session's only (the bare session never stops here)
                }
            }
            do { try r.apply(ops) } catch { return XCTFail("\(label) frame \(k): \(error)") }
        }
    }

    /// Every level's set-up builds; all twelve `.Load1LightFaceFromPICT` call sites load (806 shrunk to 84 × 84).
    func testEveryLevelSetsUp() throws {
        let res = try Self.resources.get()
        for level in BuiltLevels.range {
            let r = try renderer(level: level)
            let s = try FerazelSession(resources: res, prefs: FerazelPrefs(), level: level, seed: 1,
                                       faceBounds: r.faceBounds, particleFaces: r.particleFaces,
                                       diffuseRandoms: r.diffuseRandoms, diffuseRandomsAt: r.diffuseRandomsAt)
            XCTAssertNoThrow(try r.addLights(s.lights), "level \(level)")
            XCTAssertNoThrow(try r.buildTintTable(s.tintTableDraws), "level \(level)")
        }
        for site in LightFace.callSites {
            XCTAssertNoThrow(try LightFace.load(pict: site.pict, width: site.width, height: site.height, from: res,
                                                search: ColorSearch(model: .ruled, tieBreak: .lowest)), "\(site)")
        }
    }

    func testEveryLevelPlaysFromItsStart() throws {
        for level in BuiltLevels.range { try play(level: level, start: nil, frames: 240, label: "level \(level)") }
    }

    func testEveryRopeDraws() throws {
        var ropes = 0
        for level in BuiltLevels.range {
            let L = try LevelFile.load(from: try Self.resources.get(), level: Int16(level))
            for p in L.placements where RopeSprite.types.contains(p.type) {
                ropes += 1
                try play(level: level, start: (x: Int(p.x) - 40, y: Int(p.y) - 90), frames: 30,
                         label: "level \(level) rope \(p.type) record \(p.index)")
            }
        }
        XCTAssertGreaterThan(ropes, 0)
    }
}
