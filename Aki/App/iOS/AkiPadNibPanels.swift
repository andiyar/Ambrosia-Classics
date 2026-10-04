import AkiCore
import UIKit

/// A Cocoa nib window (`designable.nib`, IB3) as an overlay: the content size and the controls at their nib
/// frames (AppKit bottom-left converted to top-left: y = H − y − h) over the parchment
/// (`PaperBackgroundView`), with the window's title bar when `titled`. Buttons with the key equivalent
/// Return / Esc answer those keys.
@MainActor class CocoaPanelOverlay: AkiOverlay {
    let content: PaperView
    private let contentHeight: CGFloat
    private var keyButtons: [(input: String, button: AquaButton)] = []

    init(window: CocoaNib.Window, titled: Bool, paper: UIImage?) {
        let width = CGFloat(window.contentWidth), height = CGFloat(window.contentHeight)
        let bar: CGFloat = titled ? AquaTitleBar.height : 0
        let panel = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height + bar))
        panel.backgroundColor = UIColor(white: 0.93, alpha: 1)
        if titled {
            panel.addSubview(AquaTitleBar(width: width, title: window.title))
        }
        content = PaperView(frame: CGRect(x: 0, y: bar, width: width, height: height), paper: paper)
        content.isUserInteractionEnabled = true
        content.clipsToBounds = true
        panel.addSubview(content)
        contentHeight = height
        super.init(panel: panel, logicalSize: panel.bounds.size)
    }

    func frame(_ c: CocoaNib.Control) -> CGRect {
        CGRect(x: CGFloat(c.x), y: contentHeight - CGFloat(c.y) - CGFloat(c.height), width: CGFloat(c.width), height: CGFloat(c.height))
    }

    func font(_ c: CocoaNib.Control) -> UIFont {
        AquaStyle.font(name: c.fontName, size: CGFloat(c.fontSize ?? 13))
    }

    func label(_ c: CocoaNib.Control, wrapping: Bool) -> TopAlignedLabel {
        let label = TopAlignedLabel(frame: frame(c))
        label.font = font(c)
        label.textColor = AquaStyle.text
        label.numberOfLines = wrapping ? 0 : 1
        label.lineBreakMode = wrapping ? .byWordWrapping : .byTruncatingTail
        label.text = c.title ?? ""
        return label
    }

    func checkbox(_ c: CocoaNib.Control) -> AquaCheckbox {
        let box = AquaCheckbox(frame: frame(c), title: c.title ?? "", font: font(c))
        box.isOn = c.isOn
        return box
    }

    /// An AppKit push button's frame carries the bezel's insets (6 left/right, 4 top, 7 bottom at regular
    /// size); the drawn bezel is the frame minus them. Return makes the default (blue) button.
    func pushButton(_ c: CocoaNib.Control, action: Selector) -> AquaButton {
        let bezel = frame(c).inset(by: UIEdgeInsets(top: 4, left: 6, bottom: 7, right: 6))
        let key = c.keyEquivalent ?? ""
        let button = AquaButton(frame: bezel, title: c.title ?? "", font: font(c), isDefault: key == "\r")
        button.addTarget(self, action: action, for: .touchUpInside)
        if key == "\r" || key == "\u{1B}" {
            keyButtons.append((key == "\r" ? "\r" : UIKeyCommand.inputEscape, button))
        }
        return button
    }

    override var keyCommands: [UIKeyCommand]? {
        keyButtons.map { entry in
            let command = UIKeyCommand(input: entry.input, modifierFlags: [], action: #selector(keyButton(_:)))
            command.wantsPriorityOverSystemBehavior = true
            return command
        }
    }

    @objc private func keyButton(_ sender: UIKeyCommand) {
        guard isTopOverlay, let button = keyButtons.first(where: { $0.input == sender.input })?.button else { return }
        button.sendActions(for: .touchUpInside)
    }
}

/// `LevelDescriptionWindowController` on iPad (`Aki/App/Mac/LevelDescriptionWindowController.swift`): the
/// window of `LevelDescription.nib` — the level's preview, its title and description, the "Display Level
/// Description" checkbox, Continue / Cancel. Built once and shared, so the checkbox keeps its state across
/// shows within a session; it starts as archived (OFF, Q5) and `setup` never sets it.
@MainActor final class LevelDescriptionOverlay: CocoaPanelOverlay {
    private unowned let controller: AkiController
    private var imageView: UIImageView!                            // _imageView
    private var titleField: TopAlignedLabel!                       // _titleTextField
    private var descriptionField: TopAlignedLabel!                 // _descriptionTextField
    private var checkboxView: AquaCheckbox!                        // _checkbox

