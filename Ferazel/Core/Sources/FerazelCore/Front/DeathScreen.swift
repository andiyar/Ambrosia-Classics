import Foundation

/// The death screen (plan S2 `DeathScreen`, D1; bank save-continue §5): `.AskToContinue @ 10007190` (M l. 3718–3858)
/// with `.TrackClickOnCommandButtonDeath @ 10006970` (M l. 3440–3500), `.WandGlow @ 10006b6c` (M l. 3503–3540) and
/// `.TurnGray @ 10006ca4` (M l. 3543–3714), as a tick machine. GameFlow (F1b) builds one after a death and ticks it
/// until `isDone`; `continues` is `.AskToContinue`'s return.
///
/// - `FlushEvents(0xff7f, 0)` runs first (no event queue in Core). `fe00 == 0` (`saved` false: nothing saved or loaded
///   since New Game) → returns false with no drawing.
/// - Else `SetScreenClut(clut 132)` (`_DAT_100a0014` = `GetCTable(0x84)`, M l. 436), the three
///   `ChangeBlitPortClut`s (off-screen ports — nothing on the screen), PICT 138 (Titles, 640×480) to the back screen +
///   `MTRedraw`, the blocking `GammaFadeIn(6)`, `ResetCursor`, `ShowCursorSafe`.
/// - The loop, one pass per tick (the original spins without a wait; `.DeadTime` = `Button`, the empty `.CheckFlags`,
///   the QuickTime idle): the mouse in `PointInRect(252, 390, 389, 411)` (l, t, r, b) → `TrackClick(1, 1)`, else in
///   `(262, 413, 378, 433)` → `TrackClick(2, 1)`; then the keys: Return (0x24) or Enter (0x4c) → `TrackClick(1, 0)`;
///   else Esc (0x35) or ⌘ (0x37) with Q (0x0c) → `TrackClick(2, 0)` — a keyboard press chooses whatever the tracker
///   returns. InputSprocket is never on (prefs+0x0a forced 0), so its marker branches never run.
/// - Button 2 chosen → `.TurnGray`, else `.WandGlow`; returns "button 2 not chosen".
public struct DeathScreen: Sendable {
    /// `.AskToContinue`'s hit rects `PointInRect(l, t, r, b)` — each 1 px smaller than the tracker's rect.
    static let hitRects = [Rect16(top: 0x186, left: 0xfc, bottom: 0x19b, right: 0x185),
                           Rect16(top: 0x19d, left: 0x106, bottom: 0x1b1, right: 0x17a)]
    /// `.TrackClickOnCommandButtonDeath`'s rects `SetRect(252, 390, 390, 412)` / `(262, 413, 379, 434)` (l, t, r, b).
    public static let buttonRects = [Rect16(top: 0x186, left: 0xfc, bottom: 0x19c, right: 0x186),
                                     Rect16(top: 0x19d, left: 0x106, bottom: 0x1b2, right: 0x17b)]
    /// `.WandGlow`'s rect: `SetRect(0x8b, 0x11f, 0xdd, 0x171)` offset by (−1, −1) → (138, 286, 220, 368) (l, t, r, b).
    public static let glowRect = Rect16(top: 0x11e, left: 0x8a, bottom: 0x170, right: 0xdc)
    /// The death screen's CLUT and background.
    public static let clutId: Int16 = 0x84
    public static let backgroundPicture: Int16 = 0x8a

    public let saved: Bool
    public let prefs: FerazelPrefs
    /// The level's scroll point (`PTR_DAT_1009fe78`, h and v) when the game loop ended: `.TurnGray`'s sound plays at
    /// the view centre (h + 0x140, v + 0xc0).
    public let scrollH: Int
    public let scrollV: Int
    /// Entry 255 of the level working CLUT `*_DAT_1009fe94`: `.TurnGray` computes entries 0…254 into that table and
    /// `SetEntries(0, 0xff)` sends all 256, so the last is whatever the level left there (black in every shipped `clut`
    /// but 198) [MED: the replica's Core does not hold the working copy; the caller supplies it].
    public let entry255: RGB16
    let clut: ColorLUT
    /// picFrame sizes (width, height) of the PICTs this screen draws into rects.
    let sizes: [Int16: (width: Int, height: Int)]

    /// The button the loop ended on (1 Continue, 2 Abort); nil while undecided or when no screen ran.
    public private(set) var chosen: Int?
    /// `.AskToContinue`'s return once `isDone`.
    public private(set) var continues: Bool?

