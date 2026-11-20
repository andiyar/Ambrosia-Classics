import Foundation

/// Start a game and return to the menu — `FUN_100234d0(mode, players)` as the OS X build runs it (X `100238c0`;
/// grounding B §1a–§1e; `front-end.md` §3; `osx-build.md` D7, D9, D13, D18; Phase 4 S3a SR). Addresses below are L's
/// (`100234d0..10023af8`, the listing the bank reads); X is the same instruction for instruction but for the
/// differences named.
///
/// **Frozen entry.** `init(mode:players:film:)` — the original's mode (0 play, 1 Last Film, 2 demo) and player count;
/// a film mode carries the film its caller chose (the films screen, S5) or nil when none loads (the result is then
/// `SessionResult.filmLoadFailed`). `init(direct:)` — the direct start (ruling 10): no level select, no fades, no
/// cursor shown on the way back; it is G12's path and stays as it is. **Returns** the game's `SessionResult`, or nil
/// when no game ran (the level select was cancelled). The level select hands back only the sector, so the game's
/// "music already playing" (`SessionStart.musicAlreadyPlaying`) is start/return's to set as it builds the start
/// after a level select. The menu's element list and its lit button are in `FrontEndState` (`menuElements`,
/// `menuLit`): the menu fills them, start/return fades them out and back in. As every screen: a pass's queued input
/// (shell events included) reaches it only when it is that pass's first step (`FrontEndScreen`).
///
/// **The start** (B §1a), one pass per stretch the original runs between two blocking steps, because the driver
/// sends a pass's cues before its ops (`FrontEndWaits`) and a cue that follows a wait must ride in a later pass:
/// 1. play mode: the menu music paused (`10023518` `FUN_10048220(1)`); a full present (`10023544`); play mode: the
///    cursor hidden (`10023550`; X skips it for a film, `1002393c..10023948`, D13); the menu's element fade-out
///    (`10023558` `FUN_10025890`). [`FUN_1000c2a0` window current; About off — empty in X, D9.]
/// 2. `tran` (gaso 3; 0x4b, 100, multiple 1 — every mode, `1002355c..10023574`); the fade to black, full-screen
///    presents (`10023584` `FUN_1000b9a0(D, 0)`, 33 steps).
/// 3. play mode: the music stopped and `ammu` looped (`100235a0..100235b8`), then the level select (`100235d0`;
///    `none` → no game, a sector > 1 → "started later", r25). The game starts from its sector, the music already
///    playing. A film plays its film at once (no music touched). [Input resume / suspend: nothing here, D18.]
///
/// **The game** is the front end's (`FrontEndState.startGame` / `gamePass`): its pass is this screen's pass. The
/// session's own end — halt and music stop for a game, the end-of-session flush — is the session's and the driver's
/// (B §1b steps 1–2).
///
/// **The return** (B §1b, on the pass after the game ended, or the pass the level select returned nil):
/// - **R1:** a game ran (r26) → the post-game gates (B §1d, below); the level select was cancelled → the music
///   stopped (`10023768..10023774`); a game ran → the fade to black of the last game frame, game-layout presents
///   (`1002378c` `FUN_1000b9a0(D, 1)`); `back` into the back and save buffers; the fade in, full-screen presents
///   (`10023834` `FUN_1000ba70(D, 0)`, 9 steps). A film (no `tran` follows) runs the menu's return in the same pass.
/// - **The table path** (`1002383c..10023974`: no cheat, not started later, not a film, no quit, a qualifier):
///   `tran` (0x32, 100, 1); FlushEvents — this pass's queued input reached this step and goes no further; [About
///   on: empty in X, D9]; the insertion (`FUN_100214c0`, `HighScoreTable.insert`) and name entry — player 1, player 2,
///   or player 1 with `NameEntry.player2Slot` when both made the table. Then (the pass name entry returned on): the
///   cursor shown (`100238b4`); [menu bar: not in X, D7]; `back` into both buffers; the menu's buttons unlit and its
///   element fade-in (`10023928..1002392c`); the redraw (`10023934`); a full present (`10023958`). Then one more pass:
///   FlushEvents (`10023960` — what arrived during the fade-in stops here, so the menu never reads it) and b6 = 1.
/// - **Otherwise** (`10023978..10023ae4`): `back` into both buffers; a full present; not a film → `tran` (0x32, 100,
///   1); [menu bar: not in X]; `back` into both buffers again; unlit, the element fade-in, the redraw; [About on]; the
///   cursor shown (`10023ad0`); not a film → b6 = 1. No flush: input that arrives during the fade-in reaches the menu.
/// - b6 makes the menu's next pass resume a living stream or play `inmu` from the start (`10022b9c`). A film never
///   sets it and never touches the music, so the menu music plays on under a film and after it (INDEX #54).
///
/// **The post-game gates** (B §1d, `10023674..10023764`; skipped when the quit flag b8 is set or a player cheated):
/// over the two slots, each present one: score > 0 → best = max(best, its level's sector, `FUN_10011e30`, 0 for a
/// level not in the order); no qualifier yet → it qualifies if its score beats the table's 15th (`FUN_10021470`,
/// signed, strict). best − 1 unless all levels were done (the finale); at least 1. Not a film and not started later:
/// best > pref 3 → pref 3 = best, in the live prefs. Esc does not set b8, so an Esc-ended game reaches the gates and
/// the table (ruling 15).
///
/// **Known differences** (the frame's rules, recorded): input typed during R1's fades is read by start/return's next
/// pass (its first step) and dropped there — the original's menu would read it after an "otherwise" return (the
/// table path flushes it anyway). The redraw draws the menu's list as the menu last built it: after a click the menu
/// built it with the pressed button lit and unlit its buttons without rebuilding (`MainMenu.track`), so the redraw
/// shows that button lit until the menu's next pass redraws its dirty buttons, where the original's redraw rebuilds
/// the list unlit at once.
///
/// **A game that cannot be built** (no original counterpart): the direct start reports an ended game with no ops and
/// tries again on its next pass; from the menu, a play game returns as if the level select were cancelled (nil) and
/// a film as if its film failed to load.
public struct StartReturn: Sendable {
    /// `FUN_100234d0`'s mode.
    public enum Mode: Equatable, Sendable {
        case play
        case lastFilm
        case demo
    }

