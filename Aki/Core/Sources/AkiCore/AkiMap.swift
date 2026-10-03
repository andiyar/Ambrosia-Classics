/// A QuickDraw `Rect` as the original's `SetRect(r, left, top, right, bottom)` calls give it:
/// top-left origin, right/bottom exclusive.
public struct QDRect: Equatable, Hashable, Sendable {
    public var left: Int, top: Int, right: Int, bottom: Int
    public init(left: Int, top: Int, right: Int, bottom: Int) {
        self.left = left; self.top = top; self.right = right; self.bottom = bottom
    }
}

/// The map screen: lantern hit boxes, the bottom bar, level selection rules, the lantern blink and
/// every rect the map draws with (`_MapScreen` DC:2355, `_RedrawMapScreen` DC:2606,
/// `_SelectMapArea` DC:2782, `_SelectMenuOptions` DC:2949, `-[Controller mouseDown:]` DC:1312;
/// docs/aki/levels.md §4–5). Points are `_GetMouseLocation` (h, v) in the 800×600 canvas.
public enum AkiMap {

    // MARK: - Lanterns

    /// Lantern i (level i + 1) at (left, top) — the `local_68` / `local_98` tables.
    public static let lanterns: [(left: Int, top: Int)] = [
        (713, 310), (403, 176), (231, 115), (89, 45), (12, 269), (234, 356),
        (326, 281), (355, 294), (547, 315), (434, 223), (374, 216), (405, 244),
    ]

    /// Inclusive box left+23 … left+52 × top+17 … top+54.
    public static func lanternContains(_ index: Int, h: Int, v: Int) -> Bool {
        guard lanterns.indices.contains(index) else { return false }
        let l = lanterns[index]
        return l.left + 0x17 <= h && h <= l.left + 0x34 && l.top + 0x11 <= v && v <= l.top + 0x36
    }

    /// The hovered lantern: the LAST lantern whose box contains the point (`_MapScreen`), nil for none (−9).
    public static func hoverIndex(h: Int, v: Int) -> Int? {
        lanterns.indices.last { lanternContains($0, h: h, v: v) }
    }

    // MARK: - Bottom bar

    /// `-[Controller mouseDown:]` on the map: v 559…588 goes to `_SelectMenuOptions`, else `_SelectMapArea`.
    public static func isBarClick(v: Int) -> Bool { 0x22f <= v && v < 0x22f + 0x1e }

    public enum BarAction: Equatable, Sendable { case preferences, quit, difficultyPrevious, difficultyNext }

    /// `_SelectMenuOptions`, tested in its order: h 32…189 Preferences, 598…765 Quit,
    /// 320…515 difficulty −1 (right arrow), 284…315 difficulty +1 (left arrow).
    public static func barAction(h: Int) -> BarAction? {
        if 0x20 <= h && h < 0x20 + 0x9e { return .preferences }
        if 0x256 <= h && h < 0x256 + 0xa8 { return .quit }
        if 0x140 <= h && h < 0x140 + 0xc4 { return .difficultyPrevious }
        if 0x11c <= h && h <= 0x11c + 0x1f { return .difficultyNext }
        return nil
    }

    /// The raw s16 arithmetic of `_SelectMenuOptions`: up `raw+1 < 4 ? raw+1 : 0`, down `raw−1 ≥ 0 ? raw−1 : 3`.
    public static func cycleDifficulty(_ raw: Int16, up: Bool) -> Int16 {
        if up {
            let n = raw &+ 1
            return n < 4 ? n : 0
        }
        let n = raw &- 1
        return n >= 0 ? n : 3
    }

    // MARK: - Selection

    public struct Selection: Equatable, Sendable {
        /// How many "Unavailable" dialogs (`_CreateNewDialog(0x28)`) the click opens, one per locked hit.
        public var unavailableDialogs: Int
        /// The level index to start (g+0x90), nil = none (−9).
        public var chosen: Int?
        public init(unavailableDialogs: Int, chosen: Int?) {
            self.unavailableDialogs = unavailableDialogs; self.chosen = chosen
        }
    }

