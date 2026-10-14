import Foundation

/// The sounds the stage screens play and wait on (plan L2): `.STPlayRegSound` as `SoundCues.regSound`, and how long each
/// voice plays — the original polls `FUN_100916dc(voice)` until the voice ends. Core holds no PCM: the App injects each
/// loaded snd's play length in ticks at rate 0x10000 (`ticks(sampleCount:sampleRate:)` over `SoundBank`).
public struct StageSounds: Equatable, Sendable {
    /// prefs+0x0b. Off → `.STPlayRegSound` returns −1 at once (M l. 40620): nothing plays and no voice is ever found
    /// playing, so every wait on a sound is 0 ticks.
    public var soundOn: Bool
    /// `iRam100a510c` (prefs+0x0e · 28).
    public var global: Int32
    /// snd id → play length in ticks; an absent id is a nil snd handle (plays nothing, waits 0).
    public var lengths: [Int16: Int]

    public init(prefs: FerazelPrefs, lengths: [Int16: Int]) {
        soundOn = prefs.soundOn != 0
        global = SoundCues.globalVolume(prefs)
        self.lengths = lengths
    }

    /// `ceil(sampleCount · 60 / sampleRate)` — the ticks until a poll finds the voice ended [MED: the poll's tick
    /// quantisation; 2304 samples at 22,050 Hz → 7].
    public static func ticks(sampleCount: Int, sampleRate: Double) -> Int {
        guard sampleCount > 0, sampleRate > 0 else { return 0 }
        return Int((Double(sampleCount) * 60 / sampleRate).rounded(.up))
    }

    /// `.STPlayRegSound(snd, prio, vol)`: the cue and how many ticks its voice plays, or nil (sound off, no handle).
    func play(_ snd: Int16, priority: Int, volume: Int16) -> (cue: SoundCue, ticks: Int)? {
        guard soundOn, let n = lengths[snd] else { return nil }
        return (SoundCues.regSound(snd: snd, priority: priority, volume: volume, global: global), n)
    }
}

/// The screens between two levels (plan S2 `StageScreens`, L2): `.PopupStageLoad`, `.UpdateStageLoad`,
/// `.StageCompleteEffect`, `.CalcPercent`, `.FillPercent` (blocking loops → `FrontTimeline`s, played by `TimelineRun`)
/// and `.ChapterScreen` (input-polled → `ChapterScreenRun`). Bank world-data-format §4.3 (BC9), rendering-omnipx-titles
/// §4 (PICTs 140/141/142, 4610…4670).
///
/// **Rect conventions.** Every `Rect16` is QuickDraw {top, left, bottom, right}. The dump builds the panel and popup
/// rects with `SetRect(l, t, r, b)` and then shrinks them with `CONCAT22(hi ± s, lo)` on the {top, left} /
/// {bottom, right} words — so s moves **top** and **bottom**; the load bar and the `.FillPercent` rects are
/// `SetRect(l, t, r, b)` arguments, labelled where they are built.
public enum StageScreens {
    /// The stage-complete panel (320×110, port `0x100ab9f0` on clut 200, M l. 483).
    public static let panelPicture: Int16 = 140
    /// The stats bar strip (52×714: 51 rows of 14, port `0x100ab9f4` on clut 200, M l. 485).
    public static let barPicture: Int16 = 141
    /// The level-loading popup (320×64, port `0x100ab9f8` on clut 199, M l. 487).
    public static let popupPicture: Int16 = 142
    /// `GetCTable(200)` / `GetCTable(199)` (`.InitAppGlobals`, M l. 404–414): the ports' CLUTs.
    public static let panelClut: Int16 = 200
    public static let popupClut: Int16 = 199

    // MARK: .CalcPercent

    /// `.CalcPercent(a, b) @ 10005894` (M l. 2843–2865): b 0 → 100; a 0 → 0; else `(int)(100.0f · a / b)` in single
    /// precision (100.0f @ `100a1570`), clamped to 100 above and to 2 below (as shorts).
    public static func calcPercent(_ a: Int16, _ b: Int16) -> Int {
        if b == 0 { return 100 }
        if a == 0 { return 0 }
        let x = (Float(100) * Float(a)) / Float(b)
        let i = fctiwz(x)
        if Int16(truncatingIfNeeded: i) > 100 { return 100 }
        if Int16(truncatingIfNeeded: i) > 1 { return Int(i) }
        return 2
    }

