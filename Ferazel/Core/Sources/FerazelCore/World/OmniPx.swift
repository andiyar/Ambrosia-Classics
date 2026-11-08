import Foundation

/// One drawn frame's `.UpdateOmniPx @ 1001a434` (M l. 13393–13519; rendering-omnipx-titles §3.4), as `DrawOp.omniPx`
/// hands it to the renderer: the base cell copied over the 128×128 port, then each loaded face blitted at its (x, y)
/// — and, unless both are 0, at (x + 128, y), (x + 128, y + 128), (x, y + 128) so it wraps toroidally — in face-slot
/// order. The port is PxBack slot 0 while OmniPx is on (`.TurnOnOmniPx`, M l. 13055–13056).
public struct OmniPxFrame: Equatable, Sendable {
    /// One face's blit: `BlitEncFaceClipX(face, port, (0, 0), (y, x), 128, 128)` (M l. 13497–13504).
    public struct Face: Equatable, Sendable {
        /// The face's PICT (`.Load1EncFaceFromPICT(pict, 0, 0, 0)` at `.SetupOmniPx`, the level+sprite CLUT).
        public var pict: Int16
        /// x, y ∈ (−128, 128): the negated truncating remainder (M l. 13488–13496).
        public var x: Int
        public var y: Int

        public init(pict: Int16, x: Int, y: Int) {
            self.pict = pict; self.x = x; self.y = y
        }

        /// The blit points [x, y] in call order: (x, y), then the three wraps when x ≠ 0 or y ≠ 0 (M l. 13498–13505).
        public var draws: [[Int]] {
            guard x != 0 || y != 0 else { return [[x, y]] }
            return [[x, y], [x + 0x80, y], [x + 0x80, y + 0x80], [x, y + 0x80]]
        }
    }

    /// Header `0x26c7` (2, 4 or 5 on a level that opens: `LevelRun.refuseUndrawnHeader`).
    public var omniPxMode: UInt8
    /// Modes 2 / 4 / 5: the PxBack slot `6 + (c >> 1)` copied over the port first (M l. 13429–13436); nil = no base.
    public var baseCell: Int?
    /// The loaded faces' blits, face slots 0…15 in order (null faces skipped, M l. 13469).
    public var faces: [Face]

    public init(omniPxMode: UInt8, baseCell: Int?, faces: [Face]) {
        self.omniPxMode = omniPxMode; self.baseCell = baseCell; self.faces = faces
    }
}

/// OmniPx (header `0x26c7`; rendering-omnipx-titles §3, M l. 13019–13547): a 128×128 port that replaces PxBack cell 0
/// and is rebuilt on every drawn frame from an animated base (other PxBack cells) and up to 16 wrapping faces, each
/// scrolled by its own parallax factor and drift. Core holds the state — the mode, the 16 face refs, the six 16-entry
/// `Int16` arrays (fx `0x100a373c`, fy `375c`, vx `377c`, vy `379c`, accX `37bc`, accY `37dc`), the counter `c`
/// (`0x100f97e8`, BSS: never reset between levels — `LevelCarry.omniPxCounter`) and the factor backup
/// (`0x100f00a8` / `0x100f40a8`); the on-flag is G+0x174 (`GameGlobals.omniPxActive`). The port's pixels are Render's.
///
/// Life cycle (§3.2): `.SetupLevel` clears G+0x174 and calls `setup` (M l. 2539–2540); each drawn `.PaintFrameWrap`
/// calls `update` after `.DrawParticles` (M l. 9434); `.GameLoop`'s exit calls `turnOff` and `kill` (M l. 5321–5322).
/// Modes 1, 3, 6, 7 and ≥ 8 are refused at level open (`LevelRun.refuseUndrawnHeader`; ◇ Phase 6 6A-RN).
public struct OmniPx: Equatable, Sendable {
    /// The 16 layer slots.
    public static let layers = 0x10
    /// The port's side.
    public static let size = 0x80

