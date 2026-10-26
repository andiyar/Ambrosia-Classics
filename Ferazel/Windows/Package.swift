// swift-tools-version: 6.0
import PackageDescription

// Ferazel's Wand for Windows (plan 2026-10-26-ferazel-windows, DECISIONS D43). `FerazelWinKit` is Foundation-only: the
// shared shell half (`Ferazel/Shared`, one git symlink per file — the Mac app compiles the same files, Ruling 1) plus,
// from WF2 on, the Windows-only logic; fully `swift test`-able on the Mac. The core package by local path; HectorKit at
// the same path identity Ferazel/Core uses (in a worktree it resolves through .claude/worktrees/HectorKit); HectorKit's
// SDL package beside it (only the executable uses it). WF2 adds the baked text and its Mac-only baker; WF3 the game's
// executable `FerazelWin` (thin SDL glue over `WinGame`, BTX `BubbleTroubleXWin` shape).
let hectorKit = Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"
let package = Package(
    name: "FerazelWindows",
    // macOS 26: HectorSDL's floor (brew's SDL3 dylib). This package is the Windows port, never the Mac app.
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "FerazelWinKit", targets: ["FerazelWinKit"]),
        // Mac-only: bakes the game's text faces into Resources/Fonts/*.fzfont through CoreTextRasterizer (WF2).
        .executable(name: "fz-bake-font", targets: ["fz-bake-font"]),
        // The game (WF3). Builds on the Mac too (brew sdl3) as the SDL development build; cross-built with
        // tools/windows/build.sh --sdl.
        .executable(name: "FerazelWin", targets: ["FerazelWin"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: hectorKit),
        // HectorSDL, a separate package beside HectorKit (no HectorKit change, Ruling 17).
        .package(path: hectorKit + "/SDL"),
    ],
    targets: [
        .target(name: "FerazelWinKit", dependencies: [
            .product(name: "FerazelCore", package: "Core"),
            .product(name: "FerazelRender", package: "Core"),
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
            .product(name: "HectorInput", package: "HectorKit"),
        ]),
        .executableTarget(name: "FerazelWin", dependencies: [
            "FerazelWinKit",
            .product(name: "HectorSDL", package: "SDL"),
            .product(name: "HectorAudio", package: "HectorKit"),
            .product(name: "HectorInput", package: "HectorKit"),
            .product(name: "FerazelCore", package: "Core"),
            .product(name: "FerazelRender", package: "Core"),
        ]),
        .executableTarget(name: "fz-bake-font", dependencies: [
            "FerazelWinKit",
            .product(name: "HectorResources", package: "HectorKit"),
        ]),
        .testTarget(name: "FerazelWinKitTests", dependencies: [
            "FerazelWinKit",
            // The staleness test bakes afresh (`@testable import fz_bake_font`); the baker is Mac-only.
            .target(name: "fz-bake-font", condition: .when(platforms: [.macOS])),
            .product(name: "FerazelCore", package: "Core"),
            .product(name: "FerazelRender", package: "Core"),
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
            .product(name: "HectorInput", package: "HectorKit"),
        ]),
    ]
)
