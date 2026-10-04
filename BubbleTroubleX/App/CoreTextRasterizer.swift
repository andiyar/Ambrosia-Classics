import BubbleTroubleCore
import BubbleTroubleRender
import CoreGraphics
import CoreText
import Foundation

/// QuickDraw text for the compositor (`TextRasterizer`, plan S2): `DrawString` at a `MoveTo` pen position in a
/// named font and size (`_DrawInterfaceText @ 0000898d`: Geneva 9; `_DrawFPS @ 00016f72`: the System font 12),
/// drawn with CoreText. Glyph coverage is blended over the destination toward `rgb`, and every touched pixel is
/// written opaque (alpha 0xFF): the compositor's buffers are opaque and its srcCopy moves pixels unchanged.
final class CoreTextRasterizer: TextRasterizer {
    private var fonts: [String: CTFont] = [:]

    /// `font` by its classic name; "System" is the system font (QuickDraw font 0). CoreText substitutes a
    /// fallback when the named font is absent.
    private func ctFont(_ name: String, size: Int) -> CTFont {
        let key = "\(name)/\(size)"
        if let f = fonts[key] { return f }
        let f: CTFont = name == "System"
            ? CTFontCreateUIFontForLanguage(.system, CGFloat(size), nil)
                ?? CTFontCreateWithName("Lucida Grande" as CFString, CGFloat(size), nil)
            : CTFontCreateWithName(name as CFString, CGFloat(size), nil)
        fonts[key] = f
        return f
    }

    private func line(_ s: String, font: CTFont) -> CTLine {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        return CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attributes))
    }

    func width(_ s: String, font: String, size: Int) -> Int {
        let l = line(s, font: ctFont(font, size: size))
        return Int(CTLineGetTypographicBounds(l, nil, nil, nil).rounded())
    }

    func rasterize(_ s: String, font: String, size: Int, rgb: UInt32, into image: inout RGBAImage,
                   at: (h: Int, v: Int), centredIn: QDRect?) {
        guard !s.isEmpty else { return }
        let f = ctFont(font, size: size)
        let l = line(s, font: f)
        var ascent: CGFloat = 0, descent: CGFloat = 0
        let advance = Int(CTLineGetTypographicBounds(l, &ascent, &descent, nil).rounded())
        var h = at.h
        if let r = centredIn {
            let rw = Int(r.right) - Int(r.left)
            h = Int(r.left) + (rw - advance) / 2                      // C truncating division
        }
        // An alpha-only coverage bitmap: `pad` columns either side, `above` rows over the baseline, `below` under.
        let pad = 2
        let above = Int(ascent.rounded(.up)) + 1, below = Int(descent.rounded(.up)) + 1
        let w = advance + 2 * pad, ht = above + below
        guard w > 0, ht > 0 else { return }
        var coverage = [UInt8](repeating: 0, count: w * ht)
        coverage.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: ht, bitsPerComponent: 8,
                                      bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else { return }
            // Antialiased, as 2008 OS X QuickDraw drew text above its 8 pt smoothing threshold (Geneva 9 included);
            // no LCD subpixel smoothing (coverage only).
            ctx.setShouldAntialias(true)
            ctx.setShouldSmoothFonts(false)
            ctx.setFillColor(CGColor(gray: 0, alpha: 1))
            ctx.textPosition = CGPoint(x: CGFloat(pad), y: CGFloat(below))
            CTLineDraw(l, ctx)
        }
        // Row r of the bitmap (top first) lands on image row v − above + r; column c on h − pad + c.
        let red = (rgb >> 16) & 0xFF, green = (rgb >> 8) & 0xFF, blue = rgb & 0xFF
        for r in 0..<ht {
            let y = at.v - above + r
            guard y >= 0, y < image.height else { continue }
            for c in 0..<w {
                let a = UInt32(coverage[r * w + c])
                guard a != 0 else { continue }
                let x = h - pad + c
                guard x >= 0, x < image.width else { continue }
                let dst = image[x, y]
                func mix(_ src: UInt32, _ shift: UInt32) -> UInt32 {
                    let d = (dst >> shift) & 0xFF
                    return ((src * a + d * (255 - a) + 127) / 255) << shift
                }
                image[x, y] = 0xFF00_0000 | mix(red, 16) | mix(green, 8) | mix(blue, 0)
            }
        }
    }
}
