import Foundation

@main
struct TestMain {
    static func main() {
        let suites: [(String, () throws -> Void)] = [
            ("UsageSnapshotTests", runUsageSnapshotTests),
            ("OverlayMetricsTests", runOverlayMetricsTests),
            ("WindowGeometryTests", runWindowGeometryTests),
            ("UsageLocalizationTests", runUsageLocalizationTests),
            ("AppServerProtocolTests", runAppServerProtocolTests),
            ("ExecutableResolverTests", runExecutableResolverTests)
        ]
        let filter = CommandLine.arguments.dropFirst().first
        var failed = false

        for (name, run) in suites where filter == nil || name.localizedCaseInsensitiveContains(filter!) {
            do {
                try run()
                print("PASS \(name)")
            } catch {
                failed = true
                print("FAIL \(name): \(error)")
            }
        }

        if failed {
            exit(1)
        }
    }
}
