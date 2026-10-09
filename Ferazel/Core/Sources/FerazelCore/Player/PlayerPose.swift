import Foundation

/// ◇ Phase-1 stub (plan S2; replaced by `.HandlePlayerSprite @ 1004d5fc` in Phase 2): Ferazel standing at his start
/// point, walking / running in place on left / right, turning and fidgeting — the grounded face arms of player-states
/// §3.11 transcribed from the handler (`ghidra/ferazel/Ferazel_handlers.decompiled.c` l. 652ff.; the same body in the
/// main dump l. 44396ff.), with no physics: the player never moves and his velocity is 0.
///
/// Start state: `.GameLoop(hdr+0x2848 − 0x20, hdr+0x2846 − 0x20, 0, 1)` (`.NewGame` l. 5823) →
/// `MTNewSprite(0, x, y, 10, …)` (`.GameLoop` l. 5181) → `.SetupPlayerSprite @ 1004aefc` (l. 42781): layer 10, face
/// `+0xc0 = 0` (no face until the first Handle), hot rect `+0x34 = SetRect(0x26, 0x22, 0x3e, 0x55)`, `+0x17e` and the
/// facing `_DAT_100a5f5a/5f5c` from `G+0x16` (0 → F = 2 right, `+0x17e = 0`; else F = 1, `+0x17e = 1`; l. 42963–42972),
/// `+0x46 = param_3 = 0` (l. 5187). `.ClearPlayerVars @ 1004aa48` zeroes the counters and sets the breath phase
/// `sRam100a5f5e = 3` (l. 42603).
///
/// One `step` = the Handle's order: idle `+1` (handler l. 846), the `.HandleKeys` L/R arm (main l. 47360–47480: idle
/// and fidgets 0, walk flag, run flag `_DAT_100a072c`, exertion +1 (< 0xb9) walking / +3 running; F from the key —
/// the binary takes F from the sign of vx, which is 0 here), `.HandleBreathing @ 1004bb44` (l. 43314; no oxygen
/// deficit, no bubbles, no sound), the grounded face arms (handler l. 2078–2347), and `+0x17e = (F ≠ 2)`, inverted
/// while the turn flag `PTR_DAT_100a06c4` is set (l. 2457).
public struct PlayerPose: Equatable, Sendable {
    /// `_DAT_100a5f5a`: 1 left, 2 right.
    public enum Facing: Int, Sendable { case left = 1, right = 2 }

    /// `.SetupPlayerSprite`'s layer `+0x80`.
    public static let layer: Int32 = 10
    /// `+4 = 0x45`.
    public static let spriteType: Int16 = 0x45
    /// The hot rect `+0x34` (QuickDraw top, left, bottom, right) in face-local px.
    public static let hotRectLocal = IdleSprites.Rect(top: 0x22, left: 0x26, bottom: 0x55, right: 0x3e)
    /// Face sets (player-states §7): stand 1003 (`_DAT_100a07ec`), walk 1020 (`07d0`), run 1024 (`07c0`), turn 1030
    /// (`07ac`), fidget 1 1029 (`07b0`), fidget 2 1028 (`07b4`).
    public static let stand: Int16 = 1003, walk: Int16 = 1020, run: Int16 = 1024, turn: Int16 = 1030
    public static let fidget1: Int16 = 1029, fidget2: Int16 = 1028

    /// The sprite's top-left `+0xc` / `+0xa` (never moved in Phase 1).
    public let x: Int
    public let y: Int
    /// `_DAT_100a5f5a` this frame / `_DAT_100a5f5c` last frame.
    public private(set) var facing: Facing
    public private(set) var previousFacing: Facing
    /// `+0xc0` (nil = 0).
    public private(set) var face: FaceRef?
    /// `+0x17e`.
    public private(set) var mirrored: Bool
    /// `PTR_DAT_100a06c4`: the turn's "drawn with the old facing" flag (cleared at the top of every Handle).
    public private(set) var turnFlag = false
    /// `PTR_DAT_100a06c8`: the turn countdown.
    public private(set) var turnCountdown = 0
    /// `+0x46`: the walk / run phase.
    public private(set) var phase: Int
    /// `_DAT_100a0728`: walking last frame.
    public private(set) var walking = false
    /// `PTR_DAT_100a0670`: standing (the stand entry sets chest frame 3 when 0).
    public private(set) var standing = false
    /// `_DAT_100a072c`: the run flag.
    public private(set) var running = false
    /// `PTR_DAT_100a04fc`: the chest frame (index into 1003). Not initialised by `.ClearPlayerVars`; 0 here.
    public private(set) var chestFrame = 0
    /// `sRam100a5f5e` / `_DAT_100a06a8` / `_DAT_100a06b0`: breath phase, last phase, period counter.
    public private(set) var breathPhase = 3
    public private(set) var previousBreathPhase = 0
    public private(set) var breathPeriod = 0
    /// `_DAT_100a06a4`: exertion.
    public private(set) var exertion = 0
    /// `_DAT_100a068c` / `_DAT_100a0688`: idle frames, fidgets played.
    public private(set) var idle = 0
    public private(set) var fidgets = 0

