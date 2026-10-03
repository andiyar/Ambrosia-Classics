import AppKit
import HectorShell

/// One of the three screens (map, game, level editor) the controller dispatches to by `AkiG.mode`.
/// Each member is that screen's branch of the corresponding `-[Controller …]` method (method-map §1).
@MainActor protocol AkiScreen: AnyObject {
    func idle()                                                // one idleTimerFired: for this mode
    func mouseDown(at point: ShellPoint, event: NSEvent)       // the mode's branch of -[Controller mouseDown:]
    func keyDown(_ event: NSEvent)                             // the mode's branch of -[Controller keyDown:] (map: no-op)
    func redrawWindow()                                        // -[Controller _redrawWindow]
    func pause(); func unpause()                               // -[Controller pause]/unpause (map: no-ops)
    func shouldTerminate() -> Bool                             // applicationShouldTerminate: branch (map: true)
}
