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
    /// Head first.
    public private(set) var sprites: [SpriteSlot] = []
    private var nextID = 1
    /// The `+0x68` an unlinked record keeps: `.MTRemoveSprite` / `.MTKillSprite` relink the neighbours but leave the
    /// record's own `next` (raw `10032ff8..1003305c`), so a walk that saved it continues from there.
    private var unlinkedNext: [Int: Int] = [:]

    public init() {}

    /// `.MTNewSprite`'s `.MTInsertSprite`: a new id, then the insert rule. Returns the sprite's id.
    @discardableResult
    public mutating func insert(_ sprite: SpriteSlot) -> Int {
        var s = sprite
        s.id = nextID
        nextID += 1
        place(s)
        return s.id
    }

    /// `.MTInsertSprite @ 10032f1c`.
    private mutating func place(_ s: SpriteSlot) {
        unlinkedNext[s.id] = nil
        if sprites.isEmpty || s.layer < sprites[0].layer {
            sprites.insert(s, at: 0)
            return
        }
        if let k = sprites.indices.dropFirst().first(where: { s.layer < sprites[$0].layer }) {
            sprites.insert(s, at: k)
        } else {
            sprites.append(s)
        }
    }

    /// `.MTRemoveSprite @ 10032ff8` (unlink; the record itself is the caller's).
    @discardableResult
    public mutating func remove(id: Int) -> SpriteSlot? {
        guard let k = sprites.firstIndex(where: { $0.id == id }) else { return nil }
        unlinkedNext[id] = k + 1 < sprites.count ? sprites[k + 1].id : nil
        return sprites.remove(at: k)
    }

    /// `.MTRemoveSprite` then `.MTInsertSprite` of a live sprite (`.MTChangeSpriteLayer`): it goes to the tail of its
    /// (new) layer group; id and record kept.
    public mutating func relink(id: Int) {
        guard let s = remove(id: id) else { return }
        place(s)
    }

    /// The record's `+0x68`: the sprite after `id` in the list, or — for an unlinked record — the `next` it kept.
    public func next(after id: Int) -> Int? {
        if let k = sprites.firstIndex(where: { $0.id == id }) {
            return k + 1 < sprites.count ? sprites[k + 1].id : nil
        }
        return unlinkedNext[id]
    }

    public func sprite(id: Int) -> SpriteSlot? { sprites.first { $0.id == id } }

    /// A store into a live sprite (no re-sort, as the original's direct field writes).
    public mutating func update(id: Int, _ body: (inout SpriteSlot) -> Void) {
        guard let k = sprites.firstIndex(where: { $0.id == id }) else { return }
        body(&sprites[k])
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
