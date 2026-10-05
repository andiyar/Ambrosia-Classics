import HectorShell

/// `_InitializeGWorlds` @ 0x27a36 (method-map §2): the original PNGs, each in a GWorld of the image's
/// own size, four 800×600 scratch buffers, and the window port the shell presents. Everything is
/// allocated once here; only `background` is replaced (per level, never per frame). Remaster (D11): the whole
/// set is built at one art scale k — the PNGs from `hd-4x/` and the buffers k× backed, every rect still logical
/// — and a switch replaces the whole object (`AkiController.setRemastered`).
@MainActor final class AkiGWorlds {
    /// The PNGs `_InitializeGWorlds` loads, by shipped name (background1 is the launch background).
    static let pngNames = ["misc", "tiles", "proverbs", "tile_pictures", "pause", "background1", "previews",
                           "plate", "map", "nopairs", "notavail", "arrow", "layer_buttons"]

    let misc, tiles, proverbs, tilePictures, pause, previews, plate, map, nopairs, notavail, arrow, layerButtons: ShellBitmap
    var background: ShellBitmap                                 // g+0x14, background1 at launch, replaced per level
    let scratch2c, scratch30, scratch38, scratch3c: ShellBitmap // 800×600 scratch buffers (g+0x2c/0x30/0x38/0x3c)
    let window: ShellBitmap                                     // the window port, presented by ShellView
    /// The art scale every bitmap here is backed at: 1 = the original art, 4 = Remaster (`hd-4x/`).
    let scale: Int

    /// `scale` 1 and `background` 1 are the launch set, exactly as before Remaster. A Remaster switch builds a
    /// new set at the other scale with the current `g.background` (the background GWorld as the last level
    /// load left it).
    init(assets: AkiAssets, scale: Int = 1, background number: Int = 1) throws {
        self.scale = scale
        misc = try assets.png("misc", scale: scale)                           // g+0x00
        tiles = try assets.png("tiles", scale: scale)                         // g+0x04
        proverbs = try assets.png("proverbs", scale: scale)                   // g+0x08
        tilePictures = try assets.png("tile_pictures", scale: scale)          // g+0x0c
        pause = try assets.png("pause", scale: scale)                         // g+0x10
        background = try assets.png("background\(number)", scale: scale)      // g+0x14
        previews = try assets.png("previews", scale: scale)                   // g+0x18
        plate = try assets.png("plate", scale: scale)                         // g+0x1c
        map = try assets.png("map", scale: scale)                             // g+0x20
        nopairs = try assets.png("nopairs", scale: scale)                     // g+0x24
        notavail = try assets.png("notavail", scale: scale)                   // g+0x28
        scratch2c = ShellBitmap(width: 800, height: 600, scale: scale)        // g+0x2c
        scratch30 = ShellBitmap(width: 800, height: 600, scale: scale)        // g+0x30
        arrow = try assets.png("arrow", scale: scale)                         // g+0x34
        scratch38 = ShellBitmap(width: 800, height: 600, scale: scale)        // g+0x38
        scratch3c = ShellBitmap(width: 800, height: 600, scale: scale)        // g+0x3c
        layerButtons = try assets.png("layer_buttons", scale: scale)          // g+0x40
        window = ShellBitmap(width: 800, height: 600, scale: scale)
    }
}
