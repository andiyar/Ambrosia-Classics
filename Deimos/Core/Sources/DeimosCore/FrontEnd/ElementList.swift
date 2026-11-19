import Foundation
import HectorResources

/// G_Interface's element list and G_Text's list fades (Phase 4, plan EL; text-metrics-lists.md §3, §3.1; grounding A
/// §5.2): the text and sprite elements the main menu, the credits, the loading lines and the high scores draw, their
/// bounds (= the menu's hit rects) and the three fades. Core only records the original's calls as `RenderOp`s in its
/// order; the host steps the waits (`RenderOp.hostWait`) and the renderer executes the rest.
///
/// Listing reads (`ghidra/deimos/Deimos_pef.decompiled.c`, `disasm-review3-all.txt`):
/// - **The list** (`FUN_10000ce0` count, `FUN_10000e10` cursor, `FUN_100009e0` append): append order, iterated from
///   the head. An element is a 0x148-byte format record; `+0x124 == 'none'` → text (`+0x000`, laid out by its format),
///   otherwise a sprite: ID `+0x124`, frame `+0x128`, centre `+0x100/+0x104` (the format's Loc), own alpha `+0x114`
///   (the format's blend), scale `+0x118`, layer `+0x10c`, clip select `+0x10d`, draw-now `+0x110`.
/// - **Rects.** Sprite (identical in `d7f0`, `da50`, `db90`, `df00`; `1000dd74..1000dde4`): `wh = FUN_10019ca0(id,
///   frame, scale +0x118)` (`1000dd7c lfs f1,0x1cc(r1)` = the record copy's +0x118), left = X − w/2, top = Y − h/2
///   (C division, `rlwinm …,1,31,31; add; srawi 1`), right = left + w, bottom = top + h. Text: `FUN_1000d260` =
///   `FUN_1000e270(…, 0)` bounds {Y, start, Y + max h, end + 1} (the digit cache is `TextLayout`'s, built at init).
/// - **Screen rect** `FUN_1000c3b0`: + the display origin (D+0x0c top, D+0x10 left) = (0, 0) — the display rect D+0xc is
///   (0, 0, 480, 640) (display-window-present.md §8) — so `FUN_1000bbd0`'s src and dst are the same rect.
public struct ElementList: Equatable, Sendable {
    /// One element: the original's 0x148-byte record (`record`: its format carries the text origin or the sprite's
    /// centre in Loc X/Y and the own blend / sprite alpha `+0x114` in `blendAmount`; `layer` `+0x10c`,
    /// `keepTemplateClip` `+0x10d`, `drawNow` `+0x110`, `scale` `+0x118`) plus the sprite ID `+0x124` and frame
    /// `+0x128`. `sprite == .none` makes it a text element.
    public struct Element: Equatable, Sendable {
        public var record: TextRequest
        /// `+0x124`: the sprite group; `none` = a text element.
        public var sprite: FourCC
        /// `+0x128`: the sprite frame.
        public var frame: Int

        /// A text element: `record.text` laid out by `record.format`.
        public static func text(_ record: TextRequest) -> Element {
            Element(record: record, sprite: .none, frame: 0)
        }

        /// A sprite element: `face` frame `frame` centred on the record's Loc (X, Y), own alpha its blend.
        public static func sprite(_ face: FourCC, frame: Int, record: TextRequest) -> Element {
            Element(record: record, sprite: face, frame: frame)
        }

        /// `+0x124 == 'none'`.
        public var isText: Bool { sprite == .none }
    }

    /// The elements in append (= draw) order.
    public var elements: [Element]

    public init(_ elements: [Element] = []) {
        self.elements = elements
    }

    /// `FUN_10000ce0`.
    public var count: Int { elements.count }

    /// `FUN_100009e0`: append at the tail.
    public mutating func append(_ element: Element) {
        elements.append(element)
    }

    /// The fade rate every caller passes (`li r3,0xa0; bl 0x10020250; fctiwz` at `10025858`, `100258a8`, `100232e8`,
    /// `10025d20`, `10025f58`, `10026048`): `fctiwz(PermFloat 160)` — `Interface_FadeRate` 1.0 → 1 tick.
    public static func fadeRate(floats: [Float]) -> UInt32 {
        UInt32(bitPattern: EntityDraw.fctiwz(floats[160]))
    }

    /// `FUN_1000da50(list, index, rectOut)` — the bounds of element `index` (0-based); `FUN_10025420` stores them at
    /// the button's +0x104 as its hit rect. The zero rect when the list is empty or `index ≥ count` (`1000da8c cmpwi
    /// r30,1; blt`, `1000da94 cmpw r27,r30; bge`); a negative index matches no element and keeps the zero rect.
    public func bounds(of index: Int, text: TextLayout, assets: DeimosAssets) -> MacRect {
        guard elements.indices.contains(index) else { return MacRect(top: 0, left: 0, bottom: 0, right: 0) }
        return Self.rect(elements[index], text: text, assets: assets)
    }

