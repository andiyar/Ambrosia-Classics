#if canImport(CoreText)
@testable import fz_bake_font
#endif
import FerazelCore
@testable import FerazelRender
@testable import FerazelWinKit
import Foundation
import HectorResources
import XCTest

/// WF2 (D43 Ruling 2): the baked text. Every comparison is byte for byte against the Mac's own `CoreTextRasterizer`
/// (the oracle tests are Mac-only, `#if canImport(CoreText)`); the format, the unbaked face and the face set run
/// everywhere. A missing data file or font is a FAILURE, never a skip.
@MainActor final class BakedTextTests: XCTestCase {
    /// The committed fonts (`Ferazel/Windows/Resources/Fonts`, by #filePath).
    nonisolated static let fontsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Resources/Fonts", isDirectory: true)

    /// The faces the game draws (font, size, face): Times 12 bold, Geneva 9 plain, Geneva 8 bold, Times 18 plain.
    static let gameFaces: Set<[Int16]> = [[20, 12, 1], [3, 9, 0], [3, 8, 1], [20, 18, 0]]
    /// Every baked face: the game's plus the in-window dialogs' UI font bold 12 (WF4a).
    static let bakedFaces: [[Int16]] = [[0, 12, 1], [3, 8, 1], [3, 9, 0], [20, 12, 1], [20, 18, 0]]

    /// Self-measured (WF2) with the baked faces in WF1's headless frames setup (muted, the silent mixer, the fixed seed
    /// and clock): boot → main menu (360 ticks) and New Game (N held) → level 1's first presented frame (107 ticks).
    /// WF3's reference. Both equal WF1's stub-text pins: neither frame draws a string (by then the driver has asked
    /// only the conversation measures, Times 18 `CharWidth` / `GetFontInfo`); CoreText gives the same (test 10).
    static let bakedMainMenuFNV: UInt64 = 0xae2b_1ee0_8c08_9b2a
    static let bakedLevelOneFNV: UInt64 = 0xc99c_e8e8_5b4b_d8f7

    static func baked() throws -> BakedTextRasterizer { try BakedTextRasterizer(fontsDirectory: fontsDirectory) }

