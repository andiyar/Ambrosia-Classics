import Foundation
import FerazelCore

/// `.WrapDrawSprites @ 100144c8` (decompile l. 10221–10396; draw-effects §1.1) for the modes the level-1 Setups store,
/// `.WrapEraseSprites @ 10014a58` (l. 10398–10618), and the blitters they reach — `.WrapDrawFace @ 100151c4`,
/// `.BlitEncFaceX @ 1002c908` (§1.2: NoClip/Clip, Flip, Special, the mask pass), `.WrapLightFace @ 100156c8` →
/// `.DrawLightOverFace @ 1001cf38` → `.BlitAmbDarkenOverFace(Flip)Clip` (§3), `.WrapBackScratchFace @ 10015454`,
/// `.WrapEraseBoolFace @ 10016784` and the mask-only `.RedrawScrollGrid(rect, 1)`.
///
/// Per sprite (`SpriteDraw`, active-list order):
/// 1. the cull: the face's opaque bounds (`+8`) offset by `(_DAT_1009fe74, _DAT_1009fe70)` (the grid's drawn h, v)
///    against `(0, 0, 0x260, 0x180)` offset by the **same** pair (raw `10014544..1001457c`) — as written the two offsets
///    cancel, so only a face whose bounds miss (0, 0, 608, 384) in face-local px is skipped;
/// 2. source window rows `[+0x1bc, min(+0x1ba, h))`, columns `[+0x1b6, min(+0x1b8, w))`, the destination moved by
///    (`+0x1bc`, `+0x1b6`) (`10014600..10014684`);
/// 3. `.WrapDrawFace`: skipped when it misses the view (dst h + w < scroll h, dst v + h < scroll v, dst h > h + 0x260,
///    dst v > v + 0x180); clipped to v + 0x180 below and **h + 0x280** on the right (`1001525c`, `10015260..1001526c`),
///    then at the left/top scroll edge; then one `.BlitEncFaceX` at the ring position (dst mod 640, mod 416, C
///    truncation) and again at v − 416, h − 640 and both when it reaches past the ring (`10015338..10015418`);
/// 4. `.BlitEncFaceX`: mode `+0xb8 >> 16`, sub `& 0xffff`; mode 0 copies, modes 1 / 9 / 0xc remap through tint
///    table sub / water table 0 / ambient L or light (L, F) (`.BlitEncFaceSpecial*`, draw-effects §2.2), mirrored by
///    `+0x17e` (the face is flipped in its frame, then windowed); then the **mask pass**: the silhouette as 0 into the
///    mask port `0008` with the same geometry (`1002d18c..1002d2c0`);
/// 5. the light pass when `+0x88` ∧ prefs Effects ≠ 3 ∧ mode ≠ 0xe (`1001493c..1001499c`): `.WrapLightFace` clips as
///    step 3 and per ring copy `.DrawLightOverFace`: D = `.GetAmbDarkVal(x + w'/2, y + h'/2)` with the clipped w', h'
///    (l. 15103–15106); with no light slot meeting the face and header `0x2706` > 0, `.BlitAmbDarkenOverFaceClip`
///    remaps every frame pixel under the face's copy runs through ambient slab D.
///
/// E2 (Phase 2) adds, per draw-effects §1.1 steps 3–5 and §2: the hurt flash (modes 3 / 4 through the redden tables,
/// `+0xaa` / `+0x1b4`), the water split at `+0x11c` with the submerged rows in mode 6 (`.BlitEncFaceWaterRipple` and
/// its flip / mask twins, the ripple phase `*_DAT_1009fd74`), scale (`.BlitEncFaceScale @ 1002bdc0`, the shrunken
/// image re-centred) and rotation (`.BlitEncFaceRot @ 1002ac00`) with their erase twins, and `.WrapEraseSprites` for
/// rotated, scaled and split sprites.
///
/// TB (Phase 4) adds translucency, mode 0xb (`.BlitEncFaceTransClip` / `.BlitEncFaceTransFlipClip`, draw-effects §2.7;
/// `transClip`), with the parallax row of `.CalcPxRowContents` under an empty mask byte.
///
/// The draw-modes fix adds the teleporter sparkle, mode 5 (`.BlitEncFaceDiffuse` / `.BlitEncFaceFlipDiffuse`,
/// draw-effects §2.3; `diffuseWalk`), its randoms replayed from the game stream's seed Core took at the draw
/// (`SpriteDraw.randomSeed`, `diffuseRandoms`), and the springboard gauge's squash, mode 0xa (`.BlitEncFaceSpecialClipX`'s
/// mode-10 arms and the squashed `.BlitEncBoolFaceClip` mask, §2.6; `squashWalk`).
///
/// Still refused by name (`Refusal`): behind-tiles (8), translucent ripple (0xd), silhouette (0xe), tile blends
/// (≥ 0x14), the undefined Special tables (2, 7, 0xf..0x13, and a flipped 0xa: the flip twins have no mode-10 arm), the
/// same modes and 5, 0xa, 0xb under scale / rotation (no table: the register keeps garbage), a mode-0xb arg whose
/// table read leaves its table, and a mode-5 draw with no seed. Each refusal (as every `throw` in FerazelRender) has its
/// row and its checked reason it cannot be reached in a built level in `DrawModeAuditTests` (DA) — a new one needs a row.
/// The light pass over a sprite with a water row uses `.DrawLightOverFace`'s underwater variants (P4).
public struct SpriteBlitter: Sendable {

    public enum Refusal: Error, Equatable {
        /// A draw mode with no transcribed blitter (`mode` = the whole effective `+0xb8` word).
        case mode(UInt32)
        /// A light-table read outside the table (the original reads other memory).
        case lightIndex(Int)
        /// A `FaceRef` with no loaded face.
        case faceNotLoaded(FaceRef)
        /// The ambient table for this darkness (outside 0 … 15 and −1).
        case darkness(Int)
        /// A rotation outside the 360-entry cos/sin tables (`_DAT_100a0164`/`0168`).
        case rotation(Int16)
        /// A rotated draw or erase reading past its column tables: the erase twins `.BlitEncFaceBoolRot` /
        /// `.BlitEncFaceBackScratchRot` build 256 entries (a wider face), and `rotWalk` refuses a copy-run column
        /// outside the table it was given (draw or erase).
        case transform
        /// A water-ripple row index that is negative under the back-scratch twins' signed `%` (the phase
        /// `*_DAT_1009fd74` past 2³¹): the original reads before `_DAT_100a0118`.
        case ripplePhase(Int32)
        /// A mode-0xb background read the replica does not make, at world x and the blitter's row counter y: no
        /// `parallax` blitter, a `.CalcPxRowContents` fetch `ParallaxBlitter.pxRowContents` refuses (x = the fetch
        /// point), a buffer index past the 301 bytes it fills (a run over 301 pixels wide: the original reads stale
        /// bytes of its static buffer, `0x100a3a16`, and past index 415 the globals after it — not modelled), or a
        /// flipped copy run straight after another copy run (the flip twin's pixel counter `iVar22` carries over and
        /// its column counter goes wrong — `FaceEncoder` never emits one).
        case translucency(x: Int, y: Int)
        /// A mode-5 draw with no `SpriteDraw.randomSeed`: its randoms belong to the game's stream, which Core hands over.
        case diffuseSeed
    }

    /// The face sets the sprites draw from (`SetupFaces.Sheet`s), loaded once.
    public struct Faces: Sendable {
        public private(set) var sheets: [Int16: FaceSheet] = [:]
        /// 6A-CF: the cache records of a PICT registered more than once (0x46a's three, two cuts), keyed by record —
        /// a face ref of such a PICT names its record and cell (`CachedFaces.recordCell(of:)`).
        public private(set) var recordSheets: [CachedFaces.RecordKey: FaceSheet] = [:]

        public init(sheets: [Int16: FaceSheet]) { self.sheets = sheets }

        /// Each sheet loaded as its `.Init<Class>Sprite` / cache call does: `GetPicture` on the front-end chain
        /// (Sprites → Sounds → Titles → app), converted under the sheet's CLUT; each of `records` (the record-keyed
        /// caches, `CachedFaces.recordSheets(markedBy:)`) the same way into `recordSheets`.
        public init<S: Sequence>(_ wanted: S, records: [(record: CachedFaces.RecordKey, sheet: SetupFaces.Sheet)] = [],
                                 resources: FerazelResources, search: ColorSearch,
                                 dither: DitherModel = .errorDiffusion) throws where S.Element == SetupFaces.Sheet {
            var cluts: [Int16: ColorLUT] = [:]
            func load(_ s: SetupFaces.Sheet) throws -> FaceSheet {
                let clut: ColorLUT
                if let c = cluts[s.clut] { clut = c } else {
                    clut = try ColorLUT.load(id: s.clut, from: resources, chain: .level)
                    cluts[s.clut] = clut
                }
                let loader: FaceSheet.Loader = s.single
                    ? .single(pict: s.pict)
                    : .set(try FaceSheet.Arguments(pict: s.pict, count: s.count, cellWidth: s.cellWidth,
                                                   cellHeight: s.cellHeight, columns: s.columns))
                return try FaceSheet.load(loader, from: resources, chain: .frontEnd, clut: clut, search: search,
                                          dither: dither)
            }
            let placeholder = SetupFaces.sheet(pict: SetupFaces.placeholderPict).map { [$0] } ?? []
            for s in Array(wanted) + placeholder where sheets[s.pict] == nil {
                sheets[s.pict] = try load(s)
            }
            for (k, s) in records where recordSheets[k] == nil {
                recordSheets[k] = try load(s)
            }
        }

        /// `.ActiveToIdleSprite`'s face rect at `.AddIdleSprite` time: face `+8` (the opaque bounds) of the face `+0xc0`
        /// holds — the loaded face for `.setup`, the placeholder PICT 150 for `.setupCached` (the caches load after
        /// `.SetupLevelSprites`) — else `SetRect(0, 0, 0x40, 0x40)`.
        public func idleFaceRect(_ e: SetupFaces.Entry) -> IdleSprites.Rect {
            let face: EncodedFace?
            switch e.source {
            case .setup: face = e.slot.face.flatMap(self.face)
            case .setupCached: face = sheets[SetupFaces.placeholderPict]?.faces.first
            case .handle, .none: face = nil
            }
            guard let b = face?.bounds else { return .noFace }
            return IdleSprites.Rect(top: Int(b.top), left: Int(b.left), bottom: Int(b.bottom), right: Int(b.right))
        }

        public func face(_ ref: FaceRef) -> EncodedFace? {
            if let s = sheets[ref.pict] {
                return s.faces.indices.contains(ref.index) ? s.faces[ref.index] : nil
            }
            // A record-keyed cache face (6A-CF): the record's own sheet, at the record's cell.
            guard !recordSheets.isEmpty, let rc = CachedFaces.recordCell(of: ref), let s = recordSheets[rc.record],
                  s.faces.indices.contains(rc.cell) else { return nil }
            return s.faces[rc.cell]
        }
    }

