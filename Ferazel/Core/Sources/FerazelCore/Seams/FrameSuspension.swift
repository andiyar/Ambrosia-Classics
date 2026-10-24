import Foundation

/// Why a `.GameLoop` iteration stopped part-way (plan S3, S1; Invariant 6, ruling 4): the original runs a modal moment
/// **inside** the frame — a save point's `.SavePointSave` and its Standard File dialog synchronously inside the special
/// collision pass (save-continue §9.2). `FerazelSession.step` returns the ops made so far with `FrameOps.suspension`
/// set; the flow runs the modal over ticks, then `FerazelSession.resume(_:)` finishes the **same** frame.
///
/// LOCKED once added (Invariant 9): cases are added, never renamed. `conversation` and `sign` (S3's list) are declared
/// now and made by C1 (also in the special pass); P1 adds `gameLoopKeys` (`.CheckGameLoopKeys`).
public enum FrameSuspension: Equatable, Sendable {
    /// The save point of placement record `record` fired (`.HitPlayerSprite`'s Box arm, type 0x429, M l. 49471–49504):
    /// the hold counter is −150, the record's p1 = facing + 1, `G+0x16` = facing, `ShowCursorSafe` made. The flow runs
    /// `.SavePointSave` (`SaveGame.swift`) and resumes with `.savePoint(saved:)`.
    case savePoint(record: Int)
    /// The NPC arm's `.Conversation(id, record, sprite)` (plan S3). // later: C1 — no arm makes it yet (unreachable).
    case conversation(id: Int16, record: Int, sprite: Int)
    /// A sign / grave text (plan S3). // later: C1 — no arm makes it yet (unreachable).
    case sign(text: [UInt8])
    /// P1: `.CheckGameLoopKeys @ 10007684` (M l. 3861–4030), called by `.GameLoop` after `.PaintFrameWrap` and before
    /// `.UpdateSprites` (M l. 5251) — a confirm, the Options dialog or `.Pause` (`GameLoopKeyEvent`, `Pause.swift`). The
    /// flow runs it and resumes with `.gameLoopKeys(_:)`; a hosted session only (`hostedByLevelRun`).
    case gameLoopKeys(GameLoopKeyEvent)

    /// What the modal answered — the value `resume(_:)` continues the frame with.
    public enum Outcome: Equatable, Sendable {
        /// `.SavePointSave`'s return (`.SaveSG`'s): true = written (the success flash), false = cancelled or failed
        /// (the record's p1 back to 0).
        case savePoint(saved: Bool)
        /// P1: the answer to a `.gameLoopKeys` suspension, with the polled input at that moment (the nested
        /// `.PaintFrameWrap` passes read the keys, the Caps Lock test reads `CapsLockDown()` live).
        case gameLoopKeys(GameLoopKeyAnswer)
    }
}
