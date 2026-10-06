import XCTest
@testable import DeimosCore
@testable import DeimosRender

/// The shipped assets, loaded once per test process (plan Landmine e).
enum ShippedAssets {
    static let loaded: Result<DeimosAssets, Error> = Result {
        try DeimosAssets.load(index: TagIndex(dataDirectory: DeimosData.dataDirectory()))
    }
    static func get() throws -> DeimosAssets { try loaded.get() }
}

/// R3 — `DeimosRenderer`'s render lists (`FUN_1001a450` append, `FUN_1001a650` flush, `FUN_100189f0` clear;
/// blit-pixel-rules §7.1, listing `1001a450…1001a6ec`).
final class RendererTests: XCTestCase {

    private static let cost = FourCC("COST")!

    /// A `COST` rect command (no frame needed): at alpha 0 it paints `colour` exactly
    /// (`FUN_1001ec80`: `⌊(dst·0 + col·32)/32⌋`).
    private func rect(_ colour: UInt16, layer: UInt8, drawNow: Bool = false, flags: UInt32 = 0,
                      alpha: UInt32 = 0, at r: MacRect = MacRect(top: 10, left: 10, bottom: 20, right: 20)) -> DrawCommand {
        var c = DrawCommand.template
        c.face = Self.cost
        c.costRect = r
        c.costColour = colour
        c.layer = layer
        c.drawNow = drawNow
        c.flags = flags
        c.alpha = alpha
        return c
    }

    func testRenderListsOrderAndFlush() throws {
        let r = DeimosRenderer(assets: try ShippedAssets.get())
        let probe = (x: 15, y: 15)

        // Draw-now commands blit at once; queued ones wait for their layer's flush.
        r.apply(.draw(rect(0x0011, layer: 7, drawNow: true)))
        XCTAssertEqual(r.buffer(.back)[probe.x, probe.y], 0x0011)
        r.apply(.draw(rect(0x0022, layer: 7)))
        XCTAssertEqual(r.buffer(.back)[probe.x, probe.y], 0x0011, "queued: not drawn before the flush")
        XCTAssertEqual(r.renderLists.count(layer: 7), 1)

        // Face none and alpha 32 return before the append (`10019590…100195a8`).
        var none = rect(0x0033, layer: 7); none.face = .none
        r.apply(.draw(none))
        r.apply(.draw(rect(0x0033, layer: 7, alpha: 32)))
        XCTAssertEqual(r.renderLists.count(layer: 7), 1)

        // Insertion order within a layer: the later command lands on top.
        r.apply(.draw(rect(0x0044, layer: 7)))
        // Layer order across a band: layer 5 queued before layer 2, flushed 2 then 5.
        let band = MacRect(top: 30, left: 30, bottom: 40, right: 40)
        r.apply(.draw(rect(0x0055, layer: 5, at: band)))
        r.apply(.draw(rect(0x0066, layer: 2, at: band)))
        // A command outside the flushed band stays queued.
        r.apply(.flushLayers(2...5))
        XCTAssertEqual(r.buffer(.back)[35, 35], 0x0055, "layer 5 drawn after layer 2")
        XCTAssertEqual(r.buffer(.back)[probe.x, probe.y], 0x0011, "layer 7 is not in 2...5")
        r.apply(.flushLayers(6...15))
        XCTAssertEqual(r.buffer(.back)[probe.x, probe.y], 0x0044, "insertion order: the second layer-7 command last")

        // Layers 2…15 keep their commands after a flush (a second flush redraws them) …
        r.apply(.fill(.back, colour: 0))
        r.apply(.flushLayers(2...5))
        XCTAssertEqual(r.buffer(.back)[35, 35], 0x0055)

        // … layers 0–1 draw into the terrain buffer by flag 8, and become `none` after drawing (`1001a6b4…1001a6c8`).
        r.apply(.draw(rect(0x0077, layer: 0, flags: 8)))
        r.apply(.draw(rect(0x0088, layer: 1, flags: 8)))
        r.apply(.flushLayers(0...1))
        XCTAssertEqual(r.buffer(.terrain)[probe.x, probe.y], 0x0088)
        XCTAssertEqual(r.buffer(.back)[probe.x, probe.y], 0, "flag 8 → the terrain port, not the back buffer")
        XCTAssertEqual(r.renderLists.count(layer: 0), 1, "the count stays; the entry is turned none")
        XCTAssertEqual(r.renderLists.commands(layer: 0).first?.face, FourCC.none)
        XCTAssertEqual(r.renderLists.commands(layer: 1).first?.face, FourCC.none)
        XCTAssertEqual(r.renderLists.commands(layer: 2).first?.face, Self.cost)
        r.apply(.fill(.terrain, colour: 0x1234))
        r.apply(.flushLayers(0...1))
        XCTAssertEqual(r.buffer(.terrain)[probe.x, probe.y], 0x1234, "a consumed layer-0/1 entry draws nothing")

        // The appended copy is draw-now (`1001a628 stb 1,0x31`).
        XCTAssertEqual(r.renderLists.commands(layer: 7).map(\.drawNow), [true, true])

        // clearLayers zeroes all 16 counts: nothing is drawn by the next flush.
        r.apply(.clearLayers)
        for l in 0..<16 { XCTAssertEqual(r.renderLists.count(layer: l), 0) }
        r.apply(.fill(.back, colour: 0))
        r.apply(.flushLayers(0...1)); r.apply(.flushLayers(2...5)); r.apply(.flushLayers(6...15))
        XCTAssertTrue(r.buffer(.back).pixels.allSatisfy { $0 == 0 })

        // The lists grow past any fixed capacity (`1001a490…1001a568`, ×2 growth).
        for i in 0..<2500 { r.apply(.draw(rect(UInt16(i & 0x7fff), layer: 9))) }
        XCTAssertEqual(r.renderLists.count(layer: 9), 2500)
        r.apply(.flushLayers(6...15))
        XCTAssertEqual(r.buffer(.back)[probe.x, probe.y], UInt16(2499))
    }
}