    public let level: LevelFile
    public internal(set) var tables: LevelTables
    public let faces: Faces
    /// prefs `+6` Effects (3 skips the light pass).
    public var effects: Int16
    /// The light slots `.DrawLightOverFace` walks and the darkness it reads.
    public var lights: LightRenderer
    /// The PxBack layer mode 0xb reads under an 0xff mask byte (`.CalcPxRowContents`); nil refuses that read.
    public var parallax: ParallaxBlitter?

    public init(level: LevelFile, tables: LevelTables, faces: Faces, effects: Int16 = FerazelPrefs().effects,
                lights: LightRenderer? = nil) {
        self.level = level
        self.tables = tables
        self.faces = faces
        self.effects = effects
        self.lights = lights ?? LightRenderer(level: level, tables: tables)
    }

    // MARK: - `.WrapDrawSprites`

    /// `DiffuseRandoms` (Core's question at `.WrapDrawSprites` time): advances `rng` by exactly the randoms
    /// `wrapDrawSprites([d], h:, v:, drawn:)` draws for `d` — the same cull (at the grid's drawn pair, as the draw's),
    /// `faceCalls`, `.Wrap*Face` ring copies at the scroll point (h, v), entry test and `diffuseWalk`, for every
    /// untransformed mode-5 call; nothing for any other draw (a transformed mode-5 draw is refused at the draw).
    /// SP: `DiffuseRandomsAt` asks at the renderer's own (h, v, drawn) for that op (`FrameRenderer.diffuseRandomsAt`).
    public func diffuseRandoms(_ d: SpriteDraw, h: Int, v: Int, drawn: (h: Int, v: Int), rng: inout FastRand) {
        guard d.rotation == 0 && d.scale == 0x100, let face = faces.face(d.face) else { return }
        let view = Rect(top: drawn.v, left: drawn.h, bottom: drawn.v + 0x180, right: drawn.h + 0x260)
        guard Rect(face.bounds).offset(dh: drawn.h, dv: drawn.v).intersects(view) else { return }
        for c in Self.faceCalls(d, face: face).calls where Int32(bitPattern: c.word) >> 16 == 5 {
            let n = Int16(truncatingIfNeeded: c.word & 0xffff)
            Self.wrap(src: (c.srcV, c.srcH), dst: (c.dstV, c.dstH), w: c.w, h: c.h, h0: h, v0: v) { s, t, w, hh in
                Self.diffuseWalk(face, src: s, dst: t, w: w, h: hh, flip: d.mirrored, n: n,
                                 random: { rng.next($0) }) { _, _ in }
            }
        }
    }

    /// The walk with the drawn pair at the scroll point (h, v) (`DiffuseRandoms`, before SP).
    public func diffuseRandoms(_ d: SpriteDraw, h: Int, v: Int, rng: inout FastRand) {
        diffuseRandoms(d, h: h, v: v, drawn: (h, v), rng: &rng)
    }

    /// The ripple phase `*_DAT_1009fd74` (0x200 at level start, `.GameLoop` l. 5217; += 0x100 after every
    /// `.WrapEraseSprites`, raw `100127ec..100127f4` — `FrameRenderer` advances it).
    public var ripplePhase: Int32 = 0x200

    /// The draw pass over `draws` (active-list order) at scroll (h, v) (`PTR_DAT_1009fe78`); `drawn` is the grid's
    /// `_DAT_1009fe74` / `_DAT_1009fe70` pair the cull offsets by. A `FaceRef` with no loaded face is refused.
    public func wrapDrawSprites(_ draws: [SpriteDraw], h: Int, v: Int, drawn: (h: Int, v: Int)? = nil,
                                ports: inout FramePorts) throws {
        let off = drawn ?? (h, v)
        let view = Rect(top: off.v, left: off.h, bottom: off.v + 0x180, right: off.h + 0x260)
        for d in draws {
            guard let face = faces.face(d.face) else { throw Refusal.faceNotLoaded(d.face) }
            guard Rect(face.bounds).offset(dh: off.h, dv: off.v).intersects(view) else { continue }
            let plan = Self.faceCalls(d, face: face)
            // Mode 5: the game stream replayed from the seed Core took at this draw (one generator per draw, shared by
            // its calls and ring copies in the binary's order).
            var rng = d.randomSeed.map { FastRand(seed: $0) }
            let random: ((Int16) -> Int16)? = rng == nil ? nil : { rng!.next($0) }
            for c in plan.calls {
                try Self.wrap(src: (c.srcV, c.srcH), dst: (c.dstV, c.dstH), w: c.w, h: c.h, h0: h, v0: v) { s, t, w, hh in
                    try blitEncFaceX(face, src: s, dst: t, w: w, h: hh, word: c.word, flip: d.mirrored,
                                     rotation: d.rotation, scale: d.scale, origin: (d.x, d.y), scroll: (h, v),
                                     random: random, ports: &ports)
                }
            }
            if let l = plan.light, effects != 3 {
                try lightFace(face, src: (l.srcV, l.srcH), dst: (l.dstV, l.dstH), w: l.w, h: l.h, x: d.x, y: d.y,
                              flip: d.mirrored, waterRow: l.waterRow, h0: h, v0: v, ports: &ports)
            }
        }
    }

    /// One `.WrapDrawFace` call (points (v, h)), or the `.WrapLightFace` call with its water row.
    struct FaceCall: Equatable {
        var srcV: Int, srcH: Int, dstV: Int, dstH: Int, w: Int, h: Int
        var word: UInt32
        var waterRow = 0
    }

    /// `.WrapDrawSprites` steps 2–7 for one drawn sprite (`100145f8..1001499c`, decompile l. 10262–10372): the source
    /// window and destination (step 2), the scale re-centring — scale < 0x100 with rotation 0 moves the destination
    /// by `((short)extent · (0x100 − scale)) >> 9` in each axis (`100146a0..100146ec`, extents = the visible rows /
    /// columns) — the effective word (step 4: `effectiveWord`), the water split on the **stored** `+0xb8` (step 5):
    /// - `+0x11c < 1`, stored mode 0xe or `+0x18c`: one call with the effective word;
    /// - `+0x11c == 1`: one call with `0x60000 + +0x128` (`1001491c`);
    /// - `+0x11c > 1`: rows above the line, height `+0x11c − +0x1bc` (not limited to the window, as written), then
    ///   from source row `max(+0x11c, +0x1bc)` at destination v − `+0x1bc` + that row, height `(short)rows − +0x11c`,
    ///   with `0x60000 + +0x128` (`10014864`, `100148e4`);
    /// and the light call (step 7: `+0x88`, stored mode ≠ 0xe; the caller tests Effects ≠ 3) with water row `+0x11c`
    /// unless `+0x18c`, at the re-centred destination with the unscaled window (face `+0x1a`/`+0x1c` are reset first,
    /// step 6).
    static func faceCalls(_ d: SpriteDraw, face: EncodedFace) -> (calls: [FaceCall], light: FaceCall?) {
        let fw = face.width, fh = face.height
        let top = d.clip.top, left = d.clip.left
        var rows = fh - top, cols = fw - left
        if d.clip.bottom < fh { rows -= fh - d.clip.bottom }
        if d.clip.right < fw { cols -= fw - d.clip.right }
        var dstV = Int(Int16(truncatingIfNeeded: d.y + top)), dstH = Int(Int16(truncatingIfNeeded: d.x + left))
        if d.scale < 0x100 && d.rotation == 0 {
            let k = 0x100 - Int(d.scale)
            dstV = Int(Int16(truncatingIfNeeded: dstV + Int(Int16(truncatingIfNeeded: (Int(Int16(truncatingIfNeeded: rows)) * k) >> 9))))
            dstH = Int(Int16(truncatingIfNeeded: dstH + Int(Int16(truncatingIfNeeded: (Int(Int16(truncatingIfNeeded: cols)) * k) >> 9))))
        }
        let m = effectiveWord(d)
        let stored = Int32(bitPattern: d.mode) >> 16
        let water = UInt32(bitPattern: Int32(d.waterKind) &+ 0x60000)
        var calls: [FaceCall] = []
        if d.waterRow < 1 || stored == 0xe || d.noWaterSplit {
            calls.append(FaceCall(srcV: top, srcH: left, dstV: dstV, dstH: dstH, w: cols, h: rows, word: m))
        } else if d.waterRow == 1 {
            calls.append(FaceCall(srcV: top, srcH: left, dstV: dstV, dstH: dstH, w: cols, h: rows, word: water))
        } else {
            calls.append(FaceCall(srcV: top, srcH: left, dstV: dstV, dstH: dstH, w: cols, h: d.waterRow - top, word: m))
            let from = max(d.waterRow, top)
            calls.append(FaceCall(srcV: from, srcH: left, dstV: Int(Int16(truncatingIfNeeded: dstV - top + from)),
                                  dstH: dstH, w: cols, h: Int(Int16(truncatingIfNeeded: rows)) - d.waterRow, word: water))
        }
        var light: FaceCall?
        if d.lightOverlay && stored != 0xe {
            light = FaceCall(srcV: top, srcH: left, dstV: dstV, dstH: dstH, w: cols, h: rows, word: m,
                             waterRow: d.noWaterSplit ? 0 : Int(Int16(truncatingIfNeeded: d.waterRow)))
        }
        return (calls, light)
    }

    /// Step 4's effective word (`100146f0..10014728`): `+0xb8`, or with `+0xaa` ≠ 0, n = min(`+0xaa`, 7) (signed)
    /// and `0x30000 + n` — `0x40000 + 2n` when `+0x1b4`. (A `+0x89` sprite's light word, written to `+0xb8` before
    /// the draw, overrides the flash: Core passes its `flash` as 0.)
    static func effectiveWord(_ d: SpriteDraw) -> UInt32 {
        guard d.flash != 0 else { return d.mode }
        let n = Int32(min(d.flash, 7))
        return UInt32(bitPattern: d.flashTable == 0 ? n &+ 0x30000 : (n << 1) &+ 0x40000)
    }

