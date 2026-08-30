// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodexUsageMonitor",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CodexUsageMonitorCore", targets: ["CodexUsageMonitorCore"]),
        .executable(name: "CodexUsageMonitor", targets: ["CodexUsageMonitorApp"])
    ],
    targets: [
        .target(name: "CodexUsageMonitorCore"),
        .executableTarget(
            name: "CodexUsageMonitorApp",
            dependencies: ["CodexUsageMonitorCore"]
        )
    ]
)
