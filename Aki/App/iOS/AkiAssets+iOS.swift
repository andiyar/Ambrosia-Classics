import UIKit

extension AkiAssets {
    /// `[NSImage imageNamed:]` semantics over this bundle on iPad: `<name>.png` from the bundle (nil when absent).
    func image(_ name: String) -> UIImage? {
        UIImage(named: name, in: bundle, with: nil)
    }
}
