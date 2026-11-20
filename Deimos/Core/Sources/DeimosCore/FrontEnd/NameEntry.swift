import Foundation
import HectorResources

/// Name entry for one player — `FUN_10021bd0(player, slot, prefs, fromGame)` (grounding B §2c; `front-end.md` §4.3;
/// dump `FUN_10021bd0`). Called only by the score-table insertion (`FUN_100214c0`, `HighScoreTable.insert`), player 1
/// then player 2, each only if that player qualified. Phase 4 S4 HS.
///
/// **Frozen entry.** `init(player:slot:prefs:fromGame:)` — the player (0 or 1), the table row (0…14), the prefs
/// copy A the insertion has already shifted, and `fromGame` (always true from the insertion). **Returns** prefs A as
/// name entry left it — the row's name and the remembered player name written; name entry also copies it into the
/// live prefs on exit (`FUN_100047f0(A)`), and the insertion hands it to the second player's entry.
///
/// **The screen** (first pass): back ← black, `back` → back and save, the row's name ← the player's remembered name
/// (`strcpy`), the edit buffer ← its first 20 bytes (`FUN_10046510`), the list built with edit 1, dim 1, the slot and
/// the player (row hilite + the player's ship), present, the list drawn once, present — no fade, no FlushEvents — and
/// gaso 9 `HighScoreAchieved` (0x32, 100, 1; its tag is `none`, so it is silent). The key clock, the flip clock and the
/// confirm clock all start at that pass's TickCount.
///
/// **The loop** (one turn per queued event, then one with none, each at the pass's TickCount; key events first, then
/// clicks, as the shell's lists keep them apart):
/// 1. leave if not running, or if confirmed and `confirm + (fromGame ? F79 25 : F78 600) < now` (unsigned);
/// 2. blink: if `lastKey + F82 (30) < now` and `lastFlip + F83 (10) < now` → lastFlip = now, flip the cursor, redraw;
/// 3. one event (`FUN_10048c90`): a click while editing does nothing, after Return it leaves; a keyDown or autoKey
///    (`0 < code < 4`) after Return leaves; while editing, its charCode (signed char, `10021ebc..10021ef4`): 0x0d / 0x0a
///    confirm; 0x08 deletes the last byte (lastKey = now, the cursor hidden; gaso 2 and a redraw only if there was
///    one); any other byte whose MSL ctype (`0x100f0f94`) has a bit of 0xdc — every byte 0x20–0x7E and 0x80–0xFE, the
///    table read for B §7a item 3 (identical in the OS X build at `0x100fc3e8`): Mac Roman's accented letters and
///    symbols are all accepted, only 0xFF ˇ and the controls are not — sets lastKey = now, hides the cursor, appends
///    if the name is under 20 (gaso 0 `clic`) else plays gaso 15 `shwa`, redraws. Every other byte (Tab, Esc, Enter
///    0x03, the arrows, 0x7F, 0xFF) does nothing at all: it neither hides the cursor nor restarts the 30 ticks. The
///    `0x5e5b` compare at `10021ef4` can never match and is not built.
/// 4. redraw: the name element ← the buffer, the row ← the buffer, + `_` (pgsl 7) if editing, the cursor is shown
///    and the name is under 20; the remembered name ← the row (`strcpy`); `back` → back; the list drawn restoring and
///    presenting each element; present.
///
/// **Confirm:** confirm = lastKey = now, gaso 4 (0x32, 100, 1), the cursor hidden; on an uppercase copy (ASCII a–z;
/// the MSL upper table at `0x100f1194` maps no byte ≥ 0x80 to ASCII, so the egg tests see only ASCII) the eggs are
/// tested by substring in the order BIKI, DILVISH, SUPERCOBRA, PYTHOS, FISJ, the last match winning; an empty name
/// becomes "Jar Jar Must Die"; otherwise the name stays as typed. The list is rebuilt with edit 0, dim 1 (no hilite,
/// no ship), then redrawn. "Leonard Cohen Rules J00" is 23 bytes: the original's `strcpy` into the 21-byte row runs
/// into the next row's field ("00"), and into the remembered name likewise (player 1's overflow lands in player 2's
/// name; player 2's in the pad before the scores) — kept (`NameFields`).
///
/// **Leaving:** if confirmed (always: nothing else ends the loop) the live prefs ← A (`FUN_100047f0`), save buffer →
/// back buffer, present. No time limit and no way out before Return; a Quit does not end it (the original reads only
/// the simple events here).
///
/// **Both players** (`player2Slot`): the insertion's two calls run back to back and read one event queue, so the keys
/// and clicks queued behind the one that ends player 1's entry are player 2's. The caller sets `player2Slot` on player
/// 1's entry when both qualified; that value then runs player 2's entry at that row next, over the prefs player 1 left,
/// in the same pass and handing it the unread events, and returns once player 2 leaves. Without it, events queued
/// behind the one that ends the entry go nowhere: under the frame's rule a pass's queue reaches only its first step.
///
/// Known divergences (kept): player 1 typing PYTHOS into row 14 — the original's `strcpy` of that row into the
/// remembered name overlaps itself and runs away (a crash); the replica copies from a snapshot (`NameFields`). A
/// 23-byte name reads back as 20 after a relaunch: the settings file writes each field cut to its width less the NUL.
public struct NameEntry: Sendable {
    public typealias Result = DeimosPrefs

