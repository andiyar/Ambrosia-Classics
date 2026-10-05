import AppKit

extension AkiAssets {
    /// `[NSImage imageNamed:]` semantics over this bundle (nil when absent). Remaster (`artScale` > 1, D11):
    /// the `hd-4x/` file, sized to the original's point size so every layout is the original's, just sharper;
    /// the original when the bundle lacks that file or it fails to load (logged once, U3 review).
    func image(_ name: String) -> NSImage? {
        guard artScale > 1, let original = bundle.image(forResource: name) else {
            return bundle.image(forResource: name)
        }
        guard let url = remasterURL(name), let hd = NSImage(contentsOf: url), hd.isValid else {
            noteRemasterFallback("\(name).png")
            return original
        }
        hd.size = original.size
        for rep in hd.representations {
            rep.size = original.size
        }
        return hd
    }
}