    /// `.BlitEncFaceX @ 1002c908` (decompile l. 26821–27108) for one ring copy, `rotation`/`scale` being face
    /// `+0x1a`/`+0x1c`: the entry test; the clip flag (0 only for the whole face at a non-negative point fitting the
    /// port; with rotation ≠ 0 or scale > 0x100 also 1 when the rotated bounding rect leaves the port, `RectInRect`;
    /// mode 0xa forces it); then
    /// - mode 0, no transform: the copy (`NoClipX`/`ClipX`, flip twins);
    /// - mode ∈ {5, 6, 8, 0xb, 0xd, 0xe}, mode > 0x13, or a transform: untransformed mode 6 → `.BlitEncFaceWaterRipple`
    ///   (flipped `.BlitEncFaceFlipWaterRipple`), untransformed 0xb → `.BlitEncFaceTrans(Flip)Clip` (`transClip`, at
    ///   the sprite's `origin` (+0xc, +0xa) and the `scroll`), untransformed 5 → `.BlitEncFaceDiffuse` (flipped
    ///   `.BlitEncFaceFlipDiffuse`; `diffuseWalk` with `random`, the replayed game stream — nil is refused), the others
    ///   refused; a transform with rotation 0, not flipped → `.BlitEncFaceScale`; any other transform → `.BlitEncFaceRot`;
    /// - mode 0xa, not flipped: `.BlitEncFaceSpecialClipX`'s squash (`squashWalk`, q = sub); flipped →
    ///   `.BlitEncFaceFlipClipSpecial` with no mode-10 table (refused);
    /// - else the Special table modes (`special`);
    /// then, for mode < 0x14, ≠ 0xd, untransformed, the mask pass: 0 under the silhouette (mode 6 through the ripple
    /// twins `.BlitEncBoolFace(Flip)WaterRipple`; mode 0xa through `.BlitEncBoolFaceClip` carrying q in r10, `1002d268..1002d270`,
    /// which squashes when q ≠ 0). Scale and Rot write the mask inline.
    func blitEncFaceX(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, word: UInt32, flip: Bool,
                      rotation rot: Int16, scale: Int16, origin: (x: Int, y: Int) = (0, 0),
                      scroll: (h: Int, v: Int) = (0, 0), random: ((Int16) -> Int16)? = nil,
                      ports: inout FramePorts) throws {
        let W = FramePorts.width, H = FramePorts.height
        let (dv, dh) = dst
        guard dh + face.width >= 0, dv + face.height >= 0, dh <= W, dv <= H else { return }
        let mode = Int(Int32(bitPattern: word) >> 16), sub = Int(Int16(truncatingIfNeeded: word & 0xffff))
        let transformed = rot != 0 || scale != 0x100
        if mode == 0 && !transformed {
            Self.blit(face, into: &ports.frame, src: src, dst: dst, w: w, h: h, flip: flip, reject: true) { s, _ in s }
        } else if [5, 6, 8, 0xb, 0xd, 0xe].contains(mode) || mode > 0x13 || transformed {
            if !transformed && mode == 0xb {
                try transClip(face, src: src, dst: dst, w: w, h: h, word: word, flip: flip, origin: origin,
                              scroll: scroll, ports: &ports)
            } else if !transformed && mode == 5 {
                guard let random else { throw Refusal.diffuseSeed }
                Self.diffuseWalk(face, src: src, dst: dst, w: w, h: h, flip: flip, n: Int16(truncatingIfNeeded: sub),
                                 random: random) { o, v in ports.frame[o] = v }
            } else if !transformed {
                guard mode == 6 else { throw Refusal.mode(word) }
                let t = try table(mode: 6, sub: sub, word: word)
                try Self.rippleWalk(face, src: src, dst: dst, w: w, h: h, flip: flip, phase: ripplePhase,
                                signedModulo: false) { o, s in ports.frame[o] = t(s) }
            } else if rot == 0 && !flip {
                let t = try table(mode: mode, sub: sub, word: word)
                Self.scaleWalk(face, src: src, dst: dst, w: w, h: h, scale: scale) { o, s in
                    ports.frame[o] = t(s)
                    ports.mask[o] = 0
                }
            } else {
                let t = try table(mode: mode, sub: sub, word: word)
                let clip = try Self.clipFlag(face, src: src, dst: dst, w: w, h: h, mode: mode, rotation: rot, scale: scale)
                try Self.rotWalk(face, src: src, dst: dst, w: w, h: h, rotation: rot, scale: scale, flip: flip,
                                 clip: clip, columns: face.width) { o, two, s in
                    let v = t(s)
                    ports.frame[o] = v
                    ports.mask[o] = 0
                    if two { ports.frame[o + 1] = v; ports.mask[o + 1] = 0 }
                }
            }
        } else if mode == 0xa {
            guard !flip else { throw Refusal.mode(word) }
            Self.squashWalk(face, src: src, dst: dst, w: w, h: h, q: Int16(truncatingIfNeeded: sub), mask: false) { o, s in
                ports.frame[o] = s
            }
        } else {
            let op = try special(word)
            Self.blit(face, into: &ports.frame, src: src, dst: dst, w: w, h: h, flip: flip, reject: true, op)
        }
        if mode < 0x14 && mode != 0xd && !transformed {
            if mode == 6 {
                try Self.rippleWalk(face, src: src, dst: dst, w: w, h: h, flip: flip, phase: ripplePhase,
                                signedModulo: false) { o, _ in ports.mask[o] = 0 }
            } else if mode == 0xa && sub != 0 {
                Self.squashWalk(face, src: src, dst: dst, w: w, h: h, q: Int16(truncatingIfNeeded: sub), mask: true) { o, _ in
                    ports.mask[o] = 0
                }
            } else {
                Self.blit(face, into: &ports.mask, src: src, dst: dst, w: w, h: h, flip: flip, reject: true) { _, _ in 0 }
            }
        }
    }

    /// `.BlitEncFaceDiffuse @ 10029988` / `.BlitEncFaceFlipDiffuse @ 10029c6c` (decompile l. 24659–24990; draw-effects
    /// §2.3), mode 5, n = (short) sub: clipped as `.BlitEncFaceClipX` (the same window walk, `forEachRun`, entry test
    /// included; there is no NoClip twin); per literal pixel of the window, in token order (rows down, source columns
    /// left to right — the flip twin walks the source the same way and writes leftwards), `random(30) < n` (signed,
    /// `10029b60..10029b7c`) → `0x99 + random(6)` (`addi r0,r3,0x99`, indices 0x99..0x9e), else the source pixel;
    /// `put(portIndex, value)`. Skips and pixels outside the window draw no random. The mask is `blitEncFaceX`'s pass.
    static func diffuseWalk(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, flip: Bool, n: Int16,
                            random: (Int16) -> Int16, _ put: (Int, UInt8) -> Void) {
        let data = face.data
        forEachRun(face, src: src, dst: dst, w: w, h: h, flip: flip, reject: true) { _, c0, count, at in
            for c in c0..<(c0 + count) {
                let v = random(30) < n ? UInt8(truncatingIfNeeded: Int(random(6)) + 0x99) : data[at.dataOffset + c - c0]
                put(at(c), v)
            }
        }
    }

    /// `.BlitEncFaceSpecialClipX @ 100271d4`'s mode-10 arms (decompile l. 22700–22965; draw-effects §2.6) — `mask`
    /// false — and `.BlitEncBoolFaceClip @ 10023574` with its squash argument q ≠ 0 (l. 19267–19470) — `mask` true. The
    /// port clip as `ClipX` (left/top edges move the source, right/bottom edges shorten the window), then the row
    /// pointer starts at dv − sv and, per row token: while the row counter is below sv the row's data is skipped, the
    /// counter +1 and the pointer down a row; after that `acc += q` (acc 0x100 at entry, a short) and only when
    /// acc > 0xff the pointer moves down, the counter +1 and acc −= 0x100; the row's pixels go to the pointer as it was
    /// before the move; the walk ends when the counter passes (sv + h) & 0xffff. Literal pixels in the column window
    /// `[sh, sh + w)` are copied raw (no table) — the colour pass only while the counter is below that end
    /// (`10027508 cmplw r30,r4; bge`), the mask pass always (no such test). `put(portIndex, sourcePixel)`; a row outside the port lands
    /// in its slop (`.NewBlitPortSlop`) and is not kept.
    static func squashWalk(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, q: Int16, mask: Bool,
                           _ put: (Int, UInt8) -> Void) {
        let W = FramePorts.width, H = FramePorts.height
        var (sv, sh) = src, (dv, dh) = dst, w = w, h = h
        if dh < 0 { sh -= dh; w += dh; dh = 0 }
        if dv < 0 { h += dv; sv -= dv; dv = 0 }
        if W <= dh + w { w = W - dh }
        if H <= dv + h { h = H - dv }
        if sh > 0 { dh -= sh }
        if sv > 0 { dv -= sv }
        let colStart = sh & 0xffff, colEnd = (sh + w) & 0xffff, rowEnd = (sv + h) & 0xffff, top = sv & 0xffff
        let data = face.data
        var p = 0, rows = 0, acc: Int16 = 0x100, next = dv, row = dv, col = 0
        while p + 4 <= data.count {
            let tok = data[p], n = Int(data[p + 1]) << 16 | Int(data[p + 2]) << 8 | Int(data[p + 3])
            p += 4
            switch tok {
            case 0:
                return
            case 1:
                row = next
                if rows < top {
                    p += n
                    rows += 1
                    next += 1
                } else {
                    acc = acc &+ q
                    if acc > 0xff {
                        next += 1
                        rows += 1
                        acc = acc &- 0x100
                    }
                }
                col = 0
                if rowEnd < rows { return }
            case 3:
                col += n
            case 2:
                let a = max(col, colStart), b = min(col + n, colEnd)
                if a < b && (mask || rows < rowEnd) && (0..<H).contains(row) {
                    for c in a..<b { put(row * W + dh + c, data[p + c - col]) }
                }
                col += n
                p += (n + 3) & ~3
            default:
                return
            }
        }
    }

