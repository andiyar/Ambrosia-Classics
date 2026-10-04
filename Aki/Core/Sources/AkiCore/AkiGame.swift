/// One side effect of an `AkiGame` method, in the order the original performs it (Phase 2 ownership rule):
/// the app's `GameScreen.perform(_:)` executes them after the method returns. Sounds are `GameSound` cases,
/// never raw ids; volumes are the original's `_PlaySound` second argument (0x80 = 128, 0x100 = 256).
public enum GameEvent: Equatable, Sendable {                  // P2.5
    case playSound(GameSound, volume: Int), stopSound(GameSound), stopMusic, startMusic, playMovie(Int)
    case redrawTile(Int), fade(FadeJob), undoRedraw(UndoJob), redrawOpenPairs(flush: Bool)
    case redrawGameScreen(tiles: Bool), flashButton(Int, glow: Bool), pressButton(Int), pauseGame(Bool)
    case dialog(Int), setNoPairsFlash(Bool), setLost, setCustomLost, setEndLevel, recordLoss(Int), savePrefs
    case applyMatchBonus
}

/// The match fade of `_RedrawMatchedTiles` @ 0x13af5 step 3 (docs/aki/rules.md §8): the two tiles and the ST
/// list `_CalculateSurroundingTiles` @ 0x138a7 built, with the layout offsets g+0x94 / g+0x98 and whether all
/// 11 frames run (p+0x213 tile animation) or only one.
public struct FadeJob: Equatable, Sendable {                  // P2.5
    public var clicked: Tile; public var selected: Tile
    public var surrounding: [Tile]; public var animate: Bool; public var offsetX: Int; public var offsetY: Int
}

/// The redraw `_UndoLastCGMove` @ 0x128cb (rules §12) issues after restoring the pair: a full `_DrawGameTiles` buffer
/// rebuild + window copies, drawn with the open-pair count as it was BEFORE the recount (`openPairsAtDraw`) — P2.6.
public struct UndoJob: Equatable, Sendable {                  // P2.5 (used by P2.6)
    public var first: Int; public var second: Int; public var openPairsAtDraw: Int
}

/// One `_RedrawCustomTimeBar` @ 0xefa0 step (rules §10, §13) — used by P2.6.
public struct TimeBarStep: Equatable, Sendable {              // P2.5 (used by P2.6)
    public var raw: Int; public var length: Int; public var events: [GameEvent]
}

/// The selection / match / hint / undo state machine (rules §7–§12): the board, the clock and the rule-only `_g`
/// fields. Each mutating method mirrors one original function and returns its side effects as ordered events.
public struct AkiGame: Equatable, Sendable {
    public var board: Board; public var clock: GameClock                                         // P2.5
    /// p+0x20c, raw — out-of-range values behave as the original's switch / compare chains.
    public let difficultyRaw: Int16                                                              // P2.5
    /// g+0x90: 0…11 built-in, 13…17 custom.
    public let levelIndex: Int                                                                   // P2.5
    /// g+0x1ec (an index into `board.tiles`), g+0x60 open pairs, g+0x62 tiles left, g+0x1f1 Undo enabled.
    public var selected: Int?; public var openPairs: Int; public var tilesLeft: Int; public var undoEnabled: Bool
    /// g+0x4c last click tick, g+0x82 tick latch, g+0x84 idle hint flash.
    public var lastClickTick: UInt32; public var tickLatch: Bool; public var idleHintFlash: Bool  // P2.5

    public var difficulty: Difficulty? { Difficulty(rawValue: difficultyRaw) }                   // P2.5
    /// `0xb < g+0x90` (rules §8 step 7, §14).
    public var isCustom: Bool { levelIndex >= 12 }                                               // P2.5

    /// `_LoadLayout` / `_LoadCustomLevel` before the deal: tilesLeft = the tile count, nothing selected,
    /// Undo off, openPairs 0 until `dealFresh`.
    public init(board: Board, difficultyRaw: Int16, levelIndex: Int) {                          // P2.5
        self.board = board
        self.clock = GameClock(start: 0)
        self.difficultyRaw = difficultyRaw
        self.levelIndex = levelIndex
        selected = nil
        openPairs = 0
        tilesLeft = board.tiles.count
        undoEnabled = false
        lastClickTick = 0
        tickLatch = false
        idleHintFlash = false
    }

