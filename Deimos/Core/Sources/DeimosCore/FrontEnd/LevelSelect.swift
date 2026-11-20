import Foundation
import HectorResources

/// The level select — `FUN_1002e310(&sector)` (grounding A §3; X rows in `osx-build.md`: the level select differs
/// only by D10's event pump, the two draws are the same; ruling 14: its own bare `GameState` for the frame
/// controller, the console and the pause). Phase 4 S3b.
///
/// **Frozen entry.** `init()` — the original's only argument is the result pointer; what it reads (pref 3, the
/// highest sector reached; pref 8, the Esc hold) is in `FrontEndState.prefs`. **Returns** the chosen sector (1…12),
/// or nil when it was left with Esc (the original's `'none'`) — the sector only: the session's "music already
/// playing" flag (`SessionStart.musicAlreadyPlaying`, which the plan has the level select pass, its `ammu` still
/// playing) is set by start/return (S3a) when it builds the game's `SessionStart` from this result.
///
/// **How it is built.** It runs on the FRAME CONTROLLER (A §3, risk 9): one pass is one frame of the original's loop
/// (`FUN_10030360` begin frame … `FUN_10030570(ctrl, 0, 1)` end frame), so every count here — the 16-step flash, the
/// 40-frame message hold, the 16th held frame of Esc — is in frames, never ticks.
/// - **Entry pass** (`1002e310..1002e868`): the set-up, one draw with the hover off, the end frame with no present
///   (`FUN_10030570(ctrl, 0, 0)`), the fade in (`FUN_1000ba70(D, 0)`), ShowCursor (`FUN_1000b730`).
/// - **Each later pass**: begin frame (Caps Lock, Esc, console, volume keys, F6 — `FrameKeys`); on the tick
///   (every frame: no code writes the divider) the save → back restore, the flash step, the notice, the input, the
///   draw `FUN_1002f3c0`; then the message fade `FUN_1002ef10` and the end frame (present; the pause screen).
/// - **Exit** (`1002ee30..`): Esc (begin frame's quit) at once, or the accept flash over (mode 0) before drawing
///   (`1002ee10`, D:27569 — the flash's last step is never drawn or presented): the fade to black, and HideCursor
///   (`FUN_1000b6e0`) when a sector was chosen.
///
/// Not modelled: the level-select-active byte `0x100e01fd` (read only by the console's ⏎ path to choose the ISp
/// restore — no visible effect); X's background event pump after each begin frame (D10: it reads no keys or clicks
/// the level select uses; Quit and app switching are the front end's and the driver's — a Quit outside the pause is
/// not read here, D10).
///
/// **Quit inside the pause** (X `10023228..10023244`, `10030cb8`): the driver lets the pause's wait go on the quit
/// flag b8 without the music resume and sets `FrontEndState.quit`; `FrontEnd.quitDuringPause` reaches only a game's
/// controller, so the level select reads the flag itself on the pass after its pause: the controller's +2, no resume
/// (`10022fb0`), and that pass's begin frame reports quit — the level select leaves as with Esc ('none').
public struct LevelSelect: Sendable {
    public typealias Result = Int?

    /// One preview record (`FUN_1004d320(0x2c8)`): sector `+0x000`, the level info `+0x004`, x `+0x28c`, y
    /// `+0x290`, the preview picture `+0x294`, reachable `+0x2c4` (`+0x2c5`, the unregistered cut, is 0 in the
    /// registered build).
    struct Preview: Equatable, Sendable {
        var sector: Int
        var name: String
        var description: String
        var image: FourCC
        var x: Int32
        var y: Int32
        var width: Int32
        var height: Int32
        var reachable: Bool

        /// The preview rect `FUN_1002f7a0` draws into: the picture's bounds moved to (x, y) (`1002f7d4..1002f828`).
        var rect: MacRect { MacRect(top: y, left: x, bottom: y &+ height, right: x &+ width) }
    }

