import Foundation
import HectorResources

/// The single centred notice slot `N` = `*(r2 − 0x71d0)` (messages-notices-console §4, HIGH). ★ LOCKED name
/// (plan S2). Notices count **logic ticks**: `tick(gameTime:)` is `FUN_10018320(G+0x1c)` from `FUN_10006b50`
/// (`10006bcc`), and the draw `FUN_100184b0` runs in the world draw. A post replaces the current notice; there
/// is no queue. In shipped 1.0.6 the only text notice is the Caps Lock pause notice (§4.4).
///
/// Listing reads for plan C16 (`disasm-review3-all.txt`):
/// - `FUN_10018130` (`10018130..100181dc`): reset = flags 0, alpha 32, start 0, last tick 0, text "", delay 0,
///   sound {`none`, 100, 100, 100, 1.0, 1.0} (`0x100d6cc4`), alignment `CEGA`.
/// - `FUN_100181e0(rec, now)` (`100181e0..1001831c`): clear (`rec` or its text NULL) → only when active and not
///   hold: fading in → active = 0 at once (`10018230`); else fading-out = 1 unless already set. Post → ignored
///   while hold; active = 1, hold = rec+4, start = now, text ≤ 63 (`FUN_10046510(+0xc, s, 0x3f)`), delay,
///   sound, alignment; fade-in (rec+5) → alpha 32, fading-in 1, fading-out 0; else alpha 0, both 0.
/// - `FUN_10018320(now)` (`10018320..100184ac`): `now > last` (signed) else return; last = now (before the
///   active test); inactive → return. Delay == 0 → start = now, sound `FUN_100475e0(&N+0x50, 1)` unless `none`.
///   Delay −= 1; delay > 0 → return. Not hold and `now > start + fctiwz(flli 71)` → Clear. Fading in: alpha <
///   fctiwz(flli 72) (`cmplw`) → alpha 0, fading-in = fading-out = 0; else alpha −= 2. Fading out: alpha +=
///   fctiwz(flli 73); `≥ 32` (`cmplwi`) → alpha 32, active 0 (fading-out stays set).
///   Note: with a delay > 0 the tick on which the delay reaches 0 is already drawable (`delay < 1`) but the
///   start reset and the sound come one tick later (when the decremented delay is read back as 0) — dead in
///   shipped data (no `entryNotice_STR`), transcribed as read.
/// - `FUN_100184b0` (`100184b0..10018574`): active, text non-empty, delay ≤ 0 (`cmpwi; bgt`) → format 49
///   (`FUN_1000d130(0x31)`), text, BlendAmount (+0x114) = alpha, +0x110 = 0, +0x10d = 1, strip blend (+0x138)
///   += alpha and the strip off when > 32 (`cmplwi; ble`), alignment (+0x108) = N+0x68, layer (+0x10c) = 15;
///   `FUN_1000d380(buf, 0)`.
public struct NoticeSlot: Equatable, Sendable {
    /// The 0x28-byte post record (§4.1): +0 text (nil = clear), +4 hold, +5 fade-in, +8 delay, +0xc…+0x20
    /// sound, +0x24 alignment.
    public struct Post: Equatable, Sendable {
        public var text: [UInt8]
        public var hold: Bool
        public var fadeIn: Bool
        public var delay: Int32
        public var sound: SoundRecord
        public var alignment: TextFormat.Alignment

        public init(text: [UInt8], hold: Bool, fadeIn: Bool, delay: Int32, sound: SoundRecord,
                    alignment: TextFormat.Alignment) {
            self.text = text
            self.hold = hold
            self.fadeIn = fadeIn
            self.delay = delay
            self.sound = sound
            self.alignment = alignment
        }

        /// The Caps Lock pause notice `FUN_10030360` posts (`10030420..100304dc`): the template `0x100eb1cc`
        /// (hold 0, fade-in 1, delay 0, sound `none` block from `0x100d70f4` by the static initialiser,
        /// alignment `CEGA`) with text = GameString 0 and fade-in forced off (`10030490`); alignment `CEBU` when
        /// `fc+4` == 0, `CEGA` when 1, the template's `CEGA` otherwise (`10030494..100304c8`).
        public static func pressCapsLock(text: [UInt8], controllerMode fc4: UInt8) -> Post {
            Post(text: text, hold: false, fadeIn: false, delay: 0, sound: SoundRecord(),
                 alignment: fc4 == 0 ? .centerInBuffer : .centerInGameArea)
        }
    }

