// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Comoni",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ComoniCore", targets: ["ComoniCore"]),
        .executable(name: "Comoni", targets: ["ComoniApp"])
    ],
    targets: [
        .target(name: "ComoniCore"),
        .executableTarget(
            name: "ComoniApp",
            dependencies: ["ComoniCore"]
        )
    ]
)
