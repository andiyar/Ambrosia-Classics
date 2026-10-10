import XCTest
import HectorResources
@testable import FerazelCore

/// F2 re-review (Opus leg, 2026-10-10): a pointer-level model of .MTInsertSprite / .MTRemoveSprite / .MTHandleSprites (raw 10032f1c..,
/// 10032ff8.., 1003259c) against SpriteWorld.handleSprites with the O(1) index map.
final class SpriteListOrderFuzzTests: XCTestCase {
    final class Ref {
        struct R { var layer: Int32; var next: Int?; var prev: Int? }
        var recs: [Int: R] = [:]
        var head: Int?
        func insert(_ id: Int) {
            guard let h = head else { head = id; return }          // empty: next left as-is
            if recs[id]!.layer < recs[h]!.layer {
                head = id; recs[id]!.next = h; recs[id]!.prev = nil; recs[h]!.prev = id; return
            }
            var r6: Int? = h; var r7 = h; var done = false
            while let c = r6, !done {
                if let r5 = recs[c]!.next, recs[id]!.layer < recs[r5]!.layer {
                    recs[id]!.next = r5; done = true; recs[id]!.prev = c
                    recs[r5]!.prev = id; recs[c]!.next = id
                }
                r7 = c; r6 = recs[c]!.next
            }
            if done { return }
            recs[r7]!.next = id; recs[id]!.prev = r7; recs[id]!.next = nil
        }
        func remove(_ id: Int) {
            let p = recs[id]!.prev, n = recs[id]!.next
            if head == id { head = n; return }
            if let p { recs[p]!.next = n }
            if let n { recs[n]!.prev = p }
        }
        func linked() -> [Int] { var out: [Int] = []; var c = head; while let x = c { out.append(x); c = recs[x]!.next; if out.count > 5000 { break } }; return out }
    }

    struct LCG { var s: UInt64; mutating func next(_ n: Int) -> Int { s = s &* 6364136223846793005 &+ 1442695040888963407; return Int((s >> 33) % UInt64(n)) } }

    func testFuzzHandleOrderMatchesPointerModel() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let level = try LevelFile.load(from: r, level: 1)
        var mismatches = 0
        var total = 0
        for seed in 0..<400 {
            let w = SpriteWorld(level: level)
            let ref = Ref()
            var rng = LCG(s: UInt64(seed) &* 7919 &+ 1)
            func add(_ layer: Int16) {
                let id = w.newSprite(type: 1400, x: 0, y: 0, layer: layer, handler: .platform)!
                ref.recs[id] = .init(layer: Int32(layer), next: nil, prev: nil)
                ref.insert(id)
            }
            for _ in 0..<(3 + rng.next(10)) { add(Int16(rng.next(5))) }
            XCTAssertEqual(w.active.sprites.map(\.id), ref.linked())
            for _ in 0..<4 {
                var core: [Int] = []
                var ops: [[(Int, Int, Int)]] = []
                var budget = 0
                w.handleSprites { world, id in
                    core.append(id); ops.append([]); budget += 1
                    guard budget < 60 else { return }
                    let lin = world.active.sprites.map(\.id)
                    switch rng.next(6) {
                    case 0:
                        let t = lin[rng.next(lin.count)]; let L = rng.next(6) - 1
                        ops[ops.count - 1].append((0, t, L)); world.changeLayer(id: t, layer: Int16(L))
                    case 1:
                        if lin.count > 1 {
                            let k2 = world.active.next(after: id)
                            let t = (rng.next(2) == 0 ? k2 : nil) ?? lin[rng.next(lin.count)]
                            if world.active.sprite(id: t) != nil {
                                ops[ops.count - 1].append((1, t, 0)); world.active.remove(id: t)
                            }
                        }
                    case 2:
                        let L = rng.next(6) - 1
                        let nid = world.newSprite(type: 1400, x: 0, y: 0, layer: Int16(L), handler: .platform)!
                        ops[ops.count - 1].append((2, nid, L))
                    default: break
                    }
                }
                var refSeen: [Int] = []
                var cur = ref.head
                while let c = cur {
                    let nxt = ref.recs[c]!.next
                    let i = refSeen.count
                    refSeen.append(c)
                    if i >= core.count { break }
                    for (k, t, L) in ops[i] {
                        switch k {
                        case 0:
                            if ref.recs[t]!.layer != Int32(L) { ref.recs[t]!.layer = Int32(L); ref.remove(t); ref.insert(t) }
                        case 1: ref.remove(t)
                        default:
                            ref.recs[t] = .init(layer: Int32(L), next: nil, prev: nil); ref.insert(t)
                        }
                    }
                    cur = nxt
                }
                if refSeen != core || w.active.sprites.map(\.id) != ref.linked() {
                    mismatches += 1
                    if mismatches < 4 { print("MISMATCH seed \(seed): core \(core) ref \(refSeen) list \(w.active.sprites.map(\.id)) ref \(ref.linked())") }
                }
                total += core.count
            }
        }
        XCTAssertEqual(mismatches, 0)
    }
}
