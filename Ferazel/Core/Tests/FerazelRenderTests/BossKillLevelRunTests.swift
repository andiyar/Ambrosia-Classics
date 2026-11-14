import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// 6A-W2 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-W2`; docs/ferazel/phase6-boss-contracts.md
/// §1.1, §2.9 items 6 and 8, §2.10): the Warrior's death ends in a burn, and a burn completes only through the REAL
/// renderer's face store ("Burns end only with face pixels") — so these run level 5 through `LevelRun` with the renderer
/// side built as `FerazelDriver.prepare` builds it, as `GoblinBurnLevelRunTests` does. Frames are `.GameLoop`
/// iterations (`LevelRun.iterations`). A missing data file is a FAILURE, never a skip.
final class BossKillLevelRunTests: XCTestCase {
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// `FerazelDriver.prepare` / `attach` (`Ferazel/Shared/FerazelDriver.swift`).
    final class Services: LevelServices {
        private(set) var renderer: FrameRenderer?
        func prepare(level: Int) throws -> LevelFaces {
            let r = try FrameRenderer(resources: try BossKillLevelRunTests.resources.get(), level: level,
                                      search: ColorSearch(model: .ruled, tieBreak: .lowest), dither: .errorDiffusion,
                                      text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
            renderer = r
            return LevelFaces(faceBounds: r.faceBounds, particleFaces: r.particleFaces, diffuseRandoms: r.diffuseRandoms,
                              diffuseRandomsAt: r.diffuseRandomsAt)
        }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
            guard let r = renderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
            try r.addLights(lights)
            try r.buildTintTable(tintTableDraws)
        }
        func deathEffectStep(_ k: Int) throws {}
    }

    /// Level 5 through the level runner from the level start, seed 1, the default prefs (effects 1, Enhanced).
    private func open(_ services: Services) throws -> LevelRun {
        let res = try Self.resources.get()
        let prefs = FerazelPrefs()
        XCTAssertEqual(prefs.effects, 1)
        return try LevelRun(resources: res, prefs: prefs, level: 5, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                            fade: ScreenFade(), music: MusicFade(), services: services,
                            sounds: StageSounds(prefs: prefs, lengths: [:]))
    }

    /// The opaque top `T` / bottom `B` (face `+8` / `+0xc`) of the last death face 0x71e[5], from the renderer's store.
    private func opaque(_ services: Services) throws -> (top: Int16, bottom: Int16) {
        let r = try XCTUnwrap(services.renderer)
        let f = try XCTUnwrap(r.particleFaces.sprite(FaceRef(pict: Warrior.deathSet, index: 5, set: .encoded)),
                              "the store holds 0x71e[5]")
        return (f.bounds[0], f.bounds[2])
    }

    private func warrior(_ run: LevelRun) -> SpriteSlot? {
        run.session?.world.active.sprites.first { $0.handler == .warrior }
    }

    /// What a death watched frame by frame shows: the death-entry frame (state 4 first seen), the burn rows (one a
    /// frame, each through the store's face), the Kill frame (`+0xe9` first set).
    private struct Death {
        var entry: Int?, kill: Int?
        var rows: [Int16] = []
        var faces: [FaceRef] = []
        mutating func watch(_ run: LevelRun, _ services: Services) throws {
            guard let b = run.session?.world.active.record(id: try XCTUnwrap(warriorID)) else { return }
            if entry == nil && b.subtype == 4 { entry = run.iterations }
            if kill == nil && b.killCount == 0 && 0 < b.burnRow && rows.last != b.burnRow {
                rows.append(b.burnRow)
                faces.append(try XCTUnwrap(b.face))
                XCTAssertNotNil(services.renderer?.particleFaces.sprite(try XCTUnwrap(b.face)), "the store has the face")
            }
            if kill == nil && b.killCount != 0 { kill = run.iterations }
        }
        var warriorID: Int?
    }

