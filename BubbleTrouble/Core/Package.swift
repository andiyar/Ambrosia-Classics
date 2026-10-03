// swift-tools-version: 6.0
import PackageDescription
// Bubble Trouble X core: data loading + frame-exact simulation + FILM replay. HectorKit by local path
// (three levels up holds both repos; in a worktree, the .claude/worktrees/HectorKit symlink — DECISIONS D1).
let package = Package(
    name: "BubbleTroubleCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "BubbleTroubleCore", targets: ["BubbleTroubleCore"]),
        .executable(name: "btx-replay", targets: ["btx-replay"]),
    ],
    dependencies: [.package(path: "../../../HectorKit")],
    targets: [
        .target(name: "BubbleTroubleCore",
                dependencies: [.product(name: "HectorResources", package: "HectorKit")]),
        .executableTarget(name: "btx-replay", dependencies: ["BubbleTroubleCore"]),
        .testTarget(name: "BubbleTroubleCoreTests",
                    dependencies: ["BubbleTroubleCore", .product(name: "HectorResources", package: "HectorKit")]),
    ]
)
