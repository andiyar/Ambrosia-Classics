import Foundation

/// One QuickDraw `DrawString`/`DrawText` of the front end (plan S3, FE0; LOCKED): the Mac Roman `bytes` as the original
/// stores them, drawn with the pen at (h, v) on the baseline in `TextFont(font)`, `TextSize(size)`, `TextFace(face)`,
/// `RGBForeColor(rgb)` and transfer mode `mode` (QuickDraw `srcOr` = 1, the mode every Phase-3 caller leaves).
public struct TextRun: Equatable, Sendable {
    /// QuickDraw `srcOr`.
    public static let srcOr = 1

    public var bytes: [UInt8]
    public var font: Int16
    public var size: Int16
    public var face: Int16
    public var h: Int
    public var v: Int
    public var rgb: RGB16
    public var mode: Int

    public init(bytes: [UInt8], font: Int16, size: Int16, face: Int16, h: Int, v: Int, rgb: RGB16,
                mode: Int = TextRun.srcOr) {
        self.bytes = bytes
        self.font = font
        self.size = size
        self.face = face
        self.h = h
        self.v = v
        self.rgb = rgb
        self.mode = mode
    }
}
