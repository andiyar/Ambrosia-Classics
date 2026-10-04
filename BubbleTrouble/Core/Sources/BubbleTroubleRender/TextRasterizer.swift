import BubbleTroubleCore

/// System-font text (the info box's Geneva 9, the FPS readout's port font) — the one thing the headless
/// compositor cannot draw from the game's own resources. The App implements it with CoreText (S2/S3); tests
/// use a stub.
public protocol TextRasterizer {
    /// Draw `s` in `font` at `size` with colour `rgb` (0xRRGGBB) into `into`. `at` is the QuickDraw pen
    /// position (`MoveTo`): `h` = left edge, `v` = BASELINE. With `centredIn`, `h` is replaced by
    /// `rect.left + ((rect.right − rect.left) − StringWidth(s)) / 2` (C truncating division), as
    /// `_DrawInterfaceText @ 0000898d` computes it.
    func rasterize(_ s: String, font: String, size: Int, rgb: UInt32, into: inout RGBAImage,
                   at: (h: Int, v: Int), centredIn: QDRect?)
    /// QuickDraw `StringWidth`: the pen advance of `s` (`_DrawFPS @ 00016f72` draws "FPS: " and the number in
    /// two colours, the second starting where the first left the pen). Additive to the S2 protocol (R1).
    func width(_ s: String, font: String, size: Int) -> Int
}