    public init(layout: Layout, difficultyRaw: Int16, levelIndex: Int) {                        // P2.5
        self.init(board: Board(layout: layout), difficultyRaw: difficultyRaw, levelIndex: levelIndex)
    }

    /// `_ShuffleCustomTiles(0)` from `_LoadLayout` (rules §5): g+0x60 = the open-pair count.
    public mutating func dealFresh<R: RandomNumberGenerator>(using rng: inout R) {               // P2.5
        openPairs = board.deal(reuse: false, using: &rng)
    }

    /// The clock starts after the slide-in (`_AnimationMapScreenToCustom` tail, R4); the idle clock with it.
    public mutating func startClock(now: UInt32) {                                               // P2.5
        clock = GameClock(start: now)
        lastClickTick = now
        idleHintFlash = false
    }

    /// `_CountOpenPairs` @ 0xe5e4 storing g+0x60 (rules §6).
    @discardableResult
    public mutating func countOpenPairs() -> Int {                                               // P2.5
        openPairs = board.countOpenPairs()
        return openPairs
    }

    /// `_SelectCGTile(Point)` @ 0x13eec (rules §7). Layers 6 → 0, tiles in list order; a hit is a tile on the
    /// layer whose box contains (h, v) that is open and not removed. Hit == selection → deselect; no selection →
    /// select; matching → `_RedrawMatchedTiles` then the match bonus; otherwise cancel and leave THIS layer's
    /// loop only — lower layers still run the full test (⚑ review fix). In the z = 0 pass, the last list tile,
    /// when not hit and a selection exists, clears the selection.
    public mutating func selectTile(h: Int, v: Int, tileAnimation: Bool) -> [GameEvent] {        // P2.5
        var events: [GameEvent] = []
        for layer in stride(from: 6, through: 0, by: -1) {
            for i in board.tiles.indices {
                let t = board.tiles[i]
                let box = board.pixelBox(of: i)
                let hit = t.z == layer && box.left <= h && h < box.right && box.top <= v && v < box.bottom
                    && t.isOpen && !t.isRemoved
                if hit {
                    guard let sel = selected else {
                        board.tiles[i].isSelected = true
                        selected = i
                        events += [.playSound(.tilehit, volume: 0x80), .redrawTile(i)]
                        return events
                    }
                    if sel == i {
                        board.tiles[i].isSelected = false
                        selected = nil
                        events += [.playSound(.unclick, volume: 0x80), .redrawTile(i)]
                        return events
                    }
                    if Board.matches(board.tiles[sel].face, t.face) {
                        events += [.stopSound(.cancel), .playSound(.tileMatch, volume: 0x80)]
                        board.tiles[i].isSelected = true
                        events += redrawMatchedTiles(clicked: i, tileAnimation: tileAnimation)
                        events.append(.applyMatchBonus)   // the bonus is added after _RedrawMatchedTiles returns
                        return events
                    }
                    events.append(.playSound(.cancel, volume: 0x80))
                    break
                }
                if layer == 0, i == board.tiles.count - 1, let old = selected {
                    board.tiles[old].isSelected = false
                    selected = nil
                    events += [.playSound(.unclick, volume: 0x80), .redrawTile(old)]
                }
            }
        }
        return events
    }

