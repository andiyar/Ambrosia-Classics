// swift-tools-version: 6.0
import PackageDescription

// Deimos Rising — core (data decoders now; game logic in Phase 1) on HectorKit.
// Plan: docs/plans/2026-10-06-deimos-phase0-data.md (Phase 0: data decoders + census; DECISIONS D24).
// DeimosCore is Foundation + HectorKit's Foundation-only products only (HectorKit D6).
// HectorKit is a LOCAL path dependency during build-out: from Deimos/Core, three levels up is the
// directory that holds both repos (in a worktree session: the .claude/worktrees/HectorKit symlink —
// docs/DECISIONS.md D1). `HECTORKIT_PATH` overrides it.
// Targets grow task by task (SwiftPM rejects a declared target with no sources).
let package = Package(
    name: "DeimosCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DeimosCore", targets: ["DeimosCore"]),
        .library(name: "DeimosRender", targets: ["DeimosRender"]),
        .library(name: "DeimosHost", targets: ["DeimosHost"]),
        .library(name: "DeimosAudio", targets: ["DeimosAudio"]),
        .executable(name: "deimos-census", targets: ["deimos-census"]),
    ],
    dependencies: [
        .package(path: Context.environment["HECTORKIT_PATH"] ?? "../../../HectorKit"),
    ],
    targets: [
        .target(name: "DeimosCore", dependencies: [
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        // The renderer (Phase 1 R1–R3): RGB555 buffers, CopyBits, presents, fades, blitters. Foundation +
        // DeimosCore only (plan invariant 1) — executes Core's RenderOps on persistent buffers.
        .target(name: "DeimosRender", dependencies: ["DeimosCore"]),
        // The host driver (Phase 1 H1): the Mac-tick clock, the FPS limiter and fade waits as yields, Esc restart.
        // Foundation + DeimosCore + DeimosRender only (plan invariant 1) — no threads, no sleeping.
        .target(name: "DeimosHost", dependencies: ["DeimosCore", "DeimosRender"]),
        // The game's own audio (Phase 2 A1–A2): the 16-voice / 8-audible effects mixer over the continuous-IMA
        // sounds, and the music streamer, behind one pull source. Foundation + DeimosCore + HectorAudio only
        // (plan invariant 1; A2 adds Synchronization for the engine's Mutex — pulled on the audio thread).
        .target(name: "DeimosAudio", dependencies: [
            "DeimosCore",
            .product(name: "HectorAudio", package: "HectorKit"),
        ]),
        // The census tool (Task C7): Markdown on stdout = docs/deimos/data-census.md below its rule.
        // `--render` uses ImageIO (PNG writer, census-only; plan invariant 2). Section 9 (Task C8, the
        // app resource fork) decodes PICT/DITL with HectorGraphics, whose QuickTime-in-PICT path uses
        // ImageIO — so HectorGraphics is a dependency of the census and the tests ONLY, never of the
        // Foundation-only DeimosCore library (portability, HectorKit D6).
        .executableTarget(name: "deimos-census", dependencies: [
            "DeimosCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
        .testTarget(name: "DeimosCensusTests", dependencies: ["deimos-census", "DeimosCore"]),
        .testTarget(name: "DeimosCoreTests", dependencies: [
            "DeimosCore",
            .product(name: "HectorResources", package: "HectorKit"),
            .product(name: "HectorAudio", package: "HectorKit"),
            .product(name: "HectorGraphics", package: "HectorKit"),
        ]),
        .testTarget(name: "DeimosRenderTests", dependencies: ["DeimosRender", "DeimosCore"]),
        .testTarget(name: "DeimosHostTests", dependencies: ["DeimosHost", "DeimosRender", "DeimosCore"]),
        .testTarget(name: "DeimosAudioTests", dependencies: ["DeimosAudio", "DeimosCore"]),
    ]
)
