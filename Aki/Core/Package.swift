// swift-tools-version: 6.0
import PackageDescription

// Aki — Mahjong Solitaire core (game logic + data loading) on HectorKit. Phase 0 holds only the
// shipped-bundle locator and the data-census tool; game logic arrives in Phase 2.
// HectorKit is a LOCAL path dependency during build-out (design §3): from Aki/Core, three levels
// up is the directory that holds both repos (in a worktree session: the .claude/worktrees/HectorKit
// symlink — docs/DECISIONS.md D1).
let package = Package(
    name: "AkiCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AkiCore", targets: ["AkiCore"]),
    ],
    dependencies: [
        .package(path: "../../../HectorKit"),
    ],
    targets: [
        .target(name: "AkiCore"),
        .testTarget(name: "AkiCoreTests", dependencies: [
            "AkiCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
    ]
)