    /// Header `0x26c7`, as `.SetupOmniPx` read it (every reader re-reads the header byte; it never changes).
    public internal(set) var omniPxMode: UInt8 = 0
    /// `0x100a36fc`: the 16 face pointers, as the PICT each was loaded from (nil = none).
    public internal(set) var faces = [Int16?](repeating: nil, count: OmniPx.layers)
    /// Per-face parallax factors (/256) and drift (1/256 px per drawn frame), and the drift accumulators.
    public internal(set) var fx = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var fy = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var vx = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var vy = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var accX = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var accY = [Int16](repeating: 0, count: OmniPx.layers)
    /// `c`, the i16 at `0x100f97e8` (slot `PTR_DAT_100a008c`): loaded only by `.UpdateOmniPx`.
    public internal(set) var counter: Int16
    /// `0x100f00a8` (8192 i16) / `0x100f40a8`: `.TurnOnOmniPx`'s backup of hdr+0x326c / hdr+0xb26c. BSS: zero until a
    /// zeroing mode backs them up (Core keeps them per level; the copy back into an ending level is unseen, §3.2).
    var backFactorsBackup = [Int16](repeating: 0, count: LevelFile.factorRows)
    var backYFactorBackup: Int16 = 0

    public init(counter: Int16 = 0) {
        self.counter = counter
    }

    /// The faces `.SetupOmniPx` loads for a mode (M l. 13246–13291), face 0 first: modes 2 and 4 → 6201 / 6200
    /// (`0x1839` / `0x1838`); 5 → 6301 / 6300 (`0x189d` / `0x189c`); 1 → 6000 / 6001; every other mode none.
    public static func facePicts(omniPxMode m: UInt8) -> [Int16] {
        switch m {
        case 2, 4: return [0x1839, 0x1838]
        case 5: return [0x189d, 0x189c]
        case 1: return [6000, 0x1771]
        default: return []
        }
    }

    /// `.TurnOnOmniPx`'s test (M l. 13045): `mode != 4 && (byte)(mode − 5) > 2` — every mode outside 4…7 backs up and
    /// zeroes the PxBack factors (the grid fixed to the view, §3.5).
    public static func turnOnZeroesFactors(omniPxMode m: UInt8) -> Bool { m != 4 && m &- 5 > 2 }

    /// `.SetupOmniPx @ 10019d78` (M l. 13125–13297). The once-only clear of the 16 face pointers (`*0x100a00b0`, M l.
    /// 13158–13170) is this type's initial `faces`. Mode 0: G+0x174 = 0 and return. Else the port
    /// (`NewBlitPort(128, 128, level+sprite CLUT)`, Render's; its failure path — `ReportError`, off — is not
    /// reachable here), the six arrays zeroed, the mode's faces and parameters, then `.TurnOnOmniPx`.
    public mutating func setup(level: inout LevelFile, globals: inout GameGlobals) {
        omniPxMode = level.header.omniPxMode
        guard omniPxMode != 0 else {
            globals.omniPxActive = 0                                  // M l. 13172–13175
            return
        }
        let zero = [Int16](repeating: 0, count: Self.layers)          // M l. 13186–13238
        fx = zero; fy = zero; vx = zero; vy = zero; accX = zero; accY = zero
        let picts = Self.facePicts(omniPxMode: omniPxMode)
        for (i, p) in picts.enumerated() { faces[i] = p }
        switch omniPxMode {
        case 2, 4, 5:
            // M l. 13246–13256 (mode 5) and 13282–13291 (modes 2, 4): the same parameters.
            fx[0] = 0x40; fy[0] = 0x40; fx[1] = 0x80; fy[1] = 0x80
            vx[0] = -0x80; vy[0] = -0x200                            // 0xff80, 0xfe00
            vx[1] = 0x80; vy[1] = 0x400
        case 1:
            // M l. 13261–13277: faces 6000 / 6001. The stores to layers 3…5 (and `0x100a3802`, past the accY array)
            // are dead: those faces are never loaded, and the face loop skips a null face (§3.3).
            fx[0] = 0x40; fy[0] = 0x40; fx[1] = 0x80; fy[1] = 0x80
            vx[0] = 0x100; vy[0] = 0x500; vx[1] = 0x200; vy[1] = 0x800
            fx[3] = 0xc0; fy[3] = 0xc0; fx[4] = 0xd2; fy[4] = 0xd2; fx[5] = 0xe6; fy[5] = 0xe6
        default:
            break                                                     // 3, 6, 7, ≥ 8: no faces
        }
        turnOn(level: &level, globals: &globals)                     // LAB_1001a14c (M l. 13292–13293)
    }

    /// `.TurnOnOmniPx @ 10019ac4` (M l. 13019–13060): nothing when G+0x174 is already set; else set it and, for a mode
    /// outside 4…7, back up and zero the 8192 PxBack x-factors (hdr+0x326c) and `yb` (hdr+0xb26c) — Core's copy of
    /// the header, so every later Core read sees zeros. Saving PxBack slot 0 and storing the port there is Render's.
    public mutating func turnOn(level: inout LevelFile, globals: inout GameGlobals) {
        guard globals.omniPxActive == 0 else { return }
        globals.omniPxActive = 1
        guard Self.turnOnZeroesFactors(omniPxMode: level.header.omniPxMode) else { return }
        backFactorsBackup = level.backFactors
        backYFactorBackup = level.header.pxBackYFactor
        level.backFactors = [Int16](repeating: 0, count: level.backFactors.count)
        level.header.pxBackYFactor = 0
    }

