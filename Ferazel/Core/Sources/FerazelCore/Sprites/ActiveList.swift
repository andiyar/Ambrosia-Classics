import Foundation

/// The active sprite list: head `*(_DAT_1009ff58 + 0x5c)`, links `+0x68` next / `+0x6c` previous (physics §0;
/// platforms-ropes-radial-2 §8.2). The draw, handle and collision passes all walk it in this order.
///
/// `.MTInsertSprite @ 10032f1c` (decompile l. 30556; raw `10032f1c..10032fd0`), transcribed: an empty list takes the
/// sprite as head; a sprite whose layer `+0x80` is below the head's (signed `cmpw`) becomes the head; otherwise the
/// list is walked from the head and the sprite goes in front of the first `next` whose layer is strictly greater
/// (`bge` on equal, `10032f44` / `10032f80`), else at the tail — so inside one layer the order is insertion order, and
/// an unsorted list (direct `+0x80` stores do not re-sort) is walked, never re-sorted. `.MTNewSprite` runs the Setup
/// before inserting (`1003321c` → `1003322c`), so the layer is the one the Setup leaves.
public struct ActiveList: Equatable, Sendable {
    /// An unlinked record: `.MTRemoveSprite @ 10032ff8` / `.MTKillSprite @ 100332fc` relink the neighbours but leave
    /// the record's own fields — its Handle `+0x4c` and its `next` `+0x68` included (raw `10032ff8..1003305c`,
    /// decompile l. 30601–30628, 30739–30770; `.MTKillSprite` only clears the in-use byte `+0`, and stores type
    /// 0x8001 when the record was the head).
    struct Unlinked: Equatable, Sendable {
        var record: SpriteSlot
        var next: Int?
    }

    /// Head first.
    public private(set) var sprites: [SpriteSlot] = []
    private var nextID = 1
    /// id → index in `sprites`, kept on every insert / remove / relink so `sprite(id:)`, `next(after:)` and `update`
    /// are O(1). Bookkeeping only (derived from `sprites`): not part of `==`.
    private var indexOf: [Int: Int] = [:]
    /// The unlinked records the table still holds, with the `next` each kept, so a walk that saved one reads it and
    /// continues from there (`.MTHandleSprites` calls its kept Handle; `.StandardSpriteHandles`' carry reads a
    /// ridden record that is no longer linked). In the original a record lives until `.MTNewSprite` reuses its slot
    /// (`MemoryClear`, l. 30703) once `.MTKillSprite` has cleared its in-use byte; Core has no slot indices, so the
    /// store keeps the `recordLimit` most recently unlinked records and drops the oldest [MED].
    private var unlinked: [Int: Unlinked] = [:]
    /// Unlink order (oldest first) for the bound.
    private var unlinkedOrder: [Int] = []
    /// The bound on `unlinked`: the record table's 700 entries (`.MTNewSprite`).
    static let recordLimit = 700

    public init() {}

    public static func == (a: ActiveList, b: ActiveList) -> Bool {
        a.sprites == b.sprites && a.nextID == b.nextID && a.unlinked == b.unlinked
    }

    /// `.MTNewSprite`'s `.MTInsertSprite`: a new id, then the insert rule. Returns the sprite's id.
    @discardableResult
    public mutating func insert(_ sprite: SpriteSlot) -> Int {
        var s = sprite
        s.id = nextID
        nextID += 1
        place(s)
        return s.id
    }

    /// Re-index `sprites[k...]` after an insert or a removal at `k` (list order itself is untouched).
    private mutating func reindex(from k: Int) {
        for i in k..<sprites.count { indexOf[sprites[i].id] = i }
    }

    /// `.MTInsertSprite @ 10032f1c`.
    private mutating func place(_ s: SpriteSlot) {
        if unlinked.removeValue(forKey: s.id) != nil, let o = unlinkedOrder.firstIndex(of: s.id) {
            unlinkedOrder.remove(at: o)
        }
        let k: Int
        if sprites.isEmpty || s.layer < sprites[0].layer {
            k = 0
        } else {
            k = sprites.indices.dropFirst().first(where: { s.layer < sprites[$0].layer }) ?? sprites.count
        }
        sprites.insert(s, at: k)
        reindex(from: k)
    }

    /// Unlink the sprite at `k` (no record kept): the shared half of `remove` and `relink`.
    private mutating func unlink(at k: Int) -> SpriteSlot {
        let s = sprites.remove(at: k)
        indexOf[s.id] = nil
        reindex(from: k)
        return s
    }