    /// `FUN_1000db90(list, rate)` — fade the list in: level 32 (`1000dbd0 li r25,0x20`); each pass lowers it by 1 while
    /// ≠ 0 and draws every element at it; 32 passes at 31 … 0 (`1000dee0 cmplwi r25,0; bne`). An empty list: no pass.
    public func fadeIn(rate: UInt32, text: TextLayout, assets: DeimosAssets) -> [RenderOp] {
        fade(levels: (0...31).reversed(), rate: rate, text: text, assets: assets)
    }

    /// `FUN_1000df00(list, rate)` — fade the list out: level 0 (`1000df40 li r25,0`); each pass raises it by 1 while
    /// < 32; 32 passes at 1 … 32 (`1000e250 cmplwi r25,0x20; bne`). The last pass (alpha 32) only restores: the draw
    /// of alpha 32 draws nothing (`100195a4`), so the elements are erased. An empty list: no pass.
    public func fadeOut(rate: UInt32, text: TextLayout, assets: DeimosAssets) -> [RenderOp] {
        fade(levels: 1...32, rate: rate, text: text, assets: assets)
    }

    /// `FUN_1000d6d0(fmt)` — fade one text record in (the loading lines; `FUN_10023040` starts them at blend 0x20).
    /// The rect is measured once from the record (`FUN_1000d260`, before the loop). Each pass: wait until `TickCount ≥
    /// prev + 1` (the constant 1, not the rate; the first pass unwaited, `prev` = 0), restore the rect, `blend −= 1` if
    /// ≠ 0 (`1000d78c..1000d79c`), draw the local copy (`FUN_1000d380`), present the rect; loop while blend ≠ 0. Blend
    /// 32 → 32 passes at 31 … 0; blend 0 → one pass at 0. The record itself is not changed.
    ///
    /// A blend above 32 is accepted as the original accepts it: it simply runs more passes (blend n → n passes at
    /// n − 1 … 0). Only a negative blend is refused (precondition): the original would spin through ~2³² decrements
    /// (about 4 billion passes) before it reached 0 — refused here rather than hung (G11). The only caller passes 0x20.
    public static func fadeOne(_ record: TextRequest, text: TextLayout) -> [RenderOp] {
        precondition(record.format.blendAmount >= 0, "fadeOne: negative blend \(record.format.blendAmount)")
        let r = text.layout(record, draw: false).bounds
        var copy = record
        var ops: [RenderOp] = []
        var first = true
        repeat {                                                     // 1000d740..1000d7d8 (do … while)
            if !first { ops.append(.hostWait(.ticks(1))) }           // 1000d750..1000d76c; t = TickCount + 1
            first = false
            ops.append(restore(r))                                   // FUN_10009fd0(D+0x6c, D+0x68, r, r, 0)
            if copy.format.blendAmount != 0 { copy.format.blendAmount -= 1 }
            ops += text.draw(copy).map { .draw($0) }                 // FUN_1000d380(copy, 0)
            ops.append(present(r))                                   // FUN_1000bbd0(D, D+0x68, r, r + origin)
        } while copy.format.blendAmount != 0
        return ops
    }

    /// `FUN_1000d7f0(list, restoreText, present)` — draw every element once at its own blend: no level, no wait, no
    /// pass. An empty list draws nothing (`if (count != 0)`). Per element in list order:
    /// - text → measure the record (`FUN_1000d260`), restore the rect only if `restoreText` (`1000d87c`), draw the
    ///   record itself (`FUN_1000d380(rec, 0)`, its own `+0x114`);
    /// - sprite → the rect at the record's scale (`1000d8b8 lfs f1,0x118`), restore it **always** (`1000d924`, not
    ///   gated), the command from the G_Text template with x, y = centre, face, frame, flags template | 1, **scale
    ///   `+0x118`** (cmd +0x18, `1000d9a8`) and **alpha = own `+0x114`** (cmd +0x1c, `1000d98c`) — unlike the fades —
    ///   draw-now `+0x110`, layer `+0x10c`, clip = back-buffer bounds unless `+0x10d`; drawn (`FUN_10019570`);
    /// - then present the rect only if `present` (`1000d9d8`).
    ///
    /// The callers: the menu redraw `FUN_100258e0` and the scores screen (`FUN_10021950`, `FUN_10021bd0` before its
    /// loop) pass (false, false) — the shell presents later; the name-entry redraw inside `FUN_10021bd0`'s loop passes
    /// (true, true).
    public func drawOnce(restoreText: Bool, present: Bool, text: TextLayout, assets: DeimosAssets) -> [RenderOp] {
        var ops: [RenderOp] = []
        for e in elements {
            let r = Self.rect(e, text: text, assets: assets)
            if e.isText {
                if restoreText { ops.append(Self.restore(r)) }
                ops += text.draw(e.record).map { .draw($0) }
            } else {
                ops.append(Self.restore(r))
                var cmd = Self.spriteCommand(e)
                cmd.scale = e.record.scale
                cmd.alpha = UInt32(bitPattern: e.record.format.blendAmount)
                ops.append(.draw(cmd))
            }
            if present { ops.append(Self.present(r)) }
        }
        return ops
    }

