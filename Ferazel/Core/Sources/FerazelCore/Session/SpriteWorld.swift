import Foundation

/// The sprite physics world (plan S2, F2): what `.HandleSprites @ 10007c24` and the sprite routines read and write —
/// the active list, the idle table, the session's one `FastRand` stream (plan Invariant 4), the game globals and the
/// level. `PlayerState` joins in P1a.
///
/// Frame order (plan Invariant 3; platforms-ropes-radial-2 §8.1): the draw, `.HandleIdleSprites`, then
/// `.HandleSprites` = `handleSprites` (`.MTHandleSprites`) → `collideSprites` (`.MTCollideSprites`) → if the player
/// is alive (`*_DAT_1009ffa8 == 0`) and exists (`*_DAT_1009fdd8 ≠ 0`): `collideSpecial`
/// (`.MTCollideSpecialSprite(player, .HitPlayerSprite)`) (decompile l. 4040–4045). Every Handle of frame n runs
/// before every hit callback of frame n.
///
/// The Handles and hit callbacks are passed in by the caller (the session) and dispatch on `SpriteSlot.handler`;
/// this type owns only the list walks.
///
/// ⚠️ Exclusivity (F3 review) — two ways to lose or trap a write, both silent in the type system:
/// 1. **Never call the tile solver (or any routine that writes `active`) inside `active.update(id:) { … }`.** The
///    closure holds exclusive access to `active`; a nested `world.active` access traps at run time ("Simultaneous
///    accesses … modification requires exclusive access"), in release builds too. Read what you need, close the
///    closure, then call.
/// 2. **Never hold a `SpriteSlot` copy across a solver call and write it back** (`var s = active.sprite(id:)!; …
///    solver.separateFromTiles(id, …); active.update(id:) { $0 = s }`): the write-back silently undoes everything the
///    solver and its tile callbacks did. Re-read after the call (the solver itself does this around its recursions and
///    callbacks). Debug builds can check a held copy with `solverWrites`: take it before, `assert` it unchanged before
///    the write-back.
public final class SpriteWorld {
    public let level: LevelFile
    /// The one mutable tile map (FG/BG cells + the kind tables) every Core tile reader uses during play — the tile
    /// solver, P2's `.CrunchTile` (which writes it and emits `DrawOp.setTile`), and every later reader (F3 review: one
    /// source of truth). Built from `level` at init; `level.fg`/`level.bg` stay the loaded file (the Phase-1 Setups read
    /// them at spawn time, before any crunch, and FerazelRender draws from them plus `setTile`).
    public var tiles: TileGrid
    /// Debug aid for hazard 2 above: bumped by every sprite write of the tile solver (`.SeparateFromTiles2`,
    /// `.WallBounce`, `.WallBounceBG`). No behaviour reads it.
    public internal(set) var solverWrites: UInt = 0
    /// The active list (`*(_DAT_1009ff58 + 0x5c)`).
    public var active: ActiveList
    /// The idle table (`0x100ac02c`).
    public var idle: IdleSprites
    /// `_DAT_100a17e8`: the one `FastRand` stream (moved here from the session, F2).
    public var rng: FastRand
    /// `G` (`_DAT_1009ffc0`).
    public var globals: GameGlobals
    /// `*_DAT_1009fdd8`: the player sprite (nil = 0).
    public var playerID: Int?
    /// `*_DAT_1009ffa8`: the player is dying / dead — `.HandleSprites` then skips the player pass.
    /// // later: P4 (the death trigger sets it)
    public var playerDead = false

    /// `*(_DAT_1009ff58 + 0x1c)` = 360 (`li r0,0x168` at `10032274`): `.MTCollideSprites`' |Δx|, |Δy| window.
    public static let collideRange = 360
    /// `.MTNewSprite`'s record table: 700 entries of 0x1fc bytes at `_DAT_100a01dc`.
    public static let recordCount = 700

    public init(level: LevelFile, seed: Int32 = 1, active: ActiveList = ActiveList(), idle: IdleSprites = IdleSprites()) {
        self.level = level
        tiles = TileGrid(level: level)
        rng = FastRand(seed: seed)
        globals = GameGlobals(header: level.header)
        self.active = active
        self.idle = idle
    }

    // MARK: - list primitives

