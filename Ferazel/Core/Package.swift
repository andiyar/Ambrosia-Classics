// swift-tools-version: 6.0
import PackageDescription

// Ferazel's Wand — core (data, world parsers, tables) and the render layer (decoders, later the renderer) on HectorKit.
// Plan: docs/plans/2026-10-06-ferazel-phase1.md (Phase 1: level 1 look-and-feel; DECISIONS D26).
// FerazelCore is Foundation + HectorResources only; FerazelRender adds FerazelCore, HectorGraphics and
// HectorAudio, still no Apple framework but Foundation (HectorKit D6; plan invariant 1).
// HectorKit is a LOCAL path dependency during build-out: from Ferazel/Core, three levels up is the
// directory that holds both repos (in a worktree session: the .claude/worktrees/HectorKit symlink —
// docs/DECISIONS.md D1). `HECTORKIT_PATH` overrides it.
// Targets grow task by task (SwiftPM rejects a declared target with no sources): ferazel-census (C6) is a thin
// main over FerazelRender.FerazelCensus; its folder alone may import ImageIO, for `--render` (plan invariant 1).
let package = Package(
    name: "FerazelCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "FerazelCore", targets: ["FerazelCore"]),
        .library(name: "FerazelRender", targets: ["FerazelRender"]),
        .executable(name: "ferazel-census", targets: ["ferazel-census"]),
    ],
    dependencies: [
        .package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"),
    ],
    targets: [
        .target(name: "FerazelCore", dependencies: [
            .product(name: "HectorResources", package: "HectorKit"),
        ]),
        .target(name: "FerazelRender", dependencies: [
            "FerazelCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        // The census tool (C6): stdout = docs/ferazel/data-census.md below its rule.
        .executableTarget(name: "ferazel-census", dependencies: ["FerazelRender", "FerazelCore"]),
        .testTarget(name: "FerazelCoreTests", dependencies: [
            "FerazelCore",
            .product(name: "HectorResources", package: "HectorKit"),
        ]),
        // Depends on the executable so `swift test` builds it (CensusTests.testExitCodes runs the binary).
        .testTarget(name: "FerazelRenderTests", dependencies: [
            "ferazel-census",
            "FerazelRender",
            "FerazelCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
    ]
)