    enum Phase: Sendable {
        case notStarted
        case fadeIn(TimelineRun)
        case polling
        /// `TrackClick(n, ·)`'s `while (Button())` loop; `fromKey` = called with param 0 while the button was down.
        case tracking(button: Int, fromKey: Bool, pressed: Bool)
        /// `TrackClick(n, 0)`'s `Delay(10)` after the pressed face.
        case keyDelay(button: Int, until: UInt32)
        case effect(TimelineRun)
        case done
    }

    var phase: Phase = .notStarted
    /// `bVar2` (Continue chosen) and `bVar7` (Abort chosen).
    var continueFlag = false
    var abortFlag = false

    /// - Throws: `ColorLUTError` when clut 132 is missing.
    public init(saved: Bool, prefs: FerazelPrefs, resources: FerazelResources, scrollH: Int, scrollV: Int,
                entry255: RGB16 = RGB16(0, 0, 0)) throws {
        self.saved = saved
        self.prefs = prefs
        self.scrollH = scrollH
        self.scrollV = scrollV
        self.entry255 = entry255
        clut = try ColorLUT.load(id: Self.clutId, from: resources, chain: .frontEnd)
        var sizes: [Int16: (width: Int, height: Int)] = [:]
        for id in [4970, 4971, 4980, 4981] + Array(0xac...0xb1) {
            let id = Int16(id)
            if let s = ChapterScreenRun.frameSize(resources.resource(type: "PICT", id: id, chain: .frontEnd)?.data) {
                sizes[id] = s
            }
        }
        self.sizes = sizes
    }

    public var isDone: Bool {
        if case .done = phase { return true }
        return false
    }

    // MARK: Pieces

    /// `MTGetandDrawPICTResInRect(id, rect)`: the picture's frame drawn into `rect` (nothing when the PICT is missing).
    func drawInRect(_ id: Int16, _ rect: Rect16) -> FrontOutput {
        guard let s = sizes[id] else { return FrontOutput() }
        return FrontOutput(draws: [.copyPicture(id: id, chain: .frontEnd,
                                                source: Rect16(top: 0, left: 0, bottom: Int16(s.height),
                                                               right: Int16(s.width)),
                                                dest: rect, forceClut: nil, transparent: false)], present: true)
    }

    /// `.STPlayRegSound(snd, 10, vol)` (sound off → nothing; every snd here has a loaded handle, `SoundSlots`).
    func regSound(_ snd: Int16, volume: Int16) -> FrontOutput {
        guard prefs.soundOn != 0 else { return FrontOutput() }
        return FrontOutput(sounds: [SoundCues.regSound(snd: snd, priority: 10, volume: volume,
                                                       global: SoundCues.globalVolume(prefs))])
    }

    /// The pressed face `PICT 4979 + n` with snd 4803 "Mouse Down" (`_DAT_100a0040`, 10, 0x55).
    func pressed(_ n: Int) -> FrontOutput {
        var o = drawInRect(Int16(0x1373 + n), Self.buttonRects[n - 1])
        o.append(regSound(0x12c3, volume: 0x55))
        return o
    }

    /// The idle face `PICT 4969 + n` with snd 4804 "Mouse Up" (`_DAT_100a003c`, 10, 0x55).
    func released(_ n: Int) -> FrontOutput {
        var o = drawInRect(Int16(0x1369 + n), Self.buttonRects[n - 1])
        o.append(regSound(0x12c4, volume: 0x55))
        return o
    }

    static func contains(_ r: Rect16, _ p: (h: Int, v: Int)?) -> Bool {
        guard let p else { return false }   // GetMouse outside the canvas: in no rect
        return p.h >= Int(r.left) && p.h < Int(r.right) && p.v >= Int(r.top) && p.v < Int(r.bottom)
    }

    /// One iteration of the tracker's `while (Button())` body (button down): the face follows the mouse in and out of
    /// the button's rect, 4803 on entering and 4804 on leaving.
    func track(_ n: Int, pressed: inout Bool, input: FrontInput, into out: inout FrontOutput) {
        if Self.contains(Self.buttonRects[n - 1], input.mouse) {
            if !pressed { pressed = true; out.append(self.pressed(n)) }
        } else if pressed {
            pressed = false
            out.append(released(n))
        }
    }

