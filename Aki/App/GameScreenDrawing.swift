import QuartzCore
import AkiCore
import HectorShell

/// The QuickDraw pipeline of the game screen (Research notes R2–R3), one original function per method, each
/// copy in the original's order with the original's rects (Invariant 13) — every rect from `AkiGameArt`.
/// `QD.drawToGWorld` mode −9 = CopyBits (stretching on a size mismatch), any other mode = CopyDeepMask.
/// Buffers: scratch3c (g+0x3c) the board, scratch2c (g+0x2c) the composed screen, `tiles` (g+0x04) the tile
/// sheet whose blank the face is painted into. Nothing here allocates a buffer (Invariant 15).
extension GameScreen {

    // MARK: - Tiles

    /// `_DrawGameTiles` @ 0xfe0a (DC:6244): background → scratch3c (full, CopyBits, DC:6272); then the R2
    /// sweep over every not-removed tile (`local_54[0xe] != 1`, DC:6287), painting it into scratch3c and
    /// copying its window rect to scratch2c (DC:6332–6337). `greyed` is the original's `g+0x60 == 0` read
    /// (DC:6308): callers pass `openPairs == 0`, or the undo's pre-recount count.
    func drawGameTiles(greyed: Bool) {                                                    // P2.9
        guard let game else { return }
        let gw = controller.gworlds!
        let full = AkiGameArt.screenRect
        QD.drawToGWorld(gw.background, gw.scratch3c, mask: gw.background, srcRect: full, dstRect: full,
                        maskRect: full, mode: -9)
        let board = game.board
        for key in sweepKeys(board.tiles, where: { _ in true }) {
            let t = board.tiles[key & 0xFFFF]
            let box = Board.pixelBox(of: t, offsetX: board.offsetX, offsetY: board.offsetY)
            paintBoardTile(t, box: box, blankMask: AkiGameArt.fadeMask(0), greyed: greyed)
            let window = AkiGameArt.tileWindowRect(box)
            QD.drawToGWorld(gw.scratch3c, gw.scratch2c, mask: gw.scratch3c, srcRect: window, dstRect: window,
                            maskRect: window, mode: -9)
        }
    }

    /// `_DrawBufferTiles(tile, selected)` @ 0x11495 (DC:6661): background → scratch3c over the tile's
    /// `bufferRestore` (DC:6693) and, with a selection, the selected tile's (DC:6697–6711); then the R2 sweep
    /// over the not-removed tiles within ±4 half-units (x and y, inclusive) of the tile or of the selected
    /// tile (DC:6727–6738), blank masked by the fade row while fading (DC:6753–6757), overlays as
    /// `_DrawGameTiles` with greyed = g+0x60 == 0 (DC:6762). Nothing reaches scratch2c.
    func drawBufferTiles(_ tile: Tile, selected: Tile?) {                                 // P2.9
        guard let game else { return }
        let gw = controller.gworlds!
        let board = game.board
        let restore = AkiGameArt.bufferRestore(Board.pixelBox(of: tile, offsetX: board.offsetX, offsetY: board.offsetY))
        QD.drawToGWorld(gw.background, gw.scratch3c, mask: gw.background, srcRect: restore, dstRect: restore,
                        maskRect: restore, mode: -9)
        if let selected {
            let restore = AkiGameArt.bufferRestore(
                Board.pixelBox(of: selected, offsetX: board.offsetX, offsetY: board.offsetY))
            QD.drawToGWorld(gw.background, gw.scratch3c, mask: gw.background, srcRect: restore, dstRect: restore,
                            maskRect: restore, mode: -9)
        }
        func near(_ t: Tile, _ c: Tile) -> Bool { abs(t.x - c.x) <= 4 && abs(t.y - c.y) <= 4 }
        let greyed = game.openPairs == 0
        for key in sweepKeys(board.tiles, where: { t in near(t, tile) || (selected.map { near(t, $0) } ?? false) }) {
            let t = board.tiles[key & 0xFFFF]
            let box = Board.pixelBox(of: t, offsetX: board.offsetX, offsetY: board.offsetY)
            paintBoardTile(t, box: box, blankMask: AkiGameArt.fadeMask(t.isFading ? t.fadeFrame : 0), greyed: greyed)
        }
    }