    func testWarriorKillFrameFormula() throws {
        // The death-to-Kill tail (BOS §1.1, §2.3, §2.10): the death entry sets `+0xb0 = 4` on frame HP0 (the Handle's
        // tail, M l. 73393–73398 — not the crush's frame); dying frames 1…45 follow (M l. 73267–73280), the 45th sets
        // `+0x1a2 = 1`; `.HandleBurn` (M l. 38765–38838) in that frame's Cleanup jumps to the opaque top T of face 0x71e[5]
        // and burns one row a frame (`+0x8d` 0), rows T + 1 … B, one R(100) a row at effects 1; past B the Kill proc
        // `+0x50` (`.KillWarrior`). So Kill − HP0 = 45 + (B − T). Set-up: Left held until the arena locks (his Handle
        // runs its tail only while locked), then `.HurtSprite` takes his HP to 0 between frames.
        let services = Services()
        let run = try open(services)
        let left = Int(FerazelPrefs().keys[0])
        var t: UInt32 = 0
        func tick(_ keys: [Int] = []) throws {
            _ = try run.tick(now: t, input: FrontInput(keys: KeyState(pressed: keys)))
            t &+= 1
        }
        while !(run.session?.world.arena.locked ?? false) && t < 4000 { try tick([left]) }
        let w = try XCTUnwrap(run.session?.world)
        XCTAssertTrue(w.arena.locked)
        var b = try XCTUnwrap(warrior(run))
        XCTAssertEqual(b.hp, 2000)
        XCTAssertNotEqual(b.subtype, 4)
        let live0 = w.enemies.live
        let hurtAt = run.iterations
        XCTAssertTrue(HurtSprite.apply(w, id: b.id, damage: b.hp, dvx: 0, dvy: -1000, invulnerable: 2, flash: 8))
        var d = Death(warriorID: b.id)
        let o = try opaque(services)
        while d.kill == nil && t < 8000 {
            let before = run.iterations
            try tick()
            if run.iterations != before { try d.watch(run, services) }
        }
        let entry = try XCTUnwrap(d.entry), kill = try XCTUnwrap(d.kill)
        XCTAssertEqual(entry, hurtAt + 1, "the death entry in the next frame's Handle")
        XCTAssertEqual(kill - entry, 45 + Int(o.bottom - o.top), "Kill − HP0 = 45 + (B − T): T \(o.top), B \(o.bottom)")
        XCTAssertEqual(d.rows, Array((o.top + 1)...o.bottom), "one row a frame, T + 1 … B")
        XCTAssertTrue(d.faces.allSatisfy { $0 == FaceRef(pict: Warrior.deathSet, index: 5, set: .encoded) },
                      "the burn runs on 0x71e[5] (dying frame 45: n capped at 0x17)")
        b = try XCTUnwrap(w.active.record(id: b.id))
        XCTAssertEqual([b.killCount != 0, b.killedForGood], [true, true])
        XCTAssertEqual(w.enemies.live, live0 - 1, "counted once")
        XCTAssertEqual(w.arena.noBossAlive, 1, "the boss-kill tail ran")

        // One R(100) a burn row at effects 1 (M l. 38765–38838; BOS §2.10). In the run every other sprite's draws fall
        // between the burn's, so the burn is replayed on the run's own world with the store's 0x71e[5]: rows T + 1 … B
        // through `Burn.handle`, each row's draws counted on a copy of the stream — `.BurnFaceRow` at spacing 2 (R4, R12,
        // R100, R150, R50, R25 a spawn; R5 == 1 → R200, R100, R250, R25), then the row's one R(100), > 50 → the row again
        // at spacing 1. (Row T + 1 is entered from `+0x1a2` = T: no row-1 sound.)
        XCTAssertEqual(w.voices.prefs.effects, 1)
        let deathFace = FaceRef(pict: Warrior.deathSet, index: 5, set: .encoded)
        let face = try XCTUnwrap(w.particleFaces.sprite(deathFace))
        func pixels(_ row: Int16) -> Int {                      // the literal pixels of token row `row`
            var rowCount = 0, p = 0, n = 0
            while let t = face.word(p) {
                p += 4
                let op = t >> 24, k = Int(t & 0xff_ffff)
                if op == 1 { rowCount += 1 }
                else if op == 2 {
                    if rowCount == Int(row) { n += k }
                    p += k + (k & 3 == 0 ? 0 : 4 - (k & 3))
                } else if op != 3 { break }
            }
            return n
        }
        var s = b
        s.face = deathFace
        s.burnRow = o.top
        s.burnSpeed = 0
        for row in (o.top + 1)...o.bottom {
            var e = w.rng
            func spawn(_ count: Int) {
                for _ in 0..<count {
                    for n: Int16 in [4, 0xc, 100, 0x96, 0x32, 0x19] { _ = e.next(n) }
                    if e.next(5) == 1 { for n: Int16 in [200, 100, 0xfa, 0x19] { _ = e.next(n) } }
                }
            }
            let n = pixels(row)
            spawn((n + 1) / 2)
            if 0x32 < e.next(100) { spawn(n) }
            Burn.handle(w, &s)
            XCTAssertEqual(s.burnRow, row)
            XCTAssertEqual(w.rng.seed, e.seed, "row \(row) (\(n) px): the row's spawns, then one R(100)")
        }
    }