    /// `.BlitEncFaceTransClip @ 10027d04` / `.BlitEncFaceTransFlipClip @ 100287cc` (decompile l. 23226–23456,
    /// 23737–23960; draw-effects §2.7), mode 0xb, arg a = (short) sub. Table (`10027d28..10027dfc`): 0 → `015c` avg,
    /// 1 → `0158` ¾ sprite, 2 → `0154` ¼ sprite, 3 → `0150`, 4 → `014c` glow, 5 → `0160` additive, else the grey-pull
    /// `0144 + (short)(a − 0x80)·0x1000`, and for a ≥ 0x80 the sprite pixel first through `0148` (255 bytes: s = 0xff
    /// reads past it → refused). Clipped by its own token walk (not `forEachRun`): the left/top port edge moves the
    /// source window, the right/bottom edge shortens it, as `ClipX` does; the flip twin draws face column c at
    /// dh − sh + width − 1 − c. Per copy-run pixel s at port offset o: bg = mask[o] == 0xff ? the parallax row byte :
    /// frame[o]; frame[o] = T[s·0x100 + bg] (a read outside the table → `Refusal.mode`). The mask is left to
    /// `blitEncFaceX`'s mask pass.
    ///
    /// The parallax row (`.CalcPxRowContents(x, y, n)`): fetched at the first 0xff pixel after a row or skip token
    /// (the flag `cVar12` / `bVar13`), with y the row counter (sprite y + 1 per row token, so face row r reads
    /// sprite y + r + 1) and n the pixels left in the run, then walked:
    /// - unflipped: fetched at x = sprite x + c (c the face column), forwards — pixel c reads the column of
    ///   sprite x + c;
    /// - flipped, as written: fetched at x = sprite x + a − k (a the run's first drawn face column, k = `iVar22`, the
    ///   pixels drawn since the row/skip token) and read **backwards from index n** — pixel j after the fetch reads
    ///   byte n − j, so with the fetch at the run start pixel c of run [a, b) reads sprite x + a + b − c, not the column
    ///   it lands on (sprite x + width − 1 − c). Straddling the view's left edge the reads run down to sprite x + 1
    ///   (further with a mid-run fetch), left of the view: a negative parallax column reads before the cell row as the
    ///   binary does (`ParallaxBlitter.pxRowContents`), never a refusal. The unflipped reads and every row stay at or
    ///   right of / below the view (all shipped x and y factors ≥ 0).
    ///
    /// Runs over 301 pixels are refused (`Refusal.translucency`): sprite sheet cells are at most 256 px wide (the
    /// widest `.Load/.CacheEncFaceSetFromPICT` cell is 0x100), but whole-PICT faces (`.Load1/.Cache1EncFaceFromPICT`,
    /// some at computed ids) can be wider (Sprites holds PICTs of 302–3,944 px), and whether any such face draws in
    /// mode 0xb with a 302-pixel opaque run is not checked.
    func transClip(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, word: UInt32, flip: Bool,
                   origin: (x: Int, y: Int), scroll: (h: Int, v: Int), ports: inout FramePorts) throws {
        let arg = Int(Int16(truncatingIfNeeded: word & 0xffff))
        let table: [UInt8], base: Int
        switch arg {
        case 0: table = tables.pair(.average); base = 0
        case 1: table = tables.pair(.threeQuarterSprite); base = 0
        case 2: table = tables.pair(.quarterSprite); base = 0
        case 3: table = tables.pair(.spriteGreyAverage); base = 0
        case 4: table = tables.pair(.glow); base = 0
        case 5: table = tables.pair(.additive); base = 0
        default: table = tables.greyPull; base = Int(Int16(truncatingIfNeeded: arg - 0x80)) * 0x1000
        }
        let remap = arg >= 0x80 ? tables.brightness : nil
        let W = FramePorts.width, H = FramePorts.height, fw = face.width
        var (sv, sh) = src, (dv, dh) = dst, w = w, h = h
        if dh < 0 { sh -= dh; w += dh; dh = 0 }
        if dv < 0 { h += dv; sv -= dv; dv = 0 }
        if W <= dh + w { w = W - dh }
        if H <= dv + h { h = H - dv }
        guard w > 0, h > 0 else { return }
        let ox = dh - sh, oy = dv - sv
        let c0 = flip ? fw - sh - w : sh, c1 = flip ? fw - sh : sh + w
        let data = face.data
        var p = 0, row = -1, col = 0, y = origin.y
        var fetch: (c: Int, n: Int, x: Int, bytes: [UInt8])?   // the `.CalcPxRowContents` buffer of this stretch
        var k = 0                                  // the flip twin's `iVar22`
        var afterCopy = false
        func background(_ o: Int, _ c: Int, _ a: Int, _ b: Int) throws -> UInt8 {
            guard ports.mask[o] == 0xff else { return ports.frame[o] }
            if fetch == nil {
                let x = flip ? origin.x + a - k : origin.x + c
                guard let parallax,
                      let bytes = parallax.pxRowContents(x: x, y: y, n: b - c, h: scroll.h, v: scroll.v)
                else { throw Refusal.translucency(x: x, y: y) }
                fetch = (c, b - c, x, bytes)
            }
            guard let f = fetch else { preconditionFailure() }
            let j = c - f.c
            let index = flip ? f.n - j : j
            guard index < f.bytes.count else { throw Refusal.translucency(x: f.x + index, y: y) }
            return f.bytes[index]
        }
        while p + 4 <= data.count {
            let tok = data[p], n = Int(data[p + 1]) << 16 | Int(data[p + 2]) << 8 | Int(data[p + 3])
            p += 4
            switch tok {
            case 1:
                row += 1; col = 0; y += 1
                fetch = nil; k = 0; afterCopy = false
                if row >= sv + h { return }
            case 3:
                col += n
                fetch = nil; k = 0; afterCopy = false
            case 2:
                if row >= sv {
                    let a = max(col, c0), b = min(col + n, c1)
                    if a < b {
                        if flip && afterCopy && k != 0 { throw Refusal.translucency(x: origin.x + a, y: y) }
                        for c in a..<b {
                            let o = (oy + row) * W + (flip ? ox + fw - 1 - c : ox + c)
                            var s = Int(data[p + c - col])
                            if let remap {
                                guard s < remap.count else { throw Refusal.mode(word) }
                                s = Int(remap[s])
                            }
                            let i = base + s * 0x100 + Int(try background(o, c, a, b))
                            guard table.indices.contains(i) else { throw Refusal.mode(word) }
                            ports.frame[o] = table[i]
                            k += 1
                        }
                    }
                }
                col += n
                p += (n + 3) & ~3
                afterCopy = true
            default:
                return
            }
        }
    }

    /// The table the transformed blitters and the ripple read (`.BlitEncFaceScale` / `.BlitEncFaceRot` switch,
    /// decompile l. 26222–26244, 25697–25719): mode 0 copies; 1 tint sub; 3 redden A sub; 4 redden B sub; 6 / 9 water
    /// sub; 0xc ambient L (F = 0) or light (L, F). Any other mode leaves the table register undefined → refused.
    func table(mode: Int, sub: Int, word: UInt32) throws -> (UInt8) -> UInt8 {
        func pick(_ bank: [[UInt8]]) throws -> (UInt8) -> UInt8 {
            guard bank.indices.contains(sub) else { throw Refusal.mode(word) }
            let t = bank[sub]
            return { t[Int($0)] }
        }
        switch mode {
        case 0: return { $0 }
        case 1: return try pick(tables.tint)
        case 3: return try pick(tables.reddenA)
        case 4: return try pick(tables.reddenB)
        case 6, 9: return try pick(tables.water)
        case 0xc:
            let op = try special(word)
            return { op($0, 0) }
        default: throw Refusal.mode(word)
        }
    }

    /// The per-pixel rule of `.BlitEncFaceX` for `word` (draw-effects §1.2, §2.2): mode 0 copies; 1 → tint table
    /// sub (`_DAT_100a0140 + sub·0x100`); 3 / 4 → redden A / B sub (the hurt flash); 9 → water table 0 (`_DAT_100a0170`, sub always 0 from the writers; the
    /// table is `sub`); 0xc → F = sub low byte, L = sub >> 8 signed: F = 0 → ambient L (`_DAT_100a0130 + L·0x100`),
    /// else light `_DAT_100a0134 + L·0x6e00 + F·0x100` (past its end at L 15, F 110…125: the ambient table that
    /// follows it, `LevelTables.followingLightRow`).
    func special(_ word: UInt32) throws -> (UInt8, UInt8) -> UInt8 {
        let mode = Int(word >> 16), sub = Int(Int16(truncatingIfNeeded: word & 0xffff))
        switch mode {
        case 0:
            return { s, _ in s }
        case 1:
            guard tables.tint.indices.contains(sub) else { throw Refusal.mode(word) }
            let t = tables.tint[sub]
            return { s, _ in t[Int(s)] }
        case 3, 4:
            // The hurt flash: `_DAT_100a0178` (redden A) / `_DAT_100a0174` (redden B) + sub·0x100 (draw-effects §2.2).
            let bank = mode == 3 ? tables.reddenA : tables.reddenB
            guard bank.indices.contains(sub) else { throw Refusal.mode(word) }
            let t = bank[sub]
            return { s, _ in t[Int(s)] }
        case 9:
            guard tables.water.indices.contains(sub) else { throw Refusal.mode(word) }
            let t = tables.water[sub]
            return { s, _ in t[Int(s)] }
        case 0xc:
            let L = sub >> 8, F = sub & 0xff
            guard tables.ambient.indices.contains(L) else { throw Refusal.darkness(L) }
            if F == 0 {
                let t = tables.ambient[L]
                return { s, _ in t[Int(s)] }
            }
            let base = L * 0x6e00 + F * 0x100
            guard base + 0x100 <= tables.light.count else {
                // L 15 with F ≥ 110 runs off the light table into the ambient table that follows it in memory
                // (ledger A13); past F 125 (the next table) still refused, no clamp.
                guard let t = tables.followingLightRow(at: base) else { throw Refusal.mode(word) }
                return { s, _ in t[Int(s)] }
            }
            let light = tables.light
            return { s, _ in light[base + Int(s)] }
        default:
            throw Refusal.mode(word)
        }
    }

