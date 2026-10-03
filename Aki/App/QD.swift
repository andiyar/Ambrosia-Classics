import AkiCore
import HectorShell

/// `_DrawToGWorld` @ 0x4a04 (DC:1494): mode −9 → `CopyBits(src, dst, srcRect, dstRect)` (stretches when
/// the sizes differ); any other mode → `CopyDeepMask(src, mask, dst, srcRect, maskRect, dstRect)`.
/// `mask` is ignored for mode −9, as in the original.
enum QD {
    static func drawToGWorld(_ src: ShellBitmap, _ dst: ShellBitmap, mask: ShellBitmap,
                             srcRect: QDRect, dstRect: QDRect, maskRect: QDRect, mode: Int) {
        if mode == -9 {
            dst.copyBits(from: src, srcRect: ShellRect(srcRect), dstRect: ShellRect(dstRect))
        } else {
            dst.copyDeepMask(from: src, mask: mask, srcRect: ShellRect(srcRect),
                             maskRect: ShellRect(maskRect), dstRect: ShellRect(dstRect))
        }
    }
}

extension ShellRect {
    /// The same QuickDraw rect (`SetRect(left, top, right, bottom)`, right/bottom exclusive).
    init(_ r: QDRect) {
        self.init(left: r.left, top: r.top, right: r.right, bottom: r.bottom)
    }
}
