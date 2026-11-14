import Foundation
import HectorResources

/// The parallax horizon strip (triggers-background-2 §4): one Backgrounds PICT (768 wide) repeated as sprites that
/// move at fx/256 and fy/256 of the camera. Not a pixel effect — drawn by `.WrapDrawSprites` like any sprite (the
/// drawing is R4's; this type holds what `.MTAddPxSprite` creates and what `.HandlePxSprite` computes).
///
/// `.SetupLevel` (decompile l. 2252–2268 / 2346–2354) calls `.MTKillPxSprites` and then, when header `0x2716 ≠ 0`,
/// `.MTAddPxSprite(0x2716 PICT, 0x2718 x factor, 0x271a y)` with Backgrounds open.
///
/// `.MTAddPxSprite @ 1003359c` (raw): `N = ⌊((fx·(W << 5)) >> 8) / 768⌋ + 1` (`100335ec..1003360c`, W = header `0xb280`,
/// `mulhw 0x2aaaaaab` + `srawi 7` = truncating /768); one face (`.Load1EncFaceFromPICT`, `1003363c`; under the
/// level+base CLUT `*1009ff8c` when header `0x26cc ≠ 0`, `10033614..10033628`); then the loop `k = 0, 1, …` while
/// `k ≤ min(N, 31 − count)` (`10033724..10033740`, `ble`), `count += 1` each pass — so **N + 1 copies** (k = 0...N,
/// at most 16 because the count grows with k), each `.MTNewSprite(0, 0, 0, layer −500, −1, .SetupPxSprite)`
/// (`10033670..10033688`) with `+0x14c = 0x300·k`, `+0x150 = y`, `+0x154 = fx`, `+0x158 = header 0xb26c` (the
/// PxBack y factor). As written the slot index is `count + k` read after `count` already grew by k (`1003368c..
/// 1003369c`), so the copies sit in slots 0, 2, 4, … of the 32-entry table — invisible to drawing.
///
/// `.SetupPxSprite @ 10033418`: empty rect, `+0x48 = 0x1ff`, `+0xea = 1`, type `+4 = 1`, `+0x88 = 0` (no light
/// overlay), `+0x5c = 0`, `+0x1f8 = 0`, handler `.HandlePxSprite`, draw mode `+0xb8 = 0x80000` (behind tiles,
/// draw-effects §2.5: word add through the mask port).
public struct PxSprites: Equatable, Sendable {
    /// `.MTNewSprite` layer argument (`10033680 li r6,-0x1f4`).
    public static let layer = -500
    /// `+0xb8` (`.SetupPxSprite`).
    public static let drawMode: UInt32 = 0x80000
    /// The x step between copies, `+0x14c = 0x300·k` (`10033714`).
    public static let copySpacing = 0x300
    /// `.HandlePxSprite`'s fixed y term (`100333e4 addi r0,r4,0xe8`).
    public static let yOffset = 0xe8
    /// The sprite table holds 31 strip sprites at most (`10033728 subfic r0,r0,0x1f`).
    public static let maxSprites = 0x1f

    /// One strip sprite's fields.
    public struct Sprite: Equatable, Sendable {
        /// `+0x14c` = 768·k.
        public let x0: Int
        /// `+0x150` = header `0x271a`.
        public let y0: Int
        /// `+0x154` = header `0x2718`.
        public let fx: Int
        /// `+0x158` = header `0xb26c`.
        public let fy: Int

        public init(x0: Int, y0: Int, fx: Int, fy: Int) {
            self.x0 = x0; self.y0 = y0; self.fx = fx; self.fy = fy
        }

        /// `.HandlePxSprite @ 10033378` for scroll (h, v) (`PTR_DAT_1009fe78`: v at +0, h at +2):
        /// `+0xc = int16(int16(x0 − (h·fx >> 8)) + h)` (`10033398..100333d8`, srawi), `+0xa = int16(y0 − (v·fy >> 8) +
        /// v + 232)` (`100333b0..100333ec`).
        public func position(h: Int, v: Int) -> (x: Int, y: Int) {
            let x = Int(Int16(truncatingIfNeeded: Int(Int16(truncatingIfNeeded: x0 - ((h * Int(Int16(truncatingIfNeeded: fx))) >> 8))) + h))
            let y = Int(Int16(truncatingIfNeeded: y0 - ((v * Int(Int16(truncatingIfNeeded: fy))) >> 8) + v + PxSprites.yOffset))
            return (x, y)
        }
    }