    /// `.MTNewSprite @ 10033060 (type, x, y, layer, record, setup)`: a cleared record (`SpriteSlot` defaults =
    /// `MemoryClear` + `.InitSprite`, as every class Setup starts with), `+0x14 = x << 8`, `+0x1c = y << 8`, the layer
    /// stored, then the Setup runs (`1003321c`) **before** `.MTInsertSprite` (`1003322c`), so the list position uses
    /// the layer the Setup leaves. Nil when all 700 records are live (the original's `ReportError`). The record index
    /// and its search hint `_DAT_100a01c4` have no reader and are not kept [MED: the Setups' idle-sprite records are
    /// made and freed outside this type].
    ///
    /// The pixel copies, as written (raw `100331e4 sth r27,0xc(r25)`, `100331f0 sth r27,0x8(r25)`, `100331f4 sth
    /// r28,0xc(r25)`, `100331f8 sth r28,0x6(r25)`; decompile l. 30706–30709): x goes to `+0xc` and `+8`, then y to
    /// the **same** `+0xc` and to `+6` — so `+0xc` = y, `+0xa` keeps the `MemoryClear` 0, `+8`/`+6` = (x, y). The
    /// 24.8 position is right; the pixel copy is fixed by the first writer (a Setup's own store, `.SeparateFromTiles2`
    /// entry, …; see `SpriteSlot.x`). The level spawn does not see it: `.AddIdleSprite` re-stores x, y into the idle
    /// entry (l. 4137–4138) and `.IdleToActiveSprite` rewrites `+0xc`/`+0xa` from it.
    ///
    /// The 700 cap counts the sprites on the list; the original counts in-use records (`+0` ≠ 0), which also
    /// include records unlinked by `.MTRemoveSprite` and not yet killed, and idled records until `.UpdateSprites`
    /// kills them [LOW: Phase 2 never comes near 700].
    @discardableResult
    public func newSprite(type: Int16, x: Int, y: Int, layer: Int16, handler: SpriteHandler, record: Int16 = -1,
                          setup: (inout SpriteSlot) -> Void = { _ in }) -> Int? {
        guard active.sprites.count < Self.recordCount else { return nil }
        var s = SpriteSlot(type: type, x: x, y: y, recordIndex: record, layer: Int32(layer))
        s.oldPosition = SpriteSlot.Point(x: x, y: y)              // `+8` = x, `+6` = y
        s.x = y                                                   // `+0xc` = x, then `+0xc` = y (the quirk above)
        s.y = 0                                                   // `+0xa` never written: `MemoryClear` 0
        s.handler = handler
        setup(&s)
        s.recordIndex = record                                    // `.MTNewSprite` re-stores `+0x48` after the Setup
        return active.insert(s)
    }

    /// `.MTChangeSpriteLayer @ 10033288` (raw `100332a0..100332bc`): `lwz 0x80; cmpw; beq` — **no-op when the layer
    /// is unchanged**; otherwise `+0x80 = layer`, `.MTRemoveSprite`, `.MTInsertSprite` (the sprite goes to the tail of
    /// its new layer group). A sprite moved during the handle pass to a layer after the walk's position is reached
    /// again and handled twice that frame (platforms-ropes-radial-2 §8.2).
    public func changeLayer(id: Int, layer: Int16) {
        guard let s = active.sprite(id: id), s.layer != Int32(layer) else { return }
        active.update(id: id) { $0.layer = Int32(layer) }
        active.relink(id: id)
    }

    // MARK: - the passes

    /// `.MTHandleSprites @ 1003259c` (raw `100325b8..100325d4`): from the head, `next` (`+0x68`) is loaded **before**
    /// the Handle `+0x4c` is called, then the walk continues from that saved sprite's own `next`. A sprite created
    /// during the pass is handled this frame only if inserted after the saved `next`; one moved to a later place is
    /// handled again. Every class Setup installs a Handle, so the `+0x4c == 0` skip is never taken.
    ///
    /// A saved `next` unlinked by the Handle is **still handled**: the walk reads `+0x4c` from the record, and
    /// `.MTRemoveSprite`/`.MTKillSprite` (l. 30601–30628, 30739–30770) leave it — kill only clears the in-use byte
    /// `+0` (and stores type 0x8001 on a head record); the record lives on until `.MTNewSprite` reuses the slot.
    /// The walk then follows the `next` the record kept. So `handle` gets the id of a record that may be off the list
    /// (`ActiveList.record(id:)`). In the original the case is latent: `.MTKillSprite`'s callers are
    /// `.AddIdleSprite` (10007e78, its own new record), `.IdleToActiveSprite` (10008168), `.UpdateSprites`
    /// (10009a58) and the px-sprite routines (100334ec, 1003384c) — none reachable from a Handle — and
    /// `.MTRemoveSprite`'s one caller, `.MTChangeSpriteLayer`, re-inserts at once. Moving the saved `next` to the head
    /// (a layer change below everything) makes the walk re-handle the current sprite: [1, 2, 3] with 1 moving 2 to the
    /// front handles [1, 2, 1, 3] (platforms-ropes-radial-2 §8.2).
    public func handleSprites(_ handle: (SpriteWorld, Int) -> Void) {
        var cursor = active.sprites.first?.id
        while let id = cursor {
            let next = active.next(after: id)                     // `lwz r31,0x68(r3)` before `bl 0x1009f80c`
            if active.record(id: id) != nil { handle(self, id) }   // `+0x4c` read from the record, linked or not
            cursor = next
        }
    }