    public init(header: LevelHeader, entryPhase: Int = 0) {
        x = Int(header.startX) - 0x20
        y = Int(header.startY) - 0x20
        facing = header.startFacingLeft == 0 ? .right : .left
        previousFacing = facing
        mirrored = header.startFacingLeft != 0
        phase = entryPhase
    }

    /// The hot rect in world px (what `.HandleIdleSprites` unions into its window).
    public var hotRect: IdleSprites.Rect {
        let r = Self.hotRectLocal
        return IdleSprites.Rect(top: y + r.top, left: x + r.left, bottom: y + r.bottom, right: x + r.right)
    }

    /// The sprite record the active list holds.
    public var slot: SpriteSlot {
        var s = SpriteSlot(type: Self.spriteType, x: x, y: y, layer: Self.layer, face: face)
        s.mirrored = mirrored
        return s
    }

    private func ref(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// One Handle frame with these actions held (Phase 1: no physics, vx = 0).
    public mutating func step(left: Bool, right: Bool, run: Bool) {
        previousFacing = facing                                // `5f5c = 5f5a` (main l. 44487)
        turnFlag = false                                       // `*puVar19 = 0` (handler prologue)
        idle += 1                                              // l. 846
        // `.HandleKeys`: the L arm, then the R arm (R wins when both are held: both write F).
        var walkFlag = false
        for (held, f) in [(left, Facing.left), (right, Facing.right)] where held {
            idle = 0
            fidgets = 0
            walkFlag = true
            if run {
                exertion += 3
            } else if exertion < 0xb9 {
                exertion += 1
            }
            running = run
            facing = f
        }
        breathe()
        if walkFlag {
            if idle > 0 { idle = fidgets }
            if !walking { phase = 0xc }
            walking = true
            standing = false
            if running {
                phase += 2
                turnCountdown = 0
                if phase > 0x17 { phase = 0 }
                face = ref(Self.run, phase >> 1)
                finish()
                return
            }
            phase += 2
            if phase > 0x1f { phase = 0 }
            // `(0x5db < |vx| || F == F') && countdown < 1` — vx is 0 in Phase 1.
            if facing == previousFacing && turnCountdown < 1 {
                turnCountdown = 0
                face = ref(Self.walk, phase >> 1)
                finish()
                return
            }
        }
        // Stand (handler l. 2190ff.).
        walking = false
        if !standing { chestFrame = 3 }
        standing = true
        if idle < 0x96 {
            if turnCountdown < 1 {
                if previousFacing == facing {
                    face = ref(Self.stand, chestFrame)
                } else {
                    turnCountdown = 4
                    face = ref(Self.turn, 0)
                    turnFlag = true
                }
            } else {
                turnCountdown -= 1
                switch turnCountdown {
                case 3: face = ref(Self.turn, 1); turnFlag = true
                case 2: face = ref(Self.turn, 2); turnFlag = true
                case 1: face = ref(Self.turn, 1)
                case 0: face = ref(Self.turn, 0)
                default: break
                }
            }
            // The potion, wand and uphill-slope overlays are not reached in Phase 1.
        } else {
            var m = idle - 0x96
            let raw = m
            if fidgets < 3 {
                if raw < 100 {
                    if raw > 7 { m = 8 }
                    face = ref(Self.fidget1, m / 3)
                }
                if m < 100 || m > 0x8b {
                    if m >= 0x8c && m <= 0x9b {
                        let s = min(m - 0x8c, 0xf)
                        face = ref(Self.fidget1, (0xf - s) / 3)
                    } else if m > 0x9b {
                        idle = 0
                        fidgets += 1
                    }
                } else {
                    let s = min(m - 0x5c, 0xf)
                    face = ref(Self.fidget1, s / 3)
                }
            } else {
                face = ref(Self.fidget2, (raw - (raw / 20) * 20) >> 1)
                if raw > 0xf0 {
                    idle = 0                                   // `-FastRand(60)`: the PRNG is not modelled (MED)
                    fidgets = 0
                }
            }
        }
        finish()
    }

    /// l. 2457: `+0x17e = (F != 2)`, inverted while the turn flag is set.
    private mutating func finish() {
        mirrored = facing != .right
        if turnFlag { mirrored.toggle() }
    }

    /// `.HandleBreathing` without an oxygen deficit (`G+6 ≥ G+4`) or bubbles: exertion −2 while > 0; level
    /// `L = clamp((min(E, 600) − 100) >> 6, 2, 6)`; the period counter reloads with `9 − L` at ≤ 0 and the phase
    /// advances unless (chest frame 1, E < 0xa0, last phase ≥ 2); the phase wraps after 5; chest = phase, or 6 − phase
    /// above 3.
    private mutating func breathe() {
        if exertion > 0 { exertion -= 2 }
        if exertion > 600 { exertion = 600 }
        let e = min(exertion, 600)
        let level = min(max((e - 100) >> 6, 2), 6)
        breathPeriod -= 1
        if breathPeriod < 1 {
            breathPeriod = 9 - level
            if chestFrame != 1 || e > 0x9f || previousBreathPhase < 2 {
                breathPhase += 1                               // phase 2: bubble / breath sound — not modelled
            }
        }
        if breathPhase > 5 { breathPhase = 0 }
        chestFrame = breathPhase > 3 ? 6 - breathPhase : breathPhase
        previousBreathPhase = breathPhase
    }
}