    /// `_RedrawMatchedTiles(tile)` @ 0x13af5 (rules §8) for the clicked tile `index` and the selection.
    private mutating func redrawMatchedTiles(clicked index: Int, tileAnimation: Bool) -> [GameEvent] {
        guard let sel = selected else { return [] }
        var events: [GameEvent] = []
        // 1. clear hints; Undo on when raw > 1: Easy and Practice (rules §8 step 1).
        for i in board.tiles.indices { board.tiles[i].isHinted = false }
        if difficultyRaw > 1 { undoEnabled = true }
        // 2. _DeleteTile every tile already removed (the previous pair); remap both indices past the deletions.
        let tiles = board.tiles
        func removedBefore(_ j: Int) -> Int { tiles[..<j].reduce(0) { $0 + ($1.isRemoved ? 1 : 0) } }
        let k = index - removedBefore(index), s = sel - removedBefore(sel)
        board.deleteRemoved()
        selected = s
        // 3. mark both fading, selection flags off; snapshot the ST list; the fade (one event, executed by the app).
        board.tiles[k].isFading = true
        board.tiles[s].isFading = true
        board.tiles[k].isSelected = false
        board.tiles[s].isSelected = false
        let surrounding = calculateSurroundingTiles(k, s, tileAnimation: tileAnimation)
        board.tiles[k].fadeFrame = 0                                   // param_1[2] = 0 before the frame loop
        events.append(.fade(FadeJob(clicked: board.tiles[k], selected: board.tiles[s], surrounding: surrounding,
                                    animate: tileAnimation, offsetX: board.offsetX, offsetY: board.offsetY)))
        // 4. mark both removed, fading off, selection cleared; visibility, openness, #Open.
        board.tiles[k].isRemoved = true
        board.tiles[s].isRemoved = true
        board.tiles[k].isFading = false
        board.tiles[s].isFading = false
        selected = nil
        board.setVisibleTiles()
        board.setOpenTiles()
        countOpenPairs()
        events.append(.redrawOpenPairs(flush: false))
        // 5. g+0x62; no open pairs → stop the music, Reshuffle.aiff.
        tilesLeft = board.unremovedCount
        if openPairs == 0 { events += [.stopMusic, .playSound(.reshuffle, volume: 0x100)] }
        // 6. tiles remain → full game-screen redraw.
        if tilesLeft > 0 { events.append(.redrawGameScreen(tiles: true)) }
        // 7. stacked loss: exactly one open tile left (no loss counter).
        if board.openUnremovedCount == 1 && tilesLeft > 0 {
            events += [.dialog(0x47), .setLost, .setEndLevel]
            if isCustom { events.append(.setCustomLost) }
        }
        // 8. board cleared → end level (the win is processed in _CustomGameScreen).
        if tilesLeft == 0 { events.append(.setEndLevel) }
        return events
    }

    /// `_CalculateSurroundingTiles(clicked, selected)` @ 0x138a7: sweep z 0→6, d 0→49, k 0→32 with
    /// (x, y) = (32−k, d−k) half-units (stopping a diagonal at y < 0), list order within a cell; collect every
    /// not-removed tile with x and y each within ±4.0 (inclusive) of either tile, as a fresh `_malloc`ed record
    /// (visible, all else clear) carrying z, x, y, face, fading, hint, and fade frame 0 (animation) or 10.
    private func calculateSurroundingTiles(_ a: Int, _ b: Int, tileAnimation: Bool) -> [Tile] {
        let ta = board.tiles[a], tb = board.tiles[b]
        func near(_ t: Tile, _ c: Tile) -> Bool { abs(t.x - c.x) <= 4 && abs(t.y - c.y) <= 4 }
        var out: [Tile] = []
        for z in 0...6 {
            for d in 0..<50 {
                for k in 0...32 {
                    let x = 32 - k, y = d - k
                    if y < 0 { break }
                    for t in board.tiles where !t.isRemoved && t.z == z && t.x == x && t.y == y
                        && (near(t, ta) || near(t, tb)) {
                        var copy = Tile(x: t.x, y: t.y, z: t.z)
                        copy.face = t.face
                        copy.isFading = t.isFading
                        copy.isHinted = t.isHinted
                        copy.fadeFrame = tileAnimation ? 0 : 10
                        out.append(copy)
                    }
                }
            }
        }
        return out
    }

    /// The match bonus `_SelectCGTile` adds to g+0xb0 after `_RedrawMatchedTiles` (rules §10): 3 / 6 / 12 / 0;
    /// nothing for an out-of-range raw difficulty.
    public mutating func applyMatchBonus() {                                                     // P2.5
        if let d = difficulty { clock.bonus += GameClock.matchBonus(d) }
    }

    /// `-[Controller mouseDown:]` @ 0x4489 in the game: g+0x4c = now; returns whether the idle hint flash
    /// (g+0x84) was on — the caller then runs `_FlashCGButton(1, 0)` — and clears it.
    public mutating func noteClick(now: UInt32) -> Bool {                                        // P2.5
        lastClickTick = now
        let was = idleHintFlash
        idleHintFlash = false
        return was
    }

