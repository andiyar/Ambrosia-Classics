import Foundation

/// The main menu's data (`.MainMenu @ 1000e618`, M l. 7303–7445; `.DrawMainMenu @ 10002f24`, M l. 1497–1527;
/// `.TrackClickOnCommandButton @ 10002c5c`, M l. 1407–1494; rendering-omnipx-titles §4.1). Buttons 1 New Game,
/// 2 Continue, 3 Options, 4 Credits, 5 Quit.
public enum MainMenu {
    /// clut 130 'main menu clut' (`_DAT_100a79b0`) and PICT 130, the 640×480 menu (PICT 134 is the other-size menu —
    /// never in the replica; `*PTR_DAT_1009ff5c` stays 0, so button 5 never switches to PICT 4925/4935).
    public static let clut: Int16 = 130
    public static let picture: Int16 = 130

    /// The hot rects as `PointInRect(pt, l, t, r, b)` / `SetRect(l, t, r, b)` pass them (M l. 7334–7342, 1430–1449),
    /// in the order the loop tests them.
    public static let rects: [Rect16] = [
        Rect16(top: 0x107, left: 0x1ab, bottom: 0x131, right: 0x245),   // 1 New Game   (427, 263, 581, 305)
        Rect16(top: 0x131, left: 0x1b2, bottom: 0x159, right: 0x272),   // 2 Continue   (434, 305, 626, 345)
        Rect16(top: 0x15a, left: 0x1b9, bottom: 0x184, right: 0x264),   // 3 Options    (441, 346, 612, 388)
        Rect16(top: 0x183, left: 0x1c0, bottom: 0x1ab, right: 0x232),   // 4 Credits    (448, 387, 562, 427)
        Rect16(top: 0x1ad, left: 0x1c8, bottom: 0x1d7, right: 0x21b),   // 5 Quit       (456, 429, 539, 471)
    ]

    /// `PtInRect`: left/top inside, right/bottom outside.
    static func contains(_ r: Rect16, h: Int, v: Int) -> Bool {
        h >= Int(r.left) && h < Int(r.right) && v >= Int(r.top) && v < Int(r.bottom)
    }

    /// The first button (1…5) whose rect holds (h, v) in the loop's order — rects 3 and 4 share row 387, Options wins.
    public static func button(h: Int, v: Int) -> Int? {
        rects.firstIndex { contains($0, h: h, v: v) }.map { $0 + 1 }
    }

    /// `0x1324 + n` highlighted, `+ 10` normal (M l. 1454–1457).
    public static func highlightPicture(_ n: Int) -> Int16 { Int16(0x1324 + n) }
    public static func normalPicture(_ n: Int) -> Int16 { Int16(0x1324 + n + 10) }

    /// snd 4803 (`*_DAT_100a0040`, `FUN_10091748(0x12c3)`, M l. 354) entering a button; snd 4804 (`*_DAT_100a003c`,
    /// 0x12c4) leaving it or releasing — both `STPlayRegSound(…, 10, 0x55)`.
    public static let enterSound: Int16 = 0x12c3
    public static let exitSound: Int16 = 0x12c4
    public static let soundPriority = 10
    public static let soundVolume: Int16 = 0x55
    /// The keyboard track's `Delay(10)` (M l. 1463).
    public static let keyboardTrackTicks = 10
    /// Global v below 0x15 with the pointer over no button shows the menu bar, else it is hidden (M l. 7344–7350).
    public static let menuBarRevealV = 0x15

    /// The polled keys, in the loop's order (M l. 7388–7431): N; O, R; I, P; C; Q; X.
    public static let newGameKey = 0x2d
    public static let continueKeys = [0x1f, 0x0f]
    public static let optionsKeys = [0x22, 0x23]
    public static let creditsKey = 0x08
    public static let quitKey = 0x0c
    public static let jokeKey = 0x07
    /// The X joke's cooldown in loop passes (`sVar5 = 0x1e`, M l. 7404).
    public static let jokeCooldown = 0x1e
    /// pstr `0x100a3023` (149 bytes, Mac Roman), `ReportDialog`'d by X.
    public static let comingSoon = "Coming soon: Ferazel's Destiny; Ferazel's Quest; Ferazel Fighter; Ferazel All-Stars; "
        + "Go-Kart Ferazel; Ferazel Soccer 2000; Summer Olympics Ferazel..."
}

/// `.TrackClickOnCommandButton(n, 1)`'s mouse loop (`while (Button()) { … }`, M l. 1466–1488) one tick at a time:
/// entering the rect highlights it and plays 4803 (and counts the entry), leaving it draws it normal and plays 4804;
/// after more than 9 entries a leave also plays snd 199 through `SndPlay` and restarts the count — no fork holds a
/// snd 199 (BC19), so `GetResource` gives nil and nothing sounds. On release: inside → normal + 4804 and true.
struct ButtonTrack: Equatable, Sendable {
    enum Event: Equatable, Sendable { case highlight, normal }

    let button: Int
    /// `sVar6`: the button is drawn highlighted.
    private(set) var inside = false
    /// `sVar5`: entries since the last snd 199.
    private(set) var entries = 0

    init(button: Int) { self.button = button }

    /// One poll of `Button()` / `GetMouse`: the draws it made, and the result when the button is up (the loop ended).
    mutating func step(button down: Bool, mouse: (h: Int, v: Int)?) -> (events: [Event], result: Bool?) {
        guard down else { return (inside ? [.normal] : [], inside) }
        let rect = MainMenu.rects[button - 1]
        let isIn = mouse.map { MainMenu.contains(rect, h: $0.h, v: $0.v) } ?? false
        if !isIn {
            guard inside else { return ([], nil) }
            inside = false
            if entries > 9 { entries = 0 }    // `SndPlay(GetResource('snd ', 199))`: absent from every fork — silent
            return ([.normal], nil)
        }
        guard !inside else { return ([], nil) }
        inside = true
        entries += 1
        return ([.highlight], nil)
    }
}
