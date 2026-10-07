import Foundation

/// What begin frame (`FUN_10030360`) hands the loop, beyond the controller's tick/quit/frames. C18a turns it
/// into ops and cues; nothing here is pass output. ★ LOCKED name (plan S2).
public struct FrameKeysResult: Equatable, Sendable {
    /// `*param_2` = the tick flag (+0x34): run the world update this pass.
    public var tick: Bool
    /// Esc (`FUN_100307c0`) or +0x02.
    public var quit: Bool
    /// The return value, +0x08 (the game stores it at G+0x30, `10005910`).
    public var framesPresented: Int32
    /// Caps Lock started a pause this frame (`10030420..100304dc`): the notice is posted; the end-frame wrapper
    /// runs the pause screen (`FrameKeys.endFrameWrapper` → `.pauseWait`).
    public var pauseStarted: Bool
    /// `-` / `=` went down this frame: int pref 0 as `FUN_10047990` / `FUN_10047a30` left it. On Mac OS X (Q4,
    /// D31) that is all: no gain change, no click, no message.
    public var volume: Int32?
    /// F6 toggled byte pref 5 this frame (message + gaso 7 already recorded).
    public var interlaceToggled: Bool
    /// The console is open at the input read (`10030534 bl 0x1002d190; bne`): no player input this tick (the
    /// same test in `FUN_10006b50`).
    public var inputWithheld: Bool
}

/// The begin-frame keys and the end-frame wrapper's pause and FPS monitor (timing-frame §2.1, §2.4, §2.6;
/// messages-notices-console §2.5, §4.4, §5.1; sound-music §4.3; front-end §8). ★ LOCKED name (plan S2).
///
/// Listing reads for plan C19 (`disasm-review3-all.txt`):
/// - `FUN_10030210` (`1003023c..10030284`): zero, +1/+4/+3, clear layers, console reset `FUN_1002d040(+8)`,
///   messages reset, FPS init `FUN_100305e0`, divider reset, FlushEvents.
/// - `FUN_10030360` (`10030380..10030564`): music service; clear layers; console open (`1002d190`) → update
///   `FUN_1002d230(+8)`, else key 0x32 down → `FUN_1002d1a0(+8)`; message aging `FUN_1002dd90(+8)`; `FUN_10030910`;
///   GetMouse; Caps Lock (0x39): up → +0 = 0; down, +0 == 0 and +1 == 0 → +0 = 1 and the notice (GameString 0,
///   template `r2+0x4e9c`, fade-in off, `CEBU` when +4 == 0, `CEGA` when 1) at game time `FUN_10005ce0`; down
///   otherwise → nothing; quit = Esc or +2; tick flag → input cleared and read unless the console is open.
/// - `FUN_10030910` (`10030930..10030bb8`): latch +0x0e for `-` (0x1B): clear → key down sets it and runs
///   `FUN_10047990`; set → latch = key. Same for +0x0f / `=` (0x18) / `FUN_10047a30`. `FUN_100461b0` (OS X) true →
///   no click and no message (`100309ec..100309f8`; the OS 9 branch `100309fc..10030aa0` is NOT built — Q4, D31).
///   Latch +0x10 / F6 (0x61): message GameString 18 if pref 5 else 17 (type 0), pref 5 = !pref 5, gaso 7 via
///   `FUN_10047670(id, 100, 100, 1)`.
/// - `FUN_10047990` / `FUN_10047a30` (`100479a8..10047a0c`, `10047a48..10047ab0`): v = int pref 0; (sound
///   available) v > 0 → v = max(v − 10, 0) / v < 100 → v = min(v + 10, 100), device skipped on OS X, int pref 0 =
///   v; return v.
/// - `FUN_10030570` (`10030584..100305c0`): end frame `FUN_10030bc0`, Esc (discarded), `FUN_10030870`, then the
///   FPS monitor if the tick flag just computed is set.
/// - `FUN_10030870` (`10030884..100308dc`): paused → console reset `FUN_1002d040(+8)`, `FUN_10022ef0(+4, 0, 0)`
///   (`10022f1c..1002300c`: FlushEvents, `FUN_100476a0` halt, gaso 8 `(0x32, 100, 1)`, music pause, wait for Caps
///   Lock up, music resume, present by +4), +2 on quit (never in 1.0.6), notice clear at game time, +0 = 0.
/// - `FUN_10030640` (`10030650..10030784`): see `fpsMonitor`.
public enum FrameKeys {
    /// Mac virtual key codes `GetKeys` tests (`FUN_10049150`).
    public static let consoleKey: UInt16 = 0x32
    public static let minusKey: UInt16 = 0x1b
    public static let equalsKey: UInt16 = 0x18
    public static let f6Key: UInt16 = 0x61
    public static let escKey: UInt16 = 0x35

