import Foundation
import HectorResources

/// The text measures the conversation's wrap and rows read (`CharWidth` / `CalcWrappedStringInBoxHeight` in Times (20)
/// 18 plain; conversations-mcnv §6). Render owns the font (C2: `TextRasterizer`); the App hands its measures to the
/// run (`LevelRun.conversationText`). The default measures nothing: every character 0 px wide (no line ever wraps)
/// and every response two 18-px lines tall.
public struct ConversationText: Sendable {
    /// `CharWidth(byte)` in Times 18.
    public var charWidth: @Sendable (UInt8) -> Int
    /// `.CalcWrappedStringInBoxHeight(text, 214 × 400)` (M l. 31656ff): TextEdit's (lines + 1) · line height.
    public var wrappedHeight: @Sendable ([UInt8]) -> Int

    public init(charWidth: @escaping @Sendable (UInt8) -> Int, wrappedHeight: @escaping @Sendable ([UInt8]) -> Int) {
        self.charWidth = charWidth
        self.wrappedHeight = wrappedHeight
    }

    public static let unmeasured = ConversationText(charWidth: { _ in 0 }, wrappedHeight: { _ in 2 * 0x12 })
}

/// `.Conversation @ 1007a7e8` / `.SimpleConv @ 10079a30` and their callees (`.HandleConvLine`, `.HandleLineResponses`,
/// `.HandleLineActions` — `ConvActions` —, `.DrawConvTextString`, `.DrawStringCharByChar`, `.CharByCharDelay`,
/// `.ConvPressAnyKeyDeadTime`; M l. 65440–66560; conversations-mcnv §3, §6) as a tick machine over the `Conversation`
/// parser (plan S2, C1; Invariant 3). Every busy-wait of the original (the 2-tick character delay, "press any key",
/// "all keys up", the menu's key wait) is a state the run stays in until the polled input lets it go on; the game is
/// frozen meanwhile (the frame is suspended, Invariant 6). The draws are the original's calls: `copyPicture` for the
/// frame / portrait / erase copies, one `drawText` per `DrawChar` of the typer, one per wrapped response chunk, the
/// name's `DrawString`, and `restoreView` (`_WrapCopyToScreen`) at the end. Text layout positions use
/// `ConversationText`; the pixels are C2's.
///
/// **`.Conversation(id, recIdx, sprite)`:** the talker kept for action 9; id negated if negative; the abort flag
/// `*0x100a0c14` cleared; `Mcnv` id loaded (`.OpenDefaultWorldConv`) — missing → `.ReportError("Error attempting to
/// load the conversation resource!", id)` (the string at `0x100a6cfc`) and the end; `.DrawConvPic(line #1's portrait)`
/// into the frame GWorld, `.CopyConvToScreen` (PICT 4000's GWorld, mode 0x24), `.DrawConvPicToScreen(line #1's
/// portrait)`; index = 19 (line #20, the entry node); `while index < 20 ∧ ¬abort: .HandleConvLine`. The end:
/// `.EraseConvNameAndText`, the 10 trail slots reset, all keys up, `DrawBlackLines` (graphics mode 3), the game view
/// redrawn (`restoreView`).
///
/// **`.HandleConvLine`:** Escape (0x35) → index 21 + abort. A negative index → negated, nothing displayed. Else index
/// 1…19 with a portrait → portrait + erase (index 0 does neither: `.Conversation` drew line #1's already); a portrait ≠
/// 0 → the name, the text typed; Escape → index 21 + abort, return; all keys up; press any key (Escape there sets the
/// abort flag — the line's menu / actions still run, the menu's rows blank); all keys up. Then the menu
/// (`.HandleLineResponses`); with none, the condition / actions / next (`ConvActions`); Escape → index 21 + abort.
///
/// **The menu:** all keys up; response 0's target 0 → none. Else portrait **4001**, erase, name "Ferazel" (`0x100a6cc6`);
/// the row tops from origin.v + 0x2b by each targeted response's wrapped height; Escape → index 21 + abort; then from
/// selection 0: every targeted response in grey (0x5555 ×3, `0x100a6cc0`), the selection again in black; Escape → index
/// 21 + abort; all keys up; wait for input 3, 2, 6, 8, 7, 5, Return (0x24) or keypad Enter (0x4c); input 2 → up (> 0),
/// input 3 → down (when `sel < 5` and response sel + 1 has a target), anything else confirms; on confirm all keys up and
/// index = the converted target.
///
/// **Typing (`.DrawConvTextString(text, 0, 1)`):** a space appended (unless 255 long); per wrapped chunk (the running
/// `CharWidth` sum > 214 → break after the last space, which is dropped) `.DrawStringCharByChar(chunk, x 0x9a, baseline
/// 0x1d + 0xe + 18·line, delay 2)`; Escape after a chunk → abort; then the next line; after the last chunk the 10-space
/// pass with delay 0 (9 steps). Each step: the next byte into the last slot older than 9 (slot 0 if none) with age 0;
/// every slot drawn in grey (10 − age)·4000 when its byte is not a space and its age is odd; a slot older than 9 becomes
/// a space; every age + 1; then `.CharByCharDelay(delay, step start)` — until `delay` ticks have passed or any key is down
/// — the x advanced by the byte's width; Escape → abort.
///
/// **`.SimpleConv(pict, name, text)`:** abort cleared; `.DrawConvPic(pict)`, `.CopyConvToScreen` (no portrait copy to
/// the screen: its white is transparent), the name, the text typed; no Escape → all keys up, press any key; all keys up;
/// the slots reset; `DrawBlackLines` (mode 3); `restoreView`. No erase, no menu, no actions.
public final class ConversationRun {
    /// What the run is: `.Conversation(id, recIdx, sprite)` or `.SimpleConv(pict, name, text)`.
    public enum Kind: Equatable, Sendable {
        case conversation(id: Int16, record: Int, sprite: Int)
        case simple(pict: Int16, name: [UInt8], text: [UInt8])
    }