    /// `.WrapLightFace` + `.DrawLightOverFace @ 1001cf38` (decompile l. 15067–15288) for one sprite, per ring copy:
    /// D = `.GetAmbDarkVal(x + w'/2, y + h'/2)` (the clipped w', h'); each active slot (200, slot order) is skipped
    /// when, as written, |x + w'/2 − light.x| ≥ light.x + r + w'/2 **and** |y + h'/2 − light.y| ≥ light.y + r + h'/2
    /// (the light's own coordinate inside the bound, l. 15172–15184; h' the current `param_6`, see below), else tested:
    /// the light face rect at (light.x − r, light.y − r) against the sprite face's bounds `+8` at (x, y); the first that
    /// meets is drawn with `.BlitLightOverFace(Flip)Clip`, every later one with `.BlitAfterLightOverFace(Flip)Clip`, at
    /// the light offset (y − (light.y − r), x − (light.x − r)). None met and header `0x2706` > 0:
    /// `.BlitAmbDarkenOverFace(Flip)Clip` through slab D.
    ///
    /// The water row W (`param_9` = `+0x11c` unless `+0x18c`; P4, the E2 carry; draw-effects §3) picks each blit's
    /// last argument 1, the **underwater variant** (the per-row ripple `rippleShift`, through `forEachRun`'s `rowShift`):
    /// - W < 1: one call, above water; W == 1: one call, underwater (the whole face);
    /// - W > 1: the rows above with height min(W, h') — except the flipped light blitters, passed W itself (l. 15250,
    ///   15254, as written) — then, when W < h', the rows from source / destination v + W (i16) with height h' − W,
    ///   underwater. In the light loop that height is stored back into `param_6` (`param_6 = param_6 − iVar9`,
    ///   l. 15259): every later slot's skip test, split and height see the shortened h' (as written); the closing
    ///   darken runs only when no light met, so it always sees the unshortened h'.
    func lightFace(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, x: Int, y: Int,
                           flip: Bool, waterRow: Int = 0, h0: Int, v0: Int, ports: inout FramePorts) throws {
        var failure: Refusal?
        let bounds = Rect(face.bounds).offset(dh: x, dv: y)
        let water = waterRow
        let shift: (Int) -> Int = { row in
            guard let r = self.rippleShift(row: row) else {
                if failure == nil { failure = .ripplePhase(self.ripplePhase) }
                return 0
            }
            return r
        }
        func lowered(_ p: (Int, Int)) -> (Int, Int) { (Int(Int16(truncatingIfNeeded: p.0 + water)), p.1) }
        Self.wrap(src: src, dst: dst, w: w, h: h, h0: h0, v0: v0) { s, t, ww, hh in
            guard failure == nil else { return }
            let D = lights.darkness(x: x + (ww >> 1), y: y + (hh >> 1))
            let cx = x + (ww >> 1)
            var hcur = hh                                               // `param_6`
            var lit = false
            for slot in lights.slots where slot.active {
                guard let lf = slot.face else { continue }
                let r = slot.radius
                let cy = y + (hcur >> 1)
                if abs(cx - slot.x) >= slot.x + r + (ww >> 1) && abs(cy - slot.y) >= slot.y + r + (hcur >> 1) { continue }
                let lightRect = Rect(top: slot.y - r, left: slot.x - r, bottom: slot.y - r + lf.height,
                                     right: slot.x - r + lf.width)
                guard lightRect.intersects(bounds) else { continue }
                if !lit && !tables.ambient.indices.contains(D) { failure = .darkness(D); return }
                func blit(_ s: (Int, Int), _ t: (Int, Int), _ height: Int, _ under: Bool) -> Refusal? {
                    lightBlit(face, into: &ports.frame, src: s, dst: t, w: ww, h: height, flip: flip, after: lit,
                              light: lf, colour: slot.colour & 0xff, D: D, offRow: y - (slot.y - r),
                              offCol: x - (slot.x - r), rowShift: under ? shift : nil)
                }
                var f: Refusal?
                if water < 1 {
                    f = blit(s, t, hcur, false)
                } else if water == 1 {
                    f = blit(s, t, hcur, true)
                } else {
                    f = blit(s, t, flip ? water : min(water, hcur), false)
                    if f == nil && water < hcur {
                        hcur -= water
                        f = blit(lowered(s), lowered(t), hcur, true)
                    }
                }
                if let f = f ?? failure {
                    failure = f
                    return
                }
                lit = true
            }
            guard !lit, level.header.darknessEnable > 0 else { return }
            guard D == -1 || tables.ambient.indices.contains(D), let slab = try? lights.ambientSlab(D) else {
                failure = .darkness(D); return
            }
            func darken(_ s: (Int, Int), _ t: (Int, Int), _ height: Int, _ under: Bool) {
                Self.blit(face, into: &ports.frame, src: s, dst: t, w: ww, h: height, flip: flip, reject: false,
                          rowShift: under ? shift : nil) { _, p in slab[Int(p)] }
            }
            if water < 1 {
                darken(s, t, hh, false)
            } else if water == 1 {
                darken(s, t, hh, true)
            } else {
                darken(s, t, min(water, hh), false)
                if water < hh { darken(lowered(s), lowered(t), hh - water, true) }
            }
        }
        if let failure { throw failure }
    }

    /// The underwater blitters' per-row offset (the last argument 1 of `.BlitLightOverFace(Flip)Clip`,
    /// `.BlitAfterLightOverFace(Flip)Clip`, `.BlitAmbDarkenOverFace(Flip)Clip`; raw `1001dcb0..1001dce0`,
    /// `1001e0b8..1001e0e4`, `1001e5f8..1001e624`, `1001edf4..1001ee24`, `1001f20c..1001f23c`, `1001f778..1001f79c`): R =
    /// `rippleOffsets[((phase >> 8) + row) % 35]` with row the **port** row of the face row and a signed `%` (`mulhw`);
    /// nil where that index is negative (the original reads before `_DAT_100a0118`).
    func rippleShift(row: Int) -> Int? {
        let i = (ripplePhase >> 8) &+ Int32(truncatingIfNeeded: row)
        let m = Int(i % 35)
        return m >= 0 ? Self.rippleOffsets[m] : nil
    }

    /// The four light blitters over one window of `face` (face pixel (r, c) reads light row offRow + r; light column
    /// offCol + c, or offCol + width − c when mirrored — the flip twins start each row at offCol + width, raw
    /// `.BlitLightOverFaceFlipClip @ 1001ea20`):
    /// - first (`.BlitLightOverFaceClip @ 1001d8e8` / `FlipClip`): the whole run → ambient slab D when the light row
    ///   is ≤ 0 (flip: < 0) or ≥ height − 1, or the run's first light column ≥ width (flip: < 1); else per pixel:
    ///   column outside the light → ambient, light pixel p = 0 → ambient, else `light[D·0x6e00 + (p + colour − 0xf5)·0x100
    ///   + dst]`;
    /// - after (`.BlitAfterLightOverFaceClip @ 1001dd8c` / `FlipClip @ 1001eee0`), slab D = 0: rows < 0 left alone, the
    ///   blit ends at the first light row ≥ height; a run whose first column is ≥ width (flip: < 1) is left alone;
    ///   per pixel inside the light: `light[(p + colour − 0xf5)·0x100 + dst]` with p = 0 read as 0xf5 (unflipped) or
    ///   the pixel left alone (flip).
    /// Returns a refusal for a light-table index outside the table.
    private func lightBlit(_ face: EncodedFace, into port: inout [UInt8], src: (Int, Int), dst: (Int, Int), w: Int,
                           h: Int, flip: Bool, after: Bool, light lf: LightFace, colour: Int, D: Int, offRow: Int,
                           offCol: Int, rowShift: ((Int) -> Int)? = nil) -> Refusal? {
        let LW = lf.width, LH = lf.height, fw = face.width
        guard let amb = after ? [] : try? lights.ambientSlab(D) else { return .darkness(D) }   // the caller checked D
        let base = after ? 0 : D * 0x6e00
        let table = tables.light
        var failure: Refusal?
        var stopped = false
        Self.forEachRun(face, src: src, dst: dst, w: w, h: h, flip: flip, reject: false,
                        rowShift: rowShift) { r, c0, n, index in
            guard failure == nil, !stopped else { return }
            let lr = offRow + r
            func lc(_ c: Int) -> Int { flip ? offCol + fw - c : offCol + c }
            func lit(_ p: Int, _ d: UInt8) -> UInt8? {
                let i = base + (p + colour - 0xf5) * 0x100 + Int(d)
                guard i >= 0, i < table.count else { failure = .lightIndex(i); return nil }
                return table[i]
            }
            if !after {
                let rowOut = flip ? (lr < 0 || lr + 1 >= LH) : (lr <= 0 || lr + 1 >= LH)
                let runOut = flip ? lc(c0) < 1 : lc(c0) >= LW
                for c in c0..<(c0 + n) {
                    let o = index(c), d = port[o]
                    let col = lc(c)
                    if rowOut || runOut || col < 0 || col >= LW { port[o] = amb[Int(d)]; continue }
                    let p = Int(lf.pixel(row: lr, col: col))
                    if p == 0 { port[o] = amb[Int(d)]; continue }
                    guard let v = lit(p, d) else { return }
                    port[o] = v
                }
            } else {
                if lr >= LH { stopped = true; return }
                guard lr >= 0 else { return }
                if flip ? lc(c0) < 1 : lc(c0) >= LW { return }
                for c in c0..<(c0 + n) {
                    let col = lc(c)
                    guard col >= 0, col < LW else { continue }
                    var p = Int(lf.pixel(row: lr, col: col))
                    if p == 0 { if flip { continue } else { p = 0xf5 } }
                    let o = index(c)
                    guard let v = lit(p, port[o]) else { return }
                    port[o] = v
                }
            }
        }
        return failure
    }

    // MARK: - `.WrapEraseSprites`