    /// The double-click guard of `-[Controller mouseDown:]`: `TickCount() < last + GetDblTime()/2`, unsigned
    /// 32-bit with wrap (rules §7 "Mouse gating").
    public static func isRepeatClick(now: UInt32, lastTick: UInt32, doubleClickTicks: Int) -> Bool {   // P2.5
        now < lastTick &+ UInt32(doubleClickTicks / 2)
    }

    /// A repeat click still counts when it moved more than 1 px in BOTH v and h.
    public static func movedEnough(h: Int, v: Int, lastH: Int, lastV: Int) -> Bool {             // P2.5
        (v > lastV + 1 || v < lastV - 1) && (h > lastH + 1 || h < lastH - 1)
    }

    // MARK: P2.6 — hint, reshuffle, undo, pause, button bar, game tick, time bar

    /// `_ShowNextCGHint` @ 0x12622 (rules §9): clear every hint flag in list order (redrawing each tile) and
    /// remember the first (F); charge the hint penalty ALWAYS (b8/2, /4, /8, 0; nothing for an out-of-range
    /// raw); scan from F.next (or the head) to the end — the first open, not-removed tile whose first open,
    /// not-removed partner in list order matches gets both flagged and a full redraw; no wrap-around.
    /// Callers gate on g+0x60 ≠ 0 ∧ !paused (`_SelectCGButton` k 3, `_HandleMenuCommand` case 4).
    public mutating func showNextHint() -> [GameEvent] {                                          // P2.6
        var events: [GameEvent] = []
        var first: Int?
        for i in board.tiles.indices where board.tiles[i].isHinted {
            board.tiles[i].isHinted = false
            events.append(.redrawTile(i))
            if first == nil { first = i }
        }
        if let d = difficulty { clock.penalty += GameClock.hintPenalty(remaining: clock.remaining, d) }
        let start = first.map { $0 + 1 } ?? 0
        for i in start..<board.tiles.count {
            let t = board.tiles[i]
            guard t.isOpen && !t.isRemoved else { continue }
            for j in board.tiles.indices where j != i {
                let u = board.tiles[j]
                guard u.isOpen && !u.isRemoved && Board.matches(t.face, u.face) else { continue }
                board.tiles[i].isHinted = true
                board.tiles[j].isHinted = true
                events.append(.redrawGameScreen(tiles: true))
                return events
            }
        }
        return events
    }

    /// Reshuffle from the button (`_SelectCGButton` k 4, DC:7766) or the menu (`_HandleMenuCommand` case 6,
    /// caller gates !paused), then `_ReshuffleCustomTiles` @ 0x133ff (rules §11). Button in "no more pairs"
    /// with c0 ≠ 0: a8 += now − c0, c0 = 0, b8 := bc (penalty from the frozen time). Menu with g+0x60 == 0:
    /// a8 += now − c0, c0 = 0 unguarded, b8 kept live (Q23).
    public mutating func reshuffle<R: RandomNumberGenerator>(fromButton: Bool, now: UInt32,
                                                             using rng: inout R) -> [GameEvent] {   // P2.6
        if fromButton {
            if openPairs == 0 && clock.freezeTick != 0 {
                clock.thaw(now: now)
                clock.remaining = clock.frozenRemaining
            }
        } else if openPairs == 0 {
            clock.thaw(now: now)
        }
        return reshuffleCustomTiles(using: &rng)
    }

    /// `_ReshuffleCustomTiles` @ 0x133ff: g+0x1ec = 0; selection and hint flags off; `_DeleteTile` every removed
    /// tile; `_ShuffleCustomTiles(1)` → g+0x60; g+0x85 = 0; `_FlashCGButton(3, 0)`; penalty unless b8 == 0;
    /// music restarts when the shuffle left "no more pairs" (the app adds the original's music-preference gate);
    /// full redraw; tick.mp3 when b8 < 16.
    private mutating func reshuffleCustomTiles<R: RandomNumberGenerator>(using rng: inout R) -> [GameEvent] {
        let pairsBefore = openPairs
        selected = nil
        for i in board.tiles.indices {
            board.tiles[i].isSelected = false
            board.tiles[i].isHinted = false
        }
        board.deleteRemoved()
        openPairs = board.deal(reuse: true, using: &rng)
        var events: [GameEvent] = [.setNoPairsFlash(false), .flashButton(3, glow: false)]
        if clock.remaining != 0, let d = difficulty {
            clock.penalty += GameClock.reshufflePenalty(remaining: clock.remaining, d)
        }
        if pairsBefore == 0 { events.append(.startMusic) }
        events.append(.redrawGameScreen(tiles: true))
        if clock.remaining < 16 { events.append(.playSound(.tick, volume: 0x80)) }
        return events
    }