    public let player: Int
    public let slot: Int
    public let prefs: DeimosPrefs
    public let fromGame: Bool
    /// Player 2's row, set on player 1's entry when both players qualified: player 2's entry follows inside this
    /// screen (see the type's comment). nil: one entry only.
    public var player2Slot: Int?

    /// The entry running now: player 1, then player 2 at `player2Slot`.
    private var entryPlayer: Int
    private var entrySlot: Int
    /// Prefs A as edited so far (the value returned).
    var edited: DeimosPrefs
    /// The edit buffer (`abStack_ad + 1`): Mac Roman bytes, at most 20 while typing (an egg can be longer).
    var buffer: [UInt8] = []
    /// The table's element list (`FUN_100222f0`).
    var list = ElementList()
    private var started = false
    /// bVar3: the loop runs.
    private var running = true
    /// bVar2: still typing (Return not yet pressed).
    private(set) var editing = true
    /// bVar4: Return was pressed.
    private var confirmed = false
    /// bVar5: the cursor is shown.
    private var cursorShown = false
    /// iVar9 / iVar13 / iVar12: the last flip, the last key, the confirm.
    private var lastFlip: UInt32 = 0
    private var lastKey: UInt32 = 0
    private var confirmTime: UInt32 = 0

    public init(player: Int, slot: Int, prefs: DeimosPrefs, fromGame: Bool = true) {
        self.player = player
        self.slot = slot
        self.prefs = prefs
        self.fromGame = fromGame
        edited = prefs
        precondition(player == 0 || player == 1, "NameEntry: player \(player) is not 0 or 1")
        precondition((0..<HighScoreTable.rowCount).contains(slot), "NameEntry: slot \(slot) is not a table row (0…14)")
        entryPlayer = player
        entrySlot = slot
    }

    /// The cap (`10022110 cmplwi r3,0x14`).
    static let maxLength = 20