    /// What the run waits for (the original's busy-wait it is in).
    public enum Wait: Equatable, Sendable {
        /// A character's delay (`.CharByCharDelay`).
        case typing
        /// All keys up (`IsAnyInputKeyDown` / `IsAnyKeyDown` loops).
        case keysUp
        /// `.ConvPressAnyKeyDeadTime`: any key or the button.
        case anyKey
        /// The menu's key wait.
        case menuKey
        /// The load error's report.
        case dialog
        /// Returned.
        case done
    }

    // Geometry (`.InitConversation`, M l. 65470–65575): the origin `*0x100a0bfc` = (v 0x2e, h 0x7e); the portrait
    // rect (24, 49)–(120, 145); the frame 387 × 308.
    public static let originH = 0x7e
    public static let originV = 0x2e
    public static let framePict: Int16 = 4000
    public static let ferazelPortrait: Int16 = 0xfa1
    public static let ferazelName = "Ferazel"
    public static let loadError = "Error attempting to load the conversation resource!"
    static let portraitRect = Rect16(top: 0x31, left: 0x18, bottom: 0x91, right: 0x78)
    static let textErase = Rect16(top: 0x1d, left: 0x9a, bottom: 0xdd, right: 0x174)
    static let nameErase = Rect16(top: 0x104, left: 0x13, bottom: 300, right: 199)
    static let responseGrey = RGB16(red: 0x5555, green: 0x5555, blue: 0x5555)
    static let black = RGB16(red: 0, green: 0, blue: 0)

    public let kind: Kind
    /// Line numbers (1-based, the data's) whose text the run typed, in order.
    public private(set) var shown: [Int] = []
    /// `local_26[0]`: the line index (0…19; ≥ 20 ends).
    public private(set) var index: Int16 = 0x13
    /// `*0x100a0c14`.
    public private(set) var aborted = false
    /// The menu's selection (`sVar15`).
    public private(set) var selection = 0
    public private(set) var wait: Wait = .typing
    public var isDone: Bool { wait == .done }

    private let world: SpriteWorld
    private let resources: FerazelResources
    private let prefs: FerazelPrefs
    private let levelName: String
    private let text: ConversationText
    private var conv: Conversation?
    /// The typer's 10 trail slots (`*0x100a0c10`).
    private(set) var trail = [Slot](repeating: Slot(), count: 10)
    private var pc: PC = .begin
    private var dialogAnswered = false
    private var rowTops = [Int](repeating: 0, count: 6)