    /// `_HandleMenuCommand` case 3 + `_UndoLastCGMove` @ 0x128cb (rules §12): only for raw > 1 (Easy, Practice)
    /// with b8 ≠ 0; in "no more pairs" a8 += now − c0, c0 = 0 (unguarded). The first two removed tiles in list
    /// order get removed/selected off; then `_DrawGameTiles` redraws the WHOLE tile buffer (plus the window copies)
    /// BEFORE `_SetVisibleTiles` / `_SetOpenTiles` / the recount — it reads removed/face/position/selected/hinted
    /// and the pre-recount g+0x60 (carried as `openPairsAtDraw`: grey tiles in "no more pairs"), never
    /// isOpen/isVisible, so the App's `.undoRedraw` executor (P2.9/P2.10) rebuilds the full buffer, not just
    /// `first`/`second`; then visibility, openness and `_RedrawCustomOpenPairs(1)` (which recounts); g+0x1ec = 0;
    /// the penalty (3 / 6 / 12 / 0). g+0x1f1 is left on (its re-disable is under raw < 2, unreachable here) and
    /// g+0x62 is not touched, as in the original. No removed pair (after a reshuffle, or a second undo): nothing.
    public mutating func undo(now: UInt32) -> [GameEvent] {                                         // P2.6
        guard difficultyRaw > 1 && clock.remaining != 0 else { return [] }
        if openPairs == 0 { clock.thaw(now: now) }
        let removed = board.tiles.indices.filter { board.tiles[$0].isRemoved }
        // Removed tiles only ever exist as the last matched pair (rules §8 step 2), so 0 or 2 are found.
        guard removed.count >= 2 else { return [] }
        let first = removed[0], second = removed[1]
        for i in [first, second] {
            board.tiles[i].isRemoved = false
            board.tiles[i].isSelected = false
        }
        var events: [GameEvent] = [.undoRedraw(UndoJob(first: first, second: second, openPairsAtDraw: openPairs))]
        board.setVisibleTiles()
        board.setOpenTiles()
        countOpenPairs()
        events.append(.redrawOpenPairs(flush: true))
        selected = nil
        if let d = difficulty { clock.penalty += GameClock.undoPenalty(d) }
        return events
    }

    /// `_PauseGame(paused)` @ 0xd34b minus the App-owned flags g+0x7f / g+0x67 / g+0x86 (rules §13).
    /// Unpause: with pairs and c0 ≠ 0, a8 += now − c0, c0 = 0; with pairs and b8 < 16, tick.mp3.
    /// Pause: with pairs and c0 == 0, c0 = now; b8 < 15 stops tick.mp3. Then, with pairs, `_PlayMovie(0x80)` and
    /// `_RedrawCustomGameScreen(!paused)`.
    public mutating func pauseChange(paused: Bool, now: UInt32) -> [GameEvent] {                    // P2.6
        var events: [GameEvent] = []
        if !paused {
            if openPairs != 0 && clock.freezeTick != 0 { clock.thaw(now: now) }
            if openPairs != 0 && clock.remaining < 16 { events.append(.playSound(.tick, volume: 0x80)) }
        } else {
            if openPairs != 0 && clock.freezeTick == 0 { clock.freeze(now: now) }
            if clock.remaining < 15 { events.append(.stopSound(.tick)) }
        }
        if openPairs != 0 { events += [.playMovie(0x80), .redrawGameScreen(tiles: !paused)] }
        return events
    }

