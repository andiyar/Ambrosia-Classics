import Foundation

/// One particle `.DrawParticles @ 10031aa4` hands `.WrapDrawParticle @ 10015948` (plan S3, E1a; LOCKED once added —
/// fields may be added, never renamed or retyped): an alive record with age > 0 whose colour is not 0 (Core makes the
/// colour-0 kill itself, `ParticleLife`; particles §3.1). FerazelRender resolves the colour (`row[|kind|][age]`, or
/// `|kind| − 256`, through the ambient table when `kind < 0` and prefs+6 ≠ 3) and draws the shape.
public struct ParticleDraw: Equatable, Sendable {
    /// The pool index 0…1999 (drawn in index order).
    public var slot: Int
    /// `+0x06` as stored (signed: negative = ambient-lit).
    public var kind: Int16
    /// `+0x02` (1…119 here).
    public var age: Int16
    /// `+0x04`, the `.WrapDrawParticle` footprint code (particles §3.2).
    public var shape: Int16
    /// `(short)(+0x18 >> 8)` / `(short)(+0x14 >> 8)` (`srawi 8; extsh`, raw `10031b20..10031b38`): level pixels.
    public var v: Int16
    public var h: Int16

    public init(slot: Int, kind: Int16, age: Int16, shape: Int16, v: Int16, h: Int16) {
        self.slot = slot
        self.kind = kind
        self.age = age
        self.shape = shape
        self.v = v
        self.h = h
    }
}
