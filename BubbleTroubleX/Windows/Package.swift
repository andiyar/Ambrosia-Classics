// swift-tools-version: 6.0
import PackageDescription
// Bubble Trouble X for Windows (plan 2026-10-06-btx-windows, DECISIONS D15). `BTXWinKit` is Foundation-only (the
// controller port, the baked-font text rasterizer, the in-window chrome), fully `swift test`-able on the Mac. The core
// package by local path (in a worktree, its own HectorKit dependency resolves through .claude/worktrees/HectorKit).
let package = Package(
    name: "BubbleTroubleXWindows",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "BTXWinKit", targets: ["BTXWinKit"]),
        // Mac-only: bakes the system-font faces into Resources/Fonts/*.btxfont with CoreText (W2).
        .executable(name: "btx-bake-font", targets: ["btx-bake-font"]),
        // Mac-only: decodes the QuickTime-JPEG PICT bands once with ImageIO into Data/Decoded/*.rgba (W0.5, D16.1).
        .executable(name: "btx-predecode", targets: ["btx-predecode"]),
    ],
    dependencies: [
        .package(path: "../../BubbleTrouble/Core"),
        // The same path identity as the core's own HectorKit dependency (../../../HectorKit from either package).
        .package(path: "../../../HectorKit"),
    ],
    targets: [
        .target(name: "BTXWinKit", dependencies: [
            .product(name: "BubbleTroubleCore", package: "Core"),
            .product(name: "BubbleTroubleRender", package: "Core"),
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
        .executableTarget(name: "btx-bake-font", dependencies: ["BTXWinKit"]),
        .executableTarget(name: "btx-predecode", dependencies: ["BTXWinKit"]),
        .testTarget(name: "BTXWinKitTests", dependencies: [
            "BTXWinKit",
            .product(name: "BubbleTroubleCore", package: "Core"),
            .product(name: "BubbleTroubleRender", package: "Core"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
    ]
)