    /// +0, +1, +2, +3.
    public private(set) var active = false
    public private(set) var hold = false
    public private(set) var fadingIn = false
    public private(set) var fadingOut = false
    /// +4: 0 opaque … 32 invisible.
    public private(set) var alpha: Int32 = 32
    /// +8: game time.
    public private(set) var start: Int32 = 0
    /// +0xc: ≤ 63 bytes.
    public private(set) var text: [UInt8] = []
    /// +0x4c: ticks before showing.
    public private(set) var delay: Int32 = 0
    /// +0x50…+0x64.
    public private(set) var sound = SoundRecord()
    /// +0x68.
    public private(set) var alignment: TextFormat.Alignment = .centerInGameArea
    /// `_DAT_100e015c`: the last game time ticked.
    public private(set) var lastTick: Int32 = 0
    /// flli 71 `Notice_AppearanceGameTime` (60), 72 fade-in step (2), 73 fade-out step (4), via `fctiwz`.
    public let appearance: Int32
    public let fadeInStep: Int32
    public let fadeOutStep: Int32

    /// The `idli Formats` line of `gano` Game_Notice.
    public static let formatIndex = 49

    public init(floats: [Float]) {
        appearance = EntityDraw.fctiwz(floats[71])
        fadeInStep = EntityDraw.fctiwz(floats[72])
        fadeOutStep = EntityDraw.fctiwz(floats[73])
    }

    /// `FUN_10018130` (level start, level select).
    public mutating func reset() {
        active = false; hold = false; fadingIn = false; fadingOut = false
        alpha = 32; lastTick = 0; start = 0; text = []; delay = 0
        sound = SoundRecord(); alignment = .centerInGameArea
    }

    /// `FUN_100181e0(rec, now)`: post, or clear when `post` is nil (`rec` or its text pointer NULL; an empty
    /// non-NULL text posts, and the draw then skips it).
    public mutating func post(_ post: Post?, now: Int32) {
        guard let post else {                           // 100181fc..10018208
            guard active, !hold else { return }                             // 1001820c..10018220
            if fadingIn { active = false }                                  // 10018224..10018234
            else if !fadingOut { fadingOut = true }                         // 1001823c..10018250
            return
        }
        guard !hold else { return }                                         // 1001825c
        active = true
        hold = post.hold
        start = now
        text = Array(post.text.prefix { $0 != 0 }.prefix(0x3f))             // 10018288
        delay = post.delay
        sound = post.sound
        alignment = post.alignment
        if post.fadeIn {                                                    // 100182d0..100182f0
            alpha = 32; fadingIn = true; fadingOut = false
        } else {                                                            // 100182f8..10018304
            alpha = 0; fadingIn = false; fadingOut = false
        }
    }

    /// `FUN_10018320(gameTime)` — once per new game time.
    public mutating func tick(gameTime now: Int32, rng: inout MSLRandom, cues: inout CueBuffer) {
        guard now > lastTick else { return }                                // 10018344 cmpw; ble
        lastTick = now                                                      // 10018350
        guard active else { return }                                        // 10018358
        if delay == 0 {                                                     // 10018360..10018388
            start = now
            if let cue = SoundPlay.record(sound, allowMultiple: true, rng: &rng) { cues.sounds.append(cue) }
        }
        delay = delay &- 1                                                  // 10018394
        guard delay <= 0 else { return }                                    // 100183a0 cmpwi; bgt
        if !hold, now > start &+ appearance {                               // 100183a8..100183d8
            post(nil, now: now)                                             // 100183dc..100183ec
        }
        if fadingIn {                                                       // 100183f4..10018440
            if UInt32(bitPattern: alpha) < UInt32(bitPattern: fadeInStep) {
                alpha = 0; fadingIn = false; fadingOut = false
            } else {
                alpha = alpha &- fadeInStep
            }
        }
        if fadingOut {                                                      // 10018444..10018490
            alpha = alpha &+ fadeOutStep
            if UInt32(bitPattern: alpha) >= 32 { alpha = 32; active = false }
        }
    }

    /// `FUN_100184b0`'s text record, or nil when nothing is drawn.
    public func drawRequest(formats: [TextFormat]) -> TextRequest? {
        guard active, !text.isEmpty, delay <= 0 else { return nil }         // 100184c8..100184ec
        var t = TextRequest(format: formats[Self.formatIndex], text: text)
        t.format.blendAmount = alpha                                        // 10018520 (+0x114)
        t.drawNow = false                                                   // 1001852c (+0x110)
        t.keepTemplateClip = true                                           // 10018530 (+0x10d)
        let strip = t.format.colorStripBlendAmount &+ alpha                 // 10018518..10018534 (+0x138)
        t.format.colorStripBlendAmount = strip
        if UInt32(bitPattern: strip) > 32 { t.format.colorStripDo = false } // 10018528..1001853c (+0x12c)
        t.format.format = alignment                                         // 10018554 (+0x108)
        t.layer = 15                                                        // 10018548 (+0x10c)
        return t
    }

    /// `FUN_100184b0` — the world draw's notice: strip, then glyphs (`FUN_1000d380`).
    public func drawCommands(text layout: TextLayout, formats: [TextFormat]) -> [DrawCommand] {
        drawRequest(formats: formats).map { layout.draw($0) } ?? []
    }
}