    /// One trail slot (`*0x100a0c10`, 8 bytes: char, x, y, age); `.InitConversation` / the resets: space, 0, 0, 10.
    struct Slot: Equatable {
        var char: UInt8 = 0x20
        var x = 0
        var y = 0
        var age: Int16 = 10
    }

    private enum PC {
        case begin, loadError, loopTest
        case lineType(Typer), lineUp1, lineAny, lineUp2
        case respUp, menuDraw, menuUp, menuKey, menuUpFinal, lineEscape
        case end, endUp
        case simpleType(Typer), simpleUp1, simpleAny, simpleUp2
        case finished
    }

    /// - Parameters:
    ///   - world: the suspended session's world (G, the live records, the talker).
    ///   - prefs: the live prefs (the input keys, graphics mode, sound).
    ///   - levelName: the status bar's (action 1's coin redraw).
    public init(_ kind: Kind, world: SpriteWorld, resources: FerazelResources, prefs: FerazelPrefs, levelName: String,
                text: ConversationText = .unmeasured) {
        self.kind = kind
        self.world = world
        self.resources = resources
        self.prefs = prefs
        self.levelName = levelName
        self.text = text
    }

    /// The load error's report was answered.
    public func dialogDone() { dialogAnswered = true }

    // MARK: Input (the polled `KeyState` of this tick)

    private func escape(_ i: FrontInput) -> Bool { i.keys.isPressed(0x35) }
    private func anyKey(_ i: FrontInput) -> Bool { ChapterScreenRun.isAnyKeyDown(i) }
    private func input(_ i: FrontInput, _ n: Int) -> Bool { InputActions(keys: i.keys, prefs: prefs).contains(.action(n)) }

    // MARK: The tick

    /// One tick at absolute 60 Hz `now` with this tick's polled input; `save` is the flow's save block (action 10).
    public func tick(now: UInt32, input i: FrontInput, save: inout SaveBlock) -> FrontOutput {
        var out = FrontOutput(present: true)
        while true {
            switch pc {
            case .finished:
                wait = .done
                return out
            case .begin:
                begin(now: now, out: &out)
            case .loadError:
                wait = .dialog
                guard dialogAnswered else { return out }
                pc = .end
            case .loopTest:
                guard index < 0x14 && !aborted else {
                    pc = .end
                    continue
                }
                lineStart(now: now, input: i, out: &out)
            case .lineType(var t):
                wait = .typing
                let finished = t.advance(now: now, input: i, run: self, out: &out)
                pc = .lineType(t)
                guard finished else { return out }
                if escape(i) {
                    abort()
                    pc = .loopTest
                } else {
                    pc = .lineUp1
                }
            case .lineUp1:
                wait = .keysUp
                guard !anyKey(i) else { return out }
                pc = .lineAny
            case .lineAny:
                wait = .anyKey
                let esc = escape(i)
                guard anyKey(i) || esc || i.button else { return out }
                if esc { aborted = true }
                pc = .lineUp2
            case .lineUp2:
                wait = .keysUp
                guard !anyKey(i) else { return out }
                pc = .respUp
            case .respUp:
                wait = .keysUp
                guard !anyKey(i) else { return out }
                menuStart(input: i, save: &save, out: &out)
            case .menuDraw:
                drawMenu(input: i, out: &out)
                if escape(i) {
                    abort()
                    pc = .lineEscape
                } else {
                    pc = .menuUp
                }
            case .menuUp:
                wait = .keysUp
                guard !anyKey(i) else { return out }
                pc = .menuKey
            case .menuKey:
                wait = .menuKey
                let keys = [3, 2, 6, 8, 7, 5].contains { input(i, $0) } || i.keys.isPressed(0x24) || i.keys.isPressed(0x4c)
                guard keys else { return out }
                if input(i, 2) {
                    if 0 < selection { selection -= 1 }
                    pc = .menuDraw
                } else if input(i, 3) {
                    if selection < 5 && target(line(index), selection + 1) != 0 { selection += 1 }
                    pc = .menuDraw
                } else {
                    pc = .menuUpFinal
                }
            case .menuUpFinal:
                wait = .keysUp
                guard !anyKey(i) else { return out }
                index = ConvActions.convert(target(line(index), selection))
                pc = .lineEscape
            case .lineEscape:
                if escape(i) { abort() }
                pc = .loopTest
            case .end:
                // `ForeColor(0x21)`, `.EraseConvNameAndText`, `.RestoreResWorldFile`, the slots reset.
                erase(&out)
                trail = [Slot](repeating: Slot(), count: 10)
                pc = .endUp
            case .endUp:
                wait = .keysUp
                guard !anyKey(i) else { return out }
                finish(&out)
            case .simpleType(var t):
                wait = .typing
                let finished = t.advance(now: now, input: i, run: self, out: &out)
                pc = .simpleType(t)
                guard finished else { return out }
                pc = escape(i) ? .simpleUp2 : .simpleUp1
            case .simpleUp1:
                wait = .keysUp
                guard !anyKey(i) else { return out }
                pc = .simpleAny
            case .simpleAny:
                wait = .anyKey
                let esc = escape(i)
                guard anyKey(i) || esc || i.button else { return out }
                if esc { aborted = true }
                pc = .simpleUp2
            case .simpleUp2:
                wait = .keysUp
                guard !anyKey(i) else { return out }
                trail = [Slot](repeating: Slot(), count: 10)
                finish(&out)
            }
        }
    }