    /// `_SelectMapArea`, lanterns 0…11 in order: locked (and Option up) and hit → one Unavailable
    /// dialog; unlocked (or Option down) and hit → chosen = that index (the last such wins). The
    /// unregistered gate on indices ≥ 3 is the registration layer the replica omits (always registered).
    public static func select(h: Int, v: Int, optionDown: Bool, settings: GameSettings) -> Selection {
        var selection = Selection(unavailableDialogs: 0, chosen: nil)
        for i in lanterns.indices where lanternContains(i, h: h, v: v) {
            if !optionDown && !settings.isUnlocked(i) {
                selection.unavailableDialogs += 1
            } else {
                selection.chosen = i
            }
        }
        return selection
    }

    /// The Practice alert: Practice and the next level (p+0x201 + level) still locked. For level 11
    /// that byte is p+0x20c — on i386 the difficulty's low byte (3 in Practice), so it never alerts.
    public static func needsPracticeAlert(level: Int, settings: GameSettings) -> Bool {
        guard settings.difficultyRaw == 3 else { return false }
        let next = level + 1
        if (1..<12).contains(next) { return !settings.isUnlocked(next) }
        if next == 12 { return UInt8(truncatingIfNeeded: settings.difficultyRaw) == 0 }
        return false
    }

    /// `SplashScreen("guide")` before a level: level 2 still locked and g+0x22b set.
    public static func showsGuide(settings: GameSettings, guideFlag: Bool) -> Bool {
        !settings.isUnlocked(1) && guideFlag
    }

    // MARK: - Lit and blinking lanterns

    /// `_MapScreen`: the highest unlocked of indices 1…11, else 0.
    public static func blinkingLantern(settings: GameSettings) -> Int {
        (1..<12).last { settings.isUnlocked($0) } ?? 0
    }

    /// `_RedrawMapScreen`'s loop bound: lanterns 0 ..< n that are unlocked draw lit; n = the highest
    /// unlocked of 1…11, else 0 when level 1 is unlocked, 12 when it is not.
    public static func litLanternCount(settings: GameSettings) -> Int {
        (1..<12).last { settings.isUnlocked($0) } ?? (settings.isUnlocked(0) ? 0 : 12)
    }

    /// The map loop runs only when `TickCount() > LastTimeCount + 6`.
    public static func tickDue(now: UInt32, last: UInt32) -> Bool { now > last &+ 6 }

    /// The blinking lantern's frame: `LastColor` (phase) ping-pongs 1,2,3,2,1,0,… from 0 with
    /// `ColorDown` (rising) initially set.
    public struct Blink: Equatable, Sendable {
        public var phase: Int
        public var rising: Bool
        public init() { phase = 0; rising = true }
        public mutating func step() {
            if rising {
                phase += 1
                if phase == 3 { rising = false }
            } else {
                phase -= 1
                if phase == 0 { rising = true }
            }
        }
    }

    // MARK: - Art rects (misc.png = g+0, previews.png = g+0x18, map = g+0x20, notavail.png = g+0x28, arrow.png = g+0x34)

