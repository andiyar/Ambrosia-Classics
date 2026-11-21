import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-CH1 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-CH1`; docs/ferazel/phase6-engine-contracts.md
/// §2.13; docs/ferazel/phase6-boss-contracts.md §3.7): the player's boss-stagger arm — `.HandlePlayerSprite` row 33's
/// `*_DAT_100a0570 > 0` arm (M l. 45591–45632): vx × 0.5 (f64 `0x100a1a28`, `fctiwz`), the stagger face 1037
/// (`_DAT_100a0784`) by `(c mod 12) >> 1` → +0, +0x34, +0, +0x68, +0x9c, +0x68 (faces 0, 1, 0, 2, 3, 2), the idle reset,
/// the standing / climb / spin clears, the spin-sound stop, the crouch 0, then the end of the state chain. The count
/// runs down in row 13 (M l. 44740–44741) before the arm reads it, so a value v gives v − 1 arm frames unless an earlier
/// arm pre-empts one. Synthetic: level 1's data with a 32×16 test grid and a flat floor (as `PlayerStateTests`); the
/// Chief writes 0x18 after the player's Handle (layer 10 before 0xc), Xichra 0x14 before it — here each is set between
/// frames.
final class PlayerStaggerTests: XCTestCase {

    private let standY = 400 - 0x55

    private func world() throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let w = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        let cols = 32
        var fg = [UInt16](repeating: 0, count: cols * 16)
        for c in 0..<cols { fg[12 * cols + c] = 4 }
        w.tiles = TileGrid(fg: TileMap(width: cols, height: 16, cells: fg),
                           bg: TileMap(width: cols, height: 16, cells: [UInt16](repeating: 0, count: cols * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    /// The player's record; a missing player fails the test (a blank slot comes back) rather than crashing the run.
    private func player(_ w: SpriteWorld, file: StaticString = #filePath, line: UInt = #line) -> SpriteSlot {
        guard let id = w.playerID, let s = w.active.record(id: id) else {
            XCTFail("no player", file: file, line: line)
            return SpriteSlot(type: 0, x: 0, y: 0)
        }
        return s
    }

    @discardableResult
    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) -> FaceRef? {
        _ = w.player.drainFrameOutputs()
        w.player.soundCalls = []
        Player.handle(world: w, keys: keys, solver: solver)
        return player(w).face
    }

    private func standing(_ w: SpriteWorld, x: Int = 300) -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: x, y: standY))
        let solver = TileSolver(world: w)
        frame(w, solver)
        frame(w, solver)
        XCTAssertEqual(player(w).groundKind, 3)
        return solver
    }

    private func f(_ i: Int) -> FaceRef { FaceRef(pict: 1037, index: i, set: .encoded) }

    /// The arm's face for the count c as the arm reads it: (c mod 12) >> 1 → 0, 1, 0, 2, 3, 2.
    private func pose(_ c: Int) -> FaceRef { f([0, 1, 0, 2, 3, 2][(c % 12) >> 1]) }

    // MARK: - 1

    func testStaggerSlowsAndPoses() throws {
        // The arm alone (row 33, `PlayerStates.select`): vx × 0.5 truncated toward zero (`fctiwz`, ENG §2.13's assert:
        // −3 → −1, not −2), the pose by the count, the end of the chain (false: no tumble face drawn).
        let w = try world()
        _ = standing(w)
        let id = try XCTUnwrap(w.playerID)
        for (v, want) in [(Int32(0x800), Int32(0x400)), (-3, -1), (3, 1), (-0x801, -0x400), (1, 0), (-1, 0)] {
            w.player.bossGrab = 5
            w.active.update(id: id) { $0.vx = v }
            XCTAssertFalse(PlayerStates.select(world: w, id: id))
            XCTAssertEqual(player(w).vx, want, "vx \(v)")
        }
        for c in 1...36 {
            w.player.bossGrab = Int16(c)
            PlayerStates.select(world: w, id: id)
            XCTAssertEqual(player(w).face, pose(c), "c \(c)")
            XCTAssertEqual(w.player.bossGrab, Int16(c), "the arm does not count")
        }
        XCTAssertEqual((1...12).map { pose($0).index }, [0, 1, 1, 0, 0, 2, 2, 3, 3, 2, 2, 0])

        // The whole Handle: the Chief's 0x18 (set after the player's Handle) → 23 arm frames from the next frame,
        // counts 23…1; Xichra's 0x14 → 19. Every arm frame: the pose by the count after the row-13 count-down, keys
        // not read (LEFT + JUMP held: no jump, no walk), vx halved. Then free: the next frame reads the keys again.
        for (value, frames) in [(Int16(0x18), 23), (Int16(0x14), 19)] {
            let v = try world()
            let solver = standing(v)
            v.player.bossGrab = value
            var poses: [FaceRef?] = [], counts: [Int16] = []
            for _ in 0..<(frames + 1) {
                let x0 = player(v).x
                let face = frame(v, solver, [.left, .jump])
                counts.append(v.player.bossGrab)
                if face?.pict == 1037 {
                    poses.append(face)
                    XCTAssertEqual(player(v).x, x0, "value \(value): no walk while staggered")
                    XCTAssertGreaterThanOrEqual(player(v).vy, 0, "value \(value): no jump while staggered")
                }
            }
            XCTAssertEqual(poses.count, frames, "value \(value): v − 1 arm frames")
            XCTAssertEqual(poses, (1...frames).reversed().map { pose($0) }, "value \(value)")
            XCTAssertEqual(counts, (0...frames).reversed().map { Int16($0) }, "value \(value): the count-down")
            XCTAssertNotEqual(frame(v, solver, [.jump]).map(\.pict), 1037)
            XCTAssertLessThan(player(v).vy, 0, "value \(value): free — the jump is read again")
        }
        // The twin with no stagger: the same keys walk and jump at once.
        let t = try world()
        let ts = standing(t)
        let x0 = player(t).x
        frame(t, ts, [.left, .jump])
        XCTAssertLessThan(player(t).vy, 0, "no stagger: the jump is read")
        frame(t, ts, [.left])
        XCTAssertLessThan(player(t).x, x0, "no stagger: the walk is read")

        // A pre-empted frame shortens it: on the 5th frame the spirit transition's last step (`_DAT_100a0574` 0x1a, M l.
        // 45581–45589, ending itself at 0x1b → 0) takes row 33 first; the count-down still runs, so 0x18 gives 22 arm
        // frames, the pre-empted one showing the transition's face.
        let p = try world()
        let ps = standing(p)
        p.player.bossGrab = 0x18
        var shown: [Int16] = []
        for k in 1...24 {
            if k == 5 { p.player.spiritTransition = 0x1a }
            let face = frame(p, ps)
            if k == 5 {
                XCTAssertEqual(face?.pict, PlayerStates.mist, "pre-empted by the spirit transition")
                XCTAssertEqual(p.player.spiritTransition, 0, "the transition ended itself")
            }
            if face?.pict == 1037 { shown.append(p.player.bossGrab) }
        }
        XCTAssertEqual(shown.count, 22, "one pre-empted frame: 22 arm frames")
        XCTAssertFalse(shown.contains(19), "count 19 was the pre-empted frame")
        XCTAssertEqual(p.player.bossGrab, 0)
    }

    // MARK: - 2

    func testStaggerClearsStates() throws {
        // Each arm frame (M l. 45599–45609): idle > 0 → idle = fidgets played (idle 0 stays 0); the standing flag
        // `PTR_DAT_100a0670`, climb `_DAT_100a0758`, spin `PTR_DAT_100a0668` and crouch `_DAT_100a071c` cleared; the spin
        // sound 427 stopped only while a voice plays it — the idle test `FUN_100916dc(427)` answered by `SoundVoices`
        // (ENG §2.13's assert).
        let w = try world()
        _ = standing(w)
        let id = try XCTUnwrap(w.playerID)
        for (idle, fidgets, want) in [(Int16(7), Int16(2), Int16(2)), (0, 2, 0), (1, 0, 0)] {
            w.player.bossGrab = 3
            w.player.idle = idle
            w.player.fidgets = fidgets
            w.player.standing0670 = true
            w.player.climb = 1
            w.player.spin = true
            w.player.crouch = 3
            PlayerStates.select(world: w, id: id)
            XCTAssertEqual(w.player.idle, want, "idle \(idle) fidgets \(fidgets)")
            XCTAssertFalse(w.player.standing0670)
            XCTAssertEqual(w.player.climb, 0)
            XCTAssertFalse(w.player.spin)
            XCTAssertEqual(w.player.crouch, 0)
        }
        for playing in [false, true] {
            w.player.bossGrab = 3
            w.player.cues = []
            w.player.soundCalls = []
            w.voices = SoundVoices(playing: playing ? [427] : [])
            PlayerStates.select(world: w, id: id)
            XCTAssertEqual(w.player.cues.filter { $0.snd == 427 }, playing ? [PlayerCue(call: .stopIfPlaying, snd: 427)] : [],
                           "427 playing \(playing)")
        }
        // A 427 started earlier this iteration counts as playing (`SoundVoices` applies the calls so far).
        w.player.bossGrab = 3
        w.voices = SoundVoices(playing: [])
        w.player.cues = []
        w.player.soundCalls = []
        w.player.cue(PlayerCue(call: .threeDRand, snd: 427, priority: 1, volume: 0x100, position: SpriteSlot.Point(),
                               rate: 60000))
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual(w.player.cues.last, PlayerCue(call: .stopIfPlaying, snd: 427))
        // The twin with no stagger: the grounded arm leaves the crouch to `.HandleKeys` and the climb alone (crouch 2
        // stands and shows 1011[1]; climb 0 must hold or the climb arm runs; the standing flag the arm clears stands).
        w.player.bossGrab = 0
        w.player.climb = 0
        w.player.crouch = 2
        w.player.standing0670 = true
        PlayerStates.select(world: w, id: id)
        XCTAssertNotEqual(player(w).face?.pict, 1037)
        XCTAssertEqual(player(w).face, FaceRef(pict: PlayerStates.crouch, index: 1, set: .encoded), "the crouch arm's face")
        XCTAssertEqual(w.player.crouch, 2, "the crouch left to `.HandleKeys`")
        XCTAssertEqual(w.player.climb, 0, "the climb left alone")
        XCTAssertTrue(w.player.standing0670, "the standing flag not cleared")
    }

    // MARK: - 3

    func testStaggerSkipsStateChain() throws {
        // After the arm, `goto LAB_10050e6c` (M l. 45632): the hurt-stun, door, rope, swim, cling and grounded arms are
        // not reached — their counters stand; the earlier arms (glider, dying, spirit transition) come first and the arm
        // is not reached on their frames. Row 34 still runs: the facing comes from `facing` (no tumble face drawn).
        let w = try world()
        let solver = standing(w)
        let id = try XCTUnwrap(w.playerID)
        w.player.bossGrab = 4
        w.player.stun = 1
        w.player.animation05f8 = 3
        w.player.swim = 2
        let swimBefore = w.player.swim
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual(player(w).face?.pict, 1037)
        XCTAssertEqual([w.player.stun, w.player.animation05f8, w.player.swim], [1, 3, swimBefore],
                       "the later arms are skipped")
        // The twin: no stagger → the hurt-stun arm runs (1013[0], the stun counted).
        w.player.bossGrab = 0
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual(player(w).face, FaceRef(pict: 1013, index: 0, set: .encoded))
        XCTAssertEqual(w.player.stun, 2)
        w.player.stun = 0
        w.player.animation05f8 = 0
        w.player.swim = 0
        // The earlier arms first: the glider, dying and the spirit transition pre-empt it (no 1037, vx not halved by it).
        for (label, set) in [("glider", { (v: SpriteWorld) in v.player.glider = true }),
                             ("dying", { (v: SpriteWorld) in v.player.dying = 1 }),
                             ("spirit", { (v: SpriteWorld) in v.player.spiritTransition = 2 })] {
            let v = try world()
            _ = standing(v)
            let vid = try XCTUnwrap(v.playerID)
            v.player.bossGrab = 4
            set(v)
            PlayerStates.select(world: v, id: vid)
            XCTAssertNotEqual(player(v).face?.pict, 1037, label)
            XCTAssertEqual(v.player.bossGrab, 4, label)
        }
        // Row 34 after the arm: the facing from `facing` (2 → not mirrored, else mirrored).
        for facing: Int16 in [1, 2] {
            w.player.bossGrab = 6
            w.player.facing = facing
            frame(w, solver)
            XCTAssertEqual(player(w).face?.pict, 1037)
            XCTAssertEqual(player(w).mirrored, facing != 2, "facing \(facing)")
        }
    }
}
