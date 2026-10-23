import Foundation

/// The constants of `.main @ 1000ffc0` (M l. 8136–8358; engine §2, rendering-omnipx-titles §4.1/§4.2) that `GameFlow`
/// runs as its boot: the logo, the loading screen, the boot keys and their reports.
public enum BootSequence {
    /// PICT 131 'Publisher Logo' (`DrawPICTToBackScreen(0x83, &DAT_100a266c)`, M l. 8278), drawn under the CLUT current
    /// at boot — `.main` sets none before it (the App's surface starts on clut 128 [MED]).
    public static let logoPicture: Int16 = 131
    /// clut 128 'splash screen clut' (`_DAT_100a79ac`, M l. 8328) and PICT 136, the 640×480 loading screen (M l. 8331;
    /// PICT 128 is the other-size screen — never in the replica, whose screen is always 640×480).
    public static let loadingClut: Int16 = 128
    public static let loadingPicture: Int16 = 136
    /// `SetAIFFMusic(0x18)` (M l. 8307).
    public static let bootTrack = 24
    /// `IsPressed(0x2d)` ∧ `IsPressed(3)` (N + F, M l. 8311–8315): fading disabled (`DAT_100a53c2 = 0`) and this report
    /// (pstr `0x100a36d0`).
    public static let fadingDisabledKeys = (0x2d, 0x03)
    public static let fadingDisabledReport = "Fading disabled."
    /// `IsPressed(0x7a)` (F1, M l. 8316–8320): this report (pstr `0x100a36e1`), then `DAT_100a5105 = 0` — `.InitSounds`
    /// loads no effects (M l. 39746).
    public static let soundLoadingKey = 0x7a
    public static let soundLoadingReport = "Sound loading turned off."
    /// `.Init3DProgBar(0x24, 0x1b8, 0xbe)` (M l. 8340): the bar's left, top and width.
    public static let barH = 0x24, barV = 0x1b8, barWidth = 0xbe
    /// `.WaitNextEvent(0xffff, …, 0x3c)` at `.MainMenu`'s top (M l. 7323): the idle before the menu fades in.
    public static let menuIdleTicks = 0x3c
}

/// `.Init3DProgBar @ 10035c18` / `.Update3DProgBar @ 10035d40` (M l. 32050–32190): the boot's 3-D progress bar.
/// Progress is 16.16 (`*_DAT_100a018c`, stored on every call), +0x48 per face the `Load*FaceFromPICT` /
/// `Load*FaceSetFromPICT` loaders load (M l. 27811ff), 0x10000 at the end (M l. 8344). The filled width
/// w = width · p >> 16 is redrawn only when it differs from the stored width `sRam100a53c0` **and** |Δw| + 5 ≥ 8 or
/// p ≥ 58000; a skipped call leaves the stored width alone.
public struct ProgressBar3D: Equatable, Sendable {
    public let h: Int
    public let v: Int
    public let width: Int
    /// `*_DAT_100a018c` (bss, 0 [MED]).
    public private(set) var progress: Int32 = 0
    /// `sRam100a53c0`, the width last drawn (bss, 0 [MED]).
    public private(set) var drawnWidth: Int16 = 0

    /// Per face (`Update3DProgBar(*018c + 0x48)`).
    public static let perFace: Int32 = 0x48

    public init(h: Int = BootSequence.barH, v: Int = BootSequence.barV, width: Int = BootSequence.barWidth) {
        self.h = h
        self.v = v
        self.width = width
    }

    /// `.SetColorPerc(c, r, g, b)` (M l. 32010ff): each percent → p · 0xffff / 100 (+ p / 0x8001, 0 here).
    static func percent(_ r: Int, _ g: Int, _ b: Int) -> RGB16 {
        func c(_ p: Int) -> UInt16 { UInt16(truncatingIfNeeded: p * 0xffff / 100 + p / 0x8001) }
        return RGB16(c(r), c(g), c(b))
    }

    /// The ramp `PTR_DAT_100a023c` [0…6] and the three singles `_DAT_100a0238`, `0234`, `0230` (`.Init3DProgBar`).
    static let ramp: [RGB16] = [percent(0, 0, 0), percent(0, 0, 0x37), percent(0x13, 0x13, 0x3d),
                                percent(0x27, 0x27, 0x51), percent(0x3d, 0x3d, 100), percent(0x51, 0x51, 100),
                                percent(100, 100, 100)]
    static let shadowNear = percent(0x20, 0x20, 0x20)      // 0238
    static let shadowFar = percent(0x37, 0x37, 0x37)       // 0234
    static let narrowFill = percent(0x28, 0x28, 0x50)      // 0230

    /// `.Update3DProgBar(p)`: the screen draws (QuickDraw lines are inclusive of both ends, pen 1×1;
    /// `PlotColoredPoint` = a zero-length line; `PlotColoredHLine(c, x, y, n)` = `MoveTo(x, y)`, `LineTo(x + n, y)`).
    public mutating func update(_ p: Int32) -> [DrawOp] {
        let p = min(p, 0x10000)
        progress = p
        let w = Int((Int32(width) &* p) >> 16)
        guard w != Int(drawnWidth) else { return [] }
        if abs(w - Int(drawnWidth)) + 5 < 8 && p < 58000 { return [] }
        drawnWidth = Int16(truncatingIfNeeded: Int(UInt32(bitPattern: Int32(width) &* p) >> 16))
        var ops: [DrawOp] = []
        func line(_ c: RGB16, _ x1: Int, _ y1: Int, _ x2: Int, _ y2: Int) {
            ops.append(.drawLine(h1: x1, v1: y1, h2: x2, v2: y2, rgb: c))
        }
        func point(_ c: RGB16, _ x: Int, _ y: Int) { line(c, x, y, x, y) }
        let c = Self.ramp, x = h, y = v
        if w < 9 {
            ops.append(.fillRect(left: x, top: y, right: x + w + 1, bottom: y + 9, rgb: Self.narrowFill))
        } else {
            line(c[3], x, y, x, y + 9)
            for (k, i) in [4, 5, 6, 6, 6, 5, 4, 3, 2].enumerated() { point(c[i], x + 1, y + k) }
            for (k, i) in [3, 4, 5, 6, 5, 4, 3, 2, 1].enumerated() { line(c[i], x + 2, y + k, x + 2 + (w - 4), y + k) }
            point(c[3], x + w - 2, y)
            line(c[2], x + w - 2, y + 1, x + w - 2, y + 7)
            point(c[1], x + w - 2, y + 8)
            line(c[1], x + w - 1, y, x + w - 1, y + 8)
        }
        line(c[0], x + w, y, x + w, y + 8)
        if width - w > 2 { line(Self.shadowNear, x + w + 1, y, x + w + 1, y + 8) }
        if width - w > 3 { line(Self.shadowFar, x + w + 2, y, x + w + 2, y + 8) }
        return ops
    }
}
