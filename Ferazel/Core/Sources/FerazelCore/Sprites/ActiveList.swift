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

    public init() {}

    /// `.MTInsertSprite`; returns the sprite's id.
    @discardableResult
    public mutating func insert(_ sprite: SpriteSlot) -> Int {
        var s = sprite
        s.id = nextID
        nextID += 1
        if sprites.isEmpty || s.layer < sprites[0].layer {
            sprites.insert(s, at: 0)
            return s.id
        }
        if let k = sprites.indices.dropFirst().first(where: { s.layer < sprites[$0].layer }) {
            sprites.insert(s, at: k)
        } else {
            sprites.append(s)
        }
        return s.id
    }

    /// `.MTRemoveSprite @ 10032ff8` (unlink; the record itself is the caller's).
    @discardableResult
    public mutating func remove(id: Int) -> SpriteSlot? {
        guard let k = sprites.firstIndex(where: { $0.id == id }) else { return nil }
        return sprites.remove(at: k)
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

    /// Every sprite in list order, mutably (the draw pass writes `+0xb8`, the still counter and the last-frame copies).
    public mutating func forEach(_ body: (inout SpriteSlot) -> Void) {
        for k in sprites.indices { body(&sprites[k]) }
    }
}