    /// `FUN_10030210` — start session (the Core part; the layer clear is the renderer's).
    public static func startSession(controller c: inout FrameController, console: inout Console, game: inout GameState,
                                    filmPlayback: Bool, gameScreenLayout: Bool, autoInterlaceAllowed: Bool,
                                    ticks: UInt32) {
        c.startSession(filmPlayback: filmPlayback, gameScreenLayout: gameScreenLayout,
                       autoInterlaceAllowed: autoInterlaceAllowed)   // zero, +1/+4/+3, … divider reset (order-free)
        console.reset(frame: UInt32(bitPattern: c.framesPresented))  // 1003025c
        game.messages.reset()                                         // 10030264
        c.fpsMonitorInit(ticks: ticks)                                // 10030270
        console.flushEvents()                                         // 10030284
    }

    /// `FUN_10030360` — begin frame.
    public static func beginFrame(controller c: inout FrameController, console: inout Console, game: inout GameState,
                                  keys: HeldKeys) -> FrameKeysResult {
        let frame = UInt32(bitPattern: c.framesPresented)
        if console.isOpen {                                           // 10030390..100303ac
            console.update(frame: frame, typed: keys.typed, game: &game)
        } else if keys.held.contains(consoleKey) {                    // 100303b0..100303c8
            console.open(frame: frame, game: &game)
        }
        game.messages.age(frame: frame)                               // 100303d0..100303d4
        let (volume, interlace) = volumeAndInterlaceKeys(controller: &c, game: &game, held: keys.held)   // 100303e0
        var pauseStarted = false
        if keys.capsLock {                                            // 100303f4..10030404
            if !c.paused && !c.filmPlayback {                         // 10030408..1003041c
                c.paused = true                                       // 10030428
                let post = NoticeSlot.Post.pressCapsLock(text: game.assets.gameStrings[0],
                                                         controllerMode: c.gameScreenLayout ? 1 : 0)
                game.notice.post(post, now: game.flags.gameTime)      // 100304cc..100304dc
                pauseStarted = true
            }
        } else {
            c.paused = false                                          // 100304e8..100304ec
        }
        let begin = c.beginFrame(escDown: keys.held.contains(escKey), escHoldPref: game.prefs.bytePrefs[8] != 0)
        return FrameKeysResult(tick: begin.tick, quit: begin.quit, framesPresented: begin.framesPresented,
                               pauseStarted: pauseStarted, volume: volume, interlaceToggled: interlace,
                               inputWithheld: console.isOpen)         // 10030534..10030540
    }

    /// `FUN_10030910` — the volume keys (Mac OS X behaviour only, Q4/D31) and F6.
    static func volumeAndInterlaceKeys(controller c: inout FrameController, game: inout GameState,
                                       held: Set<UInt16>) -> (volume: Int32?, interlace: Bool) {
        var volume: Int32?
        if !c.latchMinus {                                            // 10030938..10030980
            if held.contains(minusKey) {
                c.latchMinus = true
                volume = volumeDown(&game.prefs)
            }
        } else {
            c.latchMinus = held.contains(minusKey)                    // 10030984..10030990
        }
        if !c.latchEquals {                                           // 10030994..100309d8
            if held.contains(equalsKey) {
                c.latchEquals = true
                volume = volumeUp(&game.prefs)
            }
        } else {
            c.latchEquals = held.contains(equalsKey)                  // 100309dc..100309e8
        }
        // 100309ec..100309f8: FUN_100461b0 (Mac OS X) is true → no click, no message (Q4 RULED, D31).
        var interlace = false
        if !c.latchF6 {                                               // 10030aa4..10030b74
            if held.contains(f6Key) {
                c.latchF6 = true
                let was = game.prefs.bytePrefs[5] != 0
                game.messages.post(text: game.assets.gameStrings[was ? 18 : 17], kind: .normal)   // 10030acc..10030b1c
                game.prefs.bytePrefs[5] = was ? 0 : 1                 // 10030b24..10030b40
                game.cues.sounds.append(SoundPlay.perm(game.assets.sounds[7], priority: 100, volume: 100,
                                                       allowMultiple: true))   // 10030b48..10030b60
                interlace = true
            }
        } else {
            c.latchF6 = held.contains(f6Key)                          // 10030b78..10030b9c
        }
        return (volume, interlace)
    }

    /// `FUN_10047990` — sound volume down (sound is always available here; the device write is skipped on OS X).
    static func volumeDown(_ prefs: inout DeimosPrefs) -> Int32 {
        var v = prefs.intPrefs[0]                                     // 100479a8
        guard v > 0 else { return v }                                 // 100479c0..100479c4
        v -= 10                                                       // 100479c8 subic.
        if v < 0 { v = 0 }                                            // 100479cc..100479d0
        prefs.intPrefs[0] = v                                         // 100479fc..10047a04
        return v
    }

    /// `FUN_10047a30` — sound volume up.
    static func volumeUp(_ prefs: inout DeimosPrefs) -> Int32 {
        var v = prefs.intPrefs[0]                                     // 10047a48
        guard v < 100 else { return v }                               // 10047a60..10047a64
        v += 10                                                       // 10047a68
        if v > 100 { v = 100 }                                        // 10047a6c..10047a74
        prefs.intPrefs[0] = v                                         // 10047aa0..10047aa8
        return v
    }

