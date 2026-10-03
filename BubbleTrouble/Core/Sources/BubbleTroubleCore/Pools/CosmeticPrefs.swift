/// The two cosmetic preferences that gate RNG-consuming pools (Invariant 11). Both default ON — the shipped
/// default (`_DoFXSuitabilityCheck @ 0000f760`: `SetBooleanPref(0x35, 1); SetBooleanPref(0x36, 1)`); whether the
/// prefs are exposed is Ben's call.
public struct CosmeticPrefs: Equatable, Sendable {
    /// Bool pref 0x35 — gates every `_NewStarGroup` group except the blast groups 0xf / 0x10.
    public var stars = true
    /// Bool pref 0x36 — gates `_Bubbles` and `_Bubbles_NewGroup`.
    public var airBubbles = true

    public init(stars: Bool = true, airBubbles: Bool = true) {
        self.stars = stars
        self.airBubbles = airBubbles
    }
}

/// What the cosmetic pools read from the hero record: `_NewStarGroup` groups 6–9 read the hero rect
/// (`hero+0x14` top, `+0x16` left); `_Bubbles` reads state, aligned, facing, rect and `+0x0c` (last
/// hero-bubble launch frame, which it also writes).
public struct HeroAnchor: Sendable {
    public var state: Int16
    public var aligned: Bool
    public var facing: Direction
    public var rect: QDRect
    public var lastBubbleFrame: UInt16

    public init(state: Int16, aligned: Bool, facing: Direction, rect: QDRect, lastBubbleFrame: UInt16) {
        self.state = state
        self.aligned = aligned
        self.facing = facing
        self.rect = rect
        self.lastBubbleFrame = lastBubbleFrame
    }
}
