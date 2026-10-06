// swift-tools-version: 6.0
import PackageDescription
// Bubble Trouble X core: data loading + frame-exact simulation + FILM replay. HectorKit by local path
// (three levels up holds both repos; in a worktree, the .claude/worktrees/HectorKit symlink — DECISIONS D1).
let package = Package(
    name: "BubbleTroubleCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "BubbleTroubleCore", targets: ["BubbleTroubleCore"]),
        // Pixels and PCM (plan 2026-10-04-btx-playable Invariant 1): Foundation + the kit's decoder layer only.
        .library(name: "BubbleTroubleRender", targets: ["BubbleTroubleRender"]),
        .executable(name: "btx-replay", targets: ["btx-replay"]),
        .executable(name: "btx-census", targets: ["btx-census"]),
    ],
    dependencies: [.package(path: "../../../HectorKit")],
    targets: [
        .target(name: "BubbleTroubleCore",
                dependencies: [.product(name: "HectorResources", package: "HectorKit")]),
        .target(name: "BubbleTroubleRender", dependencies: [
            "BubbleTroubleCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        .testTarget(name: "BubbleTroubleRenderTests", dependencies: [
            "BubbleTroubleRender", "BubbleTroubleCore",
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        .executableTarget(name: "btx-replay", dependencies: ["BubbleTroubleCore"]),
        .testTarget(name: "BubbleTroubleCoreTests",
                    dependencies: ["BubbleTroubleCore", .product(name: "HectorResources", package: "HectorKit")]),
        // Data census through HectorKit's decoders (plan 2026-10-03-hectorkit-btx-decoders Task 7, ruling R3).
        .executableTarget(name: "btx-census", dependencies: [
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        .testTarget(name: "BTXCensusTests", dependencies: [
            "btx-census",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
    ]
)
