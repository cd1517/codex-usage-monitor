import Foundation

public enum AppServerProtocolEvent: Equatable, Sendable {
    case none
    case send([Data])
    case complete(AppServerRateLimitsResponse)
}

public enum AppServerProtocolError: LocalizedError, Equatable, Sendable {
    case invalidState
    case invalidResponse
    case serverRejected

    public var errorDescription: String? {
        switch self {
        case .invalidState:
            return "Codex 用量会话状态异常"
        case .invalidResponse:
            return "Codex 返回了无法识别的用量数据"
        case .serverRejected:
            return "Codex 暂时无法读取用量"
        }
    }
}

public struct AppServerProtocolSession: Sendable {
    private enum Stage: Sendable {
        case ready
        case awaitingInitialize
        case awaitingRateLimits
        case complete
    }

    private var stage: Stage = .ready

    public init() {}

    public mutating func initialRequest() throws -> Data {
        guard stage == .ready else {
            throw AppServerProtocolError.invalidState
        }
        stage = .awaitingInitialize
        return try Self.encode([
            "id": 1,
            "method": "initialize",
            "params": [
                "clientInfo": [
                    "name": "codex-usage-monitor",
                    "title": "Codex Usage Monitor",
                    "version": "1.0.0"
                ],
                "capabilities": [
                    "optOutNotificationMethods": []
                ]
            ]
        ])
    }

    public mutating func receive(line: Data) throws -> AppServerProtocolEvent {
        guard let object = try JSONSerialization.jsonObject(with: line) as? [String: Any] else {
            throw AppServerProtocolError.invalidResponse
        }

        guard let id = object["id"] as? Int else {
            return .none
        }
        if object["error"] != nil {
            throw AppServerProtocolError.serverRejected
        }

        switch (stage, id) {
        case (.awaitingInitialize, 1):
            guard object["result"] != nil else {
                throw AppServerProtocolError.invalidResponse
            }
            stage = .awaitingRateLimits
            return .send([
                try Self.encode(["method": "initialized"]),
                try Self.encode([
                    "id": 2,
                    "method": "account/rateLimits/read"
                ])
            ])

        case (.awaitingRateLimits, 2):
            let envelope = try JSONDecoder().decode(RateLimitsEnvelope.self, from: line)
            stage = .complete
            return .complete(envelope.result)

        default:
            return .none
        }
    }

    private static func encode(_ object: [String: Any]) throws -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        } catch {
            throw AppServerProtocolError.invalidState
        }
    }
}

private struct RateLimitsEnvelope: Decodable {
    let result: AppServerRateLimitsResponse
}