    /// The dirty-rect restore after a frame, over `sprites` in active-list order at scroll (h, v): for each sprite
    /// with a last-frame face (`+0xc8`), the rect test, the change test, then `.WrapBackScratchFace` (frame ← tiles
    /// port `0004` under the last-frame face at the last-frame position), `.WrapEraseBoolFace` (mask ← 0xFF there) and
    /// `.RedrawScrollGrid(cells, 1)` over the cells the erased rect covers (with `grid`: the mask-only re-stamp).
    /// Returns the cell rects re-stamped (top row, left col, bottom row, right col; inclusive).
    ///
    /// Read as written (raw `10014a80..10014c34`): the rect tested against the ring window `((h >> 5)·32, (v >> 5)·32,
    /// +640, +416)` and the four 32-px edge strips of the view is the last face's opaque bounds (mirrored when `+0x17f`)
    /// offset by the **scroll** (h, v) (`10014c08..10014c14`), not by the sprite's position — so the edge test fires
    /// for any face whose bounds lie within 16 px of a face-local edge of (0, 0, 608, 384).
    @discardableResult
    public func wrapEraseSprites(_ sprites: [SpriteSlot], h: Int, v: Int, ports: inout FramePorts,
                                 grid: TileGridRenderer? = nil) throws -> [(top: Int, left: Int, bottom: Int, right: Int)] {
        let ring = Rect(top: (v >> 5) << 5, left: (h >> 5) << 5, bottom: ((v >> 5) << 5) + 0x1a0,
                        right: ((h >> 5) << 5) + 0x280)
        let view = Rect(top: v, left: h, bottom: v + 0x180, right: h + 0x260)
        let strips = [Rect(top: view.top - 0x10, left: view.left, bottom: view.top + 0x10, right: view.right),
                      Rect(top: view.top, left: view.left - 0x10, bottom: view.bottom, right: view.left + 0x10),
                      Rect(top: view.bottom - 0x10, left: view.left, bottom: view.bottom + 0x10, right: view.right),
                      Rect(top: view.top, left: view.right - 0x10, bottom: view.bottom, right: view.right + 0x10)]
        var restamped: [(top: Int, left: Int, bottom: Int, right: Int)] = []
        for s in sprites {
            guard let prev = s.previous else { continue }
            guard let face = faces.face(prev.face) else { throw Refusal.faceNotLoaded(prev.face) }
            let prevRot = s.previousRotation, prevScale = s.previousScale
            let frameRect = Rect(face.frame)
            func mirroredBounds() -> Rect {
                Rect(top: Int(face.bounds.top), left: Int(face.frame.left) + face.width - Int(face.bounds.right),
                     bottom: Int(face.bounds.bottom), right: face.width - Int(face.bounds.left))
            }
            // The tested rect: the bounds `+8` (mirrored with `+0x17f`), or the frame `+0` with a rotation `+0x1ac`.
            var bounds = prevRot == 0 ? Rect(face.bounds) : frameRect
            if prev.mirrored && prevRot == 0 { bounds = mirroredBounds() }
            let tested = bounds.offset(dh: h, dv: v)
            guard tested.intersects(ring) else { continue }
            let nearEdge = strips.contains { tested.intersects($0) }
            let prevMode = Int(Int32(bitPattern: prev.mode) >> 16)
            let changed = s.x != prev.x || s.y != prev.y || s.face != prev.face || s.mirrored != prev.mirrored
                || prevMode == 0xb || prevMode == 5 || s.previousWaterRow != 0 || s.burning || nearEdge
                || s.face == nil || s.clip.left != 0 || s.clip.top != 0 || s.clip.right != 32000
                || s.clip.bottom != 32000 || s.rotation != 0 || prevRot != 0 || s.scale != 0x100 || s.dead
            guard changed else { continue }
            // The erased rect (`local_bc`): the frame with a last rotation, or a last scale ≠ 0x100 that is > 0xff or
            // near an edge; else the bounds; mirrored when `+0x17f` and no rotation; at the drawn `+0xc6`/`+0xc4`.
            var erasedRect = (prevRot != 0 || (prevScale != 0x100 && (prevScale > 0xff || nearEdge)))
                ? frameRect : Rect(face.bounds)
            if prev.mirrored && prevRot == 0 {
                erasedRect = Rect(top: erasedRect.top, left: Int(face.frame.left) + face.width - Int(face.bounds.right),
                                  bottom: erasedRect.bottom, right: face.width - Int(face.bounds.left))
            }
            let erased = erasedRect.offset(dh: s.drawnX, dv: s.drawnY)
            // The point `local_c8`, re-centred for a last scale < 0x100 with no rotation by the face's whole extents.
            var dstV = s.drawnY, dstH = s.drawnX
            if prevScale < 0x100 && prevRot == 0 {
                let k = 0x100 - Int(prevScale)
                dstV = Int(Int16(truncatingIfNeeded: dstV + Int(Int16(truncatingIfNeeded: (face.height * k) >> 9))))
                dstH = Int(Int16(truncatingIfNeeded: dstH + Int(Int16(truncatingIfNeeded: (face.width * k) >> 9))))
            }
            let fw = face.width, fh = face.height
            let water = UInt32(bitPattern: Int32(s.waterKind) &+ 0x60000)   // the current `+0x128`, as written
            let wr = Int(s.previousWaterRow)
            var parts: [(src: (Int, Int), dst: (Int, Int), h: Int, word: UInt32)] = []
            if wr == 0 || prevMode == 0xe || prev.noWaterSplit {
                parts = [((0, 0), (dstV, dstH), fh, prev.mode)]
            } else if wr == 1 {
                parts = [((0, 0), (dstV, dstH), fh, water)]
            } else {
                let w16 = Int(Int16(truncatingIfNeeded: wr))
                parts = [((0, 0), (dstV, dstH), w16, prev.mode),
                         ((w16, 0), (Int(Int16(truncatingIfNeeded: dstV + w16)), dstH), fh - wr, water)]
            }
            for part in parts {
                try Self.wrap(src: part.src, dst: part.dst, w: fw, h: part.h, h0: h, v0: v) { sp, t, w, hh in
                    try backScratch(face, src: sp, dst: t, w: w, h: hh, word: part.word, flip: prev.mirrored,
                                    rotation: prevRot, scale: prevScale, ports: &ports)
                }
                try Self.wrap(src: part.src, dst: part.dst, w: fw, h: part.h, h0: h, v0: v) { sp, t, w, hh in
                    try eraseBool(face, src: sp, dst: t, w: w, h: hh, word: part.word, flip: prev.mirrored,
                                  rotation: prevRot, scale: prevScale, ports: &ports)
                }
            }
            // `SectRectFast` → QuickDraw `SectRect`: no overlap gives the empty rect (0, 0, 0, 0), so cell (0, 0) is
            // re-stamped (l. 10589–10603); a last mode 5 widens it by sub + 2 (l. 10592–10598).
            var cells = erased.intersection(ring) ?? Rect(top: 0, left: 0, bottom: 0, right: 0)
            if prevMode == 5 {
                let k = Int(Int16(truncatingIfNeeded: Int(Int16(truncatingIfNeeded: prev.mode & 0xffff)) + 2))
                cells = Rect(top: cells.top - k, left: cells.left - k, bottom: cells.bottom + k, right: cells.right + k)
            }
            let r = (top: cells.top >> 5, left: cells.left >> 5, bottom: cells.bottom >> 5, right: cells.right >> 5)
            grid?.redrawScrollGridMask(top: r.top, left: r.left, right: r.right, bottom: r.bottom, h: h, v: v,
                                       ports: &ports)
            restamped.append(r)
        }
        return restamped
    }

    /// `.BackScratchBlitEncFace @ 1002d2f8` (decompile l. 27112–27290): frame ← tiles port `0004` under the face.
    /// Untransformed: mode 6 / 0xd → `.BlitEncFaceBackScratchWaterRipple(Flip)Clip` (0xd never flipped), else the
    /// plain copy; rotation 0, scale ≤ 0x100, not flipped → `.BlitEncFaceScaleBackScratch`; otherwise
    /// `.BlitEncFaceBackScratchRot` (a flipped or scale > 0x100 erase is the Rot one, unlike the draw's dispatch).
    func backScratch(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, word: UInt32, flip: Bool,
                     rotation rot: Int16, scale: Int16, ports: inout FramePorts) throws {
        let (dv, dh) = dst
        guard dh + face.width >= 0, dv + face.height >= 0, dh <= FramePorts.width, dv <= FramePorts.height else { return }
        let mode = Int(Int32(bitPattern: word) >> 16)
        let tiles = ports.tiles
        if rot == 0 && scale == 0x100 {
            if mode == 6 || mode == 0xd {
                try Self.rippleWalk(face, src: src, dst: dst, w: w, h: h, flip: flip && mode != 0xd, phase: ripplePhase,
                                signedModulo: true) { o, _ in ports.frame[o] = tiles[o] }
            } else {
                Self.blit(face, into: &ports.frame, src: src, dst: dst, w: w, h: h, flip: flip, reject: true,
                          index: { o, _, _ in tiles[o] })
            }
        } else if rot == 0 && scale <= 0x100 && !flip {
            Self.scaleWalk(face, src: src, dst: dst, w: w, h: h, scale: scale) { o, _ in ports.frame[o] = tiles[o] }
        } else {
            guard face.width <= 0x100 else { throw Refusal.transform }
            let clip = try Self.clipFlag(face, src: src, dst: dst, w: w, h: h, mode: mode, rotation: rot, scale: scale)
            try Self.rotWalk(face, src: src, dst: dst, w: w, h: h, rotation: rot, scale: scale, flip: flip, clip: clip,
                             columns: 0x100) { o, two, _ in
                ports.frame[o] = tiles[o]
                if two { ports.frame[o + 1] = tiles[o + 1] }
            }
        }
    }

    /// `.EraseBoolEncFaceX @ 1002d844` (decompile l. 27294–27450): mask ← 0xFF under the face, the same dispatch —
    /// `.BlitEncBoolFace(Flip)WaterRipple`, the plain bool stamp, `.BlitEncFaceScaleBool`, `.BlitEncFaceBoolRot`.
    func eraseBool(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, word: UInt32, flip: Bool,
                   rotation rot: Int16, scale: Int16, ports: inout FramePorts) throws {
        let (dv, dh) = dst
        guard dh + face.width >= 0, dv + face.height >= 0, dh <= FramePorts.width, dv <= FramePorts.height else { return }
        let mode = Int(Int32(bitPattern: word) >> 16)
        if rot == 0 && scale == 0x100 {
            if mode == 6 || mode == 0xd {
                try Self.rippleWalk(face, src: src, dst: dst, w: w, h: h, flip: flip && mode != 0xd, phase: ripplePhase,
                                signedModulo: false) { o, _ in ports.mask[o] = 0xff }
            } else {
                Self.blit(face, into: &ports.mask, src: src, dst: dst, w: w, h: h, flip: flip, reject: true) { _, _ in 0xff }
            }
        } else if rot == 0 && scale <= 0x100 && !flip {
            Self.scaleWalk(face, src: src, dst: dst, w: w, h: h, scale: scale) { o, _ in ports.mask[o] = 0xff }
        } else {
            guard face.width <= 0x100 else { throw Refusal.transform }
            let clip = try Self.clipFlag(face, src: src, dst: dst, w: w, h: h, mode: mode, rotation: rot, scale: scale)
            try Self.rotWalk(face, src: src, dst: dst, w: w, h: h, rotation: rot, scale: scale, flip: flip, clip: clip,
                             columns: 0x100) { o, two, _ in
                ports.mask[o] = 0xff
                if two { ports.mask[o + 1] = 0xff }
            }
        }
    }

    // MARK: - geometry

    /// A QuickDraw rect (top, left, bottom, right), half-open.
    struct Rect: Equatable {
        var top: Int, left: Int, bottom: Int, right: Int

        init(top: Int, left: Int, bottom: Int, right: Int) {
            self.top = top; self.left = left; self.bottom = bottom; self.right = right
        }

        init(_ r: EncodedFace.Rect) {
            self.init(top: Int(r.top), left: Int(r.left), bottom: Int(r.bottom), right: Int(r.right))
        }

        func offset(dh: Int, dv: Int) -> Rect { Rect(top: top + dv, left: left + dh, bottom: bottom + dv, right: right + dh) }

        func intersection(_ o: Rect) -> Rect? {
            let r = Rect(top: max(top, o.top), left: max(left, o.left), bottom: min(bottom, o.bottom),
                         right: min(right, o.right))
            return r.top < r.bottom && r.left < r.right ? r : nil
        }

        func intersects(_ o: Rect) -> Bool { intersection(o) != nil }
    }

    /// The `.Wrap*Face` wrapper (`.WrapDrawFace` with the frame port, `.WrapLightFace`, `.WrapBackScratchFace`,
    /// `.WrapEraseBoolFace` — the same code): the view test and clip against scroll (h0, v0), then `body(src, dst, w,
    /// h)` at the ring position and its up-to-three wrapped copies. Points are (v, h).
    static func wrap(src: (Int, Int), dst: (Int, Int), w: Int, h: Int, h0: Int, v0: Int,
                     _ body: ((Int, Int), (Int, Int), Int, Int) throws -> Void) rethrows {
        var (sv, sh) = src, (dv, dh) = dst, w = w, h = h
        guard dh + w >= h0, dv + h >= v0, dh <= h0 + 0x260, dv <= v0 + 0x180 else { return }
        if dv + h > v0 + 0x180 { h = v0 + 0x180 - dv }
        if dh + w > h0 + 0x280 { w = h0 + 0x280 - dh }
        if dh < h0 { let d = h0 - dh; w -= d; sh += d; dh = h0 }
        if dv < v0 { let d = v0 - dv; h -= d; sv += d; dv = v0 }
        let rh = dh % FramePorts.width, rv = dv % FramePorts.height   // C truncation (`mulhw 0x66666667` / `0x4ec4ec4f`)
        try body((sv, sh), (rv, rh), w, h)
        if rv - FramePorts.height + h > 0 { try body((sv, sh), (rv - FramePorts.height, rh), w, h) }
        if rh - FramePorts.width + w > 0 { try body((sv, sh), (rv, rh - FramePorts.width), w, h) }
        if rh - FramePorts.width + w > 0 && rv - FramePorts.height + h > 0 {
            try body((sv, sh), (rv - FramePorts.height, rh - FramePorts.width), w, h)
        }
    }