    private func abort() {
        index = 0x15
        aborted = true
    }

    /// `DrawBlackLines` (graphics mode 3) and `_WrapCopyToScreen` of the game view.
    private func finish(_ out: inout FrontOutput) {
        if prefs.graphics == 3 { out.draws.append(.drawBlackLines) }
        out.draws.append(.restoreView)
        pc = .finished
    }

    private func begin(now: UInt32, out: inout FrontOutput) {
        aborted = false
        switch kind {
        case .conversation(let id, _, _):
            let n: Int16 = id < 0 ? 0 &- id : id
            guard let c = try? Conversation.load(from: resources, id: n) else {
                out.requests.append(.dialog(.error(text: Self.loadError, code: n)))
                pc = .loadError
                return
            }
            conv = c
            let pic = c.lines[0].portrait
            copyConvToScreen(pic, &out)
            portraitToScreen(pic, &out)
            index = 0x13
            pc = .loopTest
        case .simple(let pict, let name, let body):
            copyConvToScreen(pict, &out)
            drawName(name, &out)
            pc = .simpleType(Typer(body, param2: 0, text: text))
        }
    }

    /// `.HandleConvLine` up to its menu.
    private func lineStart(now: UInt32, input i: FrontInput, out: inout FrontOutput) {
        if escape(i) {
            abort()
            pc = .loopTest
            return
        }
        if index < 0 {
            index = 0 &- index
            pc = .respUp
            return
        }
        let l = line(index)
        if 0 < index && index < 0x14 && l.portrait != 0 {
            portraitToScreen(l.portrait, &out)
            erase(&out)
        }
        guard l.portrait != 0 else {
            pc = .respUp
            return
        }
        drawName(MacRoman.bytes(l.speaker), &out)
        shown.append(Int(index) + 1)
        pc = .lineType(Typer(MacRoman.bytes(l.text), param2: 0, text: text))
    }

    /// `.HandleLineResponses`' entry after its all-keys-up wait: no menu → the actions; else the header and the rows.
    private func menuStart(input i: FrontInput, save: inout SaveBlock, out: inout FrontOutput) {
        let l = line(index)
        guard target(l, 0) != 0 else {
            lineActions(save: &save, out: &out)
            pc = .lineEscape
            return
        }
        portraitToScreen(Self.ferazelPortrait, &out)
        erase(&out)
        drawName(MacRoman.bytes(Self.ferazelName), &out)
        var top = Self.originV + 0x2b
        for k in 0..<5 where target(l, k) != 0 {
            rowTops[k] = top
            top += text.wrappedHeight(response(l, k))
        }
        if escape(i) {
            abort()
            pc = .lineEscape
            return
        }
        selection = 0
        pc = .menuDraw
    }

    /// The menu's rows: every targeted response grey, then the selection black (`.DrawConvTextString(…, 0)`).
    private func drawMenu(input i: FrontInput, out: inout FrontOutput) {
        let l = line(index)
        let base = Self.originV + 0x2b
        for k in 0..<5 where target(l, k) != 0 {
            drawStatic(response(l, k), param2: rowTops[k] - base, rgb: Self.responseGrey, input: i, out: &out)
        }
        drawStatic(response(l, selection), param2: rowTops[selection] - base, rgb: Self.black, input: i, out: &out)
    }

