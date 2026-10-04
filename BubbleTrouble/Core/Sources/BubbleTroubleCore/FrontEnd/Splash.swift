// The launch splash and loading screen (plan 2026-10-04 btx-playable C6; FI §1a), transcribed from `_InitMac
// @ 0000563c` (from `_DoBirthdaysCheck` on; the licence code is out of scope — Invariant 5), `_InitProgressBar
// @ 00006f83`, `_UpdateProgress @ 000071c5`, `_PlayIntroSound @ 00026986`, then `_Interface @ 0000b500`'s prologue.
//
// Windowed (bool 0x37 off, the default): comp ← black + PICT 200 centred, `_WipeScreenOut(4)`, held until 130 ticks
// after the reveal began; comp ← black, `_WipeScreen(4)`; comp ← black + PICT 9011 centred, `_WipeScreenOut(4)`;
// the progress bar on screen; snd 9027; held until 60 ticks after the bar. Full screen: the same pictures drawn
// straight to the screen between synchronous `CGDisplayFade`s (0.1 s to black, 0.6 s in / out) instead of wipes.

extension FrontEnd {
    /// `gPRect` (`_InitProgressBar`: L 0xfa T 0x1bd R 0x186 B 0x1c3).
    static let progressRect = QDRect(top: 0x1bd, left: 0xfa, bottom: 0x1c3, right: 0x186)
    /// `gPBorderCol1` (0, 0x7fff, 0x7fff), `gPBorderCol2` / `gPInside1` black, `gPInside2` (0xffff, 0xdfff, 0) —
    /// `__data` 0x3406a / 0x34064 / 0x3405e / 0x34058 (closes U4's progress-bar part / Q13).
    static let progressBorder1: UInt32 = 0x007f7f
    static let progressBorder2: UInt32 = 0x000000
    static let progressInside1: UInt32 = 0x000000
    static let progressInside2: UInt32 = 0xffdf00
    /// `FLOAT_00033fb0` = 95.0 — `_UpdateProgress`'s step total.
    static let progressTotal: Float = 95
    /// The `_UpdateProgress` calls of the load: 1 + one per sprite set of `_LoadSprites(0)` + 1 + orbit 1 + one per
    /// `snd` 9000…9047 (48) + 1. The bar clamps at its right edge.
    func progressSteps() -> Int { 1 + data.sprites.setCount + 1 + 1 + 48 + 1 }

    static let wipeOutAdvances4 = (2 * 4 + 0xf0) / 4 + 1
    static func wipeAdvances(_ step: Int) -> Int { (2 * step + 0xf0 + step - 1) / step }

    func splashSteps() -> [Step] {
        var steps: [Step] = []
        // `_DoBirthdaysCheck @ 0000c78e`: 20 Jan → DLOG 3000 (David Wareing), 17 Sep → DLOG 3001 (Alex Metcalf).
        let (month, day) = today()
        let birthday: Int? = switch (month, day) {
        case (1, 20): 3000
        case (9, 17): 3001
        default: nil
        }
        if let id = birthday {
            steps += [.run { SessionOutput(requests: [.modalDialog(id: id)]) }, .dialog(then: { _ in [] })]
        }
        let full = storedPrefs.fullScreen
        var t0: UInt32 = 0
        if full {
            steps += [
                .run { SessionOutput(drawOps: [.fillBlack(target: .screen)],
                                     requests: [.hideCursor, .displayFade(toBlack: true, seconds: 0.1)]) },
                .waitTicks(6),
                .run { [unowned self] in
                    t0 = now
                    return SessionOutput(drawOps: [.fillBlack(target: .screen), .fillBlack(target: .screen),
                                                   .pict(id: 200, dst: MainMenu.centred(data: data, pict: 200),
                                                         target: .screen)],
                                         requests: [.displayFade(toBlack: false, seconds: 0.6)])
                },
                .waitTicks(36),
                .waitUntil { t0 &+ 0x82 },
                .run { SessionOutput(requests: [.displayFade(toBlack: true, seconds: 0.6)]) },
                .waitTicks(36),
                .run { [unowned self] in
                    SessionOutput(drawOps: [.fillBlack(target: .screen), .fillBlack(target: .screen),
                                            .pict(id: 9011, dst: MainMenu.centred(data: data, pict: 9011),
                                                  target: .screen)],
                                  requests: [.displayFade(toBlack: false, seconds: 0.6)])
                },
                .waitTicks(36),
            ]
        } else {
            steps += [
                .run { [unowned self] in
                    t0 = now
                    return SessionOutput(drawOps: [.fillBlack(target: .screen), .fillBlack(target: .comp),
                                                   .pict(id: 200, dst: MainMenu.centred(data: data, pict: 200),
                                                         target: .comp),
                                                   .wipeOut(step: 4)])
                },
                .advances(Self.wipeOutAdvances4),
                .waitUntil { t0 &+ 0x82 },
                .run { SessionOutput(drawOps: [.fillBlack(target: .comp), .wipe(step: 4)]) },
                .advances(Self.wipeAdvances(4)),
                .run { [unowned self] in
                    SessionOutput(drawOps: [.fillBlack(target: .comp),
                                            .pict(id: 9011, dst: MainMenu.centred(data: data, pict: 9011),
                                                  target: .comp),
                                            .wipeOut(step: 4)])
                },
                .advances(Self.wipeOutAdvances4),
            ]
        }
        var t1: UInt32 = 0
        steps += [
            .run { [unowned self] in
                t1 = now
                var out = SessionOutput(drawOps: progressBarInitOps())
                // `_PlayIntroSound`: snd 9027 at priority 0x14 and the SFX volume — not at all when SFX is off.
                if (2...4).contains(prefs.sfxVolume) {
                    out.sounds.append(SoundCue(slot: 27, priority: 0x14, delayFrames: 0))
                }
                for n in 1...progressSteps() { out.drawOps.append(progressUpdateOp(n)) }
                return out
            },
            .waitUntil { t1 &+ 0x3c },
            .run { [unowned self] in
                push(interfaceEntrySteps())
                return SessionOutput()
            },
        ]
        return steps
    }

