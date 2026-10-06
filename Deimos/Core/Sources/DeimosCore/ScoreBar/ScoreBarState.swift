import Foundation
import HectorResources

/// The score bar's state (G_ScoreBar.cc; hud-scorebar.md §2–§3, §6–§7): two records of 0x14c bytes at
/// `*(r2−0x6f28)` → `0x10103610`, one per player. ★ LOCKED name (plan S2). The draw is `ScoreBarDraw` (C5).
///
/// Listing read for plan C4 — `FUN_100317e0` (`10031810…10031aac`), per player: clear the six dirty bytes
/// (`10031818..10031830`); not in game (`FUN_10026c10`) or out of lives (`FUN_10026c20`) → if `+0x12e`:
/// `+0x12f` = 0, all six dirty, `+0x12e` = 0 (`10031a6c..10031a9c`), nothing else; otherwise score changed →
/// store + dirty (`1003186c..10031898`), lives changed → store + dirty count (`1003189c..100318c8`), handler
/// `+0x08` → dirty weapons + `FUN_1003bb40` (`100318cc..100318f0`), shield follower (`100318fc..10031994`:
/// `fcmpu` ≠ → dirty; above → `−= F121`, floored at the target; below **and** state 4 (`FUN_10026c60(p, 4)`)
/// → `+= F120`, capped), power follower (`10031998..10031a34`, F127 / F126, the same shape) then the
/// displayed power clamp `< 1.0 → 0.0`, `> 100.0 → 100.0` (`10031a38..10031a64`). Agrees with the contract.
public struct ScoreBarState: Equatable, Sendable {
    /// A {4CC, frame} pair (icons, plde sprite IDs).
    public struct Icon: Equatable, Sendable {
        public var face: FourCC
        public var frame: Int32
        public init(face: FourCC, frame: Int32) { self.face = face; self.frame = frame }
        public static let none = Icon(face: .none, frame: 0)
    }

