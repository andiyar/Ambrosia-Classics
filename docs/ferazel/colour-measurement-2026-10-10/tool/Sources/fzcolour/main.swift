import Foundation
import FerazelCore
import FerazelRender

// Throwaway measurement tool (colour study). Renders level-1 frames at arbitrary scrolls through the public
// FrameRenderer API by issuing the same DrawOps the session would (no core change).
// usage: fzcolour render <model> <tie> <dither> <effects> <sprites 0|1> <outdir> h,v [h,v ...] [--drop i,j,..] [--only i,j]
//                       [--twinkle k]   (k 0…3: every item light shows BonusHandle.twinkleFaces[k], as after its Handle)
//        fzcolour lights <effects>
//        fzcolour info
struct NoText: TextRasterizer {
    func rasterize(_ text: String, font: Int16, size: Int16, face: Int16) -> (left: Int, top: Int, width: Int, height: Int, bits: [Bool]) {
        (0, 0, 0, 0, [])
    }
}
let args = CommandLine.arguments
let res = try FerazelData.open(try FerazelData.dataDirectory())
func model(_ s: String) -> ColorSearch.Model {
    switch s { case "exact": .exactNearest; case "ruled": .ruled; case "inv4": .inverseTable(bits: 4); case "inv5": .inverseTable(bits: 5)
    default: fatalError("model \(s)") }
}
switch args[1] {
case "info":
    let L = try LevelFile.load(from: res, level: 1)
    print("grid", L.header.gridWidth, L.header.gridHeight, "start", L.header.startX, L.header.startY)
case "lights":
    var prefs = FerazelPrefs(); prefs.effects = Int16(args[2])!
    let L = try LevelFile.load(from: res, level: 1)
    let ctx = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header), effects: prefs.effects)
    let sp = try SetupFaces.spawnLevelSprites(context: ctx) { _ in .noFace }
    for (i, l) in sp.lights.enumerated() { print(i, l.pict, l.width, l.x, l.y, l.colour) }
    // sprite types & positions
    for p in L.spawnOrder { let e = try SetupFaces.setup(p, context: ctx); print("S", p.index, p.type, e.slot.x, e.slot.y, e.light != nil ? "L" : "") }
case "render":
    var prefs = FerazelPrefs(); prefs.effects = Int16(args[5])!
    let tie: ColorSearch.TieBreak = args[3] == "highest" ? .highest : .lowest
    let dither: DitherModel = args[4] == "fs" ? .errorDiffusion : .none
    let sprites = args[6] == "1"
    let outdir = args[7]
    var scrolls: [(Int, Int)] = []; var drop = Set<Int>(); var only: Set<Int>? = nil; var twinkle: Int? = nil
    var i = 8
    while i < args.count {
        if args[i] == "--drop" { drop = Set(args[i+1].split(separator: ",").map { Int($0)! }); i += 2; continue }
        if args[i] == "--twinkle" { twinkle = Int(args[i+1])!; i += 2; continue }
        if args[i] == "--only" { only = Set(args[i+1].split(separator: ",").compactMap { Int($0) }); i += 2; continue }
        let p = args[i].split(separator: ",").map { Int($0)! }; scrolls.append((p[0], p[1])); i += 1
    }
    let search = ColorSearch(model: model(args[2]), tieBreak: tie)
    let r = try FrameRenderer(resources: res, level: 1, search: search, dither: dither, text: NoText(), prefs: prefs)
    let L = r.level
    let ctx = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header), effects: prefs.effects)
    var sp = try SetupFaces.spawnLevelSprites(context: ctx) { e in
        switch e.source {
        case .none, .handle: return .noFace
        case .setupCached: return r.faceBounds(FaceRef(pict: SetupFaces.placeholderPict, index: 0, set: .encoded))
        case .setup: return e.slot.face.map(r.faceBounds) ?? .noFace
        }
    }
    let kept = sp.lights.indices.filter { !drop.contains($0) && (only?.contains($0) ?? true) }
    try r.addLights(kept.map { sp.lights[$0] })
    if let k = twinkle {
        // the item lights (`+0x9a` = their index in sp.lights) at their slot after the --drop/--only filter
        let items = (sp.active.sprites + sp.idle.entries.compactMap { $0?.saved }).filter { BonusHandle.twinkles(type: $0.type) && $0.light >= 0 }
        let f = BonusHandle.twinkleFaces[k]
        let ops = items.compactMap { s in kept.firstIndex(of: Int(s.light)) }.map {
            DrawOp.changeLightFace(slot: $0, pict: f.pict, width: f.width, height: f.height) }
        try r.apply(FrameOps(draws: ops))
    }
    try r.apply(FrameOps(draws: [.setScreenClut(id: ColorLUT.screenClutId(L.header)), .drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0)]))
    for (h, v) in scrolls {
        var draws: [SpriteDraw] = []
        for _ in 0..<2 {
            var ops: [DrawOp] = [.redrawEntireScrollGrid(h: h, v: v), .redrawScrollGrid(h: h, v: v)]
            if prefs.effects != 3 { ops.append(.drawLightsOntoTiles) }
            if sprites {
                sp.idle.handle(h: h, v: v, playerHotRect: nil, active: &sp.active, faceRect: r.faceBounds)
                draws = sp.active.wrapDrawSprites()
            } else { draws = [] }
            ops.append(.wrapDrawSprites(draws))
            ops.append(.copyToScreen(h: h, v: v, graphicsMode: 1, backdrop: prefs.plainCopy == 0))
            try r.apply(FrameOps(draws: ops))
            // erase so the next pass / scroll starts clean
            try r.apply(FrameOps(draws: [.wrapEraseSprites(sprites: sp.active.sprites, h: h, v: v)]))
        }
        let words = r.screen.rgba(through: r.screenClut)
        var bytes = [UInt8](); bytes.reserveCapacity(words.count * 3)
        for w in words { bytes += [UInt8(w >> 16 & 0xff), UInt8(w >> 8 & 0xff), UInt8(w & 0xff)] }
        try Data(bytes).write(to: URL(fileURLWithPath: "\(outdir)/\(h)_\(v).rgb"))
        // also the sprite-coverage: render a mask of sprite pixels = screen indices differ from a sprite-less pass is costly; skip
    }
default: fatalError("cmd")
}
