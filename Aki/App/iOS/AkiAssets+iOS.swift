import UIKit

extension AkiAssets {
    /// `[NSImage imageNamed:]` semantics over this bundle on iPad: `<name>.png` from the bundle (nil when absent).
    /// Remaster (`artScale` > 1, D11): the `hd-4x/` file at the scale that gives it the original's point size, so
    /// every layout is the original's, just sharper; the original when the bundle lacks that file or it fails to
    /// load (logged once, U3 review).
    func image(_ name: String) -> UIImage? {
        guard artScale > 1, let original = UIImage(named: name, in: bundle, with: nil), original.size.width > 0 else {
            return UIImage(named: name, in: bundle, with: nil)
        }
        guard let url = remasterURL(name), let hd = UIImage(contentsOfFile: url.path), let cg = hd.cgImage else {
            noteRemasterFallback("\(name).png")
            return original
        }
        return UIImage(cgImage: cg, scale: CGFloat(cg.width) / original.size.width, orientation: .up)
    }
}
