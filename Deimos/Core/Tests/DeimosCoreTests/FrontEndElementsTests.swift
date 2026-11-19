import XCTest
import HectorResources
@testable import DeimosCore

/// G_Text's element lists and their fades (text-metrics-lists.md §3, §3.1; grounding A §5.2): bounds `FUN_1000da50`,
/// fade in `FUN_1000db90`, fade out `FUN_1000df00`, one-element fade `FUN_1000d6d0`, draw once `FUN_1000d7f0`. Real
/// formats, strings and sprite frames from the shipped data; every loop is bounded by the op list it reads (G11: a
/// pass count over its bound fails).
final class FrontEndElementsTests: XCTestCase {
    static let layout: Result<TextLayout, Error> = Result { try TextLayout(assets: TestAssets.loaded.get()) }

    /// The menu's logo (grounding A §2.1: `gasp 5` = `galo` frame 0, centre (320, 101), format 7 `ingl`). The decoded
    /// frame is 158 × 109.
    static func logo(_ a: DeimosAssets) -> ElementList.Element {
        var f = a.formats[7]
        f.locX = 320
        return .sprite(a.sprites[5], frame: 0, record: TextRequest(format: f, text: []))
    }

    /// The 1 PLAYER button (A §2.1: `gasp 3` `mebu` frame 0 normal / `gasp 4` `mebh` frame 0 hilited, centre (320, 198),
    /// format 5 `inbn`). Decoded frames 96 × 25 / 101 × 25.
    static func onePlayer(_ a: DeimosAssets, hilited: Bool = false) -> ElementList.Element {
        var f = a.formats[hilited ? 6 : 5]
        f.locX = 320
        f.locY = 198
        return .sprite(a.sprites[hilited ? 4 : 3], frame: 0, record: TextRequest(format: f, text: []))
    }

    /// The web line (A §2.1: `inte 0` "WWW.DEIMOSRISING.COM", format 1 `inwe`: CEBU, y 426, spacing 0, own blend 12).
    static func web(_ a: DeimosAssets) throws -> ElementList.Element {
        let text = try XCTUnwrap(a.interfaceStrings().string(at: 0))
        XCTAssertEqual(text, "WWW.DEIMOSRISING.COM")
        return .text(TextRequest(format: a.formats[1], text: text))
    }

    /// Splits an op list at its host waits: the passes and the waits between them.
    func passes(_ ops: [RenderOp]) -> (passes: [[RenderOp]], waits: [HostWait]) {
        var out: [[RenderOp]] = [[]]
        var waits: [HostWait] = []
        for op in ops {
            if case let .hostWait(w) = op { waits.append(w); out.append([]) } else { out[out.count - 1].append(op) }
        }
        return (ops.isEmpty ? [] : out, waits)
    }

    func draws(_ pass: [RenderOp]) -> [DrawCommand] {
        pass.compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
    }

