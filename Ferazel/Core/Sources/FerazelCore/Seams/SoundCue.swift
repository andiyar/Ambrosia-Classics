import Foundation

/// One sound the original started this iteration (`STPlay*`; sprites-backgrounds §6.2–§6.3) — plan S3, LOCKED.
public struct SoundCue: Equatable, Sendable {
    public var snd: Int16
    public var priority: Int
    public var left: Int
    public var right: Int
    public var rate: UInt32
    /// S1: `if (!FUN_100916dc(snd)) play(…)` — the call is made only while no voice plays `snd` (`FUN_100916dc` =
    /// the number of voices playing it); the shell asks its mixer at the cue's place in `sounds`.
    public var onlyIfIdle: Bool
    /// 6A-RN: `.STPlayLoopedSound @ 10047e34` (M l. 40978ff) — the play-list request carries the completion proc
    /// `.STLoopCallBack` (`PTR_PTR_100a111c` at request +0x0c), which re-plays the same request each time the entry runs
    /// out (`FUN_10091c94` calls it with reason 1, M l. 78640–78644; a stop's reason 2 is ignored, M l. 78364–78366), so
    /// the sound plays until a stop (`FUN_10091504(snd)`) ends it. Default off: every other cue plays once (Invariant 9).
    /// The voice stays findable by `snd` (the entry's sound), so a later cue that sets the volume of the voice playing
    /// `snd` (6B-AS's ambience, `FUN_10091a60` / `FUN_10091890`) can be added beside this one as its own field.
    public var loops: Bool

    public init(snd: Int16, priority: Int, left: Int, right: Int, rate: UInt32, onlyIfIdle: Bool = false,
                loops: Bool = false) {
        self.snd = snd
        self.priority = priority
        self.left = left
        self.right = right
        self.rate = rate
        self.onlyIfIdle = onlyIfIdle
        self.loops = loops
    }
}