    /// One button record (`local_424` / `local_448` / `local_46c`): hover `+0x00`, hit rect `+0x04` (`reli`),
    /// face `+0x14`, frame `+0x18`, x `+0x1c`, y `+0x20`.
    struct Button: Equatable, Sendable {
        var hover = false
        var rect: MacRect
        var face: FourCC
        var frame: Int
        var x: Int32
        var y: Int32
    }

    /// The message record (`local_2b8`, 0x20c bytes): time `+0x000`, text `+0x004`, the level text kept to restore
    /// `+0x104`, active `+0x204`, colour `+0x206`, blend `+0x208`.
    struct Message: Equatable, Sendable {
        var time: Int32 = 0
        var text: [UInt8]
        var backup: [UInt8]
        var active = false
        var colour: UInt16 = 0x7fff
        var blend: Int32 = 0
    }

    /// The flash record (`PTR_DAT_100df3b4`): mode `+0x0` (0 off, 1 accept, 2 refused), colour `+0x2`, alpha
    /// `+0x4`, scale `+0x8`, growing `+0xc`. Reset (`FUN_1002fc90`, `1002fc90..1002fcbc`): 0, 0x7fff, 32, 1.0, 0.
    struct Flash: Equatable, Sendable {
        var mode: UInt8 = 0
        var colour: UInt16 = 0x7fff
        var alpha: Int32 = 32
        var scale: Float = 1
        var growing = false
    }

    /// `0x100d70dc` / `0x100d70e0` (`PTR_DAT_100df3a0`): the flash's rest scale and the centring half.
    static let restScale: Float = 1.0
    static let half: Float = 0.5
    static let lese = FourCC("lese")!
    static let costFace = FourCC("COST")!
    static let screen = MacRect(top: 0, left: 0, bottom: 480, right: 640)

    enum Phase: Equatable, Sendable {
        case entry
        case running
    }

    private(set) var phase = Phase.entry
    private(set) var game: GameState?
    private var console: Console?
    private(set) var controller = FrameController(fpsMaxRate: 30)
    /// `iVar18`: the middle preview's index (sector − 1).
    private(set) var index = 0
    private(set) var previews: [Preview] = []
    private(set) var buttons: [Button] = []
    private(set) var message = Message(text: [], backup: [])
    private(set) var flash = Flash()
    /// `0x100e01fe`: a sector was accepted.
    private(set) var accepted = false
    /// `bVar1` / `bVar2` / `bVar3`: the accept, left and right edge latches.
    private var acceptLatch = false
    private var leftLatch = false
    private var rightLatch = false
    /// `iVar17`: the level select's own frame count, the notice's clock.
    private(set) var frameCount: Int32 = 0
    /// The video grid's tile (gasp 0 `vigr`, frame fctiwz(flli 84)) size, `FUN_10019ca0` (read once).
    private var tile: (w: Int32, h: Int32) = (0, 0)
    private var imageSizes: [FourCC: (Int32, Int32)] = [:]
    /// The last pass ended in the pause screen's wait (`.pauseWait`).
    private var pausedLastPass = false

