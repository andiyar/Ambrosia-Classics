// swift-tools-version: 6.0
import PackageDescription

// Deimos Rising — core (data decoders now; game logic in Phase 1) on HectorKit.
// Plan: docs/plans/2026-10-06-deimos-phase0-data.md (Phase 0: data decoders + census; DECISIONS D24).
// DeimosCore is Foundation + HectorKit's Foundation-only products only (HectorKit D6).
// HectorKit is a LOCAL path dependency during build-out: from Deimos/Core, three levels up is the
// directory that holds both repos (in a worktree session: the .claude/worktrees/HectorKit symlink —
// docs/DECISIONS.md D1). `HECTORKIT_PATH` overrides it.
// Targets grow task by task (SwiftPM rejects a declared target with no sources).
let package = Package(
    name: "DeimosCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DeimosCore", targets: ["DeimosCore"]),
        .executable(name: "deimos-census", targets: ["deimos-census"]),
    ],
    dependencies: [
        .package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"),
    ],
    targets: [
        .target(name: "DeimosCore", dependencies: [
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        // The census tool (Task C7): Markdown on stdout = docs/deimos/data-census.md below its rule.
        // `--render` alone uses ImageIO (PNG writer, census-only; plan invariant 2).
        .executableTarget(name: "deimos-census", dependencies: [
            "DeimosCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        .testTarget(name: "DeimosCensusTests", dependencies: ["deimos-census", "DeimosCore"]),
        .testTarget(name: "DeimosCoreTests", dependencies: [
            "DeimosCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
    ]
)
