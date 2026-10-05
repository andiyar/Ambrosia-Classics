import AVFoundation
import AkiCore
import HectorShell
import UIKit
import os

/// The iPad `AkiHost` (plan C1–C6, D7): HectorShell's `ShellViewController` as the window's root, the
/// shared `AkiController` over it (owned here — `controller.host` is weak), the 0.05 s idle loop, the touch
/// / key input, and every host modal as an overlay above the canvas.
///
/// **Modals (C4).** Overlays STACK in `chrome` (a new one above the current; dismissal returns to the one
/// below; each completion runs on dismissal, so nested ones run in LIFO order, each exactly once on the main
/// actor). While any modal is up (`modalDepth` > 0, or a sheet / alert is presented) the canvas gets no
/// clicks or keys, the menu commands are off, the Give Up X is hidden and `mouseLocation()` is (0, 0).
/// **Idle freeze:** a modal requested from INSIDE the idle tick stops the idle timer until its completion
/// has run (the Mac's Timer cannot re-fire during its own nested `runModal`); one opened from a click or a
/// menu leaves it running (the Mac's `.common`-mode timer). The freeze is counted per idle-originated modal.
@MainActor final class AkiPadHost: NSObject, AkiHost, ShellTouchInputHandler {
    let controller: AkiController
    private var window: UIWindow?
    /// The window's root, kept across scene reconnects (the shell, or the dev-build missing-data message).
    private var rootController: UIViewController?
    private var shellController: ShellViewController?
    private var chrome: AkiChromeView?
    private let giveUpButton = UIButton(type: .custom)
    private var idleTimer: ShellIdleTimer?
    /// `_launched` (ivar 0x0e): set by `finishLaunch`, 0.5 s after launch.
    private(set) var launched = false
    private var resourcesLoaded = false
    private var sceneActive = false
    /// Host modals up (overlays + the Practice alert).
    private var modalDepth = 0
    /// True while the idle tick (or a completion of a modal it opened) runs.
    private var inIdleContext = false
    /// Idle-originated modals still up or still completing; the idle timer is stopped while > 0.
    private var frozenModals = 0
    private var levelDescription: LevelDescriptionOverlay?   // the shared controller, created on first use
    private var preferences: PreferencesOverlay?             // ivar 0x20, created on first use

    override init() {
        controller = AkiController()
        super.init()
        controller.host = self
    }

    private var shellView: ShellTouchView? { shellController?.shellView }

    /// Whether a host modal, a sheet or an alert is up.
    var isModalUp: Bool {
        modalDepth > 0 || shellController?.presentedViewController != nil
    }

    /// About / Preferences / Help / Handbook / Release Notes: on once the game is loaded and no modal is up.
    var hostCommandsEnabled: Bool { resourcesLoaded && !isModalUp }

    /// "Remastered Art" (D11): as the host commands, and only with the art set in the bundle.
    var remasterCommandEnabled: Bool { hostCommandsEnabled && controller.remasterAvailable }

    /// The shared per-tag state (retitle + enabled), off before launch, for a later phase's tag, and while
    /// a modal is up.
    func menuState(tag: Int) -> (enabled: Bool, title: String?) {
        guard resourcesLoaded else { return (false, nil) }
        let state = controller.menuState(tag: tag)
        return (state.enabled && !AkiController.notYetBuilt.contains(tag) && !isModalUp, state.title)
    }

    // MARK: Launch (the Mac's applicationDidFinishLaunching, in its order)

    /// The window for a connecting scene. The game launches ONCE per process: the first scene builds the
    /// shell, loads the resources and starts the idle loop; a scene that connects after the previous one
    /// disconnected gets a new window over the SAME root view controller (its overlays, the modal counts and
    /// the idle timer are untouched).
    func attach(to scene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = .light              // the 2008 app always drew Aqua
        window.backgroundColor = .black
        self.window = window
        if let root = rootController {
            window.rootViewController = root
            window.makeKeyAndVisible()
            restoreFirstResponder()
        } else {
            launch(in: window)
        }
        return window
    }

