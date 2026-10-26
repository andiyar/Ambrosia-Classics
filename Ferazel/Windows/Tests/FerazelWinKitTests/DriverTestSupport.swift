import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// Fixed-width solid boxes (WF1): every character advances 6 px; a non-space character covers a solid 5-px-wide box
/// from the ascent to the baseline. The driver's frame FNVs pin the driver and Core, not the text (WF2 re-measures the
/// text frames with the baked glyphs).
struct StubGlyphRasterizer: TextRasterizer {
    static let advance = 6

    func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
        -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]) {
        let chars = Array(text.unicodeScalars)
        let (ascent, _, _) = fontInfo(font: font, size: size, face: face)
        let width = chars.count * Self.advance
        guard width > 0, ascent > 0 else { return (0, 0, 0, 0, []) }
        var coverage = [UInt8](repeating: 0, count: width * ascent)
        for (i, c) in chars.enumerated() where c != " " {
            for y in 0..<ascent {
                for x in 0..<(Self.advance - 1) { coverage[y * width + i * Self.advance + x] = 255 }
            }
        }
        return (0, -ascent, width, ascent, coverage)
    }

    func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int { Self.advance }

    func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int) {
        let s = max(Int(size), 1)
        return (s * 3 / 4, s / 4, 0)
    }
}

/// Every mixer call, recorded in order; `attach` keeps the Sound Tool.
@MainActor final class FakeMixer: FerazelMixer {
    var calls: [String] = []
    var tools: [SoundTool] = []

    func load(id: Int, samples: [Int16], channels: Int, sampleRate: Double) {
        calls.append("load \(id) ch\(channels) \(Int(sampleRate))")
    }
    func play(id: Int, on voice: Int, volume: Float, loops: Int) {
        calls.append("play \(id) v\(voice) vol\(Int(volume)) loops\(loops == Int.max ? "max" : String(loops))")
    }
    func stop(voice: Int) { calls.append("stop v\(voice)") }
    func stopAll() { calls.append("stopAll") }
    func setVolume(voice: Int, _ volume: Float) { calls.append("volume v\(voice) \(Int(volume))") }
    func attach(stream: SoundTool) {
        calls.append("attach")
        tools.append(stream)
    }
}

/// The prefs and saved games in memory: no prefs file (the defaults), nothing written outside the test.
final class MemoryFiles: FrontFiles {
    var stored: [Data] = []
    func loadPrefs() -> Data? { nil }
    func storePrefs(_ record: Data) throws { stored.append(record) }
    func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { throw SavedGameError.notASavedGame }
    func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
}

/// FNV-1a 64 over bytes.
func fnv1a64(_ bytes: [UInt8]) -> UInt64 {
    var h: UInt64 = 0xcbf2_9ce4_8422_2325
    for b in bytes {
        h ^= UInt64(b)
        h = h &* 0x0000_0100_0000_01b3
    }
    return h
}

func hex(_ v: UInt64) -> String { "0x" + String(v, radix: 16) }

/// The driver as a shell drives it, headless (no window, no audio device): one `tick` per game tick at a fixed clock,
/// a present → RGBA on the ticks that ask, the dialogs and file panels answered at once (OK / cancelled), then
/// `serviceLoad` — the Mac's `idleFired` order.
@MainActor final class Rig {
    /// The injected hooks' counters (a box: the closures are made before the rig exists).
    final class Counters {
        var mixerFactoryCalls = 0
        var beeps = 0
        var logs: [String] = []
    }

    nonisolated static let seed: Int32 = 0x1234_5678
    /// A fixed `GetDateTime` (seconds since 1904).
    nonisolated static let dateTime: UInt32 = 0xBA00_0000

    let driver: FerazelDriver
    let counters = Counters()
    let files = MemoryFiles()
    var t: UInt32 = 1000
    var ticks = 0
    var lastRGBA: [UInt8]?
    var lastOutput = FrontOutput()

    enum Mixer { case none, silent, fake(FakeMixer) }

    /// - Parameter mixer: what the factory returns (`.silent` = the headless frames mode's `FerazelSilentMixer`).
    init(mute: Bool = false, macGamma: Bool = false, mixer: Mixer = .silent, boot: Bool = true) throws {
        var settings = FerazelSettings()
        settings.mute = mute
        settings.macGamma = macGamma
        let counters = self.counters
        let made: FerazelMixer?
        switch mixer {
        case .none: made = nil
        case .silent: made = FerazelSilentMixer()
        case .fake(let m): made = m
        }
        driver = FerazelDriver(settings: settings, text: StubGlyphRasterizer(), files: files, seed: { Rig.seed },
                               keyCharacter: { _ in nil }, dateTime: { Rig.dateTime },
                               mixer: { counters.mixerFactoryCalls += 1; return made },
                               beeper: { counters.beeps += 1 }, log: { counters.logs.append($0) })
        if boot { try driver.boot(dataDirectory: FerazelData.dataDirectory()) }
    }

    var flow: GameFlow { driver.flow }

    @discardableResult
    func step(_ input: FrontInput = FrontInput()) throws -> FrontOutput {
        var input = input
        input.playing = driver.playingSounds()
        let out = try driver.tick(now: t, input: input)
        if out.present { lastRGBA = driver.presentRGBA() }
        for request in out.requests {
            switch request {
            case .dialog: flow.dialogDone(.ok)
            case .getFile, .putFile: flow.fileDone(.cancelled)
            default: break
            }
        }
        driver.serviceLoad()
        lastOutput = out
        t &+= 1
        ticks += 1
        return out
    }

    /// Ticks until `until` holds after a tick; fails after `max`.
    func drive(max: Int = 6000, input: (GameFlow) -> FrontInput = { _ in FrontInput() },
               until: (Rig) -> Bool) throws {
        for _ in 0..<max {
            try step(input(flow))
            if until(self) { return }
        }
        XCTFail("not reached in \(max) ticks (state \(flow.state))")
    }

    func toMainMenu() throws {
        try drive { $0.flow.state == .mainMenu }
    }
}
