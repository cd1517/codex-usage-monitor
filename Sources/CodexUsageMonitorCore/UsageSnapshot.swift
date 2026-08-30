import Foundation

public struct RateLimitWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double?
    public let windowDurationMins: Int?
    public let resetsAt: TimeInterval?

    public init(usedPercent: Double?, windowDurationMins: Int?, resetsAt: TimeInterval?) {
        self.usedPercent = usedPercent
        self.windowDurationMins = windowDurationMins
        self.resetsAt = resetsAt
    }
}

public struct CreditsSnapshot: Codable, Equatable, Sendable {
    public let hasCredits: Bool
    public let unlimited: Bool
    public let balance: String?

    public init(hasCredits: Bool, unlimited: Bool, balance: String?) {
        self.hasCredits = hasCredits
        self.unlimited = unlimited
        self.balance = balance
    }
}

public struct RateLimitSnapshot: Codable, Equatable, Sendable {
    public let planType: String?
    public let primary: RateLimitWindow?
    public let secondary: RateLimitWindow?
    public let credits: CreditsSnapshot?

    public init(
        planType: String?,
        primary: RateLimitWindow?,
        secondary: RateLimitWindow?,
        credits: CreditsSnapshot?
    ) {
        self.planType = planType
        self.primary = primary
        self.secondary = secondary
        self.credits = credits
    }
}

public struct RateLimitResetCredit: Codable, Equatable, Sendable {
    public let expiresAt: TimeInterval?

    public init(expiresAt: TimeInterval?) {
        self.expiresAt = expiresAt
    }
}

public struct RateLimitResetCredits: Codable, Equatable, Sendable {
    public let availableCount: Int
    public let credits: [RateLimitResetCredit]?

    public init(availableCount: Int, credits: [RateLimitResetCredit]? = nil) {
        self.availableCount = availableCount
        self.credits = credits
    }
}

public struct AppServerRateLimitsResponse: Codable, Equatable, Sendable {
    public let rateLimits: RateLimitSnapshot
    public let rateLimitResetCredits: RateLimitResetCredits?

    public init(rateLimits: RateLimitSnapshot, rateLimitResetCredits: RateLimitResetCredits?) {
        self.rateLimits = rateLimits
        self.rateLimitResetCredits = rateLimitResetCredits
    }
}

public struct UsageWindow: Equatable, Sendable {
    public let label: String
    public let remainingPercent: Int?
    public let resetsAt: Date?
}

public struct UsageDisplaySnapshot: Equatable, Sendable {
    public let planType: String?
    public let windows: [UsageWindow]
    public let credits: CreditsSnapshot?
    public let resetCreditsAvailable: Int?
    public let resetCreditExpiresAt: Date?

    public init(response: AppServerRateLimitsResponse) {
        planType = response.rateLimits.planType
        windows = [
            Self.makeWindow(label: "5 小时", source: response.rateLimits.primary),
            Self.makeWindow(label: "7 天", source: response.rateLimits.secondary)
        ]
        credits = response.rateLimits.credits
        resetCreditsAvailable = response.rateLimitResetCredits?.availableCount
        resetCreditExpiresAt = response.rateLimitResetCredits?.credits?
            .compactMap(\.expiresAt)
            .min()
            .map(Date.init(timeIntervalSince1970:))
    }

    private static func makeWindow(label: String, source: RateLimitWindow?) -> UsageWindow {
        let remaining = source?.usedPercent.map { used in
            Int((100 - min(max(used, 0), 100)).rounded())
        }
        let resetDate = source?.resetsAt.map(Date.init(timeIntervalSince1970:))
        return UsageWindow(label: label, remainingPercent: remaining, resetsAt: resetDate)
    }
}