    /// `TrackClickOnCommandButtonDeath(n, 0)` from the key branch: with the button up, the pressed face, 4803 and
    /// `Delay(10)`; with the button down, the mouse-tracking loop.
    mutating func keyTrack(_ n: Int, now: UInt32, input: FrontInput, into out: inout FrontOutput) {
        if input.button {
            var p = false
            track(n, pressed: &p, input: input, into: &out)
            phase = .tracking(button: n, fromKey: true, pressed: p)
        } else {
            out.append(pressed(n))
            phase = .keyDelay(button: n, until: now &+ 10)
        }
    }

    /// The key half of a loop pass; true when a key started a `TrackClick(n, 0)` (the pass continues there).
    mutating func keyHalf(now: UInt32, input: FrontInput, into out: inout FrontOutput) -> Bool {
        let k = input.keys
        if k.isPressed(0x24) || k.isPressed(0x4c) {
            keyTrack(1, now: now, input: input, into: &out)
            return true
        }
        if k.isPressed(0x35) || (k.isPressed(0x37) && k.isPressed(0x0c)) {
            keyTrack(2, now: now, input: input, into: &out)
            return true
        }
        return false
    }

    /// The pass ends (`.DeadTime`); the loop exits when a flag is set: Abort → `.TurnGray`, else `.WandGlow`.
    mutating func endPass(now: UInt32) {
        guard continueFlag || abortFlag else {
            phase = .polling
            return
        }
        chosen = abortFlag ? 2 : 1
        phase = .effect(TimelineRun(abortFlag ? turnGray() : wandGlow(), start: now))
    }

    // MARK: Exit effects

    /// `.WandGlow`: a 6-tick wait, snd 606 (`_DAT_1009fdf0`, 10, 0x100), then 11 frames of 5 ticks — PICT 172…177,
    /// then 176…172 — in `glowRect` (drawn straight to the screen, `MTSetPortScreen`).
    func wandGlow() -> FrontTimeline {
        var b = TimelineBuilder()
        for i in 0..<11 {
            let id = Int16(i < 6 ? 0xac + i : 0xb6 - i)
            var o = i == 0 ? regSound(0x25e, volume: 0x100) : FrontOutput()
            o.append(drawInRect(id, Self.glowRect))
            b.add(at: 6 + 5 * i, o)
        }
        return b.timeline(duration: 6 + 55)
    }

    /// `.TurnGray`: snd 435 (`_DAT_1009fdec`) through `STPlay3DSoundPitched(snd, 10, 0x100, view centre, 35000)`, then
    /// for f = 0…150 one `SetEntries(0, 0xff)` of `turnGray(clut 132, f)` per tick (each frame waits until
    /// `TickCount` has moved on by 1). Afterwards entries 0…254 of the level working copy `*_DAT_1009fe94` are copied
    /// back from the level CLUT `*_DAT_1009ff8c` (M l. 3687–3714) — a write to the level's working table only, with no
    /// `SetEntries`: the screen stays black until the next `SetScreenClut`. The replica's working copy is rebuilt at
    /// every level load (`.SetupLevel`'s `HandToHand`), so nothing is emitted for it.
    func turnGray() -> FrontTimeline {
        var b = TimelineBuilder()
        var o = FrontOutput()
        if prefs.soundOn != 0, let cue = SoundCues.play3DPitched(
            snd: 0x1b3, priority: 10, volume: 0x100,
            position: SpriteSlot.Point(x: Int(Int16(truncatingIfNeeded: scrollH + 0x140)),
                                       y: Int(Int16(truncatingIfNeeded: scrollV + 0xc0))),
            rate: 35000, scrollH: scrollH, scrollV: scrollV, global: SoundCues.globalVolume(prefs)) {
            o.sounds.append(cue)
        }
        for f in 0...150 {
            o.draws.append(.screenGamma(.clut(entries: Self.turnGray(clut, frame: f, entry255: entry255))))
            o.present = true
            b.add(at: f, o)
            o = FrontOutput()
        }
        return b.timeline(duration: 151)
    }