    /// `_RedrawTile(tile)` @ 0x11c93 (DC:6805): `_DrawBufferTiles(tile, g+0x1ec)`; window ← scratch3c at the
    /// tile's window rect (layout offsets included), flushed (DC:6825–6829); with a selection, window ←
    /// scratch3c at the selected tile's window rect computed WITHOUT g+0x94 / g+0x98 (DC:6833, Q30), flushed.
    func redrawTile(_ index: Int) {                                                       // P2.9
        guard let game else { return }
        let gw = controller.gworlds!
        let board = game.board
        let selected = game.selected.map { board.tiles[$0] }
        drawBufferTiles(board.tiles[index], selected: selected)
        let window = AkiGameArt.tileWindowRect(board.pixelBox(of: index))
        controller.drawToWindow(gw.scratch3c, srcRect: window, dstRect: window, flush: true)
        if let selected {
            let window = AkiGameArt.tileWindowRect(Board.pixelBox(of: selected, offsetX: 0, offsetY: 0))
            controller.drawToWindow(gw.scratch3c, srcRect: window, dstRect: window, flush: true)
        }
    }

    // MARK: - The match fade

    /// The frame loop of `_RedrawMatchedTiles` @ 0x13af5 (DC:7954–7966): while the clicked tile's frame
    /// (`param_1[2]`, 0 at entry) < 11: `_DrawFadeBufferTiles`, then window ← scratch3c at the clicked
    /// tile's rect and the selected tile's, each flushed, with no explicit wait between frames; without tile
    /// animation (p+0x213 == 0) the loop breaks after one frame. Pacing (D6, Q24 ⚑): each of the two presents
    /// per frame is followed by `waitOneRefresh()`, standing in for the 10.4+ refresh-throttled port flush —
    /// ~22/60 s for an animated fade. The window rect is (left, top+1, left+53, top+69) (DC:7957, DC:7960) —
    /// `tileRect` with its top moved down one row. The ST list is the job's copies; their frames advance
    /// here, as `_DrawFadeBufferTiles` advances the malloc'd ST records.
    func runFade(_ job: FadeJob) {                                                        // P2.9
        guard game != nil else { return }
        let gw = controller.gworlds!
        let clickedBox = Board.pixelBox(of: job.clicked, offsetX: job.offsetX, offsetY: job.offsetY)
        let selectedBox = Board.pixelBox(of: job.selected, offsetX: job.offsetX, offsetY: job.offsetY)
        var surrounding = job.surrounding
        var frame = job.clicked.fadeFrame
        while frame < 11 {
            drawFadeBufferTiles(clickedBox, selectedBox, &surrounding, offsetX: job.offsetX, offsetY: job.offsetY)
            let clickedWindow = AkiGameArt.fadeWindowRect(clickedBox)
            controller.drawToWindow(gw.scratch3c, srcRect: clickedWindow, dstRect: clickedWindow, flush: true)
            CATransaction.flush()
            waitOneRefresh()
            let selectedWindow = AkiGameArt.fadeWindowRect(selectedBox)
            controller.drawToWindow(gw.scratch3c, srcRect: selectedWindow, dstRect: selectedWindow, flush: true)
            CATransaction.flush()
            waitOneRefresh()
            if !job.animate { break }
            frame += 1
        }
    }

    /// One full tick (1/60 s) busy-waited on `ShellClock`'s clock — not "until the tick changes", which can
    /// return at once. Mac OS X 10.4+ throttled each QuickDraw port flush to the display refresh (D6, Q24 ⚑).
    private func waitOneRefresh() {
        let end = ProcessInfo.processInfo.systemUptime + 1.0 / 60
        while ProcessInfo.processInfo.systemUptime < end {}
    }

