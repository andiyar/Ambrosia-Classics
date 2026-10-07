import Foundation
import HectorResources

/// G_Console.cc — the `~` console (messages-notices-console §5, HIGH). ★ LOCKED name (plan S2). Session state,
/// not simulation state (it lives beside the frame controller, C18a): it counts **presented frames** (`fc+0x8`
/// from begin frame, `100303a0`/`100303c4`) and acts on the game through `GameState` (prefs, messages, cues,
/// flags, players). The game keeps ticking while it is open; only the player input read is withheld
/// (`10030534`, `FrameKeysResult.inputWithheld`).
///
/// Listing reads for plan C19 (`disasm-review3-all.txt`; globals r2 = `0x100e6330`):
/// - `FUN_1002d040(t)` (`1002d040..1002d07c`): reset = lastKey −0x614c = t, open −0x613f = 0, draw flag −0x6140 = 0,
///   fade −0x6148 = 0, the 32-byte line `r2+0x46d0` zeroed. (⚑ the bank's "reset also sets the draw flag" — the
///   listing stores 0.)
/// - `FUN_1002d080` (`1002d080..1002d184`): a debug-only registration (r7 ≠ 0) creates nothing; else name ≤ 31,
///   uppercased (`FUN_100463b0`), +0x128 result sound (r6), +0x129 hidden (r8), appended. The ten r7 = 0 sites
///   of `FUN_100051a0` (`1000527c`, `100052dc`, `100052fc`, `10005434..100054f4`; names from the data image at
///   r2 − 0x2634 + 0x4a / 0xf7 / 0x123 / 0x2c2 … 0x38a, the cheat word from + 0x29c) are `commands`.
/// - `FUN_1002d1a0(frame)` (`1002d1a0..1002d228`): FlushEvents, gaso 1 via `FUN_10047670(id, 0x32, 100, 1)`,
///   lastKey = frame, open = draw flag = 1, fade = 0, line zeroed, the InputSprocket suspend (host).
/// - `FUN_1002d230(frame)` (`1002d230..1002d400`): open only. expired = frame > lastKey + `FUN_1004d5c0(flli 22)`
///   (`cmplw`); one `GetOSEvent` (keyDown only); no key and not expired → return. lastKey = frame; len = strlen;
///   len ≥ 30 (`cmplwi`) or expired → key = 0x0A. 0x1E: last line empty → return, else `strcpy(line, last)`
///   (bytes past its NUL are kept — an original quirk, kept), then return. 0x0A/0x0D → open = 0, execute, the
///   InputSprocket resume (host). 0x08: len > 1 → line[len − 1] = 0; len 1 → line[0] = 0. 0x60/0x7E → draw flag
///   = 1. Anything else (incl. the signed-negative high bytes) → line[len] = key.
/// - `FUN_1002d770(line)` (`1002d770..1002d940`): strlen ≤ 0 → nothing. The name = the first min(len, 31) bytes up
///   to the first byte whose MSL ctype (`*(r2 − 0x78e8)` = `0x100f0f94`) has bit 0x2 or 0x4 (0x09–0x0D, 0x20,
///   0xCA), uppercased; exact match over the list. None → `Unknown Command` (type 1), no sound, the last line
///   NOT saved. Found → handler(whole line); last line = line; +0x128 → gaso 4 if the handler's byte ≠ 0 else
///   gaso 5, both `(0x32, 100, 1)`.
/// - `FUN_1002d410` (`1002d410..1002d5c8`), every end frame: draw flag 0 → nothing. The prompt = `stli inte`
///   line 16 (`FUN_10002e50('inte', 0x10, buf, 8)`, loaded once). Closed: fade < 32 − (rate − 1) (`cmplw`) → fade
///   += rate (flli 23 = 4); ≥ 32 → draw flag 0, fade 32. Still drawn: format 33 with the prompt, +0x114 = fade,
///   +0x110 = 0, +0x138 += fade and +0x12c = 0 when that is > 32, layer 15; then, if the line is non-empty,
///   format 34 with the line, +0x114 = fade, +0x110 = 0, layer 15.
public struct Console: Equatable, Sendable {
    /// The nine handlers of the ten registered commands (TOC slot → TV → code, data image).
    public enum Handler: Equatable, Sendable {
        /// `0x10007eb0` FPS.
        case fps
        /// `0x10008660` VERSION / VERS.
        case version
        /// `0x10008990` the cheat word.
        case cheatWord
        /// `0x100089f0` `0x10008b80` `0x10008c90` `0x10008df0` `0x10008f60` `0x100090d0`.
        case life, accuracy, funds, score, shields, mult
    }

