import Foundation
import DeimosCore

/// Executes Core's `RenderOp`s on the display's persistent buffers (plan S4, R3): `DisplayBuffers` (R1) + the
/// sprite dispatcher `SpriteBlitter` (R2) + the 16 render lists. Every op but `.fade` and `.limit` goes through
/// `apply`; a fade is stepped by the host with `fadeBegin` / `fadeStep` / `fadeEnd` (Fades.swift), and `.limit` is
/// the host's wait. Nothing is reset between passes — the buffers carry the original's artefacts (the score bar
/// persists in the back buffer; HUD elements are restored from the save buffer before each redraw).
///
/// Ops:
/// - `.loadTerrain(id)` — `FUN_1000fbc0` (`1000fbc0…1000fd04`): `FUN_10009d70(D+0x6c, w, h, depth)` resizes the
///   terrain buffer to the image — when the size differs it frees the old one, zeroes the object (the interlace
///   parity `+0x2c` included, `10009e00`) and creates a fresh black one (`FUN_10009bd0`); the same size keeps
///   it (`10009d9c…10009dbc`) — then `FUN_10009fd0(image, terrain, &bounds, &bounds, 0)` copies the image
///   (`1000fcc0…1000fcf0`). The original asserts image size == the level's background RECT (line 0xe7,
///   "Background image dimensions do not match Level data": width == RECT right, height == RECT bottom —
///   data-tags.md); replicated as a precondition against every `leve` whose `#backgroundImage_ID` is the image.
/// - `.fill(id, colour)` — `FUN_10009f00`: PaintRect(portRect).
/// - `.loadImage(id, into, dst)` — `FUN_10031400`: the TGA (`TGAImage`, row 0 = visual top) copied srcCopy to
///   `dst` (equal size: `scor` 160×480 into {0,416,480,576} and {0,0,480,160}).
/// - `.copy` — `FUN_10009fd0` (`DisplayBuffers.copyBuffer`).
/// - `.draw(cmd)` — `FUN_10019570`: face `none` or alpha 32 → nothing (`10019590…100195a8`); `+0x31` == 0 →
///   `FUN_1001a450` append (`100195ac…100195bc`); else the blit (`SpriteBlitter`, frame from
///   `DeimosAssets.spriteGroup`).
/// - `.clearLayers` / `.flushLayers(r)` — `FUN_100189f0` / `FUN_10018b20` (each layer of the band in order,
///   `FUN_1001a650(n)`; RenderLists.swift).
/// - `.screenBlit(src, dst)` — `FUN_1000bbd0` (`1000bbd0…1000bc5c`): one CopyBits srcCopy, back → window.
/// - `.present(kind)` — `Presents`.
/// - `.particles(stamps)` — `FUN_10043ba0` (`ParticleStamps`): the 7×7 spread-555 stamps into the back buffer.
/// - `.pauseWait` traps with `.fade` / `.limit` (`RenderOp.isHostOp`).
///
/// Image decodes are cached per process (`ImageCache`); sprite groups through the assets' own cache. Missing data
/// stops the renderer the same way for both: an `im16` that is missing or not a 16-bit TGA, and a sprite group
/// that is missing or does not decode, are precondition failures naming the tag and the data directory (the
/// original's loaders assert). A frame index outside an existing group draws nothing.
public final class DeimosRenderer {
    public let assets: DeimosAssets
    public private(set) var buffers = DisplayBuffers()
    public private(set) var renderLists = RenderLists()
    /// Resolved sprite groups (the assets' cache takes a lock per lookup; this skips it on the hot path).
    private var groups: [FourCC: SpriteGroup?] = [:]

    public init(assets: DeimosAssets) {
        self.assets = assets
    }

    /// The 640×480 window content.
    public var screen: Pixmap555 { buffers.screen }

    public func buffer(_ id: BufferID) -> Pixmap555 { buffers.buffer(id) }

    public func apply(_ op: RenderOp) {
        switch op {
        case let .loadTerrain(image):
            loadTerrain(image)
        case let .fill(id, colour):
            withBuffer(id) { $0.fill(colour) }
        case let .loadImage(image, into, dst):
            let img = self.image(image)
            let src = img.bounds
            withBuffer(into) { CopyBits.copy(from: img, to: &$0, srcRect: src, dstRect: dst) }
        case let .copy(from, to, src, dst, interlaced):
            buffers.copyBuffer(from: from, to: to, srcRect: src, dstRect: dst, interlaced: interlaced)
        case let .draw(cmd):
            draw(cmd)
        case .clearLayers:
            renderLists.clear()
        case let .flushLayers(range):
            for layer in range { renderLists.flush(layer: layer) { blit($0) } }   // blits touch `buffers` only
        case let .screenBlit(src, dst):
            let back = buffers.back
            CopyBits.copy(from: back, to: &buffers.screen, srcRect: src, dstRect: dst)
        case let .present(kind):
            buffers.present(kind)
        case let .particles(stamps):
            ParticleStamps.stamp(stamps, into: &buffers.back)                       // FUN_10043ba0 at 10030cd0
        case .fade, .limit, .pauseWait:
            preconditionFailure("DeimosRenderer.apply: \(op) is the host's (fadeBegin/fadeStep/fadeEnd; limit; pauseWait)")
        }
    }

