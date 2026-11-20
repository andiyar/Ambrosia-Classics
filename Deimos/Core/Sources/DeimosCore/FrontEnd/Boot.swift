import Foundation
import HectorResources

/// The boot — `FUN_100000e0` (grounding A §1, §9a items 1 and 7; Phase 4 S6 BT): the configuration window first when
/// asked, the publisher logo held until `publ` ends, the developer logo with `inmu`, the loading screen and its five
/// lines, every fade. The OS X build's boot is the same (X `100000e0` matches L instruction for instruction but for
/// TOC offsets; `osx-build.md` §2), and its loading line differs only by a suspend/resume pump (D17); the loading
/// lines' closing list fade is X's 16 passes (D1, ruling 5).
///
/// **Frozen entry.** `init()` — the boot reads everything it needs from `FrontEndState`: the launch modifiers
/// (Command = the quiet launch, Option = the configuration window), sound available, the prefs. **Returns** nothing
/// (`ScreenDone`); the front end then enters the main menu (`FUN_100000a0`).
///
/// **How it is built.** One pass per stretch the original runs between two points the replica must split at — a cue
/// that follows a fade (the driver sends a pass's cues when it begins), or a `TickCount` read that a later wait
/// counts from (the next pass's `ticks`, as the credits' timer):
/// 1. `100000fc..1000022c`: the toolbox, the managers and the prefs are the shell's and the frame's. Option
///    (`1000015c`, key 0x3A) held **or** byte pref 2 = 0 (`100001f0..10000204`) → the configuration window
///    `FUN_100047c0(1)` — called with 1 whichever asked (`10000214 li r3,0x1`) — and when it returns byte pref 2 ← 1
///    (`10000220..10000228` `FUN_10004ab0(2, 1)`), its own result unread. The display (`FUN_1000ae20`, byte pref 4)
///    and the sprite manager are the shell's. Then the 5-tick busy-wait (`FUN_10049820(5)`) and the fade to black
///    (`FUN_1000b9a0(D, 0)`).
/// 2. back ← black (`FUN_10009f00`), `pucr` copied centred (`FUN_1000a3b0`: left = (640 − w) / 2, top = (480 − h) / 2,
///    C division, `1000a3cc..1000a430`); with sound, the volume up then down (`FUN_10047a30`, `FUN_10047990`: each
///    tests the sound system itself — int pref 0 quantised to 90 or below); T1 = `TickCount` (`10000350`) — this
///    pass's tick; Command up and `publ` loaded (`FUN_10047330`: false without a sound system) → `publ` (0x32, 100,
///    multiple); the fade in (`FUN_1000ba70(D, 0)`); the sprite-cache policy (nothing here).
/// 3. Command up and sound available (`FUN_10047910`) → spin while `publ`'s voice lives (`FUN_100476e0`), no floor
///    and no cap (`100003b4..10000404`, A §9a item 7: the length is the mixer's — the host's `.voiceEnd`); else
///    (`10000408..10000430`) until `TickCount ≥ T1 + flli 66` (130; `do … while (now < T1 + n)`, unsigned). Then the
///    fade to black, port = back (no op), back ← black, PICT 1000 at (0, 0) (`FUN_10044c30(1000)`: the shell's
///    picture, ruling 9).
/// 4. Command up → `inmu` (`FUN_10047f90('inmu', 1, 0)`: loop, not paused; the music player does not test the sound
///    system); T2 = `TickCount` — this pass's tick; the fade in.
/// 5. Spin until `TickCount ≥ T2 + 240` (`100004b8..100004d4`); the fade to black; the text and message modules
///    (nothing here); back ← black; the `back` TGA into the back buffer and the save buffer (`FUN_10009fd0` × 2, whole
///    port rects); the fade in; the loaders and their loading lines (`10000590..100005e8`, `loadingLines`); the
///    lines' fade-out (`100005f0` `FUN_100232d0`). The waits are counted from the pass's tick, at which the host
///    reaches them.
/// 6. The return, a pass after the fade-out's waits (so the menu's cues follow it).
public struct Boot: Sendable {
    public typealias Result = ScreenDone