    /// `_InitProgressBar`: the outer border in `gPBorderCol1` (MoveTo/LineTo through (L−2,T−2)…(R+1,B+1), i.e. a
    /// frame of the rect outset 2), its four corners `SetCPixel` black, the inner border in `gPBorderCol2` (outset
    /// 1), the inside filled `gPInside1` — all on the screen.
    func progressBarInitOps() -> [DrawOp] {
        let r = Self.progressRect
        let outer = QDRect(top: r.top - 2, left: r.left - 2, bottom: r.bottom + 2, right: r.right + 2)
        let inner = QDRect(top: r.top - 1, left: r.left - 1, bottom: r.bottom + 1, right: r.right + 1)
        func pixel(_ h: Int16, _ v: Int16) -> DrawOp {
            .fillRect(QDRect(top: v, left: h, bottom: v + 1, right: h + 1), rgb: 0, target: .screen)
        }
        return [
            .frameRect(outer, rgb: Self.progressBorder1, target: .screen),
            pixel(r.right + 1, r.top - 2), pixel(r.right + 1, r.bottom + 1),
            pixel(r.left - 2, r.bottom + 1), pixel(r.left - 2, r.top - 2),
            .frameRect(inner, rgb: Self.progressBorder2, target: .screen),
            .fillRect(r, rgb: Self.progressInside1, target: .screen),
        ]
    }

    /// `_UpdateProgress` call `n`: `gPInside2` from the left edge to `left + (int)((float)(R − L) · (n / 95.0f))`,
    /// clamped to the right edge.
    func progressUpdateOp(_ n: Int) -> DrawOp {
        let r = Self.progressRect
        let width = Float(Int(r.right) - Int(r.left))
        let grown = Int16(truncatingIfNeeded: Int(r.left) + Int(width * (Float(n) / Self.progressTotal)))
        let right = grown <= r.right ? grown : r.right
        return .fillRect(QDRect(top: r.top, left: r.left, bottom: r.bottom, right: right), rgb: Self.progressInside2,
                         target: .screen)
    }

    /// `_Interface`'s prologue: timers, `_ResetMenuStars`, the latches, `_LoadMusic(0)`, `_DrawMainMenu`,
    /// `_CheckNumRecordings`, cursor, `_WipeScreen(6)`; then (foreground, registered) `_StartMusic` and
    /// `_UpdateScreen`.
    func interfaceEntrySteps() -> [Step] {
        [
            .run { [unowned self] in
                phase = .busy
                idleStart = now
                hitButtons = []
                msgCounter = 0
                infoTimer = now
                events = []                                              // FlushEvents(0x3e)
                stars.reset(now: now, mouse: mouse)
                var latch = random
                let u = latch.fast(0, 6)
                let l = latch.fast(0xd, 0x16)
                random = latch
                latches = SessionLatches(u: u, L: l)
                var out = loadTitleMusic()
                out.drawOps += drawMainMenuOps()
                numFilms = countFilms()
                out.requests += [.showCursor, .setCursor(id: 200)]
                out.drawOps.append(.wipe(step: 6))
                return out
            },
            .advances(Self.wipeAdvances(6)),
            .run { [unowned self] in
                var out = SessionOutput()
                if !foreground {
                    out.append(suspendGame())
                } else {
                    out.append(startMusic())
                }
                out.drawOps.append(.compToScreen(MainMenu.screenRect))
                return out
            },
        ]
    }

    /// `_CheckNumRecordings @ 0001716f`: FILM 1, 2, … while `GetResource` finds them.
    func countFilms() -> Int {
        var n = 0
        while data.levels.filmIDs.contains(n + 1) { n += 1 }
        return n
    }
}