    /// The scene went away: only its window is dropped (the root view controller is kept for the next one).
    func sceneDidDisconnect() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
    }

    private func launch(in window: UIWindow) {
        configureAudioSession()

        let assets = AkiAssets()
        #if DEBUG
        if !assets.missingFiles().isEmpty {
            let missing = MissingDataViewController()
            rootController = missing
            window.rootViewController = missing
            window.makeKeyAndVisible()
            return
        }
        #endif
        controller.beginLaunch(assets: assets)                  // _Initialize: _LoadPrefs
        controller.loadLaunchResources()                        // _InitializeGWorlds, screens, sound, music
        resourcesLoaded = true
        UIMenuSystem.main.setNeedsRebuild()                     // MainMenu.nib (buildMenu reads the bundle)

        let shell = ShellViewController(logicalWidth: 800, logicalHeight: 600)
        shellController = shell
        rootController = shell
        let shellView = shell.shellView
        shellView.scalingPolicy = .aspectFit                    // Ben 2026-10-04 on the mini: fill the height (D7 amended)
        shellView.inputHandler = self
        let chrome = AkiChromeView(frame: shellView.bounds)
        chrome.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chrome.backgroundColor = .clear
        chrome.onLayout = { [weak self] in self?.layoutChrome() }
        shellView.addSubview(chrome)
        self.chrome = chrome
        configureGiveUp(in: chrome)
        window.rootViewController = shell

        controller.composeLaunchMap()                           // _RedrawMapScreen, _LoopMusic(1), _PlayMovie(0x80)
        window.makeKeyAndVisible()
        controller.startLaunchClocks()                          // the tick ivars, blink, preview
        let timer = ShellIdleTimer(interval: 0.05) { [weak self] in self?.idleTimerFired() }
        idleTimer = timer
        timer.start()
        perform(#selector(finishLaunch), with: nil, afterDelay: 0.5)
    }

    /// Ben's ruling: obey the silent switch and stop other audio (`.soloAmbient`), before any sound. An
    /// interruption that ends reactivates the session (no game state changes).
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.soloAmbient)
        } catch {
            Self.log.error("AVAudioSession setCategory(.soloAmbient) failed: \(error.localizedDescription, privacy: .public)")
        }
        activateAudioSession()
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterrupted(_:)),
                                               name: AVAudioSession.interruptionNotification, object: session)
    }

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Self.log.error("AVAudioSession setActive(true) failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    @objc private nonisolated func audioSessionInterrupted(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
        Task { @MainActor [weak self] in self?.activateAudioSession() }
    }

    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Aki", category: "AkiPadHost")

    /// `-[Controller finishLaunch:]` @ 0x41d4 (DC:1200): `_launched` = 1 (the window is already up — no
    /// fullscreen swap on iPad), then the first-launch "welcome" splash.
    @objc private func finishLaunch() {
        launched = true
        controller.showFirstLaunchWelcome()
    }

    /// `-[Controller idleTimerFired:]` → the shared idle entry point, wrapped to know which modals it opens.
    private func idleTimerFired() {
        let saved = inIdleContext
        inIdleContext = true
        controller.idleTick()
        inIdleContext = saved
        updateGiveUp()
    }

    @objc private func redrawWindow() {
        controller.redrawWindow()
    }

    // MARK: Focus loss (the Mac's windowDidResignMain / BecomeMain + applicationWillResignActive / DidBecomeActive)

    func sceneWillResignActive() {
        sceneActive = false
        controller.resignActiveMusic()                          // applicationWillResignActive:
        controller.focusLost()                                  // windowDidResignMain:
    }

    func sceneDidBecomeActive() {
        sceneActive = true
        perform(#selector(redrawWindow), with: nil, afterDelay: 0)   // windowDidBecomeMain:
        controller.focusRegained()
        controller.becomeActiveMusic(launched: launched)        // applicationDidBecomeActive:
    }

    // MARK: Input (ShellTouchInputHandler)

    /// `-[Controller mouseDown:]`: the point is `_GetMouseLocation`. D7 R2, iPad only: on the map, a tap on a
    /// lantern that is not the current preview only moves the pointer (the touch view already did) — the map's
    /// idle hover shows the preview and plays Preview.aiff; a tap on the previewed lantern is delivered.
    func shellTouchView(_ view: ShellTouchView, click: ShellClick) {
        guard resourcesLoaded, !isModalUp else { return }
        let point = mouseLocation()
        if controller.g.mode == .map, let lantern = AkiMap.hoverIndex(h: point.h, v: point.v),
           lantern != controller.mapScreen.lastPreview {
            return
        }
        controller.mouseDown(ShellClick(point: point, timestamp: click.timestamp, modifiers: click.modifiers))
    }

    /// `-[Controller keyDown:]`.
    func shellTouchView(_ view: ShellTouchView, key: ShellKey) {
        guard resourcesLoaded, !isModalUp else { return }
        controller.keyDown(key)
    }

    // MARK: The Give Up X (D7 R1)

    private func configureGiveUp(in chrome: AkiChromeView) {
        let symbol = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular))
        giveUpButton.setImage(symbol, for: .normal)
        giveUpButton.tintColor = UIColor(white: 0.85, alpha: 1)
        giveUpButton.backgroundColor = .clear
        giveUpButton.accessibilityLabel = controller.assets.localized("Give Up")
        giveUpButton.addTarget(self, action: #selector(giveUpTapped), for: .touchUpInside)
        giveUpButton.isHidden = true
        chrome.addSubview(giveUpButton)
    }

    /// The menu command for tag 2 (Give Up → "Are you sure…?").
    @objc private func giveUpTapped() {
        guard menuState(tag: 2).enabled, controller.g.mode == .game else { return }
        controller.handleMenuCommand(2)
    }

    private func updateGiveUp() {
        let visible = resourcesLoaded && controller.g.mode == .game && !isModalUp
        if giveUpButton.isHidden == visible { giveUpButton.isHidden = !visible }
    }

    /// The X in the black border at the top-left corner, outside the canvas, clear of the window controls
    /// (the safe area with horizontal corner adaptation). If the border cannot hold it (the non-integer
    /// fallback leaves none), it sits over the canvas's top-left corner instead.
    private func layoutChrome() {
        guard let chrome, let shellView else { return }
        let canvas = shellView.imageRectInPoints
        let scale = max(shellView.traitCollection.displayScale, 1)
        for overlay in chrome.overlays {
            overlay.place(in: chrome.bounds, canvas: canvas, logicalCanvasWidth: shellView.logicalWidth, displayScale: scale)
        }
        let insets = chrome.edgeInsets(for: .safeArea(cornerAdaptation: .horizontal))
        let side: CGFloat = 44
        var origin = CGPoint(x: insets.left + 4, y: insets.top + 4)
        let fitsLeft = origin.x + side <= canvas.minX
        let fitsAbove = origin.y + side <= canvas.minY
        if !fitsLeft && !fitsAbove {
            origin = CGPoint(x: max(canvas.minX, insets.left), y: max(canvas.minY, insets.top))
        }
        giveUpButton.frame = CGRect(origin: origin, size: CGSize(width: side, height: side))
    }

    // MARK: Modal bookkeeping

    private struct ModalToken {
        let frozen: Bool
    }

    /// A modal starts: counted; frozen (idle timer stopped) when requested from inside the idle tick.
    private func beginModal() -> ModalToken {
        let token = ModalToken(frozen: inIdleContext)
        if token.frozen {
            frozenModals += 1
            idleTimer?.invalidate()
        }
        modalDepth += 1
        updateGiveUp()
        return token
    }

    /// A modal ended: uncounted, input back to the overlay below (or the canvas), then its completion — in
    /// the idle context when it froze the idle loop — then the idle timer restarts once no frozen modal is left.
    private func endModal(_ token: ModalToken, completion: () -> Void) {
        modalDepth -= 1
        restoreFirstResponder()
        updateGiveUp()
        let saved = inIdleContext
        if token.frozen { inIdleContext = true }
        completion()
        inIdleContext = saved
        if token.frozen {
            frozenModals -= 1
            if frozenModals == 0 { idleTimer?.start() }
        }
        updateGiveUp()
    }

    /// After any overlay / alert / sheet dismissal (and a scene reconnect): on the next run-loop turn — after
    /// UIKit's own first-responder restoration — the NEW top overlay becomes first responder (its Return / Esc
    /// key commands), else the shell view. While a sheet or alert is presented it keeps first responder; its
    /// dismissal calls this again.
    private func restoreFirstResponder() {
        DispatchQueue.main.async { [weak self] in self?.focusTop() }
    }

    private func focusTop() {
        guard shellController?.presentedViewController == nil else { return }
        if let top = chrome?.overlays.last {
            top.becomeFirstResponder()
        } else {
            shellView?.becomeFirstResponder()
        }
    }

    /// Puts `overlay` on top of the stack; `completion` runs when it closes.
    private func present(_ overlay: AkiOverlay, completion: @escaping () -> Void) {
        guard let chrome, let shellView else { return completion() }
        let token = beginModal()
        overlay.prepareToShow()
        overlay.onClose = { [weak self] in
            guard let self else { return completion() }
            endModal(token, completion: completion)
        }
        chrome.addSubview(overlay)
        overlay.place(in: chrome.bounds, canvas: shellView.imageRectInPoints, logicalCanvasWidth: shellView.logicalWidth,
                      displayScale: max(shellView.traitCollection.displayScale, 1))
        // Opened under a sheet (About / Release Notes / Handbook): the sheet keeps first responder; the
        // sheet's dismissal hands it to this overlay.
        if shellController?.presentedViewController == nil {
            overlay.becomeFirstResponder()
        }
    }

    /// Presents a sheet / alert above everything; its dismissal (Done, swipe, or an alert action) returns
    /// first responder to the top overlay or the canvas.
    private func presentAbove(_ sheet: AkiPadInfo.Sheet) {
        sheet.onDismissed = { [weak self] in self?.restoreFirstResponder() }
        presenter?.present(sheet, animated: true)
    }

    /// The topmost presented view controller (sheets and alerts go above it).
    private var presenter: UIViewController? {
        var top: UIViewController? = shellController
        while let next = top?.presentedViewController { top = next }
        return top
    }

    // MARK: AkiHost

    func present(_ window: ShellBitmap) {
        shellView?.present(window)
    }

    /// `_GetMouseLocation` @ 0x46ee: (0, 0) unless the scene is active and no modal is up; else the last
    /// touch / hover point in the 800×600 canvas, truncating and unclamped.
    func mouseLocation() -> ShellPoint {
        guard sceneActive, !isModalUp, let shellView else { return .zero }
        return shellView.logicalMouseLocation()
    }

    /// `GetDblTime()`: 30 ticks (0.5 s) on iPad.
    var doubleClickTicks: Int { 30 }

    func runDialog(_ name: String, texts: [Int: String], completion: @escaping (_ command: String?) -> Void) {
        let nibWindow: CarbonNib.Window
        do {
            guard let window = try CarbonNib(data: controller.assets.lproj("Aki.nib/objects.xib")).window(named: name) else {
                fatalError("Aki: Aki.nib has no window \"\(name)\"")       // _CreateWindowFromNib ≠ 0 → _ExitToShell
            }
            nibWindow = window
        } catch {
            fatalError("Aki: cannot read Aki.nib: \(error)")
        }
        let overlay = CarbonDialogOverlay(window: nibWindow, texts: texts, controller: controller)
        present(overlay) { completion(overlay.command) }   // the cycle ends when the overlay drops `onClose`
    }

    func showSplash(named name: String, timeout: Int, completion: @escaping () -> Void) {
        guard let image = controller.assets.image(name) else { return completion() }
        present(SplashOverlay(image: image, timeout: timeout), completion: completion)
    }

    /// `_RandomProverbScreen`: `random() % 11` picks one 392×157 strip of `proverbs.png`, `fromRect:{0, k·157,
    /// 392, 157}` in NSImage (bottom-left) coordinates — top-left row (1727 − 157 − k·157) — 20 s timeout.
    func showRandomProverb(completion: @escaping () -> Void) {
        let k = Int.random(in: 0..<11)
        guard let proverbs = controller.assets.image("proverbs"), let cg = proverbs.cgImage else {
            return completion()
        }
        let s = controller.artScale                             // Remaster (D11): the 4× sheet, cropped in its pixels
        let y = cg.height - 157 * s - k * 157 * s
        guard y >= 0, let strip = cg.cropping(to: CGRect(x: 0, y: y, width: 392 * s, height: 157 * s)) else {
            return completion()
        }
        present(SplashOverlay(image: UIImage(cgImage: strip, scale: CGFloat(s), orientation: .up), timeout: 20), completion: completion)
    }

    /// `_SelectMapArea`'s "Practice Mode" alert: "Practice Level" / "Cancel"; `cancelled` = Cancel.
    func runPracticeAlert(completion: @escaping (_ cancelled: Bool) -> Void) {
        let assets = controller.assets!
        let alert = UIAlertController(title: assets.localized("Practice Mode"),
                                      message: assets.localized("You will not be able to progress to the next level when playing in practice mode."),
                                      preferredStyle: .alert)
        let token = beginModal()
        let finish: (Bool) -> Void = { [weak self] cancelled in
            guard let self else { return completion(cancelled) }
            endModal(token) { completion(cancelled) }
        }
        let practice = UIAlertAction(title: assets.localized("Practice Level"), style: .default) { _ in finish(false) }
        alert.addAction(practice)
        alert.addAction(UIAlertAction(title: assets.localized("Cancel"), style: .cancel) { _ in finish(true) })
        alert.preferredAction = practice
        guard let presenter else {
            // No view controller to present from (cannot happen once launched — the Mac's NSAlert always
            // runs): end the modal as "Practice Level" (not cancelled) so the modal count cannot stick.
            return finish(false)
        }
        presenter.present(alert, animated: true)
    }

    /// `+[LevelDescriptionWindowController runModalWithLayout:custom:]` @ 0x29d40: n = layout + 1; title
    /// `level%d_custom_title` when `custom`, else `level%d_title`; `level%d_description`; image `preview%d`.
    func runLevelDescription(layout: Int, custom: Bool, completion: @escaping () -> Void) {
        let n = layout + 1
        let assets = controller.assets!
        let overlay = levelDescription ?? LevelDescriptionOverlay(controller: controller)
        levelDescription = overlay
        overlay.setup(title: assets.localized(custom ? "level\(n)_custom_title" : "level\(n)_title"),
                      description: assets.localized("level\(n)_description"), image: assets.image("preview\(n)"))
        present(overlay, completion: completion)
    }

    /// `-[Controller showPreferences:]`, the windowed path: `pause`, the Preferences sheet, `unpause` when it
    /// ends (`preferencesSheetDidEnd:…`).
    func showPreferences() {
        guard hostCommandsEnabled else { return }
        if preferences == nil {
            do {
                preferences = try PreferencesOverlay(controller: controller)
            } catch {
                fatalError("Aki: cannot read Preferences.nib: \(error)")
            }
        }
        guard let preferences else { return }
        controller.pause()
        preferences.updateUI()
        present(preferences) { [controller] in controller.unpause() }
    }

    /// The map bar's Quit: drawn, non-functional on iPad (D7 R4).
    func quit() {}

    func showAbout() {
        guard hostCommandsEnabled else { return }
        presentAbove(AkiPadInfo.about(controller: controller))
    }

    func showReleaseNotes() {
        guard hostCommandsEnabled else { return }
        presentAbove(AkiPadInfo.releaseNotes(controller: controller))
    }

    func showHandbook() {
        guard hostCommandsEnabled, let handbook = AkiPadInfo.handbook(controller: controller) else { return }
        presentAbove(handbook)
    }
}

#if DEBUG
/// Dev-build launch check (Known delta 7): the shipped data is missing — a plain message instead of NSAlert.
@MainActor private final class MissingDataViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let label = UILabel()
        label.text = "Aki's original data files are missing from this app. Set AKI_DATA_12 (or link Resources/Aki/1.2.0.app) and rebuild."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
        ])
    }
}
#endif
