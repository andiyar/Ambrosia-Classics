import AppKit
import AkiCore

/// `Preferences` (method-map §1; Research notes 5, 14; file-formats §2.2): the `NSWindowController` of
/// `Preferences.nib` (`-init` @ 0x6232, `initWithWindowNibName:@"Preferences"`) — Sound, Fullscreen, Tile
/// Animation, Music and Display Level Description checkboxes over the parchment, OK / Cancel. Built once by
/// `-[Controller showPreferences:]` from the nib's `designable.nib` XML; run as a sheet on the main window
/// when windowed, app-modal over the fullscreen window otherwise. OK writes the `_p` bytes and the
/// `GameSettings` blob.
@MainActor final class PreferencesWindowController: NSObject {
    private unowned let app: AkiAppDelegate
    private unowned let controller: AkiController
    private let window: NSWindow
    private let soundCheckbox: NSButton                        // _soundCheckbox (ivar 0x28)
    private let fullscreenCheckbox: NSButton                   // _fullscreenCheckbox (ivar 0x2c)
    private let animationCheckbox: NSButton                    // _animationCheckbox (ivar 0x30)
    private let musicCheckbox: NSButton                        // _musicCheckbox (ivar 0x34)
    private let descriptionCheckbox: NSButton                  // _descriptionCheckbox (ivar 0x38)
    /// "Remastered art" (D11, not in the nib): one row below the nib's checkboxes; the window is one row taller.
    private let remasterCheckbox: NSButton
    private let content: PaperBackgroundView
    /// The art scale `content`'s paper was loaded at (reloaded after a Remaster switch).
    private var paperScale: Int
    private var isSheet = false                                // ivar 0x3c: 1 in a sheet, 0 when modal

