import XCTest
@testable import FerazelCore

/// HU (docs/plans/2026-10-24-ferazel-phase4.md): the status-bar calls as Core makes them — `.UpdateStatusBar(p1, p2,
/// p3) @ 100095dc` (M l. 4842–4921) at each named call site with the key step (`stepSelection`, the 12-call repeat
/// counter `*_DAT_1009fd9c`), and the direct `.UpdateItemStat()` / `.UpdateTextStats(0)`.
final class StatusBarCallTests: XCTestCase {

    private func call(_ op: DrawOp) -> StatusBarCall? {
        if case .statusBar(let s) = op { return s.call }
        return nil
    }

    private func state(_ op: DrawOp) -> StatusBarState? {
        if case .statusBar(let s) = op { return s }
        return nil
    }

    func testCallSiteParams() {
        var calls = StatusBarCalls()
        var g = GameGlobals.initGameGlobals(previous: nil)
        func make(_ site: StatusBarCalls.Site) -> StatusBarCall? {
            call(calls.update(site, globals: &g, actions: [], levelName: "x"))
        }
        // `.GameLoop` M l. 5216: (0, 0, 0) — the full redraw.
        XCTAssertEqual(make(.levelStart), StatusBarCall())
        XCTAssertEqual(make(.levelStart)?.partial, false)
        // M l. 5280: (1, 0, 0).
        XCTAssertEqual(make(.loopIteration), StatusBarCall(partial: true))
        // `.MoveSelectedItemToFront` M l. 39704: (1, 1, 0).
        XCTAssertEqual(make(.moveSelectedItemToFront), StatusBarCall(partial: true, forceItems: true))
        // The (0, 0, 0) sites: `.CheckGameLoopKeys` (M l. 3919–4011), `.ChapterScreen` (5087), `.SavePointSave`
        // (6492), the map's entry, first frame and idle calls (67505, 67539, 67579); the map's walk call (67585) (1,0,0).
        for site: StatusBarCalls.Site in [.escapeCancel, .confirmOK, .confirmCancel, .optionsClosed, .chapterScreen,
                                          .savePointSave, .mapEntry, .mapFirstFrame, .mapIdle] {
            XCTAssertEqual(make(site), StatusBarCall(), "\(site)")
        }
        XCTAssertEqual(make(.mapIteration), StatusBarCall(partial: true))
        // The direct calls: `.UpdateItemStat()` (M l. 66311, 66325) and `.UpdateTextStats(0)` (M l. 66284).
        XCTAssertEqual(call(StatusBarCalls.itemStat(globals: &g, levelName: "x")), StatusBarCall(itemsOnly: true))
        XCTAssertEqual(call(StatusBarCalls.textStats(globals: g, levelName: "x")), StatusBarCall(textOnly: true))
        // The op carries G's inventory, maxima and suffocation and the flashes it was given.
        g.maxHealth = 0x2a0
        g.suffocation = 7
        g.inventory[1].count = 3
        let flashes = StatusBarCalls.Flashes(health: 4, magic: 5, item: 6, itemSlot: 1, itemMode: 1)
        let s = state(calls.update(.loopIteration, globals: &g, actions: [], flashes: flashes, levelName: "x"))
        XCTAssertEqual(s?.maxHealth, 0x2a0)
        XCTAssertEqual(s?.suffocation, 7)
        XCTAssertEqual(s?.inventory, g.inventory)
        XCTAssertEqual(s.map { [$0.healthFlash, $0.magicFlash, $0.itemFlash, $0.itemFlashSlot, $0.itemFlashMode] },
                       [4, 5, 6, 1, 1])
    }

    /// BC39: the world map's calls step the selection too. Next (key 8, default key code 0x5c) held from the second
    /// loop iteration on: its idle call (M l. 67579) steps 0 → 1 of [spell 0, item 0]; the next 12 calls (67585, then
    /// 67579 / 67585 pairs) only count the repeat counter down (12 → 0); the 13th steps again (1 → 2, empty → 0).
    func testEveryCallStepsSelection() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.unlocked[1] = 1
        var fade = ScreenFade()
        fade.faded = true
        let name = try LevelFile.load(from: r, level: 1).header.name
        let run = try WorldMapRun(resources: r, prefs: FerazelPrefs(), globals: g, level: 1, levelName: name,
                                  exit1: -1, exit2: -1, levelComplete: true, seed: 1, fade: fade, music: MusicFade(),
                                  sprites: [])
        var t: UInt32 = 1000
        // No key until the first loop iteration has run.
        while run.iterations < 1 && t < 4000 {
            _ = run.tick(now: t, input: FrontInput())
            t += 1
        }
        XCTAssertEqual(run.iterations, 1)
        XCTAssertEqual(run.globals.selectedSlot, 0)
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
    }

    /// `.UpdateStatusBar(1, 0, 0)` returns before `.UpdateItemStat` when nothing stepped and no item flash runs
    /// (M l. 4913–4916); a flash of 3 redraws it. The `== 2 ∧ +8 → 3` store (M l. 4748–4750) is made only when it runs,
    /// and the op carries the inventory as the call read it (the big icon is drawn before the store).
    func testItemStatGate() {
        var calls = StatusBarCalls()
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.inventory[2] = InventorySlot(id: 2, count: 1, field4: -1, field6: 0, isSpell: 1)
        let quiet = state(calls.update(.loopIteration, globals: &g, actions: [], levelName: "x"))
        XCTAssertEqual(quiet?.call.stepped, false)
        XCTAssertEqual(quiet?.drawsItems, false)
        XCTAssertEqual(g.inventory[2].id, 2)                              // no `.UpdateItemStat`, no store
        let flash = StatusBarCalls.Flashes(health: 0, magic: 0, item: 3, itemSlot: 1, itemMode: 0)
        let lit = state(calls.update(.loopIteration, globals: &g, actions: [], flashes: flash, levelName: "x"))
        XCTAssertEqual(lit?.drawsItems, true)
        XCTAssertEqual(lit?.inventory[2].id, 2)                           // as read
        XCTAssertEqual(g.inventory[2].id, 3)                              // the G write
        // A flash of 1 still redraws (`< 1` is the test); 0 does not; param_2 forces it; param_1 0 always.
        XCTAssertEqual(state(calls.update(.loopIteration, globals: &g, actions: [],
                                          flashes: StatusBarCalls.Flashes(health: 0, magic: 0, item: 1, itemSlot: 0,
                                                                          itemMode: 0),
                                          levelName: "x"))?.drawsItems, true)
        XCTAssertEqual(state(calls.update(.moveSelectedItemToFront, globals: &g, actions: [], levelName: "x"))?
            .drawsItems, true)
        XCTAssertEqual(state(calls.update(.levelStart, globals: &g, actions: [], levelName: "x"))?.drawsItems, true)
        // A step redraws: previous (key 7) from 0 wraps to the last filled slot, 2.
        let stepped = state(calls.update(.loopIteration, globals: &g, actions: .previousItem, levelName: "x"))
        XCTAssertEqual(stepped?.call.stepped, true)
        XCTAssertEqual(stepped?.drawsItems, true)
        XCTAssertEqual(stepped?.selectedSlot, 2)
        XCTAssertEqual(calls.repeatCounter, 12)
        XCTAssertEqual(state(StatusBarCalls.textStats(globals: g, levelName: "x"))?.drawsItems, false)
    }
}