    /// The six dirty bytes +0x128…+0x12d.
    public struct Dirty: OptionSet, Equatable, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        public static let score = Dirty(rawValue: 1 << 0)        // +0x128
        public static let livesSymbol = Dirty(rawValue: 1 << 1)  // +0x129
        public static let livesCount = Dirty(rawValue: 1 << 2)   // +0x12a
        public static let weapons = Dirty(rawValue: 1 << 3)      // +0x12b
        public static let shield = Dirty(rawValue: 1 << 4)       // +0x12c
        public static let power = Dirty(rawValue: 1 << 5)        // +0x12d
        public static let all: Dirty = [.score, .livesSymbol, .livesCount, .weapons, .shield, .power]
    }

    /// One player's record (0x14c bytes).
    public struct Record: Equatable, Sendable {
        /// +0x00/+0x04, +0x08/+0x0c, +0x10/+0x14: plde `spriteScoreBar`, `…Shield`, `…Power` face/frame.
        public var livesSymbol = Icon.none
        public var shieldMeter = Icon.none
        public var powerMeter = Icon.none
        /// +0x18 / +0x1c: last score / lives drawn.
        public var lastScore: Int32 = 0
        public var lastLives: Int32 = 0
        /// +0x20 / +0x24: displayed shield / power % (followers).
        public var shownShield: Float = 0
        public var shownPower: Float = 0
        /// +0x28…+0xa7: rects R0…R7 (P2: R8…R15) relative to the 160-px bar — score, life symbol, life
        /// count, weapon 1, 2, 3, shields, power.
        public var localRects: [MacRect] = []
        /// +0xa8…+0x127: the same in back-buffer coordinates (+ (D+0x3c, D+0x40) = (0, 416)).
        public var bufferRects: [MacRect] = []
        /// +0x128…+0x12d.
        public var dirty: Dirty = .all
        /// +0x12e: still to be retired (in game at level start; cleared by the one-shot dim redraw).
        public var pendingRetire = false
        /// +0x12f: draw active (false = dimmed, no icons).
        public var drawActive = false
        /// +0x134…+0x14b: weapon icons — current, next, next-after.
        public var icons: [Icon] = [.none, .none, .none]
    }

    /// Record 0 = P1, 1 = P2.
    public var records: [Record]
    /// F120 / F121 ShieldMeterIncrease / DecreaseRate, F126 / F127 PowerMeterIncrease / DecreaseRate.
    let shieldIncrease: Float, shieldDecrease: Float, powerIncrease: Float, powerDecrease: Float

    /// `FUN_10030f40` (hud-scorebar §1, §7): per player the 8 local rects (`FUN_10020220(k)`, k = 0…7 /
    /// 8…15) and their back-buffer copies (+ top `D+0x3c` = 0, left `D+0x40` = F54 = 416); last score / lives
    /// 0, displayed 0.0, all dirty, icons `none`.
    public init(assets: DeimosAssets) {
        let left = Int32(assets.floats[54])                          // D+0x40 = F54 (FUN_1000ae20)
        let top: Int32 = 0                                           // D+0x3c
        records = (0..<2).map { p in
            var r = Record()
            r.localRects = Array(assets.rects[(8 * p)..<(8 * p + 8)])
            r.bufferRects = r.localRects.map {
                MacRect(top: $0.top + top, left: $0.left + left, bottom: $0.bottom + top, right: $0.right + left)
            }
            return r
        }
        shieldIncrease = assets.floats[120]
        shieldDecrease = assets.floats[121]
        powerIncrease = assets.floats[126]
        powerDecrease = assets.floats[127]
    }

    /// `FUN_10031400 @ 10031400(p1, p2)` — the state part (hud-scorebar §7; the image loads and the
    /// element draw are `ScoreBarDraw.levelStartOps`, C5): both players' icons `FUN_1003bb40`
    /// (`1003151c`, `1003152c`), the plde sprite IDs (`1003154c…10031594`), then per player: all six dirty,
    /// displayed shield / power 0.0, last score / lives = current, `+0x12e` = `+0x12f` = in game (`+0xc4`).
    public mutating func levelStart(players: [Player]) {
        for (i, p) in players.prefix(2).enumerated() {
            records[i].icons = p.scoreBarIcons()
        }
        for (i, p) in players.prefix(2).enumerated() {
            let d = p.definition
            records[i].livesSymbol = Icon(face: d.spriteScoreBar, frame: d.spriteScoreBarFrame)
            records[i].shieldMeter = Icon(face: d.spriteScoreBarShield, frame: d.spriteScoreBarShieldFrame)
            records[i].powerMeter = Icon(face: d.spriteScoreBarPower, frame: d.spriteScoreBarPowerFrame)
        }
        for (i, p) in players.prefix(2).enumerated() {
            records[i].dirty = .all
            records[i].shownShield = 0
            records[i].shownPower = 0
            records[i].lastScore = p.score
            records[i].lastLives = p.lives
            records[i].pendingRetire = p.inGame
            records[i].drawActive = p.inGame
        }
    }

    /// `FUN_100317e0 @ 100317e0(p1, p2)` — the per-tick update (see the type's comment). Caller: the
    /// logic tick `FUN_10006b50`, after both players.
    public mutating func update(players: [Player]) {
        for (i, p) in players.prefix(2).enumerated() {
            var r = records[i]
            r.dirty = []                                             // 10031818..10031830
            if !p.inGame || p.lifeState == 1 {                         // 10031848 FUN_10026c10, 1003185c FUN_10026c20
                if r.pendingRetire {                                 // 10031a6c..10031a74
                    r.drawActive = false
                    r.dirty = .all
                    r.pendingRetire = false
                }
                records[i] = r
                continue
            }
            if r.lastScore != p.score { r.lastScore = p.score; r.dirty.insert(.score) }
            if r.lastLives != p.lives { r.lastLives = p.lives; r.dirty.insert(.livesCount) }
            if p.handler.iconsDirty {                                // 100318cc FUN_1003bb30
                r.dirty.insert(.weapons)
                r.icons = p.scoreBarIcons()                          // 100318f0 FUN_1003bb40
            }
            let active = p.lifeState == 4
            Self.follow(&r.shownShield, p.shield, down: shieldDecrease, up: shieldIncrease,
                        rise: active, dirty: &r.dirty, flag: .shield)
            Self.follow(&r.shownPower, p.handler.powerPercent, down: powerDecrease, up: powerIncrease,
                        rise: active, dirty: &r.dirty, flag: .power)
            Self.clampPower(&r.shownPower)                           // 10031a38..10031a64
            records[i] = r
        }
    }

    /// One follower (`100318fc..10031994` / `10031998..10031a34`), single precision.
    private static func follow(_ shown: inout Float, _ target: Float, down: Float, up: Float, rise: Bool,
                               dirty: inout Dirty, flag: Dirty) {
        guard shown != target else { return }                        // fcmpu; beq
        dirty.insert(flag)
        if shown > target {                                          // fcmpo; ble
            shown = shown - down                                     // fsubs
            if shown < target { shown = target }                     // fcmpo; bge
        } else if shown < target && rise {                           // bge; FUN_10026c60(p, 4)
            shown = shown + up                                       // fadds
            if shown > target { shown = target }                     // fcmpo; ble
        }
    }

    /// The displayed-power clamp: `< 1.0 → 0.0`, `> 100.0 → 100.0`.
    private static func clampPower(_ v: inout Float) {
        if v < 1 { v = 0 } else if v > 100 { v = 100 }
    }

    /// `FUN_10031710(idx, v)`: displayed shield = v (no clamp).
    public mutating func setShownShield(index: Int, _ v: Float) {
        guard records.indices.contains(index) else { return }
        records[index].shownShield = v
    }

    /// `FUN_10031760(idx, v)`: displayed power = v with the 1.0 / 100.0 clamp.
    public mutating func setShownPower(index: Int, _ v: Float) {
        guard records.indices.contains(index) else { return }
        var x = v
        Self.clampPower(&x)
        records[index].shownPower = x
    }
}