    /// `_DrawFadeBufferTiles(cx, cy, sx, sy)` @ 0x11e6d (DC:6847): background → scratch3c over the clicked
    /// and the selected tile's `bufferRestore` (DC:6866–6876); then each ST tile in list order: face → tile
    /// sheet (DC:6886), blank masked by `fadeMask(frame)` while fading — the record's frame then += 1 — else
    /// `fadeMask(0)` (DC:6890–6897), and the hint overlay when hinted (DC:6898–6904). No grey, no selection.
    private func drawFadeBufferTiles(_ clickedBox: QDRect, _ selectedBox: QDRect, _ surrounding: inout [Tile],
                                     offsetX: Int, offsetY: Int) {
        let gw = controller.gworlds!
        let clickedRestore = AkiGameArt.bufferRestore(clickedBox)
        QD.drawToGWorld(gw.background, gw.scratch3c, mask: gw.background, srcRect: clickedRestore,
                        dstRect: clickedRestore, maskRect: clickedRestore, mode: -9)
        let selectedRestore = AkiGameArt.bufferRestore(selectedBox)
        QD.drawToGWorld(gw.background, gw.scratch3c, mask: gw.background, srcRect: selectedRestore,
                        dstRect: selectedRestore, maskRect: selectedRestore, mode: -9)
        for i in surrounding.indices {
            let t = surrounding[i]
            let rect = AkiGameArt.tileRect(Board.pixelBox(of: t, offsetX: offsetX, offsetY: offsetY))
            let face = AkiGameArt.facePicture(t.face)
            QD.drawToGWorld(gw.tilePictures, gw.tiles, mask: gw.tilePictures, srcRect: face,
                            dstRect: AkiGameArt.faceDestination, maskRect: face, mode: -9)
            var mask = AkiGameArt.fadeMask(0)
            if t.isFading {
                mask = AkiGameArt.fadeMask(t.fadeFrame)
                surrounding[i].fadeFrame += 1
            }
            QD.drawToGWorld(gw.tiles, gw.scratch3c, mask: gw.tiles, srcRect: AkiGameArt.tileBlank, dstRect: rect,
                            maskRect: mask, mode: 1)
            if t.isHinted {
                QD.drawToGWorld(gw.tiles, gw.scratch3c, mask: gw.tiles, srcRect: AkiGameArt.tileHint, dstRect: rect,
                                maskRect: AkiGameArt.overlayMask, mode: 1)
            }
        }
    }

    /// The draw part of `_UndoLastCGMove` @ 0x128cb (DC:7193–7210): `_DrawGameTiles` with the pre-recount
    /// g+0x60, then window ← scratch3c at the window rect of the SECOND restored tile, then the first's
    /// (g+0x1ec), each flushed.
    func undoRedraw(_ job: UndoJob) {                                                     // P2.9
        guard let game else { return }
        let gw = controller.gworlds!
        drawGameTiles(greyed: job.openPairsAtDraw == 0)
        let board = game.board
        let secondWindow = AkiGameArt.tileWindowRect(board.pixelBox(of: job.second))
        controller.drawToWindow(gw.scratch3c, srcRect: secondWindow, dstRect: secondWindow, flush: true)
        let firstWindow = AkiGameArt.tileWindowRect(board.pixelBox(of: job.first))
        controller.drawToWindow(gw.scratch3c, srcRect: firstWindow, dstRect: firstWindow, flush: true)
    }

    // MARK: - The game screen