    private enum Event {
        case key(UInt8)
        case click
    }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        var out = PassOutput()
        if !started { start(ticks: ticks, state: state, out: &out) }
        let a = state.assets
        let events = keys.keyEvents.map { Event.key($0.charCode) } + keys.mouseDowns.map { _ in Event.click }
        let wait = UInt32(bitPattern: EntityDraw.fctiwz(a.floats[fromGame ? 79 : 78]))
        let keyWait = UInt32(bitPattern: EntityDraw.fctiwz(a.floats[82]))
        let flipWait = UInt32(bitPattern: EntityDraw.fctiwz(a.floats[83]))
        var next = 0                                                 // the next unread event
        var lastTurnDone = false
        while !lastTurnDone {                                        // one turn per event, then one with none
            if !running || (!editing && confirmTime &+ wait < ticks) {
                if confirmed { state.prefs = edited }                // FUN_100047f0(A)
                out.ops += [.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false),
                            .present(.fullScreen)]
                guard let slot2 = player2Slot, entryPlayer == 0 else { return .finish(edited, out) }
                precondition((0..<HighScoreTable.rowCount).contains(slot2),
                             "NameEntry: player2Slot \(slot2) is not a table row (0…14)")
                beginPlayer2(slot: slot2)                            // FUN_10021bd0(1, idx2, A, 1)
                start(ticks: ticks, state: state, out: &out)
                continue                                             // the unread events are player 2's
            }
            var redraw = false
            if lastKey &+ keyWait < ticks, lastFlip &+ flipWait < ticks {
                lastFlip = ticks
                cursorShown.toggle()
                redraw = true
            }
            if next < events.count {
                defer { next += 1 }
                switch events[next] {
                case .click:
                    if !editing { running = false }
                case let .key(c):
                    if !editing {
                        running = false
                    } else {
                        handle(c, ticks: ticks, state: state, out: &out, redraw: &redraw)
                    }
                }
            } else {
                lastTurnDone = true
            }
            if redraw { self.redraw(state: state, out: &out) }
        }
        return .stay(out)
    }

    // MARK: - The steps

    /// Player 2's entry, from player 1's prefs A, every flag as a fresh call has it.
    private mutating func beginPlayer2(slot: Int) {
        entryPlayer = 1
        entrySlot = slot
        buffer = []
        running = true
        editing = true
        confirmed = false
        cursorShown = false
    }

    private mutating func start(ticks: UInt32, state: FrontEndState, out: inout PassOutput) {
        started = true
        var fields = NameFields(edited)
        fields.strcpy(to: entrySlot, fields.string(NameFields.player(entryPlayer)))     // row ← remembered
        fields.store(into: &edited)
        buffer = Array(fields.string(entrySlot).prefix(Self.maxLength))    // FUN_10046510(buf, row, 0x14)
        list = Scores.tableList(prefs: edited, edit: true, dim: true, slot: entrySlot, player: entryPlayer,
                                assets: state.assets)
        out.ops += Scores.screenOpen
        out.ops += list.drawOnce(restoreText: false, present: false, text: state.text, assets: state.assets)
        out.ops.append(.present(.fullScreen))
        out.sounds.append(Self.cue(9, state))
        lastFlip = ticks
        lastKey = ticks
        confirmTime = ticks
    }

    private mutating func handle(_ c: UInt8, ticks: UInt32, state: FrontEndState, out: inout PassOutput,
                                 redraw: inout Bool) {
        switch c {
        case 0x0d, 0x0a:                                             // Return / 0x0a: LAB_10021f18
            confirmTime = ticks
            editing = false
            lastKey = ticks
            confirmed = true
            out.sounds.append(Self.cue(4, state))
            redraw = true
            cursorShown = false
            buffer = Self.confirmedName(buffer)
            list = Scores.tableList(prefs: edited, edit: false, dim: true, slot: 0, player: entryPlayer,
                                    assets: state.assets)
        case 0x08:                                                   // Backspace
            lastKey = ticks
            if !buffer.isEmpty {
                buffer.removeLast()
                out.sounds.append(Self.cue(2, state))
                redraw = true
            }
            cursorShown = false
        default:
            guard Self.accepts(c) else { return }                    // ctype & 0xdc == 0: nothing at all
            lastKey = ticks
            if buffer.count < Self.maxLength {
                buffer.append(c)
                out.sounds.append(Self.cue(0, state))
            } else {
                out.sounds.append(Self.cue(15, state))
            }
            redraw = true
            cursorShown = false
        }
    }

    /// `LAB_10022174`.
    private mutating func redraw(state: FrontEndState, out: inout PassOutput) {
        let nameIndex = 4 + 4 * entrySlot                            // FUN_10000cf0(list, slot·4 + 4), 0-based
        var shown = buffer
        var fields = NameFields(edited)
        fields.strcpy(to: entrySlot, buffer)                         // row ← buffer
        if editing, cursorShown, shown.count < Self.maxLength {
            shown += state.assets.gameStrings[7]                     // pgsl 7 `_`
        }
        fields.strcpy(to: NameFields.player(entryPlayer), fields.string(entrySlot))  // remembered ← row
        fields.store(into: &edited)
        if list.elements.indices.contains(nameIndex) { list.elements[nameIndex].record.text = shown }
        out.ops.append(.loadImage(image: Scores.backImage, into: .back, dst: Scores.fullRect))
        out.ops += list.drawOnce(restoreText: true, present: true, text: state.text, assets: state.assets)
        out.ops.append(.present(.fullScreen))
    }

    // MARK: - Rules read from the binary

    /// `ctype[c] & 0xdc != 0` over the MSL table at `0x100f0f94` (read from the data image: 0x00–0x1F 0x01 / 0x02,
    /// 0x20 0x04, 0x21–0x7E 0x08 / 0x10 / 0x20 / 0x40 / 0x80 combinations, 0x7F 0x01, 0x80–0xFE 0x04 / 0x08 / 0x40 /
    /// 0x80, 0xFF 0x00).
    static func accepts(_ c: UInt8) -> Bool {
        (0x20...0x7e).contains(c) || (0x80...0xfe).contains(c)
    }

    /// The eggs, in the order tested (`0x100e8af8`, `s_DILVISH`, `s_SUPERCOBRA`, `s_PYTHOS`, `0x100e8b63`).
    static let eggs: [(String, String)] = [
        ("BIKI", "Filthy Communist"), ("DILVISH", "Just Ship It, Baby"), ("SUPERCOBRA", "Munkis Rool J00"),
        ("PYTHOS", "Leonard Cohen Rules J00"), ("FISJ", "Daikajinn!!"),
    ]

    /// The name Return leaves: the last egg whose word is in the uppercase copy, else "Jar Jar Must Die" if empty,
    /// else the buffer as typed.
    static func confirmedName(_ buffer: [UInt8]) -> [UInt8] {
        let upper = buffer.map { (0x61...0x7a).contains($0) ? $0 - 0x20 : $0 }
        var name = buffer
        for (word, egg) in eggs where contains(upper, Array(word.utf8)) { name = Array(egg.utf8) }
        if upper.isEmpty { name = Array("Jar Jar Must Die".utf8) }
        return name
    }

    /// `strstr(haystack, needle) != NULL` (bounded by the haystack's length).
    private static func contains(_ haystack: [UInt8], _ needle: [UInt8]) -> Bool {
        guard needle.count <= haystack.count else { return false }
        for i in 0...(haystack.count - needle.count) where Array(haystack[i..<(i + needle.count)]) == needle {
            return true
        }
        return false
    }

    /// `FUN_10047670(gaso i, 0x32, 100, 1)`.
    private static func cue(_ i: Int, _ state: FrontEndState) -> SoundCue {
        SoundPlay.perm(state.assets.sounds[i], priority: 0x32, volume: 100, allowMultiple: true)
    }
}

