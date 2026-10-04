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

/// The two-tile redraw of `_UndoLastCGMove` @ 0x128cb (rules §12) — used by P2.6.
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
                        events += [.playSound(.tilehit, volume: 0x80), .redrawTile(i)]
                        board.tiles[i].isSelected = true
                        selected = i
                        return events
                    }
                    if sel == i {
                        events += [.playSound(.unclick, volume: 0x80), .redrawTile(i)]
                        board.tiles[i].isSelected = false
                        selected = nil
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
                    events += [.playSound(.unclick, volume: 0x80), .redrawTile(old)]
                    board.tiles[old].isSelected = false
                    selected = nil
                }
            }
        }
        return events
    }

    /// `_RedrawMatchedTiles(tile)` @ 0x13af5 (rules §8) for the clicked tile `index` and the selection.
    private mutating func redrawMatchedTiles(clicked index: Int, tileAnimation: Bool) -> [GameEvent] {
        guard let sel = selected else { return [] }
        var events: [GameEvent] = []
        // 1. clear hints; Undo on above Medium.
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
}
