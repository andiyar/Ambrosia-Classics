// The high-score entry and the high-score screen (plan 2026-10-04 btx-playable C7; FI §3e), transcribed from
// `_CheckHiScore @ 00024b34`, `_HiScoreNameFilter @ 00024890` (the App's dialog filter — documented on
// `ShellRequest.highScoreNameDialog`), `_DisplayHiScores @ 00025733` and `_DrawSingleHiScore @ 0002553a`. The
// eligibility test is `_RequestGame @ 0000a9a1`'s. Custom-level games (the "^" suffix `_CheckHiScore` appends) are not
// reachable (plan Known delta 3); a name typed with a trailing "^" still gets the PICT 9077 badge, as it did.

/// One blocking sequence of the original run as steps on TickCount (the C7 screens): `_WaitFor`s, wipes, a modal
/// dialog, and the closing `WaitNextEvent` loop. Input that arrives meanwhile is queued like the original's event
/// queue — `FlushEvents(0x3e)` drops the key / mouse events and keeps the activate / deactivate ones.
class ScriptedScreen: FrontEndScreen {
    enum Step {
        /// Runs at once.
        case run(() -> SessionOutput)
        /// `_WaitFor(n)`: done when TickCount ≥ start + n.
        case waitTicks(Int)
        /// A `.wipe` op in flight: `n` advances, one per tick that TickCount has moved on (as `FrontEnd.Step`).
        case advances(Int)
        /// One pass of a `WaitNextEvent` loop per TickCount tick; returns true when the loop is left. It may push
        /// steps in front of itself (they run at once; the loop resumes after them, at the next tick).
        case loop((HeldKeys, inout SessionOutput) -> Bool)
        /// A modal dialog the App shows; resumes with the answer.
        case dialog((FrontEndDialogAnswer) -> [Step])
    }

    /// `WaitNextEvent(0x800a)`: mouseDown, keyDown and the OS suspend / resume event.
    enum Event: Equatable {
        case key(chars: String)
        case mouseDown
        case activated
        case deactivated
    }

    unowned let frontEnd: FrontEnd
    var steps: [Step] = []
    var events: [Event] = []
    private(set) var result: FrontEndScreenResult?
    /// TickCount as last seen.
    var now: UInt32 = 0
    private var started = false
    private var stepStart: UInt32?
    private var stepLast: UInt32 = 0
    private var stepCount = 0

    init(frontEnd: FrontEnd) {
        self.frontEnd = frontEnd
    }

    func finish(_ r: FrontEndScreenResult) {
        result = r
        steps = []
    }

    /// `FlushEvents(0x3e, 0)`.
    func flushEvents() {
        events.removeAll { $0 != .activated && $0 != .deactivated }
    }

    func push(_ more: [Step]) {
        steps.insert(contentsOf: more, at: 0)
    }

    // MARK: FrontEndScreen

    func tick(now: UInt32, keys: HeldKeys, mouse: MousePoint) -> SessionOutput {
        // A tick at an unchanged TickCount (the front end ticks a screen as it builds it) runs only what is due.
        let fresh = !started || now != self.now
        started = true
        self.now = now
        return run(keys: keys, fresh: fresh)
    }

    func key(_ code: UInt16, chars: String, modifiers: KeyModifiers) -> SessionOutput {
        if result == nil { events.append(.key(chars: chars)) }
        return SessionOutput()
    }

