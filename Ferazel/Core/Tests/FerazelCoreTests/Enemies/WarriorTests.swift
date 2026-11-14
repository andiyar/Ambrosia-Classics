import XCTest
@testable import FerazelCore

/// 6A-W1 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-W1`; docs/ferazel/phase6-boss-contracts.md
/// §2.3, §2.8, §2.9, §2.11): the Warrior's Handle — `.HandleWarriorSprite` (M l. 73115–73419), `.WarriorLayEgg`
/// (M l. 73080–73092), `.RandomWarriorAttack` (M l. 73095–73112), `.HitWarriorTileSprite` (M l. 73498–73530). Every
/// test opens level 5 (built) as `LevelFiveTests` does — the Warrior record 0 (x 875, y 227, p4 1) — and drives the
/// session, or the Handle alone on the session's world. Every expected draw is re-derived from a copy of the stream.
final class WarriorTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func session(seed: Int32 = 1) throws -> FerazelSession {
        try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 5, seed: seed)
    }

    private func warriorID(_ s: FerazelSession) throws -> Int {
        try XCTUnwrap(s.world.active.sprites.first { $0.handler == .warrior }?.id)
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// One Warrior Handle call (the session's dispatch row, without the rest of the frame).
    private func handle(_ w: SpriteWorld, _ id: Int) {
        Warrior.handle(world: w, id: id, solver: TileSolver(world: w))
    }

    /// The Warrior's crate slots `+0x1d4` / `+0x1d8` / `+0x1dc`.
    private func slots(_ s: SpriteSlot) -> [Int?] { [s.siblings.first, s.siblings.second, s.siblings.third] }

    /// The first seed in 1…10,000,000 whose stream makes `pick` true (the rarest pick here, the far egg edge, needs
    /// 1,024,787); none → a failure, not a hang.
    private func seed(_ pick: (inout FastRand) -> Bool) -> Int32 {
        for s: Int32 in 1...10_000_000 {
            var r = FastRand(seed: s)
            if pick(&r) { return s }
        }
        XCTFail("no seed in 1…10,000,000 makes the pick true")
        return 1
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// The Warrior with the arena locked, in `state`, standing where the level put it, its centre and the player's
    /// centre globals given (the decide's inputs).
    private func locked(_ s: FerazelSession, state: Int16, body: (inout SpriteSlot) -> Void = { _ in }) throws -> Int {
        let id = try warriorID(s)
        s.world.arena.locked = true
        s.world.active.update(id: id) { w in
            w.subtype = state
            body(&w)
        }
        return id
    }

    // MARK: - 1

    func testWarriorCratesFirstFrame() throws {
        let s = try session()
        let id = try warriorID(s)
        let before = try slot(s.world, id)
        XCTAssertEqual(slots(before), [nil, nil, nil])
        XCTAssertEqual(before.classWord16c, 0, "`+0x16c` starts 0")
        XCTAssertFalse(s.world.active.sprites.contains { $0.type == 0x433 })
        _ = s.step(keys: KeyState())
        let w1 = try slot(s.world, id)
        // The first Handle frame: `+0x16c` 0 − 1 < 1 → all three empty slots spawn, in slot order (M l. 73161–73182).
        let ids = slots(w1).compactMap { $0 }
        XCTAssertEqual(ids.count, 3)
        XCTAssertEqual(ids, ids.sorted(), "spawned in slot order")
        XCTAssertEqual(w1.classWord16c, -1, "decremented before the spawns")
        let crates = try ids.map { try slot(s.world, $0) }
        // (home 875 − 0xba / + 0x46 / + 0x146, y 227 − 400 / − 500 / − 400).
        XCTAssertEqual(crates.map { [$0.x, $0.y] }, [[689, -173], [945, -273], [1201, -173]])
        XCTAssertEqual(crates.map { [Int($0.x256), Int($0.y256)] },
                       [[689 << 8, -173 << 8], [945 << 8, -273 << 8], [1201 << 8, -173 << 8]])
        for c in crates {
            XCTAssertEqual(c.type, 0x433)
            XCTAssertEqual(c.handler, .box)
            XCTAssertEqual(c.layer, 2, "the Box Setup's layer (M l. 58939), not the argument 9")
            XCTAssertEqual(c.gravity, 0x100, "the rocks' arm (M l. 59055–59075)")
            XCTAssertEqual(c.hotRect, IdleSprites.Rect(top: 0, left: 4, bottom: 0x1c, right: 0x1c))
            XCTAssertEqual(c.face, f(0x42e, 0), "the boot single 0x42e (M l. 59054–59055)")
            XCTAssertEqual(c.classWord160, 0, "not hovering: `+0x160` ≥ 0")
            XCTAssertEqual(c.recordIndex, -1)
            XCTAssertEqual(c.vy, 0, "not handled on its spawn frame")
        }
        // In front of the Warrior in the list (layer 2 < 0xc): not reached by this frame's walk.
        let order = s.world.active.sprites.map(\.id)
        let wi = try XCTUnwrap(order.firstIndex(of: id))
        for c in ids { XCTAssertLessThan(try XCTUnwrap(order.firstIndex(of: c)), wi) }
        // The head's hot rect SetRect(0x2a, 0x3c, 0x89, 0x88), 10 px wider on the facing side (M l. 73144–73150).
        XCTAssertEqual(w1.hotRect, w1.mirrored ? IdleSprites.Rect(top: 0x3c, left: 0x2a, bottom: 0x88, right: 0x93)
                                               : IdleSprites.Rect(top: 0x3c, left: 0x20, bottom: 0x88, right: 0x89))
        _ = s.step(keys: KeyState())
        let w2 = try slot(s.world, id)
        XCTAssertEqual(slots(w2), slots(w1), "a falling crate keeps its slot")
        XCTAssertEqual(w2.classWord16c, 15, "all three present → `+0x16c = 15` (M l. 73186)")
        XCTAssertEqual(try ids.map { try slot(s.world, $0).vy }, [0x100, 0x100, 0x100], "each handled from frame 2")
        XCTAssertEqual(s.world.refusedSpawns, 0)

        // 2.11 items 1 and 2: `+0xe9` or `+0x1b2` → the Handle returns before `.StandardSpriteHandles` (M l.
        // 73137–73142): no crate, the invulnerability counter not stepped, the hot rect untouched.
        for (label, mark) in [("+0xe9", { (w: inout SpriteSlot) in w.dead = true }),
                              ("+0x1b2", { (w: inout SpriteSlot) in w.handleSkip = true })] {
            let t = try session()
            let tid = try warriorID(t)
            t.world.active.update(id: tid) { w in
                mark(&w)
                w.invulnerable = 5
            }
            let held = try slot(t.world, tid)
            handle(t.world, tid)
            XCTAssertEqual(try slot(t.world, tid), held, "\(label): nothing written")
            XCTAssertFalse(t.world.active.sprites.contains { $0.type == 0x433 }, "\(label): no crate")
        }
        // The hot rect for both facings (M l. 73144–73150): left − 10 facing left, right + 10 facing right.
        let hr = try session()
        let hid = try warriorID(hr)
        for m in [true, false] {
            hr.world.active.update(id: hid) { $0.mirrored = m }
            handle(hr.world, hid)
            XCTAssertEqual(try slot(hr.world, hid).hotRect,
                           m ? IdleSprites.Rect(top: 0x3c, left: 0x2a, bottom: 0x88, right: 0x93)
                             : IdleSprites.Rect(top: 0x3c, left: 0x20, bottom: 0x88, right: 0x89), "mirrored \(m)")
        }
    }

    // MARK: - 2

    func testWarriorCrateRespawnAfter14Or15() throws {
        // (a) A crate killed by its own landing (`.HitBoxTileSprite` → `.KillBox`, in its Handle — crates, layer 2,
        // precede him): his Handle the same frame k empties the slot (`+0x16c` 15 → 14); the new crate comes on k + 14.
        // On level 5 the crates come to rest on the BG ledges (kind 103, `.WallBounceBG`: no `.KillBox`) and keep their
        // slots; a test-only FG ledge (level 5's own kind-3 FG tile, in memory) across row 4 under the first crate
        // (columns 21…22, x 672…735) makes its landing an FG hit at speed.
        let s = try session()
        let id = try warriorID(s)
        let g = s.world.tiles
        let solid = try XCTUnwrap(g.fg.cells.first { $0 & 0xff != 0 && g.fgKind(tile: Int($0 & 0xff) - 1) == 3 })
        var cells = g.fg.cells
        for c in 21...22 { cells[4 * g.fg.width + c] = solid }
        s.world.tiles.fg = TileMap(width: g.fg.width, height: g.fg.height, cells: cells)
        var k = 0, gone: [Int] = [], held: [Int?] = []
        for frame in 1...200 {
            let before = try slot(s.world, id)
            _ = s.step(keys: KeyState())
            let w = try slot(s.world, id)
            gone = (0..<3).filter { slots(w)[$0] == nil }
            if frame > 1 && !gone.isEmpty { k = frame; held = slots(before); break }
        }
        XCTAssertGreaterThan(k, 2, "a crate landed")
        XCTAssertEqual(gone, [0], "the first crate, on the ledge")
        var w = try slot(s.world, id)
        XCTAssertEqual(w.classWord16c, 14, "emptied on the frame it died: 15 → 14")
        // The dead crate is still a record with `+0xe9` set — killed by its own Handle this frame, before his.
        XCTAssertNotEqual(try slot(s.world, try XCTUnwrap(held.first ?? nil)).killCount, 0)
        // The Warrior's current `+0xa` moved: the respawn reads it (M l. 73167, 73173, 73179). His `+0xc` moved too:
        // the respawn x is the home `+0x168` (875) + d, not his current x.
        s.world.active.update(id: id) { $0.y = 200; $0.x = 900 }
        for frame in (k + 1)...(k + 13) {
            _ = s.step(keys: KeyState())
            w = try slot(s.world, id)
            for i in gone { XCTAssertNil(slots(w)[i], "frame \(frame): not yet") }
            XCTAssertEqual(w.classWord16c, Int32(14 - (frame - k)))
        }
        let spawnedBefore = Set(s.world.active.sprites.filter { $0.type == 0x433 }.map(\.id))
        _ = s.step(keys: KeyState())
        w = try slot(s.world, id)
        let fresh = try gone.map { try XCTUnwrap(slots(w)[$0], "frame k + 14: slot \($0) refilled") }
        XCTAssertEqual(fresh, fresh.sorted(), "in slot order")
        for (i, c) in zip(gone, fresh) {
            XCTAssertFalse(spawnedBefore.contains(c))
            let t = try slot(s.world, c)
            let dx = [-0xba, 0x46, 0x146][i], dy = [-400, -500, -400][i]
            XCTAssertEqual([t.x, t.y], [875 + dx, 200 + dy], "slot \(i): home + d, the current +0xa − h")
        }
        XCTAssertEqual(w.classWord16c, 0, "the refill frame: 1 − 1 = 0")

        // (b) A crate killed in the collide pass (after every Handle of frame k — the crush's or the player arm's
        // `.KillBox`): his next Handle (k + 1) sees it first, so the new crate comes on k + 15.
        for vi in [1, 2] {
            let t = try session()
            let tid = try warriorID(t)
            for _ in 0..<3 { _ = t.step(keys: KeyState()) }
            let victim = try XCTUnwrap(slots(try slot(t.world, tid))[vi])
            let kb = 3
            BoxSprite.killBox(t.world, id: victim)                    // the collide pass of frame kb
            XCTAssertEqual(slots(try slot(t.world, tid))[vi], victim, "frame kb's Handle had already run")
            for frame in (kb + 1)...(kb + 14) {
                _ = t.step(keys: KeyState())
                let v = try slot(t.world, tid)
                if frame == kb + 1 { XCTAssertNil(slots(v)[vi]); XCTAssertEqual(v.classWord16c, 14) }
                if frame < kb + 15 { XCTAssertNil(slots(v)[vi], "frame \(frame)") }
            }
            _ = t.step(keys: KeyState())
            XCTAssertNotNil(slots(try slot(t.world, tid))[vi], "slot \(vi): frame kb + 15")
        }

        // (c) No free record (known deviation 6, Ruling 16 widened): the full table refuses the spawn, the slot stays
        // empty and re-tries every frame, `+0x16c` keeps counting below 1, each refusal counted.
        let u = try session()
        let uid = try warriorID(u)
        for _ in 0..<2 { _ = u.step(keys: KeyState()) }
        let lost = try XCTUnwrap(slots(try slot(u.world, uid))[0])
        BoxSprite.killBox(u.world, id: lost)
        var fillers: [Int] = []
        while u.world.active.sprites.count < SpriteWorld.recordCount {
            fillers.append(u.world.active.insert(SpriteSlot(type: 1, x: -5000, y: -5000, layer: 0)))
        }
        XCTAssertEqual(u.world.refusedSpawns, 0)
        u.world.active.update(id: uid) { $0.classWord16c = 1 }
        var counts: [Int32] = []
        for _ in 0..<3 {
            handle(u.world, uid)
            let v = try slot(u.world, uid)
            XCTAssertNil(slots(v)[0], "no record: the slot stays empty")
            counts.append(v.classWord16c)
        }
        XCTAssertEqual(counts, [0, -1, -2], "`+0x16c` counts on below 1")
        XCTAssertEqual(u.world.refusedSpawns, 3, "one refused spawn a frame")
        for f in fillers { _ = u.world.active.remove(id: f) }
        handle(u.world, uid)
        let v = try slot(u.world, uid)
        XCTAssertNotNil(slots(v)[0], "a free record: the slot refilled")
        XCTAssertEqual(v.classWord16c, -3)
        XCTAssertEqual(u.world.refusedSpawns, 3)
    }

    // MARK: - 3

    func testWarriorUnlockedReturnsBeforeGravity() throws {
        let s = try session()
        let id = try warriorID(s)
        XCTAssertFalse(s.world.arena.locked)
        s.world.active.update(id: id) { w in
            w.counterA6 = 3
            w.vx = 1000
            w.vy = 0
            w.hp = 0
            w.face = nil
        }
        let start = try slot(s.world, id)
        var a6: [Int16] = []
        for _ in 0..<5 {
            let seed = s.world.rng.seed
            handle(s.world, id)
            let w = try slot(s.world, id)
            a6.append(w.counterA6)
            XCTAssertEqual(s.world.rng.seed, seed, "no R(100): the decide is not reached")
            XCTAssertEqual([w.x, w.y], [start.x, start.y], "no gravity, no motion")
            XCTAssertEqual([w.vx, w.vy], [1000, 0], "no vx × 0.5, no gravity")
            XCTAssertEqual(w.face, f(Warrior.walkSet, 0), "state 6's face, every frame (M l. 73334)")
            XCTAssertEqual(w.subtype, 6, "no death entry at HP 0 while the arena is open")
            XCTAssertEqual(w.centre, start.centre, "no `.StandardSpriteCleanup`")
        }
        XCTAssertEqual(a6, [2, 1, 0, 0, 0], "`+0xa6` counts to 0 and stays")
        XCTAssertTrue(s.world.player.cues.allSatisfy { $0.snd != 703 }, "no snd 703")

        // 2.11 item 21: locked, every state reaches `.ApplyGravityAndSeparateFromTiles` with gravity 0x122 — here
        // states 0, 1, 3, 5 and 8 (no arm: state, `+0x46` and vx untouched) in the air: one frame adds 0x122 to vy;
        // then `.StandardSpriteCleanup` clears `+0xd6` (M l. 32660) and re-centres.
        for st: Int16 in [0, 1, 3, 5, 8] {
            let t = try session()
            let tid = try locked(t, state: st) { w in w.vy = 0; w.vx = 0; w.phase = 3; w.slope = 5 }
            let up = try slot(t.world, tid)
            handle(t.world, tid)
            let down = try slot(t.world, tid)
            XCTAssertEqual(down.vy, 0x122, "gravity 0x122 (M l. 73399)")
            XCTAssertGreaterThan(down.y256, up.y256)
            XCTAssertEqual([down.subtype, down.phase], [st, 3], "state \(st): no arm")
            XCTAssertEqual(down.vx, 0)
            XCTAssertEqual(down.slope, 0, "Cleanup clears `+0xd6`")
            let hr = down.hotRect
            let centre = SpriteSlot.Point(x: down.x + hr.left + ((hr.right - hr.left) >> 1),
                                          y: down.y + hr.top + ((hr.bottom - hr.top) >> 1))
            XCTAssertEqual(down.centre, centre, "Cleanup ran")
        }
    }

    // MARK: - 4

    func testWarriorDecideDraws() throws {
        // The decide (M l. 73341–73387): r = R(100); T = 0x41 (and face the player) when |playerCY − cy| < 0x50, else
        // 0x13; r > T → state 7, `+0x46 = 1`, face 0x71c[0], `+0xa6 = R(3) + 2`; R(100) > 100 − T → run, else walk and
        // R(100) > 0x50 → `.WarriorLayEgg` (R(2)); then the bound facing. Then vx × 0.5.
        struct Case { let label: String; let near: Bool; let pick: (inout FastRand) -> Bool }
        func walkPick(near: Bool, run: Bool, egg: Bool, edge: Bool = false) -> (inout FastRand) -> Bool {
            let t: Int16 = near ? 0x41 : 0x13
            return { g in
                let r0 = g.next(100)
                guard t < r0, !edge || r0 == t + 1 else { return false }
                _ = g.next(3)
                let rr = g.next(100)
                if run { return 100 - t < rr && (!edge || rr == 101 - t) }
                guard rr <= 100 - t, !edge || rr == 100 - t else { return false }
                let e = g.next(100)
                return egg == (0x50 < e) && (!edge || e == (egg ? 0x51 : 0x50))
            }
        }
        let cases = [Case(label: "near run", near: true, pick: walkPick(near: true, run: true, egg: false)),
                     Case(label: "near walk", near: true, pick: walkPick(near: true, run: false, egg: false)),
                     Case(label: "near walk + egg", near: true, pick: walkPick(near: true, run: false, egg: true)),
                     Case(label: "far run", near: false, pick: walkPick(near: false, run: true, egg: false)),
                     Case(label: "far walk", near: false, pick: walkPick(near: false, run: false, egg: false)),
                     Case(label: "far walk + egg", near: false, pick: walkPick(near: false, run: false, egg: true)),
                     // The edges: r = T + 1 walks; R(100) 101 − T runs, 100 − T walks; egg draw 0x51 lays, 0x50 not.
                     Case(label: "near run edge", near: true,
                          pick: walkPick(near: true, run: true, egg: false, edge: true)),
                     Case(label: "far walk edge", near: false,
                          pick: walkPick(near: false, run: false, egg: false, edge: true)),
                     Case(label: "far egg edge", near: false,
                          pick: walkPick(near: false, run: false, egg: true, edge: true))]
        for c in cases {
            let k = seed(c.pick)
            let s = try session()
            let id = try locked(s, state: 6) { w in
                w.counterA6 = 0
                w.classTimer = 7
                w.vx = 0x301
                w.mirrored = false
                w.x = 875
                w.centre = SpriteSlot.Point(x: 960, y: 300)
            }
            s.world.player.centreX = 1100                         // right of him: "face the player" = facing right
            s.world.player.centreY = c.near ? 300 + 0x4f : 300 + 0x50
            s.world.rng = FastRand(seed: k)
            var e = FastRand(seed: k)
            let t: Int16 = c.near ? 0x41 : 0x13
            let r = e.next(100)
            let a6 = e.next(3) + 2
            let rr = e.next(100)
            let run = 100 - t < rr
            var timer: Int32 = run ? 1 : 0, egg = false, eggTimer: Int32 = 0
            if !run && 0x50 < e.next(100) {
                egg = true
                eggTimer = Int32(e.next(2)) + 1
                timer = eggTimer
            }
            XCTAssertGreaterThan(r, t, c.label)
            handle(s.world, id)
            let w = try slot(s.world, id)
            XCTAssertEqual(s.world.rng.seed, e.seed, "\(c.label): exactly the decide's draws")
            XCTAssertEqual(w.subtype, 7, c.label)
            XCTAssertEqual(w.phase, 1, c.label)
            XCTAssertEqual(w.face, f(Warrior.walkSet, 0), c.label)
            XCTAssertEqual(w.counterA6, egg ? 5 : a6, "\(c.label): R(3) + 2, or the egg's 5")
            XCTAssertEqual(w.classTimer, timer, "\(c.label): run iff R(100) > 100 − T (35 near, 81 far); egg R(2) + 1")
            XCTAssertEqual(w.classWord154, egg ? 2 : 0, "\(c.label): the egg's `+0x154 = 2` (M l. 73087)")
            if egg { XCTAssertGreaterThan(eggTimer, 0, "the egg turns the walk into a run") }
            XCTAssertEqual(w.mirrored, c.near, "\(c.label): faces the player only when near (x inside the bounds)")
            XCTAssertEqual(w.vx, 0x180, "\(c.label): vx × 0.5 truncated after the decide (M l. 73389)")
        }
        // The bound facing after the choice (M l. 73377–73382): x > `+0x160` → left; x < `+0x15c` → right — over the
        // near "face the player".
        for (x, want) in [(1226, false), (524, true), (1225, true), (525, false)] {
            let k = seed(walkPick(near: true, run: false, egg: false))
            let s = try session()
            let id = try locked(s, state: 6) { w in
                w.counterA6 = 0
                w.x = x
                w.mirrored = !want
                w.centre = SpriteSlot.Point(x: 960, y: 300)
            }
            // Outside the bounds the player stands on the other side (the bound overrides the near facing); inside,
            // the player's side decides.
            let outside = x == 1226 || x == 524
            s.world.player.centreX = outside == want ? 800 : 1100
            s.world.player.centreY = 300
            s.world.rng = FastRand(seed: k)
            handle(s.world, id)
            XCTAssertEqual(try slot(s.world, id).mirrored, want, "x \(x)")
        }
        // The game-over flag (`*_DAT_1009ffa8`) → T = −1: any r walks or runs — even r 0 (M l. 73357–73359).
        let k0 = seed { g in g.next(100) == 0 }
        let s = try session()
        let id = try locked(s, state: 6) { w in
            w.counterA6 = 0
            w.centre = SpriteSlot.Point(x: 960, y: 300)
        }
        s.world.player.centreY = 300
        s.world.playerDead = true
        s.world.rng = FastRand(seed: k0)
        handle(s.world, id)
        XCTAssertEqual(try slot(s.world, id).subtype, 7, "r 0 > −1")
        // Without the flag r 0 attacks.
        let a = try session()
        let aid = try locked(a, state: 6) { w in
            w.counterA6 = 0
            w.centre = SpriteSlot.Point(x: 960, y: 300)
        }
        a.world.player.centreY = 300
        a.world.rng = FastRand(seed: k0)
        handle(a.world, aid)
        XCTAssertEqual(try slot(a.world, aid).subtype, 2)
        // Near, equal centres: "face the player" (playerCX > cx, the signed-compare idiom, M l. 73350–73352) is left.
        let q = try session()
        let qid = try locked(q, state: 6) { w in
            w.counterA6 = 0
            w.mirrored = true
            w.centre = SpriteSlot.Point(x: 960, y: 300)
        }
        q.world.player.centreX = 960
        q.world.player.centreY = 300
        handle(q.world, qid)
        XCTAssertFalse(try slot(q.world, qid).mirrored, "equal centres: facing left")
        // A decide not yet due (`+0xa6` 2 → 1): no draw, vx still halved; locked, state 6 still writes face 0x71c[0]
        // (2.11 item 5, M l. 73334).
        let n = try session()
        let nid = try locked(n, state: 6) { w in
            w.counterA6 = 2
            w.vx = -0x301
            w.face = nil
        }
        let seed0 = n.world.rng.seed
        handle(n.world, nid)
        XCTAssertEqual(n.world.rng.seed, seed0)
        XCTAssertEqual(try slot(n.world, nid).face, f(Warrior.walkSet, 0), "locked, no decide: the head's face")
        XCTAssertEqual([try slot(n.world, nid).counterA6], [1])
        XCTAssertEqual(try slot(n.world, nid).vx, -0x180, "(int)(−769 · 0.5) toward zero")
    }

    // MARK: - 5

    func testWarriorAttackDiscardsR100() throws {
        // r ≤ T → `.RandomWarriorAttack` (M l. 73095–73112): R(100) discarded (raw 10087b7c..10087b84), state 2,
        // `+0x46 = 0`, `+0x154 = 0`, `+0xa6 = 0x10`, `+0x14c = R(2) + 1`.
        for near in [true, false] {
            let t: Int16 = near ? 0x41 : 0x13
            // r = T exactly (the edge: r ≤ T attacks), and a seed whose discarded draw and swing draw differ in what
            // they would give, so a skipped discard shows.
            let k = seed { g in
                guard g.next(100) == t else { return false }
                let d = g.next(100)
                return (d & 1) != g.next(2)
            }
            let s = try session()
            let id = try locked(s, state: 6) { w in
                w.counterA6 = 0
                w.classWord154 = 3
                w.phase = 5
                w.vx = 0x200
                w.mirrored = true
                w.centre = SpriteSlot.Point(x: 960, y: 300)
            }
            s.world.player.centreX = 800
            s.world.player.centreY = near ? 300 : 500
            s.world.rng = FastRand(seed: k)
            var e = FastRand(seed: k)
            _ = e.next(100)
            _ = e.next(100)
            let swings = Int32(e.next(2)) + 1
            handle(s.world, id)
            let w = try slot(s.world, id)
            XCTAssertEqual(s.world.rng.seed, e.seed, "R(100), R(100) discarded, R(2)")
            XCTAssertEqual(w.subtype, 2)
            XCTAssertEqual(w.phase, 0)
            XCTAssertEqual(w.classWord154, 0)
            XCTAssertEqual(w.counterA6, 0x10)
            XCTAssertEqual(w.classTimer, swings, "the third draw, not the second")
            XCTAssertEqual(w.mirrored, !near, near ? "near: faced the player (left)" : "far: facing kept")
            XCTAssertEqual(w.vx, 0x100, "the decide frame's vx × 0.5")
        }
    }

    // MARK: - 6

    func testWarriorSwingTimingAndShot() throws {
        for right in [true, false] {
            let s = try session()
            let id = try locked(s, state: 2) { w in
                w.phase = 0
                w.classTimer = 2
                w.mirrored = !right                               // facing away: n 0 turns him to the player
                w.vx = 0x300
                w.centre = SpriteSlot.Point(x: 960, y: 300)
            }
            s.world.player.centreX = right ? 2000 : 0
            var phases: [Int16] = [], frames = 0, shotID: Int?
            _ = s.world.player.drainFrameOutputs()
            while try slot(s.world, id).subtype == 2 && frames < 60 {
                // A live vx entering n 9, so the record written back before the shot's spawn shows (`SpriteWorld`
                // rule 2): a stale re-read would bring back the un-dragged vx.
                if try slot(s.world, id).phase == 9 { s.world.active.update(id: id) { $0.vx = 0x300 } }
                let w0 = try slot(s.world, id)
                let n = w0.phase
                let seedBefore = s.world.rng.seed
                var e = FastRand(seed: seedBefore)
                let before = Set(s.world.active.sprites.map(\.id))
                handle(s.world, id)
                frames += 1
                phases.append(n)
                let w = try slot(s.world, id)
                let cues = s.world.player.drainFrameOutputs().cues
                XCTAssertEqual(w.vx, TileSolver.fctiwz(Double(w0.vx) * 0.4), "n \(n): vx × 0.4 (M l. 73223)")
                if n < 2 {
                    XCTAssertEqual(w.face, f(Warrior.walkSet, 0), "n \(n)")
                    XCTAssertEqual(w.mirrored, right, "n \(n): faces the player")
                } else {
                    XCTAssertEqual(w.face, f(Warrior.attackSet, Int(n >> 1) - 1), "n \(n): word (n >> 1) of 0x71d")
                }
                if n == 7 {
                    let r = Int32(e.next(6000))
                    XCTAssertEqual(cues, [PlayerCue(call: .threeDPitched, snd: 704, priority: 1, volume: 0x100,
                                                    position: w0.centre, rate: r + 50000)])
                } else {
                    XCTAssertTrue(cues.allSatisfy { $0.snd != 704 }, "n \(n)")
                }
                let made = s.world.active.sprites.map(\.id).filter { !before.contains($0) && $0 != id }
                    .filter { s.world.active.sprite(id: $0)?.type == EnemyShot.warriorShot }
                if n == 9 {
                    XCTAssertEqual(made.count, 1, "the shot on n = 9")
                    shotID = made.first
                    _ = e.next(5)                                  // its Setup's R(5) (M l. 51460)
                    let shot = try slot(s.world, try XCTUnwrap(shotID))
                    let cx = w0.centre.x, cy = w0.centre.y
                    XCTAssertEqual([shot.x, shot.y], [cx + (right ? 0x30 : -0x30) - 0x18, cy - 0x25])
                    XCTAssertEqual(shot.layer, 0, "the argument, kept by the EnemyShot Setup")
                    XCTAssertEqual(shot.vx, right ? 0xb00 : -0xb00)
                    XCTAssertEqual(shot.handler, .enemyShot)
                    XCTAssertEqual(s.world.rng.seed, e.seed, "n 9: the shot Setup's R(5) only")
                } else {
                    XCTAssertTrue(made.isEmpty, "n \(n)")
                }
                if n == 0x11 && w.subtype == 6 {
                    let a6 = e.next(9) + 4
                    XCTAssertEqual(w.counterA6, a6, "the reload R(9) + 4 (M l. 73259)")
                    XCTAssertEqual(s.world.rng.seed, e.seed)
                } else if n != 7 && n != 9 {
                    XCTAssertEqual(s.world.rng.seed, seedBefore, "n \(n): no draw")
                } else if n == 7 {
                    XCTAssertEqual(s.world.rng.seed, e.seed)
                }
            }
            // First swing n 0…17 (18 frames, the shot at the 10th), the second n 1…17 (17 frames).
            XCTAssertEqual(phases, Array(0...17) + Array(1...17), "right \(right)")
            XCTAssertEqual(frames, 35)
            XCTAssertEqual(try slot(s.world, id).subtype, 6)
            XCTAssertNotNil(shotID)
        }
        // Frame order: the shot (layer 0) goes in front of the Warrior (0xc) and is first handled the next frame.
        let s = try session()
        let id = try locked(s, state: 2) { w in
            w.phase = 9
            w.classTimer = 1
            w.mirrored = true
        }
        _ = s.step(keys: KeyState())
        let shot = try XCTUnwrap(s.world.active.sprites.first { $0.type == EnemyShot.warriorShot })
        XCTAssertNil(shot.face, "not handled on its spawn frame (its Handle sets the face)")
        let order = s.world.active.sprites.map(\.id)
        XCTAssertLessThan(try XCTUnwrap(order.firstIndex(of: shot.id)), try XCTUnwrap(order.firstIndex(of: id)))
        _ = s.step(keys: KeyState())
        XCTAssertEqual(try slot(s.world, shot.id).face, f(EnemyShot.warriorShot, 1), "handled from the next frame")
    }

    // MARK: - 7

    func testWarriorWalkRunCycles() throws {
        for run in [false, true] {
            for right in [false, true] {
                let s = try session()
                let id = try locked(s, state: 7) { w in
                    w.classTimer = run ? 1 : 0
                    w.phase = 1
                    w.counterA6 = 1
                    w.mirrored = right
                    w.x = 875
                    w.x256 = 875 << 8
                }
                var frames = 0
                let cycle = run ? 7 : 15
                while try slot(s.world, id).subtype == 7 && frames < 40 {
                    let n = try slot(s.world, id).phase
                    let seedBefore = s.world.rng.seed
                    var e = FastRand(seed: seedBefore)
                    handle(s.world, id)
                    frames += 1
                    let w = try slot(s.world, id)
                    let v: Int32 = run ? 0xc00 : 0x600
                    XCTAssertEqual(w.vx, right ? v : -v, "run \(run) n \(n)")
                    XCTAssertEqual(w.face, f(Warrior.walkSet, run ? Int(n) : Int(n >> 1)),
                                   "run \(run) n \(n): face 0x71c[n] / [n >> 1] (M l. 73286, 73310)")
                    if frames == cycle {
                        XCTAssertEqual(w.subtype, 6)
                        XCTAssertEqual(w.counterA6, e.next(9) + 4, "the reload R(9) + 4 (M l. 73296, 73320)")
                        XCTAssertEqual(s.world.rng.seed, e.seed)
                        XCTAssertEqual(w.phase, 1, "n = 0, then + 1")
                    } else {
                        XCTAssertEqual(s.world.rng.seed, seedBefore)
                        XCTAssertEqual(w.phase, n + 1)
                    }
                }
                XCTAssertEqual(frames, cycle, "run \(run): the cycle")
            }
        }
        // Two cycles with `+0xa6` 2; and the patrol bound forces `+0xa6 = 0` at the cycle's end (M l. 73290–73293).
        let s = try session()
        let id = try locked(s, state: 7) { w in
            w.classTimer = 1
            w.phase = 1
            w.counterA6 = 2
            w.mirrored = true
        }
        var frames = 0
        while try slot(s.world, id).subtype == 7 && frames < 40 { handle(s.world, id); frames += 1 }
        XCTAssertEqual(frames, 14, "two run cycles")
        for (x, left) in [(1300, true), (450, false)] {
            let t = try session()
            let tid = try locked(t, state: 7) { w in
                w.classTimer = 1
                w.phase = 7
                w.counterA6 = 9
                w.mirrored = !left
                w.x = x
                w.x256 = Int32(x) << 8
            }
            var e = FastRand(seed: t.world.rng.seed)
            handle(t.world, tid)
            let w = try slot(t.world, tid)
            XCTAssertEqual(w.subtype, 6, "x \(x): outside [525, 1225] ends the walk")
            XCTAssertEqual(w.counterA6, e.next(9) + 4)
        }
        // Inside the bounds — the bounds themselves included (strict compares, M l. 73290–73291 walk, 73314–73315
        // run) — the same cycle end only counts down.
        for x in [875, 1225, 525] {
            let i = try session()
            let iid = try locked(i, state: 7) { w in
                w.classTimer = 1
                w.phase = 7
                w.counterA6 = 9
                w.x = x
                w.x256 = Int32(x) << 8
            }
            handle(i.world, iid)
            XCTAssertEqual([try slot(i.world, iid).subtype, try slot(i.world, iid).counterA6], [7, 8], "x \(x)")
        }
    }

    // MARK: - 8

    func testWarriorDeathAndGlow() throws {
        // HP < 1 with state ≠ 4 → state 4, `+0x46 = +0xa6 = 0`, snd 703 (3D, 1, 0x100) at his centre as the Handle
        // found it, before Cleanup re-centres (M l. 73393–73398). HP 1 is alive.
        let h1 = try session()
        let h1id = try locked(h1, state: 7) { w in w.hp = 1; w.classTimer = 0; w.phase = 3 }
        handle(h1.world, h1id)
        XCTAssertEqual(try slot(h1.world, h1id).subtype, 7, "HP 1: alive")
        let s = try session()
        let id = try locked(s, state: 7) { w in
            w.hp = 0
            w.classTimer = 0
            w.phase = 3
            w.vx = 1000
            w.centre = SpriteSlot.Point(x: 960, y: 300)
        }
        _ = s.world.player.drainFrameOutputs()
        handle(s.world, id)
        var w = try slot(s.world, id)
        XCTAssertEqual([w.subtype, w.phase, w.counterA6], [4, 0, 0])
        let cue = try XCTUnwrap(s.world.player.drainFrameOutputs().cues.first { $0.snd == 703 })
        XCTAssertEqual([cue.call == .threeD, cue.priority == 1, cue.volume == 0x100], [true, true, true])
        XCTAssertEqual(cue.position, SpriteSlot.Point(x: 960, y: 300), "the centre before Cleanup")
        // Dying (M l. 73268–73279): vx × 0.9, face 0x71e[n >> 2] (n capped at 0x17 → index ≤ 5), `+0xa6` + 1; at 0x2d
        // `+0x1a2 = 1` — dying frame 45.
        s.world.active.update(id: id) { $0.vx = 1000 }
        for frame in 1...45 {
            handle(s.world, id)
            w = try slot(s.world, id)
            XCTAssertEqual(w.face, f(Warrior.deathSet, min(frame - 1, 0x17) >> 2), "dying frame \(frame)")
            XCTAssertEqual(w.phase, Int16(min(frame, 0x17)))
            XCTAssertEqual(w.counterA6, Int16(frame))
            if frame == 1 { XCTAssertEqual(w.vx, 900, "vx × 0.9") }
            if frame < 45 { XCTAssertEqual(w.burnRow, 0, "dying frame \(frame)") }
        }
        XCTAssertNotEqual(w.burnRow, 0, "the burn starts on dying frame 45")
        XCTAssertEqual(w.subtype, 4, "no second death entry")

        // The wounded glow, boss mode only, whatever the lock (M l. 73188–73212): `+0xf0` − 1; 4…6 → 0x10009 and 1…3 →
        // 0x10008 below 1001 HP; ≤ 0 → reload 15 (below 501) or 30, `+0xb8 = 0`.
        let g = try session()
        let gid = try warriorID(g)
        XCTAssertFalse(g.world.arena.locked)
        g.world.active.update(id: gid) { w in
            w.hp = 1000
            w.voicePitch = 8
            w.mode = 0x77
        }
        var modes: [UInt32] = [], timers: [Int32] = []
        for _ in 0..<9 {
            handle(g.world, gid)
            let w = try slot(g.world, gid)
            modes.append(w.mode)
            timers.append(w.voicePitch)
        }
        XCTAssertEqual(timers, [7, 6, 5, 4, 3, 2, 1, 0x1e, 0x1d])
        XCTAssertEqual(modes, [0x77, 0x10009, 0x10009, 0x10009, 0x10008, 0x10008, 0x10008, 0, 0])
        for (hp, period) in [(Int16(500), Int32(0xf)), (Int16(501), Int32(0x1e))] {
            g.world.active.update(id: gid) { w in w.hp = hp; w.voicePitch = 1; w.mode = 0x77 }
            handle(g.world, gid)
            XCTAssertEqual([try slot(g.world, gid).voicePitch], [period], "HP \(hp)")
            XCTAssertEqual(try slot(g.world, gid).mode, 0)
        }
        // The band edges: v 1 (from 2) tints at 1000 HP; v 2 (from 3) at 1001 HP leaves `+0xb8`.
        g.world.active.update(id: gid) { w in w.hp = 1000; w.voicePitch = 2; w.mode = 0x77 }
        handle(g.world, gid)
        XCTAssertEqual(try slot(g.world, gid).mode, 0x10008, "v 1 tints")
        g.world.active.update(id: gid) { w in w.hp = 1001; w.voicePitch = 3; w.mode = 0x77 }
        handle(g.world, gid)
        XCTAssertEqual(try slot(g.world, gid).mode, 0x77, "band 1 above 1000 HP")
        // Above 1000 HP no tint is written, but the reload still clears `+0xb8`.
        g.world.active.update(id: gid) { w in w.hp = 1001; w.voicePitch = 6; w.mode = 0x77 }
        handle(g.world, gid)
        XCTAssertEqual(try slot(g.world, gid).mode, 0x77)
        g.world.active.update(id: gid) { w in w.voicePitch = 1 }
        handle(g.world, gid)
        XCTAssertEqual(try slot(g.world, gid).mode, 0)

        // 2.11 item 3: p4 = 0 (`+0x170 == 0`): no crate, `+0x16c` untouched, no glow (M l. 73151).
        let p = try session()
        let pid = try warriorID(p)
        p.world.active.update(id: pid) { w in
            w.classWord170 = 0
            w.hp = 100
            w.voicePitch = 3
            w.classWord16c = 7
            w.mode = 0x77
        }
        for _ in 0..<3 { handle(p.world, pid) }
        let q = try slot(p.world, pid)
        XCTAssertEqual([q.voicePitch, q.classWord16c], [3, 7])
        XCTAssertEqual(q.mode, 0x77)
        XCTAssertFalse(p.world.active.sprites.contains { $0.type == 0x433 })
    }

    // MARK: - 9

    func testWarriorTileCallbackIsCrawlerBody() throws {
        // `.HitWarriorTileSprite` (M l. 73498–73530) is the Crawler's body (`CrawlerRoach.hitTile`): the same writes for
        // every layer and kind band — FG any kind and BG < 100 `.WallBounce`, BG 100…199 `.WallBounceBG(kind − 100)`,
        // ≥ 200 water `.HandleUnderWater` unless `+0x140`.
        let cases: [(kind: Int, layer: TileLayer, done: Bool)] = [
            (3, .foreground, false), (150, .foreground, false), (3, .background, false), (99, .background, false),
            (100, .background, false), (0x7f, .background, false), (199, .background, false),
            (200, .background, false), (202, .background, false), (200, .background, true),
        ]
        var changed = 0
        for c in cases {
            let a = try session(), b = try session()
            var ids: [Int] = []
            for t in [a, b] {
                let id = try warriorID(t)
                t.world.active.update(id: id) { w in
                    w.x = 640; w.y = 280; w.x256 = 640 << 8; w.y256 = 280 << 8
                    w.vx = 0x300; w.vy = 0x500
                    w.underwaterDone = c.done
                }
                ids.append(id)
            }
            let before = try slot(a.world, ids[0])
            let pass = try XCTUnwrap(Warrior.pass(before), "the Setup stored `+0x1f8`")
            pass(TileSolver(world: a.world), ids[0], TilePos(x: 672, y: 320), c.kind, c.layer)
            CrawlerRoach.hitTile(TileSolver(world: b.world), id: ids[1], pos: TilePos(x: 672, y: 320), kind: c.kind,
                                 layer: c.layer)
            let wa = try slot(a.world, ids[0]), wb = try slot(b.world, ids[1])
            XCTAssertEqual(wa, wb, "kind \(c.kind) \(c.layer) done \(c.done)")
            if wa != before { changed += 1 }
            if c.done && c.kind >= 200 { XCTAssertEqual(wa, before, "`+0x140` set: no `.HandleUnderWater`") }
            // One band's own writes, not only the sameness: water (200…209) with `+0x140` clear runs
            // `.HandleUnderWater`, which ends `+0x140 = 1` with `+0x11c` at least 1 (M l. 38178–38179, 38218).
            if !c.done && c.kind >= 200 {
                XCTAssertEqual([wa.underwaterDone, wa.waterRow >= 1], [true, true], "kind \(c.kind): in the water")
            }
        }
        XCTAssertGreaterThan(changed, 4, "the bands write")
        let z = try session()
        var none = try slot(z.world, try warriorID(z))
        none.hasTileHit = false
        XCTAssertNil(Warrior.pass(none), "`+0x1f8` 0 → no callback")
        // The Handle installs it: locked, he falls onto the arena floor and stays there (vy 0 once landed).
        let s = try session()
        let id = try locked(s, state: 0)
        var ys: [Int] = []
        for _ in 0..<120 { handle(s.world, id); ys.append(try slot(s.world, id).y) }
        XCTAssertEqual(Array(Set(ys.suffix(20))).count, 1, "landed")
        XCTAssertEqual(try slot(s.world, id).groundKind != 0, true, "on ground")
    }

    // MARK: - 6A-W2: the Hit, the Kill, the three pieces (BOS §2.4–§2.6, §2.9's 6A-W2 list, §2.11 items 22–28)

    /// A sprite of `type` / `handler` with a 20×20 hot rect centred on the Warrior's stored centre moved by `dx` (a
    /// player shot by default; `+0xa6` 0).
    private func other(_ w: SpriteWorld, over id: Int, dx: Int = 0, type: Int16 = 2,
                       handler: SpriteHandler = .playerShot,
                       body: (inout SpriteSlot) -> Void = { _ in }) throws -> Int {
        let t = try slot(w, id)
        let c = SpriteSlot.Point(x: t.centre.x + dx, y: t.centre.y)
        return try XCTUnwrap(w.newSprite(type: type, x: c.x - 10, y: c.y - 10, layer: 0xb, handler: handler) { s in
            s.x = c.x - 10
            s.y = c.y - 10
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
            s.centre = c
            s.hp = 150
            s.vx = 1000
            body(&s)
        })
    }

    private func effects(_ w: SpriteWorld) -> Int { w.active.sprites.filter { $0.handler == .effect }.count }

    /// The Warrior with a known centre (a Cleanup's), its HP 2000 as the Setup left it.
    private func standing(_ s: FerazelSession) throws -> Int {
        let id = try warriorID(s)
        s.world.active.update(id: id) { $0.centre = SpriteSlot.Point(x: 950, y: 270) }
        return id
    }

    // MARK: - 10

    func testWarriorAbsorbsShots() throws {
        // `.HitWarriorSprite` (M l. 73433–73439): a player shot (`+0x4c` = 0x100a04e8) with `+0xa6 == 0` while HP > 0
        // → `.KillPlayerShot(shot, 0, 1)` — no hit sound, the effect — then `.STPlay3DSound(303, 1, 0x100, shot +0xe)`,
        // the shot's centre read after the kill. Immune: HP, invulnerability and state untouched, in every state.
        for (type, state) in [(Int16(0), Int16(6)), (2, 7), (3, 2), (4, 6)] {
            let tag = "type \(type) state \(state)"
            let s = try session()
            let id = try standing(s)
            s.world.active.update(id: id) { $0.subtype = state }
            let sid = try other(s.world, over: id, dx: -3, type: type)
            let before = try slot(s.world, id)
            // The twin: the same kill by hand — the stream after it is the Hit's (no `sound` R(10000): flag 0).
            let twin = try session()
            let tid = try standing(twin)
            twin.world.active.update(id: tid) { $0.subtype = state }
            let tsid = try other(twin.world, over: tid, dx: -3, type: type)
            var lights = LightTable()
            PlayerShotHits.kill(twin.world, shot: tsid, sound: false, effect: true, effects: 1, lights: &lights)
            let fx0 = effects(s.world)
            s.world.player.cues = []
            FerazelSession.hitCallback(s.world, id, sid)
            let after = try slot(s.world, id)
            let shot = try slot(s.world, sid)
            XCTAssertTrue(shot.dead, "\(tag): the shot is killed")
            XCTAssertGreaterThan(effects(s.world), fx0, "\(tag): effect 1 — the impact sprite made")
            XCTAssertEqual(effects(s.world), effects(twin.world), tag)
            XCTAssertEqual(s.world.rng.seed, twin.world.rng.seed, "\(tag): sound 0 — no R(10000)")
            XCTAssertEqual(s.world.player.cues, [PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0x100,
                                                           position: shot.centre)], tag)
            XCTAssertEqual([after.hp, after.invulnerable, after.subtype, after.flash],
                           [before.hp, before.invulnerable, before.subtype, before.flash], "\(tag): immune")
            XCTAssertEqual([after.vx, after.vy], [before.vx, before.vy], tag)
        }
        // 2.11 item 22: a shot whose `+0xa6 ≠ 0`, or the Warrior at HP ≤ 0 (dying): the shot passes through — not
        // killed, no snd 303, nothing drawn (M l. 73436–73437).
        for (a6, hp) in [(Int16(1), Int16(2000)), (-6, 2000), (0, 0), (0, -50)] {
            let s = try session()
            let id = try standing(s)
            s.world.active.update(id: id) { $0.hp = hp }
            let sid = try other(s.world, over: id) { $0.counterA6 = a6 }
            let seed0 = s.world.rng.seed
            s.world.player.cues = []
            FerazelSession.hitCallback(s.world, id, sid)
            XCTAssertFalse(try slot(s.world, sid).dead, "a6 \(a6) HP \(hp): passes through")
            XCTAssertEqual(s.world.player.cues, [], "a6 \(a6) HP \(hp)")
            XCTAssertEqual(s.world.rng.seed, seed0)
            XCTAssertEqual(try slot(s.world, id).hp, hp)
        }
        // The Ring of Smiting (`Smite.enemyHandlers[0]` = the Warrior's Handle 0x100a0494): the seed spawned at his
        // stored centre − 4 is absorbed like any shot — the seed's own kill (snd 435, flash 3, shake 0x14, the big
        // explosion), then snd 303 last; HP unchanged.
        let s = try session()
        let id = try standing(s)
        let shots0 = Set(s.world.active.sprites.filter { $0.handler == .playerShot }.map(\.id))
        Smite.smiteEnemies(s.world)
        let seedID = try XCTUnwrap(s.world.active.sprites.first { sp in
            sp.handler == .playerShot && !shots0.contains(sp.id) && sp.type == PlayerShot.seed
                && sp.x == 950 - 4 && sp.y == 270 - 4
        }?.id, "a seed at his stored centre − 4")
        s.world.player.cues = []
        FerazelSession.hitCallback(s.world, id, seedID)
        let seed = try slot(s.world, seedID)
        XCTAssertTrue(seed.dead)
        XCTAssertEqual(s.world.player.cues.first?.snd, 435, "the seed's own kill first")
        XCTAssertEqual(s.world.player.cues.last, PlayerCue(call: .threeD, snd: 303, priority: 1, volume: 0x100,
                                                           position: seed.centre))
        XCTAssertEqual(s.world.flash.count, 3)
        XCTAssertEqual(try slot(s.world, id).hp, 2000)
        // No environmental-hazard arm (BOS §1.1): the seed's big explosion 0x4b7 touching him does nothing.
        let big = try XCTUnwrap(s.world.active.sprites.first { $0.handler == .effect && $0.type == EffectSprite.bigExplosion })
        XCTAssertLessThan(big.phase, 8)
        let seed1 = s.world.rng.seed
        s.world.player.cues = []
        FerazelSession.hitCallback(s.world, id, big.id)
        XCTAssertEqual([try slot(s.world, id).hp], [2000])
        XCTAssertEqual(s.world.player.cues, [])
        XCTAssertEqual(s.world.rng.seed, seed1)
        // The session's own collide pass (`FerazelSession.step` → `.MTCollideSprites` → its `.warrior` row) hands the
        // session's face bounds to the Hit and through it to `.KillPlayerShot`'s clip test: with the shell's bounds the
        // kill spawns its impact at (x − 8, y − 0xc); with bounds ending at the clip's left edge (0), no impact.
        for custom in [false, true] {
            let tag = custom ? "bounds left of the clip" : "the session's bounds"
            let left: (FaceRef) -> IdleSprites.Rect = { _ in IdleSprites.Rect(top: 0, left: -0x10, bottom: 1, right: 0) }
            let fs = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 5, seed: 1,
                                        faceBounds: custom ? left : nil, start: (800, 250))
            let fid = try warriorID(fs)
            _ = fs.step(keys: KeyState())
            let hr = try slot(fs.world, fid).hotRectWorld
            let c = SpriteSlot.Point(x: (hr.left + hr.right) >> 1, y: (hr.top + hr.bottom) >> 1)
            let sid = try XCTUnwrap(fs.world.newSprite(type: 0, x: c.x - 10, y: c.y - 10, layer: 0xb,
                                                       handler: .playerShot) { t in
                t.x = c.x - 10
                t.y = c.y - 10
                t.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
                t.centre = c
                t.hp = 150
            })
            let fx0 = Set(fs.world.active.sprites.filter { $0.handler == .effect }.map(\.id))
            _ = fs.step(keys: KeyState())
            let shot = try slot(fs.world, sid)
            XCTAssertTrue(shot.dead, "\(tag): absorbed in the collide pass")
            XCTAssertEqual(fs.world.player.cues.map(\.snd), [303], tag)
            let impact = fs.world.active.sprites.filter { $0.handler == .effect && !fx0.contains($0.id) && $0.type == 0 }
            XCTAssertEqual(impact.map { [$0.x, $0.y] }, custom ? [] : [[shot.x - 8, shot.y - 0xc]], tag)
        }
    }

    // MARK: - 11

    func testWarriorCrateCrush200() throws {
        // `.HitWarriorSprite`'s solid arm (M l. 73440–73460): a Statue (0x100a01f8) or Box (0x100a0484) other →
        // `.PlatformBounce(S, solid, S's hot-rect centre offset, 0, S +0x34, 0)`; 2 (contact from below) with the solid
        // falling (`+0x2c > 0`) or S on ground (`+0xce`) → `.HurtSprite(S, 200, solid.vx >> 1, −1000, 2, 8)`, `+0xf0 = 0`,
        // `.KillBox(solid)`, R(10000) → snd 701 at 42000 + R, R(10000), R(2) → 477 / 478 at 42000 + R (pitched, 1, 0x100,
        // S +0xe). A crate 0x433 sits on his head: its hot rect (0, 4, 0x1c, 0x1c) 3 px into his Setup rect (0x17, 0x1a,
        // 0x3a, 0x4a), centred over him.
        // The crate face 0x42e as a 3-row synthetic face, so `.KillBox`'s `.ExplodeFaceIntoParticles` emits.
        func tok(_ op: UInt32, _ n: Int) -> [UInt8] {
            let t = op << 24 | UInt32(n)
            return [UInt8(t >> 24), UInt8(t >> 16 & 0xff), UInt8(t >> 8 & 0xff), UInt8(t & 0xff)]
        }
        let face = ParticleFace(frame: [0, 0, 3, 4], bounds: [0, -1, 4, 6],
                                tokens: tok(1, 8) + tok(2, 3) + [10, 11, 12, 0] + tok(1, 12) + tok(3, 1) + tok(2, 2)
                                    + [20, 21, 0, 0] + tok(1, 8) + tok(2, 4) + [30, 31, 32, 33] + tok(0, 0))
        struct Case { let label: String; let vy: Int32; let ground: UInt8; let invulnerable: Int16; let crush: Bool }
        let cases = [Case(label: "falling", vy: 0x300, ground: 0, invulnerable: 0, crush: true),
                     Case(label: "vy 1", vy: 1, ground: 0, invulnerable: 0, crush: true),
                     // 2.11 item 24: S on ground (`+0xce`) with the solid resting or rising.
                     Case(label: "on ground, vy 0", vy: 0, ground: 3, invulnerable: 0, crush: true),
                     Case(label: "on ground, rising", vy: -0x200, ground: 1, invulnerable: 0, crush: true),
                     // 2.11 item 27: the hurt refused (`+0x116 ≠ 0`) — `+0xf0 = 0`, `.KillBox` and both sounds still.
                     Case(label: "invulnerable", vy: 0x300, ground: 0, invulnerable: 1, crush: true),
                     Case(label: "resting, in the air", vy: 0, ground: 0, invulnerable: 0, crush: false)]
        for (k, c) in cases.enumerated() {
            for handler in [SpriteHandler.box, .statue] {
                let tag = "\(c.label) \(handler)"
                let s = try session(seed: Int32(7 + k))
                let w = s.world
                w.particleFaces = ParticleFaces(sprite: { $0.pict == 0x42e ? face : nil })
                let id = try warriorID(s)
                w.active.update(id: id) { m in
                    m.vx = 0
                    m.vy = 0
                    m.groundKind = c.ground
                    m.invulnerable = c.invulnerable
                    m.voicePitch = 0x11
                    m.centre = SpriteSlot.Point(x: 950, y: 270)
                }
                let m0 = try slot(w, id)
                XCTAssertEqual(m0.hotRect, IdleSprites.Rect(top: 0x17, left: 0x1a, bottom: 0x3a, right: 0x4a))
                let crate = try XCTUnwrap(Warrior.newCrate(w, x: m0.x + 0x22, y: m0.y - 2))
                w.active.update(id: crate) { b in
                    b.handler = handler
                    b.vy = c.vy
                    b.vx = -1001
                    b.centre = SpriteSlot.Point(x: b.x + 0x10, y: b.y + 0xe)
                }
                let box0 = try slot(w, crate)
                // The bounce alone, on a twin: 2 (from below).
                let twin = try session(seed: Int32(7 + k))
                let tid = try warriorID(twin)
                twin.world.active.update(id: tid) { m in m.vx = 0; m.vy = 0; m.groundKind = c.ground }
                let tc = try XCTUnwrap(Warrior.newCrate(twin.world, x: m0.x + 0x22, y: m0.y - 2))
                twin.world.active.update(id: tc) { $0.vy = c.vy }
                let r = m0.hotRect
                XCTAssertEqual(twin.world.platformBounce(mover: tid, solid: tc, centre: SpriteSlot.Point(x: 0x32, y: 0x28),
                                                         factor: 0, rect: r, bounce: false), 2, "\(tag): from below")
                var e = w.rng
                let pool0 = w.particles.counters.count
                w.player.cues = []
                FerazelSession.hitCallback(w, id, crate)
                let m = try slot(w, id)
                guard c.crush else {
                    XCTAssertEqual([m.hp], [2000], tag)
                    XCTAssertFalse(try slot(w, crate).dead, tag)
                    XCTAssertEqual(m.voicePitch, 0x11, tag)
                    XCTAssertEqual(w.player.cues, [], tag)
                    XCTAssertEqual(w.rng.seed, e.seed, tag)
                    continue
                }
                let hurt = c.invulnerable == 0
                XCTAssertEqual(m.hp, hurt ? 1800 : 2000, "\(tag): 200 a crate — 2000 / 200 = 10 crates")
                if hurt {
                    // 2.11 item 23: `.HurtSprite(S, 200, solid.vx >> 1, −1000, 2, 8)` — vx 0 + (−1001 >> 1).
                    XCTAssertEqual([Int(m.invulnerable), Int(m.flash), Int(m.vx), Int(m.vy)], [2, 8, -501, -1000], tag)
                } else {
                    XCTAssertEqual([Int(m.invulnerable), Int(m.vx)], [1, 0], tag)
                }
                XCTAssertEqual(m.voicePitch, 0, "\(tag): `+0xf0 = 0` (the glow restarts)")
                XCTAssertTrue(try slot(w, crate).dead, "\(tag): `.KillBox(solid)`")
                // 2.11 items 25 / 26: `.KillBox`'s draws first — R(10000) for snd 424 (a 0x433 or a Statue of one), then
                // four a pixel for its particles — then R(10000) (701), R(10000), R(2) (477 / 478).
                let n = w.particles.counters.count - pool0
                XCTAssertGreaterThan(n, 0, "\(tag): the crate face exploded")
                let r424 = e.soundRate()
                for _ in 0..<n { _ = e.next(20); _ = e.next(750); _ = e.next(100); _ = e.next(30) }
                let r701 = Int32(e.next(10000)) + 42000
                let rMon = Int32(e.next(10000)) + 42000
                let mon: Int16 = e.next(2) == 0 ? 477 : 478
                XCTAssertEqual(w.rng.seed, e.seed, "\(tag): exactly those draws")
                XCTAssertEqual(w.player.cues, [
                    PlayerCue(call: .threeDRand, snd: 424, priority: 1, volume: 0x100, position: box0.centre, rate: r424),
                    PlayerCue(call: .threeDPitched, snd: 701, priority: 1, volume: 0x100, position: m.centre, rate: r701),
                    PlayerCue(call: .threeDPitched, snd: mon, priority: 1, volume: 0x100, position: m.centre, rate: rMon),
                ], tag)
            }
        }
        // Not a solid from below (the crate beside him, `.PlatformBounce` 0 or a side), or a Platform solid: nothing.
        for (dx, handler) in [(0x40, SpriteHandler.box), (0, .platform)] {
            let s = try session()
            let id = try warriorID(s)
            let m0 = try slot(s.world, id)
            let crate = try XCTUnwrap(Warrior.newCrate(s.world, x: m0.x + 0x22 + dx, y: m0.y - 2 + (dx == 0 ? 0 : 0x20)))
            s.world.active.update(id: crate) { $0.vy = 0x300; $0.handler = handler }
            let seed0 = s.world.rng.seed
            FerazelSession.hitCallback(s.world, id, crate)
            XCTAssertEqual(try slot(s.world, id).hp, 2000, "dx \(dx) \(handler)")
            XCTAssertFalse(try slot(s.world, crate).dead)
            XCTAssertEqual(s.world.rng.seed, seed0)
        }
        // `.PlatformBounce` 1 (he lands on a crate below him, falling): no crush — 2 only — and the landing is the
        // bounce's own (bounce flag 0: `+0xce = 3`, `+0xdc = solid`) — so the `+0xce` term must not be read on a 1.
        do {
            let s = try session()
            let id = try warriorID(s)
            s.world.active.update(id: id) { $0.vx = 0; $0.vy = 0x300; $0.groundKind = 0 }
            let m0 = try slot(s.world, id)
            let crate = try XCTUnwrap(Warrior.newCrate(s.world, x: m0.x + 0x22, y: m0.y + 0x3a - 2))
            s.world.active.update(id: crate) { $0.vy = 0; $0.vx = 0 }
            let seed0 = s.world.rng.seed
            s.world.player.cues = []
            FerazelSession.hitCallback(s.world, id, crate)
            let m = try slot(s.world, id)
            XCTAssertEqual([Int(m.hp), Int(m.groundKind), m.ridden ?? -1], [2000, 3, crate], "landed on the crate: no crush")
            XCTAssertFalse(try slot(s.world, crate).dead)
            XCTAssertEqual(s.world.player.cues, [])
            XCTAssertEqual(s.world.rng.seed, seed0)
        }
        // The bounce's centre is his hot-rect centre offset (0x32, 0x28): it picks the side at the edges — a crate 20 px
        // into him from above is still "from below" (crushed); one at dx −11 / dy +24 or dy +29 is a side contact.
        for (dx, dy, crush) in [(0, 20, true), (-11, 24, false), (0, 29, false)] {
            let s = try session()
            let id = try warriorID(s)
            s.world.active.update(id: id) { $0.vx = 0; $0.vy = 0; $0.groundKind = 0 }
            let m0 = try slot(s.world, id)
            let crate = try XCTUnwrap(Warrior.newCrate(s.world, x: m0.x + 0x22 + dx, y: m0.y - 2 + dy))
            s.world.active.update(id: crate) { $0.vy = 0x300 }
            FerazelSession.hitCallback(s.world, id, crate)
            XCTAssertEqual(try slot(s.world, id).hp, crush ? 1800 : 2000, "centre: dx \(dx) dy \(dy)")
            XCTAssertEqual(try slot(s.world, crate).dead, crush, "centre: dx \(dx) dy \(dy)")
        }
        // A real Statue (BOS §1.1): a Walker 0x6a4 petrified by `.TurnIntoStatue`, falling onto his head — 200 as a crate,
        // but `.KillBox` makes no draw of its own (snd 424 and the particles are the switch blocks' and the rocks 0x433 /
        // 0x434 only, M l. 61483–61520): the Hit's R(10000) 701, R(10000), R(2) alone.
        do {
            let s = try session()
            let w = s.world
            let id = try warriorID(s)
            w.active.update(id: id) { $0.vx = 0; $0.vy = 0; $0.groundKind = 0 }
            let m0 = try slot(w, id)
            var lights = LightTable()
            let st = try XCTUnwrap(BoxSprite.generate(w, type: 0x6a4, x: m0.x, y: m0.y - 0x60, layer: 0xb,
                                                      lights: &lights, effects: 1))
            StatueSprite.turnIntoStatue(w, id: st)
            let r = try slot(w, st).hotRect
            w.active.update(id: st) { t in                                    // centred on him, 3 px into his top
                t.x = m0.x + 0x32 - ((r.left + r.right) >> 1)
                t.y = m0.y + 0x17 + 3 - r.bottom
                t.vy = 0x300
                t.vx = 0
            }
            XCTAssertEqual([try slot(w, st).handler], [.statue])
            var e = w.rng
            let pool0 = w.particles.counters.count
            w.player.cues = []
            FerazelSession.hitCallback(w, id, st)
            let m = try slot(w, id)
            XCTAssertEqual(m.hp, 1800, "a Statue: 200")
            XCTAssertTrue(try slot(w, st).dead, "a Statue: `.KillBox(solid)`")
            XCTAssertEqual(w.particles.counters.count, pool0, "a Statue: no particles")
            let r701 = Int32(e.next(10000)) + 42000
            let rMon = Int32(e.next(10000)) + 42000
            let mon: Int16 = e.next(2) == 0 ? 477 : 478
            XCTAssertEqual(w.rng.seed, e.seed, "a Statue: the Hit's three draws alone")
            XCTAssertEqual(w.player.cues, [
                PlayerCue(call: .threeDPitched, snd: 701, priority: 1, volume: 0x100, position: m.centre, rate: r701),
                PlayerCue(call: .threeDPitched, snd: mon, priority: 1, volume: 0x100, position: m.centre, rate: rMon),
            ], "a Statue: no snd 424")
        }
    }

    // MARK: - 12

    func testWarriorStatueShotIsAShot() throws {
        // No boss Hit calls `.TurnIntoStatue` (raw scan, bosses §1.5): a Statue-spell shot (type 1) is absorbed like any
        // player shot — killed (sound 0, effect 1), snd 303 — from either side, in any state; he stays the Warrior.
        for (dx, state, mirrored) in [(-5, Int16(6), false), (5, 6, true), (-5, 7, true), (5, 2, false), (0, 4, false)] {
            let s = try session()
            let id = try standing(s)
            s.world.active.update(id: id) { $0.subtype = state; $0.mirrored = mirrored }
            let sid = try other(s.world, over: id, dx: dx, type: 1)
            let fx0 = effects(s.world)
            s.world.player.cues = []
            FerazelSession.hitCallback(s.world, id, sid)
            let w = try slot(s.world, id)
            let tag = "dx \(dx) state \(state)"
            XCTAssertEqual(w.handler, .warrior, "\(tag): not turned to stone")
            XCTAssertEqual(w.hp, 2000, tag)
            XCTAssertTrue(try slot(s.world, sid).dead, tag)
            XCTAssertGreaterThan(effects(s.world), fx0, "\(tag): effect 1")
            XCTAssertEqual(s.world.player.cues.map(\.snd), [303], tag)
            XCTAssertFalse(s.world.active.sprites.contains { $0.handler == .statue }, tag)
        }
    }

    // MARK: - 13

    func testWarriorLavaAndBrine() throws {
        // The tail's liquids (M l. 73400–73416) — the Dillo's rows (`EnemyCommon.liquids(class: .dillo)`): in liquid
        // (`+0x11c ≠ 0` and (`+0x11c == 1` with kind 0, or kind > 0)): kind 3 (brine) heals 4 below HP 500; kind 2 (lava)
        // with `+0x116 == 0` → `+0x116 = 0x13`, HP − 100, `+0xaa = 0x11`, snd 701 vol 0x55 (`.STPlay3DSound`, no draw);
        // kinds 0 (fully under) and 1 nothing. Level 5 has no liquid: a test-only BG liquid (in memory, the level's own
        // tile index 0 given kind 200 + k) fills rows 2…14 over columns 20…35 around him (a column reaching row 0 would
        // never end `.HandleUnderWater`'s surface walk — `UnderWater.surfaceY`); the arena locked.
        struct Case { let kind: Int; let hp: Int16; let invulnerable: Int16; let want: Int16 }
        let cases = [Case(kind: 2, hp: 2000, invulnerable: 0, want: 1900), Case(kind: 2, hp: 2000, invulnerable: 3, want: 2000),
                     Case(kind: 3, hp: 300, invulnerable: 0, want: 304), Case(kind: 3, hp: 499, invulnerable: 0, want: 503),
                     Case(kind: 3, hp: 500, invulnerable: 0, want: 500), Case(kind: 0, hp: 2000, invulnerable: 0, want: 2000),
                     Case(kind: 1, hp: 2000, invulnerable: 0, want: 2000), Case(kind: 1, hp: 300, invulnerable: 0, want: 300)]
        for c in cases {
            let tag = "kind \(c.kind) HP \(c.hp) invul \(c.invulnerable)"
            let s = try session()
            let g = s.world.tiles
            var bg = g.bg.cells
            for row in 2..<min(15, g.bg.height) { for col in 20...35 { bg[row * g.bg.width + col] = bg[row * g.bg.width + col] & 0xff00 | 1 } }   // tile 0
            var kinds = g.bgKinds
            kinds[0] = 200 + c.kind
            s.world.tiles = TileGrid(fg: g.fg, bg: TileMap(width: g.bg.width, height: g.bg.height, cells: bg),
                                     fgKinds: g.fgKinds, bgKinds: kinds)
            let id = try locked(s, state: 0) { w in
                w.hp = c.hp
                w.invulnerable = c.invulnerable
                w.vx = 0
                w.vy = 0
            }
            s.world.player.cues = []
            handle(s.world, id)
            let w = try slot(s.world, id)
            XCTAssertEqual(w.waterRow, 1, "\(tag): fully under (the surface at row 2, above him)")
            XCTAssertEqual(w.waterKind, Int16(c.kind), tag)
            XCTAssertEqual(w.hp, c.want, tag)
            let lava = c.kind == 2 && c.invulnerable == 0
            let ouch = s.world.player.cues.filter { $0.snd == 701 }
            XCTAssertEqual(ouch.map { [$0.call == .threeD, $0.priority == 1, $0.volume == 0x55, $0.rate == nil] },
                           lava ? [[true, true, true, true]] : [], tag)
            if lava { XCTAssertEqual([Int(w.invulnerable), Int(w.flash)], [0x13, 0x11], tag) }
        }
        // The arena open: the Handle returns before the tail — no liquids, whatever the kind.
        let s = try session()
        let g = s.world.tiles
        var bg = g.bg.cells
        for row in 2..<min(15, g.bg.height) { for col in 20...35 { bg[row * g.bg.width + col] = bg[row * g.bg.width + col] & 0xff00 | 1 } }
        var kinds = g.bgKinds
        kinds[0] = 202
        s.world.tiles = TileGrid(fg: g.fg, bg: TileMap(width: g.bg.width, height: g.bg.height, cells: bg),
                                 fgKinds: g.fgKinds, bgKinds: kinds)
        let id = try warriorID(s)
        handle(s.world, id)
        XCTAssertEqual(try slot(s.world, id).hp, 2000, "unlocked: no liquids")
    }

    // MARK: - 14

    func testWarriorKillTail() throws {
        // `.KillWarrior` (M l. 73465–73495), the Kill proc `+0x50` (`EnemyCommon.killProc`, as `.HandleBurn` calls it):
        // the count head (`+0xe9 == 0 ∧ +0x1b5` → live − 1 and `G+0x306+2L` + 1), `+0xe9 = 1`, `+0xea = 1`; then with
        // `+0x170 ≠ 0` the boss-kill tail — `.STPlay3DSoundPitched(453, 1, 0x100, +0xe, 48000)` (no draw), the shake
        // `*_DAT_1009ffa0 = 0x1e`, the mask flash `*_DAT_100a00fc = 3`, `*_DAT_1009fed0 = 1`. No score.
        let s = try session()
        let w = s.world
        let id = try standing(s)
        let me = try slot(w, id)
        XCTAssertTrue(me.countedInTotals, "counted inside the window")
        XCTAssertEqual(w.arena.noBossAlive, 0, "his Setup cleared it")
        let live0 = w.enemies.live, stat0 = w.globals.achieved[0][w.levelIndex], score0 = w.globals.score
        let seed0 = w.rng.seed
        w.player.cues = []
        EnemyCommon.killProc(w, id: id)
        var k = try slot(w, id)
        XCTAssertEqual([k.dead, k.killedForGood], [true, true], "`+0xe9 = 1`, `+0xea = 1`")
        XCTAssertEqual(w.enemies.live, live0 - 1)
        XCTAssertEqual(w.globals.achieved[0][w.levelIndex], stat0 + 1)
        XCTAssertEqual(w.globals.score, score0, "no score")
        let thunder = PlayerCue(call: .threeDPitched, snd: 453, priority: 1, volume: 0x100, position: me.centre,
                                rate: 48000)
        XCTAssertEqual(w.player.cues, [thunder])
        XCTAssertEqual(w.shakeStore, 0x1e)
        XCTAssertEqual(w.flash.count, 3)
        XCTAssertEqual(w.arena.noBossAlive, 1, "the gate opens from the next gate Handle")
        XCTAssertEqual(w.rng.seed, seed0, "no draw")
        // 2.11 item 28: the guard covers the count only — a second call counts nothing but replays the tail.
        w.player.cues = []
        w.shakeStore = nil
        w.flash.count = 0
        w.arena.noBossAlive = 0
        EnemyCommon.killProc(w, id: id)
        k = try slot(w, id)
        XCTAssertEqual(w.enemies.live, live0 - 1, "counted once")
        XCTAssertEqual(w.globals.achieved[0][w.levelIndex], stat0 + 1)
        XCTAssertEqual(w.player.cues, [thunder], "the tail replays")
        XCTAssertEqual([Int(w.shakeStore ?? 0), Int(w.flash.count), Int(w.arena.noBossAlive)], [0x1e, 3, 1])
        // p4 = 0 (`+0x170 == 0`): the count and the flags, no tail.
        let p = try session()
        let pid = try standing(p)
        p.world.active.update(id: pid) { $0.classWord170 = 0 }
        let plive = p.world.enemies.live
        p.world.player.cues = []
        EnemyCommon.killProc(p.world, id: pid)
        XCTAssertEqual([try slot(p.world, pid).dead, try slot(p.world, pid).killedForGood], [true, true])
        XCTAssertEqual(p.world.enemies.live, plive - 1)
        XCTAssertEqual(p.world.player.cues, [])
        XCTAssertNil(p.world.shakeStore)
        XCTAssertEqual([Int(p.world.flash.count), Int(p.world.arena.noBossAlive)], [0, 0])
        // Any non-zero boss flag runs the tail (`+0x170 ≠ 0`, not `== 1`).
        let q = try session()
        let qid = try standing(q)
        q.world.active.update(id: qid) { $0.classWord170 = 2 }
        EnemyCommon.killProc(q.world, id: qid)
        XCTAssertEqual(q.world.arena.noBossAlive, 1, "p4 2: the tail")

        // Through the level runner: the real Kill opens the gate — 2940 (record 4, p1 −1) rises from the next gate
        // Handle — and the loop rule (M l. 5266–5274) fades to track 30; with the music preference off (prefs+0xc = 0)
        // the rule never switches to 30. (Closes the Phase 5 carries "the Warrior's killProc arm would count and remove
        // the Warrior without opening the gate" and "no test with music off".)
        for music in [UInt8(1), 0] {
            var prefs = FerazelPrefs()
            prefs.musicOn = music
            let run = try LevelRun(resources: try resources(), prefs: prefs, level: 5, seed: 1, carry: LevelCarry(),
                                   save: SaveBlock(), fade: ScreenFade(), music: MusicFade(), services: Headless(),
                                   sounds: StageSounds(prefs: prefs, lengths: [:]), start: (470, 300))
            var t: UInt32 = 0
            var plays: [Int] = []
            func tick(_ n: Int) throws {
                let goal = run.iterations + n
                var guardTicks = 0
                while run.iterations < goal && guardTicks < 20_000 {
                    let out = try run.tick(now: t, input: FrontInput())
                    t &+= 1
                    guardTicks += 1
                    plays += out.merged.music.compactMap { if case .play(let n) = $0 { n } else { nil } }
                }
            }
            try tick(60)
            let rs = try XCTUnwrap(run.session)
            rs.world.arena.locked = true
            let gate = try XCTUnwrap(rs.world.active.sprites.first { $0.recordIndex == 4 }, "the gate active near x 470")
            XCTAssertEqual(gate.y, 265, "shut")
            let wid = try XCTUnwrap(rs.world.active.sprites.first { $0.handler == .warrior }?.id)
            XCTAssertFalse(plays.contains(30), "music \(music): no track 30 while he stands")
            XCTAssertTrue(run.music.asyncDone, "music \(music): the loop rule starts no fade while he stands")
            EnemyCommon.killProc(rs.world, id: wid)
            XCTAssertEqual(rs.world.arena.noBossAlive, 1)
            try tick(1)
            XCTAssertEqual(try XCTUnwrap(rs.world.active.sprites.first { $0.recordIndex == 4 }).y, 263,
                           "music \(music): the next gate Handle lifts it 2 px")
            try tick(239)
            let g = try XCTUnwrap(rs.world.active.sprites.first { $0.recordIndex == 4 })
            XCTAssertLessThan(g.y, 265, "music \(music): the gate rose")
            if music == 1 {
                XCTAssertTrue(plays.contains(30), "the loop rule's track 30")
                XCTAssertEqual(run.music.currentTrack, 30)
                XCTAssertEqual([run.music.asyncDirection, run.music.asyncFrames], [1, 0x3c], "track 30 fades in over 60")
            } else {
                XCTAssertFalse(plays.contains(30), "music off: never track 30")
                XCTAssertNotEqual(run.music.currentTrack, 30)
            }
        }
    }

    private final class Headless: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    // MARK: - 15

    func testWarriorContactAndWriteBack() throws {
        // `.HitPlayerSprite` step 7: the routing list (M l. 49514–49521) sends the Warrior's Handle (0x100a0494) to the
        // generic path (M l. 49802–49929); his damage row 0x70 (M l. 49840–49842), invulnerability 0x3c; damage 0x70 →
        // R(100) > 0x50 → 3 coins, drawn before `.HurtPlayer` and whatever it decides; then `.HurtPlayer(player, him,
        // 0x70, blood 1, 0x3c, coins)`.
        for band in [0...0x50, 0x51...99] as [ClosedRange<Int16>] {
            let k = seed { g in band.contains(g.next(100)) }
            for invulnerable in [Int16(0), 5] {
                let tag = "band \(band) invul \(invulnerable)"
                func make() throws -> (FerazelSession, Int, Int) {
                    let s = try session()
                    let id = try standing(s)
                    let pid = try XCTUnwrap(s.world.playerID)
                    s.world.active.update(id: pid) { $0.invulnerable = invulnerable }
                    s.world.globals.coins = 20
                    s.world.rng = FastRand(seed: k)
                    return (s, id, pid)
                }
                let (s, id, pid) = try make()
                let hp0 = try slot(s.world, pid).hp
                var lights = LightTable()
                HitPlayerSprite.hit(s.world, player: pid, other: id, lights: &lights, effects: 1)
                // The twin: R(100) by hand, then `.HurtPlayer` with the row's arguments.
                let (t, tid, tpid) = try make()
                let coins: Int16 = 0x50 < t.world.rng.next(100) ? 3 : 0
                HurtPlayer.hurt(t.world, player: tpid, attacker: tid, damage: 0x70, blood: true, invulnerable: 0x3c,
                                coins: coins)
                let p = try slot(s.world, pid), q = try slot(t.world, tpid)
                XCTAssertEqual(s.world.rng.seed, t.world.rng.seed, "\(tag): R(100) first, then the hurt's draws")
                XCTAssertEqual(s.world.globals.coins, t.world.globals.coins, tag)
                XCTAssertEqual([p.hp, p.invulnerable], [q.hp, q.invulnerable], tag)
                if invulnerable == 0 {
                    XCTAssertEqual([Int(p.hp), Int(p.invulnerable)], [Int(hp0) - 0x70, 0x3c], tag)
                    XCTAssertEqual(s.world.globals.coins < 20, 0x50 < band.lowerBound, "\(tag): coins only above 0x50")
                } else {
                    XCTAssertEqual(p.hp, hp0, "\(tag): refused — the R(100) still drawn")
                    var e = FastRand(seed: k)
                    _ = e.next(100)
                    XCTAssertEqual(s.world.rng.seed, e.seed, tag)
                }
            }
        }
        // The save write-back flags: the Setup's `+0x18a = 1` (M l. 73027) and the Kill's `+0xea = 1` (M l. 73485).
        let s = try session()
        let id = try warriorID(s)
        XCTAssertTrue(try slot(s.world, id).noWriteBack18a, "`+0x18a = 1`")
        XCTAssertFalse(try slot(s.world, id).killedForGood)
        EnemyCommon.killProc(s.world, id: id)
        XCTAssertTrue(try slot(s.world, id).killedForGood, "`+0xea = 1`")
    }
}