    public init() {}

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        switch phase {
        case .entry:
            return .stay(enter(keys: keys, ticks: ticks, state: &state))
        case .running:
            return frame(keys: keys, ticks: ticks, state: &state)
        }
    }

    // MARK: - Entry (1002e310..1002e868)

    private mutating func enter(keys: HeldKeys, ticks: UInt32, state: inout FrontEndState) -> PassOutput {
        let a = state.assets
        var g = GameState(assets: a, prefs: state.prefs, seed: 0)                    // ruling 14
        var con: Console
        do { con = try Console(assets: a) } catch {                                  // the shipped data always loads
            preconditionFailure("LevelSelect: the console does not load (\(error))")
        }
        var ops: [RenderOp] = []
        flash = Flash()                                                              // 1002e344 FUN_1002fc90
        // FUN_10009d70: the save buffer re-made 640×480 — `.loadTerrain(lese)` below (lese is 640×480).
        accepted = false                                                             // 1002e39c
        index = 0                                                                    // 1002e3b0..1002e3b8: r31,
        rightLatch = false                                                           // r30, r29 = iVar18, bVar3,
        frameCount = 0                                                               // iVar17
        acceptLatch = false                                                          // 1002e838 (bVar1)
        leftLatch = false                                                            // 1002e83c (bVar2)
        g.notice.reset()                                                             // FUN_10018130
        let f = a.floats
        func fl(_ i: Int) -> Int32 { EntityDraw.fctiwz(f[i]) }
        buttons = [                                                                  // reli 18–20, gasp 6
            Button(rect: a.rects[18], face: a.sprites[6], frame: Int(fl(96)), x: fl(90), y: fl(91)),
            Button(rect: a.rects[19], face: a.sprites[6], frame: Int(fl(97)), x: fl(92), y: fl(93)),
            Button(rect: a.rects[20], face: a.sprites[6], frame: Int(fl(99)), x: fl(94), y: fl(95)),
        ]
        controller = FrameController(fpsMaxRate: fl(32))                             // FUN_10030190
        ops.append(.clearLayers)                                                     // FUN_10030210 → FUN_100189f0
        FrameKeys.startSession(controller: &controller, console: &con, game: &g, filmPlayback: false,
                               gameScreenLayout: false, autoInterlaceAllowed: false, ticks: ticks)   // 1002e554
        ops.append(.fill(.back, colour: 0))                                          // FUN_10009f00(back, black)
        ops.append(.loadImage(image: Self.lese, into: .back, dst: Self.screen))      // FUN_10020da0 + FUN_10009fd0
        ops.append(.loadTerrain(image: Self.lese))                                   // FUN_10009fd0(tga, save)
        message = Message(text: Array("Not Inited".utf8), backup: Array("Not Inited".utf8))   // 1002e5e8..1002e61c
        ops.append(.copy(from: .back, to: .terrain, src: nil, dst: nil, interlaced: false))  // FUN_10009fd0(back, save)
        let n = a.levelOrder.levels.count                                            // FUN_10011de0, asserts ≥ 3
        precondition(n >= 3, "LevelSelect: numLevels > kPriv_NumPreviews (G_LevelSelection.cc 0x117)")
        let grid = try? a.spriteGroup(a.sprites[0])
        if let fr = grid?.frames, fr.indices.contains(Int(fl(84))) {
            tile = (Int32(fr[Int(fl(84))].width), Int32(fr[Int(fl(84))].height))
        }
        previews = (0..<3).map { i in                                                // 1002e700..1002e778
            Preview(sector: 0, name: "", description: "", image: .none,
                    x: fl(39) &+ Int32(i) &* fl(41), y: fl(40) &+ Int32(i) &* fl(42), width: 0, height: 0,
                    reachable: false)
        }
        fill(sector: 1, state: state, ops: &ops)                                     // FUN_1002efb0(list, 1, 1, …)
        draw(hover: false, paused: false, keys: keys, game: &g, state: state, ops: &ops)   // FUN_1002f3c0(…, 0, 0)
        let pause = endFrame(present: false, keys: keys, ticks: ticks, text: state.text,
                             game: &g, console: &con, ops: &ops)
        ops.append(.fade(.fromBlack, .fullScreen))                                   // FUN_1000ba70(D, 0)
        console = con
        phase = .running
        var out = output(ops: ops, game: &g, pause: pause)
        out.requests.append(.showCursor)                                             // FUN_1000b730
        state.prefs = g.prefs
        game = g
        return out
    }

    // MARK: - One frame (1002e86c..1002ee2c)

    private mutating func frame(keys: HeldKeys, ticks: UInt32,
                                state: inout FrontEndState) -> ScreenStep<Result> {
        guard var g = game, var con = console else { preconditionFailure("LevelSelect: no frame before the entry") }
        game = nil
        defer { state.prefs = g.prefs; game = g; console = con }
        if pausedLastPass && state.quit {                                            // the wait let go on b8
            controller.quitChosen = true                                             // X 10030cb8 (+0x02)
            g.cues.music.removeAll { $0 == .resume }                                 // 10022fb0: no FUN_10048220(0)
        }
        pausedLastPass = false
        var ops: [RenderOp] = [.clearLayers]                                         // 10030388 FUN_100189f0
        let begin = FrameKeys.beginFrame(controller: &controller, console: &con, game: &g, keys: keys)
        if begin.quit {                                                              // 1002ee28: 'none'
            return leave(nil, ops: &ops, game: &g)
        }
        if begin.tick {
            if !accepted {                                                           // FUN_10009fd0(save, back)
                ops.append(.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false))
            }
            stepFlash(floats: state.assets.floats)                                   // FUN_1002fcc0
            g.notice.tick(gameTime: frameCount, rng: &g.rng, cues: &g.cues)          // FUN_10018320(iVar17)
            let paused = controller.paused                                           // FUN_10030900
            if !paused { g.notice.post(nil, now: frameCount) }                       // FUN_100181e0(0, iVar17)
            if !accepted {
                if !con.isOpen {                                                     // FUN_1002d190
                    input(keys: keys, game: &g, state: state, ops: &ops)
                }
            } else if flash.mode == 0 {                                              // 1002ee10: before drawing
                return leave(index + 1, ops: &ops, game: &g)
            }
            draw(hover: true, paused: paused, keys: keys, game: &g, state: state, ops: &ops)
            frameCount &+= 1
        }
        messageFade(framesPresented: controller.framesPresented, floats: state.assets.floats)   // FUN_1002ef10
        let pause = endFrame(present: true, keys: keys, ticks: ticks, text: state.text,
                             game: &g, console: &con, ops: &ops)
        pausedLastPass = pause != nil
        return .stay(output(ops: ops, game: &g, pause: pause))
    }

    /// `1002ee30..`: the fade to black (`FUN_1000b9a0(D, 0)`), the controller's end (`FUN_100302b0`: FlushEvents —
    /// the next screen reads its own queue), HideCursor when a sector was chosen; `*sector` = index + 1.
    private mutating func leave(_ result: Int?, ops: inout [RenderOp],
                                game g: inout GameState) -> ScreenStep<Result> {
        ops.append(.fade(.toBlack, .fullScreen))
        var out = output(ops: ops, game: &g, pause: nil)
        if result != nil { out.requests.append(.hideCursor) }                        // FUN_1000b6e0
        return .finish(result, out)
    }

    /// The pass's output: its ops and the cues it collected. A pause's resume (`PauseScreen.musicAfterWait`) is
    /// left for the next pass, first in its music (as the session does).
    private func output(ops: [RenderOp], game g: inout GameState, pause: PauseScreen?) -> PassOutput {
        let cues = g.cues
        g.cues = CueBuffer()
        if let pause { g.cues.music = pause.musicAfterWait }                          // 10022fb4, after the wait
        return PassOutput(ops: ops, sounds: cues.sounds, music: cues.music, haltEffectsAt: cues.haltEffectsAt)
    }

    // MARK: - Input (1002e89c..1002ed08)

    private mutating func input(keys: HeldKeys, game g: inout GameState, state: FrontEndState,
                                ops: inout [RenderOp]) {
        let a = state.assets
        let p = KeyTable(prefs: g.prefs).input(keys, player: 0)                      // FUN_1004ab50(0, buf)
        var right = p.contains(.right), left = p.contains(.left)                     // [1], [3]
        var fireGround = p.contains(.fireGround)                                     // [4]
        let fireAir = p.contains(.fireAir), select = p.contains(.select)             // [5], [6]
        func fl(_ i: Int) -> Int { Int(EntityDraw.fctiwz(a.floats[i])) }
        let reachable = previews[1].reachable                                        // FUN_1002fc60(list): element 1
        // `<` (local_424), `>` (local_46c), START (local_448): hover → gasp 7 `mebh`, else gasp 6 `mebu`.
        if hit(0, keys: keys, game: &g, state: state), keys.mouseButton { left = true }    // FUN_10048e60 Button()
        buttons[0].face = a.sprites[buttons[0].hover ? 7 : 6]; buttons[0].frame = fl(96)
        if hit(2, keys: keys, game: &g, state: state), keys.mouseButton { right = true }
        buttons[2].face = a.sprites[buttons[2].hover ? 7 : 6]; buttons[2].frame = fl(99)
        if hit(1, keys: keys, game: &g, state: state), keys.mouseButton { fireGround = true }
        buttons[1].face = a.sprites[buttons[1].hover ? 7 : 6]
        // START 10 / NO ACCESS 11 from the middle as it stands BEFORE this frame's move (1002eaa0..1002eacc read
        // FUN_1002fc60 first): the frame of a move still shows the old middle's — a one-frame lag, as the binary.
        buttons[1].frame = fl(reachable ? 97 : 98)
        if !select && !fireGround && !fireAir {                                      // 1002eae0..
            acceptLatch = false
            var moved = false
            let n = a.levelOrder.levels.count
            if left {
                if !leftLatch {
                    if flash.mode != 0 { flash = Flash() }                           // FUN_1002fc90
                    index -= 1
                    if index < 0 { index = n - 1 }
                    moved = true
                }
                leftLatch = true
            } else {
                leftLatch = false
            }
            if right {
                if !rightLatch {
                    if flash.mode != 0 { flash = Flash() }
                    index += 1
                    if index >= n { index = 0 }
                    moved = true
                }
                rightLatch = true
            } else {
                rightLatch = false
            }
            if moved {
                g.cues.sounds.append(SoundPlay.perm(a.sounds[13], priority: 0x32, volume: 100, allowMultiple: true))
                fill(sector: index + 1, state: state, ops: &ops)                     // FUN_1002efb0
            }
        } else if !acceptLatch {
            acceptLatch = true
            if !reachable {                                                          // 1002ec64..1002ed08
                g.cues.sounds.append(SoundPlay.perm(a.sounds[14], priority: 0x32, volume: 100, allowMultiple: true))
                message.time = controller.framesPresented                           // FUN_10030350
                message.text = Array(g.assets.gameStrings[4].prefix { $0 != 0 })     // pgsl 4 (+0x2c5 = 0)
                let f26 = a.formats[26]                                              // `lsfa`
                message.active = f26.coloriseDo                                      // +0x120
                message.colour = f26.coloriseColor                                   // +0x122
                message.blend = f26.blendAmount                                      // +0x114
                startFlash(2, formats: a.formats)
            } else {                                                                 // 1002ec24..1002ec5c
                g.cues.sounds.append(SoundPlay.perm(a.sounds[12], priority: 0x32, volume: 100, allowMultiple: true))
                if !accepted {
                    startFlash(1, formats: a.formats)
                    accepted = true
                }
            }
        }
    }

    /// `FUN_1002ff30(button, mouse)`: inside the hit rect (inclusive, the mouse local to the picture) → hover; on
    /// entry gaso 11 `mbro` (0x4b, 100, 0).
    private mutating func hit(_ i: Int, keys: HeldKeys, game g: inout GameState, state: FrontEndState) -> Bool {
        let was = buttons[i].hover
        let r = buttons[i].rect
        var now = false
        if let m = keys.mouse {
            now = r.left <= m.h && m.h <= r.right && r.top <= m.v && m.v <= r.bottom
        }
        buttons[i].hover = now
        if now && !was {
            g.cues.sounds.append(SoundPlay.perm(state.assets.sounds[11], priority: 0x4b, volume: 100,
                                                allowMultiple: false))
        }
        return now
    }

    // MARK: - The previews (FUN_1002efb0)

    /// `FUN_1002efb0(list, sector, 1, &message, &tag)`: save → back; per preview the sector (middle = `sector`,
    /// its neighbours wrapping 1 ↔ 12), the level info, reachable (registered: sector ≤ int pref 3), the picture;
    /// the middle one's description into the message text and its keep-copy, the message off.
    private mutating func fill(sector: Int, state: FrontEndState, ops: inout [RenderOp]) {
        let a = state.assets
        ops.append(.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false))
        let n = a.levelOrder.levels.count
        let highest = Int(state.prefs.intPrefs[3])
        for i in previews.indices {
            var s = sector
            if i > 1 { s = sector + 1; if s > n { s = 1 } }
            if i < 1 { s = sector - 1; if s < 1 { s = n } }
            let tag = a.levelOrder.level(sector: s)
            let info = a.definitions.levels.first { $0.id == tag } ?? LevelDefinition()
            previews[i].sector = s
            previews[i].name = info.name
            previews[i].description = info.description
            previews[i].reachable = s <= highest                                     // FUN_10004f00(3)
            previews[i].image = info.previewImage
            let (w, h) = imageSize(info.previewImage, assets: a)
            previews[i].width = w
            previews[i].height = h
            if i == 1 {
                let d = MacRoman.encode(info.description, lossy: true) ?? []
                message.text = d                                                    // param_4 + 4
                message.backup = d                                                  // param_4 + 0x104
                message.active = false                                              // param_4 + 0x204
            }
        }
    }

    private mutating func imageSize(_ id: FourCC, assets a: DeimosAssets) -> (Int32, Int32) {
        if let s = imageSizes[id] { return s }
        var s: (Int32, Int32) = (0, 0)
        if let r = a.index.record(type: FourCC("im16")!, id: id), let data = try? a.index.data(for: r),
           let tga = try? TGAImage(data: data) {
            s = (Int32(tga.width), Int32(tga.height))
        }
        imageSizes[id] = s
        return s
    }

    // MARK: - The flash (FUN_1002fe40, FUN_1002fcc0) and the message fade (FUN_1002ef10)

    /// `FUN_1002fe40(mode)`: mode 1 → format 27 `lsca`, mode 2 → 28 `lscf`: scale 1.0, growing, colour `+0x122`,
    /// alpha `+0x114` (16).
    private mutating func startFlash(_ mode: UInt8, formats: [TextFormat]) {
        let f = formats[mode == 1 ? 27 : 28]
        flash.mode = mode
        flash.scale = Self.restScale
        flash.growing = true
        flash.colour = f.coloriseColor
        flash.alpha = f.blendAmount
    }

    /// `FUN_1002fcc0` (`1002fcc0..1002fe38`): alpha + 1 to 32; the scale grows by flli 44 / 46 (`fadds`) to flli 45 /
    /// 47 (`fcmpo`, ≥), then shrinks (`fsubs`) to 1.0 (≤); at scale 1.0 and alpha 32 the reset.
    private mutating func stepFlash(floats f: [Float]) {
        guard flash.mode != 0 else { return }
        if flash.alpha != 32 {
            flash.alpha &+= 1
            if UInt32(bitPattern: flash.alpha) > 32 { flash.alpha = 32 }
        }
        var step: Float = 0, top: Float = 0
        if flash.mode == 2 { step = f[46]; top = f[47] } else if flash.mode == 1 { step = f[44]; top = f[45] }
        if flash.growing {
            flash.scale = flash.scale + step
            if flash.scale >= top { flash.scale = top; flash.growing = false }
        } else {
            flash.scale = flash.scale - step
            if flash.scale <= Self.restScale { flash.scale = Self.restScale }
        }
        if flash.scale == Self.restScale && flash.alpha == 32 { flash = Flash() }
    }

    /// `FUN_1002ef10(&message, framesPresented)`: after flli 43 (40) frames (`time + 40 < now`, unsigned), blend + 1
    /// a frame; past 31 → 32, off, the level text back.
    private mutating func messageFade(framesPresented now: Int32, floats f: [Float]) {
        let hold = EntityDraw.fctiwz(f[43])
        guard UInt32(bitPattern: message.time &+ hold) < UInt32(bitPattern: now), message.active else { return }
        message.blend &+= 1
        if UInt32(bitPattern: message.blend) > 0x1f {
            message.blend = 32
            message.active = false
            message.text = message.backup
        }
    }

    // MARK: - Drawing one frame (FUN_1002f3c0, FUN_1002f7a0, FUN_10006240)

    /// `FUN_1002f3c0(list, 1, &message, <, START, >, hover, paused)`: the notice; the three previews; the name (or
    /// the message) and the number; the three buttons (START skipped while paused).
    private mutating func draw(hover: Bool, paused: Bool, keys: HeldKeys, game g: inout GameState,
                               state: FrontEndState, ops: inout [RenderOp]) {
        let a = state.assets
        ops += g.notice.drawCommands(text: state.text, formats: a.formats).map { .draw($0) }   // FUN_100184b0
        for i in previews.indices {
            drawPreview(i, middle: i == 1, hover: hover, keys: keys, assets: a, ops: &ops)
        }
        for t in textRequests(assets: a) { ops += state.text.draw(t).map { .draw($0) } }       // FUN_1000d380 × 2
        for (i, b) in buttons.enumerated() where !(i == 1 && paused) {
            // The level select's template 0x100eaddc, the game's 0x100e63e4 and the grid's 0x100e3ad0 are byte-identical
            // over their 0x4c bytes (data image) with the same static-init clip {0,0,480,416}: `.template` is exact.
            var c = DrawCommand.template                                             // 0x100eaddc
            c.clip = EntityDraw.backBufferBounds                                     // FUN_1000a530(back)
            c.face = b.face
            c.frame = b.frame
            c.x = b.x
            c.y = b.y
            c.layer = 15
            if b.hover { c.scale = a.floats[100] } else { c.flags = 0; c.alpha = 0 }  // flli 100 (1.1)
            ops.append(.draw(c))                                                     // FUN_10018a40: queued
        }
    }

    /// The name — or, while the message is on, the message with colourise, its colour and blend — in format 25
    /// `lsde` (reachable) or 24 `lsna`; then the number `"%0.2i"` in 22 `lsnu` / 23 `lsnn`. Both queued (+0x110 = 0).
    func textRequests(assets a: DeimosAssets) -> [TextRequest] {
        let mid = previews[1]
        var name: TextRequest
        if message.active {
            name = TextRequest(format: a.formats[mid.reachable ? 25 : 24], text: message.text)
            name.format.coloriseDo = true                                            // +0x120
            name.format.coloriseColor = message.colour                               // +0x122
            name.format.blendAmount = message.blend                                  // +0x114
        } else {
            name = TextRequest(format: a.formats[mid.reachable ? 25 : 24], text: mid.name)
        }
        name.drawNow = false
        let digits = String(mid.sector)
        var number = TextRequest(format: a.formats[mid.reachable ? 22 : 23],
                                 text: digits.count < 2 ? "0" + digits : digits)     // 0x100eb032 "%0.2i"
        number.drawNow = false
        return [name, number]
    }

    /// `FUN_1002f7a0(preview, middle, hover)`.
    private func drawPreview(_ i: Int, middle: Bool, hover: Bool, keys: HeldKeys, assets a: DeimosAssets,
                             ops: inout [RenderOp]) {
        let p = previews[i]
        let r = p.rect
        // The hover strip, drawn now: clip = the back buffer's bounds (L 1002f920..1002f934 / X 1002fd00..1002fd14),
        // so it shows on all three previews — corrects plan ruling 15 / grounding A risk 7 (seat ruling 2026-11-20).
        if !accepted && hover, let m = keys.mouse,
           r.left <= m.h && m.h <= r.right && r.top <= m.v && m.v <= r.bottom {      // 1002f854..1002f8dc
            let f29 = a.formats[29]                                                  // `lsbo`
            var c = DrawCommand.template
            c.clip = EntityDraw.backBufferBounds
            c.face = Self.costFace
            c.frame = 0
            c.drawNow = true                                                         // 1002f998 (+0x31)
            c.costRect = MacRect(top: r.top &+ f29.locY, left: r.left &+ f29.locX,
                                 bottom: r.bottom &- f29.locY, right: r.right &- f29.locX)
            c.costColour = f29.coloriseColor                                         // +0x122
            c.alpha = UInt32(bitPattern: f29.blendAmount)                            // +0x114
            ops.append(.draw(c))                                                     // FUN_10018a40 → now
        }
        if middle && flash.scale != Self.restScale {                                 // 1002f9e4..1002f9f4 fcmpu
            // The opaque scaled copy FUN_1001d1b0 (1002f9f8..1002fb80): w′ = trunc(w·s), h′ = trunc(h·s), centred.
            let s = flash.scale
            let fw = Float(p.width) * s, fh = Float(p.height) * s                    // fmuls
            let cx = Float(r.left &+ p.width / 2), cy = Float(r.top &+ p.height / 2)
            let left = EntityDraw.fctiwz(-((-cx).addingProduct(fw, Self.half)))      // fnmsubs
            let top = EntityDraw.fctiwz(-((-cy).addingProduct(fh, Self.half)))
            let dst = MacRect(top: top, left: left, bottom: top &+ EntityDraw.fctiwz(fh),
                              right: left &+ EntityDraw.fctiwz(fw))
            ops.append(.scaledCopy(image: p.image, into: .back, dst: dst, clip: r))
            if flash.alpha != 32 {                                                   // 1002fb88..1002fc10
                var c = DrawCommand.template                                         // the template clip {0,0,480,416}
                c.face = Self.costFace
                c.alpha = UInt32(bitPattern: flash.alpha)
                c.drawNow = true
                c.costColour = flash.colour
                c.costRect = r
                ops.append(.draw(c))                                                 // FUN_10019570: now
            }
        } else {
            ops.append(.loadImage(image: p.image, into: .back, dst: r))              // FUN_10009fd0(preview, back)
        }
        ops += Self.grid(over: r, tile: tile, face: a.sprites[0], frame: Int(EntityDraw.fctiwz(a.floats[84])))
    }

    /// `FUN_10006240(rect, 0, 0)`: gasp 0 `vigr` frame flli 84 tiled over the rect, rows outer: (h / th + 1) rows
    /// of (w / tw + 1) tiles from the centre (left + tw/2, top + th/2), clip = the rect, layer 15, queued
    /// (template 0x100e3ad0, +0x31 = 0).
    static func grid(over r: MacRect, tile: (w: Int32, h: Int32), face: FourCC, frame: Int) -> [RenderOp] {
        guard tile.w > 0, tile.h > 0 else { return [] }
        var c = DrawCommand.template
        c.face = face
        c.frame = frame
        c.clip = r
        c.layer = 15
        c.drawNow = false
        let cols = (r.right &- r.left) / tile.w + 1, rows = (r.bottom &- r.top) / tile.h + 1
        var ops: [RenderOp] = []
        c.y = r.top &+ tile.h / 2
        for _ in 0..<max(rows, 0) {
            c.x = r.left &+ tile.w / 2
            for _ in 0..<max(cols, 0) {
                ops.append(.draw(c))
                c.x &+= tile.w
            }
            c.y &+= tile.h
        }
        return ops
    }

    // MARK: - End frame (FUN_10030570(ctrl, 0, present) → FUN_10030bc0)

    private mutating func endFrame(present: Bool, keys: HeldKeys, ticks: UInt32, text: TextLayout,
                                   game g: inout GameState, console con: inout Console,
                                   ops: inout [RenderOp]) -> PauseScreen? {
        let a = g.assets
        ops += g.messages.drawCommands(text: text, formats: a.formats).map { .draw($0) }   // 10030bec FUN_1002dea0
        if let fps = FrameKeys.fpsCounterRequest(controller: controller, prefs: g.prefs, formats: a.formats) {
            ops += text.draw(fps).map { .draw($0) }                                  // 10030bf4..10030c90
        }
        ops += con.drawCommands(text: text, formats: a.formats).map { .draw($0) }    // 10030c98 FUN_1002d410
        ops.append(.flushLayers(0...1))                                              // 10030ca4 (no terrain blit)
        ops.append(.flushLayers(2...5))                                              // 10030cc0 (no particles)
        ops.append(.flushLayers(6...15))                                             // 10030cdc
        if g.prefs.bytePrefs[10] != 0 { ops.append(.limit) }                         // 10030ce4..10030d24
        if present { ops.append(.present(.fullScreen)) }                             // 10030d90..10030db4 (+4 = 0)
        let pause = FrameKeys.endFrameWrapper(controller: &controller, console: &con, game: &g, keys: keys,
                                              ticks: ticks)
        if let pause { ops.append(.pauseWait(pause.present)) }                       // 10022ef0 (host waits)
        return pause
    }
}