    /// The window and its controls from `Preferences.nib` XML: title, content size and style mask;
    /// `PaperBackgroundView` content (the nib's custom class); the five checkbox outlets and the buttons
    /// wired to `save:` / `cancel:`, with their nib frames, titles, fonts and key equivalents, added in the
    /// nib's subview order (OK, Cancel, Sound, Fullscreen, Tile Animation, Music, Display Level Description).
    /// D11 adds "Remastered art" last: `RemasterSetting.preferencesRow` grows the window by the nib's checkbox
    /// pitch, moves the five checkboxes up by it (same distance from the window top) and leaves OK / Cancel at
    /// their nib frames (same distance from the bottom).
    init(app: AkiAppDelegate) throws {
        self.app = app
        let controller = app.controller
        self.controller = controller
        let nib = try CocoaNib(data: controller.assets.lproj("Preferences.nib/designable.nib"))
        guard let w = nib.window,
              let sound = nib.control(outlet: "_soundCheckbox"), let fullscreen = nib.control(outlet: "_fullscreenCheckbox"),
              let animation = nib.control(outlet: "_animationCheckbox"), let music = nib.control(outlet: "_musicCheckbox"),
              let description = nib.control(outlet: "_descriptionCheckbox"),
              let ok = nib.control(action: "save:"), let cancel = nib.control(action: "cancel:")
        else { throw AkiAssets.AssetError.missing("Preferences.nib") }
        let row = RemasterSetting.preferencesRow(window: w, checkboxes: [sound, fullscreen, animation, music, description],
                                                 title: "Remastered art")

        let size = NSRect(x: 0, y: 0, width: row.window.contentWidth, height: row.window.contentHeight)
        window = NSWindow(contentRect: size, styleMask: NSWindow.StyleMask(rawValue: UInt(w.styleMask)),
                          backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.title = w.title
        content = PaperBackgroundView(frame: size, paper: controller.assets.image("paper"))
        paperScale = controller.artScale
        window.contentView = content

        soundCheckbox = Self.checkbox(row.checkboxes[0])
        fullscreenCheckbox = Self.checkbox(row.checkboxes[1])
        animationCheckbox = Self.checkbox(row.checkboxes[2])
        musicCheckbox = Self.checkbox(row.checkboxes[3])
        descriptionCheckbox = Self.checkbox(row.checkboxes[4])
        remasterCheckbox = Self.checkbox(row.remaster)

        super.init()

        let okButton = Self.pushButton(ok, target: self, action: #selector(save(_:)))
        let cancelButton = Self.pushButton(cancel, target: self, action: #selector(cancel(_:)))
        for view in [okButton, cancelButton, soundCheckbox, fullscreenCheckbox, animationCheckbox,
                     musicCheckbox, descriptionCheckbox, remasterCheckbox] {
            content.addSubview(view)
        }
    }

    /// `-[Preferences _updateUI]` @ 0x6584 (otool): Sound = p+0x210 > 1, Music = p+0x20e > 1, Tile
    /// Animation = p+0x213 ≠ 0, Display Level Description = p+0x214 ≠ 0, Fullscreen = p+0x212 ≠ 0.
    func updateUI() {
        let p = controller.p
        soundCheckbox.state = p.soundCheckbox ? .on : .off
        musicCheckbox.state = p.musicCheckbox ? .on : .off
        animationCheckbox.state = p.tileAnimation != 0 ? .on : .off
        descriptionCheckbox.state = p.showDescription != 0 ? .on : .off
        fullscreenCheckbox.state = p.fullscreen != 0 ? .on : .off
        remasterCheckbox.state = controller.remasterActive ? .on : .off   // D11: the effective setting
        remasterCheckbox.isEnabled = controller.remasterAvailable
        if paperScale != controller.artScale {                 // a Remaster switch since the window was built
            paperScale = controller.artScale
            content.paper = controller.assets.image("paper")
        }
    }

    /// `-[Preferences runModal]` @ 0x64fc (DC:2337): `_updateUI`, ivar 0x3c = 0, `scheduleSetShieldingLevel`
    /// (centred on the display, above the fullscreen window), `runModalForWindow:`.
    func runModal() {
        updateUI()
        isSheet = false
        window.scheduleShieldingLevel()
        NSApp.runModal(for: window)
    }

    /// `-[Preferences beginSheetModalForWindow:modalDelegate:didEndSelector:contextInfo:]` @ 0x647b
    /// (DC:2314): `_updateUI`, ivar 0x3c = 1, `beginSheet:modalForWindow:…` with the Controller as delegate;
    /// its `preferencesSheetDidEnd:returnCode:contextInfo:` @ 0x41c3 sends `unpause` (method-map §1).
    func beginSheet(on window: NSWindow) {
        updateUI()
        isSheet = true
        let controller = controller
        window.beginSheet(self.window) { _ in controller.unpause() }
    }

    /// `-[Preferences cancel:]` @ 0x6264 (DC:2245): in a sheet `endSheet:`, else `stopModalWithCode:1`;
    /// then the window ordered out.
    @objc func cancel(_ sender: Any?) {
        if isSheet {
            window.sheetParent?.endSheet(window)
        } else {
            NSApp.stopModal(withCode: NSApplication.ModalResponse(rawValue: 1))
        }
        window.orderOut(nil)
    }

    /// `-[Preferences save:]` @ 0x62ee (DC:2271): `cancel:`, then p+0x210 / p+0x20e = old % 2 + 2 · box
    /// (Sound, Music), p+0x213 = Tile Animation, p+0x214 = Display Level Description; a changed Fullscreen
    /// box → p+0x212 = box and `toggleFullscreen:` after delay 0; `_SavePrefs`; `_PlayMovie` (args lost →
    /// 0x80, Q15) — which stops or resumes Theme 3 by the new Music bit. Then (D11) the Remastered art box,
    /// applied live (`setRemastered`; a no-op without the art set).
    @objc func save(_ sender: Any?) {
        cancel(sender)
        controller.p.setSoundCheckbox(soundCheckbox.state == .on)
        controller.p.setMusicCheckbox(musicCheckbox.state == .on)
        controller.p.tileAnimation = animationCheckbox.state == .on ? 1 : 0
        controller.p.showDescription = descriptionCheckbox.state == .on ? 1 : 0
        let fullscreenOn = fullscreenCheckbox.state == .on
        if (controller.p.fullscreen != 0) != fullscreenOn {
            controller.p.fullscreen = fullscreenOn ? 1 : 0
            app.perform(#selector(AkiAppDelegate.toggleFullscreen(_:)), with: nil, afterDelay: 0)
        }
        controller.savePrefs()
        controller.music.playMovie(0x80)
        if remasterCheckbox.isEnabled {
            controller.setRemastered(remasterCheckbox.state == .on)
        }
    }

    // MARK: Nib conversion (IB3 frames are already AppKit's, bottom-left)

    private static func frame(_ c: CocoaNib.Control) -> NSRect {
        NSRect(x: c.x, y: c.y, width: c.width, height: c.height)
    }

    private static func font(_ c: CocoaNib.Control) -> NSFont {
        let size = CGFloat(c.fontSize ?? 13)
        return c.fontName.flatMap { NSFont(name: $0, size: size) } ?? .systemFont(ofSize: size)
    }

    /// A nib checkbox: its title, frame and font; its state is `_updateUI`'s before every show.
    private static func checkbox(_ c: CocoaNib.Control) -> NSButton {
        let box = NSButton(checkboxWithTitle: c.title ?? "", target: nil, action: nil)
        box.frame = frame(c)
        box.font = font(c)
        return box
    }

    private static func pushButton(_ c: CocoaNib.Control, target: AnyObject, action: Selector) -> NSButton {
        let button = NSButton(title: c.title ?? "", target: target, action: action)
        button.bezelStyle = .push
        button.frame = frame(c)
        button.font = font(c)
        button.keyEquivalent = c.keyEquivalent ?? ""
        return button
    }
}
