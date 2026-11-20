import Foundation

/// The high-score screen — `FUN_10021950` (grounding B §2d; `front-end.md` §4.1: 600 ticks, a click or a key leaves,
/// `N` starts a one-player game), its table layout `FUN_100222f0` (front-end.md §4.2, shared with name entry), and the
/// menu's Option-click erase question (front-end.md §2.7; plan question 8). Phase 4 S4 HS.
///
/// **Frozen entry.** `init()` — the table is `FrontEndState.prefs`. **Returns** how it was left: `.newGame` for `N`
/// (its caller `FUN_10024e70` then starts a one-player game, `10024eb0`), else `.leave`.
///
/// **The erase question.** In the original it belongs to the menu's SCORES click, before this screen: if Option (key
/// 0x3a) is down on a CLICK (not the S / H keys), the menu suspends, asks `inte` 24–27 ("Erase High Scores", "Are you
/// sure…", "Erase", "Cancel"), runs `FUN_10004ae0` on "Erase", resumes, and only then calls `FUN_10024e70`. Here the
/// caller sets `askErase` for an Option-click: the screen's first pass puts the question to the shell
/// (`ShellRequest.ask`) and waits (`HostWait.answer`); on the answer it erases (or not) and the screen begins in that
/// same pass. The menu's own suspend / resume around the alert (window, music, its flags) stay the menu's.
///
/// **The screen** (dump `FUN_10021950`): back ← black, the `back` TGA → back and save buffers, the list built with
/// edit 0 / dim 0, present, the list drawn once (no restore, no present), present — no fade; then FlushEvents
/// (`FUN_10048e30`), so input queued before the screen's first pass is dropped. Each later pass is one turn of its loop
/// at that pass's TickCount: leave once `start + F78 < now` (unsigned; F78 = 600), tested before any event; then the
/// events in order — key events (keyDown and autoKey, `0 < code < 4`) first, then clicks, as the shell's lists keep
/// them apart — a click leaves silently, a key leaves, `N` / `n` after gaso 2 (0x32, 100, 1) with `.newGame`. Leaving:
/// save buffer → back buffer, present. (The `update` event's present has no input here.)
public struct Scores: Sendable {
    public enum Exit: Equatable, Sendable {
        case leave
        case newGame
    }

    public typealias Result = Exit

    /// Set by the caller for an Option-click on SCORES: ask the erase question before the screen.
    public var askErase = false

    private enum Phase: Sendable {
        case begin
        case awaitingAnswer
        case shown(start: UInt32)
    }

    private var phase = Phase.begin
    /// The table's element list (`FUN_100222f0` with edit 0, dim 0, slot 0, player −1).
    var list = ElementList()