    /// One `.BlitEncFace*` call: the face's source window (rows `[sv, sv + h)`, columns `[sh, sh + w)`; with `flip`
    /// the face mirrored in its frame first, `.BlitEncFaceFlipClip @ 10028f48`: face column c lands at
    /// dh − sh + width − 1 − c) at port position (dv, dh), clipped to the 640×416 port as `.BlitEncFaceClipX @ 10024998`
    /// clips (left/top edge moves the source, right/bottom edge shortens the window). `reject`: `.BlitEncFaceX`'s
    /// entry test (dh + face width < 0, dv + face height < 0, dh > 640, dv > 416 → nothing). Each copy-run pixel
    /// becomes `op(source pixel, port pixel)`; skips leave the port alone.
    static func blit(_ face: EncodedFace, into port: inout [UInt8], src: (Int, Int), dst: (Int, Int), w: Int, h: Int,
                     flip: Bool, reject: Bool, rowShift: ((Int) -> Int)? = nil, _ op: (UInt8, UInt8) -> UInt8) {
        blit(face, into: &port, src: src, dst: dst, w: w, h: h, flip: flip, reject: reject, rowShift: rowShift,
             index: { _, s, old in op(s, old) })
    }

    /// As above with `index(portIndex, source pixel, port pixel)`.
    static func blit(_ face: EncodedFace, into port: inout [UInt8], src: (Int, Int), dst: (Int, Int), w: Int, h: Int,
                     flip: Bool, reject: Bool, rowShift: ((Int) -> Int)? = nil,
                     index: (Int, UInt8, UInt8) -> UInt8) {
        let data = face.data
        forEachRun(face, src: src, dst: dst, w: w, h: h, flip: flip, reject: reject, rowShift: rowShift) { _, c0, n, at in
            for c in c0..<(c0 + n) {
                let o = at(c)
                port[o] = index(o, data[at.dataOffset + c - c0], port[o])
            }
        }
    }

    /// Where a window run's face column c lands in the port, and the run's first data byte.
    struct RunIndex {
        let row: Int, ox: Int, fw: Int, flip: Bool, dataOffset: Int
        func callAsFunction(_ c: Int) -> Int {
            row * FramePorts.width + (flip ? ox + fw - 1 - c : ox + c)
        }
    }

    /// The window walk every `.BlitEncFace*` clip variant shares: rows `[sv, sv + h)` and face columns `[sh, sh + w)`
    /// (mirrored: `[fw − sh − w, fw − sh)`) of `face` at port position (dv, dh), clipped to the port as
    /// `.BlitEncFaceClipX` clips; `run(faceRow, firstFaceColumn, count, index)` per copy-run piece, in token order.
    /// - Parameter rowShift: the underwater light / darken blitters (P4): per drawn row, R = `rowShift(port row)`
    ///   starts both the destination and the column counter (the light blitters' `in_r11` / `in_r0`), so face column
    ///   c lands at dh − sh + c + R (mirrored: dh − sh + width − 1 − c − R) and the window is tested on c + R; the light
    ///   column a blitter reads stays the unshifted c (its own counter starts at offCol).
    static func forEachRun(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, flip: Bool,
                           reject: Bool, rowShift: ((Int) -> Int)? = nil, _ run: (Int, Int, Int, RunIndex) -> Void) {
        let W = FramePorts.width, H = FramePorts.height
        let fw = face.width, fh = face.height
        var (sv, sh) = src, (dv, dh) = dst, w = w, h = h
        if reject { guard dh + fw >= 0, dv + fh >= 0, dh <= W, dv <= H else { return } }
        if dh < 0 { sh -= dh; w += dh; dh = 0 }
        if dv < 0 { h += dv; sv -= dv; dv = 0 }
        if W <= dh + w { w = W - dh }
        if H <= dv + h { h = H - dv }
        guard w > 0, h > 0 else { return }
        let ox = dh - sh, oy = dv - sv
        let c0 = flip ? fw - sh - w : sh, c1 = flip ? fw - sh : sh + w
        let data = face.data
        var p = 0, row = -1, col = 0, R = 0
        while p + 4 <= data.count {
            let tok = data[p], n = Int(data[p + 1]) << 16 | Int(data[p + 2]) << 8 | Int(data[p + 3])
            p += 4
            switch tok {
            case 1:
                row += 1
                col = 0
                if row >= sv + h { return }
                if let rowShift, row >= sv { R = rowShift(oy + row) }
            case 3:
                col += n
            case 2:
                if row >= sv {
                    let a = max(col, c0 - R), b = min(col + n, c1 - R)
                    if a < b {
                        run(row, a, b - a, RunIndex(row: oy + row, ox: flip ? ox - R : ox + R, fw: fw, flip: flip,
                                                    dataOffset: p + a - col))
                    }
                }
                col += n
                p += (n + 3) & ~3
            default:
                return
            }
        }
    }
}

// MARK: - E2: ripple, scale, rotation

extension SpriteBlitter {

    /// `.BuildSineTable` (`100201e0..1002024c`): R[i] = fctiwz(frsp(frsp(sin(f32(i) · 0.1795194f)) · 1.5)) for
    /// i = 0..34 (f32 at `100a1730`, f64 1.5 at `100a1728`) — `_DAT_100a0118`, the water-ripple row offsets.
    static let rippleOffsets: [Int] = (0..<35).map { i in
        let a = Float(i) * Float(bitPattern: 0x3e37_d3f1)          // fsubs, fmuls
        let s = Float(sin(Double(a)))                               // bl sin, frsp
        let v = Float(Double(s) * 1.5)                              // fmul, frsp
        return Int(v.rounded(.towardZero))                          // fctiwz
    }

    /// `.BuildTintTable`'s cos/sin tables (`10020b10..10020b8c`): for i = 0..359, a = (π · (2.0 · i)) / 360.0 with
    /// π = 3.1415926535 as stored (`100a16c8` = 0x400921fb54411744), cos(a) → `_DAT_100a0168`, sin(a) → `_DAT_100a0164`.
    static let cosTable: [Double] = (0..<360).map { cos(angle($0)) }
    static let sinTable: [Double] = (0..<360).map { sin(angle($0)) }
    private static func angle(_ i: Int) -> Double {
        (Double(bitPattern: 0x4009_21fb_5441_1744) * (2.0 * Double(i))) / 360.0
    }

    /// The water-ripple walk of `.BlitEncFaceWaterRipple @ 10029f70` and its twins (`…FlipWaterRipple @ 1002a300`,
    /// `.BlitEncBoolFace(Flip)WaterRipple @ 10023fd0 / 10024358`, `.BlitEncFaceBackScratchWaterRipple(Flip)Clip @
    /// 10026010 / 100264d0`): clipped to the port as `ClipX`; per row token R = `rippleOffsets[((phase >> 8) + row) mod
    /// 35]` with row the port row (draw / bool: unsigned `mulhwu` modulo; back-scratch: signed `%`), and both the
    /// destination and the column counter start at R — so face column c lands at x = dh − sh + c + R (flipped:
    /// dh − sh + width − 1 − c − R) and the window test is on c + R ∈ [sh, sh + w) (flipped: [width − w − sh,
    /// width − sh)), the bank's one-pixel clip quirk (draw-effects §2.4). `put(portIndex, sourcePixel)` per pixel;
    /// a pixel outside the 640×416 port lands in its 8-px slop (`.NewBlitPortSlop`) and is not kept.
    static func rippleWalk(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, flip: Bool,
                           phase: Int32, signedModulo: Bool, _ put: (Int, UInt8) -> Void) throws {
        let W = FramePorts.width, H = FramePorts.height, fw = face.width
        var (sv, sh) = src, (dv, dh) = dst, w = w, h = h
        if dh < 0 { sh -= dh; w += dh; dh = 0 }
        if dv < 0 { h += dv; sv -= dv; dv = 0 }
        if W <= dh + w { w = W - dh }
        if H <= dv + h { h = H - dv }
        if sh > 0 { dh -= sh }
        if sv > 0 { dv -= sv }
        let left = flip ? (fw - w - sh) & 0xffff : sh & 0xffff
        let right = flip ? (fw - sh) & 0xffff : (sh + w) & 0xffff
        let rowsEnd = (sv + h) & 0xffff
        let data = face.data
        var p = 0, rowsSeen = 0, nextRow = dv, row = 0, k = 0, x = 0
        while p + 4 <= data.count {
            let tok = data[p], n = Int(data[p + 1]) << 16 | Int(data[p + 2]) << 8 | Int(data[p + 3])
            p += 4
            switch tok {
            case 0:
                return
            case 1:
                let skipped = rowsSeen < (sv & 0xffff)
                if skipped { p += n }
                rowsSeen += 1
                let i = Int32(truncatingIfNeeded: Int(phase >> 8) + nextRow)
                let m = signedModulo ? Int(i % 35) : Int(UInt32(bitPattern: i) % 35)
                // A negative index reads before the table; harmless for a row whose data is skipped.
                guard m >= 0 || skipped else { throw Refusal.ripplePhase(phase) }
                let R = m >= 0 ? rippleOffsets[m] : 0
                row = nextRow
                nextRow += 1
                k = R
                x = flip ? dh + fw - 1 - R : dh + R
                if rowsEnd < rowsSeen { return }
            case 3:
                x += flip ? -n : n
                k += n
            case 2:
                var n2 = n, q = p, skipRest = 0
                let pad = n & 3 == 0 ? 0 : 4 - (n & 3)
                defer { p += n + pad }
                if k < left {
                    let d = left - k
                    if n2 < d { x += flip ? -n2 : n2; k += n2; continue }
                    n2 -= d; x += flip ? -d : d; q += d; k += d
                }
                if right < k + n2 {
                    guard k <= right else { x += flip ? -n2 : n2; k += n2; continue }
                    skipRest = n2 - (right - k)
                    n2 = right - k
                }
                for i in 0..<n2 {
                    let px = flip ? x - i : x + i
                    if (0..<W).contains(px) && (0..<H).contains(row) { put(row * W + px, data[q + i]) }
                }
                x += flip ? -(n2 + skipRest) : n2 + skipRest
                k += n2 + skipRest
            default:
                return
            }
        }
    }

