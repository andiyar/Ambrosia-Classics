// swift-tools-version: 6.0
import PackageDescription

// Ferazel's Wand — core (data, world parsers, tables; later the render layer) on HectorKit.
// Plan: docs/plans/2026-10-06-ferazel-phase1.md (Phase 1: level 1 look-and-feel; DECISIONS D26).
// FerazelCore is Foundation + HectorResources only (HectorKit D6; plan invariant 1).
// HectorKit is a LOCAL path dependency during build-out: from Ferazel/Core, three levels up is the
// directory that holds both repos (in a worktree session: the .claude/worktrees/HectorKit symlink —
// docs/DECISIONS.md D1). `HECTORKIT_PATH` overrides it.
// Targets grow task by task (SwiftPM rejects a declared target with no sources): FerazelRender and
// ferazel-census land with their first sources.
let package = Package(
    name: "FerazelCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "FerazelCore", targets: ["FerazelCore"]),
    ],
    dependencies: [
        .package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"),
    ],
    targets: [
        .target(name: "FerazelCore", dependencies: [
            .product(name: "HectorResources", package: "HectorKit"),
        ]),
        .testTarget(name: "FerazelCoreTests", dependencies: [
            "FerazelCore",
            .product(name: "HectorResources", package: "HectorKit"),
        ]),
    ]
)
