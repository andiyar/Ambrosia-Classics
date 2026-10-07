import Foundation
import HectorResources

/// G_Message.cc — the in-game message list (messages-notices-console §2, HIGH). ★ LOCKED name (plan S2).
/// Messages count **presented frames**: `age(frame:)` is called once per begin frame with the frame-controller
/// counter `fc+0x8` (`100303d0`), and the post time is the clock of the last aging call. Drawn every end frame
/// (`1002dea0`) on top of everything.
///
/// Listing reads for plan C16 (`disasm-review3-all.txt`):
/// - `FUN_1002db50` (`1002db50..1002dbc4`): reset = free the list, new list, clock 0.
/// - `FUN_1002dbd0` (`1002dbd0..1002dd88`): (the module flag is always on here); a non-zero readout searches
///   the list for `+0x50 == readout` and clears that entry's sticky byte, then returns (`1002dc40..1002dc68`);
///   empty text → nothing (`1002dc7c`); `count ≥ fctiwz(flli 24)` (signed, sticky entries counted) → the new
///   message is dropped (`1002dc88..1002dca4`); record: post = clock, fade 0, text ≤ 63 chars
///   (`FUN_10046510(+0xc, s, 0x3f)` = strncpy + NUL at 63), +0x4c upper, +0x54 type, +0x50 readout, sticky =
///   readout ≠ 0; upper → `FUN_100463b0` (`100463b0..10046404`: per byte, class table `*(r2 − 0x78e8)` =
///   `0x100f0f94` bit 0x40 → map `*(r2 − 0x78c4)` = `0x100f1194`; the shipped MSL Mac Roman tables, read from
///   the data image — `toUpper` below); sticky → prepend (`FUN_10000910`), else append (`FUN_100009e0`).
/// - `FUN_1002dd90` (`1002dd90..1002de9c`): clock = frame (stored first, even with an empty list); for i in
///   0..<count (count read once), sticky skipped: `clock > post + fctiwz(flli 25)` (`cmplw`, unsigned) → fade +=
///   fctiwz(flli 26); `fade ≥ 32` (`cmplwi`) → unlink + free and **return** (one deletion per frame).
/// - `FUN_1002dea0` (`1002dea0..1002e18c`): gap = fctiwz(flli 27). Pass 1, sticky entries in list order, k = 0,
///   1, …: text `"%s%i"` (label, readout()), Loc_Y += k·gap. Pass 2, normal entries, j counted over the normal
///   entries only (`1002e134`): Loc_Y += gap·(count − j − 1) with count = all entries (`1002e110..1002e11c`).
///   Per entry: format 35/36/37 by type (`FUN_1000d130`), type ≥ 3 aborts the whole draw (unreachable here —
///   `Kind` has three cases); +0x10d = 1, +0x110 = 0, BlendAmount (+0x114) = fade, strip blend (+0x138) =
///   fade + 16 and the strip off (+0x12c = 0) when that is > 32 (`cmplwi; ble`), layer +0x10c = 15; then
///   `FUN_1000d380(buf, 0)`.
public struct MessageQueue: Equatable, Sendable {
    /// +0x54: 0 normal (`meno`), 1 error (`meer`), 2 status (`mest`).
    public enum Kind: UInt8, Equatable, Sendable {
        case normal = 0, error = 1, status = 2

        /// The `idli Formats` line drawn for this type (`1002df9c..1002dfc8`).
        public var formatIndex: Int { 35 + Int(rawValue) }
    }

    /// One 0x58-byte record (§2.1).
    public struct Message: Equatable, Sendable {
        /// +0x04: the message clock at the post.
        public var postTime: UInt32
        /// +0x08: 0 opaque … 32 gone.
        public var fade: Int32
        /// +0x0c: the text (Mac Roman, ≤ 63 bytes).
        public var text: [UInt8]
        /// +0x4c.
        public var uppercase: Bool
        /// +0x4d: a sticky readout line (drawn first, never aged).
        public var sticky: Bool
        /// +0x50: the readout TV — an opaque token here (0 = none); only debug-only commands post one (§5.5).
        public var readout: UInt32
        /// +0x54.
        public var kind: Kind
    }

    /// `FUN_100463b0`'s effective map: every byte whose class entry (`0x100f0f94`) has bit 0x40 and whose map
    /// entry (`0x100f1194`) differs (58 class-0x40 bytes; 0xa7, 0xde, 0xdf map to themselves). Data image
    /// `mem/100de330.bin`, r2 = `0x100e6330`.
    static let toUpper: [UInt8: UInt8] = {
        var m: [UInt8: UInt8] = [:]
        for c in UInt8(0x61)...0x7a { m[c] = c - 0x20 }
        let high: [(UInt8, UInt8)] = [
            (0x87, 0xe7), (0x88, 0xcb), (0x89, 0xe5), (0x8a, 0x80), (0x8b, 0xcc), (0x8c, 0x81), (0x8d, 0x82),
            (0x8e, 0x83), (0x8f, 0xe9), (0x90, 0xe6), (0x91, 0xe8), (0x92, 0xea), (0x93, 0xed), (0x94, 0xeb),
            (0x95, 0xec), (0x96, 0x84), (0x97, 0xee), (0x98, 0xf1), (0x99, 0xef), (0x9a, 0x85), (0x9b, 0xcd),
            (0x9c, 0xf2), (0x9d, 0xf4), (0x9e, 0xf3), (0x9f, 0x86), (0xbe, 0xae), (0xbf, 0xaf), (0xcf, 0xce),
            (0xd8, 0xd9),
        ]
        for (l, u) in high { m[l] = u }
        return m
    }()

