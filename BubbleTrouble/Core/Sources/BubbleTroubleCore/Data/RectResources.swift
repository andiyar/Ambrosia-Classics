import Foundation

/// The `Rect` resources 1…7 of `Bubble Trouble X.rsrc` — the main-menu button hot rects.
///
/// Stored **Left, Top, Right, Bottom** (`TMPL 128`; `_GetRectRsrc @ 0000c9e9`), not QuickDraw's
/// top,left,bottom,right — data-formats §7 as corrected by T0 of plan 2026-10-04-btx-playable.
/// `Rect 1` "Interface - New Button" = `00a5 00e4 013b 0106` = L165 T228 R315 B262.
public struct RectResources: Equatable, Sendable {
    /// Resource ids as named in the file ("Interface - New Button" …).
    public static let newGame = 1, demo = 2, scores = 3, prefs = 4, credits = 5, quit = 6, register = 7

    private let rects: [Int: QDRect]
    private let names: [Int: String]

    public init(rects: [Int: QDRect], names: [Int: String] = [:]) {
        self.rects = rects
        self.names = names
    }

    /// Decodes one 8-byte `Rect` resource: i16 left, top, right, bottom (big-endian).
    public static func decode(_ data: Data, id: Int = 0) throws -> QDRect {
        guard data.count == 8 else {
            throw BTXDataError.badSize(type: "Rect", id: Int16(truncatingIfNeeded: id), size: data.count)
        }
        return QDRect(top: BigEndian.int16(data, at: 2), left: BigEndian.int16(data, at: 0),
                      bottom: BigEndian.int16(data, at: 6), right: BigEndian.int16(data, at: 4))
    }

    public var ids: [Int] { rects.keys.sorted() }
    public func rect(_ id: Int) -> QDRect? { rects[id] }
    public func name(_ id: Int) -> String? { names[id] }
}