    /// The lit lantern sprite in misc.png (75×73).
    public static let lanternSprite = QDRect(left: 0xcd, top: 0x150, right: 0x118, bottom: 0x199)
    /// The static lit lanterns' mask (`_RedrawMapScreen`).
    public static let lanternStaticMask = QDRect(left: 0x118, top: 0x150, right: 0x163, bottom: 0x199)
    /// The blink's mask per phase 0…3 (`_MapScreen`).
    public static let blinkMasks: [QDRect] = [
        QDRect(left: 0x118, top: 0x150, right: 0x163, bottom: 0x199),
        QDRect(left: 0x163, top: 0x150, right: 0x1ae, bottom: 0x199),
        QDRect(left: 0x119, top: 0x95, right: 0x164, bottom: 0xde),
        QDRect(left: 0x164, top: 0x95, right: 0x1af, bottom: 0xde),
    ]
    /// A static lit lantern: (left, top, left+74, top+72) — 1 px short of the 75×73 sprite (QuickDraw stretches).
    public static func litLanternDestination(_ i: Int) -> QDRect {
        let l = lanterns[i]
        return QDRect(left: l.left, top: l.top, right: l.left + 0x4a, bottom: l.top + 0x48)
    }
    /// The blinking lantern (and the map restore under it): (left, top, left+75, top+73).
    public static func blinkDestination(_ i: Int) -> QDRect {
        let l = lanterns[i]
        return QDRect(left: l.left, top: l.top, right: l.left + 0x4b, bottom: l.top + 0x49)
    }

    /// Difficulty word d in misc.png: (296, 241+23d, 379, 264+23d).
    public static func difficultyWord(_ d: Int) -> QDRect {
        QDRect(left: 0x128, top: d * 0x17 + 0xf1, right: 0x17b, bottom: d * 0x17 + 0x108)
    }
    /// Its mask: (379, 241+23d, 462, 264+23d).
    public static func difficultyWordMask(_ d: Int) -> QDRect {
        QDRect(left: 0x17b, top: d * 0x17 + 0xf1, right: 0x1ce, bottom: d * 0x17 + 0x108)
    }
    public static let difficultyWordDestination = QDRect(left: 0x163, top: 0x235, right: 0x1b6, bottom: 0x24c)

    /// The left arrow (difficulty +1) in arrow.png, its mask, its place on the bar and its pressed (+2,+2) place.
    public static let leftArrowSprite = QDRect(left: 0, top: 0x55, right: 0x21, bottom: 0x71)
    public static let leftArrowMask = QDRect(left: 0, top: 0x71, right: 0x21, bottom: 0x8d)
    public static let leftArrowRest = QDRect(left: 0x118, top: 0x232, right: 0x139, bottom: 0x24e)
    public static let leftArrowPressed = QDRect(left: 0x11a, top: 0x234, right: 0x13b, bottom: 0x250)
    /// The right arrow (difficulty −1).
    public static let rightArrowSprite = QDRect(left: 0x21, top: 0x55, right: 0x42, bottom: 0x71)
    public static let rightArrowMask = QDRect(left: 0x21, top: 0x71, right: 0x42, bottom: 0x8d)
    public static let rightArrowRest = QDRect(left: 0x1df, top: 0x232, right: 0x200, bottom: 0x24e)
    public static let rightArrowPressed = QDRect(left: 0x1e1, top: 0x234, right: 0x202, bottom: 0x250)

    /// Level i's 236×180 strip of previews.png: (0, 181i, 236, 181i+180).
    public static func previewStrip(_ i: Int) -> QDRect {
        QDRect(left: 0, top: i * 0xb5, right: 0xec, bottom: i * 0xb5 + 0xb4)
    }
    /// Where the hover preview goes (235×179 — QuickDraw stretches the 236×180 strip).
    public static let previewDestination = QDRect(left: 0x207, top: 0x2b, right: 0x2f2, bottom: 0xde)
    /// The map rect copied back when nothing is hovered.
    public static let previewRestore = QDRect(left: 0x207, top: 0x2b, right: 0x2f3, bottom: 0xdf)

    /// The "not available" overlay for a locked level (notavail.png rows 100–150, masked by rows 50–100).
    public static let lockedOverlay = QDRect(left: 0, top: 100, right: 0xf0, bottom: 0x96)
    public static let lockedOverlayMask = QDRect(left: 0, top: 0x32, right: 0xf0, bottom: 100)
    public static let lockedOverlayDestination = QDRect(left: 0x206, top: 0x6e, right: 0x2f6, bottom: 0xa0)
}