    func mouseDown(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput {
        if result == nil { events.append(.mouseDown) }
        return SessionOutput()
    }

    /// Not in the event mask.
    func mouseUp(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput { SessionOutput() }

    func appActivated() -> SessionOutput {
        if result == nil { events.append(.activated) }
        return SessionOutput()
    }

    func appDeactivated() -> SessionOutput {
        if result == nil { events.append(.deactivated) }
        return SessionOutput()
    }

    func dialogAnswered(_ answer: FrontEndDialogAnswer) -> SessionOutput {
        guard case .dialog(let then)? = steps.first else { return SessionOutput() }
        steps.removeFirst()
        push(then(answer))
        return run(keys: HeldKeys(), fresh: false)
    }

    // MARK: Runner

    private func run(keys: HeldKeys, fresh: Bool) -> SessionOutput {
        var out = SessionOutput()
        var fresh = fresh
        while result == nil, let step = steps.first {
            switch step {
            case .run(let f):
                steps.removeFirst()
                out.append(f())
                continue
            case .waitTicks(let n):
                if stepStart == nil { begin() }
                if now >= stepStart! &+ UInt32(n) { end(); continue }
            case .advances(let n):
                if stepStart == nil { begin() } else if stepLast < now { stepCount += 1; stepLast = now }
                if stepCount >= n { end(); continue }
            case .loop(let body):
                guard fresh else { break }
                fresh = false
                let before = steps.count
                let done = body(keys, &out)
                if result != nil { break }
                if done {
                    steps.remove(at: steps.count - before)
                    continue
                }
                if steps.count != before { continue }
            case .dialog:
                break
            }
            break
        }
        return out
    }

    private func begin() {
        stepStart = now
        stepLast = now
        stepCount = 0
    }

    private func end() {
        steps.removeFirst()
        stepStart = nil
    }

    // MARK: Shared pieces of the two event loops

    /// `PlayMySnd(0x11, 10, 0)` — the click that leaves the scores / credits screen.
    static let leaveSound = SoundCue(slot: 0x11, priority: 10, delayFrames: 0)

    /// One `WaitNextEvent` result of `_DisplayHiScores` / `_DisplayCredits`: a key → snd 17, N / n → new game,
    /// else back; a click → snd 17, back; the OS event → `_SuspendGame` / `_ResumeGame` (then `onResume`).
    func handleLeavingEvent(_ e: Event, out: inout SessionOutput, onResume: () -> Void = {}) {
        switch e {
        case .key(let chars):
            out.sounds.append(Self.leaveSound)
            let c = chars.unicodeScalars.first?.value
            finish(c == 0x4e || c == 0x6e ? .newGame : .finished)
        case .mouseDown:
            out.sounds.append(Self.leaveSound)
            finish(.finished)
        case .deactivated:
            out.append(frontEnd.suspendGame())
        case .activated:
            out.append(frontEnd.resumeGame())
            onResume()
        }
    }
}

// MARK: - `_CheckHiScore`

extension FrontEnd {
    /// `_RequestGame @ 0000a9a1`: `_CheckHiScore` runs after a game started at level 1 (`gPlayerIsCheating = 1 <
    /// level`, so level select never qualifies), not cheating (the pause cheats set `gPlayerIsCheating` too — C8;
    /// read here from `GameSession.playerIsCheating`) and not a demo — however the game ended (Esc included).
    static func checksHighScore(mode: GameMode, startLevel: Int, cheating: Bool) -> Bool {
        !(1 < startLevel) && !cheating && mode == .play
    }
}

/// `_CheckHiScore @ 00024b34` (registered build): no entry unless the score beats entry #7. Otherwise the game's last
/// picture is overlaid with System pattern 4 (`GetIndPattern(0, 4)`, `PenMode(patOr)`, `PaintRect` over the whole
/// comp — the Compositor's Q12 default) and shown (`_UpdateScreen`), the key / mouse events flushed, the score and
/// level shifted into the table, DLOG 1000 opened (snd 13, `_InitCursor`) — and on OK snd 15, the name resolved (empty
/// → "Maniac" / "Swoop" by `GetRandomFast(0, 1)` on the front end's stream; the joke names with their sound — C5) and
/// written to the entry and to slot 0; `_SetToScreen`, `_UpdateScreen`. Result: the entry's row
/// (`gLatestHighScoreIndex`), which `_DisplayHiScores` then flashes. The table is written back to
/// `frontEnd.highScores`; it reaches disk with the next prefs save (`_LoadLevel` / quit), as in the original.
final class HighScoreCheckScreen: ScriptedScreen {
    /// `PlayMySnd(0xd, 10, 0)` as DLOG 1000 opens; `PlayMySnd(0xf, 10, 0)` on OK.
    static let openSound = SoundCue(slot: 0xd, priority: 10, delayFrames: 0)
    static let okSound = SoundCue(slot: 0xf, priority: 10, delayFrames: 0)
    /// `GetIndPattern(pat, 0, 4)`.
    static let overlayPattern = 4

    init(frontEnd: FrontEnd, score: Int, level: Int) {
        super.init(frontEnd: frontEnd)
        let score = Int32(truncatingIfNeeded: score)
        steps = [.run { [unowned self] in open(score: score, level: level) }]
    }

    private func open(score: Int32, level: Int) -> SessionOutput {
        var table = frontEnd.highScores
        guard let rank = table.insertScore(score: score, level: Int(Int16(truncatingIfNeeded: level))) else {
            finish(.highScoreEntered(rank: nil))                       // `GetScore() <= highScores+0x78` → 0
            return SessionOutput()
        }
        let overlay: [DrawOp] = [.patternOverlay(index: Self.overlayPattern), .compToScreen(MainMenu.screenRect)]
        flushEvents()
        frontEnd.highScores = table
        push([.dialog { [unowned self] answer in
            [.run { [unowned self] in named(answer, rank: rank) }]
        }])
        return SessionOutput(sounds: [Self.openSound], drawOps: overlay,
                             requests: [.highScoreNameDialog(defaultName: table.defaultName), .setCursor(id: nil)])
    }

    /// After `ModalDialog` returned item 1. DLOG 1000 has no Cancel; a dismissal (never sent by the App) counts as
    /// an empty field.
    private func named(_ answer: FrontEndDialogAnswer, rank: Int) -> SessionOutput {
        let typed: String
        if case .name(let s) = answer { typed = s } else { typed = "" }
        var out = SessionOutput(sounds: [Self.okSound])
        let resolved = HighScoreTable.resolveName(typed: typed) { frontEnd.random.fast($0, $1) }
        if let extra = resolved.sound { out.sounds.append(SoundCue(slot: extra, priority: 10, delayFrames: 0)) }
        frontEnd.highScores.setName(resolved.name, at: rank)
        out.drawOps = [.compToScreen(MainMenu.screenRect)]
        finish(.highScoreEntered(rank: rank))
        return out
    }
}

// MARK: - `_DisplayHiScores`

/// `_DisplayHiScores @ 00025733`: the table on PICT 912, revealed by `_WipeScreen(12)`; the new entry (if any) flashes;
/// then up to 600 ticks from entry (`TickCount > start + 600`) or a key / click (snd 17; N → new game). ⌘Q held while
/// no event is pending sets `gFinished` (`IsCommandKeyDown() && GameKeyDown(0xc)`) — the menu loop then quits.
final class HighScoresScreen: ScriptedScreen {
    /// PICT 9020 "High Scores" — `SetRect` order top 0x50, left 0xd1, bottom 0x75, right 0x1af.
    static let titlePict = 0x233c
    static let titleRect = QDRect(top: 0x50, left: 0xd1, bottom: 0x75, right: 0x1af)
    /// `gCustomLevelsPict` = PICT 9077, the "^" badge.
    static let customBadgePict = 0x2375
    /// The column headers, Letters highlighted, at y 0x91.
    static let headers: [(text: String, h: Int)] = [("Name", 0x74), ("Score", 0x151), ("Level", 0x1c3)]
    static let headerV = 0x91
    /// `_DrawSingleHiScore`: name at x 0x74 (proportional), score at 0x154 and level at 0x1d8 (fixed pitch 15).
    static let nameH = 0x74, scoreH = 0x154, levelH = 0x1d8
    static let fixedPitch = 15
    /// Row i's baseline: 0xbc + 0x23·i.
    static func rowV(_ i: Int) -> Int { 0xbc + 0x23 * i }
    static let wipeStep = 12
    /// `_WaitFor(0x14)` before the flash; 6 cycles of `_WaitFor(5)` halves.
    static let flashDelay = 0x14, flashCycles = 6, flashHalf = 5
    /// `TickCount() > start + 600` → back.
    static let timeoutTicks: UInt32 = 600
    /// ⌘ + `GameKeyDown(0xc)` (Q).
    static let quitKeyCode: UInt16 = 0x0c

    private var start: UInt32 = 0

    init(frontEnd: FrontEnd, newEntryRank: Int?) {
        super.init(frontEnd: frontEnd)
        var seq: [Step] = [
            .run { [unowned self] in
                start = now
                let fe = self.frontEnd
                return SessionOutput(drawOps: Self.layoutOps(fe.highScores, backdrop: fe.menu.compPatternRect)
                                     + [.wipe(step: Self.wipeStep)])
            },
            .advances(DrawOp.wipeSteps(Self.wipeStep)),
        ]
        if let rank = newEntryRank, (0..<HighScoreTable.entryCount).contains(rank) {
            seq.append(.waitTicks(Self.flashDelay))
            for _ in 0..<Self.flashCycles {
                seq += [.run { SessionOutput(drawOps: Self.flashOffOps(rank)) },
                        .waitTicks(Self.flashHalf),
                        .run { [unowned self] in
                            SessionOutput(drawOps: Self.flashOnOps(self.frontEnd.highScores, rank))
                        },
                        .waitTicks(Self.flashHalf)]
            }
        }
        seq.append(.run { [unowned self] in flushEvents(); return SessionOutput() })
        seq.append(.loop { [unowned self] keys, out in waitPass(keys: keys, out: &out) })
        steps = seq
    }

    /// The drawing up to `_WipeScreen(12)`: PICT 912 centred into bgnd (`_DrawAndCentrePict`) and comp
    /// (`_PatternFillCompGWorld`), PICT 9020, the headers, the seven rows — all into comp.
    static func layoutOps(_ table: HighScoreTable, backdrop: QDRect) -> [DrawOp] {
        var ops: [DrawOp] = [.pict(id: MainMenu.compPatternPict, dst: backdrop, target: .bgnd),
                             .pict(id: MainMenu.compPatternPict, dst: backdrop, target: .comp),
                             .pict(id: titlePict, dst: titleRect, target: .comp)]
        for (text, h) in headers {
            ops.append(.string(text: text, h: h, v: headerV, highlighted: true, fixedPitch: nil, target: .comp))
        }
        for i in 0..<HighScoreTable.entryCount { ops += rowOps(table, i, v: rowV(i)) }
        return ops
    }

    /// `_DrawSingleHiScore(i, v, 0, …)` into comp: the name, the "^" badge (PICT 9077 at L49 T v R96 B v+23) when the
    /// name ends in "^", the score and the level (`NumToString`).
    static func rowOps(_ table: HighScoreTable, _ i: Int, v: Int) -> [DrawOp] {
        let e = table.entry(i)
        var ops: [DrawOp] = [.string(text: e.name, h: nameH, v: v, highlighted: false, fixedPitch: nil, target: .comp)]
        if e.name.hasSuffix("^") {
            ops.append(.pict(id: customBadgePict, dst: QDRect(top: Int16(v), left: 0x31, bottom: Int16(v + 0x17),
                                                               right: 0x60), target: .comp))
        }
        ops.append(.string(text: String(e.score), h: scoreH, v: v, highlighted: false, fixedPitch: fixedPitch,
                           target: .comp))
        ops.append(.string(text: String(e.level), h: levelH, v: v, highlighted: false, fixedPitch: fixedPitch,
                           target: .comp))
        return ops
    }

    /// The flash rect `SetRect(r, 0x74, 0xb7 + 35·rank, 0x209, 0xd8 + 35·rank)` (L116 R521).
    static func flashRect(_ rank: Int) -> QDRect {
        let d = 0x23 * rank
        return QDRect(top: Int16(0xb7 + d), left: 0x74, bottom: Int16(0xd8 + d), right: 0x209)
    }

    /// Off half: `_AddRectToBgnd(r)` (OS X: left down / right up to a multiple of 4, bottom ≤ 440; its `_CheckBlock`
    /// pass has no effect outside a game) and `_AddRectToScreen(r)`, `_RestoreBgnd(1)` = bgnd → comp, then
    /// `_DrawRectsToScreen` (comp → screen over r): the row vanishes into the backdrop.
    static func flashOffOps(_ rank: Int) -> [DrawOp] {
        let r = flashRect(rank)
        var b = r
        b.left = Int16(Int(b.left) & ~3)
        b.right = Int16((Int(b.right) + 3) & ~3)
        b.top = max(b.top, 0)
        b.bottom = min(b.bottom, 440)
        return [.restoreBgnd(b, target: .comp), .compToScreen(r)]
    }

    /// On half: `_DrawSingleHiScore(rank, v, 0, 1)` into comp, which adds L106 T v−5 R521 B v+27 to the screen list —
    /// merged with the off half's r (the list is not reset in between) into L106 T r.top R521 B r.bottom — then
    /// `_DrawRectsToScreen`.
    static func flashOnOps(_ table: HighScoreTable, _ rank: Int) -> [DrawOp] {
        let v = rowV(rank), r = flashRect(rank)
        let union = QDRect(top: min(r.top, Int16(v - 5)), left: 0x6a, bottom: max(r.bottom, Int16(v + 0x1b)),
                           right: 0x209)
        return rowOps(table, rank, v: v) + [.compToScreen(union)]
    }

    private func waitPass(keys: HeldKeys, out: inout SessionOutput) -> Bool {
        if start &+ Self.timeoutTicks < now {
            finish(.finished)
            return true
        }
        guard !events.isEmpty else {
            if keys.command && keys.codes.contains(Self.quitKeyCode) {
                frontEnd.finished = true
                finish(.finished)
                return true
            }
            return false
        }
        handleLeavingEvent(events.removeFirst(), out: &out)
        return result != nil
    }
}
