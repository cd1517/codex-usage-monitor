import Foundation

func runUsageSnapshotTests() throws {
    let response = AppServerRateLimitsResponse(
        rateLimits: RateLimitSnapshot(
            planType: "plus",
            primary: RateLimitWindow(usedPercent: 3, windowDurationMins: 300, resetsAt: 1_788_117_494),
            secondary: RateLimitWindow(usedPercent: 37, windowDurationMins: 10_080, resetsAt: 1_788_645_762),
            credits: CreditsSnapshot(hasCredits: false, unlimited: false, balance: "0")
        ),
        rateLimitResetCredits: RateLimitResetCredits(
            availableCount: 1,
            credits: [RateLimitResetCredit(expiresAt: 1_789_000_000)]
        )
    )
    let usage = UsageDisplaySnapshot(response: response)

    try expect(usage.planType == "plus", "plan type should be preserved")
    try expect(usage.windows.map(\.label) == ["5 小时", "7 天"], "window labels should be stable")
    try expect(usage.windows.map(\.remainingPercent) == [97, 63], "remaining percentage should be 100 minus used")
    try expect(usage.windows[0].resetsAt == Date(timeIntervalSince1970: 1_788_117_494), "reset epoch should convert to Date")
    try expect(usage.credits?.balance == "0", "credit balance should be preserved")
    try expect(usage.resetCreditsAvailable == 1, "reset credit count should be preserved")
    try expect(usage.resetCreditExpiresAt == Date(timeIntervalSince1970: 1_789_000_000), "earliest reset credit expiry should be exposed")

    let invalid = AppServerRateLimitsResponse(
        rateLimits: RateLimitSnapshot(
            planType: nil,
            primary: RateLimitWindow(usedPercent: -5, windowDurationMins: nil, resetsAt: nil),
            secondary: RateLimitWindow(usedPercent: 115, windowDurationMins: nil, resetsAt: nil),
            credits: nil
        ),
        rateLimitResetCredits: nil
    )
    try expect(UsageDisplaySnapshot(response: invalid).windows.map(\.remainingPercent) == [100, 0], "percentages should clamp to 0...100")

    let unavailable = AppServerRateLimitsResponse(
        rateLimits: RateLimitSnapshot(planType: nil, primary: nil, secondary: nil, credits: nil),
        rateLimitResetCredits: nil
    )
    let unavailableUsage = UsageDisplaySnapshot(response: unavailable)
    try expect(unavailableUsage.windows.map(\.remainingPercent) == [nil, nil], "missing windows must remain unavailable")
    try expect(unavailableUsage.windows.map(\.resetsAt) == [nil, nil], "missing reset times must remain unavailable")
    try expect(unavailableUsage.resetCreditsAvailable == nil, "missing reset credits must remain unavailable")

    try expect(!isLowRemainingUsage(nil), "missing usage must not be shown as low")
    try expect(isLowRemainingUsage(0), "zero remaining usage should be low")
    try expect(isLowRemainingUsage(10), "ten percent remaining usage should be low")
    try expect(!isLowRemainingUsage(11), "eleven percent remaining usage should not be low")
}