    init(controller: AkiController) {
        self.controller = controller
        let nib: CocoaNib
        do {
            nib = try CocoaNib(data: controller.assets.lproj("LevelDescription.nib/designable.nib"))
        } catch {
            fatalError("Aki: cannot read LevelDescription.nib: \(error)")
        }
        guard let w = nib.window, let image = nib.control(outlet: "_imageView"),
              let title = nib.control(outlet: "_titleTextField"), let text = nib.control(outlet: "_descriptionTextField"),
              let box = nib.control(outlet: "_checkbox"), let cont = nib.control(action: "continue:"),
              let cancel = nib.control(action: "cancel:")
        else { fatalError("Aki: LevelDescription.nib lacks its window or controls") }
        super.init(window: w, titled: (w.styleMask & 1) != 0, paper: controller.assets.image("paper"))

        imageView = UIImageView(frame: frame(image))
        imageView.contentMode = .center                               // NSScaleProportionallyDown, centred
        imageView.clipsToBounds = true
        titleField = label(title, wrapping: false)
        descriptionField = label(text, wrapping: true)
        checkboxView = checkbox(box)                                  // archived OFF (Q5)
        let continueButton = pushButton(cont, action: #selector(continueLevel))
        let cancelButton = pushButton(cancel, action: #selector(cancelLevel))
        for view in [imageView!, checkboxView!, continueButton, cancelButton, titleField!, descriptionField!] as [UIView] {
            content.addSubview(view)                                  // nib subview order
        }
    }

    /// `_setupWithTitle:description:image:` @ 0x2a0a7 (DC:11446).
    func setup(title: String, description: String, image: UIImage?) {
        titleField.text = title
        descriptionField.text = description
        imageView.image = image
        if let image, image.size.width > imageView.bounds.width || image.size.height > imageView.bounds.height {
            imageView.contentMode = .scaleAspectFit
        } else {
            imageView.contentMode = .center
        }
    }

    /// `-[LevelDescriptionWindowController cancel:]` @ 0x29fcd (DC:11417): g+0x7c = 1, closed.
    @objc private func cancelLevel() {
        guard isTopOverlay else { return }
        controller.g.cancelStart = true
        close()
    }

    /// `-[LevelDescriptionWindowController continue:]` @ 0x2a02e (DC:11430): p+0x214 = (checkbox on), closed.
    /// (No `_SavePrefs` here.)
    @objc private func continueLevel() {
        guard isTopOverlay else { return }
        controller.p.showDescription = checkboxView.isOn ? 1 : 0
        close()
    }
}

/// `Preferences` on iPad (`Aki/App/Mac/PreferencesWindowController.swift`): `Preferences.nib` — Sound,
/// Fullscreen, Tile Animation, Music and Display Level Description over the parchment, OK / Cancel — shown
/// as the Mac's windowed path shows it (a sheet: no title bar; the game paused while it is up, `unpause` when
/// it ends). OK writes the `_p` bytes and the `GameSettings` blob. The Fullscreen box is shown and saved
/// (p+0x212) but has no effect on iPad: there is no window to swap.
@MainActor final class PreferencesOverlay: CocoaPanelOverlay {
    private unowned let controller: AkiController
    private var sound: AquaCheckbox!, fullscreen: AquaCheckbox!, animation: AquaCheckbox!
    private var music: AquaCheckbox!, levelDescription: AquaCheckbox!

    init(controller: AkiController) throws {
        self.controller = controller
        let nib = try CocoaNib(data: controller.assets.lproj("Preferences.nib/designable.nib"))
        guard let w = nib.window,
              let sound = nib.control(outlet: "_soundCheckbox"), let fullscreen = nib.control(outlet: "_fullscreenCheckbox"),
              let animation = nib.control(outlet: "_animationCheckbox"), let music = nib.control(outlet: "_musicCheckbox"),
              let description = nib.control(outlet: "_descriptionCheckbox"),
              let ok = nib.control(action: "save:"), let cancel = nib.control(action: "cancel:")
        else { throw AkiAssets.AssetError.missing("Preferences.nib") }
        super.init(window: w, titled: false, paper: controller.assets.image("paper"))
        self.sound = checkbox(sound)
        self.fullscreen = checkbox(fullscreen)
        self.animation = checkbox(animation)
        self.music = checkbox(music)
        self.levelDescription = checkbox(description)
        let okButton = pushButton(ok, action: #selector(save))
        let cancelButton = pushButton(cancel, action: #selector(cancelPreferences))
        for view in [okButton, cancelButton, self.sound!, self.fullscreen!, self.animation!, self.music!,
                     self.levelDescription!] as [UIView] {
            content.addSubview(view)                                  // nib subview order
        }
    }

    /// `-[Preferences _updateUI]` @ 0x6584.
    func updateUI() {
        let p = controller.p
        sound.isOn = p.soundCheckbox
        music.isOn = p.musicCheckbox
        animation.isOn = p.tileAnimation != 0
        levelDescription.isOn = p.showDescription != 0
        fullscreen.isOn = p.fullscreen != 0
    }

    /// `-[Preferences cancel:]` @ 0x6264: the sheet ends (its end sends `unpause` — the host's `onClose`).
    @objc private func cancelPreferences() {
        guard isTopOverlay else { return }
        close()
    }

    /// `-[Preferences save:]` @ 0x62ee (DC:2271): `cancel:`, then p+0x210 / p+0x20e from Sound / Music,
    /// p+0x213 Tile Animation, p+0x214 Display Level Description, p+0x212 Fullscreen (no toggle on iPad);
    /// `_SavePrefs`; `_PlayMovie(0x80)`.
    @objc private func save() {
        guard isTopOverlay else { return }
        close()
        controller.p.setSoundCheckbox(sound.isOn)
        controller.p.setMusicCheckbox(music.isOn)
        controller.p.tileAnimation = animation.isOn ? 1 : 0
        controller.p.showDescription = levelDescription.isOn ? 1 : 0
        let fullscreenOn = fullscreen.isOn
        if (controller.p.fullscreen != 0) != fullscreenOn {
            controller.p.fullscreen = fullscreenOn ? 1 : 0
        }
        controller.savePrefs()
        controller.music.playMovie(0x80)
    }
}
