import Foundation
import XCTest
@testable import AkiCore

/// U1 (D11 Remaster) — `tools/aki-art-regions.json` covers every source rect the game draws from. Picture
/// regions are upscaled per region by `tools/upscale-aki-art.py`, so a picture source rect spanning two regions
/// (or one region spanning two sprites) would bleed; mask regions stay nearest-neighbour, bit-exact.
/// No game data needed: the rects come from `AkiGameArt` / `AkiMap` / `AkiSplash` and the JSON's own sizes.
final class ArtRegionsTests: XCTestCase {

    private struct Region { var rect: QDRect; var kind: String; var note: String }
    private struct FileEntry { var width: Int; var height: Int; var regions: [Region] }

    private func r(_ l: Int, _ t: Int, _ rr: Int, _ b: Int) -> QDRect { QDRect(left: l, top: t, right: rr, bottom: b) }

    private func loadMap() throws -> [String: FileEntry] {
        var repo = URL(fileURLWithPath: #filePath)             // …/Aki/Core/Tests/AkiCoreTests/<file>
        for _ in 0..<5 { repo.deleteLastPathComponent() }      // → the repo (or worktree) root
        let data = try Data(contentsOf: repo.appendingPathComponent("tools/aki-art-regions.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var map: [String: FileEntry] = [:]
        for (name, value) in json where name.hasSuffix(".png") {
            let entry = try XCTUnwrap(value as? [String: Any], name)
            let size = try XCTUnwrap(entry["size"] as? [Int], name)
            let regions = try XCTUnwrap(entry["regions"] as? [[String: Any]], name).map { reg -> Region in
                let a = reg["rect"] as? [Int] ?? []
                return Region(rect: a.count == 4 ? r(a[0], a[1], a[2], a[3]) : r(0, 0, 0, 0),
                              kind: reg["kind"] as? String ?? "?", note: reg["note"] as? String ?? "")
            }
            map[name] = FileEntry(width: size[0], height: size[1], regions: regions)
        }
        return map
    }

    private func inside(_ a: QDRect, _ b: QDRect) -> Bool {
        a.left >= b.left && a.top >= b.top && a.right <= b.right && a.bottom <= b.bottom
    }

    private func overlaps(_ a: QDRect, _ b: QDRect) -> Bool {
        a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom
    }

    // MARK: - Every source rect the game draws from

    private static let wholeFilePictures: [String] = ["map.png", "buyaki.png", "welcome.png", "guide.png", "paper.png"]
        + (1...17).map { "background\($0).png" } + (1...17).map { "preview\($0).png" }

    /// (file, rect, label) for every PICTURE source rect.
    private func pictureSources(_ map: [String: FileEntry]) -> [(String, QDRect, String)] {
        typealias A = AkiGameArt
        var out: [(String, QDRect, String)] = []
        // tiles.png / tile_pictures.png
        out += [("tiles.png", A.tileBlank, "tileBlank"), ("tiles.png", A.tileSelected, "tileSelected"),
                ("tiles.png", A.tileHint, "tileHint"), ("tiles.png", A.tileGrey, "tileGrey")]
        out += (200...241).map { ("tile_pictures.png", A.facePicture($0), "facePicture(\($0))") }
        // plate.png: the plate and every restore source taken from it
        out.append(("plate.png", A.plateSource, "plateSource"))
        out += (3...5).map { ("plate.png", A.pressedRestoreSource($0), "pressedRestoreSource(\($0))") }
        out += (1...6).map { ("plate.png", A.flash($0).restoreSource, "flash(\($0)).restoreSource") }
        out += [("plate.png", A.elapsedRestore.src, "elapsedRestore"), ("plate.png", A.pairsRestore.src, "pairsRestore"),
                ("plate.png", A.timeBarRestore.src, "timeBarRestore")]
        // misc.png: buttons, flash, digits, time bar, lantern, difficulty words
        out += (3...5).map { ("misc.png", A.buttonSprite($0), "buttonSprite(\($0))") }
        out += (3...5).map { ("misc.png", A.pressedSprite($0), "pressedSprite(\($0))") }
        out.append(("misc.png", A.pausedSprite, "pausedSprite"))
        for n in 1...6 {
            out.append(("misc.png", A.flash(n).spriteSource, "flash(\(n)).spriteSource"))
            out.append(("misc.png", A.flash(n).glowSource, "flash(\(n)).glowSource"))
        }
        out += (0...9).map { ("misc.png", A.digit($0).src, "digit(\($0))") }
        // pairsHundredsDigit(0) (row 87) is excluded: the caller draws it only for (n / 100) % 10 == 0 with n > 99,
        // i.e. n >= 1000 open pairs — unreachable — and its rect lies inside the time-bar stone-mask strip
        // (3, 78, 428, 117), not on a digit sprite.
        out += (1...9).map { ("misc.png", A.pairsHundredsDigit($0).src, "pairsHundredsDigit(\($0))") }
        out.append(("misc.png", A.colon, "colon"))
        for length in 0...(17 * 24 + 23) {
            let s = try! XCTUnwrap(A.timeBarStones(raw: 1, length: length))
            if let full = s.fullSource { out.append(("misc.png", full, "timeBarStones(\(length)).fullSource")) }
            out.append(("misc.png", s.capSource, "timeBarStones(\(length)).capSource"))
        }
        out.append(("misc.png", AkiMap.lanternSprite, "lanternSprite"))
        out += (0...3).map { ("misc.png", AkiMap.difficultyWord($0), "difficultyWord(\($0))") }
        // pause.png / nopairs.png
        out += ["pause.png", "nopairs.png"].map { ($0, A.overlaySource, "overlaySource") }
        // arrow.png, previews.png, notavail.png
        out += [("arrow.png", AkiMap.leftArrowSprite, "leftArrowSprite"), ("arrow.png", AkiMap.rightArrowSprite, "rightArrowSprite")]
        out += (0...11).map { ("previews.png", AkiMap.previewStrip($0), "previewStrip(\($0))") }
        out.append(("notavail.png", AkiMap.lockedOverlay, "lockedOverlay"))
        // proverbs.png: 11 strips of 392×157 (AkiSplash.randomProverb, 11 × 157 = 1727)
        out += (0..<11).map { ("proverbs.png", r(0, 157 * $0, 392, 157 * $0 + 157), "proverb strip \($0)") }
        // whole-file pictures (drawn whole: map, backgrounds, splashes, paper, level previews) + the map's preview restore
        for name in Self.wholeFilePictures {
            let e = map[name]
            out.append((name, r(0, 0, e?.width ?? -1, e?.height ?? -1), "\(name) whole"))
        }
        out.append(("map.png", AkiMap.previewRestore, "previewRestore"))
        return out
    }

    /// (file, rect, label) for every MASK source rect.
    private func maskSources() -> [(String, QDRect, String)] {
        typealias A = AkiGameArt
        var out: [(String, QDRect, String)] = []
        out += (0...10).map { ("tiles.png", A.fadeMask($0), "fadeMask(\($0))") }
        out.append(("tiles.png", A.overlayMask, "overlayMask"))
        out.append(("plate.png", A.plateMask, "plateMask"))
        out.append(("misc.png", A.buttonMask, "buttonMask"))
        for n in 1...6 {
            out.append(("misc.png", A.flash(n).spriteMask, "flash(\(n)).spriteMask"))
            for p in 1...6 { out.append(("misc.png", A.flash(n).glowMask(p), "flash(\(n)).glowMask(\(p))")) }
        }
        out += (0...9).map { ("misc.png", A.digit($0).mask, "digit(\($0)).mask") }
        out += (1...9).map { ("misc.png", A.pairsHundredsDigit($0).mask, "pairsHundredsDigit(\($0)).mask") }  // 0: see pictureSources
        out.append(("misc.png", A.colonMask, "colonMask"))
        for length in 0...(17 * 24 + 23) {
            let s = try! XCTUnwrap(A.timeBarStones(raw: 1, length: length))
            if let full = s.fullMask { out.append(("misc.png", full, "timeBarStones(\(length)).fullMask")) }
            out.append(("misc.png", s.capMask, "timeBarStones(\(length)).capMask"))
        }
        out += (0...23).map { ("misc.png", A.capCell($0), "capCell(\($0))") }
        out.append(("misc.png", AkiMap.lanternStaticMask, "lanternStaticMask"))
        out += AkiMap.blinkMasks.enumerated().map { ("misc.png", $1, "blinkMasks[\($0)]") }
        out += (0...3).map { ("misc.png", AkiMap.difficultyWordMask($0), "difficultyWordMask(\($0))") }
        out += ["pause.png", "nopairs.png"].map { ($0, A.overlaySourceMask, "overlaySourceMask") }
        out += [("arrow.png", AkiMap.leftArrowMask, "leftArrowMask"), ("arrow.png", AkiMap.rightArrowMask, "rightArrowMask")]
        out.append(("notavail.png", AkiMap.lockedOverlayMask, "lockedOverlayMask"))
        return out
    }

    // MARK: - Tests

    func testEveryPictureSourceRectLiesInOnePictureRegion() throws {
        let map = try loadMap()
        let sources = pictureSources(map)
        XCTAssertGreaterThan(sources.count, 900)
        for (file, rect, label) in sources {
            guard let entry = map[file] else { XCTFail("\(file) missing from the region map (\(label))"); continue }
            let hits = entry.regions.filter { $0.kind == "picture" && inside(rect, $0.rect) }
            XCTAssertEqual(hits.count, 1, "\(file) \(label) \(rect) lies in \(hits.count) picture regions")
            let touched = entry.regions.filter { overlaps(rect, $0.rect) }
            XCTAssertEqual(touched.count, 1, "\(file) \(label) \(rect) touches \(touched.map(\.note))")
        }
    }

    /// Every picture region is the tight union bounding box of the picture source rects that lie in it, and those
    /// rects leave no pixel of it uncovered, so a region
    /// that swallows two separate sprites plus the gap between them (which would bleed into each other through the
    /// upscaler) fails. A whole-file region passes only by being a whole-file picture's own enumerated source.
    /// The one region with no enumerated source is notavail.png's demo-unavailable strip: shipped art the replica
    /// never draws, kept as its own region (it still must not touch anything else — testRegionsDisjointAndInBounds).
    func testNoPictureRegionSpansTwoSprites() throws {
        let map = try loadMap()
        let sources = pictureSources(map)
        for (name, entry) in map {
            for region in entry.regions where region.kind == "picture" {
                let inRegion = sources.filter { $0.0 == name && inside($0.1, region.rect) }.map(\.1)
                guard let first = inRegion.first else {
                    XCTAssertTrue(name == "notavail.png" && region.note.contains("unused by the replica"),
                                  "\(name) picture region \(region.note) \(region.rect) has no source rect in it")
                    continue
                }
                let union = inRegion.dropFirst().reduce(first) {
                    r(min($0.left, $1.left), min($0.top, $1.top), max($0.right, $1.right), max($0.bottom, $1.bottom))
                }
                XCTAssertEqual(region.rect, union, "\(name) picture region \(region.note) \(region.rect) is not the "
                               + "bounding box \(union) of its \(inRegion.count) source rects")
                // and no gap: the source rects together cover every pixel of the region
                let w = region.rect.right - region.rect.left, h = region.rect.bottom - region.rect.top
                var covered = [Bool](repeating: false, count: max(0, w * h))
                for s in inRegion {
                    for y in (s.top - region.rect.top)..<(s.bottom - region.rect.top) {
                        for x in (s.left - region.rect.left)..<(s.right - region.rect.left) { covered[y * w + x] = true }
                    }
                }
                let gaps = covered.filter { !$0 }.count
                XCTAssertEqual(gaps, 0, "\(name) picture region \(region.note) \(region.rect): \(gaps) px covered by "
                               + "none of its \(inRegion.count) source rects (two sprites and a gap?)")
            }
        }
    }

    func testEveryMaskRectLiesInAMaskRegion() throws {
        let map = try loadMap()
        for (file, rect, label) in maskSources() {
            guard let entry = map[file] else { XCTFail("\(file) missing from the region map (\(label))"); continue }
            let hits = entry.regions.filter { $0.kind == "mask" && inside(rect, $0.rect) }
            XCTAssertEqual(hits.count, 1, "\(file) \(label) \(rect) lies in \(hits.count) mask regions")
            let pictures = entry.regions.filter { $0.kind == "picture" && overlaps(rect, $0.rect) }
            XCTAssertTrue(pictures.isEmpty, "\(file) \(label) \(rect) overlaps picture regions \(pictures.map(\.note))")
        }
    }

    func testRegionsDisjointAndInBounds() throws {
        let map = try loadMap()
        XCTAssertEqual(map.count, 50, "every one of the 50 shipped PNGs appears")
        for name in Self.wholeFilePictures + ["tiles.png", "tile_pictures.png", "plate.png", "misc.png", "pause.png",
                                               "nopairs.png", "previews.png", "notavail.png", "arrow.png",
                                               "proverbs.png", "layer_buttons.png"] {
            XCTAssertNotNil(map[name], name)
        }
        for (name, entry) in map {
            for (i, a) in entry.regions.enumerated() {
                XCTAssertTrue(["picture", "mask"].contains(a.kind), "\(name) \(a.note) kind \(a.kind)")
                XCTAssertTrue(a.rect.left >= 0 && a.rect.top >= 0 && a.rect.right <= entry.width
                              && a.rect.bottom <= entry.height && a.rect.left < a.rect.right && a.rect.top < a.rect.bottom,
                              "\(name) \(a.note) \(a.rect) outside \(entry.width)×\(entry.height)")
                for b in entry.regions[(i + 1)...] {
                    XCTAssertFalse(overlaps(a.rect, b.rect), "\(name): \(a.note) overlaps \(b.note)")
                }
            }
        }
    }
}
