import UIKit

/// The iPad entry point (plan C1): the app delegate owns the one `AkiPadHost` for the app's lifetime (the
/// host owns the shared `AkiController`, whose `host` is weak — AkiHost ownership rule). It is also the
/// menu bar's builder, the target of every menu command (it ends the responder chain) and their validator.
@main @MainActor final class AkiPadAppDelegate: UIResponder, UIApplicationDelegate {
    let host = AkiPadHost()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = AkiSceneDelegate.self
        return configuration
    }

    // MARK: Menus (MainMenu.nib, plan C5)

    override func buildMenu(with builder: any UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard builder.system == .main else { return }
        AkiPadMenus.build(builder, assets: AkiAssets())
    }

    /// `-[Controller gameMenuAction:]`: every tagged item → `_HandleMenuCommand(tag)` (when enabled).
    @objc func akiMenuCommand(_ sender: UICommand) {
        guard let tag = Self.tag(sender), host.menuState(tag: tag).enabled else { return }
        host.controller.handleMenuCommand(tag)
    }

    @objc func akiShowAbout(_ sender: Any?) { host.showAbout() }
    @objc func akiShowPreferences(_ sender: Any?) { host.showPreferences() }
    @objc func akiShowHelp(_ sender: Any?) { host.showSplash(named: "guide", timeout: 0) {} }   // showHelp:
    @objc func akiShowHandbook(_ sender: Any?) { host.showHandbook() }
    @objc func akiShowReleaseNotes(_ sender: Any?) { host.showReleaseNotes() }
    /// "Remastered Art" (D11, not in the nib): flips the Remaster art live, when enabled.
    @objc func akiToggleRemasteredArt(_ sender: Any?) {
        guard host.remasterCommandEnabled else { return }
        host.controller.setRemastered(!host.controller.remasterActive)
    }
    /// Quit Aki (⌘Q): drawn, does nothing (D7 R4).
    @objc func akiQuit(_ sender: Any?) {}
    /// A nib item wired to no action (the Japanese "Undo Last Move"): never enabled.
    @objc func akiNoAction(_ sender: Any?) {}

    private static func tag(_ command: UICommand) -> Int? {
        (command.propertyList as? [String: Int])?["tag"]
    }

    private static let hostActions: Set<Selector> = [
        #selector(akiShowAbout(_:)), #selector(akiShowPreferences(_:)), #selector(akiShowHelp(_:)),
        #selector(akiShowHandbook(_:)), #selector(akiShowReleaseNotes(_:)),
    ]

    /// Tagged commands stay performable so `validate` can retitle them; the host's untagged commands are off
    /// while a modal is up (and before launch); Quit is always on (and does nothing).
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(akiMenuCommand(_:)) { return true }
        if action == #selector(akiToggleRemasteredArt(_:)) { return true }   // `validate` sets its check and enabling
        if action == #selector(akiQuit(_:)) { return true }
        if action == #selector(akiNoAction(_:)) { return false }
        if Self.hostActions.contains(action) { return host.hostCommandsEnabled }
        return super.canPerformAction(action, withSender: sender)
    }

    /// The tagged half of `-[Controller validateMenuItem:]` (shared `menuState`): the retitle, then enabled
    /// unless a later phase's tag or a modal is up.
    override func validate(_ command: UICommand) {
        super.validate(command)
        if command.action == #selector(akiToggleRemasteredArt(_:)) {
            command.state = host.controller.remasterActive ? .on : .off
            if host.remasterCommandEnabled {
                command.attributes.remove(.disabled)
            } else {
                command.attributes.insert(.disabled)
            }
            return
        }
        guard command.action == #selector(akiMenuCommand(_:)), let tag = Self.tag(command) else { return }
        let state = host.menuState(tag: tag)
        if let title = state.title {
            command.title = title
        }
        if state.enabled {
            command.attributes.remove(.disabled)
        } else {
            command.attributes.insert(.disabled)
        }
    }
}

/// The one window scene: the host builds the window and launches the game in it; the scene's activity is
/// the Mac's main-window / app activity (plan C1, C2 focus loss).
@MainActor final class AkiSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var host: AkiPadHost? {
        (UIApplication.shared.delegate as? AkiPadAppDelegate)?.host
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene, let host else { return }
        window = host.attach(to: windowScene)
    }

    /// The scene is released: only its window goes (the game was launched once and keeps running).
    func sceneDidDisconnect(_ scene: UIScene) {
        host?.sceneDidDisconnect()
        window = nil
    }

    func sceneWillResignActive(_ scene: UIScene) {
        host?.sceneWillResignActive()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        host?.sceneDidBecomeActive()
    }
}