    /// Header `0x2716` (Backgrounds PICT).
    public let pict: Int16
    /// Header `0x26cc ≠ 0`: the face converts under the level+base CLUT `0x285e`. Otherwise under whatever
    /// `*1009ff94` holds at `.SetupLevel` time (not traced here; R4 reads it when it draws the strip).
    public let usesLevelBaseClut: Bool
    /// The formula value `N = ⌊((fx·W·32) >> 8) / 768⌋ + 1`.
    public let n: Int
    /// The copies in creation order (k = 0...min(N, 15)).
    public let sprites: [Sprite]

    /// `.MTAddPxSprite` for a freshly killed strip table (`.MTKillPxSprites` first, count 0); nil when the level has
    /// no strip (header `0x2716 == 0`, every level but 10, 30, 40, 45, 62, 67).
    public init?(header: LevelHeader) {
        guard header.stripPict != 0 else { return nil }
        let fx = Int(header.stripFactor)
        let product = Int(Int32(truncatingIfNeeded: fx * (Int(header.gridWidth) << 5)))
        let n = Int(Int32(truncatingIfNeeded: (product >> 8) / 0x300)) + 1
        var sprites: [Sprite] = []
        var count = 0
        var k = 0
        while k <= min(n, Self.maxSprites - count) {
            sprites.append(Sprite(x0: Self.copySpacing * k, y0: Int(header.stripBaseY), fx: fx,
                                  fy: Int(header.pxBackYFactor)))
            count += 1
            k += 1
        }
        pict = header.stripPict
        usesLevelBaseClut = header.pxUsesLevelBaseClut != 0
        self.n = n
        self.sprites = sprites
    }
}

// MARK: - 6A-S8: the strip's real records (ENG §2.1)

extension PxSprites {
    /// `*_DAT_1009ff94` at the long path's add: `.SetupLevel` stores `*_DAT_100a0020` there (M l. 2273, through
    /// `piVar9 = _DAT_1009ff94`, M l. 2235), and `_DAT_100a0020` is `GetCTable(200)` (`.InitAppGlobals` M l. 404–405;
    /// `.main` M l. 8262–8265). Between M l. 2273 and the add (M l. 2353) only `_CheckFlags`, `_MTKillPxSprites` and the
    /// open-failure report run. The restart fast path (M l. 2252–2268) does not reset the pointer: it holds what the
    /// last writer left, and every alias store reached between a strip level's start and its restart restores clut 200
    /// (`LevelRun.setupLevel` lists them) — so both paths pass this value.
    public static let setupLevelClut: Int16 = 200

    /// The colour table a strip face converts under when `*_DAT_1009ff94` holds `pointer` at the add: the level+base
    /// CLUT `*_DAT_1009ff8c` (header `0x285e`, 0 → 202) when header `0x26cc` ≠ 0 (M l. 30885–30886), else `pointer`.
    public static func faceClut(header: LevelHeader, pointer: Int16) -> Int16 {
        header.pxUsesLevelBaseClut != 0 ? ColorLUT.screenClutId(header) : pointer
    }

    /// The strip face `+0xc0` (`.Load1EncFaceFromPICT(pict, 0, 0, 0)` from the Backgrounds file opened on top).
    public static func face(pict: Int16) -> FaceRef { FaceRef(pict: pict, index: 0, set: .backgroundsSingle) }

    /// The strip globals: the 32-entry sprite table `_DAT_100a01d4`, the 32-entry face table `_DAT_100a01d0`, the
    /// sprite count `*_DAT_100a01bc` and the face count `*_DAT_100a01b8`.
    public struct Table: Equatable, Sendable {
        public static let entries = 0x20
        /// `_DAT_100a01d4`: sprite ids (nil = 0). `.MTAddPxSprite` stores at entry count + k with the count already
        /// advanced by the earlier passes (M l. 30904), so the ids land in every other entry.
        public var sprites: [Int?] = Array(repeating: nil, count: Table.entries)
        /// `_DAT_100a01d0`: the faces (nil = 0), one per successful add (M l. 30920).
        public var faces: [FaceRef?] = Array(repeating: nil, count: Table.entries)
        /// `*_DAT_100a01bc`.
        public var spriteCount: Int16 = 0
        /// `*_DAT_100a01b8`.
        public var faceCount: Int16 = 0

        public init() {}

        /// The table's sprite ids, entry order (= creation order).
        public var ids: [Int] { sprites.compactMap { $0 } }

