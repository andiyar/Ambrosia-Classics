/// The sound-effect ids `_InitializeSound` @ 0x27cea registers (docs/aki/method-map-1.2.md §2,
/// assets-census §2) — the ONE id table; the app keys its sound bank by `rawValue`.
/// `tick.aiff` ships in the bundle but has no id (never registered).
public enum GameSound: Int, Sendable {
    case tilehit = 10, reshuffle = 0x14, levelComplete = 0x1e, gameOver = 0x28, levelStart = 0x32,
         preview = 0x3c, tileMatch = 0x46, chime = 0x4b, cancel = 0x50, unclick = 0x5a, tick = 100
}