    public init() {}

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        var out = PassOutput()
        switch phase {
        case .begin where askErase:
            out.requests.append(.ask(Self.eraseQuestion(state.assets)))
            out.ops.append(.hostWait(.answer))
            phase = .awaitingAnswer
            return .stay(out)
        case .awaitingAnswer:
            guard let answer = keys.events.lazy.compactMap({ e -> QuestionButton? in
                if case let .answer(b) = e { return b } else { return nil }
            }).first else {
                out.ops.append(.hostWait(.answer))                    // still waiting for the shell's answer
                return .stay(out)
            }
            if answer == .first { state.prefs = HighScoreTable.erase(state.prefs) }   // "Erase" → FUN_10004ae0
            begin(ticks: ticks, state: state, out: &out)
            return .stay(out)
        case .begin:
            begin(ticks: ticks, state: state, out: &out)
            return .stay(out)                                         // FlushEvents: this pass's input is dropped
        case let .shown(start):
            let duration = UInt32(bitPattern: EntityDraw.fctiwz(state.assets.floats[78]))
            if start &+ duration < ticks { return .finish(.leave, Self.leave(out)) }   // 10021ab4: before the event
            if let key = keys.keyEvents.first {                       // codes 2 and 3
                var exit = Exit.leave
                if key.charCode == 0x6e || key.charCode == 0x4e {     // 'n' / 'N'
                    out.sounds.append(SoundPlay.perm(state.assets.sounds[2], priority: 0x32, volume: 100,
                                                     allowMultiple: true))
                    exit = .newGame
                }
                return .finish(exit, Self.leave(out))
            }
            if !keys.mouseDowns.isEmpty { return .finish(.leave, Self.leave(out)) }   // code 1, silent
            return .stay(out)
        }
    }

    /// The screen's entry (before its loop); the clock starts here (`iVar2 = TickCount()` first thing).
    private mutating func begin(ticks: UInt32, state: FrontEndState, out: inout PassOutput) {
        phase = .shown(start: ticks)
        list = Self.tableList(prefs: state.prefs, edit: false, dim: false, slot: 0, player: -1, assets: state.assets)
        out.ops += Self.screenOpen
        out.ops += list.drawOnce(restoreText: false, present: false, text: state.text, assets: state.assets)
        out.ops.append(.present(.fullScreen))
    }

    /// Leaving (`LAB_10021b60`): restore +0x6c → +0x68, present.
    private static func leave(_ out: PassOutput) -> PassOutput {
        var out = out
        out.ops += [.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false), .present(.fullScreen)]
        return out
    }

    // MARK: - Shared with name entry

    /// The `back` TGA (`FUN_10020da0(img, 'back', 'TGA ')`).
    static let backImage = FourCC("back")!
    /// The whole 640×480 picture (`FUN_10009fd0(img, buf, 0, 0, 0)`: the image's bounds both sides).
    static let fullRect = MacRect(top: 0, left: 0, bottom: 480, right: 640)

    /// The opening both screens share (`10021990..100219fc`, `10021c14..10021c78`, then `FUN_1000c2a0` — making the
    /// window current draws nothing — and the first `FUN_1000bc60`): back ← black, `back` → back, `back` → save,
    /// present.
    static let screenOpen: [RenderOp] = [
        .fill(.back, colour: 0),
        .loadImage(image: backImage, into: .back, dst: fullRect),
        .loadImage(image: backImage, into: .terrain, dst: fullRect),
        .present(.fullScreen),
    ]

    /// `FUN_100222f0(list, prefs, edit, dim, slot, player)` (front-end.md §4.2; dump `100222f0`). Headers: format 10
    /// "Name", 11 "Score", 12 "Sector" (strings `0x100e8ba1/ba6/bac`), each at its format's own Loc. Then 15 rows from
    /// y = F77, F76 apart, four elements each, appended in order:
    /// - the symbol: the text-settings template `0x100e8968` (empty text, LEFT, layer 8, draw-now, scale 1, the format
    ///   template's defaults — data image read) at x = F80, y = row + F81; on the edited row (`edit` and row == `slot`)
    ///   its sprite is the player's ship: gaob `player` (0 or 1) → the player definition with that tag (`FUN_10039460`,
    ///   the first) → +0x28 / +0x2c (`spriteHighScore`, frame). A tag with no definition keeps `none`.
    /// - the name (C string of the row's field), the score (`%i`), the sector name — each at y = row, x from its format.
    /// - formats: the edited row hilite 14 / 17 / 20; else `dim` ? 15 / 18 / 21 : 13 / 16 / 19.
    static func tableList(prefs: DeimosPrefs, edit: Bool, dim: Bool, slot: Int, player: Int,
                          assets: DeimosAssets) -> ElementList {
        let f = assets.floats
        var list = ElementList()
        for (fmt, text) in [(10, "Name"), (11, "Score"), (12, "Sector")] {
            list.append(.text(TextRequest(format: assets.formats[fmt], text: text)))
        }
        var rowY = EntityDraw.fctiwz(f[77])
        for row in 0..<HighScoreTable.rowCount {
            let edited = edit && row == slot
            var symbolFormat = TextFormat(text: [])
            symbolFormat.locX = EntityDraw.fctiwz(f[80])
            symbolFormat.locY = rowY &+ EntityDraw.fctiwz(f[81])
            var symbol = ElementList.Element.text(TextRequest(format: symbolFormat, text: [UInt8]()))
            if edited, player == 0 || player == 1,
               let def = assets.definitions.players.first(where: { $0.id == assets.objects[player] }) {
                symbol.sprite = def.spriteHighScore
                symbol.frame = Int(def.spriteHighScoreFrame)
            }
            list.append(symbol)
            let base = edited ? 1 : (dim ? 2 : 0)                     // 13 + base: normal, hilite, dim
            let fields = [prefs.highScoreNames[row], String(prefs.highScores[row]), prefs.highScoreSectorNames[row]]
            for (k, text) in fields.enumerated() {
                var format = assets.formats[13 + 3 * k + base]
                format.locY = rowY                                    // +0x104 = rowY; x stays the format's
                list.append(.text(TextRequest(format: format, text: text)))
            }
            rowY &+= EntityDraw.fctiwz(f[76])
        }
        return list
    }

    /// The erase question (`FUN_100498e0(inte 24, 25, 26, 27)` → `FUN_10045c60`: a Note alert, title 24, message 25,
    /// default button 26 "Erase", cancel 27 "Cancel"). `ShellQuestion` carries one message, so the title and the
    /// message are joined by a line break.
    public static func eraseQuestion(_ assets: DeimosAssets) -> ShellQuestion {
        let inte = try? assets.interfaceStrings()
        func line(_ i: Int) -> String { inte?.string(at: i) ?? "" }
        return ShellQuestion(message: line(24) + "\n" + line(25), firstButton: line(26), secondButton: line(27))
    }
}