    /// `_RedrawCustomGameScreen(tiles)` @ 0x10a07 (DC:6470): background → scratch2c (full); the tiles; the
    /// plate masked by its right half (DC:6495); hint and reshuffle buttons (DC:6501, DC:6505); the pause
    /// button, paused or not (DC:6509–6522); `_RedrawCustomTimeBar(TickCount(), 0)`; the Practice reset and
    /// the 300 s cap (DC:6526–6532); open pairs and elapsed time unflushed; the pause overlay while paused
    /// (DC:6535–6541); "no more pairs" when g+0x60 == 0 with tiles left (DC:6543); the whole window.
    func redrawCustomGameScreen(tiles: Bool) {                                            // P2.9
        guard let atEntry = game else { return }  // not `game`: later reads must see the mutated value
        let gw = controller.gworlds!
        let g = controller.g
        let full = AkiGameArt.screenRect
        QD.drawToGWorld(gw.background, gw.scratch2c, mask: gw.background, srcRect: full, dstRect: full,
                        maskRect: full, mode: -9)
        if tiles {
            drawGameTiles(greyed: atEntry.openPairs == 0)
        }
        QD.drawToGWorld(gw.plate, gw.scratch2c, mask: gw.plate, srcRect: AkiGameArt.plateSource,
                        dstRect: AkiGameArt.plateDestination, maskRect: AkiGameArt.plateMask, mode: 1)
        for k in 3...4 {
            QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: AkiGameArt.buttonSprite(k),
                            dstRect: AkiGameArt.buttonDestination(k), maskRect: AkiGameArt.buttonMask, mode: 1)
        }
        QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc,
                        srcRect: g.paused ? AkiGameArt.pausedSprite : AkiGameArt.buttonSprite(5),
                        dstRect: AkiGameArt.buttonDestination(5), maskRect: AkiGameArt.buttonMask, mode: 1)
        redrawTimeBar(now: ShellClock.ticks(), flush: false)
        let now = ShellClock.ticks()
        updateGame { $0.clock.applyTimeBarAdjustments(now: now, difficultyRaw: $0.difficultyRaw) }
        redrawOpenPairs(flush: false)
        redrawTimeAccumulated(flush: false)
        if g.paused {
            QD.drawToGWorld(gw.pause, gw.scratch2c, mask: gw.pause, srcRect: AkiGameArt.overlaySource,
                            dstRect: AkiGameArt.overlayDestination, maskRect: AkiGameArt.overlaySourceMask, mode: 1)
        }
        if let game, game.openPairs == 0 && game.tilesLeft > 0 {
            redrawNoMorePairs()
        }
        redrawEntireWindow()
    }

    /// `_RedrawCustomTimeBar(now, flush)` @ 0xefa0 (DC:5860): `_CountOpenPairs() == 0` → nothing (the
    /// AkiCore step returns nil). Else plate → scratch2c over the bar (CopyBits, DC:5884); the stones from
    /// misc.png deep-masked into scratch2c — k full stones in one copy, then the cap (DC:6045–6052,
    /// DC:6195–6198; the 39-px stones overhang the 31-px bar inside scratch2c, copied as is); window ← the
    /// bar, `flush` (DC:6204); then the step's tick latch / time-out events, in order (DC:6205–6236).
    func redrawTimeBar(now: UInt32, flush: Bool) {                                        // P2.9
        let paused = controller.g.paused
        guard let step = updateGame({ $0.timeBarStep(now: now, paused: paused) }) ?? nil else { return }
        let gw = controller.gworlds!
        QD.drawToGWorld(gw.plate, gw.scratch2c, mask: gw.plate, srcRect: AkiGameArt.timeBarRestore.src,
                        dstRect: AkiGameArt.timeBarRestore.dst, maskRect: AkiGameArt.timeBarRestore.src, mode: -9)
        if let stones = AkiGameArt.timeBarStones(raw: step.raw, length: step.length) {
            if let src = stones.fullSource, let dst = stones.fullDestination, let mask = stones.fullMask {
                QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: src, dstRect: dst, maskRect: mask, mode: 1)
            }
            QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: stones.capSource,
                            dstRect: stones.capDestination, maskRect: stones.capMask, mode: 1)
        }
        let window = AkiGameArt.timeBarWindow
        controller.drawToWindow(gw.scratch2c, srcRect: window, dstRect: window, flush: flush)
        perform(step.events)
    }

    /// `_RedrawCustomTimeAccumulated(flush)` @ 0xe6e4 (DC:5746): `_CountOpenPairs()` (stores g+0x60) == 0 →
    /// nothing. Else HH = b4/3600, MM = b4%3600/60, SS = b4%60; plate → scratch2c (CopyBits, DC:5771); the
    /// digits deep-masked right to left as the original draws them — S-ones, S-tens, colon, M-ones, M-tens,
    /// colon, H-ones, H-tens (DC:5777–5848; a 0 digit uses row 10); window ← the field, `flush` (DC:5852).
    func redrawTimeAccumulated(flush: Bool) {                                             // P2.9
        guard let pairs = updateGame({ $0.countOpenPairs() }), pairs != 0, let game else { return }
        let gw = controller.gworlds!
        let elapsed = game.clock.elapsed
        let hh = elapsed / 3600, mm = elapsed % 3600 / 60, ss = elapsed % 3600 - mm * 60
        QD.drawToGWorld(gw.plate, gw.scratch2c, mask: gw.plate, srcRect: AkiGameArt.elapsedRestore.src,
                        dstRect: AkiGameArt.elapsedRestore.dst, maskRect: AkiGameArt.elapsedRestore.src, mode: -9)
        func put(_ slot: Int, _ src: QDRect, _ mask: QDRect) {
            QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: src,
                            dstRect: AkiGameArt.elapsedDestinations[slot], maskRect: mask, mode: 1)
        }
        func put(_ slot: Int, digit d: Int) {
            let digit = AkiGameArt.digit(d)
            put(slot, digit.src, digit.mask)
        }
        put(7, digit: ss % 10)
        put(6, digit: ss / 10)
        put(5, AkiGameArt.colon, AkiGameArt.colonMask)
        put(4, digit: mm % 10)
        put(3, digit: mm / 10)
        put(2, AkiGameArt.colon, AkiGameArt.colonMask)
        put(1, digit: hh % 10)
        put(0, digit: hh / 10)
        let window = AkiGameArt.elapsedWindow
        controller.drawToWindow(gw.scratch2c, srcRect: window, dstRect: window, flush: flush)
    }

    /// `_RedrawCustomOpenPairs(flush)` @ 0x103f5 (DC:6355): n = `_CountOpenPairs()`; plate → scratch2c
    /// (CopyBits, DC:6374); ones (DC:6388), tens when n ≥ 10 (DC:6390), hundreds when n ≥ 100 without the
    /// 0 → 10 row map (DC:6401); window ← the field, `flush` (DC:6412).
    func redrawOpenPairs(flush: Bool) {                                                   // P2.9
        guard let n = updateGame({ $0.countOpenPairs() }) else { return }
        let gw = controller.gworlds!
        QD.drawToGWorld(gw.plate, gw.scratch2c, mask: gw.plate, srcRect: AkiGameArt.pairsRestore.src,
                        dstRect: AkiGameArt.pairsRestore.dst, maskRect: AkiGameArt.pairsRestore.src, mode: -9)
        let ones = AkiGameArt.digit(n % 10)
        QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: ones.src,
                        dstRect: AkiGameArt.pairsDigitDestination(0), maskRect: ones.mask, mode: 1)
        if n > 9 {
            let tens = AkiGameArt.digit((n / 10) % 10)
            QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: tens.src,
                            dstRect: AkiGameArt.pairsDigitDestination(1), maskRect: tens.mask, mode: 1)
        }
        if n > 99 {
            let hundreds = AkiGameArt.pairsHundredsDigit((n / 100) % 10)
            QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: hundreds.src,
                            dstRect: AkiGameArt.pairsDigitDestination(2), maskRect: hundreds.mask, mode: 1)
        }
        let window = AkiGameArt.pairsWindow
        controller.drawToWindow(gw.scratch2c, srcRect: window, dstRect: window, flush: flush)
    }

    /// `_RedrawNoMorePairs` @ 0x10854 (DC:6420): b8 < 16 → `_StopSound(100)` (DC:6435); nopairs.png
    /// deep-masked by its right half into scratch2c (DC:6437–6441); then g+0x85 = 1 and the freeze
    /// (DC:6442–6447). `enterNoMorePairs` does the freeze; its events run on either side of the overlay at
    /// the original's points (the stop before, the flag after).
    func redrawNoMorePairs() {                                                            // P2.9
        guard let events = updateGame({ $0.enterNoMorePairs(now: ShellClock.ticks()) }) else { return }
        let split = events.firstIndex(of: .setNoPairsFlash(true)) ?? events.endIndex
        perform(Array(events[..<split]))
        let gw = controller.gworlds!
        QD.drawToGWorld(gw.nopairs, gw.scratch2c, mask: gw.nopairs, srcRect: AkiGameArt.overlaySource,
                        dstRect: AkiGameArt.overlayDestination, maskRect: AkiGameArt.overlaySourceMask, mode: 1)
        perform(Array(events[split...]))
    }

    /// `_RedrawEntireWindow` @ 0x10975 (DC:6453): scratch2c → window (full), flushed.
    func redrawEntireWindow() {                                                           // P2.9
        guard game != nil else { return }
        let gw = controller.gworlds!
        controller.drawToWindow(gw.scratch2c, srcRect: AkiGameArt.screenRect, dstRect: AkiGameArt.screenRect, flush: true)
    }

    // MARK: - Buttons

    /// `_FlashCGButton(n, glow)` @ 0xd90e (DC:5412): plate restore → scratch2c (CopyBits, DC:5434) and the
    /// button sprite deep-masked (DC:5446) on every call; with `glow`, the phase steps FIRST (g+0x87 falling,
    /// g+0x88 phase, DC:5449–5461) and the glow is then masked by the NEW phase row (DC:5462–5468); window ←
    /// the slot, flushed (DC:5472).
    func flashButton(_ n: Int, glow: Bool) {                                              // P2.9
        guard game != nil else { return }
        let gw = controller.gworlds!
        let g = controller.g
        let r = AkiGameArt.flash(n)
        QD.drawToGWorld(gw.plate, gw.scratch2c, mask: gw.plate, srcRect: r.restoreSource,
                        dstRect: r.restoreDestination, maskRect: r.restoreSource, mode: -9)
        QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: r.spriteSource,
                        dstRect: r.spriteDestination, maskRect: r.spriteMask, mode: 1)
        if glow {
            var phase = AkiGameArt.FlashPhase(rising: !g.flashFalling, p: g.flashPhase)
            phase.step()
            g.flashFalling = !phase.rising
            g.flashPhase = phase.p
            QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: r.glowSource,
                            dstRect: r.glowDestination, maskRect: r.glowMask(g.flashPhase), mode: 1)
        }
        controller.drawToWindow(gw.scratch2c, srcRect: r.window, dstRect: r.window, flush: true)
    }

    /// The pressed look of `_SelectCGButton` @ 0x1356f (DC:7753–7764), drawn for k 3 / 4 when g+0x60 ≠ 0
    /// (AkiGame emits `.pressButton` only then): plate restore → scratch2c with CopyBits (the original's mask
    /// rect lies outside plate.png, Q26); the pressed sprite deep-masked into the 25×25 slot; window ← the
    /// slot, flushed.
    func pressButton(_ k: Int) {                                                          // P2.9
        guard game != nil else { return }
        let gw = controller.gworlds!
        QD.drawToGWorld(gw.plate, gw.scratch2c, mask: gw.plate, srcRect: AkiGameArt.pressedRestoreSource(k),
                        dstRect: AkiGameArt.pressedRestoreDestination(k), maskRect: AkiGameArt.pressedRestoreSource(k),
                        mode: -9)
        let slot = AkiGameArt.buttonDestination(k)
        QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: AkiGameArt.pressedSprite(k), dstRect: slot,
                        maskRect: AkiGameArt.buttonMask, mode: 1)
        controller.drawToWindow(gw.scratch2c, srcRect: slot, dstRect: slot, flush: true)
    }

    // MARK: - Helpers

    /// The R2 sweep order shared by `_DrawGameTiles`, `_DrawBufferTiles` and `_CalculateSurroundingTiles`:
    /// z 0→6, d 0→49, k 0→32 at (x, y) = (32−k, d−k) half-units (a diagonal stops at y < 0), list order within
    /// a cell; removed tiles are skipped. Returned as sorted keys ((z, d, k) << 16 | list index) — the same
    /// visiting order as the triple loop, built once per call; a tile outside the swept cells is never drawn,
    /// as in the original.
    private func sweepKeys(_ tiles: [Tile], where include: (Tile) -> Bool) -> [Int] {
        var keys: [Int] = []
        keys.reserveCapacity(tiles.count)
        for (i, t) in tiles.enumerated() where !t.isRemoved && include(t) {
            let k = 32 - t.x, d = t.y + k
            guard (0...6).contains(t.z), (0...32).contains(k), t.y >= 0, d < 50 else { continue }
            keys.append((((t.z * 50 + d) * 33 + k) << 16) | i)
        }
        keys.sort()
        return keys
    }

    /// One tile of `_DrawGameTiles` (DC:6296–6331) / `_DrawBufferTiles` (DC:6743–6790) into scratch3c: the
    /// face → the tile sheet's blank (CopyBits, 38×50 → 38×49 stretch); the blank deep-masked by
    /// `blankMask`; then greyed ? grey : selected ? selected : hinted ? hint, masked by `overlayMask`.
    private func paintBoardTile(_ t: Tile, box: QDRect, blankMask: QDRect, greyed: Bool) {
        let gw = controller.gworlds!
        let face = AkiGameArt.facePicture(t.face)
        QD.drawToGWorld(gw.tilePictures, gw.tiles, mask: gw.tilePictures, srcRect: face,
                        dstRect: AkiGameArt.faceDestination, maskRect: face, mode: -9)
        let rect = AkiGameArt.tileRect(box)
        QD.drawToGWorld(gw.tiles, gw.scratch3c, mask: gw.tiles, srcRect: AkiGameArt.tileBlank, dstRect: rect,
                        maskRect: blankMask, mode: 1)
        let overlay: QDRect? = greyed ? AkiGameArt.tileGrey
            : t.isSelected ? AkiGameArt.tileSelected
            : t.isHinted ? AkiGameArt.tileHint : nil
        if let overlay {
            QD.drawToGWorld(gw.tiles, gw.scratch3c, mask: gw.tiles, srcRect: overlay, dstRect: rect,
                            maskRect: AkiGameArt.overlayMask, mode: 1)
        }
    }
}