    /// `.CalcHotRect @ 10032614`: `+0x3c = +0x34` offset by (x, y); `+0x44 = 1`.
    func calcHotRect(_ id: Int) {
        active.update(id: id) { s in
            let r = s.hotRect
            s.hotRectWorld = IdleSprites.Rect(top: Int(Int16(truncatingIfNeeded: r.top + s.y)),
                                              left: Int(Int16(truncatingIfNeeded: r.left + s.x)),
                                              bottom: Int(Int16(truncatingIfNeeded: r.bottom + s.y)),
                                              right: Int(Int16(truncatingIfNeeded: r.right + s.x)))
            s.hotRectBuilt = true
        }
    }

    /// `.MTCollideSprites @ 100326cc` (decompile l. 30216–30372; platforms-ropes-radial-2 §8.3). `+0x44` cleared for
    /// every sprite; then for each A in list order with a hit callback (`+0x5c`), `+0x1b2 == 0`, `+0xe9 == 0`, every B
    /// from the head with B ≠ A, `+0xe9 == 0`, |ΔA+0xc| < 360 and |ΔA+0xa| < 360, the `+0x184` same-handler exclusion,
    /// and the `.CalcHotRect` rects (built once per pass) intersecting (`.TheSectRect`). Contacts 1…6 are collected, a
    /// 7th and later dispatched at once (`A.hit(A, B)` then `B.hit(B, A)` if B has one). One contact: A.hit, B.hit.
    /// Two to six: key `−(|ey − A+0xe| + |ex − A+0x10|)` (ex = B `+0x42` if B `+0x10` < A `+0x10` else B `+0x3e`;
    /// ey = B `+0x3c` if B `+0xe` < A `+0xe` else B `+0x40`), the single-pass minimum first, then the others in list
    /// order. `hit(world, a, b)` is `a`'s callback, called only when `a` has one (`+0x5c` re-read at each call).
    public func collideSprites(_ hit: (SpriteWorld, Int, Int) -> Void) {
        active.clearHotRectBuilt()
        func call(_ a: Int, _ b: Int) {
            if active.sprite(id: a)?.hasHit == true { hit(self, a, b) }
        }
        let R = Self.collideRange
        var outer = active.sprites.first?.id
        while let aID = outer {
            var contacts: [Int] = []
            if let A = active.sprite(id: aID), A.hasHit, !A.handleSkip, !A.dead {
                var inner = active.sprites.first?.id
                while let bID = inner {
                    defer { inner = active.next(after: bID) }
                    // Fields read in place by list index (O(1), no whole-record copies), re-read every pair: a
                    // hit dispatched at once (7th contact on) may change A or B.
                    guard bID != aID, let ai = active.index(of: aID), let bi = active.index(of: bID) else { continue }
                    let pair = active.collidePair(ai, bi)
                    guard !pair.bDead, abs(pair.dx) < R, abs(pair.dy) < R, pair.eitherHit,
                          !pair.exempt else { continue }
                    if !pair.aBuilt { calcHotRect(aID) }
                    if !pair.bBuilt { calcHotRect(bID) }
                    guard active.hotRectsIntersect(ai, bi) else { continue }
                    if contacts.count < 6 {
                        contacts.append(bID)
                    } else {
                        hit(self, aID, bID)                            // A's `+0x5c` was tested at the top
                        call(bID, aID)
                    }
                }
            }
            if contacts.count == 1 {
                call(aID, contacts[0])
                call(contacts[0], aID)
            } else if contacts.count > 1, let A = active.sprite(id: aID) {
                var keys = contacts.map { Self.dispatchKey(of: $0, from: A, world: self) }
                var minIndex = -1
                var minKey: Int16 = 32000
                for k in keys.indices where keys[k] < minKey {   // `10032990..100329bc`
                    minKey = keys[k]
                    keys[k] = 32000
                    minIndex = k
                }
                if minIndex != -1 {
                    call(aID, contacts[minIndex])
                    call(contacts[minIndex], aID)
                }
                for k in contacts.indices where k != minIndex {
                    call(aID, contacts[k])
                    call(contacts[k], aID)
                }
            }
            outer = active.next(after: aID)
        }
    }

