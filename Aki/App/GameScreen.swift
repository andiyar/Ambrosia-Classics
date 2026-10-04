import AppKit
import AkiCore
import HectorShell

/// The game screen: `_CustomGameScreen` @ 0x12dbc (DC:7422) and the game branches of the controller's
/// mouse / key / redraw / pause entry points (method-map §1). P2.9 lands the stored state and the drawing
/// (`GameScreenDrawing.swift`, the QuickDraw pipeline of `_DrawGameTiles` DC:6244 … `_SelectCGButton`
/// DC:7729); the level lifecycle and the event executor are P2.10's, the input and pause P2.11's. Every rect
/// comes from `AkiGameArt`; the buffers are the original GWorlds — scratch2c the composed screen, scratch3c
/// the board buffer.
@MainActor final class GameScreen: AkiScreen {
    unowned let controller: AkiController

    /// The level being played (the board, the clock and the rule-only `_g` fields). Set by P2.10's
    /// `startLevel`; nil until then, and every drawing method returns at once while it is nil.
    private(set) var game: AkiGame?                                                       // P2.9

    init(controller: AkiController) {                                                     // P2.9
        self.controller = controller
    }

    /// The drawing routines that mutate `_g` in the original — `_CountOpenPairs` (g+0x60), the
    /// `_RedrawCustomTimeBar` step, the `_RedrawCustomGameScreen` time-bar tail (DC:6527), `_RedrawNoMorePairs`
    /// (DC:6420) — call the matching `AkiGame` mutator through here at the same point (Phase 2 ownership rule),
    /// so `game`'s setter stays private. nil (nothing run) while no level is loaded.
    /// Internal, not private: the drawing extension is a second file and P2.10's `startLevel` sets the game;
    /// S3's `private(set)` intent is "only GameScreen mutates".
    func updateGame<R>(_ body: (inout AkiGame) -> R) -> R? {
        guard game != nil else { return nil }
        return body(&game!)
    }

    /// `GameScreen.perform(_:)` executes an `AkiGame` method's events in order — the executor is P2.10's;
    /// in P2.9 it is the no-op that lets the drawing routines call it at the original's points. // P2.10
    func perform(_ events: [GameEvent]) {}

    // MARK: AkiScreen (bodies land in P2.10 / P2.11; map-safe no-ops so the target builds)

    func idle() {}
    func mouseDown(at point: ShellPoint, event: NSEvent) {}
    func keyDown(_ event: NSEvent) {}
    func redrawWindow() {}
    func pause() {}
    func unpause() {}
    func shouldTerminate() -> Bool { true }
}