    /// `.MTRemoveSprite @ 10032ff8` (unlink). The record and the `next` it kept stay readable through
    /// `record(id:)` / `next(after:)` (see `unlinked`).
    @discardableResult
    public mutating func remove(id: Int) -> SpriteSlot? {
        guard let k = indexOf[id] else { return nil }
        let next = k + 1 < sprites.count ? sprites[k + 1].id : nil
        let s = unlink(at: k)
        unlinked[id] = Unlinked(record: s, next: next)
        unlinkedOrder.append(id)
        if unlinkedOrder.count > Self.recordLimit {
            unlinked[unlinkedOrder.removeFirst()] = nil
        }
        return s
    }

    /// `.MTRemoveSprite` then `.MTInsertSprite` of a live sprite (`.MTChangeSpriteLayer`): it goes to the tail of its
    /// (new) layer group; id and record kept.
    public mutating func relink(id: Int) {
        guard let k = indexOf[id] else { return }
        place(unlink(at: k))
    }

    /// The record's `+0x68`: the sprite after `id` in the list, or — for an unlinked record — the `next` it kept.
    public func next(after id: Int) -> Int? {
        if let k = indexOf[id] {
            return k + 1 < sprites.count ? sprites[k + 1].id : nil
        }
        return unlinked[id]?.next
    }

    /// The linked sprite `id` (nil when it is not on the list).
    public func sprite(id: Int) -> SpriteSlot? { indexOf[id].map { sprites[$0] } }

    /// The record `id`, linked or not (a pointer in the original reads the record whether or not it is on the list).
    public func record(id: Int) -> SpriteSlot? { sprite(id: id) ?? unlinked[id]?.record }

    /// The list index of the linked sprite `id` (O(1)); for passes that read fields in place.
    func index(of id: Int) -> Int? { indexOf[id] }

    /// A store into the record `id` — linked or unlinked, as the original's direct field writes (no re-sort).
    /// ⚠️ Exclusivity: `body` runs with exclusive access to this list (and so to the `SpriteWorld` property holding
    /// it); it must not call back into the world or the list (`sprite(id:)`, `update`, a pass …) — read what it
    /// needs before the call.
    public mutating func update(id: Int, _ body: (inout SpriteSlot) -> Void) {
        if let k = indexOf[id] {
            body(&sprites[k])
        } else if unlinked[id] != nil {
            body(&unlinked[id]!.record)
        }
    }

    // MARK: - `.MTCollideSprites` in-place reads (no whole-record copies in the O(n²) pair loop)

    /// `+0x44 = 0` for every sprite (the pass start).
    mutating func clearHotRectBuilt() {
        for k in sprites.indices { sprites[k].hotRectBuilt = false }
    }

    /// The pair gates of `.MTCollideSprites` for A = `sprites[a]`, B = `sprites[b]`: B `+0xe9`, Δx / Δy of `+0xc` /
    /// `+0xa`, either `+0x5c`, the `+0x184` same-handler exclusion, and both `+0x44`.
    func collidePair(_ a: Int, _ b: Int) -> (bDead: Bool, dx: Int, dy: Int, eitherHit: Bool, exempt: Bool,
                                             aBuilt: Bool, bBuilt: Bool) {
        (sprites[b].dead, sprites[a].x - sprites[b].x, sprites[a].y - sprites[b].y,
         sprites[a].hasHit || sprites[b].hasHit,
         sprites[a].sameHandlerExempt && sprites[a].handler == sprites[b].handler,
         sprites[a].hotRectBuilt, sprites[b].hotRectBuilt)
    }

    /// `.TheSectRect` of the two `+0x3c` rects.
    func hotRectsIntersect(_ a: Int, _ b: Int) -> Bool {
        sprites[a].hotRectWorld.intersects(sprites[b].hotRectWorld)
    }

    /// The Core half of `.WrapDrawSprites @ 100144c8`, in list order: each `+0x89` sprite's mode from
    /// `light(sprite)` = (`.GetLightTile`, `.GetFakeLight`) (written back to `+0xb8`), the draw of every live sprite
    /// with a face, then every sprite's last-frame copies (`SpriteSlot.recordDrawn`). The pixels are
    /// `FerazelRender.SpriteBlitter`'s.
    public mutating func wrapDrawSprites(light: (SpriteSlot) -> (lightTile: Int, fakeLight: Int) = { _ in (0, 0) })
        -> [SpriteDraw] {
        var out: [SpriteDraw] = []
        for k in sprites.indices {
            if sprites[k].dynamicLight, sprites[k].face != nil, !sprites[k].dead {
                let l = light(sprites[k])
                _ = sprites[k].applyDynamicLight(lightTile: l.lightTile, fakeLight: l.fakeLight)
            }
            if let d = sprites[k].draw { out.append(d) }
            sprites[k].recordDrawn()
        }
        return out
    }
}
