import Foundation

/// Which screen the idle loop, mouse and keys go to: `_g`+0x66 == 0 → map; `_g`+0x80 → level editor;
/// otherwise the game (method-map §5).
enum AkiMode { case map, game, editor }

/// The `_g` fields (method-map §6) the replica needs — one body, one instance owned by the controller.
/// Offsets in the comments are into `_g` @ 0x34780.
@MainActor final class AkiG {
    var mode: AkiMode = .map                                   // 0x66/0x80
    var paused = false                                         // 0x67
    var endLevel = false                                       // 0x68
    var cancelStart = false                                    // 0x7c
    var lost = false                                           // 0x7d
    var pausedBeforeExternal = false                           // 0x7f
    var dialogOK = false                                       // 0x81
    var noPairsFlash = false                                   // 0x85
    var levelIndex: Int? = nil                                 // 0x90 (nil = −9)
    var musicTrack = 0                                         // 0x5c
    var lastGameTrack = 1                                      // 0x5e
    var customLost = false                                     // 0x229
    var tryAgainOK = false                                     // 0x22a
    var guideFlag = true                                       // 0x22b
    var quitRequested = false                                  // g+100
    var pauseFlash = false                                     // 0x86  — P2.9
    var flashFalling = false                                   // 0x87  — P2.9
    var flashPhase = 2                                         // 0x88  — P2.9
    var background = 1                                         // 0x8e  — P2.9: background/decoration number (1…12 built-in, 13…17 custom)
}
