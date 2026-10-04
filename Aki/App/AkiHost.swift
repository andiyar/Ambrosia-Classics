import HectorShell

/// The platform shell under the shared game code (plan C2): everything the shared screens and the controller
/// need from AppKit (Mac, `Aki/App/Mac/`) or UIKit (iPad, `Aki/App/iOS/`, T4) goes through here, so no shared
/// file imports either.
///
/// **The modal contract.** Every modal is completion style. A host MAY run the modal asynchronously and call
/// the completion on dismissal (iPad: an overlay). The **Mac** host runs it as it always did — `NSApp.runModal`
/// (or `NSAlert.runModal`) — and calls the completion **before the method returns**, exactly once. Every shared
/// call site puts the code that follows the modal (in its function and up its callers' chain) inside the
/// completion, so on the Mac the order of every write and draw is today's, by construction; where a site leaves
/// code after the call instead, it says why that code is independent of the modal and unobservable in between.
///
/// **What an asynchronous host (T4) must also do — the Mac gets these from AppKit for free:**
/// - Modal from the idle tick: on the Mac the 0.05 s `Timer` cannot re-fire while its own callout is inside a
///   nested `runModal`, so a modal opened from `AkiController.idleTick()` (the proverb, via `leaveLevel`) freezes
///   the idle loop until it closes, while one opened from a menu or a click does not (the timer runs in the modal
///   mode). Wrap `idleTick()` to know which case a modal request is in, and hold the idle loop for the former.
/// - `mouseLocation()` returns (0, 0) while any modal is up (the Mac tests `NSApp.modalWindow`).
/// - Menu commands are disabled while a modal is up (AND it with `AkiController.menuState(tag:)`).
/// - Input to the screens (`AkiController.mouseDown` / `keyDown`) is not delivered while a modal is up.
/// - Modals STACK. On the Mac the idle timer keeps firing under a click- or key-opened modal (the LoadLevel
///   "Are you sure", Stacked) and the game is not paused, so a time-out can leave the level and open the
///   proverb ON TOP; the outer dialog's completion runs only after the proverb closes. A new modal goes above
///   the current one, dismissal returns to the one below, completions run in LIFO order, and the idle freeze
///   applies per idle-originated modal.
/// - Ownership: `AkiController.host` is weak — the host must own the controller (or be owned by something
///   that outlives it) and never deallocate first.
/// - Every completion runs on the main actor, exactly once.
@MainActor protocol AkiHost: AnyObject {
    /// `_DrawToWindow`'s flush: put the window port on screen.
    func present(_ window: ShellBitmap)
    /// `_GetMouseLocation` @ 0x46ee (DC:1413): (0, 0) unless the app is active, no modal is up, and the game
    /// window is the key one; else the pointer in the 800×600 canvas, truncating and unclamped.
    func mouseLocation() -> ShellPoint
    /// `GetDblTime()` in ticks (Q29).
    var doubleClickTicks: Int { get }

    /// `_CreateNewDialog`: the Carbon dialog `name` of `Aki.nib`. `texts` fills static texts by control ID — the
    /// FIRST control per ID in nib order; only static texts take text (so ID 2, the OK button, keeps its title).
    /// The runner sets `g.dialogOK` from the closing button; `completion` gets its HICommand.
    func runDialog(_ name: String, texts: [Int: String], completion: @escaping (_ command: String?) -> Void)
    /// `_SplashScreen(name, timeout)` (0 = no timeout); nothing is shown when the image is absent.
    func showSplash(named name: String, timeout: Int, completion: @escaping () -> Void)
    /// `_RandomProverbScreen`: one random proverb strip, 20 s timeout.
    func showRandomProverb(completion: @escaping () -> Void)
    /// `_SelectMapArea`'s "Practice Mode" alert; `cancelled` = the alternate (Cancel) button.
    func runPracticeAlert(completion: @escaping (_ cancelled: Bool) -> Void)
    /// `+[LevelDescriptionWindowController runModalWithLayout:custom:]`: Cancel sets `g.cancelStart`, Continue
    /// writes `p.showDescription` — both before `completion`.
    func runLevelDescription(layout: Int, custom: Bool, completion: @escaping () -> Void)

    /// `-[Controller showPreferences:]`. Not completion style: no call site has code after it.
    func showPreferences()
    /// The map bar's Quit (`[NSApp terminate:]`).
    func quit()
    /// `showAboutBox:`, `showReleaseNotes:`, `showHandbook:` (non-modal windows / another app).
    func showAbout()
    func showReleaseNotes()
    func showHandbook()
}
