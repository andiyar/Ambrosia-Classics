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
    /// C1: `.Conversation(id, record, sprite) @ 1007a7e8` from `.HitPlayerSprite`'s Box arm — the NPC arm (types
    /// 0xb87…0xb99, M l. 49199–49210, raw `10056d14..10056d68`: `id` = the record's p1, cooldown 150) or the sign arm
    /// (2902…2909 except 2907, graves 2833…2836, p1 > 100, raw `10057124`: cooldown 90). `record` = the sprite's `+0x48`,
    /// `sprite` = its `ActiveList` id (`*PTR_DAT_100a0bec`, action 9's target). The flow runs `ConversationRun` and
    /// resumes with `.conversation`.
    case conversation(id: Int16, record: Int, sprite: Int)
    /// C1: the 2902 sign's `.SimpleConv(4020, "Wooden Sign", STR# 500[p1])` (M l. 49287–49297, raw `10057100`): the
    /// text as `GetIndString` returns it (Mac Roman bytes; empty outside the list). The flow runs `ConversationRun`
    /// and resumes with `.sign`.
    case sign(text: [UInt8])
    /// P1: `.CheckGameLoopKeys @ 10007684` (M l. 3861–4030), called by `.GameLoop` after `.PaintFrameWrap` and before
    /// `.UpdateSprites` (M l. 5251) — a confirm, the Options dialog or `.Pause` (`GameLoopKeyEvent`, `Pause.swift`). The
    /// flow runs it and resumes with `.gameLoopKeys(_:)`; a hosted session only (`hostedByLevelRun`).
    case gameLoopKeys(GameLoopKeyEvent)
    /// PK: the upgrade arm (1340 / 1341, `.HitPlayerSprite` M l. 48810–48916) has played snd 451, added 2000 to the
    /// score, set `+0xe9` and started `GammaFadeOutAsync(2, colour, 0xc, 0x10)`; its six blocking tick loops (120 ticks,
    /// BC35) run in the flow (`UpgradeAnimation`, `LevelRun`), which resumes with `.upgrade` — the arm returns after
    /// them.
    case upgrade(type: Int16)
    /// IU: a USE hint — `.HandleKeys`' item switch with a key (1–3), a shield (0xe, 0xf) or the Red Xichrons (0x16)
    /// selected calls `.SimpleConv(4001, "Ferazel", text)` (M l. 47563–47566, 47587–47589, 47605–47606) **inside the
    /// player's Handle** (Invariant 5): the frame stops at the switch (also inside a nested `.PaintFrameWrap` — the
    /// pause's or `.CheckGameLoopKeys`' redraw, `FerazelSession.suspendedInNestedPass`); the flow runs `ConversationRun`
    /// and resumes with `.hint` — the rest of `.HandleKeys`, the player's rows, the handle pass from the player's saved
    /// `next`, then the frame.
    case hint(text: [UInt8])
    /// TP: a teleporter fired (`.HitPlayerSprite`'s Box arm, 0x424…0x426, M l. 49407–49470; pickups-boxes §2.4.7,
    /// BC40, BC50) — a landing with the fire pulse `PTR_DAT_100a0708` set; `record` is the teleporter's placement
    /// record (`+0x48`, whose p1 names the partner). **Stage 1**: snd 421 made, the frame stops at
    /// `.MosaicTransition(1, 3, 0x14)` (the out-mosaic, cells 1…20, `MosaicTransition` in `LevelRun`); its resume moves
    /// the player (every in-use idle entry whose record index is p1), re-seats the camera, `.HandleIdleSprites`,
    /// `.WrapDrawSprites`, snd 420 and stops again — **stage 2**: `.MosaicTransition(0, 3, 0x14)` (the in-mosaic,
    /// cells 20…1), whose resume is `.RedrawEntireScrollGrid`, `0708 = 0`, the charge −59 and the rest of the frame.
    case teleport(record: Int, stage: Int)

    /// What the modal answered — the value `resume(_:)` continues the frame with.
    public enum Outcome: Equatable, Sendable {
        /// `.SavePointSave`'s return (`.SaveSG`'s): true = written (the success flash), false = cancelled or failed
        /// (the record's p1 back to 0).
        case savePoint(saved: Bool)
        /// P1: the answer to a `.gameLoopKeys` suspension, with the polled input at that moment (the nested
        /// `.PaintFrameWrap` passes read the keys, the Caps Lock test reads `CapsLockDown()` live).
        case gameLoopKeys(GameLoopKeyAnswer)
        /// C1: `.Conversation` returned (ended, aborted by Escape, or its `Mcnv` failed to load and the error was
        /// reported) — the arm goes on after the call, with the polled input at that moment: the rest of the frame
        /// reads it live (`.IsInputKeyPressed` → `_IsPressed` → `GetKeys`, M l. 42336ff / 32391ff; the later contacts'
        /// UP test l. 49281, `.CheckGameLoopKeys`' keys and `CapsLockDown()`), and the conversation ended waiting for
        /// all keys up.
        case conversation(keys: KeyState, capsLock: Bool)
        /// C1: `.SimpleConv` returned, with the polled input at that moment (as `.conversation`).
        case sign(keys: KeyState, capsLock: Bool)
        /// PK: the upgrade animation's loops ran out (`UpgradeAnimation.isDone`), with the polled input at that moment
        /// (as `.conversation`: the rest of the frame reads it — live in the original).
        case upgrade(keys: KeyState, capsLock: Bool)
        /// IU: the hint's `.SimpleConv` returned, with the polled input at that moment — the rest of `.HandleKeys`
        /// (the DOWN / climb blocks, the JUMP arm), the player's rows, the later Handles and the frame read it (live in
        /// the original, as after a conversation).
        case hint(keys: KeyState, capsLock: Bool)
        /// TP: a `.MosaicTransition` returned, with the polled input at that moment (as `.upgrade`: after stage 2 the
        /// later contacts and `.CheckGameLoopKeys` read it — live in the original).
        case teleport(keys: KeyState, capsLock: Bool)
    }
}