    /// `FUN_10030570` after its `FUN_10030bc0` draw part: the end-frame counters (`FrameController.endFrame`), Esc
    /// again (discarded), the pause screen (`FUN_10030870`), then the FPS monitor if the next frame ticks. Returns
    /// the present of the blocking `.pauseWait` when the pause screen ran (the cues around the wait — halt, gaso
    /// 8, music pause, then music resume — are already in `game.cues`; the host waits for Caps Lock up).
    public static func endFrameWrapper(controller c: inout FrameController, console: inout Console,
                                       game: inout GameState, keys: HeldKeys, ticks: UInt32) -> PresentKind? {
        c.endFrame()                                                  // 10030584
        _ = c.escCheck(escDown: keys.held.contains(escKey), escHoldPref: game.prefs.bytePrefs[8] != 0)   // 10030590
        let wait = pauseScreen(controller: &c, console: &console, game: &game)   // 1003059c
        if c.tickNextFrame {                                          // 100305a8..100305b4
            fpsMonitor(controller: &c, game: &game, ticks: ticks)     // 100305bc
        }
        return wait
    }

    /// `FUN_10030870` → `FUN_10022ef0(+4, 0, 0)`.
    static func pauseScreen(controller c: inout FrameController, console: inout Console,
                            game: inout GameState) -> PresentKind? {
        guard c.paused else { return nil }                            // 10030884..1003088c
        console.reset(frame: UInt32(bitPattern: c.framesPresented))   // 10030890..10030894
        console.flushEvents()                                         // 10022f1c
        game.cues.haltEffects()                                       // 10022f24 FUN_100476a0
        game.cues.sounds.append(SoundPlay.perm(game.assets.sounds[8], priority: 0x32, volume: 100,
                                               allowMultiple: true))  // 10022f2c..10022f44
        game.cues.music.append(.pause)                                // 10022f4c..10022f50
        // … the host waits for Caps Lock up (`.pauseWait`); quit (b8) is never set during play (INDEX #48) …
        game.cues.music.append(.resume)                               // 10022fb4..10022fb8
        game.notice.post(nil, now: game.flags.gameTime)               // 100308c0..100308d0
        c.paused = false                                              // 100308d8..100308dc
        return c.gameScreenLayout ? .gameScreen : .fullScreen         // 10022fd4..10023004 (+4 = 1 / 0)
    }

    /// `FUN_10030640` — on tick frames: TickCount > +0x18 + 60 (`cmplw; ble`) → +0x24 = +0x20; byte pref 10 →
    /// clamp +0x20 to 30, and +0x20 < 30 → +0x28 += 1, at fctiwz(flli 34) (10): +0x28 = 0 and, with +3, byte pref 6
    /// and not byte pref 5, byte pref 5 = 1 + GameString 17 (type 0); then +0x20 = 0, +0x18 = TickCount.
    static func fpsMonitor(controller c: inout FrameController, game: inout GameState, ticks: UInt32) {
        let maxRate = c.fpsMaxRate                                    // 10030650..1003066c
        guard ticks > c.fpsWindowStart &+ 60 else { return }          // 10030670..10030684
        c.fpsShown = c.windowFrames                                   // 10030688..10030690
        if game.prefs.bytePrefs[10] != 0 {                            // 1003068c..100306a0
            if c.windowFrames > maxRate { c.windowFrames = maxRate }  // 100306a4..100306b0
            if c.windowFrames < maxRate {                             // 100306b4..100306bc
                c.deficientWindows &+= 1                              // 100306c0..100306cc
                if c.deficientWindows == EntityDraw.fctiwz(game.assets.floats[34]) {   // 100306d0..100306ec
                    c.deficientWindows = 0                            // 100306f0..100306f4
                    if c.autoInterlaceAllowed && game.prefs.bytePrefs[6] != 0 && game.prefs.bytePrefs[5] == 0 {
                        game.prefs.bytePrefs[5] = 1                   // 1003072c..10030734
                        game.messages.post(text: game.assets.gameStrings[17], kind: .normal)   // 1003073c..10030754
                    }
                }
            }
        }
        c.windowFrames = 0                                            // 1003075c..10030760
        c.fpsWindowStart = ticks                                      // 10030764..1003076c
    }

    /// `FUN_10030bc0` step 1's FPS counter (`10030bf4..10030c90`): byte pref 9 → `"%i"` of +0x24, format 39 when
    /// +0x24 ≥ fctiwz(flli 32) (`cmpw; blt`) else 40, +0x110 = 0, layer 15; nil when pref 9 is off.
    public static func fpsCounterRequest(controller c: FrameController, prefs: DeimosPrefs,
                                         formats: [TextFormat]) -> TextRequest? {
        guard prefs.bytePrefs[9] != 0 else { return nil }
        var t = TextRequest(format: formats[c.fpsShown < c.fpsMaxRate ? 40 : 39], text: String(c.fpsShown))
        t.drawNow = false                                             // 10030c80 (+0x110)
        t.layer = 15                                                  // 10030c88 (+0x10c)
        return t
    }
}