    /// One 300-byte command record (§5.2) as far as play reads it (+0x28 help is HELP's — unreachable).
    public struct Command: Equatable, Sendable {
        /// +0x08, uppercased.
        public var name: [UInt8]
        public var handler: Handler
        /// +0x128: play gaso 4 / 5 on the handler's result.
        public var resultSound: Bool
        /// +0x129: hidden from HELP.
        public var hidden: Bool
    }

    /// The obfuscated cheat word at r2 − 0x2634 + 0x29c (`c8 a8 f8 a9 d8 29 a8 19 49 69`).
    static let cheatWordData: [UInt8] = [0xc8, 0xa8, 0xf8, 0xa9, 0xd8, 0x29, 0xa8, 0x19, 0x49, 0x69]

    /// `FUN_10046470` over the cheat word: per byte rotate the nibbles, then invert → `supermunki`.
    public static let cheatWord: [UInt8] = cheatWordData.map { ~(($0 >> 4) | ($0 << 4)) }

    /// The registration order of `FUN_100051a0` with r7 = 0 (`1000527c` … `100054f4`).
    public static let registered: [Command] = {
        func c(_ n: String, _ h: Handler, _ s: Bool, _ hid: Bool) -> Command {
            Command(name: Array(n.utf8), handler: h, resultSound: s, hidden: hid)
        }
        return [c("FPS", .fps, true, false), c("VERSION", .version, true, false), c("VERS", .version, true, false),
                Command(name: cheatWord.map { MessageQueue.toUpper[$0] ?? $0 }, handler: .cheatWord,
                        resultSound: true, hidden: true),
                c("LIFE", .life, false, true), c("ACCURACY", .accuracy, false, true), c("FUNDS", .funds, false, true),
                c("SCORE", .score, false, true), c("SHIELDS", .shields, false, true), c("MULT", .mult, false, true)]
    }()

    /// The console's command list `_DAT_100e01ec`.
    public let commands: [Command]
    /// −0x613f: open (typing).
    public private(set) var isOpen = false
    /// −0x6140: the draw/redraw flag — drawn while set; cleared when the fade-out ends.
    public private(set) var visible = false
    /// −0x6148: 0 opaque … 32 gone.
    public private(set) var fade: UInt32 = 0
    /// −0x614c: the frame of the last key (or of the open / reset).
    public private(set) var lastKey: UInt32 = 0
    /// `r2+0x46d0`: the 32-byte line buffer.
    public private(set) var buffer = [UInt8](repeating: 0, count: 32)
    /// `r2+0x46f0`: the last executed (known) command line, 32 bytes.
    public private(set) var lastBuffer = [UInt8](repeating: 0, count: 32)
    /// The OS keyDown queue `GetOSEvent` reads one event from per frame (fed from `HeldKeys.typed`).
    public private(set) var events: [UInt8] = []
    /// `stli inte` line 16 (≤ 7 bytes): `>`.
    public let prompt: [UInt8]
    /// `FUN_1004d5c0(flli 22)` (`Console_ExpireTime`, 120).
    public let expireTime: UInt32
    /// fctiwz(flli 23) (`Console_FadeOutRate`, 4).
    public let fadeRate: Int32

