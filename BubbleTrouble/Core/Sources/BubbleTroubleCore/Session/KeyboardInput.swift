// Live keyboard input for play (plan 2026-10-04 btx-playable C4 item 1; FI §4), transcribed from the play-mode branch
// of `_CheckHeroMovement @ 00021f49`: `_UpKey` / `_DownKey` / `_LeftKey` / `_RightKey` / `_PushKey`, each
// `_GameKeyDown(code)` (`GetKeys` + `BitTst` — the key's level right now, no repeat) with the codes `_InitControls`
// loaded from the current key set (prefs short 0x38; default set 1 ← → ↑ ↓ Space).

/// `InputSource` over the held keys. The session sets `keys` before each frame; `_CheckHeroMovement` samples them only
/// when it runs (Invariant 5). Play mode never touches `gRecordingCounter`, so `samplesConsumed` stays 0.
public struct KeyboardInput: InputSource, Sendable {
    public var keySet: KeySet
    public var keys: HeldKeys
    /// `local_ea`: the app was deactivated during play (the session sets it; it pauses like the key).
    public var appDeactivated = false

    public init(keySet: KeySet, keys: HeldKeys = HeldKeys()) {
        self.keySet = keySet
        self.keys = keys
    }

    /// The five flags as `_CheckHeroMovement` reads them now.
    public var sample: FilmSample {
        FilmSample(up: keys.codes.contains(keySet.up), down: keys.codes.contains(keySet.down),
                   left: keys.codes.contains(keySet.left), right: keys.codes.contains(keySet.right),
                   push: keys.codes.contains(keySet.push))
    }

    public mutating func readSample() -> FilmSample { sample }

    public var samplesConsumed: Int { 0 }

    public var isExhausted: Bool { false }

    /// `_PauseKey()` (Caps Lock state, `GameKeyDown(0x39)`) `|| local_ea`.
    public var pauseRequested: Bool { keys.capsLock || appDeactivated }
}