    public typealias Result = SessionResult?

    public let mode: Mode
    public let players: Int
    public let film: Film?
    /// The direct start's game (nil from a menu).
    public let direct: SessionStart?

    private enum Step: Sendable {
        /// 1a steps 1–3 (the music pause, present, cursor, element fade-out).
        case begin
        /// 1a steps 4–5 (`tran`, the fade to black).
        case blackout
        /// 1a steps 6–9 (the level select, or the film's session).
        case session
        case levelSelect
        case game
        /// 1b step 11b, after R1.
        case menu
        /// 1b step 11a: `tran`, the insertion and name entry.
        case table
        /// 1b step 11a after name entry.
        case tableMenu
        /// 1b step 11a's last FlushEvents and b6.
        case tableFlush
    }
    private var step = Step.begin
    /// r25: the level select chose a sector above 1.
    private var startedLater = false
    /// The result handed back (nil when no game ran).
    private var result: SessionResult?

    public init(mode: Mode, players: Int, film: Film? = nil) {
        self.mode = mode
        self.players = players
        self.film = film
        direct = nil
    }

    /// The direct start (ruling 10).
    public init(direct start: SessionStart) {
        mode = .play
        players = start.players
        film = start.film
        direct = start
    }

    /// r27: a film mode.
    private var isFilm: Bool { mode != .play }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        if let direct { return directPass(direct, keys: keys, ticks: ticks, state: &state) }
        var out = PassOutput()
        switch step {
        case .begin:
            if !isFilm { out.music.append(.pause) }                  // 10023518 FUN_10048220(1)
            out.ops.append(.present(.fullScreen))                     // 10023544 FUN_1000bc60
            if !isFilm { out.requests.append(.hideCursor) }           // 10023550 FUN_1000b6e0; X not for a film (D13)
            out.ops += state.menuElements.fadeOut(rate: Self.fadeRate(state), text: state.text,
                                                  assets: state.assets)   // 10023558 FUN_10025890
            step = .blackout
            return .stay(out)
        case .blackout:
            out.sounds.append(Self.tran(priority: 0x4b, state))      // 1002355c..10023574
            out.ops.append(.fade(.toBlack, .fullScreen))              // 10023584 FUN_1000b9a0(D, 0)
            step = .session
            return .stay(out)
        case .session:
            switch mode {
            case .play:
                out.music += [.stop, .play(Self.ammu, loop: true)]    // 100235a0 FUN_10048120(0); 100235b8 ammu
                step = .levelSelect
                return .call(.levelSelect(LevelSelect()), out)        // 100235d0 FUN_1002e310
            case .lastFilm, .demo:
                guard let film else {                                 // 100056dc..100056f0: the result stays zero
                    return comeBack(.filmLoadFailed(startSector: 0), gameRan: true, state: &state)
                }
                return startGame(SessionStart(sector: 1, players: film.playerCount, film: film), keys: keys,
                                 ticks: ticks, state: &state)
            }
        case .levelSelect:
            guard case let .levelSelect(sector)? = returned, let sector else {     // 'none': no game (r26 = 0)
                return comeBack(nil, gameRan: false, state: &state)
            }
            startedLater = sector > 1                                 // 100235dc..100235e4 r25
            return startGame(SessionStart(sector: sector, players: players, film: nil, musicAlreadyPlaying: true),
                             keys: keys, ticks: ticks, state: &state)
        case .game:
            guard state.gameRunning else { return comeBack(state.game?.session.result, gameRan: true, state: &state) }
            return .stay(state.gamePass(keys: keys, ticks: ticks))
        case .menu:
            return menuReturn(tran: true, state: &state, &out)
        case .table:
            return table(state: &state, &out)
        case .tableMenu:
            out.requests.append(.showCursor)                          // 100238b4 FUN_1000b780 InitCursor
            out.ops += Self.backIntoBoth                              // 100238c4..10023910 (X: no menu bar, D7)
            out.ops += menuFadeInAndRedraw(state: &state)             // 10023924..10023934
            out.ops.append(.present(.fullScreen))                     // 10023958 FUN_1000bc60
            step = .tableFlush
            return .stay(out)
        case .tableFlush:
            // 10023960 FlushEvents: this pass's queued input (what arrived during the fade-in) goes no further.
            state.menuMusic = true                                    // 10023970 b6 = 1 (never a film here)
            return .finish(result, out)
        }
    }

    // MARK: - The start

    /// Build the game and run its first pass. It cannot be built: a play game returns as if the level select were
    /// cancelled, a film as if its film failed to load.
    private mutating func startGame(_ start: SessionStart, keys: HeldKeys, ticks: UInt32,
                                    state: inout FrontEndState) -> ScreenStep<Result> {
        do {
            try state.startGame(start, ticks: ticks)
        } catch {
            return isFilm ? comeBack(.filmLoadFailed(startSector: 0), gameRan: true, state: &state)
                          : comeBack(nil, gameRan: false, state: &state)
        }
        step = .game
        return .stay(state.gamePass(keys: keys, ticks: ticks))
    }

    // MARK: - The return

    /// R1 (`10023674..10023838`). [`10005b00..10005b18` Last Film: the front end's `gamePass`, section S5's.]
    private mutating func comeBack(_ result: SessionResult?, gameRan: Bool,
                                   state: inout FrontEndState) -> ScreenStep<Result> {
        self.result = result
        var out = PassOutput()
        var qualifies = false
        if gameRan {
            qualifies = gates(result, state: &state)
        } else {
            out.music.append(.stop)                                   // 10023768..10023774 (play mode only)
        }
        if gameRan { out.ops.append(.fade(.toBlack, .gameLayout)) }   // 1002378c FUN_1000b9a0(D, 1)
        out.ops += Self.backIntoBoth                                  // 10023794..10023818
        out.ops.append(.fade(.fromBlack, .fullScreen))                // 10023834 FUN_1000ba70(D, 0)
        // 1002383c..1002386c: no cheat, not started later, not a film, no quit, a qualifier. The listing tests the cheat
        // (1002383c, the result's +0x15) and the quit flag (1002385c, r24 = b8 as 10023674 read it) a second time
        // here, though a qualifier (r23) is only ever set inside the gates, which both skip; kept as the listing has
        // them.
        let cheated = result?.cheated ?? false
        if !cheated && !startedLater && !isFilm && !state.quit && qualifies {
            step = .table
            return .stay(out)
        }
        if isFilm { return menuReturn(tran: false, state: &state, &out) }   // no tran: nothing waits for a later pass
        step = .menu
        return .stay(out)
    }

    /// The gates (`10023674..10023764`): pref 3 and whether a present player qualifies for the table.
    private func gates(_ result: SessionResult?, state: inout FrontEndState) -> Bool {
        guard !state.quit, let result, !result.cheated else { return false }    // 10023674..1002368c b8, +0x15
        var best: Int32 = -1                                          // 10023698
        var qualifies = false
        let last = state.prefs.highScores[HighScoreTable.rowCount - 1]
        // A slot with no score or level in the result counts as HighScoreTable.insert counts it: no score → absent,
        // no level → a level not in the order.
        for p in 0..<2 where result.present.indices.contains(p) && result.present[p]       // 100236a8
            && result.scores.indices.contains(p) {
            let score = result.scores[p]
            if score > 0 {                                            // 100236bc
                let level = result.levels.indices.contains(p) ? result.levels[p] : .none
                let sector = Int32(state.assets.levelOrder.sector(of: level) ?? 0)   // FUN_10011e30
                if sector > best { best = sector }                    // 100236d0 cmpw
            }
            if !qualifies && score > last { qualifies = true }        // 100236dc..100236f8 FUN_10021470
        }
        if !result.allLevels { best -= 1 }                            // 10023710..10023720
        if best < 1 { best = 1 }                                      // 10023724..1002372c
        if !isFilm && !startedLater && best > state.prefs.intPrefs[3] {   // 10023730..10023750 FUN_10004f00(3)
            state.prefs.intPrefs[3] = best                            // 1002375c FUN_10004ac0(3, best)
        }
        return qualifies
    }

    /// 11a's first part (`10023870..100238a8`): `tran`, FlushEvents, the insertion and name entry.
    private mutating func table(state: inout FrontEndState, _ out: inout PassOutput) -> ScreenStep<Result> {
        out.sounds.append(Self.tran(priority: 0x32, state))          // 10023870..10023888
        // 10023890 FlushEvents: this pass's queued input reached this step (its first) and goes no further.
        // [10023898 About on: empty in X, D9.]
        step = .tableMenu
        // Invariant: `.table` is set only by `comeBack` when `gates` returned true, which needs a non-nil result.
        guard let result else { preconditionFailure("StartReturn: the table path with no result") }
        let insertion = HighScoreTable.insert(result, into: state.prefs, assets: state.assets)   // FUN_100214c0
        var entry: NameEntry
        switch (insertion.slots[0], insertion.slots[1]) {
        case let (s1?, s2?):
            entry = NameEntry(player: 0, slot: s1, prefs: insertion.prefs)
            entry.player2Slot = s2
        case let (s1?, nil):
            entry = NameEntry(player: 0, slot: s1, prefs: insertion.prefs)
        case let (nil, s2?):
            entry = NameEntry(player: 1, slot: s2, prefs: insertion.prefs)
        case (nil, nil):                                              // a qualifier always keeps one row
            // Invariant: `gates` qualified a present slot whose score beats row 15, and insert gives that slot a row.
            preconditionFailure("StartReturn: a qualifier with no table row")
        }
        return .call(.nameEntry(entry), out)
    }

    /// 11b (`10023978..10023ae4`), finishing with the result.
    private mutating func menuReturn(tran: Bool, state: inout FrontEndState,
                                     _ out: inout PassOutput) -> ScreenStep<Result> {
        out.ops += Self.backIntoBoth                                  // 10023980..100239ec
        out.ops.append(.present(.fullScreen))                         // 100239f8 FUN_1000bc60
        if tran { out.sounds.append(Self.tran(priority: 0x32, state)) }   // 10023a00..10023a20 (not a film)
        out.ops += Self.backIntoBoth                                  // 10023a30..10023a88 (X: no menu bar, D7)
        out.ops += menuFadeInAndRedraw(state: &state)                 // 10023a90..10023aa0
        out.requests.append(.showCursor)                              // 10023ad0 FUN_1000b780 (About on: D9)
        if !isFilm { state.menuMusic = true }                         // 10023ad8..10023ae4 b6 = 1
        return .finish(result, out)
    }

    /// `FUN_10024a00(0)` (every button unlit), `FUN_10025840` (the element fade-in of the list as last built) and
    /// `FUN_10024810(0)` (the redraw: the back buffer restored from the save buffer, the list drawn once, a full
    /// present) — the menu's (`MainMenu.redraw`), with no list nothing to draw.
    private func menuFadeInAndRedraw(state: inout FrontEndState) -> [RenderOp] {
        state.menuLit = nil
        let list = state.menuElements
        var ops = list.fadeIn(rate: Self.fadeRate(state), text: state.text, assets: state.assets)
        guard list.count > 0 else { return ops }
        ops.append(.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false))
        ops += list.drawOnce(restoreText: false, present: false, text: state.text, assets: state.assets)
        ops.append(.present(.fullScreen))
        return ops
    }

    // MARK: - The direct start (ruling 10; G12's path, unchanged)

    /// The direct start: its game (the first one already built, provisionally) with the cursor hidden on the pass
    /// that starts it; when it has ended, its result with no ops. A game that cannot be built: an ended game with no
    /// ops, tried again on the next pass.
    private mutating func directPass(_ start: SessionStart, keys: HeldKeys, ticks: UInt32,
                                     state: inout FrontEndState) -> ScreenStep<Result> {
        if step == .game {
            guard state.gameRunning else { return .finish(state.game?.session.result, PassOutput()) }
            return .stay(state.gamePass(keys: keys, ticks: ticks))
        }
        let prebuilt = state.game.map { $0.provisional && !$0.begun } ?? false
        if !prebuilt {
            do {
                try state.startGame(start, ticks: ticks)
            } catch {
                return .stay(PassOutput(sessionEnded: true))
            }
        }
        step = .game
        var out = state.gamePass(keys: keys, ticks: ticks)
        out.requests.insert(.hideCursor, at: 0)                       // 10023550 FUN_1000b6e0
        return .stay(out)
    }

    // MARK: - Helpers

    /// TGA `back` into the back and save buffers (`FUN_10020da0`, `FUN_10009fd0` × 2), as the menu's entry draws it.
    static let backIntoBoth: [RenderOp] = [
        .loadImage(image: FourCC("back")!, into: .back, dst: MacRect(top: 0, left: 0, bottom: 480, right: 640)),
        .loadImage(image: FourCC("back")!, into: .terrain, dst: MacRect(top: 0, left: 0, bottom: 480, right: 640)),
    ]
    static let ammu = FourCC("ammu")!

    /// gaso 3 `InterfaceTransition` (`FUN_10047670(id, priority, 100, 1)`).
    static func tran(priority: Int32, _ state: FrontEndState) -> SoundCue {
        SoundPlay.perm(state.assets.sounds[3], priority: priority, volume: 100, allowMultiple: true)
    }

    private static func fadeRate(_ state: FrontEndState) -> UInt32 { ElementList.fadeRate(floats: state.assets.floats) }
}
