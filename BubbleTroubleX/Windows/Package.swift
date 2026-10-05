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
    ],
    dependencies: [.package(path: "../../BubbleTrouble/Core")],
    targets: [
        .target(name: "BTXWinKit", dependencies: [
            .product(name: "BubbleTroubleCore", package: "Core"),
            .product(name: "BubbleTroubleRender", package: "Core"),
        ]),
        .executableTarget(name: "btx-bake-font", dependencies: ["BTXWinKit"]),
        .testTarget(name: "BTXWinKitTests", dependencies: [
            "BTXWinKit",
            .product(name: "BubbleTroubleCore", package: "Core"),
            .product(name: "BubbleTroubleRender", package: "Core"),
        ]),
    ]
)
