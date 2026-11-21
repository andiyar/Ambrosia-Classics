import AppKit
import CoreGraphics
import HectorShell

/// ◇ The hidden key log (`-keylog`, or `defaults write com.ambrosiaclassics.deimos keylog -bool YES`): a diagnostic
/// for Ben's first playtest, where one tap of left Option (a bomb) left the arrow keys dead until a click on the
/// window. It writes, to `~/Library/Logs/Deimos Rising/keys.log` (truncated at each launch), one plain-text line per
/// thing the app sees, each line written at once (a crash or force-quit loses nothing) and led by the seconds since
/// the log began:
/// - every key-down, key-up, modifier change and left mouse-down the APP receives, before routing (a local event
///   monitor that returns every event unchanged), with the window it is for;
/// - every such event that reaches the game view (`DeimosController`'s `ShellInputHandler` hooks);
/// - the windows becoming / resigning key and main, the app becoming / resigning active;
/// - a state line whenever the polled keyboard, focus or hardware key state differs from the last one written;
/// - each change of the display's suspension.
/// Nothing here changes what the game sees. With the switch off no `KeyLog` exists and nothing is installed.
@MainActor final class KeyLog: NSObject {
    private let shell: ShellWindowController
    private let handle: FileHandle
    private let start = ProcessInfo.processInfo.systemUptime
    private var monitor: Any?
    private var lastState: String?

    /// The log file: `~/Library/Logs/Deimos Rising/keys.log`.
    static var fileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Deimos Rising", isDirectory: true)
            .appendingPathComponent("keys.log")
    }

    /// Opens (truncating) the log and installs the monitor and observers; nil (logged) when the file cannot be made.
    init?(shell: ShellWindowController) {
        let url = Self.fileURL
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
        } catch {
            NSLog("Deimos Rising: key log folder cannot be made: %@", "\(error)")
            return nil
        }
        guard FileManager.default.createFile(atPath: url.path, contents: Data()),
              let handle = try? FileHandle(forWritingTo: url) else {
            NSLog("Deimos Rising: key log cannot be opened at %@", url.path)
            return nil
        }
        self.shell = shell
        self.handle = handle
        super.init()
        NSLog("Deimos Rising: key log on: %@", url.path)
        write("Deimos Rising key log \(ISO8601DateFormatter().string(from: Date())) | macOS "
              + "\(ProcessInfo.processInfo.operatingSystemVersionString) | listen access "
              + "\(CGPreflightListenEventAccess() ? "yes" : "no") | \(shell.isFullscreen ? "full screen" : "windowed")")
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged, .leftMouseDown]) {
            [weak self] event in
            MainActor.assumeIsolated { self?.appEvent(event) }
            return event
        }
        let center = NotificationCenter.default
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification,
                     NSWindow.didBecomeMainNotification, NSWindow.didResignMainNotification] {
            center.addObserver(self, selector: #selector(windowNotification(_:)), name: name, object: nil)
        }
        for name in [NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification] {
            center.addObserver(self, selector: #selector(appNotification(_:)), name: name, object: nil)
        }
    }

    // MARK: Hooks

    /// An event that reached the game view (`ShellInputHandler`): "view keyDown 123 …".
    func view(_ kind: String, _ event: NSEvent) {
        var line = "view \(kind)"
        if event.type == .keyDown || event.type == .keyUp || event.type == .flagsChanged {
            line += " \(event.keyCode)"
        }
        line += " flags \(Self.hex(event.modifierFlags.rawValue))"
        if event.type == .keyDown || event.type == .keyUp { line += " repeat \(Self.yesNo(event.isARepeat))" }
        write(line)
    }

    /// `updateSuspension` changed the display's suspension.
    func suspendedChanged(_ suspended: Bool) {
        write("suspended -> \(Self.yesNo(suspended))")
    }

    /// The key poll's state, written when it differs from the last state line.
    func pollState(_ state: ShellKeyState, suspended: Bool) {
        let window = shell.currentWindow
        let responder: String
        if let first = window.firstResponder {
            responder = first === shell.view ? "view" : String(describing: type(of: first))
        } else {
            responder = "nil"
        }
        let hardware = [(0x7B, "left"), (0x7C, "right"), (0x7D, "down"), (0x7E, "up"), (0x31, "space")]
            .map { "\($0.1) \(CGEventSource.keyState(.combinedSessionState, key: CGKeyCode($0.0)) ? "down" : "up")" }
            .joined(separator: ", ")
        let line = "state held \(state.held.sorted()) modifiers \(Self.hex(UInt(state.modifiers.rawValue)))"
            + " capsLock \(Self.yesNo(state.capsLock)) active \(Self.yesNo(NSApp.isActive))"
            + " keyWindow \(describe(NSApp.keyWindow)) currentIsKey \(Self.yesNo(window.isKeyWindow))"
            + " firstResponder \(responder) fullScreen \(Self.yesNo(shell.isFullscreen))"
            + " suspended \(Self.yesNo(suspended)) hardware [\(hardware)] pad \(shell.view.padFrame.held.sorted())"
        guard line != lastState else { return }
        lastState = line
        write(line)
    }

    // MARK: Sources

    private func appEvent(_ event: NSEvent) {
        var line: String
        switch event.type {
        case .keyDown: line = "app keyDown \(event.keyCode)"
        case .keyUp: line = "app keyUp \(event.keyCode)"
        case .flagsChanged: line = "app flagsChanged \(event.keyCode)"
        case .leftMouseDown: line = "app leftMouseDown"
        default: line = "app event \(event.type.rawValue)"
        }
        line += " flags \(Self.hex(event.modifierFlags.rawValue))"
        if event.type == .keyDown || event.type == .keyUp { line += " repeat \(Self.yesNo(event.isARepeat))" }
        line += " window \(describe(event.window))"
        write(line)
    }

    @objc private func windowNotification(_ notification: Notification) {
        write("notify \(notification.name.rawValue) \(describe(notification.object as? NSWindow))")
    }

    @objc private func appNotification(_ notification: Notification) {
        write("notify \(notification.name.rawValue)")
    }

    // MARK: Writing

    /// "shell" (the shell's current window), "other(Class "title")" or "nil".
    private func describe(_ window: NSWindow?) -> String {
        guard let window else { return "nil" }
        if window === shell.currentWindow { return "shell" }
        let note = window === shell.windowedWindow ? " shell's windowed window, not current" : ""
        return "other(\(String(describing: type(of: window))) \"\(window.title)\"\(note))"
    }

    private func write(_ text: String) {
        let seconds = ProcessInfo.processInfo.systemUptime - start
        let line = String(format: "%.3f ", seconds) + text + "\n"
        try? handle.write(contentsOf: Data(line.utf8))
    }

    private static func hex(_ value: UInt) -> String { "0x" + String(value, radix: 16) }
    private static func yesNo(_ value: Bool) -> String { value ? "yes" : "no" }
}
