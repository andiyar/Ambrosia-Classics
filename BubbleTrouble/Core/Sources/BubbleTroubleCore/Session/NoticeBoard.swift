// The in-game notices (plan 2026-10-04 btx-playable C4; FI §6a), transcribed from `_ResetNotices @ 000276d8`,
// `_PrepareNotice @ 00027829`, `_GetCurrentNotice @ 0002781d`, `_EraseNotice @ 0002784e` and `_DrawNotice @ 00027948`.
//
// Notice ids: 0 none · 1 GET READY! · 2 FIN! · 3 PAUSED (+ PICT 9030 / 9031) · 4 GAME OVER · 5 HURRY UP! · 6 LEVEL n.
//
// Ownership: the session sets every notice for now (its own sites — `_NewLevel`, pause — and the frame sites it
// derives from state: hero appear/respawn, the time-bonus HURRY UP!). C3 may move this value into `GameState` and set
// the in-frame sites itself; the transcription is meant to be reused, not re-done.

/// `_gShowWhichNotice` / `_gLastNoticeShown` / `_gEraseNotice` and the rects `_ResetNotices` computes for a 480-high
/// screen (`(480 − 38) / 2 = 221` is the common top).
public struct NoticeBoard: Equatable, Sendable {
    /// `_gShowWhichNotice`.
    public private(set) var current: Int = 0
    /// `_gLastNoticeShown`.
    public private(set) var lastShown: Int = 0
    /// `_gEraseNotice`.
    public private(set) var erasePending = false

    public init() {}

    static let top: Int16 = (480 - 0x26) / 2                                                  // 221
    /// `_gGetReadyNoticeRect` L236 T221 R403 B259.
    static let getReadyRect = QDRect(top: top, left: 0xec, bottom: top + 0x26, right: 0x193)
    /// `_gBellyUpNoticeRect` (FIN!) L256 T221 R384 B285.
    static let finRect = QDRect(top: top, left: 0x100, bottom: top + 0x40, right: 0x180)
    /// `_gPausedNoticeRect` L265 T221 R374 B259.
    static let pausedRect = QDRect(top: top, left: 0x109, bottom: top + 0x26, right: 0x176)
    /// `_gResumeNoticeRect` (PICT 9030) L155 T279 R485 B295.
    static let resumeRect = QDRect(top: top + 0x3a, left: 0x9b, bottom: top + 0x4a, right: 0x1e5)
    /// `_gResumeNotice2Rect` (PICT 9031) L190 T299 R450 B315.
    static let resume2Rect = QDRect(top: top + 0x4e, left: 0xbe, bottom: top + 0x5e, right: 0x1c2)
    /// `_gGameOverNoticeRect` L234 T221 R405 B259.
    static let gameOverRect = QDRect(top: top, left: 0xea, bottom: top + 0x26, right: 0x195)
    /// `_gHurryUpNoticeRect` L234 T221 R406 B259.
    static let hurryUpRect = QDRect(top: top, left: 0xea, bottom: top + 0x26, right: 0x196)
    /// `_gNotice_Rect_Level` L230 T221 R410 B259.
    static let levelRect = QDRect(top: top, left: 0xe6, bottom: top + 0x26, right: 0x19a)

    /// `_ResetNotices @ 000276d8`: nothing shown, nothing to erase.
    public mutating func reset() {
        current = 0
        lastShown = 0
        erasePending = false
    }

    /// `_PrepareNotice(n) @ 00027829`: erase = something was shown; last = current; current = n.
    public mutating func prepare(_ notice: Int) {
        erasePending = current != 0
        lastShown = current
        current = notice
    }

    /// `_EraseNotice @ 0002784e` (once per frame, before the draw pass): when flagged, the last notice's rects go on
    /// the bgnd-restore list (`_AddRectToBgnd`) and the screen list (`_AddRectToScreen`); the flag clears.
    public mutating func erase() -> (restore: [QDRect], flush: [QDRect]) {
        guard erasePending else { return ([], []) }
        let rects: [QDRect]
        switch lastShown {
        case 1: rects = [Self.getReadyRect]
        case 2: rects = [Self.finRect]
        case 3: rects = [Self.pausedRect, Self.resumeRect, Self.resume2Rect]
        case 4: rects = [Self.gameOverRect]
        case 5: rects = [Self.hurryUpRect]
        case 6: rects = [Self.levelRect]
        default: return ([], [])            // switch default: returns before clearing the flag (as the decompile)
        }
        erasePending = false
        return (rects, rects)
    }

    /// `_DrawNotice @ 00027948` (every frame, last before the flush): the current notice's sprites into comp, plus the
    /// rects for the screen list. `level` = `_GetCurrLevelNum()`. PAUSED also draws PICT 9030 / 9031 with
    /// `_DrawPictInRect` into the port `_IsDoubleBuffered` selects — on OS X the window port the frame is drawn
    /// into, i.e. the comp-equivalent here (so the flush shows them).
    public func draw(level: Int) -> (ops: [DrawOp], flush: [QDRect]) {
        let v = Int(Self.top)
        func strip(_ set: Int, _ h: Int, frames: Int) -> [DrawOp] {
            (0..<frames).map { .sprite(set: set, frame: $0 + 1, h: h + 0x40 * $0, v: v, mode: .normal) }
        }
        switch current {
        case 1: return (strip(9, 0xec, frames: 3), [Self.getReadyRect])
        case 2: return (strip(0xb, 0x100, frames: 2), [Self.finRect])
        case 3:
            let ops = strip(0xa, 0x109, frames: 2) + [
                .pict(id: 0x2346, dst: Self.resumeRect, target: .comp),
                .pict(id: 0x2347, dst: Self.resume2Rect, target: .comp),
            ]
            return (ops, [Self.pausedRect, Self.resumeRect, Self.resume2Rect])
        case 4: return (strip(0xc, 0xea, frames: 3), [Self.gameOverRect])
        case 5: return (strip(0xd, 0xea, frames: 3), [Self.hurryUpRect])
        case 6:
            // `_gNotice_Rect_Level + 2`: the digits sit 2 px lower than the word.
            var ops: [DrawOp]
            if level < 10 {
                ops = [.sprite(set: 0xe, frame: 1, h: 0xfe, v: v, mode: .normal),
                       .sprite(set: 0xe, frame: 2, h: 0x13e, v: v, mode: .normal),
                       .sprite(set: 0xf, frame: level + 1, h: 0x166, v: v + 2, mode: .normal)]
            } else {
                ops = [.sprite(set: 0xe, frame: 1, h: 0xf1, v: v, mode: .normal),
                       .sprite(set: 0xe, frame: 2, h: 0x131, v: v, mode: .normal),
                       .sprite(set: 0xf, frame: level % 10 + 1, h: 0x174, v: v + 2, mode: .normal),
                       .sprite(set: 0xf, frame: level / 10 + 1, h: 0x159, v: v + 2, mode: .normal)]
            }
            return (ops, [Self.levelRect])
        default:
            return ([], [])
        }
    }
}