    /// `.TurnOffOmniPx @ 10019bac` (M l. 13061–13121): when G+0x174 is set, clear it and copy the backup back into
    /// hdr+0x326c / hdr+0xb26c — always, also after modes 4…7, whose backup is stale (§3.2: harmless, every level start
    /// re-reads `Mlvl`). Restoring PxBack slot 0 is Render's.
    public mutating func turnOff(level: inout LevelFile, globals: inout GameGlobals) {
        guard globals.omniPxActive != 0 else { return }
        globals.omniPxActive = 0
        level.backFactors = backFactorsBackup
        level.header.pxBackYFactor = backYFactorBackup
    }

    /// `.KillOmniPx @ 1001a86c` (M l. 13520–13547): every face disposed (the port is Render's).
    public mutating func kill() {
        faces = [Int16?](repeating: nil, count: Self.layers)
    }

    /// `.UpdateOmniPx @ 1001a434` (M l. 13393–13519) at scroll (h, v) (`PTR_DAT_1009fe78`): nil while G+0x174 is clear.
    /// Modes 2, 4, 5: `if c > 0x11 { c = 0 }`, then the base cell `6 + (c >> 1)` — c is not incremented there. Then
    /// each loaded face i: `c += 1`; `accX += vx`, `accY −= vy` as shorts, each > 0x7fff → − 0x8000 (never true of a
    /// short) and negative → − 0x8000 as a 16-bit short; x = −(((accX >> 8) + (H·fx >> 8)) rem 128), y likewise with
    /// accY, V and fy (truncating remainder, 16-bit results). No RNG.
    public mutating func update(globals: GameGlobals, h: Int, v: Int) -> OmniPxFrame? {
        guard globals.omniPxActive != 0 else { return nil }
        var base: Int?
        switch omniPxMode {
        case 2, 4, 5:
            if counter > 0x11 { counter = 0 }                         // M l. 13430–13432
            base = 6 + Int(counter >> 1)                              // `0x100a4f2c + 4·(c >> 1)` = slot 6 + (c >> 1)
        default:
            // later: Phase 6 (6A-RN) — mode 6's `.InterlaceBlit128` base (M l. 13438–13446) and mode 7's ping-pong
            // copy (M l. 13447–13465), each with its own `c` step; refused at level open until then.
            break
        }
        let H = Int32(Int16(truncatingIfNeeded: h)), V = Int32(Int16(truncatingIfNeeded: v))
        var drawn: [OmniPxFrame.Face] = []
        for i in 0..<Self.layers {
            guard let pict = faces[i] else { continue }
            counter &+= 1                                             // M l. 13471
            accX[i] = accX[i] &+ vx[i]                                // M l. 13474
            accY[i] = accY[i] &- vy[i]                                // M l. 13475
            // `if (0x7fff < acc) acc −= 0x8000` (M l. 13476–13481): a short is never above 0x7fff.
            if accX[i] < 0 { accX[i] = Int16(truncatingIfNeeded: Int(accX[i]) - 0x8000) }   // M l. 13482–13484
            if accY[i] < 0 { accY[i] = Int16(truncatingIfNeeded: Int(accY[i]) - 0x8000) }   // M l. 13485–13487
            drawn.append(OmniPxFrame.Face(pict: pict, x: Self.offset(acc: accX[i], scroll: H, factor: fx[i]),
                                          y: Self.offset(acc: accY[i], scroll: V, factor: fy[i])))
        }
        return OmniPxFrame(omniPxMode: omniPxMode, baseCell: base, faces: drawn)
    }

    /// `u = (acc >> 8) + (scroll·factor >> 8)` (int), then `−((short)u + (short)(u / 128)·−0x80)` as a short — the
    /// negated truncating remainder (M l. 13488–13496).
    static func offset(acc: Int16, scroll: Int32, factor: Int16) -> Int {
        let u = Int32(acc >> 8) &+ ((scroll &* Int32(factor)) >> 8)
        let r = Int32(Int16(truncatingIfNeeded: u)) &+ Int32(Int16(truncatingIfNeeded: u / 0x80)) &* -0x80
        return Int(Int16(truncatingIfNeeded: -r))
    }
}