        /// `.MTKillPxSprites @ 100334b8` (M l. 30820–30852): every non-zero sprite entry `.MTKillSprite`d and zeroed,
        /// every face disposed and zeroed, both counts 0.
        public mutating func kill(world: SpriteWorld) {
            for k in sprites.indices {
                if let id = sprites[k] {
                    world.active.remove(id: id)
                    sprites[k] = nil
                }
            }
            for k in faces.indices { faces[k] = nil }
            spriteCount = 0
            faceCount = 0
        }

        /// What one `.MTAddPxSprite` did.
        public enum Outcome: Equatable, Sendable {
            /// The face count was ≥ 31: the whole routine skipped (M l. 30884) — no face, no sprite, no CLUT swap.
            case skipped
            /// `.Load1EncFaceFromPICT` returned 0: `.ReportError(…, 0)` and nothing else (M l. 30888–30890) — no
            /// sprite, no face entry, and the CLUT pointer left as the `0x26cc` swap made it (the restore of M l. 30919
            /// is in the success branch).
            case faceLoadFailed
            /// The face loaded under `faceClut`; the copies were made (some ids nil when `.MTNewSprite` found no
            /// record — the count still advanced, M l. 30917).
            case added(faceClut: Int16)
        }

        /// `.MTAddPxSprite @ 1003359c (pict, fx, y)` (M l. 30853–30927), transcribed. `clut` is `*_DAT_1009ff94` (by
        /// id). N = ⌊((fx·W·32) >> 8) / 768⌋ + 1 (C division, W = header `0xb280`); skipped whole at face count ≥ 31;
        /// the face from the Backgrounds file (its absence is the load failure — the Backgrounds file holds all six
        /// shipped strip PICTs; the Resource Manager's fall-through to the files below it is not modelled [LOW]);
        /// then k = 0, 1, … while k ≤ min(N, 31 − count), the cap re-read each pass: `.MTNewSprite(0, 0, 0, −500, −1,
        /// .SetupPxSprite)` at entry count + k, `+0xc0` face, `+0x14c` 768·k, `+0x150` y, `+0x154` fx, `+0x158`
        /// header `0xb26c`; count + 1 each pass; then the pointer restored and the face appended.
        public mutating func add(pict: Int16, fx: Int16, y: Int16, header: LevelHeader, backgrounds: ResourceCollection,
                                 clut: inout Int16, world: SpriteWorld) -> Outcome {
            let saved = clut                                                       // `uVar11 = *_DAT_1009ff94`
            let product = Int32(truncatingIfNeeded: Int(fx) &* Int(header.gridWidth) &* 0x20)
            let quotient = (product >> 8) / 0x300                                  // truncating, as the C division
            guard faceCount < 0x1f else { return .skipped }                        // M l. 30884
            if header.pxUsesLevelBaseClut != 0 { clut = ColorLUT.screenClutId(header) }   // M l. 30885–30886
            guard backgrounds.resource(type: "PICT", id: pict) != nil else { return .faceLoadFailed }
            let loadedUnder = clut
            let face = PxSprites.face(pict: pict)
            let n = Int(Int16(truncatingIfNeeded: quotient &+ 1))                  // `(short)(N + 1)`
            var k = 0
            var x0: Int32 = 0
            while true {
                let cap = min(n, 0x1f - Int(spriteCount))                          // M l. 30897–30900
                if cap < k { break }
                let id = world.newSprite(type: 0, x: 0, y: 0, layer: Int16(PxSprites.layer), handler: .pxSprite,
                                         record: -1) { PxSprites.setup(&$0) }
                let entry = Int(spriteCount) + k                                   // M l. 30904
                if sprites.indices.contains(entry) { sprites[entry] = id }
                if let id {
                    let yb = header.pxBackYFactor
                    world.active.update(id: id) { s in
                        s.face = face                                              // `+0xc0`
                        s.classTimer = x0                                          // `+0x14c`
                        s.classWord150 = Int32(y)                                  // `+0x150`
                        s.classWord154 = Int32(fx)                                 // `+0x154`
                        s.classWord158 = Int32(yb)                                 // `+0x158`
                    }
                }
                x0 &+= Int32(PxSprites.copySpacing)
                k += 1
                spriteCount &+= 1                                                  // M l. 30917, also on a failed spawn
            }
            clut = saved                                                           // M l. 30919
            if faces.indices.contains(Int(faceCount)) { faces[Int(faceCount)] = face }   // M l. 30920
            faceCount &+= 1
            return .added(faceClut: loadedUnder)
        }
    }

