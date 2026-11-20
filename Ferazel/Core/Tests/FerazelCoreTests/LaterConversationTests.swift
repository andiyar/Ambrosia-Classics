import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-MC (docs/superpowers/plans/2026-11-04-ferazel-remainder.md): the six conversations of levels 10–22 — `Mcnv` 206
/// and 220 (level 11), 260, 261 and 300 (level 21), 221 (level 22); later-levels ledger §5 and §4 item 4 — run to their
/// end through `ConversationRun` (`.Conversation`, `.HandleConvLine`, `.HandleLineActions`; M l. 65440–66560,
/// conversations-mcnv §3) with their portraits drawn from the level chain, every condition and action they use taking
/// its effect (`ConvActions`, M l. 66164–66376). Standalone from the data files: each talker's record read from its
/// level file, its sprite made by its Setup into a world over those records; no level is opened. One G is carried
/// through the story in the game's order (Nimbo, the arm-hurt character, Dimbo, Dimbo saved, Nimbo again), as the
/// globals carry across a level exit. A missing data file is a FAILURE, never a skip.
final class LaterConversationTests: XCTestCase {

    private static let anyKey = 0x01                                   // 'S' (any key but A, which `IsAnyKeyDown` skips)
    private static let returnKey = 0x24
    private static var downKey: Int { Int(FerazelPrefs().keys[3]) }

    /// One talker: the level, its record, and the ledger's (type, flag, Mcnv) for it (LL §5).
    private struct Talker {
        let level: Int
        let record: Int
        let type: Int16
        let flag: UInt8
        let mcnv: Int16
    }

    private static let nimbo = Talker(level: 11, record: 135, type: 2955, flag: 1, mcnv: 206)
    private static let dimboSaved = Talker(level: 11, record: 283, type: 2956, flag: 99, mcnv: 220)
    private static let grave2 = Talker(level: 21, record: 89, type: 2834, flag: 1, mcnv: 261)
    private static let grave1 = Talker(level: 21, record: 207, type: 2833, flag: 1, mcnv: 260)
    private static let obfusc = Talker(level: 21, record: 318, type: 2962, flag: 1, mcnv: 300)
    private static let dimbo = Talker(level: 22, record: 405, type: 2956, flag: 1, mcnv: 221)

    /// A world over `t`'s level records with its talker's sprite made by its Setup (record index kept, `+0x48`); the
    /// conversation id is the record's p1, as `.HitPlayerSprite`'s talker arms hand it on.
    private func world(_ r: FerazelResources, _ t: Talker, globals: GameGlobals? = nil) throws
        -> (world: SpriteWorld, sprite: Int, id: Int16) {
        let L = try LevelFile.load(from: r, level: Int16(t.level))
        let p = L.placements[t.record]
        XCTAssertEqual([p.type, Int16(p.flag)], [t.type, Int16(t.flag)], "L\(t.level) rec \(t.record)")
        let w = SpriteWorld(level: L)
        if let g = globals { w.globals = g }
        var slot = try SetupFaces.setup(p, context: SetupFaces.Context(level: L, playerX: 0)).slot
        slot.recordIndex = Int16(t.record)
        return (w, w.active.insert(slot), p.p1)
    }

    /// One run of `t`'s conversation to its end: "press any key" answered by one tick of a key, each menu key wait by
    /// the next of `menu`. The run, and every draw it made.
    private func talk(_ r: FerazelResources, _ t: Talker, world w: SpriteWorld, sprite: Int, id: Int16,
                      menu: [Int] = [], save: inout SaveBlock) throws -> (run: ConversationRun, draws: [DrawOp]) {
        XCTAssertEqual(id, t.mcnv, "L\(t.level) rec \(t.record) p1")
        let c = ConversationRun(.conversation(id: id, record: t.record, sprite: sprite), world: w, resources: r,
                                prefs: FerazelPrefs(), levelName: w.level.header.name)
        var keys = menu
        var draws: [DrawOp] = []
        var now: UInt32 = 5000
        for _ in 0..<40000 where !c.isDone {
            var input = FrontInput()
            switch c.wait {
            case .anyKey: input.keys = KeyState(pressed: [Self.anyKey])
            case .menuKey:
                guard !keys.isEmpty else {
                    XCTFail("Mcnv \(id): a menu with no key left")
                    return (c, draws)
                }
                input.keys = KeyState(pressed: [keys.removeFirst()])
            case .dialog:
                XCTFail("Mcnv \(id): the load error")
                return (c, draws)
            default: break
            }
            draws += c.tick(now: now, input: input, save: &save).draws
            now &+= 1
        }
        XCTAssertTrue(c.isDone, "Mcnv \(id) did not end")
        XCTAssertFalse(c.aborted, "Mcnv \(id)")
        XCTAssertEqual(c.index, 20, "Mcnv \(id): its last line's next 21 → index 20, the end")
        XCTAssertEqual(draws.last, .restoreView, "Mcnv \(id)")
        XCTAssertTrue(keys.isEmpty, "Mcnv \(id): menu keys left over")
        return (c, draws)
    }

