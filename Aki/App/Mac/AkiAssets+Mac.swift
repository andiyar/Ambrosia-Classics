import AppKit

extension AkiAssets {
    /// `[NSImage imageNamed:]` semantics over this bundle (nil when absent). Remaster (`artScale` > 1, D11):
    /// the `hd-4x/` file, sized to the original's point size so every layout is the original's, just sharper;
    /// the original when the bundle lacks that file.
    func image(_ name: String) -> NSImage? {
        guard artScale > 1, let url = remasterURL(name), let original = bundle.image(forResource: name),
              let hd = NSImage(contentsOf: url) else {
            return bundle.image(forResource: name)
        }
        hd.size = original.size
        for rep in hd.representations {
            rep.size = original.size
        }
        return hd
    }
}
