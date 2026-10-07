import XCTest
@testable import DeimosCore

/// Phase 2 seam additions (plan C0, S3; S2 `CueBuffer`/`SoundPlay`): the new `RenderOp` cases, the positional
/// halt, typed keys, the RNG draw counter, the sound-cue builders (`FUN_100475e0`, `FUN_10047670`) and the
/// unit index; the button mapping pinned to the guide and the films (probes p08, p11, p13, p17).
final class Phase2SeamTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try AssetsTests.loaded.get() }

    func testPassOutputAdditiveDefaults() {
        let out = PassOutput()
        XCTAssertNil(out.haltEffectsAt)
        XCTAssertEqual(HeldKeys().typed, [])
        XCTAssertNil(CueBuffer().haltEffectsAt)
        let stamp = ParticleStamp(x: 3, y: -4, core: 0x7BDE, fringe: 0x4A52, fade: 2)
        XCTAssertEqual(RenderOp.particles([stamp]), .particles([stamp]))
        XCTAssertNotEqual(RenderOp.particles([stamp]), .particles([]))
        XCTAssertEqual(RenderOp.pauseWait(.gameScreen), .pauseWait(.gameScreen))
        XCTAssertNotEqual(RenderOp.pauseWait(.gameScreen), .pauseWait(.fullScreen))
        XCTAssertTrue(RenderOp.isHostOp(.fade(.toBlack, .gameScreen)))
        XCTAssertTrue(RenderOp.isHostOp(.limit))
        XCTAssertTrue(RenderOp.isHostOp(.pauseWait(.gameScreen)))
        XCTAssertFalse(RenderOp.isHostOp(.present(.gameScreen)))
        XCTAssertFalse(RenderOp.isHostOp(.particles([stamp])))
    }

    /// `rand` counts its draws; RandomRange with min == max makes none (`100465a0`, `100465fc…`); p08.
    func testRandomDrawCounter() {
        var r = MSLRandom(seed: 0)
        XCTAssertEqual(r.draws, 0)
        r.srand(1)
        XCTAssertEqual(r.range(Int32(10), Int32(11)), 10, "rand 16838 (p08)")
        XCTAssertEqual(r.draws, 1)
        XCTAssertEqual(r.range(Int32(5), Int32(5)), 5)
        XCTAssertEqual(r.range(Float(1.0), Float(1.0)), 1.0)
        XCTAssertEqual(r.draws, 1)
        r.srand(1)
        XCTAssertEqual(r.draws, 0)
        // Equality is the generator state alone.
        var a = MSLRandom(seed: 7)
        _ = a.rand()
        var b = MSLRandom(seed: 0)
        b.srand(a.state)
        XCTAssertEqual(a.draws, 1)
        XCTAssertEqual(b.draws, 0)
        XCTAssertEqual(a, b)
    }

    /// `FUN_100475e0` (`10047600–1004764c`): pitch is drawn, volume = R(min, min) (no draw), priority & 0xFF;
    /// id `none` → no cue, no draw (sound-music §2.3).
    func testSoundRecordDrawsPitchOnly() {
        var rec = SoundRecord()
        rec.id = FourCC("exsl")!
        rec.minVolume = 100
        rec.maxVolume = 70
        rec.priority = 0x132
        rec.minPitch = 0.50
        rec.maxPitch = 0.55
        var rng = MSLRandom(seed: 1)
        let cue = SoundPlay.record(rec, allowMultiple: true, rng: &rng)
        XCTAssertEqual(cue?.id, FourCC("exsl"))
        XCTAssertEqual(cue?.volume, 100)
        XCTAssertEqual(cue?.priority, 0x32)
        XCTAssertEqual(cue?.pitch.bitPattern, 0x3f06_93da)
        XCTAssertEqual(cue?.allowMultiple, true)
        XCTAssertEqual(rng.draws, 1)

        rec.id = .none
        var quiet = MSLRandom(seed: 1)
        XCTAssertNil(SoundPlay.record(rec, allowMultiple: false, rng: &quiet))
        XCTAssertEqual(quiet.draws, 0)
        XCTAssertEqual(quiet.state, 1)
    }

    /// `FUN_10047670`: pitch = `*(*(r2−0x6dbc))` = 1.0 (`0x100d7414`), no draw.
    func testPermSoundNoDraw() throws {
        let a = try assets()
        XCTAssertEqual(a.sounds[18], FourCC("wesw"))
        let rng = MSLRandom(seed: 1)
        let cue = SoundPlay.perm(a.sounds[18], priority: 75, volume: 100, allowMultiple: true)
        XCTAssertEqual(cue, SoundCue(id: FourCC("wesw")!, priority: 75, volume: 100, pitch: 1.0, allowMultiple: true))
        XCTAssertEqual(rng.draws, 0)
    }

    /// `unde` tag → master-list index (`FUN_1003d2f0` / `FUN_1003d550`).
    func testUnitIndex() throws {
        let a = try assets()
        XCTAssertEqual(a.unitIndex.count, 386)
        let i = try XCTUnwrap(a.unitIndex[FourCC("bu01")!])
        XCTAssertEqual(a.definitions.units[i].id, FourCC("bu01"))
        XCTAssertEqual(a.definitions.units[i].name, "Buzzsaw Mk 1")
        XCTAssertNil(a.unitIndex[.none])
        for (id, idx) in a.unitIndex { XCTAssertEqual(a.definitions.units[idx].id, id) }
    }

    /// Slots 4/5/6 = fire air / fire ground / select, as the guide's Default Controls (⌘, ⌥, Space; p17);
    /// the select bit (6) appears in de02–de04 and never in de01 (p11).
    func testButtonMappingMatchesGuideAndFilms() throws {
        XCTAssertEqual(KeyTable.slotBits, [.up, .left, .right, .down, .fireAir, .fireGround, .select])
        let t = KeyTable(prefs: .fresh)
        XCTAssertEqual(t.input(HeldKeys(held: [0x37]), player: 0), .fireAir)
        XCTAssertEqual(t.input(HeldKeys(held: [0x3A]), player: 0), .fireGround)
        XCTAssertEqual(t.input(HeldKeys(held: [0x31]), player: 0), .select)
        XCTAssertEqual(PlayerInput.select.rawValue, 0x40)
        let index = try RealData.index()
        var census: [Int] = []
        for id in ["de01", "de02", "de03", "de04"] {
            let r = try XCTUnwrap(index.record(type: FourCC("film")!, id: FourCC(id)!), id)
            let f = try Film(data: try index.data(for: r))
            census.append(f.players[0].inputs.filter { $0 & 0x40 != 0 }.count)
        }
        XCTAssertEqual(census, [0, 15, 26, 3])
    }
}
