import HectorShell

/// One of the three screens (map, game, level editor) the controller dispatches to by `AkiG.mode`.
/// Each member is that screen's branch of the corresponding `-[Controller …]` method (method-map §1).
/// Input is platform-neutral (plan C3): the host converts its events to `ShellClick` / `ShellKey`.
@MainActor protocol AkiScreen: AnyObject {
    func idle()                                                // one idleTimerFired: for this mode
    func mouseDown(at point: ShellPoint, click: ShellClick)    // the mode's branch of -[Controller mouseDown:]
    func keyDown(_ key: ShellKey)                              // the mode's branch of -[Controller keyDown:] (map: no-op)
    func redrawWindow()                                        // -[Controller _redrawWindow]
    func pause(); func unpause()                               // -[Controller pause]/unpause (map: no-ops)
    /// The applicationShouldTerminate: branch (map: true at once); completion style, as it may run a modal.
    func shouldTerminate(_ completion: @escaping (Bool) -> Void)
}