    /// `FUN_1000db90` / `FUN_1000df00` (TM §3.1): 32 passes at levels 31 … 0 (in) and 1 … 32 (out), the rate
    /// `fctiwz(F160)` = 1 tick between pass starts, the first pass unwaited and nothing after the last; per element in
    /// list order: restore the rect from D+0x6c, draw, present the rect (D+0xc origin = 0, 0). Text alpha = max(level,
    /// own +0x114), unsigned; sprite alpha = level (own ignored), flags template | 1, scale the template's 1.0.
    func testElementFades() throws {
        let a = try TestAssets.loaded.get()
        let t = try Self.layout.get()
        XCTAssertEqual(a.floats[160], 1.0)
        let rate = ElementList.fadeRate(floats: a.floats)
        XCTAssertEqual(rate, 1)
        var logo = Self.logo(a)
        logo.record.format.blendAmount = 20                           // a sprite's own +0x114 never reaches the fade
        let list = try ElementList([logo, Self.web(a)])
        let logoRect = MacRect(top: 47, left: 241, bottom: 156, right: 399)
        let webRect = MacRect(top: 426, left: 249, bottom: 439, right: 392)

        for (name, ops, levels) in [("in", list.fadeIn(rate: rate, text: t, assets: a), Array((0...31).reversed())),
                                    ("out", list.fadeOut(rate: rate, text: t, assets: a), Array(1...32))] {
            let (ps, waits) = passes(ops)
            XCTAssertEqual(ps.count, 32, name)
            guard ps.count <= 32 else { return XCTFail("\(name): \(ps.count) passes, bound 32") }
            XCTAssertEqual(waits, Array(repeating: .ticks(1), count: 31), name)
            XCTAssertFalse({ if case .hostWait = ops.first { return true } else { return false } }(), name)
            XCTAssertFalse({ if case .hostWait = ops.last { return true } else { return false } }(), name)
            for (k, pass) in ps.enumerated() {
                let level = UInt32(levels[k])
                // Logo: restore, one sprite command, present.
                var sprite = DrawCommand.template
                sprite.face = FourCC("galo")!
                sprite.frame = 0
                sprite.x = 320
                sprite.y = 101
                sprite.flags = 1
                sprite.alpha = level
                sprite.clip = MacRect(top: 0, left: 0, bottom: 480, right: 640)   // +0x10d = 0 → back-buffer bounds
                sprite.layer = 8                                                  // +0x10c template
                sprite.drawNow = true                                             // +0x110 template
                XCTAssertEqual(Array(pass.prefix(3)), [
                    .copy(from: .terrain, to: .back, src: logoRect, dst: logoRect, interlaced: false),
                    .draw(sprite),
                    .screenBlit(src: logoRect, dst: logoRect),
                ], "\(name) pass \(k + 1)")
                // Web line: restore, 20 glyphs (no spaces), present.
                XCTAssertEqual(pass.count, 3 + 1 + 20 + 1, "\(name) pass \(k + 1)")
                guard pass.count == 25 else { continue }
                XCTAssertEqual(pass[3], .copy(from: .terrain, to: .back, src: webRect, dst: webRect, interlaced: false))
                XCTAssertEqual(pass.last, .screenBlit(src: webRect, dst: webRect))
                let glyphs = draws(Array(pass[4..<(pass.count - 1)]))
                XCTAssertEqual(glyphs.count, 20)
                XCTAssertEqual(Set(glyphs.map(\.alpha)), [max(level, 12)], "\(name) pass \(k + 1)")
                XCTAssertEqual(Set(glyphs.map(\.flags)), [1])
                XCTAssertEqual(glyphs.first?.face, FourCC("tesm"))
            }
        }
        // Worked example B (TM §3.1): passes 1–5 of the fade-in at 31 … 27; inwe holds 12 from level 12 down.
        let inPasses = passes(list.fadeIn(rate: rate, text: t, assets: a)).passes
        XCTAssertEqual(inPasses.prefix(5).map { draws($0).first?.alpha }, [31, 30, 29, 28, 27])
        XCTAssertEqual(inPasses.map { draws($0).dropFirst().first?.alpha },
                       [31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13]
                       + Array(repeating: 12, count: 13))
        // The rate is the caller's: rate 3 waits 3 ticks between pass starts.
        XCTAssertEqual(passes(list.fadeOut(rate: 3, text: t, assets: a)).waits, Array(repeating: .ticks(3), count: 31))
        // A colourised text element (format 2 `inwh`, own blend 0): flags 4, colour white, alpha = level.
        var hilite = try Self.web(a)
        hilite.record.format = a.formats[2]
        let h = passes(ElementList([hilite]).fadeOut(rate: rate, text: t, assets: a)).passes
        XCTAssertEqual(h.map { draws($0).first?.alpha }, (1...32).map { UInt32($0) })
        XCTAssertEqual(Set(h.flatMap { draws($0).map(\.flags) }), [4])
        XCTAssertEqual(h.first.flatMap { draws($0).first }?.colour, a.formats[2].coloriseColor)
    }