    /// The condition, the actions and the next (`.HandleLineActions`, `ConvActions`).
    private func lineActions(save: inout SaveBlock, out: inout FrontOutput) {
        let l = line(index)
        var record = -1, talker: Int?
        if case .conversation(_, let r, let s) = kind {
            record = r
            talker = s
        }
        if l.conditionType != 0, ConvActions.condition(l, record: record, world: world) {
            index = ConvActions.convert(l.conditionTarget)
            return
        }
        for act in [l.action1, l.action2] {
            ConvActions.run(act, record: record, talker: talker, world: world, save: &save, prefs: prefs,
                            levelName: levelName, into: &out)
        }
        if l.next == 0 {
            index = index < 0x13 ? index + 1 : 0
        } else {
            index = ConvActions.convert(l.next)
        }
    }

    // MARK: The line record

    private static let emptyLine = Conversation.Line(
        text: "", speaker: "", responses: ["", "", "", "", ""], responseTargets: [0, 0, 0, 0, 0], portrait: 0,
        conditionType: 0, conditionA: 0, conditionB: 0, conditionTarget: 0,
        action1: Conversation.Action(type: 0, a: 0, b: 0), action2: Conversation.Action(type: 0, a: 0, b: 0), next: 0)

    /// Line `i`; outside 0…19 (the original reads past the 20 lines — no shipped target gets there) an empty line.
    private func line(_ i: Int16) -> Conversation.Line {
        guard let c = conv, (0..<Conversation.lineCount).contains(Int(i)) else { return Self.emptyLine }
        return c.lines[Int(i)]
    }

    /// Response slot k's target (`+0x800 + 2k`); slot 5 reads the next word, the portrait (`+0x80a`, the latent
    /// fifth-response case of §3.3).
    private func target(_ l: Conversation.Line, _ k: Int) -> Int16 { k < 5 ? l.responseTargets[k] : l.portrait }

    /// Response slot k's text (slot 5: the target words — latent, none shipped: empty).
    private func response(_ l: Conversation.Line, _ k: Int) -> [UInt8] { k < 5 ? MacRoman.bytes(l.responses[k]) : [] }

    // MARK: Draws

    private func offset(_ r: Rect16) -> Rect16 {
        Rect16(top: r.top + Int16(Self.originV), left: r.left + Int16(Self.originH),
               bottom: r.bottom + Int16(Self.originV), right: r.right + Int16(Self.originH))
    }