    /// The scale walk of `.BlitEncFaceScale @ 1002bdc0` and its twins `.BlitEncFaceScaleBool @ 1002c220` /
    /// `.BlitEncFaceScaleBackScratch @ 1002c528` (decompile l. 26187–26820): nearest-neighbour reduction, as written —
    /// clipped as `ClipX`, the face origin at (dv − sv, dh − sh); a row accumulator (0x100 at entry) gains `scale`
    /// at each visible row token and the destination row advances when `(short)acc > 0xff` (rows above the clip
    /// advance 1:1 and their data is skipped); the row is drawn at the destination row **before** that advance, and
    /// the walk ends when the advanced row passes dv + h. Per row the column accumulator restarts at 0; a skip adds
    /// n·scale and advances while `(short)acc > 0xff` (the short compare as written, raw `1002c14c..1002c150`); a copy
    /// run's part left of dh advances 1:1; a run starting at or past the last column dh + w − 1 is skipped; else each
    /// source pixel adds `scale` and, past 0xff, is written at the current column, which then advances — the run ends
    /// once that column passes dh + w − 1. `put(portIndex, sourcePixel)`; slop pixels are dropped.
    static func scaleWalk(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, scale: Int16,
                          _ put: (Int, UInt8) -> Void) {
        let W = FramePorts.width, H = FramePorts.height
        var (sv, sh) = src, (dv, dh) = dst, w = w, h = h
        if dh < 0 { sh -= dh; w += dh; dh = 0 }
        if dv < 0 { h += dv; sv -= dv; dv = 0 }
        if W <= dh + w { w = W - dh }
        if H <= dv + h { h = H - dv }
        if sh > 0 { dh -= sh }
        if sv > 0 { dv -= sv }
        let firstCol = dh + sh, firstRow = dv + sv, lastRow = dv + h + sv, lastCol = dh + w - 1 + sh
        let s = Int32(scale)
        let data = face.data
        var p = 0, cur = dv, row = dv, col = dh
        var accV: Int32 = 0x100, accH: Int32 = 0
        func over(_ a: Int32) -> Bool { Int16(truncatingIfNeeded: a) > 0xff }
        while p + 4 <= data.count {
            let tok = data[p], n = Int(data[p + 1]) << 16 | Int(data[p + 2]) << 8 | Int(data[p + 3])
            p += 4
            switch tok {
            case 0:
                return
            case 1:
                let before = cur
                if cur < firstRow {
                    p += n
                    cur += 1
                } else {
                    accV &+= s
                    if over(accV) { cur += 1; accV &-= 0x100 }
                }
                accH = 0
                row = before
                col = dh
                if lastRow < cur { return }
            case 3:
                accH &+= Int32(truncatingIfNeeded: n) &* s
                while over(accH) { col += 1; accH &-= 0x100 }
            case 2:
                let pad = n & 3 == 0 ? 0 : 4 - (n & 3)
                defer { p += n + pad }
                var n2 = n, q = p
                if col < firstCol {
                    let d = firstCol - col
                    if d <= n2 { n2 -= d; col += d; q += d } else { col += n2; continue }
                }
                guard col < lastCol else { continue }
                while n2 != 0 {
                    accH &+= s
                    var rem = n2
                    if over(accH) {
                        let at = col
                        col += 1
                        if (0..<W).contains(at) && (0..<H).contains(row) { put(row * W + at, data[q]) }
                        accH &-= 0x100
                        if lastCol < col { rem = 1 }
                    }
                    q += 1
                    n2 = rem - 1
                }
            default:
                return
            }
        }
    }

    /// The rotation walk of `.BlitEncFaceRot @ 1002ac00` and its twins `.BlitEncFaceBoolRot @ 1002b0e0` /
    /// `.BlitEncFaceBackScratchRot @ 1002b724` (decompile l. 25648–26186): the angle 360 − rotation when flipped
    /// (rotation ≠ 0); A = sin, B = cos of it, both `· scale · (1/256)` when scale ≠ 0x100 (f64, `100a1680`); about
    /// the frame centre (cx, cy) = ((right + left) >> 1, (bottom + top) >> 1), per face column c the tables
    /// X[c] = (int)(B·(c − cx)) and Y[c] = (int)−(A·(c − cx)) (`columns` entries: the face width for the draw, 256 for
    /// the twins); per pixel with dy = row + 1 − cy: ix = (int)(dy·A) + X[c], iy = (int)(dy·B) + Y[c], the destination
    /// x = dh + cx − sh + (flip ? −ix : ix), y = dv + cy − sv − 1 + iy; with the clip flag only when x, y are in the
    /// port and ix + cx ∈ [sh, sh + w), iy + cy ∈ [sv, sv + h) (the window tested on the rotated point, as written).
    /// Two pixels (x, x + 1) when ix + cx + 1 < sh + w and x < 639, else one. `put(portIndex, two, sourcePixel)`;
    /// writes outside the port (no clip flag) are dropped.
    static func rotWalk(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, rotation: Int16,
                        scale: Int16, flip: Bool, clip: Bool, columns: Int, _ put: (Int, Bool, UInt8) -> Void) throws {
        let W = FramePorts.width, H = FramePorts.height
        var angle = Int(rotation)
        if flip && angle != 0 { angle = 0x168 - angle }
        guard (0..<360).contains(angle) else { throw Refusal.rotation(rotation) }
        var A = sinTable[angle], B = cosTable[angle]
        if scale != 0x100 {
            A = A * Double(scale) * 0.00390625
            B = B * Double(scale) * 0.00390625
        }
        let fr = face.frame
        let cx = (Int(fr.right) + Int(fr.left)) >> 1, cy = (Int(fr.bottom) + Int(fr.top)) >> 1
        let X = (0..<columns).map { Int((B * Double($0 - cx)).rounded(.towardZero)) }
        let Y = (0..<columns).map { Int((-(A * Double($0 - cx))).rounded(.towardZero)) }
        let (sv, sh) = src, (dv, dh) = dst
        let data = face.data
        var p = 0, dy = -cy, col = 0
        while p + 4 <= data.count {
            let tok = data[p], n = Int(data[p + 1]) << 16 | Int(data[p + 2]) << 8 | Int(data[p + 3])
            p += 4
            switch tok {
            case 0:
                return
            case 1:
                dy += 1
                col = -cx
            case 3:
                col += n
            case 2:
                let fdy = Double(dy)
                for i in 0..<n {
                    let c = col + cx
                    guard X.indices.contains(c) else { throw Refusal.transform }
                    let ix = Int((fdy * A).rounded(.towardZero)) + X[c]
                    let iy = Int((fdy * B).rounded(.towardZero)) + Y[c]
                    let x = (dh + cx - sh) + (flip ? -ix : ix)
                    let y = (dv + cy - sv) - 1 + iy
                    let inside = (0..<W).contains(x) && (0..<H).contains(y)
                    if !clip || (inside && sh <= ix + cx && ix + cx < sh + w && sv <= iy + cy && iy + cy < sv + h) {
                        if inside {
                            let two = ix + cx + 1 < sh + w && x < W - 1
                            put(y * W + x, two, data[p + i])
                        }
                    }
                    col += 1
                }
                p += n + (n & 3 == 0 ? 0 : 4 - (n & 3))
            default:
                return
            }
        }
    }

    /// `.BlitEncFaceX`'s clip flag (l. 26862–26944; `.BackScratchBlitEncFace`, `.EraseBoolEncFaceX` the same): false only
    /// for source (0, 0), a non-negative destination, the whole face (w, h = frame right, bottom) and the port
    /// holding it; with rotation ≠ 0 or scale > 0x100 true again unless `RectInRect` (`1002c878`) of the face frame at
    /// the destination grown by S = max(h, w) — top/bottom by (int)(S·|sin|), left/right by (int)(S·|cos|) — in
    /// (0, 0, 416, 640); mode 0xa true.
    static func clipFlag(_ face: EncodedFace, src: (Int, Int), dst: (Int, Int), w: Int, h: Int, mode: Int,
                         rotation: Int16, scale: Int16) throws -> Bool {
        let W = FramePorts.width, H = FramePorts.height
        let (dv, dh) = dst
        var clip = !(src == (0, 0) && dh >= 0 && dv >= 0 && w == face.width && h == face.height && dh + w <= W
                     && dv + h <= H)
        if rotation != 0 || scale > 0x100 {
            guard (0..<360).contains(Int(rotation)) else { throw Refusal.rotation(rotation) }
            let fr = face.frame
            let S = Double(max(Int(fr.bottom) - Int(fr.top), Int(fr.right) - Int(fr.left)))
            let s = abs(sinTable[Int(rotation)]), c = abs(cosTable[Int(rotation)])
            func i16(_ x: Double) -> Int { Int(Int16(truncatingIfNeeded: Int(x.rounded(.towardZero)))) }
            let top = i16(-(S * s - Double(Int(fr.top) + dv))), left = i16(-(S * c - Double(Int(fr.left) + dh)))
            let bottom = i16(S * s + Double(Int(fr.bottom) + dv)), right = i16(S * c + Double(Int(fr.right) + dh))
            let inPort = 0 <= left && right <= W && 0 <= top && bottom <= H
            if !inPort { clip = true }
        }
        if mode == 0xa { clip = true }
        return clip
    }
}

// MARK: - `.RedrawScrollGrid(rect, 1)`: the mask-only re-stamp `.WrapEraseSprites` calls

extension TileGridRenderer {

    /// `.RedrawScrollGrid(rect, param_2 ≠ 0)` (decompile l. 9812–10088, the `param_2` arms): per cell (col, row)
    /// with FG tile t, BG tile b and overlay o1/o2, only boolean stamps into the mask port, no cell clear, no tile
    /// draw, no light, no copy to the frame: b < 0 ∧ t ≥ 0 → the FG rule (FG face without a transparent pixel or b < 0
    /// → FG stamp) then the overlay o2 stamp; b ≥ 0 → BG stamp, the FG stamp when t ≥ 0 and the BG face has a
    /// transparent pixel, the overlay o2 stamp; then (every cell with o1 = 100 / 101) the overlay stamp again.
    func redrawScrollGridMask(top: Int, left: Int, right: Int, bottom: Int, h: Int, v: Int, ports: inout FramePorts) {
        guard top <= bottom, left <= right else { return }
        let scroll = TileBlitters.Scroll(h: h, v: v)
        let width = Int(level.header.gridWidth), height = Int(level.header.gridHeight)
        let fg = sets.fg.faces, bg = sets.bg.faces
        for row in top...bottom {
            for col in left...right where col >= 0 && col < width && row >= 0 && row < height {
                let x = col << 5, y = row << 5
                let t = level.fgTile(col: col, row: row), b = level.bgTile(col: col, row: row)
                let o1 = level.overlay1(col: col, row: row)
                let o2 = o1 > 99 ? level.overlay2(col: col, row: row) : -1
                // Out of range: the original's `ReportError` and `return` — the rest of the rect is not stamped.
                guard (-1...0x5f).contains(t), (-1...0x5f).contains(b) else { return }
                func stamp(_ face: EncodedFace) {
                    TileBlitters.wrapDraw(face, .bool, into: &ports.mask, x: x, y: y, scroll: scroll)
                }
                func overlay() {
                    guard o2 >= 0 else { return }
                    if o1 == 100, o2 < fg.count { stamp(fg[o2]) } else if o1 == 101, o2 < bg.count { stamp(bg[o2]) }
                }
                if b < 0 && t >= 0 {
                    stamp(fg[t])   // `!fg[t].hasTransparentPixel || b < 0`: b < 0 holds
                    overlay()
                } else if b >= 0 {
                    stamp(bg[b])
                    if t >= 0 && bg[b].hasTransparentPixel { stamp(fg[t]) }
                    overlay()
                }
                overlay()
            }
        }
    }
}