    func testWarriorScriptedKill() throws {
        // The scripted fight (BOS §2.10, measured by the build — D46.4; the seat's ruling of 2026-11-14 replaced the
        // contract's starting script, which never brought a crate down on him). How the fight is won: the crates rest on
        // three background ledges (kind 103, row 5) above his patrol line; Ferazel climbs onto the right-hand ledge
        // (cells 37…38, x 1184…1247) by the blinking platform 1403 at x 1274, and pushes the crate off the ledge's edge
        // (a rock 0x433 has push mass 0x8c) as the Warrior walks beneath: a crate falling onto him is `.HitWarriorSprite`'s
        // crush (`.PlatformBounce` 2, vy > 0) — 200 a crate, 10 crates. A crate that falls dies (`.KillBox`) and a new one
        // drops onto the same ledge 14 Handle frames later. The script below decides its keys from what a player sees
        // (positions of Ferazel, the Warrior, the crates and the platform); nothing is patched.
        let services = Services()
        let run = try open(services)
        let k = FerazelPrefs().keys
        var script = WarriorFightScript(left: Int(k[0]), right: Int(k[1]), jump: Int(k[5]))
        var t: UInt32 = 0
        var keys: [Int] = [], decidedFor = -1
        var d = Death()
        var hps: [Int16] = [2000], crushFrames: [Int] = []
        var phases: [String] = []                                       // (frame, phase) at each change, for a failure
        let cap = 20_000
        func alive() -> Bool { (run.session?.globals.health ?? 1) >= 1 }
        // Stops at the Kill, or as soon as Ferazel's health is gone (not 50 death-effect steps later), or at the cap.
        while d.kill == nil && run.iterations < cap && alive() && !run.died && run.end == nil {
            // The keys are decided once per `.GameLoop` iteration (the loop runs every other tick) and held until it runs.
            if decidedFor != run.iterations, let s = run.session {
                decidedFor = run.iterations
                let before = script.phase
                keys = script.keys(s.world)
                if phases.isEmpty || script.phase != before { phases.append("\(run.iterations) \(script.phase)") }
            }
            let before = run.iterations
            _ = try run.tick(now: t, input: FrontInput(keys: KeyState(pressed: keys)))
            t &+= 1
            guard run.iterations != before, let b = warrior(run) else { continue }
            if d.warriorID == nil { d.warriorID = b.id }
            if hps.last != b.hp { hps.append(b.hp); crushFrames.append(run.iterations) }
            try d.watch(run, services)
        }
        let o = try opaque(services)
        let trail = "script phases (frame phase): " + phases.joined(separator: ", ")
        XCTAssertTrue(alive() && !run.died, "Ferazel lives (frame \(run.iterations)); \(trail)")
        let hp0 = try XCTUnwrap(d.entry, "HP 0 within \(cap) frames; \(trail)"), kill = try XCTUnwrap(d.kill)
        XCTAssertEqual(hps, stride(from: 2000, through: 0, by: -200).map { Int16($0) }, "ten crushes of 200")
        XCTAssertEqual(crushFrames, [350, 842, 1962, 2391, 2546, 2759, 3834, 4164, 4584, 4965],
                       "the crush frames; \(trail)")
        XCTAssertEqual(hp0, try XCTUnwrap(crushFrames.last) + 1, "the death entry one frame after the tenth crush")
        XCTAssertEqual(kill - hp0, 45 + Int(o.bottom - o.top), "Kill − HP0 = 45 + (B − T)")
        XCTAssertEqual(hp0, Self.pinnedHP0, "the HP-0 frame, measured once (D46.4)")
        XCTAssertEqual(kill, Self.pinnedKill, "the Kill frame, measured once (D46.4)")
        XCTAssertEqual(run.session?.world.arena.noBossAlive, 1, "the boss-kill tail: the gate opens")
    }

    /// Measured 2026-11-14 (6A-W2): crushes on frames 350, 842, 1962, 2391, 2546, 2759, 3834, 4164, 4584, 4965; the death
    /// entry on 4966; T 111, B 151 → the Kill on 4966 + 45 + 40 = 5051.
    static let pinnedHP0 = 4966, pinnedKill = 5051
}

/// The Warrior's scripted fight: the keys, decided each frame from what a player sees (positions only).
struct WarriorFightScript {
    let left: Int, right: Int, jump: Int
    var phase = Phase.approach
    var airborne = 0
    var lastWX: Int?
    var target = 1198

