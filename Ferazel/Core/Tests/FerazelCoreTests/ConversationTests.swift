import XCTest
import HectorResources
@testable import FerazelCore

/// C1 (docs/plans/2026-10-14-ferazel-phase3.md): conversations and signs in the suspended frame — `.HitPlayerSprite`'s
/// NPC arm (types 0xb87…0xb99, M l. 49199–49210, raw `10056d14..10056d68`) and sign / grave arm (M l. 49287–49303, raw
/// `10056fdc..10057134`), the talk cooldown `*PTR_DAT_100a06cc` (150 / 90), the NPC Handle's rect (M l. 61119–61134),
/// and `ConversationRun` (`.Conversation`, `.HandleConvLine`, `.HandleLineResponses`, `.HandleLineActions`,
/// `.SimpleConv`, the typer; M l. 65440–66560); conversations-mcnv §1–§6 (BC20, BC30). Driven against the committed
/// `Resources/Ferazel` (D26). A missing data file is a FAILURE, never a skip.
final class ConversationTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private final class StubServices: LevelServices {
        func prepare(level: Int) throws -> LevelFaces { LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    private static let signTypes: [Int16] = [0xb56, 0xb57, 0xb58, 0xb59, 0xb5a, 0xb5c, 0xb5d, 0xb11, 0xb12, 0xb13, 0xb14]
    private static let anyKey = 0x01                                   // 'S' (any key but A, which `IsAnyKeyDown` skips)
    private static let escape = 0x35
    private static let returnKey = 0x24
    private static var downKey: Int { Int(FerazelPrefs().keys[3]) }
    private static var upKey: Int { Int(FerazelPrefs().keys[2]) }

    /// A session with the player's origin at the placement's: his hot rect (0x26, 0x22)–(0x3e, 0x55) inside the talker's.
    private func session(_ r: FerazelResources, level: Int, record: Int) throws -> FerazelSession {
        let L = try LevelFile.load(from: r, level: Int16(level))
        let p = L.placements[record]
        return try FerazelSession(resources: r, prefs: FerazelPrefs(), level: level, start: (Int(p.x), Int(p.y)))
    }

    /// Steps until the frame suspends (the special pass reached a talker); the steps taken and the suspension.
    private func stepToTalk(_ s: FerazelSession, max: Int = 400, keys: KeyState = KeyState()) -> (steps: Int,
                                                                                                    FrameSuspension?) {
        for k in 1...max {
            let ops = s.step(keys: keys)
            if let x = ops.suspension { return (k, x) }
        }
        return (max, nil)
    }

    private func run(_ s: FerazelSession, _ x: FrameSuspension?, r: FerazelResources) throws -> ConversationRun {
        let level = s.level.header.name
        switch try XCTUnwrap(x) {
        case .conversation(let id, let record, let sprite):
            return ConversationRun(.conversation(id: id, record: record, sprite: sprite), world: s.world, resources: r,
                                   prefs: FerazelPrefs(), levelName: level)
        case .sign(let text):
            return ConversationRun(.simple(pict: 4020, name: MacRoman.bytes("Wooden Sign"), text: text), world: s.world,
                                   resources: r, prefs: FerazelPrefs(), levelName: level)
        default:
            throw XCTSkip("not a talk suspension")
        }
    }

    /// Ticks `c` to its end: "press any key" answered by one tick of a key, each menu key wait by the next of `menu`
    /// (one tick each), `stopAt` (a predicate) before a tick ends the drive early. Every tick's output.
    @discardableResult
    private func talk(_ c: ConversationRun, from t0: UInt32 = 5000, menu: [Int] = [], save: inout SaveBlock,
                      max: Int = 20000, stopAt: ((ConversationRun) -> Bool)? = nil) -> [FrontOutput] {
        var outs: [FrontOutput] = []
        var keys = menu
        var t = t0
        for _ in 0..<max {
            if c.isDone || stopAt?(c) == true { return outs }
            var input = FrontInput()
            switch c.wait {
            case .anyKey: input.keys = KeyState(pressed: [Self.anyKey])
            case .menuKey:
                guard !keys.isEmpty else {
                    XCTFail("a menu with no key left")
                    return outs
                }
                input.keys = KeyState(pressed: [keys.removeFirst()])
            default: break
            }
            outs.append(c.tick(now: t, input: input, save: &save))
            t &+= 1
        }
        XCTFail("the conversation did not end in \(max) ticks")
        return outs
    }

    // MARK: -

    func testTalkersAndSignsLevels1And2() throws {
        let r = try resources()
        let strings = try StringList.load(from: r, id: 500)
        // (record, type, p1) from World Data; conversations-mcnv §1.2 and the plan's Tests line.
        let signs: [Int: [(Int, Int16, Int16)]] = [1: [(1, 0xb56, 12), (6, 0xb56, 11), (48, 0xb56, 4), (125, 0xb56, 13)],
                                                   2: [(14, 0xb56, 7), (185, 0xb56, 9)]]
        let npcs: [Int: [(Int, Int16, Int16)]] = [1: [(12, 2952, 200), (157, 2951, 201)], 2: [(188, 2954, 203)]]
        for level in [1, 2] {
            let L = try LevelFile.load(from: r, level: Int16(level))
            XCTAssertEqual(L.placements.filter { Self.signTypes.contains($0.type) }.map { ($0.index) },
                           signs[level]!.map(\.0), "level \(level) signs")
            XCTAssertEqual(L.placements.filter { HitPlayerSprite.npcs.contains($0.type) }.map(\.index),
                           npcs[level]!.map(\.0), "level \(level) NPCs")
            for (rec, type, p1) in signs[level]! + npcs[level]! {
                let p = L.placements[rec]
                XCTAssertEqual(p.type, type, "L\(level) rec \(rec)")
                XCTAssertEqual(p.p1, p1, "L\(level) rec \(rec)")
                XCTAssertEqual(p.p4, 0, "L\(level) rec \(rec)")
                // The arm on a direct contact (a fresh session each): the suspension, the cooldown, p4.
                let s = try session(r, level: level, record: rec)
                let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: L, playerX: 0))
                let id = s.world.active.insert(e.slot)
                let pid = try XCTUnwrap(s.world.playerID)
                HitPlayerSprite.hit(s.world, player: pid, other: id)
                if type == 0xb56 {
                    let text = MacRoman.bytes(try XCTUnwrap(strings.string(Int(p1))))
                    XCTAssertEqual(s.world.suspension, .sign(text: text), "L\(level) rec \(rec)")
                    XCTAssertEqual(s.world.player.countdown06cc, 90)
                    XCTAssertEqual(s.world.records[rec].p4, 1)
                } else {
                    XCTAssertEqual(s.world.suspension, .conversation(id: p1, record: rec, sprite: id), "L\(level) rec \(rec)")
                    XCTAssertEqual(s.world.player.countdown06cc, 150)
                    XCTAssertEqual(s.world.records[rec].p4, 0)
                    XCTAssertNoThrow(try Conversation.load(from: r, id: p1))
                }
            }
        }
        // The sign texts the plan names (STR# 500 [12], [11], [4], [13], [7], [9]).
        XCTAssertTrue(strings.string(12)!.hasPrefix("The sign reads, “Sparkly torches and rock piles"))
        XCTAssertTrue(strings.string(11)!.hasPrefix("The sign reads, “Some walls can be destroyed."))
        XCTAssertTrue(strings.string(4)!.hasPrefix("The sign says, “Caution! Dangerous area ahead!”"))
        XCTAssertTrue(strings.string(13)!.hasPrefix("The sign reads, “You can perform a spin jump"))
        XCTAssertTrue(strings.string(7)!.hasPrefix("The sign reads, “Good things come to those who wait.”"))
        XCTAssertTrue(strings.string(9)!.hasPrefix("The sign reads, “Nimbo's Secret Stash!"))
        // The NPC arm's gates: the cooldown blocks; `+0xb0 ≠ 0` blocks; never `.PlatformBounce` (no landing latch).
        let L1 = try LevelFile.load(from: r, level: 1)
        let s = try session(r, level: 1, record: 12)
        let e = try SetupFaces.setup(L1.placements[12], context: SetupFaces.Context(level: L1, playerX: 0))
        let id = s.world.active.insert(e.slot)
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.player.countdown06cc = 1
        HitPlayerSprite.hit(s.world, player: pid, other: id)
        XCTAssertNil(s.world.suspension)
        s.world.player.countdown06cc = 0
        s.world.active.update(id: id) { $0.subtype = 1 }
        HitPlayerSprite.hit(s.world, player: pid, other: id)
        XCTAssertNil(s.world.suspension)
        XCTAssertEqual(s.world.player.countdown06cc, 0)
        // The Handle's NPC arm: face = its single, the hot rect from the face's bounds, one-way, layer 0, gravity 0.
        let bounds = IdleSprites.Rect(top: 3, left: 5, bottom: 60, right: 40)
        BoxSprite.handle(world: s.world, id: id) { _ in bounds }
        let npc = try XCTUnwrap(s.world.active.record(id: id))
        XCTAssertEqual(npc.hotRect, bounds)
        XCTAssertEqual(npc.face, FaceRef(pict: 2952, index: 0, set: .encoded))
        XCTAssertTrue(npc.oneWay)
        XCTAssertEqual(npc.gravity, 0)
        XCTAssertFalse(npc.mirrored)
        // Mcnv 221 #8 (Dimbo, L22): action 9 removes the talker (`+0xe9`, its record's spawn byte 0) and action 10 arms
        // L11's snapshot record 283 (spawn byte 1) — run on this talker and an empty save block.
        let dimbo = try Conversation.load(from: r, id: 221).lines[7]
        XCTAssertEqual([dimbo.action1.type, dimbo.action2.type, dimbo.action2.a, dimbo.action2.b], [9, 10, 283, 11])
        var save = SaveBlock()
        var out = FrontOutput()
        XCTAssertEqual(s.world.records[12].flag, 1)
        for act in [dimbo.action1, dimbo.action2] {
            ConvActions.run(act, record: 12, talker: id, world: s.world, save: &save, prefs: FerazelPrefs(),
                            levelName: "", into: &out)
        }
        XCTAssertEqual(s.world.active.record(id: id)?.dead, true)
        XCTAssertEqual(s.world.records[12].flag, 0)
        XCTAssertEqual(save.snapshots[11][283].flag, 1)
        XCTAssertEqual(save.snapshots[11].filter { $0.flag != 0 }.count, 1)
        // A missing `Mcnv` (L4 rec 88's p1 0): the report with the id as its code, then the end once it is answered.
        let bad = ConversationRun(.conversation(id: 0, record: 88, sprite: id), world: s.world, resources: r,
                                  prefs: FerazelPrefs(), levelName: "")
        let o1 = bad.tick(now: 0, input: FrontInput(), save: &save)
        XCTAssertEqual(o1.requests, [.dialog(.error(text: "Error attempting to load the conversation resource!", code: 0))])
        XCTAssertEqual(bad.wait, .dialog)
        XCTAssertEqual(bad.tick(now: 1, input: FrontInput(), save: &save).requests, [])
        bad.dialogDone()
        let o2 = bad.tick(now: 2, input: FrontInput(), save: &save)
        XCTAssertTrue(bad.isDone)
        XCTAssertEqual(o2.draws.last, .restoreView)
        XCTAssertTrue(bad.shown.isEmpty)
    }

    func testMcnv201FirstVisitAndRevisit() throws {
        let r = try resources()
        let s = try session(r, level: 1, record: 157)
        var save = SaveBlock()
        let (_, x) = stepToTalk(s)
        guard case .conversation(201, 157, _)? = x else { return XCTFail("no Mcnv 201 suspension: \(String(describing: x))") }
        XCTAssertEqual(s.world.player.countdown06cc, 150)
        let c = try run(s, x, r: r)
        talk(c, save: &save)
        XCTAssertEqual(c.shown, Array(1...15))                      // #1, then #2 … #15
        XCTAssertFalse(c.aborted)
        XCTAssertEqual(s.world.records[157].p2, 1)                  // #14 / #15: action 4, own p2 = 1
        XCTAssertNil(s.resume(.conversation).suspension)
        // Still in contact: the next touch is the frame the cooldown reaches 0 — 150 frames later — and plays #16 only.
        let (steps, y) = stepToTalk(s)
        XCTAssertEqual(steps, 150)
        guard case .conversation(201, 157, _)? = y else { return XCTFail("no second Mcnv 201 suspension") }
        let c2 = try run(s, y, r: r)
        talk(c2, save: &save)
        XCTAssertEqual(c2.shown, [16])
        XCTAssertNil(s.resume(.conversation).suspension)
    }

    func testMcnv203FiveLines() throws {
        let r = try resources()
        let s = try session(r, level: 2, record: 188)
        var save = SaveBlock()
        let (_, x) = stepToTalk(s)
        guard case .conversation(203, 188, _)? = x else { return XCTFail("no Mcnv 203 suspension: \(String(describing: x))") }
        let c = try run(s, x, r: r)
        let outs = talk(c, save: &save)
        XCTAssertEqual(c.shown, [1, 2, 3, 4, 5])
        XCTAssertEqual(c.index, 20)                                  // #5's next 21 → index 20: the end
        XCTAssertFalse(c.aborted)
        // The opening copies: the frame (PICT 4000, transparent) at the origin, line #1's portrait 4006 into it and onto
        // the screen; the last draw restores the view.
        let draws = outs.flatMap(\.draws)
        guard case .copyPicture(4000, .level, _, let dest, nil, true)? = draws.first else {
            return XCTFail("the frame copy first")
        }
        XCTAssertEqual(dest, Rect16(top: 46, left: 126, bottom: 354, right: 513))
        XCTAssertEqual(draws.dropFirst().first.map { if case .copyPicture(4006, _, _, _, _, true) = $0 { true } else { false } },
                       true)
        XCTAssertEqual(draws.dropFirst(2).first.map { if case .copyPicture(4006, _, _, _, _, false) = $0 { true } else { false } },
                       true)
        XCTAssertEqual(draws.last, .restoreView)
    }

    func testMcnv200NotEnoughCoins() throws {
        let r = try resources()
        var save = SaveBlock()
        // Coins 0: #20 (own p3 0) → −16 → #16 silently (condition 3, never) → #1 → #3, the menu with 4 replies; reply 2
        // "Got anything…" → #5 the shop; Magic Potion (−17) → #17 silently (fewer than 2 held) → #10 silently (coins ≥ 30:
        // no) → #12 "not enough"; its reply 1 → #9 (own p2 = 1) → the end.
        let s = try session(r, level: 1, record: 12)
        s.world.globals.coins = 0
        let (_, x) = stepToTalk(s)
        guard case .conversation(200, 12, _)? = x else { return XCTFail("no Mcnv 200 suspension: \(String(describing: x))") }
        let mcnv = try Conversation.load(from: r, id: 200)
        XCTAssertEqual(mcnv.lines[2].responseTargets.filter { $0 != 0 }.count, 4)
        let c = try run(s, x, r: r)
        talk(c, menu: [Self.downKey, Self.returnKey, Self.returnKey, Self.returnKey], save: &save)
        XCTAssertEqual(c.shown, [1, 3, 5, 12, 9])
        XCTAssertTrue(mcnv.lines[11].text.hasPrefix("What're you trying to pull, buddy? You don't have"))
        XCTAssertEqual(s.world.globals.coins, 0)
        XCTAssertFalse(s.world.globals.inventory.contains { $0.id == 4 && $0.isSpell == 0 })
        XCTAssertEqual(s.world.records[12].p2, 1)
        // Coins 30: … #10 true → #7: coins −30 → 0, item 4 × 1 into the first empty slot, snd 501 (when loaded), the end.
        let s2 = try session(r, level: 1, record: 12)
        s2.world.globals.coins = 30
        let (_, y) = stepToTalk(s2)
        let c2 = try run(s2, y, r: r)
        let outs = talk(c2, menu: [Self.downKey, Self.returnKey, Self.returnKey], save: &save)
        XCTAssertEqual(c2.shown, [1, 3, 5, 7])
        XCTAssertEqual(s2.world.globals.coins, 0)
        let slot = try XCTUnwrap(s2.world.globals.inventory.firstIndex { $0.id == 4 })
        XCTAssertEqual(slot, 2)                                      // slots 0 / 1 are `.InitGameGlobals`' spell / item 0
        XCTAssertEqual(s2.world.globals.inventory[slot].count, 1)
        XCTAssertEqual(s2.world.globals.inventory[slot].isSpell, 0)
        XCTAssertTrue(outs.flatMap(\.draws).contains { if case .statusBar(let b) = $0 { b.coins == 0 } else { false } })
        if SoundSlots.isLoaded(501) { XCTAssertEqual(outs.flatMap(\.sounds).map(\.snd), [501]) }
    }

    func testSignAutoReadThenUp() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 1)
        let sign = L.placements[1]
        // Through LevelRun: the player's start on L1 sign rec 1 (p1 12, p4 0).
        let run = try LevelRun(resources: r, prefs: FerazelPrefs(), level: 1, seed: 1, carry: LevelCarry(),
                               save: SaveBlock(), fade: ScreenFade(), music: MusicFade(), services: StubServices(),
                               sounds: StageSounds(prefs: FerazelPrefs(), lengths: [:]),
                               start: (Int(sign.x) - 0x26 + 8, Int(sign.y) + 0x1f - 0x55))
        var t: UInt32 = 1000
        func tick(_ keys: [Int] = []) throws -> FrontOutput {
            defer { t &+= 1 }
            return try run.tick(now: t, input: FrontInput(keys: KeyState(pressed: keys))).merged
        }
        /// Ticks with `keys` held until a read starts (or `max` ticks); the iteration it started in.
        func untilRead(_ keys: [Int] = [], max: Int = 3000) throws -> Int? {
            for _ in 0..<max {
                _ = try tick(keys)
                if run.conversation != nil { return run.iterations }
            }
            return nil
        }
        /// Answers the read ("press any key" one tick) to its end.
        func finishRead() throws {
            var guardTicks = 0
            while let c = run.conversation, guardTicks < 5000 {
                _ = try tick(c.wait == .anyKey ? [Self.anyKey] : [])
                guardTicks += 1
            }
            XCTAssertNil(run.conversation)
        }
        // The first touch reads at once (p4 0 → 1).
        let first = try XCTUnwrap(try untilRead(), "no automatic read")
        guard case .simple(4020, let name, let text)? = run.conversation?.kind else { return XCTFail("not the sign") }
        XCTAssertEqual(name, MacRoman.bytes("Wooden Sign"))
        XCTAssertEqual(text, MacRoman.bytes(try StringList.load(from: r, id: 500).string(12)!))
        XCTAssertEqual(run.session?.world.records[1].p4, 1)
        XCTAssertEqual(run.session?.world.player.countdown06cc, 90)
        try finishRead()
        // UP held: the sign reads again the frame the cooldown reaches 0 — 90 frames after the first read.
        let second = try XCTUnwrap(try untilRead([Self.upKey]), "no read with UP")
        XCTAssertEqual(second - first, 90)
        try finishRead()
        // Without UP no read, however long the player stays (p4 = 1).
        for _ in 0..<600 { _ = try tick() }
        XCTAssertNil(run.conversation)
        XCTAssertGreaterThan(run.iterations - second, 200)
    }

    func testTypingTimeline() throws {
        let r = try resources()
        let s = try session(r, level: 1, record: 1)
        var save = SaveBlock()
        let line = MacRoman.bytes("ABCDEFGHIJKLMNOPQRST")                // 20 characters
        let t0: UInt32 = 1000
        let c = ConversationRun(.simple(pict: 4020, name: MacRoman.bytes("Wooden Sign"), text: line), world: s.world,
                                resources: r, prefs: FerazelPrefs(), levelName: "")
        var draws: [DrawOp] = []
        var t = t0
        while c.wait == .typing || t == t0 {
            draws += c.tick(now: t, input: FrontInput(), save: &save).draws
            if c.wait != .typing { break }
            t += 1
        }
        XCTAssertEqual(t - t0, 40)                                   // 2 ticks a character, the 9-step pass at once
        XCTAssertEqual(c.wait, .anyKey)
        // The trail: 'A' is overdrawn on its odd ages 1, 3, 5, 7, 9 in grey (10 − age)·4000.
        let greys = draws.compactMap { op -> UInt16? in
            if case .drawText(let run) = op, run.bytes == [0x41] { return run.rgb.red }
            return nil
        }
        XCTAssertEqual(greys, [36000, 28000, 20000, 12000, 4000])
        // Any key held: no delay — the whole line and the pass in the first tick (then the wait for all keys up).
        let c2 = ConversationRun(.simple(pict: 4020, name: MacRoman.bytes("Wooden Sign"), text: line), world: s.world,
                                 resources: r, prefs: FerazelPrefs(), levelName: "")
        let held = c2.tick(now: t0, input: FrontInput(keys: KeyState(pressed: [Self.anyKey])), save: &save)
        XCTAssertEqual(c2.wait, .keysUp)
        XCTAssertEqual(held.draws.filter { if case .drawText(let run) = $0 { run.bytes == [0x54] } else { false } }.count,
                       5)                                            // 'T' reaches age 9 within the pass
        _ = c2.tick(now: t0 + 1, input: FrontInput(), save: &save)
        XCTAssertEqual(c2.wait, .anyKey)
    }

    func testEscapeAtAnyKeyStillRunsActions() throws {
        let r = try resources()
        let s = try session(r, level: 1, record: 157)
        var save = SaveBlock()
        let (_, x) = stepToTalk(s)
        let c = try run(s, x, r: r)
        // Up to #14's "press any key" (#14 carries action 4: own p2 = 1).
        talk(c, save: &save, stopAt: { $0.shown.last == 14 && $0.wait == .anyKey })
        XCTAssertEqual(s.world.records[157].p2, 0)
        _ = c.tick(now: 90000, input: FrontInput(keys: KeyState(pressed: [Self.escape])), save: &save)
        XCTAssertTrue(c.aborted)
        XCTAssertEqual(c.wait, .keysUp)
        XCTAssertEqual(s.world.records[157].p2, 0)
        _ = c.tick(now: 90001, input: FrontInput(), save: &save)
        XCTAssertTrue(c.isDone)
        XCTAssertEqual(s.world.records[157].p2, 1)                  // the action ran
        XCTAssertEqual(c.shown.last, 14)                             // #15 never typed
        XCTAssertEqual(c.index, 14)                                  // #14's next 0 → index 14; the abort flag ends it
    }
}