    /// Element rects (TM §3): sprite `wh = FUN_10019ca0(id, frame, scale +0x118)`, left = X − w/2, top = Y − h/2 (C
    /// division), right = left + w, bottom = top + h; text = `FUN_1000d260` {Y, start, Y + max h, end + 1}.
    func testElementBounds() throws {
        let a = try TestAssets.loaded.get()
        let t = try Self.layout.get()
        // Logo 158 × 109 at (320, 101): 320 − 79, 101 − 54.
        // Web: CEBU, spacing 0, W = Σ widths "WWW.DEIMOSRISING.COM" = 142 → start fctiwz((640 − 142)·0.5) = 249,
        // end 391 → right 392; glyph height 13.
        // 1 PLAYER (mebu 0, 96 × 25) at (320, 198); hilited (mebh 0, 101 × 25): 101/2 = 50.
        var list = try ElementList([Self.logo(a), Self.web(a), Self.onePlayer(a), Self.onePlayer(a, hilited: true)])
        XCTAssertEqual(list.count, 4)
        XCTAssertEqual(list.bounds(of: 0, text: t, assets: a), MacRect(top: 47, left: 241, bottom: 156, right: 399))
        XCTAssertEqual(list.bounds(of: 1, text: t, assets: a), MacRect(top: 426, left: 249, bottom: 439, right: 392))
        XCTAssertEqual(list.bounds(of: 2, text: t, assets: a), MacRect(top: 186, left: 272, bottom: 211, right: 368))
        XCTAssertEqual(list.bounds(of: 3, text: t, assets: a), MacRect(top: 186, left: 270, bottom: 211, right: 371))
        // Scale 0.5: trunc(96·0.5) × trunc(25·0.5) = 48 × 12 → (320 − 24, 198 − 6). The fades restore and present this
        // scaled rect, but their command keeps the template scale 1.0 (no store to cmd +0x18, TM §3.1 quirk).
        list.elements[2].record.scale = 0.5
        let scaled = MacRect(top: 192, left: 296, bottom: 204, right: 344)
        XCTAssertEqual(list.bounds(of: 2, text: t, assets: a), scaled)
        let pass = ElementList([list.elements[2]]).fadeIn(rate: 1, text: t, assets: a).prefix(3)
        XCTAssertEqual(pass.first, .copy(from: .terrain, to: .back, src: scaled, dst: scaled, interlaced: false))
        XCTAssertEqual(pass.last, .screenBlit(src: scaled, dst: scaled))
        XCTAssertEqual(draws(Array(pass)).map(\.scale), [1.0])
        // +0x10d = 1 keeps the template clip (the game area); +0x10c / +0x110 reach the command.
        list.elements[2].record.keepTemplateClip = true
        list.elements[2].record.layer = 3
        list.elements[2].record.drawNow = false
        let kept = try XCTUnwrap(draws(ElementList([list.elements[2]]).fadeIn(rate: 1, text: t, assets: a)).first)
        XCTAssertEqual(kept.clip, MacRect(top: 0, left: 0, bottom: 480, right: 416))
        XCTAssertEqual(kept.layer, 3)
        XCTAssertFalse(kept.drawNow)
        // An empty text measures nothing: the zero rect.
        XCTAssertEqual(ElementList([.text(TextRequest(format: a.formats[1], text: ""))]).bounds(of: 0, text: t, assets: a),
                       MacRect(top: 0, left: 0, bottom: 0, right: 0))
    }

