import BTXWinKit
import BubbleTroubleCore
import Foundation
import XCTest

/// A `WinHost` for headless driver tests: the fixed-step clock and scripted input of `WinScriptedInput`, plus
/// events injected by the test, and a record of every platform call.
final class ScriptedHost: WinHost {
    var input: WinScriptedInput
    var injected: [WinEvent] = []
    private(set) var lastFrame: WinFrame?
    private(set) var presents = 0
    private(set) var cursorVisible = true
    private(set) var cursors: [WinCursor] = []
    private(set) var captured = false
    private(set) var restores = 0
    private(set) var beeps = 0
    private(set) var quitCalled = false

    init(script: WinKeyScript = WinKeyScript()) {
        input = WinScriptedInput(script: script)
    }

    var nanoseconds: UInt64 { input.nanoseconds }
    var modifiers: WinModifiers { input.modifiers }
    /// The iteration being run.
    var frame: Int { input.frame }

    func pollEvents() -> [WinEvent] {
        let events = injected + input.events()
        injected = []
        return events
    }

    func present(_ frame: WinFrame) {
        lastFrame = frame
        presents += 1
    }

    func setCursorVisible(_ visible: Bool) { cursorVisible = visible }
    func setCursor(_ cursor: WinCursor) { cursors.append(cursor) }
    func setMouseCaptured(_ captured: Bool) { self.captured = captured }
    func restoreMousePosition() { restores += 1 }
    func beep() { beeps += 1 }
    func quit() { quitCalled = true }
}

/// Records every output call, with a settable "playing" state per voice.
final class RecordingAudioOutput: WinAudioOutput {
    enum Call: Equatable {
        case load(id: Int, count: Int, channels: Int, rate: Double)
        case play(id: Int, voice: Int, volume: Float, loops: Int)
        case stop(Int), pause(Int), resume(Int)
        case setVolume(Int, Float)
    }
    var calls: [Call] = []
    var playing: Set<Int> = []
    /// When true, `play` marks the voice playing (a sound that lasts).
    var playsLast = true

    func load(id: Int, samples: [Int16], channels: Int, sampleRate: Double) {
        calls.append(.load(id: id, count: samples.count, channels: channels, rate: sampleRate))
    }
    func play(id: Int, on voice: Int, volume: Float, loops: Int) {
        calls.append(.play(id: id, voice: voice, volume: volume, loops: loops))
        if playsLast { playing.insert(voice) }
    }
    func stop(voice: Int) { calls.append(.stop(voice)); playing.remove(voice) }
    func pause(voice: Int) { calls.append(.pause(voice)) }
    func resume(voice: Int) { calls.append(.resume(voice)) }
    func setVolume(voice: Int, _ volume: Float) { calls.append(.setVolume(voice, volume)) }
    func isPlaying(voice: Int) -> Bool { playing.contains(voice) }

    /// The calls after the initial effect loads.
    var nonLoadCalls: [Call] { calls.filter { if case .load = $0 { false } else { true } } }
}

enum WinTestData {
    static let variable = "HECTORKIT_DATA_BTX"

    /// The BTX `Contents/Resources` folder (HECTORKIT_DATA_BTX), or XCTSkip naming the variable.
    static func resources() throws -> URL {
        guard let value = ProcessInfo.processInfo.environment[variable], !value.isEmpty else {
            throw XCTSkip("\(variable) unset — set it to Bubble Trouble X.app/Contents/Resources")
        }
        return URL(fileURLWithPath: value).resolvingSymlinksInPath()
    }

    /// The committed baked fonts (BubbleTroubleX/Windows/Resources/Fonts).
    static var fonts: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Resources/Fonts", isDirectory: true)
    }

    nonisolated(unsafe) private static var cached: WinGameAssets?

    /// Loaded once per test process (the prewarm is the slow part).
    static func assets() throws -> WinGameAssets {
        if let cached { return cached }
        let a = try WinGameAssets(dataDirectory: resources(), fontsDirectory: fonts)
        cached = a
        return a
    }

    /// A started driver over a scripted host; fixed date and name, so runs are reproducible.
    static func driver(script: WinKeyScript = WinKeyScript(), backing: any BTXPrefsBacking = WinMemoryPrefs(),
                       output: any WinAudioOutput = SilentWinAudioOutput(),
                       dialogs: any WinDialogs = WinDialogsStub()) throws -> (WinGameDriver, ScriptedHost) {
        let host = ScriptedHost(script: script)
        let driver = try WinGameDriver(assets: assets(), host: host, audioOutput: output, prefsBacking: backing,
                                       dialogs: dialogs,
                                       options: .init(registeredName: "Player", today: { (3, 3) }))
        driver.start()
        return (driver, host)
    }

    /// Runs iterations until `until` holds (checked before each) or `limit` iterations ran; returns whether it held.
    @discardableResult
    static func run(_ driver: WinGameDriver, _ host: ScriptedHost, limit: Int,
                    until: () -> Bool = { false }) -> Bool {
        for _ in 0..<limit {
            if until() { return true }
            if driver.finished { return until() }
            driver.step()
            host.input.advance()
        }
        return until()
    }
}