    /// Frame `f` of `.TurnGray`'s table (raw `10006d40..10006f30`): k = (float)(1 − (float)(100f / 7500.0)) (7500.0 @
    /// `100a1560`), 0 when below 0; for entries 0…254 of `source`, gray = (r + g + b) >> 2 and, when f > 75,
    /// gray = (int)((float)gray · (float)((150 − f) / 75.0)) (75.0 @ `100a1540`); each channel c →
    /// (int)((double)(float)(c · k) + gray · (1 − k)) (single product, double sum, truncated), clamped to 0…0xffff.
    /// Entry 255 is not computed (`entry255`).
    public static func turnGray(_ source: ColorLUT, frame f: Int, entry255: RGB16) -> [RGB16] {
        var k = Float(1.0 - Double(Float(Double(Float(100 * f)) / 7500.0)))
        if k < 0 { k = 0 }
        let oneMinusK = 1.0 - Double(k)
        let scale: Float? = f > 0x4b ? Float(Double(Float(0x96 - f)) / 75.0) : nil
        func channel(_ c: UInt16, _ grayPart: Double) -> UInt16 {
            let v = Double(Float(c) * k) + grayPart
            let i = Int(v.rounded(.towardZero))
            return UInt16(i < 1 ? 0 : min(i, 0xffff))
        }
        var out: [RGB16] = []
        out.reserveCapacity(256)
        for e in source.entries.prefix(255) {
            var gray = (Int(e.red) + Int(e.green) + Int(e.blue)) >> 2
            if let s = scale { gray = Int((Float(gray) * s).rounded(.towardZero)) }
            let grayPart = Double(gray) * oneMinusK
            out.append(RGB16(channel(e.red, grayPart), channel(e.green, grayPart), channel(e.blue, grayPart)))
        }
        out.append(entry255)
        return out
    }

    // MARK: Tick

    /// One tick at absolute 60 Hz `now`; `input` is this tick's poll; `fade` is the flow's gamma state
    /// (`GammaFadeIn(6)` gates on and clears it).
    public mutating func tick(now: UInt32, input: FrontInput, fade: inout ScreenFade) -> FrontOutput {
        var out = FrontOutput()
        while true {
            switch phase {
            case .done:
                return out
            case .notStarted:
                // `FlushEvents(0xff7f, 0)` — nothing in Core.
                guard saved else {
                    continues = false
                    phase = .done
                    return out
                }
                out.append(FrontOutput(draws: [.setScreenClut(id: Self.clutId),
                                               .drawPicture(id: Self.backgroundPicture, chain: .frontEnd, h: 0, v: 0)],
                                       present: true))
                phase = .fadeIn(TimelineRun(fade.gammaFadeIn(6), start: now))
            case .fadeIn(var run):
                out.append(run.tick(now: now))
                guard run.isDone(now: now) else {
                    phase = .fadeIn(run)
                    return out
                }
                // `ResetCursor` (the arrow), `ShowCursorSafe`; the first pass runs on the tick the fade ends.
                out.append(FrontOutput(requests: [.showCursor]))
                phase = .polling
                pass(now: now, input: input, into: &out)
                if case .effect = phase { continue }
                return out
            case .polling:
                pass(now: now, input: input, into: &out)
                if case .effect = phase { continue }
                return out
            case .tracking(let n, let fromKey, var p):
                if input.button {
                    track(n, pressed: &p, input: input, into: &out)
                    phase = .tracking(button: n, fromKey: fromKey, pressed: p)
                    return out
                }
                if p { out.append(released(n)) }
                if fromKey {
                    // The key branch sets its flag whatever the tracker returned.
                    if n == 1 { continueFlag = true } else { abortFlag = true }
                    endPass(now: now)
                } else {
                    if p { if n == 1 { continueFlag = true } else { abortFlag = true } }
                    if !keyHalf(now: now, input: input, into: &out) { endPass(now: now) }
                }
                if case .effect = phase { continue }
                return out
            case .keyDelay(let n, let until):
                guard Int32(bitPattern: now &- until) >= 0 else { return out }
                out.append(released(n))
                if n == 1 { continueFlag = true } else { abortFlag = true }
                endPass(now: until)
                if case .effect = phase { continue }
                return out
            case .effect(var run):
                out.append(run.tick(now: now))
                guard run.isDone(now: now) else {
                    phase = .effect(run)
                    return out
                }
                continues = !abortFlag
                phase = .done
                return out
            }
        }
    }

    /// One loop pass from its start: the mouse half, then the key half, then `.DeadTime`.
    mutating func pass(now: UInt32, input: FrontInput, into out: inout FrontOutput) {
        for n in 1...2 where Self.contains(Self.hitRects[n - 1], input.mouse) {
            // `TrackClick(n, 1)`: with the button up the `while (Button())` loop never runs and it returns 0.
            if input.button {
                var p = false
                track(n, pressed: &p, input: input, into: &out)
                phase = .tracking(button: n, fromKey: false, pressed: p)
                return
            }
            break
        }
        if !keyHalf(now: now, input: input, into: &out) { endPass(now: now) }
    }
}