    /// The list in order: sticky entries at the head, then the normal entries oldest first.
    public private(set) var messages: [Message] = []
    /// `_DAT_100e01f4`: the frame passed to the last aging call.
    public private(set) var clock: UInt32 = 0
    /// flli 24 `Message_MaxNum` (20), 25 `Message_Duration` (60), 26 `Message_FadeOutRate` (1), 27
    /// `Message_VerticalGap` (20), each through `fctiwz`.
    public let maxCount: Int32
    public let duration: UInt32
    public let fadeRate: Int32
    public let gap: Int32

    public init(floats: [Float]) {
        maxCount = EntityDraw.fctiwz(floats[24])
        duration = UInt32(bitPattern: EntityDraw.fctiwz(floats[25]))
        fadeRate = EntityDraw.fctiwz(floats[26])
        gap = EntityDraw.fctiwz(floats[27])
    }

    /// `FUN_1002db50`: empty list, clock 0 (level start, frame-controller init/reset).
    public mutating func reset() {
        messages = []
        clock = 0
    }

    /// `FUN_1002dbd0(text, type, upper, readout)`.
    public mutating func post(text: [UInt8], kind: Kind, uppercase: Bool = false, readout: UInt32 = 0) {
        if readout != 0, let i = messages.firstIndex(where: { $0.readout == readout }) {
            messages[i].sticky = false                                       // 1002dc60
            return
        }
        let s = Array(text.prefix { $0 != 0 })
        guard !s.isEmpty else { return }                                     // 1002dc7c
        guard Int32(messages.count) < maxCount else { return }               // 1002dca0 cmpw; bge
        var body = Array(s.prefix(0x3f))                                     // 1002dd04 FUN_10046510
        if uppercase {                                                       // 1002dd30..1002dd40
            body = body.map { Self.toUpper[$0] ?? $0 }
        }
        let m = Message(postTime: clock, fade: 0, text: body, uppercase: uppercase, sticky: readout != 0,
                        readout: readout, kind: kind)
        if m.sticky { messages.insert(m, at: 0) } else { messages.append(m) }   // 1002dd5c / 1002dd70
    }

    /// `post` with a Swift string (Mac Roman, lossy).
    public mutating func post(text: String, kind: Kind, uppercase: Bool = false, readout: UInt32 = 0) {
        post(text: MacRoman.encode(text, lossy: true) ?? [], kind: kind, uppercase: uppercase, readout: readout)
    }

    /// `FUN_1002dd90(frame)` — every begin frame.
    public mutating func age(frame: UInt32) {
        clock = frame                                                        // 1002dda0
        for i in messages.indices where !messages[i].sticky {                // 1002de1c..1002de24
            guard clock > messages[i].postTime &+ duration else { continue } // 1002de30 cmplw; ble
            messages[i].fade = messages[i].fade &+ fadeRate                  // 1002de40
            if UInt32(bitPattern: messages[i].fade) >= 32 {                  // 1002de4c cmplwi; blt
                messages.remove(at: i)                                       // 1002de60, 1002de74
                return                                                       // 1002de7c
            }
        }
    }

    /// `FUN_1002dea0`'s text records, in draw order (sticky lines, then the normal lines oldest first).
    /// `readoutValue` stands in for the readout TV call (`1002df54`).
    public func drawRequests(formats: [TextFormat], readoutValue: (UInt32) -> Int32 = { _ in 0 }) -> [TextRequest] {
        var out: [TextRequest] = []
        let count = Int32(messages.count)
        func request(_ m: Message, text: [UInt8], dy: Int32) -> TextRequest {
            var t = TextRequest(format: formats[m.kind.formatIndex], text: text)
            t.format.locY = t.format.locY &+ dy
            t.keepTemplateClip = true                                        // +0x10d = 1
            t.drawNow = false                                                // +0x110 = 0
            t.format.blendAmount = m.fade                                    // +0x114
            let strip = m.fade &+ 16                                         // +0x138
            t.format.colorStripBlendAmount = strip
            if UInt32(bitPattern: strip) > 32 { t.format.colorStripDo = false }   // +0x12c = 0
            t.layer = 15                                                     // +0x10c
            return t
        }
        var k: Int32 = 0
        for m in messages where m.sticky {                                   // 1002df00..1002e050
            let line = Array(m.text.prefix(0x7f)) + Array(String(readoutValue(m.readout)).utf8)   // "%s%i"
            out.append(request(m, text: line, dy: k &* gap))
            k += 1
        }
        var j: Int32 = 0
        for m in messages where !m.sticky {                                  // 1002e070..1002e178
            out.append(request(m, text: m.text, dy: gap &* (count &- j &- 1)))
            j += 1
        }
        return out
    }

    /// `FUN_1002dea0` — every end frame: each record through `FUN_1000d380` (strip, then glyphs).
    public func drawCommands(text: TextLayout, formats: [TextFormat],
                             readoutValue: (UInt32) -> Int32 = { _ in 0 }) -> [DrawCommand] {
        drawRequests(formats: formats, readoutValue: readoutValue).flatMap { text.draw($0) }
    }
}
