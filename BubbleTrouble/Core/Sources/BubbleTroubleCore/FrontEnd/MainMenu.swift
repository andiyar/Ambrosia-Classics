// The main menu screen (plan 2026-10-04 btx-playable C6; FI §1b), transcribed from `_DrawMainMenu @ 00009eb3`,
// `_FlashButton @ 000078e0`, `_DrawButton @ 00007f62` and the geometry they set up. Registered build: the Register
// button (Rect 7, src 0,204,123,238) is never drawn or hit (Invariant 5).

/// The main menu's pictures, rects and the op lists of its drawing routines.
public struct MainMenu: Equatable, Sendable {
    /// The six buttons, numbered as the original's `_FlashButton` / `_DrawButton` argument and `Rect` id.
    public enum Button: Int, CaseIterable, Sendable {
        case newGame = 1, demo, scores, prefs, credits, quit
    }

    /// `_PatternFillCompGWorld(0x391)`: PICT 913 (the title backdrop) centred into comp.
    public static let backdropPict = 913
    /// `_DrawPictInRect(0x2334, …)`: PICT 9012 "By Alex Metcalf & David Wareing".
    public static let creditLinePict = 9012
    public static let creditLineRect = QDRect(top: 0xbb, left: 0xe5, bottom: 0xc9, right: 0x19b)
    /// `gMenuButtonsPict` = PICT 9100, drawn into bgnd at (0, 0, 300, 300) before every button copy.
    public static let buttonsPict = 9100
    public static let buttonsPictRect = QDRect(top: 0, left: 0, bottom: 300, right: 300)
    /// `_FlashButton` / `_DrawButton`: `OffsetRect(src, 0x96, 0)` → the highlighted state.
    public static let highlightOffset: Int16 = 0x96
    /// `_DrawCompPattern @ 0000742c`: `_PatternFillCompGWorld(0x390)` — PICT 912 centred (the high-score backdrop).
    public static let compPatternPict = 912
    /// `gLogoR` (set in `_DrawMainMenu`): top 0x19, left 0xab, bottom 0xad, right 0x1d5; hit-tested inset 5.
    public static let logoRect = QDRect(top: 0x19, left: 0xab, bottom: 0xad, right: 0x1d5)
    /// The whole logical screen (`environment + 0x12`) — `_UpdateScreen`'s `_CompToScreen`.
    public static let screenRect = QDRect(top: 0, left: 0, bottom: 480, right: 640)

    /// `_DrawMainMenu`'s `SetRect`s of the normal-state sources in PICT 9100 (left, top, right, bottom).
    public static let sourceRects: [Button: QDRect] = [
        .newGame: QDRect(top: 0, left: 0, bottom: 0x22, right: 0x96),
        .demo: QDRect(top: 0x22, left: 0, bottom: 0x44, right: 0x47),
        .scores: QDRect(top: 0x44, left: 0, bottom: 0x66, right: 0x65),
        .prefs: QDRect(top: 0x66, left: 0, bottom: 0x88, right: 0x50),
        .credits: QDRect(top: 0x88, left: 0, bottom: 0xaa, right: 0x68),
        .quit: QDRect(top: 0xaa, left: 0, bottom: 0xcc, right: 0x43),
    ]

    /// `_GetRectRsrc(1…6)`: the destinations (and hot rects) from `Rect` 1…6.
    public let destinations: [Button: QDRect]
    /// PICT 913's centred destination (`_DrawAndCentrePict`).
    public let backdropRect: QDRect
    /// PICT 912's centred destination.
    public let compPatternRect: QDRect

    public init(data: BTXGameData) {
        var dst: [Button: QDRect] = [:]
        for b in Button.allCases {
            dst[b] = data.rects.rect(b.rawValue) ?? Self.fallbackDestinations[b]
        }
        destinations = dst
        backdropRect = Self.centred(data: data, pict: Self.backdropPict)
        compPatternRect = Self.centred(data: data, pict: Self.compPatternPict)
    }

    /// FI §1b's decode of `Rect` 1…6 (used only if a `Rect` is missing).
    static let fallbackDestinations: [Button: QDRect] = [
        .newGame: QDRect(top: 228, left: 165, bottom: 262, right: 315),
        .demo: QDRect(top: 276, left: 165, bottom: 310, right: 236),
        .scores: QDRect(top: 324, left: 165, bottom: 358, right: 266),
        .prefs: QDRect(top: 228, left: 394, bottom: 262, right: 474),
        .credits: QDRect(top: 276, left: 373, bottom: 310, right: 477),
        .quit: QDRect(top: 324, left: 409, bottom: 358, right: 476),
    ]