    /// PowerPC `fctiwz`: toward zero, saturating at the Int32 bounds; NaN → Int32.min.
    static func fctiwz(_ x: Float) -> Int32 {
        if x.isNaN { return .min }
        if x >= 2_147_483_647 { return .max }
        if x <= -2_147_483_648 { return .min }
        return Int32(x.rounded(.towardZero))
    }

    // MARK: .PopupStageLoad / .UpdateStageLoad

    /// `.UpdateStageLoad(p, q)`'s bar width (M l. 2993–3029): `(int)((float)p / (float)q · 293.0f)` (293.0f @
    /// `100a156c`), the short clamped 0…293 (q 0 → ±inf / NaN → 0).
    public static func stageLoadWidth(_ p: Int16, of q: Int16) -> Int {
        let w = Int16(truncatingIfNeeded: fctiwz(Float(p) / Float(q) * 293))
        return Int(min(max(w, 0), 0x125))
    }

    /// `.UpdateStageLoad(p, q) @ 10005ce4`: `SetRect(172, 213, 172 + w, 224)` (**l, t, r, b**), `MTSetPortScreen`,
    /// `RGBForeColor(0x59d8 ×3)`, `PaintRect` — straight onto the screen, no wait (the `TickCount` read is unused).
    public static func updateStageLoad(_ p: Int16, of q: Int16) -> FrontOutput {
        let w = stageLoadWidth(p, of: q)
        let grey = RGB16(red: 0x59d8, green: 0x59d8, blue: 0x59d8)
        return FrontOutput(draws: [.fillRect(left: 0xac, top: 0xd5, right: 0xac + w, bottom: 0xe0, rgb: grey)],
                           present: true)
    }

    /// `.PopupStageLoad @ 10005ba0` (M l. 2946–2990): the whole PICT 142 (source `SetRect(0, 0, 320, 64)` (l, t, r, b)
    /// = {t 0, l 0, b 64, r 320}) copied by plain `CopyBits` (mode 0: the 199-port's colours remapped into the screen
    /// CLUT — `forceClut` 199 names the port's CLUT, the same conversion) **stretched** into {t 173 + s, l 160,
    /// b 237 − s, r 480} for s = 30, 28 … 0, one busy-waited tick each (no `DeadTime`): 16 ticks.
    public static func popupStageLoad() -> FrontTimeline {
        let source = Rect16(top: 0, left: 0, bottom: 0x40, right: 0x140)
        var events: [FrontTimeline.Event] = []
        for i in 0..<16 {
            let s = Int16(0x1e - 2 * i)
            let dest = Rect16(top: 0xad + s, left: 0xa0, bottom: 0xad + 0x40 - s, right: 0xa0 + 0x140)
            events.append(.init(at: i, output: FrontOutput(draws: [
                .copyPicture(id: popupPicture, chain: .frontEnd, source: source, dest: dest, forceClut: popupClut,
                             transparent: false)])))
        }
        return FrontTimeline(events: events, duration: 16)
    }

    // MARK: .FillPercent