    public func fadeBegin(_ kind: FadeKind) { buffers.fadeBegin(kind) }

    public func fadeStep(_ kind: FadeKind, a: Int, present: PresentKind) {
        buffers.fadeStep(kind, a: a, present: present)
    }

    public func fadeEnd() { buffers.fadeEnd() }

    // MARK: - Internals

    private func withBuffer(_ id: BufferID, _ body: (inout Pixmap555) -> Void) {
        switch id {
        case .back: body(&buffers.back)
        case .terrain: body(&buffers.terrain)
        case .scoreSave: body(&buffers.scoreSave)
        }
    }

    private func loadTerrain(_ image: FourCC) {
        let img = self.image(image)
        for level in assets.definitions.levels where level.backgroundImage == image {
            precondition(img.width == Int(level.background.right) && img.height == Int(level.background.bottom),
                         "DeimosRenderer: Background image dimensions do not match Level data — im16 '\(image)' is "
                         + "\(img.width)×\(img.height), leve '\(level.id)' #background_RECT \(level.background) "
                         + "(data: \(dataDirectory))")
        }
        if buffers.terrain.width != img.width || buffers.terrain.height != img.height {
            buffers.terrain = Pixmap555(width: img.width, height: img.height)       // 10009dc0…10009e1c
        }
        let r = buffers.terrain.bounds
        CopyBits.copy(from: img, to: &buffers.terrain, srcRect: r, dstRect: r)      // 1000fcf0
    }

    /// The decoded image; a missing or undecodable tag stops here as the original's loader asserts.
    private func image(_ id: FourCC) -> Pixmap555 {
        guard let img = ImageCache.shared.image(id, index: assets.index) else {
            preconditionFailure("DeimosRenderer: im16 '\(id)' is missing or not a 16-bit TGA (data: \(dataDirectory))")
        }
        return img
    }

    /// The folder holding the paks, for failure messages.
    private var dataDirectory: String {
        assets.index.paks.first?.deletingLastPathComponent().deletingLastPathComponent().path ?? "?"
    }

    /// `FUN_10019570`'s entry: refuse, queue, or blit.
    private func draw(_ cmd: DrawCommand) {
        if cmd.face == .none || cmd.alpha == 32 { return }                          // 10019590…100195a8
        if !cmd.drawNow { renderLists.append(cmd); return }                         // 100195ac…100195bc
        blit(cmd)
    }

    private func blit(_ cmd: DrawCommand) {
        let frame = cmd.face == SpriteBlitter.costFace ? nil : resolve(cmd.face, cmd.frame)
        SpriteBlitter.draw(cmd, frame: frame, buffers: &buffers)
    }

    private func resolve(_ face: FourCC, _ index: Int) -> SpriteFrame? {
        let group: SpriteGroup?
        if let cached = groups[face] {
            group = cached
        } else {
            do {
                group = try assets.spriteGroup(face)
            } catch {
                preconditionFailure("DeimosRenderer: sprite group '\(face)' is missing or does not decode: \(error) "
                                    + "(data: \(dataDirectory))")
            }
            groups[face] = .some(group)
        }
        guard let g = group, g.frames.indices.contains(index) else { return nil }
        return g.frames[index]
    }
}

/// Decoded `im16` images as 16-bit buffers, once per process per data set (plan Landmine e).
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private let lock = NSLock()
    private var images: [String: Pixmap555?] = [:]

    func image(_ id: FourCC, index: TagIndex) -> Pixmap555? {
        let key = index.paks.map(\.path).joined(separator: "|") + "#" + id.description
        lock.lock()
        defer { lock.unlock() }
        if let hit = images[key] { return hit }
        var out: Pixmap555?
        if let r = index.record(type: FourCC("im16")!, id: id), let data = try? index.data(for: r),
           let tga = try? TGAImage(data: data) {
            var p = Pixmap555(width: tga.width, height: tga.height)
            p.pixels = tga.pixels
            out = p
        }
        images[key] = .some(out)
        return out
    }
}
