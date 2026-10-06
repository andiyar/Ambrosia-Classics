// Proof A of the Windows cross-compile (plan W0): each line exercises one piece of the runtime the game
// leans on. Every line is flushed as it is printed, so a crash mid-run still shows every step before it.
// (No setvbuf(_IOLBF, 0): the MSVC CRT rejects a zero buffer size with an invalid-parameter abort.)
//
//   hello                       all steps; UserDefaults last (it crashes under CrossOver — see README)
//   hello --skip-userdefaults   every step except UserDefaults
import Foundation
import Synchronization

func say(_ line: String) { print("hello: " + line); fflush(stdout) }

#if os(Windows)
let platform = "Windows"
#elseif os(macOS)
let platform = "macOS"
#else
let platform = "other"
#endif
let skipDefaults = CommandLine.arguments.contains("--skip-userdefaults")

say("platform \(platform)")
say("Date \(ISO8601DateFormatter().string(from: Date()))")
say("String(format:) \(String(format: "%05.2f|%04X|%@", 3.14159, 0xBEEF, "ok"))")

let dir = FileManager.default.temporaryDirectory
    .appendingPathComponent("hello-w0-\(ProcessInfo.processInfo.processIdentifier)")
try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
for name in ["b.txt", "a.txt"] {
    try Data(name.utf8).write(to: dir.appendingPathComponent(name))
}
let listing = try FileManager.default.contentsOfDirectory(atPath: dir.path).sorted()
say("FileManager listing \(listing)")
try FileManager.default.removeItem(at: dir)

let counter = Mutex(0)
for _ in 0..<1000 { counter.withLock { $0 += 1 } }
let count = counter.withLock { $0 }
say("Mutex \(count)")

var defaultsOK = true
if skipDefaults {
    say("UserDefaults skipped")
} else {
    say("UserDefaults …")
    let defaults = UserDefaults(suiteName: "hello-w0") ?? .standard
    defaults.set(42, forKey: "answer")
    let answer = defaults.integer(forKey: "answer")
    defaults.removeObject(forKey: "answer")
    defaultsOK = answer == 42
    say("UserDefaults round-trip \(answer)")
}

let ok = listing == ["a.txt", "b.txt"] && count == 1000 && defaultsOK
say(ok ? "OK" : "FAIL")
exit(ok ? 0 : 1)