    /// `.FillPercent(h, v, pct, dh, dv) @ 10005510` (M l. 2752–2836; BC9). n2 = (pct / 2) · 2 (the short, toward
    /// zero); a row lasts 1 tick when pct > 45, else 2. Row j: source `SetRect(0, 14j, 52, 14j + 14)` (l, t, r, b) of
    /// PICT 141, dest `SetRect(h, v, h + 52, v + 14)` (l, t, r, b) offset by (dh, dv), `CopyBitsCTForce` (port on clut
    /// 200). When n2 > 0: snd 803 (prio 1, vol 0xab), rows j = 0 … n2/2 − 1, each followed by polls for its row ticks
    /// that restart 803 whenever its voice has ended; then 803 stopped. Always: snd 804 (vol 0x100) and the final row
    /// n2/2; wait until 804 ends; 4 ticks; the band snd 800 (n2 < 11, vol 0x100) / 801 (< 100, vol 0xab) / 802 (vol
    /// 0x100); wait until it ends; 22 ticks (n2 < 11) else 12.
    public static func fillPercent(h: Int, v: Int, percent: Int, offsetH: Int, offsetV: Int,
                                   sounds: StageSounds) -> FrontTimeline {
        let pct = Int16(truncatingIfNeeded: percent)
        let rowTicks = pct > 0x2d ? 1 : 2
        let n2 = Int(Int16(truncatingIfNeeded: Int(pct) / 2 * 2))
        var b = TimelineBuilder()
        func row(_ j: Int) -> DrawOp {
            let top = Int16(truncatingIfNeeded: j * 0xe)
            let source = Rect16(top: top, left: 0, bottom: top + 0xe, right: 0x34)
            let l = Int16(truncatingIfNeeded: h + offsetH), t = Int16(truncatingIfNeeded: v + offsetV)
            let dest = Rect16(top: t, left: l, bottom: t + 0xe, right: l + 0x34)
            return .copyPicture(id: barPicture, chain: .frontEnd, source: source, dest: dest, forceClut: panelClut,
                                transparent: false)
        }
        var t = 0
        if n2 > 0 {
            var voice = sounds.play(803, priority: 1, volume: 0xab)
            var started = 0
            if let v = voice { b.add(at: 0, FrontOutput(sounds: [v.cue])) }
            for j in 0..<(n2 / 2) {
                b.add(at: t, FrontOutput(draws: [row(j)]))
                // `do { if (!FUN_100916dc(voice)) voice = STPlayRegSound(803…); DeadTime } while (now − tick < start)`:
                // one poll at least, on each tick of the row.
                for u in t..<(t + rowTicks) {
                    if voice == nil || u >= started + voice!.ticks {
                        if let v = sounds.play(803, priority: 1, volume: 0xab) {
                            voice = v
                            started = u
                            b.add(at: u, FrontOutput(sounds: [v.cue]))
                        }
                    }
                }
                t += rowTicks
            }
            // `FUN_10091504(voice)`: stops the last 803 voice (a −1 voice, sound off, stops nothing).
            if voice != nil { b.add(at: t, FrontOutput(soundStops: [803], soundStopAt: [0])) }
        }
        let tail = sounds.play(804, priority: 1, volume: 0x100)
        b.add(at: t, FrontOutput(draws: [row(n2 / 2)], sounds: tail.map { [$0.cue] } ?? []))
        t += tail?.ticks ?? 0
        t += 4
        let band: (cue: SoundCue, ticks: Int)?
        if n2 < 0xb {
            band = sounds.play(800, priority: 1, volume: 0x100)
        } else if n2 < 100 {
            band = sounds.play(801, priority: 1, volume: 0xab)
        } else {
            band = sounds.play(802, priority: 1, volume: 0x100)
        }
        if let c = band { b.add(at: t, FrontOutput(sounds: [c.cue])) }
        t += band?.ticks ?? 0
        t += n2 < 0xb ? 0x16 : 0xc
        return b.timeline(duration: t)
    }

    // MARK: .StageCompleteEffect

