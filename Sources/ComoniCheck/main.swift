import Foundation

@main
struct ComoniCheck {
    static func main() {
        do {
            let response = try CodexAppServerClient.resolved().readRateLimits()
            let usage = UsageDisplaySnapshot(response: response)
            let output: [String: Any] = [
                "localeIdentifier": jsonValue(ChatGPTLanguageDetector.detect()),
                "planType": jsonValue(usage.planType),
                "remainingPercent": usage.windows.map { jsonValue($0.remainingPercent) },
                "resetCreditsAvailable": jsonValue(usage.resetCreditsAvailable),
                "resetCreditExpiresAt": jsonValue(usage.resetCreditExpiresAt?.timeIntervalSince1970)
            ]
            let data = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys])
            print(String(decoding: data, as: UTF8.self))
        } catch {
            fputs("Codex Usage Monitor: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func jsonValue<T>(_ value: T?) -> Any {
        value.map { $0 as Any } ?? NSNull()
    }
}
