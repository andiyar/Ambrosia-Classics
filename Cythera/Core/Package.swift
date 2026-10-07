// swift-tools-version: 6.0
import PackageDescription

// Cythera — core (data, segment file, world records, script decoder) and later the render layer on HectorKit.
// Plan: docs/plans/2026-10-06-cythera-phase0.md (Phase 0: data in git, decoders, census; DECISIONS D28).
// CytheraCore is Foundation + HectorResources only (HectorKit D6; plan invariant 1). CytheraRender (C5) adds
// CytheraCore, HectorGraphics and HectorAudio; the cythera-census executable lands with C11.
// HectorKit is a LOCAL path dependency during build-out: from Cythera/Core, three levels up is the
// directory that holds both repos (in a worktree session: the .claude/worktrees/HectorKit symlink —
// docs/DECISIONS.md D1). `HECTORKIT_PATH` overrides it.
// Targets grow task by task (SwiftPM rejects a declared target with no sources; plan Landmine (c)).
let package = Package(
    name: "CytheraCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "CytheraCore", targets: ["CytheraCore"]),
        .library(name: "CytheraRender", targets: ["CytheraRender"]),
    ],
    dependencies: [
        .package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"),
    ],
    targets: [
        .target(name: "CytheraCore", dependencies: [
            .product(name: "HectorResources", package: "HectorKit"),
        ]),
        // The render layer (C5): segment and PICT pixels as indexed buffers, the palette (plan S1, S3).
        .target(name: "CytheraRender", dependencies: [
            "CytheraCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        .testTarget(name: "CytheraCoreTests", dependencies: [
            "CytheraCore",
            .product(name: "HectorResources", package: "HectorKit"),
        ]),
        .testTarget(name: "CytheraRenderTests", dependencies: [
            "CytheraRender",
            "CytheraCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
    ]
)