    /// `.StageCompleteEffect @ 10005950` (M l. 2870–2943): snd 805 (prio 1, vol 0x100, not waited on); 27 frames
    /// s = 52, 50 … 0 of the whole PICT 140 (source `SetRect(0, 0, 320, 110)` (l, t, r, b) = {t 0, l 0, b 110, r 320},
    /// `CopyBitsCTForce`, port on clut 200) stretched into {t 150 + s, l 160, b 260 − s, r 480}, one tick each; 15 ticks;
    /// three `.FillPercent(253, 50 / 68 / 86, CalcPercent(achieved[k][L], totals[k][L]), 160, 150)` for k = 0 enemies,
    /// 1 Xichrons, 2 secrets (G+0x306/0x3ce/0x496 and +0x6ee/0x7b6/0x87e + 2L; L = `*_DAT_1009feac`); 40 ticks.
    public static func stageCompleteEffect(globals g: GameGlobals, level: Int, sounds: StageSounds) -> FrontTimeline {
        var b = TimelineBuilder()
        let source = Rect16(top: 0, left: 0, bottom: 0x6e, right: 0x140)
        if let c = sounds.play(805, priority: 1, volume: 0x100) { b.add(at: 0, FrontOutput(sounds: [c.cue])) }
        var t = 0
        for i in 0..<27 {
            let s = Int16(0x34 - 2 * i)
            let dest = Rect16(top: 0x96 + s, left: 0xa0, bottom: 0x96 + 0x6e - s, right: 0xa0 + 0x140)
            b.add(at: t, FrontOutput(draws: [.copyPicture(id: panelPicture, chain: .frontEnd, source: source, dest: dest,
                                                          forceClut: panelClut, transparent: false)]))
            t += 1
        }
        t += 0xf
        for (k, v) in [0x32, 0x44, 0x56].enumerated() {
            let pct = calcPercent(g.achieved[k][level], g.totals[k][level])
            let bar = fillPercent(h: 0xfd, v: v, percent: pct, offsetH: 0xa0, offsetV: 0x96, sounds: sounds)
            b.append(bar, at: t)
            t += bar.duration
        }
        t += 0x28
        return b.timeline(duration: t)
    }
}

/// `.ChapterScreen(n) @ 10009b9c` (M l. 5038–5089) as a tick machine (plan L2). `init` returns nil when
/// `GetCTable(280 + n)` finds nothing — the original then skips everything. Otherwise, on the first `tick`:
/// `SetScreenClut(280 + n)`, PICT 4600 + 10n drawn into `SetRect(0, 0, 640, 480)` (l, t, r, b) by
/// `MTGetandDrawPICTResInRect` (the PICT's frame stretched to the rect — 608-wide cards widen [MED: library
/// `DrawPicture`]), then the blocking `GammaFadeInSlow(0x37)` (109 ticks when faded); then up to **1200** one-tick
/// waits, each polling `IsAnyInputKeyDown` (key codes 1…127, or Caps Lock locked) and `Button` and calling
/// `HideCursorSafe` — a key or the button ends the loop after the current tick; then `GammaFadeOut(0x1e)` (160
/// ticks), the level CLUT, PICT 129 in (0, 0, 640, 480) and `UpdateStatusBar(0, 0, 0)` (a full redraw) on the tick the fade ends.
/// `MusicAIFFTickle` is the QuickTime idle — nothing in the replica.
public struct ChapterScreenRun: Sendable {
    public let chapter: Int16
    public let levelClut: Int16
    public let statusBar: StatusBarState
    /// `GammaFadeOut`'s colour argument (`_DAT_100a53d0` / `_DAT_100a53c4` halves, stored for the async fade only)
    /// [LOW: the data-section value is not in the dump; black assumed].
    public let fadeColour: RGB16
    /// The card's frame size (the PICT header's picFrame).
    let pictureSize: (width: Int, height: Int)

    enum Phase: Sendable {
        case notStarted
        case fadeIn(TimelineRun)
        /// The wait loop: the next poll's tick, iterations left (`iVar6`), the key/button flag (`bVar1`).
        case waiting(next: UInt32, left: Int, pressed: Bool)
        case fadeOut(TimelineRun)
        case done
    }

    var phase: Phase = .notStarted

    public var clutId: Int16 { chapter &+ 0x118 }
    public var pictureId: Int16 { chapter &* 10 &+ 0x11f8 }

    /// The resources are looked up on the level chain (the call is made from `.GameLoop`, M l. 5241ff).
    public init?(chapter n: Int16, levelClut: Int16, statusBar: StatusBarState, resources: FerazelResources,
                 fadeColour: RGB16 = RGB16(red: 0, green: 0, blue: 0)) {
        chapter = n
        self.levelClut = levelClut
        self.statusBar = statusBar
        self.fadeColour = fadeColour
        guard resources.resource(type: "clut", id: n &+ 0x118, chain: .level) != nil else { return nil }
        let pict = resources.resource(type: "PICT", id: n &* 10 &+ 0x11f8, chain: .level)
        pictureSize = Self.frameSize(pict?.data) ?? (0x280, 0x1e0)
    }

