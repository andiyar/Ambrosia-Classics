// swift-tools-version: 6.0
import PackageDescription
// Bubble Trouble X for Windows (plan 2026-10-06-btx-windows, DECISIONS D15). `BTXWinKit` is Foundation-only (the
// controller port, the baked-font text rasterizer, the in-window chrome), fully `swift test`-able on the Mac. The core
// package by local path (in a worktree, its own HectorKit dependency resolves through .claude/worktrees/HectorKit).
let package = Package(
    name: "BubbleTroubleXWindows",
    // macOS 26: HectorSDL's floor (brew's SDL3 dylib). This package is the Windows port, never the Mac app.
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "BTXWinKit", targets: ["BTXWinKit"]),
        // Mac-only: bakes the system-font faces into Resources/Fonts/*.btxfont with CoreText (W2).
        .executable(name: "btx-bake-font", targets: ["btx-bake-font"]),
        // Mac-only: decodes the QuickTime-JPEG PICT bands once with ImageIO into Data/Decoded/*.rgba (W0.5, D16.1).
        .executable(name: "btx-predecode", targets: ["btx-predecode"]),
        // The game (W4): thin SDL glue over `WinGameDriver`. Builds on the Mac too (brew sdl3) for development.
        .executable(name: "BubbleTroubleXWin", targets: ["BubbleTroubleXWin"]),
    ],
    dependencies: [
        .package(path: "../../BubbleTrouble/Core"),
        // The same path identity as the core's own HectorKit dependency (../../../HectorKit from either package).
        .package(path: "../../../HectorKit"),
        // HectorSDL (W3), a separate package beside HectorKit; only the executable uses it.
        .package(path: "../../../HectorKit/SDL"),
    ],
    targets: [
        .target(name: "BTXWinKit", dependencies: [
            .product(name: "BubbleTroubleCore", package: "Core"),
            .product(name: "BubbleTroubleRender", package: "Core"),
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        .executableTarget(name: "BubbleTroubleXWin", dependencies: [
            "BTXWinKit",
            .product(name: "HectorSDL", package: "SDL"),
            .product(name: "HectorAudio", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "BubbleTroubleCore", package: "Core"),
        ]),
        .executableTarget(name: "btx-bake-font", dependencies: ["BTXWinKit"]),
        .executableTarget(name: "btx-predecode", dependencies: ["BTXWinKit"]),
        .testTarget(name: "BTXWinKitTests", dependencies: [
            "BTXWinKit",
            .product(name: "BubbleTroubleCore", package: "Core"),
            .product(name: "BubbleTroubleRender", package: "Core"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
    ]
)