    /// The portrait PICTs a run drew (every `copyPicture` but the frame, PICT 4000), each checked against its PICT's
    /// frame on the level chain — drawn only because it was found there (`ConversationRun.frame`).
    private func portraits(_ r: FerazelResources, _ draws: [DrawOp]) -> Set<Int16> {
        var ids = Set<Int16>()
        for op in draws {
            guard case .copyPicture(let id, let chain, let source, _, nil, _) = op, id != ConversationRun.framePict else {
                continue
            }
            XCTAssertEqual(chain, .level)
            guard let res = r.resource(type: "PICT", id: id, chain: .level) else {
                XCTFail("PICT \(id) drawn but not on the level chain")
                continue
            }
            let b = [UInt8](res.data.prefix(10))
            func i16(_ o: Int) -> Int16 { Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1])) }
            if source.top == i16(2) && source.left == i16(4) {      // the whole picture (not an erase's sub-rect)
                XCTAssertEqual([source.bottom, source.right], [i16(6), i16(8)], "PICT \(id) frame")
                XCTAssertGreaterThan(source.bottom - source.top, 0, "PICT \(id)")
                XCTAssertGreaterThan(source.right - source.left, 0, "PICT \(id)")
                XCTAssertGreaterThan(res.data.count, 512, "PICT \(id): a real picture")
            }
            ids.insert(id)
        }
        return ids
    }

    func testLevels10To22ConversationsRunToEnd() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let talkers = [Self.nimbo, Self.dimboSaved, Self.grave2, Self.grave1, Self.obfusc, Self.dimbo]

        // The opcodes each conversation's lines use (condition `+0x70c`, actions `+0x71c` / `+0x722`), against LL §5.
        let ledger: [Int16: (conditions: [Int16], actions: [Int16])] = [
            206: ([4, 5], [1, 2, 4, 5]), 220: ([], []), 261: ([], []), 260: ([], []), 300: ([5], []), 221: ([5], [5, 9, 10]),
        ]
        var allConditions = Set<Int16>(), allActions = Set<Int16>()
        for t in talkers {
            let lines = try Conversation.load(from: r, id: t.mcnv).lines
            let conds = Set(lines.map(\.conditionType)).subtracting([0])
            let acts = Set(lines.flatMap { [$0.action1.type, $0.action2.type] }).subtracting([0])
            XCTAssertEqual(conds.sorted(), ledger[t.mcnv]?.conditions, "Mcnv \(t.mcnv) conditions")
            XCTAssertEqual(acts.sorted(), ledger[t.mcnv]?.actions, "Mcnv \(t.mcnv) actions")
            allConditions.formUnion(conds)
            allActions.formUnion(acts)
        }
        XCTAssertEqual(allConditions.sorted(), [4, 5])
        XCTAssertEqual(allActions.sorted(), [1, 2, 4, 5, 9, 10])

        var drawn: [Int16: Set<Int16>] = [:]
        var save = SaveBlock()

        // The story, one G carried. (a) Nimbo, first visit: #20 world flag 1 ≠ 1 (cond 5 false) → #9 flag 6 ≠ 1 → #16
        // own p2 low byte 0 (cond 4 false) → #1 … #8; #1 / #3 action 4 (own p2 = 1), #2 action 5 (flag 5 = 1).
        let l11 = try world(r, Self.nimbo)
        var g = l11.world.globals
        XCTAssertEqual(g.worldFlags[1], 0)
        XCTAssertEqual(g.worldFlags[5], 0)
        XCTAssertEqual(g.worldFlags[6], 0)
        var (c, d) = try talk(r, Self.nimbo, world: l11.world, sprite: l11.sprite, id: l11.id, save: &save)
        XCTAssertEqual(c.shown, Array(1...8))
        XCTAssertEqual(l11.world.records[Self.nimbo.record].p2, 1)
        XCTAssertEqual(l11.world.globals.worldFlags[5], 1)
        drawn[206, default: []].formUnion(portraits(r, d))
        // (b) Nimbo again, same level: #16's own p2 is now 1 (cond 4 true) → #7, #8.
        (c, d) = try talk(r, Self.nimbo, world: l11.world, sprite: l11.sprite, id: l11.id, save: &save)
        XCTAssertEqual(c.shown, [7, 8])
        drawn[206, default: []].formUnion(portraits(r, d))
        g = l11.world.globals

        // (c) Level 21's arm-hurt character with flag 5 set: #4's cond 5 true → #5 (Ferazel, 4001), #6, #7.
        let l21 = try world(r, Self.obfusc, globals: g)
        (c, d) = try talk(r, Self.obfusc, world: l21.world, sprite: l21.sprite, id: l21.id, save: &save)
        XCTAssertEqual(c.shown, [1, 2, 3, 4, 5, 6, 7])
        drawn[300, default: []].formUnion(portraits(r, d))
        g = l21.world.globals

        // (d) Dimbo on level 22, flag 5 set: #20 cond 5 true → #5 … #9; #7 action 5 (flag 6 = 1), #8 action 9 (the
        // talker killed, its record's spawn byte 0) and action 10 (level 11's snapshot record 283 armed: spawn byte 1).
        let l22 = try world(r, Self.dimbo, globals: g)
        XCTAssertEqual(save.snapshots[11][283].flag, 0)
        (c, d) = try talk(r, Self.dimbo, world: l22.world, sprite: l22.sprite, id: l22.id, save: &save)
        XCTAssertEqual(c.shown, [5, 6, 7, 8, 9])
        XCTAssertEqual(l22.world.globals.worldFlags[6], 1)
        XCTAssertEqual(l22.world.active.record(id: l22.sprite)?.dead, true)
        XCTAssertEqual(l22.world.records[Self.dimbo.record].flag, 0)
        XCTAssertEqual(save.snapshots[11][Self.dimboSaved.record].flag, 1)
        XCTAssertEqual(save.snapshots[11].filter { $0.flag != 0 }.count, 1)
        drawn[221, default: []].formUnion(portraits(r, d))
        g = l22.world.globals

        // (e) Dimbo saved, back on level 11 (the record action 10 armed): one line, no opcode.
        let saved = try world(r, Self.dimboSaved, globals: g)
        (c, d) = try talk(r, Self.dimboSaved, world: saved.world, sprite: saved.sprite, id: saved.id, save: &save)
        XCTAssertEqual(c.shown, [1])
        drawn[220, default: []].formUnion(portraits(r, d))
        // (f) Nimbo with flag 6 set: #9 cond 5 true → #10, whose cond 5 (flag 4 = 1) is false → #11.
        let back = try world(r, Self.nimbo, globals: saved.world.globals)
        (c, d) = try talk(r, Self.nimbo, world: back.world, sprite: back.sprite, id: back.id, save: &save)
        XCTAssertEqual(c.shown, [10, 11])
        drawn[206, default: []].formUnion(portraits(r, d))
        // (g) Flag 4 set by hand (no line of levels 10–22 sets it): #10 → #17, action 2 × 2 — items 6 and 26 × 99
        // into the first empty slots.
        var g4 = back.world.globals
        g4.worldFlags[4] = 1
        let gifts = try world(r, Self.nimbo, globals: g4)
        let empties = g4.inventory.indices.filter { g4.inventory[$0].id == -1 }
        (c, d) = try talk(r, Self.nimbo, world: gifts.world, sprite: gifts.sprite, id: gifts.id, save: &save)
        XCTAssertEqual(c.shown, [10, 17])
        let inv = gifts.world.globals.inventory
        XCTAssertEqual([inv[empties[0]].id, inv[empties[0]].count, Int16(inv[empties[0]].isSpell)], [6, 99, 0])
        XCTAssertEqual([inv[empties[1]].id, inv[empties[1]].count, Int16(inv[empties[1]].isSpell)], [26, 99, 0])
        drawn[206, default: []].formUnion(portraits(r, d))

        // (h) Nimbo after a theft (flag 1 set, 300 coins): #20 cond 5 true → #12's menu; reply 1 "…" → #13, action 1
        // (coins −250) and action 5 (flag 1 = 0), next 6 → #6, #7, #8. (i) Reply 2 → #15, nothing taken.
        var thief = GameGlobals(header: l11.world.level.header)
        thief.worldFlags[1] = 1
        thief.coins = 300
        let pay = try world(r, Self.nimbo, globals: thief)
        (c, d) = try talk(r, Self.nimbo, world: pay.world, sprite: pay.sprite, id: pay.id, menu: [Self.returnKey],
                          save: &save)
        XCTAssertEqual(c.shown, [12, 13, 6, 7, 8])
        XCTAssertEqual(pay.world.globals.coins, 50)
        XCTAssertEqual(pay.world.globals.worldFlags[1], 0)
        XCTAssertTrue(d.contains { if case .statusBar(let b) = $0 { b.coins == 50 } else { false } })
        drawn[206, default: []].formUnion(portraits(r, d))
        let refuse = try world(r, Self.nimbo, globals: thief)
        (c, d) = try talk(r, Self.nimbo, world: refuse.world, sprite: refuse.sprite, id: refuse.id,
                          menu: [Self.downKey, Self.returnKey], save: &save)
        XCTAssertEqual(c.shown, [12, 15])
        XCTAssertEqual(refuse.world.globals.coins, 300)
        XCTAssertEqual(refuse.world.globals.worldFlags[1], 1)
        drawn[206, default: []].formUnion(portraits(r, d))

        // (j) The arm-hurt character and (k) Dimbo with flag 5 clear: #4 false → #7; #20 false → #1 only, nothing
        // changed. (l) The two graves: one line each.
        let fresh21 = try world(r, Self.obfusc)
        (c, d) = try talk(r, Self.obfusc, world: fresh21.world, sprite: fresh21.sprite, id: fresh21.id, save: &save)
        XCTAssertEqual(c.shown, [1, 2, 3, 4, 7])
        XCTAssertEqual(portraits(r, d), [4022])
        let fresh22 = try world(r, Self.dimbo)
        var untouched = SaveBlock()
        (c, d) = try talk(r, Self.dimbo, world: fresh22.world, sprite: fresh22.sprite, id: fresh22.id, save: &untouched)
        XCTAssertEqual(c.shown, [1])
        XCTAssertEqual(fresh22.world.active.record(id: fresh22.sprite)?.dead, false)
        XCTAssertEqual(fresh22.world.records[Self.dimbo.record].flag, 1)
        XCTAssertEqual(fresh22.world.globals.worldFlags[6], 0)
        XCTAssertEqual(untouched.snapshots[11].filter { $0.flag != 0 }.count, 0)
        XCTAssertEqual(portraits(r, d), [4014])
        for t in [Self.grave2, Self.grave1] {
            let gw = try world(r, t)
            (c, d) = try talk(r, t, world: gw.world, sprite: gw.sprite, id: gw.id, save: &save)
            XCTAssertEqual(c.shown, [1])
            drawn[t.mcnv, default: []].formUnion(portraits(r, d))
        }

        // Every portrait of LL §5 drawn: 206 4001 / 4013, 220 4014, 261 / 260 4024, 300 4001 / 4022, 221 4001 / 4014.
        XCTAssertEqual(drawn.mapValues { $0.sorted() }, [206: [4001, 4013], 220: [4014], 261: [4024], 260: [4024],
                                                         300: [4001, 4022], 221: [4001, 4014]])
        XCTAssertEqual(Set(drawn.values.flatMap { $0 }).sorted(), [4001, 4013, 4014, 4022, 4024])
    }
}