    /// The dispatch key of contact `bID` seen from `A` (`100328e8..10032958`): `−(|ex − A+0x10| + |ey − A+0xe|)` as
    /// i16, ex = B `+0x42` (right) if B `+0x10` < A `+0x10` else B `+0x3e` (left), ey = B `+0x3c` (top) if
    /// B `+0xe` < A `+0xe` else B `+0x40` (bottom) — B's near x edge and far y edge, as written.
    static func dispatchKey(of bID: Int, from A: SpriteSlot, world: SpriteWorld) -> Int16 {
        guard let B = world.active.sprite(id: bID) else { return 0 }
        let ex = B.centre.x < A.centre.x ? B.hotRectWorld.right : B.hotRectWorld.left
        let ey = B.centre.y < A.centre.y ? B.hotRectWorld.top : B.hotRectWorld.bottom
        let dx = Int16(truncatingIfNeeded: abs(ex - A.centre.x)), dy = Int16(truncatingIfNeeded: abs(ey - A.centre.y))
        return 0 &- (dx &+ dy)
    }

    /// Whether `s` runs `.HandleSeeSawSegSprite` (`_DAT_100a01c8` → `100655c8`, compared at `10032db8`): the see-saw
    /// segments 0x59b that `.MakeRadiusSprites` makes with `.SetupSeeSawSegSprite` (platforms-ropes-radial-2 §8.4)
    /// [MED: identified by type; W1 builds them].
    static func isSeeSawSegment(_ s: SpriteSlot) -> Bool { s.type == 0x59b }

    /// `.MTCollideSpecialSprite(player, .HitPlayerSprite) @ 10032ac8` (decompile l. 30374–30520; raw
    /// `10032ac8..10032eec`; platforms-ropes-radial-2 §8.3), run by `.HandleSprites` only when `playerDead` is false
    /// and the player exists. Contacts: every sprite in list order with a Handle, `+0xe9 == 0`, ≠ player, whose raw
    /// `+0x34` rect plus position meets the player's (`.SectRectFast`); up to 16 collected, later ones get
    /// `hitPlayer` at once (no own hit). One contact: `hitPlayer(player, C)`, then `C.hit(C, player)` if C has one.
    /// Two or more: if any is a see-saw segment, `hitPlayer` for each in list order and no contact hits; otherwise
    /// each in list order (the "sort" takes the first unvisited key < 32000 and breaks — every key is ≤ 0) gets
    /// `hitPlayer` then `C.hit`. `hitPlayer` = `.HitPlayerSprite` // later: P2 (and the movers' arms, W1–W3).
    public func collideSpecial(hitPlayer: (SpriteWorld, Int, Int) -> Void, hit: (SpriteWorld, Int, Int) -> Void) {
        guard !playerDead, let pID = playerID, active.sprite(id: pID) != nil else { return }
        func rect(_ s: SpriteSlot) -> IdleSprites.Rect {
            IdleSprites.Rect(top: Int(Int16(truncatingIfNeeded: s.hotRect.top + s.y)),
                             left: Int(Int16(truncatingIfNeeded: s.hotRect.left + s.x)),
                             bottom: Int(Int16(truncatingIfNeeded: s.hotRect.bottom + s.y)),
                             right: Int(Int16(truncatingIfNeeded: s.hotRect.right + s.x)))
        }
        var contacts: [Int] = []
        var cursor = active.sprites.first?.id
        while let cID = cursor {
            defer { cursor = active.next(after: cID) }
            guard cID != pID, let C = active.sprite(id: cID), !C.dead, let P = active.sprite(id: pID),
                  rect(P).intersects(rect(C)) else { continue }
            if contacts.count < 16 { contacts.append(cID) } else { hitPlayer(self, pID, cID) }
        }
        func contactHit(_ c: Int) {
            if active.sprite(id: c)?.hasHit == true { hit(self, c, pID) }
        }
        if contacts.count == 1 {
            hitPlayer(self, pID, contacts[0])
            contactHit(contacts[0])
        } else if contacts.count > 1, let P = active.sprite(id: pID) {
            var keys = contacts.map { Self.dispatchKey(of: $0, from: P, world: self) }
            let seeSaw = contacts.contains { active.sprite(id: $0).map(Self.isSeeSawSegment) ?? false }
            if seeSaw {
                for c in contacts { hitPlayer(self, pID, c) }        // `10032e9c..10032ed8`
            } else {
                // `10032e04..10032e30`: each round takes the first key < 32000, marks it 32000 and breaks.
                while let k = keys.firstIndex(where: { $0 < 32000 }) {
                    keys[k] = 32000
                    hitPlayer(self, pID, contacts[k])
                    contactHit(contacts[k])
                }
            }
        }
    }
}