    /// `FUN_1000da50(list, index, rectOut)` — the hit rect `FUN_10025420` stores at button +0x104: the element's
    /// current bounds (0-based, list order); the zero rect when the list is empty or `index ≥ count`
    /// (`1000da8c cmpwi r30,1; blt`, `1000da94 cmpw r27,r30; bge`), and for a negative index (no element matches).
    /// A hilited button's hit rect is its `mebh` frame's (A §2.1, risk 6).
    func testElementHitRects() throws {
        let a = try TestAssets.loaded.get()
        let t = try Self.layout.get()
        let zero = MacRect(top: 0, left: 0, bottom: 0, right: 0)
        var list = try ElementList([Self.logo(a), Self.onePlayer(a), Self.web(a)])
        XCTAssertEqual(list.bounds(of: 0, text: t, assets: a), MacRect(top: 47, left: 241, bottom: 156, right: 399))
        XCTAssertEqual(list.bounds(of: 1, text: t, assets: a), MacRect(top: 186, left: 272, bottom: 211, right: 368))
        XCTAssertEqual(list.bounds(of: 2, text: t, assets: a), MacRect(top: 426, left: 249, bottom: 439, right: 392))
        XCTAssertEqual(list.bounds(of: 3, text: t, assets: a), zero)
        XCTAssertEqual(list.bounds(of: 99, text: t, assets: a), zero)
        XCTAssertEqual(list.bounds(of: -1, text: t, assets: a), zero)
        XCTAssertEqual(ElementList().bounds(of: 0, text: t, assets: a), zero)
        // Hilite the button: its rect follows the drawn frame (101 wide, 2 px left and 3 px right of the normal one).
        list.elements[1] = Self.onePlayer(a, hilited: true)
        XCTAssertEqual(list.bounds(of: 1, text: t, assets: a), MacRect(top: 186, left: 270, bottom: 211, right: 371))
        // Append keeps list order: the new element is the last index.
        list.append(Self.logo(a))
        XCTAssertEqual(list.count, 4)
        XCTAssertEqual(list.bounds(of: 3, text: t, assets: a), MacRect(top: 47, left: 241, bottom: 156, right: 399))
    }

    /// `FUN_1000d6d0(fmt)` (TM §3 table): the rect measured once; per pass wait until `TickCount ≥ prev + 1` (the first
    /// pass unwaited), restore, `blend −= 1` if ≠ 0, draw, present; loop while blend ≠ 0. A loading line starts at blend
    /// 0x20 (`FUN_10023040`) → 32 draws at 31 … 0, one tick apart.
    func testOneElementFade() throws {
        let a = try TestAssets.loaded.get()
        let t = try Self.layout.get()
        let line = try XCTUnwrap(a.interfaceStrings().string(at: 6))
        XCTAssertEqual(line, "Loading Permanent Image:  ")
        var r = TextRequest(format: a.formats[0], text: line)        // `prog`: LEFT (50, 100), spacing 0
        r.format.blendAmount = 0x20
        // Widths sum 160 (26 chars, 4 spaces) → right 50 + 160 + 1; height 13.
        let rect = MacRect(top: 100, left: 50, bottom: 113, right: 211)
        let (ps, waits) = passes(ElementList.fadeOne(r, text: t))
        XCTAssertEqual(ps.count, 32)
        guard ps.count <= 32 else { return XCTFail("\(ps.count) passes, bound 32") }
        XCTAssertEqual(waits, Array(repeating: .ticks(1), count: 31))
        for (k, pass) in ps.enumerated() {
            let blend = UInt32(31 - k)
            XCTAssertEqual(pass.first, .copy(from: .terrain, to: .back, src: rect, dst: rect, interlaced: false))
            XCTAssertEqual(pass.last, .screenBlit(src: rect, dst: rect))
            let g = draws(pass)
            XCTAssertEqual(g.count, 22, "pass \(k + 1)")
            XCTAssertEqual(pass.count, 22 + 2)
            XCTAssertEqual(Set(g.map(\.alpha)), [blend], "pass \(k + 1)")
            XCTAssertEqual(Set(g.map(\.flags)), [blend == 0 ? 0 : 1], "pass \(k + 1)")
        }
        // The text is drawn exactly as `FUN_1000d380` draws the record at that blend.
        var last = r
        last.format.blendAmount = 0
        XCTAssertEqual(ps.last.map { draws($0) }, t.draw(last))
        // Starting at blend 0: one pass at 0, no wait (the do-while body runs once).
        r.format.blendAmount = 0
        let once = passes(ElementList.fadeOne(r, text: t))
        XCTAssertEqual(once.passes.count, 1)
        XCTAssertEqual(once.waits, [])
        XCTAssertEqual(once.passes.first.map { Set(draws($0).map(\.alpha)) }, [0])
        // Above 32 the original simply runs more passes: blend 34 → 34 passes at 33 … 0, 33 waits.
        r.format.blendAmount = 34
        let more = passes(ElementList.fadeOne(r, text: t))
        XCTAssertEqual(more.passes.count, 34)
        guard more.passes.count <= 34 else { return XCTFail("\(more.passes.count) passes, bound 34") }
        XCTAssertEqual(more.waits, Array(repeating: .ticks(1), count: 33))
        XCTAssertEqual(more.passes.map { Set(draws($0).map(\.alpha)) }, (0...33).reversed().map { [UInt32($0)] })
    }

