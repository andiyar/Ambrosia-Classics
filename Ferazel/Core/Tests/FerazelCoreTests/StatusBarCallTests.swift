import XCTest
@testable import FerazelCore

/// HU (docs/plans/2026-10-24-ferazel-phase4.md): the status-bar calls as Core makes them — `.UpdateStatusBar(p1, p2,
/// p3) @ 100095dc` (M l. 4842–4921) at each named call site with `.UpdateHealthMagic`'s G writes, caches and
/// suffocation tick (M l. 4361–4580), the key step (`stepSelection`, the 12-call repeat counter `*_DAT_1009fd9c`), and
/// the direct `.UpdateItemStat()` / `.UpdateTextStats(0)`; one flow-wide set of these globals.
final class StatusBarCallTests: XCTestCase {

    private func state(_ op: DrawOp) -> StatusBarState? {
        if case .statusBar(let s) = op { return s }
        return nil
    }

    private func call(_ op: DrawOp) -> StatusBarCall? { state(op)?.call }

    func testCallSiteParams() throws {
        var calls = StatusBarCalls()
        var g = GameGlobals.initGameGlobals(previous: nil)
        func make(_ site: StatusBarCalls.Site) -> StatusBarCall? {
            call(calls.update(site, globals: &g, actions: [], levelName: "x").op)
        }
        // `.GameLoop` M l. 5216: (0, 0, 0) — the full redraw.
        XCTAssertEqual(make(.levelStart), StatusBarCall())
        XCTAssertEqual(make(.levelStart)?.partial, false)
        // M l. 5280: (1, 0, 0) — nothing changed since the last call: `.UpdateHealthMagic` returns at once (M l.
        // 4417–4422), neither bar part runs.
        XCTAssertEqual(make(.loopIteration), StatusBarCall(partial: true, healthBar: false, magicBar: false))
        // `.MoveSelectedItemToFront` M l. 39704: (1, 1, 0).
        XCTAssertEqual(make(.moveSelectedItemToFront),
                       StatusBarCall(partial: true, forceItems: true, healthBar: false, magicBar: false))
        // The (0, 0, 0) sites: `.CheckGameLoopKeys` (M l. 3919–4011), `.ChapterScreen` (5087), `.SavePointSave`
        // (6492), the map's entry, first frame and idle calls (67505, 67539, 67579); the map's walk call (67585) (1,0,0).
        for site: StatusBarCalls.Site in [.escapeCancel, .confirmOK, .confirmCancel, .optionsClosed, .chapterScreen,
                                          .savePointSave, .mapEntry, .mapFirstFrame, .mapIdle] {
            XCTAssertEqual(make(site), StatusBarCall(), "\(site)")
        }
        XCTAssertEqual(make(.mapIteration), StatusBarCall(partial: true, healthBar: false, magicBar: false))
        // param_3: `.UpdateHealthMagic(1)` whatever param_1 (M l. 4878–4883) — a (0, 0, 1) takes the cached path.
        XCTAssertEqual(call(calls.update(p1: false, p2: false, p3: true, globals: &g, actions: [], levelName: "x").op),
                       StatusBarCall(forceBars: true, healthBar: false, magicBar: false))
        // The direct calls: `.UpdateItemStat()` (M l. 66311, 66325) and `.UpdateTextStats(0)` (M l. 66284).
        XCTAssertEqual(call(calls.itemStat(globals: &g, levelName: "x")), StatusBarCall(itemsOnly: true))
        XCTAssertEqual(call(calls.textStats(globals: g, levelName: "x")), StatusBarCall(textOnly: true))
        // The op carries G's inventory, maxima and suffocation and the flow-wide flashes.
        g.maxHealth = 0x2a0
        g.suffocation = 7
        g.inventory[1].count = 3
        calls.flashes = StatusBarCalls.Flashes(health: 4, magic: 5, item: 6, itemSlot: 1, itemMode: 1)
        let s = state(calls.update(.loopIteration, globals: &g, actions: [], levelName: "x").op)
        XCTAssertEqual(s?.maxHealth, 0x2a0)
        XCTAssertEqual(s?.suffocation, 7)
        XCTAssertEqual(s?.inventory, g.inventory)
        XCTAssertEqual(s.map { [$0.healthFlash, $0.magicFlash, $0.itemFlash, $0.itemFlashSlot, $0.itemFlashMode] },
                       [4, 5, 6, 1, 1])
        XCTAssertEqual(s.map { [$0.call.healthBar, $0.call.magicBar] }, [true, true])   // the flashes run

        // `.UpdateHealthMagic`'s G writes (M l. 4409–4416, 4426–4428): health / magic down to their maxima on every
        // call, before the early return; the breath down to the health when the health part runs.
        calls.flashes = StatusBarCalls.Flashes()
        g.maxHealth = 0x230
        g.health = 0x300
        g.maxMagic = 0x100
        g.magic = 0x180
        g.breath = 0x290
        let clamped = state(calls.update(.loopIteration, globals: &g, actions: [], levelName: "x").op)
        XCTAssertEqual([g.health, g.magic, g.breath], [0x230, 0x100, 0x230])
        XCTAssertEqual(clamped.map { [$0.health, $0.magic, $0.breath] }, [0x230, 0x100, 0x230])
        XCTAssertEqual([calls.healthCache, calls.magicCache, calls.breathCache, calls.suffocationCache],
                       [0x230, 0x100, 0x230, 7])
        g.health = 0x300                                                     // the clamp before the early return
        XCTAssertEqual(call(calls.update(.loopIteration, globals: &g, actions: [], levelName: "x").op)?.healthBar, false)
        XCTAssertEqual(g.health, 0x230)

        // The suffocation tick (M l. 4486–4493): breath < 1, G+8 ≥ 1 and G+8 mod 10 == 9 while the health part runs.
        g.breath = 0
        g.suffocation = 9
        XCTAssertEqual(calls.update(.loopIteration, globals: &g, actions: [], levelName: "x").suffocationTick, true)
        // G+8 19 with health and breath unchanged: the health part is skipped (G+8 not tested, M l. 4423–4424) — no
        // tick; with param_1 0 it runs and ticks.
        g.suffocation = 19
        let skipped = calls.update(.loopIteration, globals: &g, actions: [], levelName: "x")
        XCTAssertEqual([skipped.suffocationTick, call(skipped.op)?.healthBar], [false, false])
        XCTAssertEqual(calls.update(.levelStart, globals: &g, actions: [], levelName: "x").suffocationTick, true)
        g.suffocation = 18
        XCTAssertEqual(calls.update(.levelStart, globals: &g, actions: [], levelName: "x").suffocationTick, false)

        // A call outside the frame loop (the level start, M l. 5216): `.STPlayRegSound(snd 442, 1, 0x100)` goes out
        // with the call's own output at once (M l. 4492) — not into the next frame's sound calls.
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let session = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1, hostedByLevelRun: true)
        session.world.globals.breath = 0
        session.world.globals.suffocation = 29
        let start = session.startOps()
        let tick = SoundCues.convert(PlayerState.SoundCall(cue: PlayerCue(call: .reg, snd: 442, priority: 1,
                                                                          volume: 0x100), scrollH: 0, scrollV: 0),
                                     prefs: FerazelPrefs())
        guard case .play(let cue)? = tick else { return XCTFail("snd 442 plays with sound on") }
        XCTAssertEqual(start.sounds, [cue])
        XCTAssertTrue(session.world.player.soundCalls.isEmpty)
        // The three flash countdowns are the flow-wide set's: row 13 counts each down once a frame (M l. 44728–44736).
        session.world.statusBar.flashes = StatusBarCalls.Flashes(health: 3, magic: 5, item: 7, itemSlot: 2, itemMode: 1)
        _ = session.step(keys: KeyState())
        XCTAssertEqual(session.world.statusBar.flashes,
                       StatusBarCalls.Flashes(health: 2, magic: 4, item: 6, itemSlot: 2, itemMode: 1))
    }

    /// BC39: the world map's calls step the selection too. Next (key 8, default key code 0x5c) held from the second
    /// loop iteration on: its idle call (M l. 67579) steps 0 → 1 of [spell 0, item 0]; the next 12 calls (67585, then
    /// 67579 / 67585 pairs) only count the repeat counter down (12 → 0); the 13th steps again (1 → 2, empty → 0). The
    /// counter is one flow-wide global: the map's goes on in the next level's session (`LevelCarry.statusBar`).
    func testEveryCallStepsSelection() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.unlocked[1] = 1
        var fade = ScreenFade()
        fade.faded = true
        let name = try LevelFile.load(from: r, level: 1).header.name
        var flowWide = StatusBarCalls()
        flowWide.flashes.item = 5                                           // left running by the last level
        let run = try WorldMapRun(resources: r, prefs: FerazelPrefs(), globals: g, level: 1, levelName: name,
                                  exit1: -1, exit2: -1, levelComplete: true, seed: 1, fade: fade, music: MusicFade(),
                                  sprites: [], statusBar: flowWide)
        var t: UInt32 = 1000
        // No key until the first loop iteration has run.
        var first: [StatusBarState] = []
        while run.iterations < 1 && t < 4000 {
            let out = run.tick(now: t, input: FrontInput())
            for op in out.ops { if case .draw(.statusBar(let s), port: .screen) = op { first.append(s) } }
            t += 1
        }
        XCTAssertEqual(run.iterations, 1)
        XCTAssertEqual(run.globals.selectedSlot, 0)
        XCTAssertEqual(first.first?.itemFlash, 5)                           // the map shows the flow's flash, uncounted
        XCTAssertEqual(run.statusCalls.flashes.item, 5)
        let next = FrontInput(keys: KeyState(pressed: [Int(FerazelPrefs.defaultKeys[8])]))
        var bars: [StatusBarState] = []
        while bars.count < 14 && t < 6000 {
            let out = run.tick(now: t, input: next)
            for op in out.ops { if case .draw(.statusBar(let s), port: .screen) = op { bars.append(s) } }
            t += 1
        }
        XCTAssertEqual(bars.count, 14)
        // The idle call first (param_1 0), then the walk-free iteration's (1, 0, 0), alternating.
        XCTAssertEqual(bars.prefix(4).map(\.call.partial), [false, true, false, true])
        XCTAssertEqual(bars[0].call.stepped, true)
        XCTAssertEqual(bars[0].selectedSlot, 1)
        XCTAssertEqual(bars[1...12].map(\.call.stepped), [Bool](repeating: false, count: 12))
        XCTAssertEqual(bars[1...12].map(\.selectedSlot), [Int](repeating: 1, count: 12))
        XCTAssertEqual(bars[13].call.stepped, true)
        XCTAssertEqual(bars[13].selectedSlot, 0)
        XCTAssertEqual(run.globals.selectedSlot, 0)
        XCTAssertEqual(run.statusCalls.repeatCounter, 12)
        // Map → level: the next session takes the same globals; next still held, its first call counts 12 → 11.
        var carry = LevelCarry()
        carry.globals = run.globals
        carry.statusBar = run.statusCalls
        let session = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1, carry: carry)
        let op = session.updateStatusBar(.levelStart, keys: next.keys).draws[0]
        XCTAssertEqual(call(op)?.stepped, false)
        XCTAssertEqual(session.world.statusBar.repeatCounter, 11)
        XCTAssertEqual(session.carry.statusBar, session.world.statusBar)
    }

    /// `.UpdateStatusBar(1, 0, 0)` returns before `.UpdateItemStat` when nothing stepped and no item flash runs
    /// (M l. 4913–4916); a flash of 3 redraws it. The `== 2 ∧ +8 → 3` store (M l. 4748–4750) is made only when it runs,
    /// and the op carries the inventory as the call read it (the big icon is drawn before the store).
    func testItemStatGate() {
        var calls = StatusBarCalls()
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.inventory[2] = InventorySlot(id: 2, count: 1, field4: -1, field6: 0, isSpell: 1)
        func update(_ site: StatusBarCalls.Site, _ actions: InputActions = []) -> StatusBarState? {
            state(calls.update(site, globals: &g, actions: actions, levelName: "x").op)
        }
        let quiet = update(.loopIteration)
        XCTAssertEqual(quiet?.call.stepped, false)
        XCTAssertEqual(quiet?.drawsItems, false)
        XCTAssertEqual(g.inventory[2].id, 2)                              // no `.UpdateItemStat`, no store
        calls.flashes = StatusBarCalls.Flashes(item: 3, itemSlot: 1)
        let lit = update(.loopIteration)
        XCTAssertEqual(lit?.drawsItems, true)
        XCTAssertEqual(lit?.inventory[2].id, 2)                           // as read
        XCTAssertEqual(g.inventory[2].id, 3)                              // the G write
        // A flash of 1 still redraws (`< 1` is the test); 0 does not; param_2 forces it; param_1 0 always.
        calls.flashes = StatusBarCalls.Flashes(item: 1)
        XCTAssertEqual(update(.loopIteration)?.drawsItems, true)
        calls.flashes = StatusBarCalls.Flashes()
        XCTAssertEqual(update(.moveSelectedItemToFront)?.drawsItems, true)
        XCTAssertEqual(update(.levelStart)?.drawsItems, true)
        // A step redraws: previous (key 7) from 0 wraps to the last filled slot, 2.
        let stepped = update(.loopIteration, .previousItem)
        XCTAssertEqual(stepped?.call.stepped, true)
        XCTAssertEqual(stepped?.drawsItems, true)
        XCTAssertEqual(stepped?.selectedSlot, 2)
        XCTAssertEqual(calls.repeatCounter, 12)
        XCTAssertEqual(state(calls.textStats(globals: g, levelName: "x"))?.drawsItems, false)
    }
}