    static func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    typealias Mask = (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8])

    static func same(_ a: Mask, _ b: Mask) -> Bool {
        a.left == b.left && a.top == b.top && a.width == b.width && a.height == b.height && a.coverage == b.coverage
    }

    /// Every level's `Mlvl` header name — what `StatusBarState.levelName` is filled with (`LevelRun.swift:520,885`,
    /// `HandleKeys.swift:256,313`: `levelFile.header.name` / `w.level.header.name`).
    static func levelNames() throws -> [String] {
        let r = try resources()
        return try r.world.resources(of: "Mlvl").map(\.id).sorted().map { try LevelFile.load(from: r, level: $0).header.name }
    }

    /// Wraps a rasterizer and records every (font, size, face) it is asked for.
    final class RecordingRasterizer: TextRasterizer {
        let inner: any TextRasterizer
        var faces: Set<[Int16]> = []
        init(_ inner: any TextRasterizer) { self.inner = inner }
        func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
            -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]) {
            faces.insert([font, size, face])
            return inner.rasterize(text, font: font, size: size, face: face)
        }
        func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int {
            faces.insert([font, size, face])
            return inner.charWidth(byte, font: font, size: size, face: face)
        }
        func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int) {
            faces.insert([font, size, face])
            return inner.fontInfo(font: font, size: size, face: face)
        }
    }

    // MARK: - routes (shared by the face-set test and the end-to-end test)

    /// Level 1's renderer (`FrameGoldenTests`' configuration: `.ruled`, tie-break lowest, error diffusion) and its
    /// session at seed 1 with the renderer's face bounds and face pixels, as `Phase2GoldenTests.session`.
    static func levelOne(_ text: any TextRasterizer) throws -> (FrameRenderer, FerazelSession) {
        let r = try resources()
        let frame = try FrameRenderer(resources: r, level: 1, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                      dither: .errorDiffusion, text: text, prefs: FerazelPrefs())
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1, seed: 1,
                                   faceBounds: frame.faceBounds, particleFaces: frame.particleFaces)
        try frame.addLights(s.lights)
        try frame.buildTintTable(s.tintTableDraws)
        return (frame, s)
    }

    /// The sign-frame route (`ConversationRenderTests.testSignFrameGolden`, golden c8e41941c1e4d6da with the box
    /// rasterizer): level 1's first frame, then L1 sign rec 1's text (STR# 500 [12]) typed out in full by
    /// `ConversationRun` with `TextLayout.conversationText(text)` and drawn by `ConversationRenderer`. FNV of the
    /// 640×480 indices.
    static func signRoute(_ text: any TextRasterizer) throws -> UInt64 {
        let r = try resources()
        let frame = try FrameRenderer(resources: r, level: 1, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                      dither: .errorDiffusion, text: text)
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1, faceBounds: frame.faceBounds)
        try frame.addLights(s.lights)
        try frame.buildTintTable(s.tintTableDraws)
        try frame.apply(s.step(keys: KeyState()))
        let words = MacRoman.bytes(try XCTUnwrap(try StringList.load(from: r, id: 500).string(12)))
        let c = ConversationRun(.simple(pict: 4020, name: MacRoman.bytes("Wooden Sign"), text: words), world: s.world,
                                resources: r, prefs: FerazelPrefs(), levelName: "",
                                text: TextLayout.conversationText(text))
        var save = SaveBlock()
        var draws: [DrawOp] = []
        var t: UInt32 = 1000
        repeat {
            draws += c.tick(now: t, input: FrontInput(), save: &save).draws
            t += 1
        } while c.wait == .typing && t < 20000
        XCTAssertEqual(c.wait, .anyKey)
        try ConversationRenderer(frame: frame, text: text).apply(draws)
        return fnv1a64(frame.screen.pixels)
    }

    // The original default keys (engine §7.1).
    static let left = Int(FerazelPrefs.defaultKeys[0]), right = Int(FerazelPrefs.defaultKeys[1])
    static let up = Int(FerazelPrefs.defaultKeys[2]), down = Int(FerazelPrefs.defaultKeys[3])
    static let run = Int(FerazelPrefs.defaultKeys[4]), jump = Int(FerazelPrefs.defaultKeys[5])

    /// `Phase2GoldenTests.swimRoute` + `poolStrokes` (the level-1 golden route, 397 iterations: the col-24 wall break,
    /// the pickups — score and the status bar's text — the sign at step 148, the pool entry).
    static let golden: [(keys: [Int], frames: Int)] = [
        ([right], 14), ([right, jump], 3), ([right], 14), ([right, jump], 6), ([right], 14), ([right, jump], 1),
        ([right, run], 19), ([right, down], 7), ([left, jump], 8), ([down, jump], 24), ([up, right], 13),
        ([right], 22), ([right, jump], 2), ([up], 27), ([right, run], 25), ([left], 20), ([right, run, jump], 4),
        ([right, down], 4), ([right, run, jump], 3), ([up, right], 6), ([down, jump], 21), ([up, right], 11),
        ([right, run], 48), ([right, run, jump], 6), ([right, run], 35),
        ([], 6), ([jump], 6), ([], 10), ([right, jump], 8), ([up], 4), ([], 6),
    ]

    /// The golden route's frames: FNV of the per-frame FNVs (little-endian), and the count.
    static func goldenRoute(_ text: any TextRasterizer) throws -> (UInt64, Int) {
        let (frame, s) = try levelOne(text)
        var chain: [UInt8] = []
        var n = 0
        for (keys, frames) in golden { for _ in 0..<frames {
            let k = KeyState(pressed: keys)
            try frame.apply(answering(s, s.step(keys: k), keys: k))
            let h = fnv1a64(frame.screen.pixels)
            chain += (0..<8).map { UInt8(h >> (8 * $0) & 0xff) }
            n += 1
        } }
        return (fnv1a64(chain), n)
    }

    /// `Phase2GoldenTests.answeringTalk`: a suspension answered at once with the rest of the frame merged in.
    static func answering(_ s: FerazelSession, _ first: FrameOps, keys: KeyState) -> FrameOps {
        var ops = first
        while let x = ops.suspension {
            let outcome: FrameSuspension.Outcome
            var modal = FrontOutput()
            switch x {
            case .sign: outcome = .sign(keys: keys, capsLock: false)
            case .conversation: outcome = .conversation(keys: keys, capsLock: false)
            case .upgrade(let type):
                var u = UpgradeAnimation(type: type)
                var now: UInt32 = 0
                while !u.isDone {
                    modal.append(u.tick(now: now, session: s, keys: keys))
                    now += 1
                }
                outcome = .upgrade(keys: keys, capsLock: false)
            case .hint: outcome = .hint(keys: keys, capsLock: false)
            case .teleport: outcome = .teleport(keys: keys, capsLock: false)
            default: return ops
            }
            let rest = s.resume(outcome)
            var whole = ops
            whole.draws += modal.draws
            whole.sounds += modal.sounds
            whole.requests += modal.requests
            whole.draws += rest.draws
            for (i, snd) in rest.soundStops.enumerated() {
                whole.soundStops.append(snd)
                whole.soundStopAt.append(ops.sounds.count + rest.soundStopAt[i])
            }
            whole.sounds += rest.sounds
            whole.music += rest.music
            whole.requests += rest.requests
            whole.drawn = rest.drawn
            whole.suspension = rest.suspension
            ops = whole
        }
        return ops
    }

    /// Boot → main menu, then New Game (N held) → level 1's first presented frame, through the shared driver (WF1's
    /// scenario): (boot ticks, main-menu FNV, New Game ticks, level-1 FNV).
    static func driverFrames(_ text: any TextRasterizer) throws -> (Int, UInt64, Int, UInt64) {
        let rig = try Rig(mute: true, mixer: .headless, text: text)
        try rig.toMainMenu()
        let boot = rig.ticks
        let menu = fnv1a64(try XCTUnwrap(rig.lastRGBA))
        try rig.drive(input: { _ in FrontInput(keys: KeyState(pressed: [MainMenu.newGameKey])) }) {
            $0.flow.levelRun != nil && $0.lastOutput.present
        }
        XCTAssertEqual(rig.flow.levelRun?.levelNumber, 1)
        XCTAssertTrue(rig.counters.logs.isEmpty, "\(rig.counters.logs)")
        return (boot, menu, rig.ticks - boot, fnv1a64(try XCTUnwrap(rig.lastRGBA)))
    }

    // MARK: - 1 … 6: against CoreText (Mac)

    #if canImport(CoreText)
    /// (1) Every face × every MacRoman byte (0x00–0xFF): `rasterize(byte:)` (offsets, size, mask), `charWidth`; each
    /// face's `fontInfo`; the smoothing threshold.
    func testEveryCharacterOfEveryFaceMatchesCoreText() throws {
        XCTAssertEqual(BakedTextRasterizer.smoothingThreshold, CoreTextRasterizer.smoothingThreshold)
        let ct = CoreTextRasterizer(), baked = try Self.baked()
        XCTAssertEqual(baked.bakedFaces, Self.bakedFaces)
        var compared = 0, misses: [String] = []
        for f in Self.bakedFaces {
            let (font, size, face) = (f[0], f[1], f[2])
            let a = ct.fontInfo(font: font, size: size, face: face), b = baked.fontInfo(font: font, size: size, face: face)
            XCTAssertTrue(a == b, "\(f) fontInfo \(a) ≠ \(b)")
            for byte in 0...255 {
                let x = ct.rasterize(byte: UInt8(byte), font: font, size: size, face: face)
                let y = baked.rasterize(byte: UInt8(byte), font: font, size: size, face: face)
                if !Self.same(x, y) { misses.append("\(f) 0x\(String(byte, radix: 16)) mask") }
                if ct.charWidth(UInt8(byte), font: font, size: size, face: face)
                    != baked.charWidth(UInt8(byte), font: font, size: size, face: face) {
                    misses.append("\(f) 0x\(String(byte, radix: 16)) charWidth")
                }
                compared += 1
            }
        }
        XCTAssertEqual(compared, 5 * 256)
        XCTAssertEqual(misses.count, 0, "\(misses.prefix(20))")
    }

    /// (2) The closed string set: every level name in Times 12 bold (`.UpdateTextStats`) and "x" in both Geneva faces.
    func testClosedStringSetMatchesCoreText() throws {
        let ct = CoreTextRasterizer(), baked = try Self.baked()
        let names = try Self.levelNames()
        XCTAssertGreaterThan(names.count, 1)
        var misses: [String] = []
        for name in names where !Self.same(ct.rasterize(name, font: 20, size: 12, face: 1),
                                           baked.rasterize(name, font: 20, size: 12, face: 1)) {
            misses.append(name)
        }
        for (size, face): (Int16, Int16) in [(9, 0), (8, 1)]
            where !Self.same(ct.rasterize("x", font: 3, size: size, face: face),
                             baked.rasterize("x", font: 3, size: size, face: face)) {
            misses.append("x \(size)/\(face)")
        }
        XCTAssertEqual(misses, [])
    }

    /// (3) Score / coin strings 0…99,999 in Times 12 bold: the edges and 1,000 seeded samples.
    func testScoreAndCoinStringsMatchCoreText() throws {
        let ct = CoreTextRasterizer(), baked = try Self.baked()
        var values = [0, 1, 9, 10, 11, 19, 99, 100, 101, 111, 999, 1000, 1111, 9999, 10000, 11111, 99999]
        var seed: UInt64 = 0x5EED_F02A
        for _ in 0..<1000 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            values.append(Int((seed >> 33) % 100_000))
        }
        XCTAssertEqual(values.count, 1017)
        let misses = values.filter {
            !Self.same(ct.rasterize(String($0), font: 20, size: 12, face: 1),
                       baked.rasterize(String($0), font: 20, size: 12, face: 1))
        }
        XCTAssertEqual(misses, [])
    }

    /// (4) Every item count the status bar can show (2…99: `1 < count`, `.AddItem` caps at 99, `Inventory.swift:74`)
    /// in Geneva 9 plain (the selected slot) and Geneva 8 bold (each slot), as whole strings.
    func testItemCountStringsMatchCoreText() throws {
        let ct = CoreTextRasterizer(), baked = try Self.baked()
        var misses: [String] = []
        for (size, face): (Int16, Int16) in [(9, 0), (8, 1)] {
            for n in 2...99 where !Self.same(ct.rasterize(String(n), font: 3, size: size, face: face),
                                             baked.rasterize(String(n), font: 3, size: size, face: face)) {
                misses.append("\(n) \(size)/\(face)")
            }
        }
        XCTAssertEqual(misses, [])
    }

    /// (5) Every kerning pair and ligature each face has, drawn as its two-character string; a ligature also inside a
    /// word, and kerning pairs chained three at a time.
    func testKerningAndLigaturePairsMatchCoreText() throws {
        let ct = CoreTextRasterizer(), baked = try Self.baked()
        var misses: [String] = [], pairs = 0, ligatures = 0
        let fonts = try FileManager.default.contentsOfDirectory(atPath: Self.fontsDirectory.path)
            .filter { $0.hasSuffix(".fzfont") }.sorted()
            .map { try FZFont(data: Data(contentsOf: Self.fontsDirectory.appendingPathComponent($0))) }
        XCTAssertEqual(fonts.count, Self.bakedFaces.count)
        func s(_ v: UInt32) -> String { String(Character(Unicode.Scalar(v)!)) }
        for f in fonts {
            func check(_ t: String) {
                if !Self.same(ct.rasterize(t, font: f.font, size: f.size, face: f.face),
                              baked.rasterize(t, font: f.font, size: f.size, face: f.face)) {
                    misses.append("\(f.font)/\(f.size)/\(f.face) \(t.unicodeScalars.map { String($0.value, radix: 16) })")
                }
            }
            let kerned = f.kerning.keys.sorted()
            for p in kerned { check(s(p.left) + s(p.right)); pairs += 1 }
            for i in stride(from: 0, to: kerned.count, by: 97) {
                let p = kerned[i]
                if let q = kerned.first(where: { $0.left == p.right }) { check(s(p.left) + s(p.right) + s(q.right)) }
            }
            for p in f.ligatures.keys.sorted() {
                check(s(p.left) + s(p.right)); check("a" + s(p.left) + s(p.right) + "e"); ligatures += 1
            }
        }
        print("BakedTextTests: \(pairs) kerning pairs, \(ligatures) ligatures compared")
        XCTAssertEqual(misses.count, 0, "\(misses.prefix(20))")
    }

    /// (6) Staleness: a fresh bake through `CoreTextRasterizer` equals the committed bytes, face by face (re-run
    /// `fz-bake-font Resources/Fonts` after any text-path change, Ruling 16(d)).
    func testCommittedFontsAreFreshBakes() throws {
        XCTAssertEqual(FZBaker.faces.map { [$0.font, $0.size, $0.face] }, Self.bakedFaces)
        let rasterizer = CoreTextRasterizer()
        for (font, size, face) in FZBaker.faces {
            let url = Self.fontsDirectory.appendingPathComponent(FZFont.fileName(font: font, size: size, face: face))
            let committed = try Data(contentsOf: url)
            let fresh = FZBaker.bake(font: font, size: size, face: face, using: rasterizer).font.encoded()
            XCTAssertTrue(fresh == committed, "\(url.lastPathComponent) is stale: re-run fz-bake-font")
        }
    }
    #endif

    // MARK: - 7 … 9: everywhere

    /// (7) The format: every committed file decodes and re-encodes to the same bytes with its face in its name; a
    /// synthetic face round-trips; damaged files are refused.
    func testFormatRoundTrip() throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: Self.fontsDirectory.path)
            .filter { $0.hasSuffix(".fzfont") }.sorted()
        XCTAssertEqual(names.count, Self.bakedFaces.count)
        for name in names {
            let data = try Data(contentsOf: Self.fontsDirectory.appendingPathComponent(name))
            let f = try FZFont(data: data)
            XCTAssertEqual(f.encoded(), data, name)
            XCTAssertEqual(FZFont.fileName(font: f.font, size: f.size, face: f.face), name)
            XCTAssertEqual(f.glyphs.count, 256, name)
            XCTAssertEqual(Array(data.prefix(4)), Array("FZF1".utf8))
        }
        let bitmap = FZFont.Bitmap(left: -1, top: -7, width: 2, height: 3, coverage: [0, 255, 128, 1, 2, 3])
        let glyph = FZFont.Glyph(advance: 5.9985, ascent: 9.5, descent: 2.25,
                                 phases: [.init(start: 0, bitmap: 0), .init(start: 0.333, bitmap: FZFont.blank)])
        let f = FZFont(font: 3, size: 9, face: 0, name: "Geneva", info: .init(ascent: 9, descent: 2, leading: 1),
                       ascent: 9.1, descent: 2.4, bitmaps: [bitmap], glyphs: [0x41: glyph, 0x20: glyph],
                       kerning: [FZFont.Pair(0x41, 0x20): -0.5], ligatures: [FZFont.Pair(0x66, 0x69): glyph])
        let data = f.encoded()
        XCTAssertEqual(try FZFont(data: data), f)
        XCTAssertEqual(glyph.bitmap(at: 0.3329), 0)
        XCTAssertEqual(glyph.bitmap(at: 0.333), FZFont.blank)
        XCTAssertThrowsError(try FZFont(data: Data("BTXF".utf8) + data.dropFirst(4))) {
            XCTAssertEqual($0 as? FZFont.FormatError, .badMagic)
        }
        XCTAssertThrowsError(try FZFont(data: data.dropLast())) {
            XCTAssertEqual($0 as? FZFont.FormatError, .truncated)
        }
        XCTAssertThrowsError(try FZFont(data: data + [0])) {
            XCTAssertEqual($0 as? FZFont.FormatError, .trailingBytes)
        }
        var v2 = data
        v2[4] = 2
        XCTAssertThrowsError(try FZFont(data: v2)) { XCTAssertEqual($0 as? FZFont.FormatError, .unsupportedVersion(2)) }
        let empty = FileManager.default.temporaryDirectory.appendingPathComponent("fzfont-empty-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: empty) }
        XCTAssertThrowsError(try BakedTextRasterizer(fontsDirectory: empty)) {
            XCTAssertEqual($0 as? BakedTextRasterizer.LoadError, .noFonts(empty.path))
        }
    }

    /// (8) A face that was not baked: an empty mask, width 0, fontInfo 0, and one log line however often it is asked.
    func testUnbakedFaceDrawsNothingAndLogsOnce() throws {
        var logs: [String] = []
        let baked = try BakedTextRasterizer(fontsDirectory: Self.fontsDirectory, log: { logs.append($0) })
        for _ in 0..<3 {
            let m = baked.rasterize("Ferazel", font: 4, size: 10, face: 0)
            XCTAssertTrue(Self.same(m, (0, 0, 0, 0, [])))
            XCTAssertEqual(baked.charWidth(0x46, font: 4, size: 10, face: 0), 0)
            XCTAssertTrue(baked.fontInfo(font: 4, size: 10, face: 0) == (0, 0, 0))
        }
        XCTAssertEqual(logs, ["BakedTextRasterizer: no baked face for font 4 size 10 face 0; its text draws nothing"])
        // A baked size in another face is not a stand-in.
        XCTAssertTrue(Self.same(baked.rasterize("1", font: 20, size: 12, face: 0), (0, 0, 0, 0, [])))
        XCTAssertEqual(logs.count, 2)
        // Baked faces draw and do not log; an empty string draws nothing.
        XCTAssertGreaterThan(baked.rasterize("1", font: 20, size: 12, face: 1).coverage.filter { $0 == 255 }.count, 0)
        XCTAssertTrue(Self.same(baked.rasterize("", font: 20, size: 12, face: 1), (0, 0, 0, 0, [])))
        XCTAssertEqual(logs.count, 2)
    }

    /// (9) The faces the game asks for, recorded through the shared driver (boot → main menu → New Game → level 1's
    /// first frame — the baked-text frames pinned here, WF3's reference), the status bar (score, coins, the level name
    /// and item counts in both Geneva faces) and the conversation layout and drawing (the sign route): exactly the four
    /// game faces, every one baked, nothing logged.
    func testFaceSetTheGameAsksForIsBaked() throws {
        var logs: [String] = []
        let baked = try BakedTextRasterizer(fontsDirectory: Self.fontsDirectory, log: { logs.append($0) })
        let recorder = RecordingRasterizer(baked)
        let (boot, menu, newGame, level) = try Self.driverFrames(recorder)
        XCTAssertEqual(boot, FerazelDriverTests.bootTicks)
        XCTAssertEqual(newGame, FerazelDriverTests.newGameTicks)
        XCTAssertEqual(hex(menu), hex(Self.bakedMainMenuFNV), "baked main menu FNV")
        XCTAssertEqual(hex(level), hex(Self.bakedLevelOneFNV), "baked level 1 first frame FNV")
        // The status bar with item counts > 1 (the selected slot's Geneva 9, every slot's Geneva bold 8).
        let (frame, _) = try Self.levelOne(recorder)
        var inventory = StatusBarState.newGameInventory
        inventory[0] = InventorySlot(id: 0, count: 7, field4: -1, field6: 0, isSpell: 1)
        inventory[1] = InventorySlot(id: 0, count: 42, field4: -1, field6: 0, isSpell: 0)
        try frame.apply(FrameOps(draws: [.statusBar(StatusBarState(score: 12345, coins: 99, levelName: "Ferazel",
                                                                   inventory: inventory))]))
        _ = try Self.signRoute(recorder)
        XCTAssertEqual(recorder.faces, Self.gameFaces)
        XCTAssertTrue(recorder.faces.isSubset(of: Set(baked.bakedFaces)))
        XCTAssertEqual(logs, [])
    }

    // MARK: - 10: end to end against CoreText (Mac)

    #if canImport(CoreText)
    /// (10) Whole frames, baked = CoreText (FNV of the 640×480 indices): the level-1 golden route (397 frames, chained)
    /// and the sign-frame route; and the driver's two baked-text frames are CoreText's.
    func testRoutesMatchCoreTextEndToEnd() throws {
        let baked = try Self.baked(), ct = CoreTextRasterizer()
        let (b, n) = try Self.goldenRoute(baked)
        let (c, m) = try Self.goldenRoute(ct)
        XCTAssertEqual([n, m], [397, 397])
        XCTAssertEqual(hex(b), hex(c), "level-1 golden route: baked ≠ CoreText")
        XCTAssertNotEqual(hex(b), hex(try Self.goldenRoute(StubGlyphRasterizer()).0), "the route draws text")
        XCTAssertEqual(hex(try Self.signRoute(baked)), hex(try Self.signRoute(ct)), "sign route: baked ≠ CoreText")
        let (_, menu, _, level) = try Self.driverFrames(ct)
        XCTAssertEqual(hex(menu), hex(Self.bakedMainMenuFNV), "main menu: CoreText ≠ baked pin")
        XCTAssertEqual(hex(level), hex(Self.bakedLevelOneFNV), "level 1 first frame: CoreText ≠ baked pin")
    }
    #endif
}