    // MARK: - The pass body shared by `FUN_1000db90` and `FUN_1000df00`

    /// One pass per level. Pass k > 1 waits until `TickCount ≥ (pass k−1's start) + rate` (`1000dbe4 cmplw r26,r3;
    /// bgt` unsigned, `1000dbf8 add r26,r23,r3`): the host's `.ticks(rate)`. No pacing difference: the driver reads its
    /// clock once per `idle` call and `.screenBlit` does not end the call, so the wait counts from the pass's start tick.
    /// The first pass does not wait (t = 0) and nothing follows the last. Then, per element in list order (a record
    /// copy, `+0x114` = max(level, own) unsigned, `1000dd20 cmplw r25,r0; blt`): text → measure the copy, restore,
    /// draw the copy (`FUN_1000d380`); sprite → rect at the record's scale, restore, the command from the G_Text
    /// template `0x100e5298` (x, y = centre, face, frame, flags template | 1, alpha = level `1000de58 stw r25,0x84(r1)`,
    /// draw-now `+0x110`, layer `+0x10c`, clip = back-buffer bounds unless `+0x10d`; **no scale store** — the template's
    /// 1.0, TM §3.1 quirk), drawn (`FUN_10019570`); then present the rect.
    func fade(levels: some Sequence<Int>, rate: UInt32, text: TextLayout, assets: DeimosAssets) -> [RenderOp] {
        guard !elements.isEmpty else { return [] }                   // if (count != 0)
        var ops: [RenderOp] = []
        var first = true
        for l in levels {
            let level = UInt32(l)
            if !first { ops.append(.hostWait(.ticks(rate))) }
            first = false
            for e in elements {
                let r = Self.rect(e, text: text, assets: assets)
                ops.append(Self.restore(r))
                if e.isText {
                    var copy = e.record
                    let own = UInt32(bitPattern: copy.format.blendAmount)
                    copy.format.blendAmount = Int32(bitPattern: own <= level ? level : own)
                    ops += text.draw(copy).map { .draw($0) }
                } else {
                    var cmd = Self.spriteCommand(e)
                    cmd.alpha = level
                    ops.append(.draw(cmd))
                }
                ops.append(Self.present(r))
            }
        }
        return ops
    }

    /// A sprite element's command, the fields `FUN_1000d7f0`, `FUN_1000db90` and `FUN_1000df00` share: the G_Text
    /// template with x, y = centre, face, frame, flags template | 1, draw-now `+0x110`, layer `+0x10c`, clip =
    /// back-buffer bounds unless `+0x10d` (`FUN_1000a530(D+0x68)`). Scale and alpha are each caller's.
    static func spriteCommand(_ e: Element) -> DrawCommand {
        var cmd = DrawCommand.template
        cmd.x = e.record.format.locX
        cmd.y = e.record.format.locY
        cmd.face = e.sprite
        cmd.frame = e.frame
        cmd.flags = DrawCommand.template.flags | 1
        cmd.drawNow = e.record.drawNow
        cmd.layer = e.record.layer
        if !e.record.keepTemplateClip { cmd.clip = EntityDraw.backBufferBounds }
        return cmd
    }

    /// The element's rect (see the type's comment).
    static func rect(_ e: Element, text: TextLayout, assets: DeimosAssets) -> MacRect {
        if e.isText { return text.layout(e.record, draw: false).bounds }      // FUN_1000d260
        let (w, h) = Player.frameSize(assets, e.sprite, Int32(truncatingIfNeeded: e.frame), e.record.scale)
        let x = e.record.format.locX, y = e.record.format.locY
        let left = x &- w / 2, top = y &- h / 2
        return MacRect(top: top, left: left, bottom: top &+ h, right: left &+ w)
    }

    /// `FUN_10009fd0(D+0x6c, D+0x68, r, r, 0)`: restore the rect from the save buffer.
    static func restore(_ r: MacRect) -> RenderOp {
        .copy(from: .terrain, to: .back, src: r, dst: r, interlaced: false)
    }

    /// `FUN_1000c3b0` (origin 0, 0) then `FUN_1000bbd0`: the rect, back buffer → screen.
    static func present(_ r: MacRect) -> RenderOp {
        .screenBlit(src: r, dst: r)
    }
}