    /// `_SelectCGButton(Point)` @ 0x1356f: k from (paused ? 5 : 3) through 5, hit iff 38k − 90 ≤ h ≤ 38k − 65
    /// (h 24…49 hint, 62…87 reshuffle, 100…125 pause; the v range 555…587 is the caller's). On a hit the pressed
    /// button is drawn only for k ≠ 5 with g+0x60 ≠ 0 (DC:7753); k 3 hints when g+0x60 ≠ 0 ∧ !paused; k 4
    /// reshuffles unconditionally; k 5 with g+0x60 ≠ 0 plays Chime at 0x40 and toggles pause (`_PauseGame`, run
    /// by the app through `pauseChange`).
    public mutating func buttonClick<R: RandomNumberGenerator>(h: Int, paused: Bool, now: UInt32,
                                                               using rng: inout R) -> [GameEvent] {   // P2.6
        var events: [GameEvent] = []
        for k in (paused ? 5 : 3)...5 {
            guard 38 * k - 90 <= h && h <= 38 * k - 65 else { continue }
            if k != 5 && openPairs != 0 { events.append(.pressButton(k)) }
            switch k {
            case 3:
                if openPairs != 0 && !paused { events += showNextHint() }
            case 4:
                events += reshuffle(fromButton: true, now: now, using: &rng)
            default:
                if openPairs != 0 { events += [.playSound(.chime, volume: 0x40), .pauseGame(!paused)] }
            }
        }
        return events
    }

    /// `_CustomGameScreen` @ 0x12dbc game block (R1; the caller gates on `gameTickDue`, !paused, !endLevel):
    /// b4/b8 from the tick, then g+0x84 = g+0x4c + 1800 < now (idle 30 s → the hint button flashes).
    public mutating func tickClock(now: UInt32) {                                                    // P2.6
        clock.update(now: now)
        idleHintFlash = lastClickTick &+ 1800 < now
    }

    /// `_RedrawCustomTimeBar(now, flush)` @ 0xefa0 (rules §10, §13): `_CountOpenPairs` (stores g+0x60) == 0 →
    /// nothing drawn and no time-out. Else the Practice reset and the 300 s cap; the bar from t = paused ? c0 :
    /// now; after the draw the tick latch g+0x82 (off ∧ b8 > 15 → on, stop tick; on ∧ b8 < 16 → tick, off) and
    /// the time-out (b8 < 1): stop music and tick, lost, losses[level]++ (built-in) or custom-lost, save, end.
    public mutating func timeBarStep(now: UInt32, paused: Bool) -> TimeBarStep? {                    // P2.6
        guard countOpenPairs() != 0 else { return nil }
        clock.applyTimeBarAdjustments(now: now, difficultyRaw: difficultyRaw)
        let t = paused ? clock.freezeTick : now
        let raw = clock.timeBarRaw(at: t), length = clock.timeBarLength(now: t)
        var events: [GameEvent] = []
        if !tickLatch {
            if clock.remaining > 15 {
                tickLatch = true
                events.append(.stopSound(.tick))
            }
        } else if clock.remaining < 16 {
            events.append(.playSound(.tick, volume: 0x80))
            tickLatch = false
        }
        if clock.remaining < 1 {
            events += [.stopMusic, .stopSound(.tick), .setLost]
            events.append(isCustom ? .setCustomLost : .recordLoss(levelIndex))
            events += [.savePrefs, .setEndLevel]
        }
        return TimeBarStep(raw: raw, length: length, events: events)
    }

    /// `_RedrawNoMorePairs` @ 0x10854 (rules §11): b8 < 16 stops tick.mp3; bc := b8, c0 := now unless already
    /// frozen; g+0x85 = 1 (the reshuffle button flashes). The `nopairs.png` overlay is the app's draw.
    public mutating func enterNoMorePairs(now: UInt32) -> [GameEvent] {                              // P2.6
        var events: [GameEvent] = []
        if clock.remaining < 16 { events.append(.stopSound(.tick)) }
        clock.enterNoMorePairs(now: now)
        events.append(.setNoPairsFlash(true))
        return events
    }

    /// The game-block cadence of `_CustomGameScreen`: `last + 1 < now`, unsigned 32-bit (as `AkiMap.tickDue`).
    public static func gameTickDue(now: UInt32, last: UInt32) -> Bool {                              // P2.6
        last &+ 1 < now
    }

    /// The flash-block cadence of `_CustomGameScreen`: `last + 5 < now`, unsigned 32-bit.
    public static func flashDue(now: UInt32, last: UInt32) -> Bool {                                 // P2.6
        last &+ 5 < now
    }
}