    /// The picFrame {top, left, bottom, right} at bytes 2…9 of a PICT.
    static func frameSize(_ data: Data?) -> (width: Int, height: Int)? {
        guard let d = data, d.count >= 10 else { return nil }
        let b = [UInt8](d.prefix(10))
        func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
        return (i16(8) - i16(4), i16(6) - i16(2))
    }

    public var isDone: Bool {
        if case .done = phase { return true }
        return false
    }

    /// `.IsAnyInputKeyDown @ 1004a1d4` (M l. 42364–42383) with InputSprocket absent → `.IsAnyKeyDown @ 10034b1c`
    /// (M l. 31579–31595): `GetKeys`, then key codes **1 … 127** (key code 0, A, is never scanned). `GetKeys` reports
    /// a locked Caps Lock (0x39) as down; the replica carries it in `FrontInput.capsLock`, outside `keys`.
    static func isAnyKeyDown(_ input: FrontInput) -> Bool {
        input.capsLock || (1...0x7f).contains { input.keys.isPressed($0) }
    }

    /// One tick at absolute 60 Hz `now`; `input` is this tick's poll. `fade` is the flow's gamma state (the fades
    /// gate on and change it). Ticks the caller skipped are polled with this input.
    public mutating func tick(now: UInt32, input: FrontInput, fade: inout ScreenFade) -> FrontOutput {
        var out = FrontOutput()
        while true {
            switch phase {
            case .done:
                return out
            case .notStarted:
                let full = Rect16(top: 0, left: 0, bottom: 0x1e0, right: 0x280)
                let source = Rect16(top: 0, left: 0, bottom: Int16(truncatingIfNeeded: pictureSize.height),
                                    right: Int16(truncatingIfNeeded: pictureSize.width))
                out.append(FrontOutput(draws: [
                    .setScreenClut(id: clutId),
                    .copyPicture(id: pictureId, chain: .level, source: source, dest: full, forceClut: nil,
                                 transparent: false)], present: true))
                phase = .fadeIn(TimelineRun(fade.gammaFadeInSlow(0x37), start: now))
            case .fadeIn(var run):
                out.append(run.tick(now: now))
                guard run.isDone(now: now) else {
                    phase = .fadeIn(run)
                    return out
                }
                phase = .waiting(next: run.start &+ UInt32(run.timeline.duration), left: 0x4b0, pressed: false)
            case .waiting(var next, var left, var pressed):
                while Int32(bitPattern: now &- next) >= 0 {
                    if left < 1 || pressed { break }
                    if Self.isAnyKeyDown(input) || input.button { pressed = true }
                    left -= 1
                    out.append(FrontOutput(requests: [.hideCursor]))
                    next &+= 1
                }
                if Int32(bitPattern: now &- next) >= 0, left < 1 || pressed {
                    phase = .fadeOut(TimelineRun(fade.gammaFadeOut(0x1e, rgb: fadeColour), start: next))
                } else {
                    phase = .waiting(next: next, left: left, pressed: pressed)
                    return out
                }
            case .fadeOut(var run):
                out.append(run.tick(now: now))
                guard run.isDone(now: now) else {
                    phase = .fadeOut(run)
                    return out
                }
                // `DisposeCTable` of the card's CLUT: nothing to do.
                out.append(FrontOutput(draws: [
                    .setScreenClut(id: levelClut),
                    .drawPicture(id: 0x81, chain: .frontEnd, h: 0, v: 0),
                    .statusBar(statusBar)], present: true))
                phase = .done
            }
        }
    }
}

/// Builds a `FrontTimeline` from events added in non-decreasing tick order.
struct TimelineBuilder {
    var events: [FrontTimeline.Event] = []

    mutating func add(at t: Int, _ output: FrontOutput) {
        precondition(events.last.map { $0.at <= t } ?? true)
        events.append(.init(at: t, output: output))
    }

    /// `other`'s events shifted to start at `t`.
    mutating func append(_ other: FrontTimeline, at t: Int) {
        for e in other.events { add(at: t + e.at, e.output) }
    }

    func timeline(duration: Int) -> FrontTimeline { FrontTimeline(events: events, duration: duration) }
}
