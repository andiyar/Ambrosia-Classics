import XCTest
import HectorResources
@testable import DeimosCore

/// The message queue (G_Message.cc, messages-notices-console §2: frame-counted) and the single notice slot
/// (§4: tick-counted) — plan C16. Numbers: flli 24 = 20, 25 = 60, 26 = 1, 27 = 20, 71 = 60, 72 = 2, 73 = 4;
/// formats 35 `meno` (30, 10) and 49 `gano`.
final class NoticeMessageTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try AssetsTests.loaded.get() }

    /// §2.3: opaque while clock ≤ post + 60 (unsigned `>`), fade += 1 per frame after, deleted on the frame its
    /// fade reaches 32 = post + 92.
    func testMessageLifetime92Frames() throws {
        let a = try assets()
        XCTAssertEqual(a.floats[25], 60)
        XCTAssertEqual(a.floats[26], 1)
        var q = MessageQueue(floats: a.floats)
        q.age(frame: 1000)
        q.post(text: "Interlacing      ON", kind: .normal)
        XCTAssertEqual(q.messages.map(\.postTime), [1000])
        for f in UInt32(1001)...1060 {
            q.age(frame: f)
            XCTAssertEqual(q.messages.first?.fade, 0, "opaque at frame \(f)")
        }
        for f in UInt32(1061)...1091 {
            q.age(frame: f)
            XCTAssertEqual(q.messages.first?.fade, Int32(f - 1060), "fade at frame \(f)")
        }
        XCTAssertEqual(q.messages.count, 1)
        q.age(frame: 1092)
        XCTAssertEqual(q.messages.count, 0, "deleted at post + 92")
    }

    /// §2.2 step 4: `count ≥ flli 24 (20)` drops the NEW message; nothing is evicted; empty text is ignored.
    func testMessageCapDropsNew() throws {
        let a = try assets()
        XCTAssertEqual(a.floats[24], 20)
        var q = MessageQueue(floats: a.floats)
        for i in 0..<20 { q.post(text: "m\(i)", kind: .normal) }
        XCTAssertEqual(q.messages.count, 20)
        q.post(text: "dropped", kind: .error)
        XCTAssertEqual(q.messages.count, 20)
        XCTAssertEqual(q.messages.first?.text, Array("m0".utf8))
        XCTAssertEqual(q.messages.last?.text, Array("m19".utf8))
        var e = MessageQueue(floats: a.floats)
        e.post(text: "", kind: .normal)
        XCTAssertTrue(e.messages.isEmpty)
        // Text is cut at 63 chars (`FUN_10046510(+0xc, s, 0x3f)`); upper → ASCII toupper (`FUN_100463b0`).
        e.post(text: String(repeating: "a", count: 70), kind: .normal, uppercase: true)
        XCTAssertEqual(e.messages.first?.text, Array(repeating: UInt8(ascii: "A"), count: 63))
        // The shipped MSL Mac Roman toupper (`0x100f0f94` class bit 0x40 → map `0x100f1194`).
        var u = MessageQueue(floats: a.floats)
        u.post(text: [0x8a, 0x87, 0x88, 0xa7, 0x61, 0x5a, 0x31, 0xd8], kind: .normal, uppercase: true)
        XCTAssertEqual(u.messages.first?.text, [0x80, 0xe7, 0xcb, 0xa7, 0x41, 0x5a, 0x31, 0xd9])
        u.post(text: [0x8a], kind: .normal, uppercase: false)
        XCTAssertEqual(u.messages.last?.text, [0x8a])
    }

    /// §2.3 quirk: at most one message is deleted per frame and the walk stops there, so the later expired
    /// messages miss that frame's fade step.
    func testOneDeletionPerFrame() throws {
        var q = MessageQueue(floats: try assets().floats)
        q.age(frame: 10)
        for t in ["a", "b", "c"] { q.post(text: t, kind: .normal) }
        for f in UInt32(11)...101 { q.age(frame: f) }
        XCTAssertEqual(q.messages.map(\.fade), [31, 31, 31])
        q.age(frame: 102)
        XCTAssertEqual(q.messages.map(\.text), [Array("b".utf8), Array("c".utf8)])
        XCTAssertEqual(q.messages.map(\.fade), [31, 31], "the walk stopped at the deletion")
        q.age(frame: 103)
        XCTAssertEqual(q.messages.map(\.text), [Array("c".utf8)])
        XCTAssertEqual(q.messages.map(\.fade), [31])
        q.age(frame: 104)
        XCTAssertTrue(q.messages.isEmpty)
    }

    /// §2.4: three normal messages at Loc_Y 10, 30, 50, newest on top (Loc_Y += 20·(count − j − 1)); strip
    /// blend = fade + 16, strip off above 32; layer 15, template clip, queued.
    func testMessageLayoutNewestOnTop() throws {
        let a = try assets()
        XCTAssertEqual(a.floats[27], 20)
        XCTAssertEqual(a.formatIDs[35], FourCC("meno"))
        XCTAssertEqual(a.formats[35].locY, 10)
        XCTAssertEqual(a.formats[35].locX, 30)
        var q = MessageQueue(floats: a.floats)
        q.age(frame: 0)
        q.post(text: "first", kind: .normal)
        q.post(text: "second", kind: .error)
        q.post(text: "third", kind: .status)
        let r = q.drawRequests(formats: a.formats)
        XCTAssertEqual(r.map(\.text), ["first", "second", "third"].map { Array($0.utf8) })
        XCTAssertEqual(r.map(\.format.locY), [50, 30, 10])
        XCTAssertEqual(r.map(\.format.coloriseColor), [a.formats[35], a.formats[36], a.formats[37]].map(\.coloriseColor))
        XCTAssertEqual(r.map(\.format.coloriseDo), [a.formats[35], a.formats[36], a.formats[37]].map(\.coloriseDo))
        for t in r {
            XCTAssertEqual(t.layer, 15)
            XCTAssertTrue(t.keepTemplateClip)
            XCTAssertFalse(t.drawNow)
            XCTAssertEqual(t.format.blendAmount, 0)
            XCTAssertEqual(t.format.colorStripBlendAmount, 16)
            XCTAssertTrue(t.format.colorStripDo)
        }
        // A sticky readout is prepended (list head) and drawn first at k·20; pass 2 counts j over the normal
        // entries only, with count = all 4 entries: Loc_Y 10 + 20·(4 − j − 1) = 70, 50, 30.
        var s = q
        s.post(text: "Game Time:  ", kind: .status, readout: 7)
        XCTAssertEqual(s.messages.map(\.sticky), [true, false, false, false])
        XCTAssertEqual(s.messages.first?.readout, 7)
        let sr = s.drawRequests(formats: a.formats, readoutValue: { $0 == 7 ? 1234 : -1 })
        XCTAssertEqual(sr.map(\.text), ["Game Time:  1234", "first", "second", "third"].map { Array($0.utf8) })
        XCTAssertEqual(sr.map(\.format.locY), [10, 70, 50, 30])
        // Sticky lines never age.
        for f in UInt32(1)...200 { s.age(frame: f) }
        XCTAssertEqual(s.messages.count, 1)
        XCTAssertEqual(s.messages.first?.fade, 0)
        // Re-posting the same readout un-sticks it (no new entry); it then ages out like a normal message.
        s.post(text: "ignored", kind: .normal, readout: 7)
        XCTAssertEqual(s.messages.count, 1)
        XCTAssertEqual(s.messages.first?.sticky, false)
        s.age(frame: 201)
        XCTAssertEqual(s.messages.first?.fade, 1, "post time 0 + 60 long passed")
        // Fade 17 → strip blend 33 > 32 → strip off.
        for f in UInt32(1)...77 { q.age(frame: f) }
        let faded = q.drawRequests(formats: a.formats)
        XCTAssertEqual(faded.first?.format.blendAmount, 17)
        XCTAssertEqual(faded.first?.format.colorStripDo, false)
        // The commands come through TextLayout: the newest line's strip and glyphs sit on y 10.
        let text = try TextLayout(assets: a)
        let cmds = MessageQueue(floats: a.floats).drawCommands(text: text, formats: a.formats)
        XCTAssertTrue(cmds.isEmpty)
        var one = MessageQueue(floats: a.floats)
        one.post(text: "Hi", kind: .normal)
        let c = one.drawCommands(text: text, formats: a.formats)
        XCTAssertEqual(c.count, 3, "strip + 2 glyphs")
        XCTAssertEqual(c.first?.face, FourCC("COST"))
        XCTAssertEqual(c.first?.costRect?.top, 10 - 3)
        XCTAssertTrue(c.allSatisfy { $0.layer == 15 && !$0.drawNow })
    }

    /// §4.2–§4.3: fade-in 32 → 0 in steps of 2 over 16 ticks (the flag clears on the 17th); auto-clear when
    /// game time > start + 60 (first at start + 61); fade-out 0 → 32 in steps of 4 over 8 ticks, then inactive.
    func testNoticeFadeHoldFade() throws {
        let a = try assets()
        XCTAssertEqual([a.floats[71], a.floats[72], a.floats[73]], [60, 2, 4])
        var n = NoticeSlot(floats: a.floats)
        var rng = MSLRandom(seed: 1)
        var cues = CueBuffer()
        var sound = SoundRecord()
        sound.id = FourCC("exli")!
        sound.minVolume = 80
        sound.priority = 0x132
        sound.minPitch = 0.5
        sound.maxPitch = 0.55
        n.post(NoticeSlot.Post(text: Array("Sector Secured".utf8), hold: false, fadeIn: true, delay: 0,
                               sound: sound, alignment: .centerInGameArea), now: 100)
        XCTAssertTrue(n.active)
        XCTAssertEqual(n.alpha, 32)
        XCTAssertTrue(n.fadingIn)
        // First visible tick: start = now, the sound through SoundPlay.record (one pitch draw).
        n.tick(gameTime: 101, rng: &rng, cues: &cues)
        XCTAssertEqual(n.start, 101)
        XCTAssertEqual(cues.sounds.count, 1)
        XCTAssertEqual(cues.sounds.first?.id, FourCC("exli"))
        XCTAssertEqual(cues.sounds.first?.priority, 0x32)
        XCTAssertEqual(cues.sounds.first?.allowMultiple, true)
        XCTAssertEqual(rng.draws, 1)
        XCTAssertEqual(n.alpha, 30)
        // A repeated game time does nothing (once per new game time).
        n.tick(gameTime: 101, rng: &rng, cues: &cues)
        XCTAssertEqual(n.alpha, 30)
        for t in Int32(102)...116 { n.tick(gameTime: t, rng: &rng, cues: &cues) }
        XCTAssertEqual(n.alpha, 0, "32 → 0 in 16 ticks")
        XCTAssertTrue(n.fadingIn)
        n.tick(gameTime: 117, rng: &rng, cues: &cues)
        XCTAssertFalse(n.fadingIn)
        XCTAssertEqual(cues.sounds.count, 1, "the sound plays once")
        for t in Int32(118)...161 { n.tick(gameTime: t, rng: &rng, cues: &cues) }
        XCTAssertTrue(n.active)
        XCTAssertFalse(n.fadingOut, "held through start + 60")
        XCTAssertEqual(n.alpha, 0)
        n.tick(gameTime: 162, rng: &rng, cues: &cues)
        XCTAssertTrue(n.fadingOut, "cleared at start + 61")
        XCTAssertEqual(n.alpha, 4)
        for t in Int32(163)...168 { n.tick(gameTime: t, rng: &rng, cues: &cues) }
        XCTAssertEqual(n.alpha, 28)
        XCTAssertTrue(n.active)
        n.tick(gameTime: 169, rng: &rng, cues: &cues)
        XCTAssertEqual(n.alpha, 32)
        XCTAssertFalse(n.active, "0 → 32 in 8 ticks")
        XCTAssertEqual(rng.draws, 1)
        // `lastTick` is stored before the active test: an inactive tick still consumes its game time.
        n.tick(gameTime: 500, rng: &rng, cues: &cues)
        XCTAssertEqual(n.lastTick, 500)
        n.post(NoticeSlot.Post(text: Array("Y".utf8), hold: false, fadeIn: true, delay: 0, sound: sound,
                               alignment: .centerInGameArea), now: 500)
        n.tick(gameTime: 500, rng: &rng, cues: &cues)
        XCTAssertEqual(n.delay, 0, "same game time: no tick")
        XCTAssertEqual(cues.sounds.count, 1)
        XCTAssertEqual(n.alpha, 32)
        // Delay 2: not drawable on the first tick; drawable on the tick the delay reaches 0 (fade-in runs), but
        // the start reset and the sound come one tick later (10018360 reads the decremented delay back as 0).
        var dl = NoticeSlot(floats: a.floats)
        var dc = CueBuffer()
        var dr = MSLRandom(seed: 1)
        dl.post(NoticeSlot.Post(text: Array("D".utf8), hold: false, fadeIn: true, delay: 2, sound: sound,
                                alignment: .centerInGameArea), now: 10)
        XCTAssertNil(dl.drawRequest(formats: a.formats))
        dl.tick(gameTime: 11, rng: &dr, cues: &dc)
        XCTAssertEqual(dl.delay, 1)
        XCTAssertNil(dl.drawRequest(formats: a.formats))
        XCTAssertEqual(dl.alpha, 32)
        dl.tick(gameTime: 12, rng: &dr, cues: &dc)
        XCTAssertEqual(dl.delay, 0)
        XCTAssertNotNil(dl.drawRequest(formats: a.formats))
        XCTAssertEqual(dl.alpha, 30)
        XCTAssertEqual(dl.start, 10)
        XCTAssertTrue(dc.sounds.isEmpty)
        dl.tick(gameTime: 13, rng: &dr, cues: &dc)
        XCTAssertEqual(dl.start, 13)
        XCTAssertEqual(dc.sounds.count, 1)
        XCTAssertEqual(dl.delay, -1)
        // Hold: no auto-clear, and later posts and clears are ignored.
        var h = NoticeSlot(floats: a.floats)
        var hc = CueBuffer()
        h.post(NoticeSlot.Post(text: Array("H".utf8), hold: true, fadeIn: false, delay: 0, sound: SoundRecord(),
                               alignment: .centerInGameArea), now: 0)
        for t in Int32(1)...200 { h.tick(gameTime: t, rng: &dr, cues: &hc) }
        XCTAssertTrue(h.active)
        XCTAssertFalse(h.fadingOut)
        XCTAssertEqual(h.alpha, 0)
        h.post(NoticeSlot.Post(text: Array("Z".utf8), hold: false, fadeIn: true, delay: 0, sound: SoundRecord(),
                               alignment: .centerInBuffer), now: 201)
        XCTAssertEqual(h.text, Array("H".utf8))
        XCTAssertEqual(h.start, 1)
        h.post(nil, now: 202)
        XCTAssertTrue(h.active)
        XCTAssertFalse(h.fadingOut)
        // Draw (FUN_100184b0): format 49, BlendAmount = alpha, strip blend += alpha, alignment N+0x68, layer 15.
        var d = NoticeSlot(floats: a.floats)
        d.post(NoticeSlot.Post(text: Array("X".utf8), hold: false, fadeIn: true, delay: 0, sound: SoundRecord(),
                               alignment: .centerInBuffer), now: 5)
        XCTAssertEqual(a.formatIDs[49], FourCC("gano"))
        let req = try XCTUnwrap(d.drawRequest(formats: a.formats))
        XCTAssertEqual(req.format.blendAmount, 32)
        XCTAssertEqual(req.format.colorStripBlendAmount, a.formats[49].colorStripBlendAmount + 32)
        XCTAssertFalse(req.format.colorStripDo, "strip off above 32")
        XCTAssertEqual(req.format.format, .centerInBuffer)
        XCTAssertEqual(req.layer, 15)
        XCTAssertTrue(req.keepTemplateClip)
        XCTAssertFalse(req.drawNow)
        // Clear while still fading in switches it off at once (10018224..10018234).
        d.post(nil, now: 6)
        XCTAssertFalse(d.active)
        XCTAssertNil(d.drawRequest(formats: a.formats))
    }

    /// §4.4: the Caps Lock pause notice (`10030420..100304dc`): GameString 0, fade-in forced off → alpha 0 at
    /// once, hold 0, delay 0, sound `none`; alignment `CEGA` for fc+4 = 1, `CEBU` for fc+4 = 0.
    func testPressCapsLockNoticeOpaqueAtOnce() throws {
        let a = try assets()
        let text = try XCTUnwrap(a.gameStrings.first)
        XCTAssertEqual(a.gameString(0), "Press Caps Lock")
        var n = NoticeSlot(floats: a.floats)
        n.post(NoticeSlot.Post.pressCapsLock(text: text, controllerMode: 1), now: 40)
        XCTAssertTrue(n.active)
        XCTAssertEqual(n.alpha, 0)
        XCTAssertFalse(n.fadingIn)
        XCTAssertFalse(n.hold)
        XCTAssertEqual(n.alignment, .centerInGameArea)
        let req = try XCTUnwrap(n.drawRequest(formats: a.formats))
        XCTAssertEqual(req.format.blendAmount, 0)
        XCTAssertEqual(req.text, Array("Press Caps Lock".utf8))
        var rng = MSLRandom(seed: 1)
        var cues = CueBuffer()
        n.tick(gameTime: 41, rng: &rng, cues: &cues)
        XCTAssertTrue(cues.sounds.isEmpty, "sound none: no cue")
        XCTAssertEqual(rng.draws, 0, "and no draw")
        XCTAssertEqual(n.alpha, 0)
        XCTAssertEqual(NoticeSlot.Post.pressCapsLock(text: text, controllerMode: 0).alignment, .centerInBuffer)
        // Resume (FUN_10030870 → Clear): fades out over 8 ticks.
        n.post(nil, now: 42)
        XCTAssertTrue(n.fadingOut)
        for t in Int32(42)...48 { n.tick(gameTime: t, rng: &rng, cues: &cues) }
        XCTAssertTrue(n.active)
        n.tick(gameTime: 49, rng: &rng, cues: &cues)
        XCTAssertFalse(n.active)
        XCTAssertEqual(n.alpha, 32)
    }
}