    enum Phase { case approach, waitPlatform, toPlatform, toLedge, retreat, push, fired }

    mutating func keys(_ w: SpriteWorld) -> [Int] {
        guard let pid = w.playerID, let p = w.active.record(id: pid) else { return [] }
        let him = w.active.sprites.first { $0.handler == .warrior }
        let wdx = (him?.x ?? 0) - (lastWX ?? him?.x ?? 0)              // his motion since the last frame
        lastWX = him?.x
        let pc = p.x + 50                                              // Ferazel's middle (hot rect 38…62)
        switch phase {
        case .approach:
            // Phase 1: Left from the level start until the arena locks behind him (x < 1384); he stops on the step.
            if !w.arena.locked { return [left] }
            phase = .waitPlatform
            return []
        case .waitPlatform:
            // Phase 2: wait on the step until the blinking platform at x 1274 has just come back (solid, fading in).
            // (Its face counter `phase` 11…0x12 is the fade-in a player watches: the platform drawn again, solid.)
            guard let pl = w.active.sprites.first(where: { $0.type == 1403 && $0.x == 1274 }),
                  pl.phase < 0x13, 10 < pl.phase else { return [] }
            phase = .toPlatform
            airborne = 0
            fallthrough                                                 // jump this same frame (one `wdx` a frame)
        case .toPlatform:
            // Phase 3: a held jump (14 frames) steered over the platform's middle (x 1274 + 0x28); landed → next.
            var k: [Int] = airborne < 14 ? [jump] : []
            let mid = 1274 + 0x28
            if pc > mid + 4 { k.append(left) } else if pc < mid - 4 { k.append(right) }
            airborne += 1
            if 4 < airborne && p.groundKind != 0 { phase = .toLedge; airborne = 0; return [] }   // standing on it
            return k
        case .toLedge:
            // Phase 4: a held jump to the right-hand ledge (x 1184…1247), steered to x 1194…1200 — right of its crate.
            var k: [Int] = airborne < 14 ? [jump] : []
            if 1200 < p.x { k.append(left) } else if p.x < 1194 { k.append(right) }
            airborne += 1
            if 4 < airborne && p.groundKind != 0 { phase = .retreat; target = pc < 1217 ? 1132 : 1198 }  // on it
            return k
        default:
            break
        }
        // On the ledge. The crate of this ledge (the respawn falls at x 1201, its hot rect 1205…1229).
        let crate = w.active.sprites.first { $0.type == 0x433 && !$0.dead && (1100...1300).contains($0.x) && 100 < $0.y && $0.y < 160 }
        let resting = crate.map { $0.vy == 0 && $0.vx == 0 && 146 <= $0.y } ?? false   // still, down on the ledge
        if phase == .fired {
            // Phase 7: push until the crate moves, then step aside.
            if let c = crate, c.vx == 0, c.vy == 0 { return pc > c.x + 16 ? [left] : [right] }   // it has not moved
            phase = .retreat
            target = pc < 1217 ? 1132 : 1198
        }
        if phase == .retreat {
            // Phase 5: stand clear of the respawn column — x 1132 (left part) or 1198 (right part), whichever is nearer
            // — until a crate rests on the ledge (not while one slides or falls).
            if 3 < abs(p.x - target) && !(crate != nil && !resting) { return p.x > target ? [left] : [right] }
            if resting { phase = .push }
            return []
        }
        guard let c = crate, resting else {
            phase = .retreat
            target = pc < 1217 ? 1132 : 1198
            return []
        }
        // Phase 6: walk up to the crate (from the side Ferazel is on); a first touch slides it to the edge; then wait,
        // and push it over when the Warrior, moving as he moved last frame, will have his middle under the drop in
        // ~16 frames (the left drop's column x ≈ 1166, the right one's ≈ 1261).
        let fromRight = pc > c.x + 16
        let gap = fromRight ? (p.x + 38) - (c.x + 0x1c) : (c.x + 4) - (p.x + 62)
        let atEdge = fromRight ? c.x < 1180 : 1222 < c.x
        if 18 < gap { return fromRight ? [left] : [right] }
        if !atEdge {
            phase = .fired
            return fromRight ? [left] : [right]
        }
        guard let b = him, b.subtype != 4 else { return [] }               // state 4: he is dying (the death face)
        let column = fromRight ? 1166 : 1261
        let x16 = b.x + wdx * 16
        if x16 + 0x2a + 4 < column - 12 && column + 12 < x16 + 0x89 - 4 {
            phase = .fired
            return fromRight ? [left] : [right]
        }
        return []
    }
}