    /// A PICT's frame (`picFrame`); nil when the PICT is absent (`DrawPicture` of nothing draws nothing).
    private func frame(_ id: Int16) -> Rect16? {
        guard let r = resources.resource(type: "PICT", id: id, chain: .level), r.data.count >= 10 else { return nil }
        let b = [UInt8](r.data)
        func i16(_ o: Int) -> Int16 { Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1])) }
        return Rect16(top: i16(2), left: i16(4), bottom: i16(6), right: i16(8))
    }

    /// `.DrawConvPic(pic)` + `.CopyConvToScreen`: the frame GWorld (PICT 4000 with `pic` drawn into the portrait rect)
    /// copied to the screen at the origin with mode 0x24 (white transparent, raw `10079870`).
    private func copyConvToScreen(_ pic: Int16, _ out: inout FrontOutput) {
        if let f = frame(Self.framePict) {
            out.draws.append(.copyPicture(id: Self.framePict, chain: .level, source: f,
                                          dest: offset(Rect16(top: 0, left: 0, bottom: 0x134, right: 0x183)),
                                          forceClut: nil, transparent: true))
        }
        if let f = frame(pic) {
            out.draws.append(.copyPicture(id: pic, chain: .level, source: f, dest: offset(Self.portraitRect),
                                          forceClut: nil, transparent: true))
        }
    }

    /// `.DrawConvPicToScreen(pic)`: `DrawPicInRect` into the portrait rect on the screen.
    private func portraitToScreen(_ pic: Int16, _ out: inout FrontOutput) {
        guard let f = frame(pic) else { return }
        out.draws.append(.copyPicture(id: pic, chain: .level, source: f, dest: offset(Self.portraitRect),
                                      forceClut: nil, transparent: false))
    }

    /// `.EraseConvNameAndText`: the text and name rects copied back from the frame GWorld (mode 0x24) — PICT 4000's
    /// pixels there (the portrait rect meets neither).
    private func erase(_ out: inout FrontOutput) {
        guard let f = frame(Self.framePict) else { return }
        for r in [Self.textErase, Self.nameErase] {
            let src = Rect16(top: r.top + f.top, left: r.left + f.left, bottom: r.bottom + f.top, right: r.right + f.left)
            out.draws.append(.copyPicture(id: Self.framePict, chain: .level, source: src, dest: offset(r),
                                          forceClut: nil, transparent: true))
        }
    }

    /// `.DrawConvNameString(name)`: Times 18, black, centred in 180 px from x 0x13 (`(180 − width) / 2`, toward zero),
    /// baseline 0x114.
    private func drawName(_ name: [UInt8], _ out: inout FrontOutput) {
        let w = name.reduce(0) { $0 + text.charWidth($1) }
        let h = Self.originH + (0xb4 - w) / 2 + 0x13
        out.draws.append(.drawText(TextRun(bytes: name, font: 0x14, size: 0x12, face: 0, h: h, v: Self.originV + 0x114,
                                           rgb: Self.black)))
    }

    /// `.DrawConvTextString(text, param2, 0, rgb)` (responses): each wrapped chunk at once (`.DrawStringCharByCharOrig`);
    /// Escape after a chunk sets the abort flag and stops. The abort flag is tested before every chunk (M l. 65816–65820:
    /// set → return, and with flag 0 no space pass): once it is set — Escape at "press any key", or at an earlier row —
    /// the rows draw nothing (the menu's header and key wait still run).
    private func drawStatic(_ bytes: [UInt8], param2: Int, rgb: RGB16, input i: FrontInput, out: inout FrontOutput) {
        let x = Self.originH + 0x9a
        for c in Self.wrap(bytes, width: text.charWidth) {
            guard !aborted else { return }
            let v = Self.originV + param2 + 0xe + 0x12 * c.line + 0x1d
            if !c.bytes.isEmpty {
                out.draws.append(.drawText(TextRun(bytes: c.bytes, font: 0x14, size: 0x12, face: 0, h: x, v: v, rgb: rgb)))
            }
            if escape(i) {
                aborted = true
                return
            }
        }
    }

    /// One `.DrawStringCharByChar` step: the byte into a slot, the trail redrawn, every age + 1.
    fileprivate func step(_ c: UInt8, x: Int, y: Int, slot s: inout Int, out: inout FrontOutput) {
        for k in 0..<10 where 9 < trail[k].age { s = k }
        trail[s] = Slot(char: c, x: x, y: y, age: 0)
        for k in 0..<10 {
            let a = trail[k].age
            if trail[k].char != 0x20 && a & 1 != 0 {
                let g = UInt16(truncatingIfNeeded: Int(10 - a) * 4000)
                out.draws.append(.drawText(TextRun(bytes: [trail[k].char], font: 0x14, size: 0x12, face: 0, h: trail[k].x,
                                                   v: trail[k].y, rgb: RGB16(red: g, green: g, blue: g))))
            }
            if 9 < a { trail[k].char = 0x20 }
            trail[k].age = a &+ 1
        }
    }

    fileprivate func escapeDown(_ i: FrontInput) -> Bool { escape(i) }
    fileprivate func anyKeyDown(_ i: FrontInput) -> Bool { anyKey(i) }
    fileprivate func setAbort() { aborted = true }

    // MARK: The wrap (`.DrawConvTextString`, M l. 65751–65877)

    /// A wrapped chunk: the bytes drawn (the chunk without its last byte — the break space or the appended space) and
    /// its line number (0-based; the baseline is 18 px per line).
    struct Chunk: Equatable {
        var bytes: [UInt8]
        var line: Int
    }

    /// The chunks `.DrawConvTextString` draws, in order: a space appended (unless the text is 255 long); the running
    /// width sum of bytes from the line start; past 214 → the chunk from the line start to the last space seen (that
    /// space dropped), the next line after it; the text's end → the rest (the appended space dropped). A chunk with no
    /// space since the line start is the original's degenerate case (empty, or no progress — the original then loops
    /// for ever; the run ends the text there instead: no shipped text has a word wider than 214 px).
    static func wrap(_ text: [UInt8], width: (UInt8) -> Int) -> [Chunk] {
        var s: [UInt8] = [UInt8(truncatingIfNeeded: text.count)] + text.prefix(255)
        if s[0] != 0xff {
            s[0] += 1
            s.append(0x20)
        }
        let n = Int(s[0])
        var chunks: [Chunk] = []
        var w = 0, i9 = 1, i8 = 1, i7 = 1, line = 0
        while i9 < n {
            w += width(s[i7])
            if s[i7] == 0x20 { i8 = i7 }
            if 0xd6 < w {
                chunks.append(Chunk(bytes: i9 < i8 ? Array(s[i9..<i8]) : [], line: line))
                guard i9 < i8 + 1 else { break }                     // no progress: the original's endless loop
                line += 1
                i7 = i8 + 1
                w = 0
                i9 = i7
            } else {
                i7 += 1
                if n <= i7 {
                    chunks.append(Chunk(bytes: Array(s[i9..<i7]), line: line))
                    break
                }
            }
        }
        return chunks
    }
}

