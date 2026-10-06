import AppKit
import AkiCore
import HectorShell

/// The Mac `AkiHost`: today's AppKit code, unchanged. Every modal runs app-modal (`NSApp.runModal` /
/// `NSAlert.runModal`) and its completion is called BEFORE the method returns, so each shared call site's
/// ordering is exactly the pre-split one (plan C2). AppKit itself provides what an asynchronous host must
/// emulate: the idle `Timer` cannot re-fire inside its own callout's nested modal; `_GetMouseLocation` tests
/// `NSApp.modalWindow`; the menu bar and the game window take no input while a modal window is up.
extension AkiAppDelegate: AkiHost {
    /// `_DrawToWindow`'s flush: the window port into the shell view.
    func present(_ window: ShellBitmap) {
        shell.view.present(window)
    }

    /// `_GetMouseLocation` @ 0x46ee (DC:1413): (0, 0) unless the app is active, no window is modal, and
    /// the game is fullscreen or the main window is key; else the pointer in the 800×600 canvas,
    /// truncating and unclamped.
    func mouseLocation() -> ShellPoint {
        guard NSApp.isActive, NSApp.modalWindow == nil,
              shell.isFullscreen || shell.windowedWindow.isKeyWindow else { return .zero }
        return shell.view.logicalMouseLocation()
    }

    /// `GetDblTime` (Q29): the system double-click interval in ticks.
    var doubleClickTicks: Int {
        Int(NSEvent.doubleClickInterval * 60)
    }

    func runDialog(_ name: String, texts: [Int: String], completion: @escaping (_ command: String?) -> Void) {
        let command = CarbonDialog.run(name, app: self, texts: texts)
        completion(command)
    }

    func showSplash(named name: String, timeout: Int, completion: @escaping () -> Void) {
        AkiSplash.show(named: name, timeout: timeout, app: self)
        completion()
    }

    func showRandomProverb(completion: @escaping () -> Void) {
        AkiSplash.randomProverb(app: self)                       // _RandomProverbScreen
        completion()
    }

    /// `_SelectMapArea`'s alert: NSAlert alertWithMessageText:"Practice Mode" defaultButton:"Practice Level"
    /// alternateButton:"Cancel" otherButton:nil informativeTextWithFormat:…; g+0x7c = (alternate).
    func runPracticeAlert(completion: @escaping (_ cancelled: Bool) -> Void) {
        let assets = controller.assets!
        let alert = NSAlert()
        alert.messageText = assets.localized("Practice Mode")
        alert.informativeText = assets.localized(
            "You will not be able to progress to the next level when playing in practice mode.")
        alert.addButton(withTitle: assets.localized("Practice Level"))
        alert.addButton(withTitle: assets.localized("Cancel"))
        if shell.isFullscreen {
            alert.window.scheduleShieldingLevel()
        }
        completion(alert.runModal() == .alertSecondButtonReturn)
    }

    func runLevelDescription(layout: Int, custom: Bool, completion: @escaping () -> Void) {
        LevelDescriptionWindowController.runModal(layout: layout, custom: custom, app: self)
        completion()
    }

    func showPreferences() {
        showPreferences(nil)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    /// `-[Controller showAboutBox:]` @ 0x327a (Q10).
    func showAbout() {
        AkiInfoWindows.showAbout(controller: controller)
    }

    /// `-[Controller showReleaseNotes:]` @ 0x358e (Q10).
    func showReleaseNotes() {
        AkiInfoWindows.showReleaseNotes(controller: controller)
    }

    /// `-[Controller showHandbook:]` @ 0x33b2 (DC:587): `openFile:withApplication:@"Preview"` on the
    /// shipped `Aki Handbook.pdf` — opened in Preview (`com.apple.Preview`); only if Preview is missing
    /// does it go to the default PDF handler.
    func showHandbook() {
        guard let url = controller.assets.url("Aki Handbook.pdf") else { return }
        if let preview = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Preview") {
            NSWorkspace.shared.open([url], withApplicationAt: preview, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }
}
