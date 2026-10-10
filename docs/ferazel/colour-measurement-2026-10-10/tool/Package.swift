// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "fzcolour",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "../../../../Ferazel/Core")],
    targets: [.executableTarget(name: "fzcolour", dependencies: [
        .product(name: "FerazelCore", package: "Core"), .product(name: "FerazelRender", package: "Core")])]
)