/// The prefs record's contiguous name fields (+0x10f8 … +0x1260): 15 table rows, then the two remembered player names,
/// 21 bytes each, then the 3 pad bytes before the scores. The original copies names with `strcpy`, so a name longer
/// than 20 bytes (only the PYTHOS egg, 23) runs into the next field. This models those copies on the bytes and reads
/// each field back as the original's `strcpy` / `strlen` do: from the field's start up to the first NUL, past the
/// field's end if it has none (bounded by the region). Fields the copies did not change keep their `String`s.
struct NameFields {
    static let width = 21
    static let fieldCount = HighScoreTable.rowCount + 2
    static let size = width * fieldCount + 3

    static func player(_ p: Int) -> Int { HighScoreTable.rowCount + p }

    private var bytes: [UInt8]
    private let before: [[UInt8]]

    init(_ prefs: DeimosPrefs) {
        bytes = [UInt8](repeating: 0, count: Self.size)
        let names = prefs.highScoreNames.prefix(HighScoreTable.rowCount) + prefs.playerNames.prefix(2)
        for (k, s) in names.enumerated() {
            let b = (MacRoman.encode(s, lossy: true) ?? []).prefix { $0 != 0 }.prefix(Self.width)
            bytes.replaceSubrange(k * Self.width..<(k * Self.width + b.count), with: b)
        }
        var read: [[UInt8]] = []
        for k in 0..<Self.fieldCount { read.append(Self.cString(bytes, from: k * Self.width)) }
        before = read
    }

    /// The C string at field `k`.
    func string(_ k: Int) -> [UInt8] { Self.cString(bytes, from: k * Self.width) }

    /// `strcpy(field k, s)`: `s` and its NUL from the field's start, bounded by the region's end.
    mutating func strcpy(to k: Int, _ s: [UInt8]) {
        let src = s.prefix { $0 != 0 } + [0]
        var at = k * Self.width
        for b in src where at < bytes.count {
            bytes[at] = b
            at += 1
        }
    }

    /// Every field whose C string changed, back into the prefs.
    func store(into prefs: inout DeimosPrefs) {
        for k in 0..<Self.fieldCount {
            let now = string(k)
            guard now != before[k] else { continue }
            let s = MacRoman.decode(now)
            if k < HighScoreTable.rowCount {
                prefs.highScoreNames[k] = s
            } else if prefs.playerNames.indices.contains(k - HighScoreTable.rowCount) {
                prefs.playerNames[k - HighScoreTable.rowCount] = s
            }
        }
    }

    private static func cString(_ b: [UInt8], from at: Int) -> [UInt8] {
        Array(b[at...].prefix { $0 != 0 })
    }
}