    /// `_DrawAndCentrePict @ 0000bd14`: top = (480 − height) / 2, left = (640 − width) / 2 (C division), from the
    /// PICT's picFrame (bytes 2…9, top/left/bottom/right big-endian). A missing PICT → the full screen.
    public static func centred(data: BTXGameData, pict id: Int) -> QDRect {
        guard let d = data.data(type: "PICT", id: id), d.count >= 10 else { return screenRect }
        let t = Int(BigEndian.int16(d, at: 2)), l = Int(BigEndian.int16(d, at: 4))
        let b = Int(BigEndian.int16(d, at: 6)), r = Int(BigEndian.int16(d, at: 8))
        let top = (480 - (b - t)) / 2, left = (640 - (r - l)) / 2
        return QDRect(top: Int16(truncatingIfNeeded: top), left: Int16(truncatingIfNeeded: left),
                      bottom: Int16(truncatingIfNeeded: top + (b - t)), right: Int16(truncatingIfNeeded: left + (r - l)))
    }

    static func highlighted(_ src: QDRect) -> QDRect {
        var r = src
        r.offset(dx: highlightOffset, dy: 0)
        return r
    }

    /// The button whose destination contains (h, v), in `_HandleMSMouse`'s test order.
    public func button(at h: Int, _ v: Int) -> Button? {
        Button.allCases.first { FrontEnd.ptInRect(h, v, destinations[$0]!) }
    }

    // MARK: Op lists

    /// `_DrawMainMenu`: backdrop into comp, info-box stash, PICT 9100 into bgnd, the credit line, the six buttons,
    /// then `_DrawInterfaceText` (`info`). Nothing reaches the screen (the caller wipes or `_UpdateScreen`s).
    public func drawOps(info: String) -> [DrawOp] {
        var ops: [DrawOp] = [
            .pict(id: Self.backdropPict, dst: backdropRect, target: .comp),
            .compToSpriteWorld(src: InfoBox.textRect, dst: InfoBox.srcTextRect),
            .pict(id: Self.buttonsPict, dst: Self.buttonsPictRect, target: .bgnd),
            .pict(id: Self.creditLinePict, dst: Self.creditLineRect, target: .comp),
        ]
        for b in Button.allCases {
            ops.append(.pictSlice(id: Self.buttonsPict, src: Self.sourceRects[b]!, dst: destinations[b]!, target: .comp))
        }
        ops.append(.infoText(info, colour: InfoBox.colour))
        return ops
    }

    /// `_FlashButton(b)`'s first half: PICT 9100 into bgnd, the highlighted slice into comp, `_DrawRectsToScreen`.
    /// (Then `_ProcessMenuStars` and `_WaitFor(10)`.)
    public func flashOnOps(_ b: Button) -> [DrawOp] {
        [.pict(id: Self.buttonsPict, dst: Self.buttonsPictRect, target: .bgnd),
         .pictSlice(id: Self.buttonsPict, src: Self.highlighted(Self.sourceRects[b]!), dst: destinations[b]!,
                    target: .comp),
         .compToScreen(destinations[b]!)]
    }

    /// `_FlashButton(b)`'s second half: PICT 9100 into bgnd again, the normal slice, `_DrawRectsToScreen` (the
    /// screen-rect list still holds the one rect). (Then `_ProcessMenuStars`.)
    public func flashOffOps(_ b: Button) -> [DrawOp] {
        [.pict(id: Self.buttonsPict, dst: Self.buttonsPictRect, target: .bgnd),
         .pictSlice(id: Self.buttonsPict, src: Self.sourceRects[b]!, dst: destinations[b]!, target: .comp),
         .compToScreen(destinations[b]!)]
    }

    /// `_DrawButton(param)` with the `gBtn_Hit_*` flags (each 0 or 1): PICT 9100 into bgnd; every lit button whose
    /// flag (1) differs from `param` is restored and cleared; then `param` 1…6 is lit (flag 1); 0 lights nothing;
    /// then `_DrawRectsToScreen`. Transcribed literally: the flag value is 1, not the button number, so a lit
    /// button is restored before being re-lit unless `param` is 1.
    public func drawButtonOps(_ param: Int, hit: inout Set<Button>) -> [DrawOp] {
        var ops: [DrawOp] = [.pict(id: Self.buttonsPict, dst: Self.buttonsPictRect, target: .bgnd)]
        var screen: [QDRect] = []
        for b in Button.allCases where hit.contains(b) && param != 1 {
            ops.append(.pictSlice(id: Self.buttonsPict, src: Self.sourceRects[b]!, dst: destinations[b]!, target: .comp))
            screen.append(destinations[b]!)
            hit.remove(b)
        }
        if let b = Button(rawValue: param) {
            ops.append(.pictSlice(id: Self.buttonsPict, src: Self.highlighted(Self.sourceRects[b]!),
                                  dst: destinations[b]!, target: .comp))
            screen.append(destinations[b]!)
            hit.insert(b)
        } else if param != 0 {
            return ops                                     // default: no `_DrawRectsToScreen`
        }
        return ops + screen.map { .compToScreen($0) }
    }
}
