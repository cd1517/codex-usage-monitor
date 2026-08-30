import Foundation

func runAppServerProtocolTests() throws {
    var session = AppServerProtocolSession()
    let initial = try session.initialRequest()
    let initialObject = try jsonObject(initial)
    try expect(initialObject["id"] as? Int == 1, "initialize request id should be 1")
    try expect(initialObject["method"] as? String == "initialize", "first request should initialize")

    let afterInitialize = try session.receive(line: Data(#"{"id":1,"result":{"userAgent":"test","codexHome":"/tmp/codex","platformFamily":"unix","platformOs":"macos"}}"#.utf8))
    guard case let .send(messages) = afterInitialize else {
        throw TestFailure(description: "initialize response should produce follow-up messages")
    }
    try expect(messages.count == 2, "initialize response should send initialized and rate-limit messages")
    let initializedObject = try jsonObject(messages[0])
    let rateLimitObject = try jsonObject(messages[1])
    try expect(initializedObject["method"] as? String == "initialized", "initialized notification should be sent")
    try expect(rateLimitObject["method"] as? String == "account/rateLimits/read", "only the read-only rate-limit method should be requested")

    let notification = try session.receive(line: Data(#"{"method":"remoteControl/status/changed","params":{"status":"disabled"}}"#.utf8))
    try expect(notification == .none, "unrelated notifications should be ignored")

    let rateLine = Data(#"{"id":2,"result":{"rateLimits":{"planType":"plus","primary":{"usedPercent":12,"windowDurationMins":300,"resetsAt":1788117494},"secondary":{"usedPercent":34,"windowDurationMins":10080,"resetsAt":1788645762},"credits":{"hasCredits":false,"unlimited":false,"balance":"0"}},"rateLimitResetCredits":{"availableCount":1}}}"#.utf8)
    let completed = try session.receive(line: rateLine)
    guard case let .complete(response) = completed else {
        throw TestFailure(description: "matching rate-limit response should complete the session")
    }
    try expect(response.rateLimits.primary?.usedPercent == 12, "primary usage should decode")
    try expect(response.rateLimitResetCredits?.availableCount == 1, "reset credit summary should decode")

    var failingSession = AppServerProtocolSession()
    _ = try failingSession.initialRequest()
    _ = try failingSession.receive(line: Data(#"{"id":1,"result":{}}"#.utf8))
    do {
        _ = try failingSession.receive(line: Data(#"{"id":2,"error":{"code":-32000,"message":"token=super-secret"}}"#.utf8))
        throw TestFailure(description: "server error should throw")
    } catch let error as AppServerProtocolError {
        try expect(!error.localizedDescription.contains("super-secret"), "server error must redact backend details")
        try expect(!error.localizedDescription.contains("token"), "server error must not expose backend fields")
    }
}

func runExecutableResolverTests() throws {
    let bundled = "/Applications/ChatGPT.app/Contents/Resources/codex"
    let resolved = CodexExecutableResolver.resolve(
        pathEnvironment: "/opt/homebrew/bin:/usr/local/bin",
        isExecutable: { [bundled, "/opt/homebrew/bin/codex"].contains($0) }
    )
    try expect(resolved?.path == bundled, "bundled ChatGPT executable should win over PATH")

    let fallback = CodexExecutableResolver.resolve(
        pathEnvironment: "/custom/bin:/usr/bin",
        isExecutable: { $0 == "/custom/bin/codex" }
    )
    try expect(fallback?.path == "/custom/bin/codex", "PATH should be used when the bundled binary is unavailable")
}

private func jsonObject(_ data: Data) throws -> [String: Any] {
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw TestFailure(description: "expected a JSON object")
    }
    return object
}