    /// `FUN_1000d7f0(list, restoreText, present)` — draw every element once at its own blend, no wait, no fade. Per
    /// element in list order: text → measure (`FUN_1000d260`), restore the rect only if `restoreText`, draw the record
    /// (`FUN_1000d380`); sprite → rect at its scale, ALWAYS restore, the command with alpha = own `+0x114` (cmd +0x1c,
    /// `1000d98c`) and scale `+0x118` (cmd +0x18, `1000d9a8`); then present the rect only if `present`. The callers:
    /// the menu redraw `FUN_100258e0` (0, 0), the scores screen `FUN_10021950` / `FUN_10021bd0` (0, 0), and the
    /// name-entry redraw in `FUN_10021bd0` (1, 1).
    func testElementDrawOnce() throws {
        let a = try TestAssets.loaded.get()
        let t = try Self.layout.get()
        var logo = Self.logo(a)
        logo.record.format.blendAmount = 20                           // the sprite's own alpha reaches the command
        logo.record.scale = 0.5                                       // and so does its scale
        let web = try Self.web(a)                                     // own blend 12
        let list = ElementList([logo, web])
        // Logo at 0.5: trunc(158·0.5) × trunc(109·0.5) = 79 × 54 → (320 − 39, 101 − 27).
        let logoRect = MacRect(top: 74, left: 281, bottom: 128, right: 360)
        let webRect = MacRect(top: 426, left: 249, bottom: 439, right: 392)
        XCTAssertEqual(list.bounds(of: 0, text: t, assets: a), logoRect)
        var sprite = DrawCommand.template
        sprite.face = FourCC("galo")!
        sprite.frame = 0
        sprite.x = 320
        sprite.y = 101
        sprite.flags = 1
        sprite.scale = 0.5
        sprite.alpha = 20
        sprite.clip = MacRect(top: 0, left: 0, bottom: 480, right: 640)
        sprite.layer = 8
        sprite.drawNow = true
        let glyphs = t.draw(web.record).map { RenderOp.draw($0) }
        XCTAssertEqual(glyphs.count, 20)
        XCTAssertEqual(Set(draws(glyphs).map(\.alpha)), [12])
        let restoreLogo = RenderOp.copy(from: .terrain, to: .back, src: logoRect, dst: logoRect, interlaced: false)
        let restoreWeb = RenderOp.copy(from: .terrain, to: .back, src: webRect, dst: webRect, interlaced: false)

        let bare: [RenderOp] = [restoreLogo, .draw(sprite)] + glyphs
        let full: [RenderOp] = [restoreLogo, .draw(sprite), .screenBlit(src: logoRect, dst: logoRect), restoreWeb]
            + glyphs + [.screenBlit(src: webRect, dst: webRect)]
        for (use, restoreText, present, expected) in [("menu redraw", false, false, bare),
                                                      ("scores screen", false, false, bare),
                                                      ("name-entry redraw", true, true, full)] {
            let ops = list.drawOnce(restoreText: restoreText, present: present, text: t, assets: a)
            XCTAssertEqual(ops, expected, use)
            XCTAssertFalse(ops.contains { if case .hostWait = $0 { return true } else { return false } }, use)
        }
        XCTAssertEqual(ElementList().drawOnce(restoreText: true, present: true, text: t, assets: a), [])
    }

    /// `FUN_1000db90` / `FUN_1000df00` test the count first (`if (count != 0)`): an empty list makes no pass, no wait
    /// and no present — the credits' first fade-out "returns at once" (A §4).
    func testEmptyListFadesInZeroPasses() throws {
        let a = try TestAssets.loaded.get()
        let t = try Self.layout.get()
        let empty = ElementList()
        XCTAssertEqual(empty.count, 0)
        XCTAssertEqual(empty.fadeIn(rate: 1, text: t, assets: a), [])
        XCTAssertEqual(empty.fadeOut(rate: 1, text: t, assets: a), [])
    }
}