    enum Phase: Equatable, Sendable {
        /// Pass 1: the configuration window, the wait and the first fade.
        case start
        /// Pass 2: the publisher logo up.
        case publisher
        /// Pass 3: its hold, then the developer logo drawn.
        case publisherHold
        /// Pass 4: `inmu`, the developer logo up.
        case developer
        /// Pass 5: its hold, then the loading screen.
        case developerHold
        /// Pass 6: the return.
        case done
    }

    private(set) var phase = Phase.start
    /// T1 (`10000350`): the tick the publisher logo's hold counts from.
    private(set) var t1: UInt32 = 0
    /// T2 (`1000049c`): the tick the developer logo's hold counts from.
    private(set) var t2: UInt32 = 0
    /// `_DAT_100e01a4`: the loading lines' list (G_Interface), freed at the end (`FUN_100253d0`).
    private(set) var lines = ElementList()

    public init() {}

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        var out = PassOutput()
        let a = state.assets
        let quiet = state.launch.command                                // 1000016c: Command (0x37) held
        switch phase {
        case .start:
            if case .configDialog? = returned {
                state.prefs.bytePrefs[2] = 1                            // 10000228 FUN_10004ab0(2, 1)
            } else if state.launch.option || state.prefs.bytePrefs[2] == 0 {   // 100001f0..10000204
                return .call(.configDialog(ConfigDialog(firstLaunch: true)))   // 10000218 FUN_100047c0(1)
            }
            out.ops.append(.hostWait(.ticks(Self.firstWait)))           // 100002c0 FUN_10049820(5)
            out.ops.append(.fade(.toBlack, .fullScreen))                // 100002d4 FUN_1000b9a0(D, 0)
            phase = .publisher
        case .publisher:
            out.ops.append(.fill(.back, colour: 0))                     // 100002ec FUN_10009f00(back, black)
            let logo = Self.centred(Self.pucr, a)                       // 10000308..1000032c FUN_1000a3b0
            out.ops.append(.loadImage(image: Self.pucr, into: .back, dst: logo))
            if state.soundAvailable {                                   // FUN_10047a30 / FUN_10047990 test it
                _ = FrameKeys.volumeUp(&state.prefs)                    // 10000340
                _ = FrameKeys.volumeDown(&state.prefs)                  // 10000348
            }
            t1 = ticks                                                  // 10000350 FUN_100497f0
            if !quiet && state.soundAvailable {                         // 10000358..10000390 FUN_10047330('publ')
                out.sounds.append(SoundPlay.perm(Self.publ, priority: 0x32, volume: 100, allowMultiple: true))
            }
            out.ops.append(.fade(.fromBlack, .fullScreen))              // 100003a0 FUN_1000ba70(D, 0)
            phase = .publisherHold
        case .publisherHold:
            if !quiet && state.soundAvailable {                         // 100003b0..100003c4 FUN_10047910
                // No time limit (plan ruling 15): the spin at 100003cc..100003f0 has no floor and no cap, so a host
                // whose mixer never ends `publ`'s voice holds here for good, as the original would.
                out.ops.append(.hostWait(.voiceEnd(Self.publ)))         // 100003cc..100003f0 FUN_100476e0('publ')
            } else {                                                    // 10000408..10000430: flli 66
                let hold = UInt32(bitPattern: EntityDraw.fctiwz(a.floats[0x42]))
                out.ops.append(.hostWait(.ticks(Self.remaining(until: t1 &+ hold, now: ticks))))
            }
            out.ops.append(.fade(.toBlack, .fullScreen))                // 1000043c FUN_1000b9a0(D, 0)
            out.ops.append(.fill(.back, colour: 0))                     // 10000468 FUN_10009f00(back, black)
            out.ops.append(.drawPicture(id: Self.developerLogo, into: .back, top: 0, left: 0))   // 10000474
            phase = .developer
        case .developer:
            if !quiet {                                                 // 10000480..10000494
                out.music.append(.play(Self.inmu, loop: true))          // FUN_10047f90('inmu', 1, 0)
            }
            t2 = ticks                                                  // 1000049c FUN_100497f0
            out.ops.append(.fade(.fromBlack, .fullScreen))              // 100004b0 FUN_1000ba70(D, 0)
            phase = .developerHold
        case .developerHold:
            let held = Self.remaining(until: t2 &+ Self.developerHold, now: ticks)   // 100004b8..100004d4
            out.ops.append(.hostWait(.ticks(held)))
            out.ops.append(.fade(.toBlack, .fullScreen))                // 100004e0 FUN_1000b9a0(D, 0)
            let screen = EntityDraw.backBufferBounds
            out.ops.append(.fill(.back, colour: 0))                     // 10000504 FUN_10009f00(back, black)
            out.ops.append(.loadImage(image: Self.back, into: .back, dst: screen))      // 1000052c, 10000548
            out.ops.append(.loadImage(image: Self.back, into: .terrain, dst: screen))   // 10000564 (D+0x6c)
            out.ops.append(.fade(.fromBlack, .fullScreen))              // 10000580 FUN_1000ba70(D, 0)
            loadingLines(state: state, &out.ops)
            phase = .done
        case .done:
            return .finish(ScreenDone())                                // after 100005fc: back to FUN_100000a0
        }
        return .stay(out)
    }

    // MARK: - The loading lines

    /// The loaders' lines, in boot order (`10000598..100005b8`; only these four functions call `FUN_10023040`, 16
    /// sites, writing five lines — `FUN_1001fe60` writes two), then
    /// `FUN_100232d0`: the list faded out (`FUN_1000df00`, rate flli 160; X `100236c0` → `1000e180`, 16 passes, D1)
    /// and freed. Every call passes fadeIn = 1.
    /// - `FUN_1001fe60` (`1001fe60..1002007c`): `inte 6` (sprintf'd with "" — no conversion in the shipped text) as a
    ///   new line; per `gasp` 0…7 `"%s%s"` (`0x100e7feb`) of `inte 6` and the `im08` display name (`FUN_100024f0`) cut
    ///   at " IA" and at " IC" (`FUN_1001a1f0`: `strstr` → NUL, `_DAT_100e0164` / `_DAT_100e0168`); `inte 7`. Then
    ///   `inte 8` as a new line; with no sound system (`FUN_10047910`) the line "Sound System Not Available", else per
    ///   `gaso` 0…23 that loads (`FUN_1001f950(0, id, 0)`: false for `none`, true when already loaded) `inte 8` and
    ///   the `soun` display name; `inte 9`.
    /// - `FUN_1003cf10` → `FUN_1003d0a0(1)` (`1003d0a0..`): the Units Cache is not read (`FUN_100420f0`): the replica
    ///   has none, as at a first launch. "Unpacking Unit:  " (hard-coded, `0x100ed24a`) as a new line; per unit
    ///   (`FUN_1003fc50(i)`, the i-th `unde`) the text and its display name; "Unpacking Unit:  Done" (`0x100ed2ff`).
    /// - `FUN_1002aa90` → `FUN_1002ab20(1)`: `inte 12` new; per `wede` `inte 12` + its display name; `inte 13`.
    /// - `FUN_100391f0` → `FUN_10039280(1)`: `inte 14` new; per `plde` `inte 14` + its display name; `inte 15`.
    private mutating func loadingLines(state: FrontEndState, _ ops: inout [RenderOp]) {
        let a = state.assets
        let inte: [[UInt8]]
        do { inte = try a.interfaceStrings().lines } catch {           // the shipped data always holds `stli inte`
            preconditionFailure("Boot: the interface strings do not load (\(error))")
        }
        func string(_ n: Int) -> [UInt8] {                              // FUN_10002e50('inte', n, buf, 0x100)
            Credits.read(inte, n) ?? []                                 // empty: `line` draws nothing (10023074..)
        }
        func name(_ type: FourCC, _ id: FourCC) -> [UInt8] {            // FUN_100024f0: the display name (rec+0x130)
            // FUN_100024f0 returns 0 when no record matches (or for `none`), and its callers sprintf that pointer;
            // the shipped data never reaches it. The replica writes no name: the line is the head alone.
            guard let r = a.index.record(type: type, id: id) else { return [] }
            return MacRoman.encode(r.displayName, lossy: true) ?? []
        }
        func item(_ head: [UInt8], _ list: [[UInt8]], _ done: [UInt8]) {
            line(head, newLine: true, state: state, &ops)
            for n in list { line(head + n, newLine: false, state: state, &ops) }   // sprintf "%s%s"
            line(done, newLine: false, state: state, &ops)
        }

        // FUN_1001fe60: the permanent images.
        item(string(6), a.sprites.map { id in
            var n = name(Self.im08, id)
            for cut in Self.spriteNameCuts {                            // FUN_1001a1f0
                if let at = Credits.find(cut, in: n) { n = Array(n[..<at]) }
            }
            return n
        }, string(7))
        // The permanent sounds.
        if state.soundAvailable {
            item(string(8), a.sounds.filter { id in                    // FUN_1001f950(0, id, 0)
                id != .none && a.index.record(type: Self.soun, id: id) != nil
            }.map { name(Self.soun, $0) }, string(9))
        } else {
            line(string(8), newLine: true, state: state, &ops)
            line(Self.noSound, newLine: false, state: state, &ops)      // 100200dc..100200e8
            line(string(9), newLine: false, state: state, &ops)
        }
        // FUN_1003d0a0(1): the units.
        item(Self.unpacking, a.index.records(ofType: Self.unde).map { name(Self.unde, $0.id) }, Self.unpackingDone)
        // FUN_1002ab20(1): the weapons; FUN_10039280(1): the players.
        item(string(12), a.index.records(ofType: Self.wede).map { name(Self.wede, $0.id) }, string(13))
        item(string(14), a.index.records(ofType: Self.plde).map { name(Self.plde, $0.id) }, string(15))

        // FUN_100232d0: the fade-out, then the list freed.
        ops += lines.fadeOut(rate: ElementList.fadeRate(floats: a.floats), text: state.text, assets: a)
        lines = ElementList()                                           // FUN_100253d0
    }

    /// `FUN_10023040(text, newLine, fadeIn = 1)` (`10023040..100232c8`; X `100233c0`): nothing for an empty text (or
    /// before the text module, `FUN_1000d230`, which is up by now). The whole back buffer restored from the save buffer
    /// (`FUN_10009fd0(D+0x6c, D+0x68, bounds, bounds, 0)`); an empty list or a new line → a new record, format 0 `prog`
    /// (`FUN_1000d130(0, rec)`), blend 0x20 (`10023140..10023144`), appended. Then each line i, in list order: Loc X =
    /// format 0's, Loc Y = format 0's + flli 64 · i, shadows (+0x10f) off; the last line takes the text (`strcpy`)
    /// and, while its blend is not 0, its draw is the one-element fade (`FUN_1000d6d0`), else it is drawn at once
    /// (`FUN_1000d380`); its blend ← 0; every other line is drawn at once at blend 0. Then the full present
    /// (`FUN_1000bc60`) — one screen update per call (question 7 default: every name shown).
    private mutating func line(_ text: [UInt8], newLine: Bool, state: FrontEndState, _ ops: inout [RenderOp]) {
        guard !text.isEmpty else { return }                             // 10023074..10023094
        let a = state.assets
        let bounds = EntityDraw.backBufferBounds
        ops.append(.copy(from: .terrain, to: .back, src: bounds, dst: bounds, interlaced: false))   // 100230a8..
        if lines.count == 0 || newLine {                                // 100230e0..100230f4
            var r = TextRequest(format: a.formats[0], text: [])
            r.format.blendAmount = 0x20
            lines.append(.text(r))                                      // 10023128 FUN_100009e0
        }
        let f0 = a.formats[0]
        let dy = EntityDraw.fctiwz(a.floats[0x40])                      // 100231ac flli 64
        let last = lines.count - 1
        for i in 0...last {
            var r = lines.elements[i].record
            r.format.locX = f0.locX                                     // +0x100
            r.format.locY = f0.locY &+ Int32(i) &* dy                   // +0x104
            r.format.drawShadows = false                                // +0x10f ← 0
            if i == last {
                r.text = text                                           // FUN_10057780 strcpy
                if r.format.blendAmount != 0 {                          // 10023204..10023214
                    ops += ElementList.fadeOne(r, text: state.text)     // 10023234 FUN_1000d6d0
                    r.format.blendAmount = 0
                } else {
                    ops += state.text.draw(r).map { .draw($0) }         // 1002326c FUN_1000d380(rec, 0)
                }
            } else {
                r.format.blendAmount = 0
                ops += state.text.draw(r).map { .draw($0) }
            }
            lines.elements[i].record = r
        }
        ops.append(.present(.fullScreen))                               // 100232b4 FUN_1000bc60
    }

    // MARK: - Helpers and constants

    /// `while (TickCount() < end)` (unsigned, the sum wrapping) counted from `now`, where the host reaches the wait.
    static func remaining(until end: UInt32, now: UInt32) -> UInt32 {
        now < end ? end &- now : 0
    }

    /// `FUN_1000a560` + `FUN_1000a3b0`: the image's rect centred in the 640 × 480 back buffer
    /// (`1000a3cc..1000a430`: left = (right − w) / 2, top = (bottom − h) / 2, C division).
    static func centred(_ image: FourCC, _ a: DeimosAssets) -> MacRect {
        let tga: TGAImage
        do {
            guard let r = a.index.record(type: FourCC("im16")!, id: image) else { throw DeimosAssetsError
                .missingTag(type: "im16", id: image.description) }
            tga = try TGAImage(data: a.index.data(for: r))
        } catch {                                                       // the shipped data always holds `pucr`
            preconditionFailure("Boot: \(image) does not load (\(error))")
        }
        let b = EntityDraw.backBufferBounds
        let w = Int32(tga.width), h = Int32(tga.height)
        let left = (b.right &- w) / 2, top = (b.bottom &- h) / 2
        return MacRect(top: top, left: left, bottom: top &+ h, right: left &+ w)
    }

    /// `100002c0 li r3,0x5`.
    static let firstWait: UInt32 = 5
    /// `100004b8 addi r27,r27,0xf0`.
    static let developerHold: UInt32 = 240
    /// `10000470 li r3,0x3e8`: PICT 1000 "Swoop Software Logo".
    static let developerLogo: Int16 = 1000
    static let pucr = FourCC("pucr")!
    static let publ = FourCC("publ")!
    static let inmu = FourCC("inmu")!
    static let back = FourCC("back")!
    /// The record types the loading lines name.
    static let im08 = FourCC("im08")!, soun = FourCC("soun")!, unde = FourCC("unde")!, wede = FourCC("wede")!,
               plde = FourCC("plde")!
    /// `0x100e6aeb` " IA", `0x100e6aef` " IC" (`_DAT_100e0164`, `_DAT_100e0168`).
    static let spriteNameCuts = [Array(" IA".utf8), Array(" IC".utf8)]
    /// `0x100e813c`.
    static let noSound = Array("Sound System Not Available".utf8)
    /// `0x100ed24a`, `0x100ed2ff` (two spaces).
    static let unpacking = Array("Unpacking Unit:  ".utf8)
    static let unpackingDone = Array("Unpacking Unit:  Done".utf8)
}