    /// The charCode table `FUN_1002d230` switches on (`1002d2e0..1002d350`): Mac `GetOSEvent` keyDown charCodes,
    /// no auto-repeat. These are the codes `HeldKeys.typed` must carry (A3 maps the host's keys onto them; this
    /// file pins them — HeldKeys' "C19 pins the codes").
    public static let upArrow: UInt8 = 0x1e
    public static let backspace: UInt8 = 0x08
    public static let returnKey: UInt8 = 0x0d
    public static let lineFeed: UInt8 = 0x0a
    public static let graveKey: UInt8 = 0x60
    public static let tildeKey: UInt8 = 0x7e
    /// The 30-char cap (`1002d2bc cmplwi r31,0x1e`).
    public static let maxLength = 30

    /// Format indices of the prompt and the typed text.
    public static let promptFormat = 33
    public static let textFormat = 34

    public init(assets: DeimosAssets) throws {
        commands = Self.registered
        guard let r = assets.index.record(type: FourCC("stli")!, id: FourCC("inte")!) else {
            throw DeimosAssetsError.missingTag(type: "stli", id: "inte")
        }
        let lines = StringList(data: try assets.index.data(for: r)).lines
        prompt = lines.indices.contains(16) ? Array(lines[16].prefix(7)) : []
        expireTime = UInt32(max(0, EntityDraw.fctiwz(assets.floats[22])))
        fadeRate = EntityDraw.fctiwz(assets.floats[23])
    }

    /// The line as typed (`strlen`).
    public var text: [UInt8] { Self.cString(buffer) }
    /// The last line (`strlen`).
    public var lastLine: [UInt8] { Self.cString(lastBuffer) }

    static func cString(_ b: [UInt8]) -> [UInt8] { Array(b.prefix { $0 != 0 }) }

    /// `FUN_1002d040(t)`.
    public mutating func reset(frame t: UInt32) {
        lastKey = t
        isOpen = false
        visible = false
        fade = 0
        buffer = [UInt8](repeating: 0, count: 32)
    }

    /// FlushEvents (`FUN_10048e30`) — the pause screen and the session start/end call it too.
    public mutating func flushEvents() { events = [] }

    /// `FUN_1002d1a0(frame)`.
    public mutating func open(frame: UInt32, game: inout GameState) {
        flushEvents()                                                        // 1002d1b4
        game.cues.sounds.append(SoundPlay.perm(game.assets.sounds[1], priority: 0x32, volume: 100,
                                               allowMultiple: true))         // 1002d1bc..1002d1d4
        lastKey = frame                                                      // 1002d1e0
        isOpen = true                                                        // 1002d1ec
        visible = true                                                       // 1002d1f4
        fade = 0                                                             // 1002d1f8
        buffer = [UInt8](repeating: 0, count: 32)                            // 1002d1fc
    }

    /// `FUN_1002d230(frame)` — once per frame; `typed` (this pass's keyDowns) joins the event queue first.
    public mutating func update(frame: UInt32, typed: [UInt8], game: inout GameState) {
        guard isOpen else { return }                                         // 1002d258..1002d260
        events += typed
        let expired = frame > lastKey &+ expireTime                          // 1002d268..1002d288
        var key: UInt8 = 0
        let got = !events.isEmpty                                            // 1002d290 GetOSEvent == 2
        if got { key = events.removeFirst() }
        guard got || expired else { return }                                 // 1002d298..1002d2a4
        lastKey = frame                                                      // 1002d2a8
        let len = text.count                                                 // 1002d2b0 strlen
        if len >= Self.maxLength { key = Self.lineFeed }                     // 1002d2bc..1002d2c8
        if expired { key = Self.lineFeed }                                   // 1002d2cc..1002d2d8
        switch key {
        case Self.upArrow:                                                   // 1002d2e0..1002d2fc, 1002d30c
            guard lastBuffer[0] != 0 else { return }
            let src = lastLine
            for (i, b) in src.enumerated() { buffer[i] = b }                 // strcpy: the NUL, not the tail
            buffer[src.count] = 0
        case Self.lineFeed, Self.returnKey:                                  // 1002d38c..1002d3dc
            isOpen = false
            execute(text, game: &game)
        case Self.backspace:                                                 // 1002d360..1002d388
            if len > 1 { buffer[len - 1] = 0 } else if len > 0 { buffer[0] = 0 }
        case Self.graveKey, Self.tildeKey:                                   // 1002d354..1002d358
            visible = true
        default:
            buffer[len] = key                                                // 1002d3e0 stbx
        }
    }