/// `.DrawConvTextString(text, param2, 1)`'s typing over ticks: the chunks' bytes one step each with a 2-tick delay,
/// Escape after each step and each chunk, then the 9-step space pass with delay 0.
private struct Typer {
    let chunks: [ConversationRun.Chunk]
    let x0: Int
    let y0: Int
    /// The chunk, the byte in it (or `chunks.count` = the space pass, its step in `byte`).
    var chunk = 0
    var byte = 0
    var x = 0
    /// `sVar6` of the current `.DrawStringCharByChar` call (0 at each call).
    var slot = 0
    /// The tick the pending step started (its delay runs), nil when the next step may start.
    var stepStart: UInt32?
    var delay: UInt32 = 2

    init(_ text: [UInt8], param2: Int, text measures: ConversationText) {
        chunks = ConversationRun.wrap(text, width: measures.charWidth)
        x0 = ConversationRun.originH + 0x9a
        y0 = ConversationRun.originV + param2 + 0xe + 0x1d
        x = x0
        widths = measures.charWidth
    }

    let widths: (UInt8) -> Int

    private func y(_ line: Int) -> Int { y0 + 0x12 * line }

    /// Steps as far as this tick allows; true when the typing returned (finished or aborted by Escape).
    mutating func advance(now: UInt32, input i: FrontInput, run: ConversationRun, out: inout FrontOutput) -> Bool {
        while true {
            if let start = stepStart {
                // `.CharByCharDelay(delay, start)`: elapsed ≥ delay, or a key seen down while waiting.
                guard now &- start >= delay || run.anyKeyDown(i) else { return false }
                stepStart = nil
                if chunk < chunks.count {
                    x += widths(chunks[chunk].bytes[byte])
                    byte += 1
                } else {
                    byte += 1
                }
                if run.escapeDown(i) {
                    run.setAbort()
                    return true
                }
                if chunk < chunks.count && byte == chunks[chunk].bytes.count {
                    // The chunk's end in `.DrawConvTextString`: Escape → abort; else the next line.
                    if run.escapeDown(i) {
                        run.setAbort()
                        return true
                    }
                    chunk += 1
                    byte = 0
                    slot = 0
                    x = x0
                }
                continue
            }
            if chunk < chunks.count {
                guard byte < chunks[chunk].bytes.count else {
                    // An empty chunk: no step; the chunk-end test.
                    if run.escapeDown(i) {
                        run.setAbort()
                        return true
                    }
                    chunk += 1
                    byte = 0
                    slot = 0
                    x = x0
                    continue
                }
                run.step(chunks[chunk].bytes[byte], x: x, y: y(chunks[chunk].line), slot: &slot, out: &out)
                delay = 2
                stepStart = now
                continue
            }
            // The 10-space pass (`.DrawStringCharByChar(10 spaces, x, y, 0)`): 9 steps, delay 0.
            guard byte < 9 else { return true }
            run.step(0x20, x: x, y: y(chunks.last?.line ?? 0), slot: &slot, out: &out)
            delay = 0
            stepStart = now
        }
    }
}