    /// What `.SetupLevel`'s strip step left (`create`).
    public struct Created: Equatable, Sendable {
        /// The strip globals after the step.
        public var table = Table()
        /// The add's outcome; nil when header `0x2716` = 0 (no add — levels 1–5 and every level but 10, 30, 40, 45, 62
        /// and 67).
        public var outcome: Table.Outcome?
        /// `*_DAT_1009ff94` after the step: the value passed in, except after a failed load under the `0x26cc` swap.
        public var clutAfter: Int16

        public init(clut: Int16) { clutAfter = clut }

        /// The strip sprites, creation order.
        public var ids: [Int] { table.ids }
        /// The CLUT the face converted under (nil when no face loaded).
        public var faceClut: Int16? {
            if case .added(let c)? = outcome { return c }
            return nil
        }
    }

    /// `.SetupLevel`'s strip step, on the long path (M l. 2350–2356) and the restart fast path (M l. 2252–2268) alike:
    /// `.MTKillPxSprites`, then — header `0x2716` ≠ 0 — `.MTAddPxSprite(hdr 0x2716, hdr 0x2718, hdr 0x271a)` with the
    /// Backgrounds file open. Called after `.KillAllSprites` (M l. 2246) and before `.SetupLevelSprites` (M l. 2526), so
    /// the strip sprites are the level's first allocations. `clut` is what `*_DAT_1009ff94` holds then
    /// (`setupLevelClut` on both paths). Header `0x271a` is read as the level has it (222 on level 10):
    /// `.BuildSineTable`'s clamp to 100 runs once, before any level loads (ENG §2.1).
    public static func create(header: LevelHeader, backgrounds: ResourceCollection, clut: Int16, world: SpriteWorld,
                              table: Table = Table()) -> Created {
        var made = Created(clut: clut)
        made.table = table
        made.table.kill(world: world)
        guard header.stripPict != 0 else { return made }
        var c = clut
        made.outcome = made.table.add(pict: header.stripPict, fx: header.stripFactor, y: header.stripBaseY,
                                      header: header, backgrounds: backgrounds, clut: &c, world: world)
        made.clutAfter = c
        return made
    }

    /// `.SetupPxSprite @ 10033418` (M l. 30798–30819): `.InitSprite` (the cleared record's defaults), the empty rect
    /// `+0x34`, `+0x48 = 0x1ff`, `+0xea = 1`, type 1, `+0x88 = 0`, `+0x5c = 0`, `+0x1f8 = 0`, the Handle
    /// `.HandlePxSprite`, `+0xb8 = 0x80000`. `.MTNewSprite` then re-stores `+0x48` = its record argument −1 (M l.
    /// 30718), so the live record holds −1 — no write-back either way.
    public static func setup(_ s: inout SpriteSlot) {
        s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
        s.recordIndex = 0x1ff
        s.killedForGood = true
        s.type = 1
        s.lightOverlay = false
        s.hasHit = false
        s.hasTileHit = false
        s.handler = .pxSprite
        s.mode = PxSprites.drawMode
    }

    /// `.HandlePxSprite @ 10033378` (M l. 30771–30797) at the scroll point (h, v) (`PTR_DAT_1009fe78`): `+0xc` and
    /// `+0xa` from `+0x14c` … `+0x158` (`Sprite.position`). No other store.
    public static func handle(world: SpriteWorld, id: Int, h: Int, v: Int) {
        guard let s = world.active.record(id: id) else { return }
        let p = Sprite(x0: Int(s.classTimer), y0: Int(s.classWord150), fx: Int(s.classWord154),
                       fy: Int(s.classWord158)).position(h: h, v: v)
        world.active.update(id: id) { c in
            c.x = p.x
            c.y = p.y
        }
    }

    /// `.MTHandlePxSprites @ 10033798` (M l. 30928–30948), called at the end of `.FindUpperLeftCorner` (M l. 6235) with
    /// the new scroll point: each of the 32 entries that is non-zero and whose record's `+0x4c` is non-zero gets its
    /// Handle called — `.HandlePxSprite`, the only Handle a strip record holds.
    public static func handleAll(world: SpriteWorld, table: Table, h: Int, v: Int) {
        for case let id? in table.sprites {
            guard let s = world.active.record(id: id), !s.handleCleared, s.handler == .pxSprite else { continue }
            handle(world: world, id: id, h: h, v: v)
        }
    }
}