    /// MSL ctype bits 0x2 | 0x4 of the shipped table `0x100f0f94` (data image): 0x09–0x0D, 0x20, 0xCA.
    static func isSeparator(_ b: UInt8) -> Bool { (0x09...0x0d).contains(b) || b == 0x20 || b == 0xca }

    /// `FUN_1002d770(line)`.
    public mutating func execute(_ line: [UInt8], game: inout GameState) {
        let line = Self.cString(line)
        guard !line.isEmpty else { return }                                  // 1002d788..1002d794
        let n = min(line.count, 31)                                          // 1002d798..1002d7a0
        let nameLength = line.prefix(n).firstIndex(where: Self.isSeparator) ?? n   // 1002d7c0..1002d7e0
        let name = line.prefix(nameLength).map { MessageQueue.toUpper[$0] ?? $0 }  // 1002d7e4..1002d80c
        guard let command = commands.first(where: { $0.name == name }) else {     // 1002d814..1002d888
            game.messages.post(text: "Unknown Command", kind: .error)        // 1002d894..1002d8a8
            return
        }
        let ok = game.consoleCommand(command.handler)                        // 1002d8b4..1002d8bc
        lastBuffer = [UInt8](repeating: 0, count: 32)                        // 1002d8c8..1002d8d0 strcpy
        for (i, b) in line.prefix(31).enumerated() { lastBuffer[i] = b }
        guard command.resultSound else { return }                            // 1002d8d8..1002d8e0
        let id = game.assets.sounds[ok ? 4 : 5]                              // 1002d8e4..1002d928
        game.cues.sounds.append(SoundPlay.perm(id, priority: 0x32, volume: 100, allowMultiple: true))
    }

    /// `FUN_1002d410`'s text records (prompt, then the line if non-empty), advancing the fade-out — call it
    /// exactly once per end frame.
    public mutating func drawRequests(formats: [TextFormat]) -> [TextRequest] {
        guard visible else { return [] }                                     // 1002d434..1002d43c
        if !isOpen {                                                         // 1002d494..1002d4d8
            if fade < UInt32(bitPattern: 32 &- (fadeRate &- 1)) {
                fade = fade &+ UInt32(bitPattern: fadeRate)
                if fade >= 32 { visible = false; fade = 32 }
            }
        }
        guard visible else { return [] }                                     // 1002d4dc..1002d4e4
        let blend = Int32(bitPattern: fade)
        var p = TextRequest(format: formats[Self.promptFormat], text: prompt)   // 1002d500..1002d514
        p.format.blendAmount = blend                                         // 1002d528 (+0x114)
        p.drawNow = false                                                    // 1002d534 (+0x110)
        let strip = p.format.colorStripBlendAmount &+ blend                  // 1002d524..1002d538 (+0x138)
        p.format.colorStripBlendAmount = strip
        if UInt32(bitPattern: strip) > 32 { p.format.colorStripDo = false }  // 1002d53c..1002d540 (+0x12c)
        p.layer = 15                                                         // 1002d544..1002d548
        var out = [p]
        let line = text
        if !line.isEmpty {                                                   // 1002d55c..1002d564
            var t = TextRequest(format: formats[Self.textFormat], text: line)   // 1002d568..1002d588
            t.format.blendAmount = blend                                     // 1002d584
            t.drawNow = false                                                // 1002d598
            t.layer = 15                                                     // 1002d5a0
            out.append(t)
        }
        return out
    }

    /// `FUN_1002d410` — the console's draw commands this end frame (strip, then glyphs, per record).
    public mutating func drawCommands(text layout: TextLayout, formats: [TextFormat]) -> [DrawCommand] {
        drawRequests(formats: formats).flatMap { layout.draw($0) }
    }
}
