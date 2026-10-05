// swift-tools-version:6.0
// Proof A of the Windows cross-compile (plan W0): Foundation + Synchronization smoke test.
import PackageDescription

let package = Package(
    name: "hello",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "hello")
    ]
)
