import AppKit

extension AkiAssets {
    /// `[NSImage imageNamed:]` semantics over this bundle (nil when absent).
    func image(_ name: String) -> NSImage? {
        bundle.image(forResource: name)
    }
}
