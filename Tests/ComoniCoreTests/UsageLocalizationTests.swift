import Foundation

func runUsageLocalizationTests() throws {
    let rendererArguments = [
        ["/Applications/ChatGPT.app/Contents/MacOS/ChatGPT"],
        ["Codex (Renderer)", "--type=renderer", "--lang=zh-CN", "--renderer-client-id=6"]
    ]
    try expect(
        chatGPTLocaleIdentifier(from: rendererArguments) == "zh-CN",
        "the ChatGPT renderer --lang value should be used as the UI locale"
    )
    try expect(
        chatGPTLocaleIdentifier(from: [["Codex (Renderer)", "--type=renderer"]]) == nil,
        "missing ChatGPT language data must not be invented"
    )

    let encodedArguments = makeProcessArgumentData([
        "/Applications/ChatGPT.app/Contents/Frameworks/Codex (Renderer)",
        "--type=renderer",
        "--lang=en-US"
    ])
    try expect(
        parseProcessArguments(encodedArguments).suffix(2) == ["--type=renderer", "--lang=en-US"],
        "KERN_PROCARGS2 data should expose the renderer language argument"
    )

    let simplifiedChinese = UsageLocalization(localeIdentifier: "zh-CN")
    try expect(simplifiedChinese.compactPrimaryLabel == "5小时", "Simplified Chinese should localize the compact label")
    try expect(simplifiedChinese.primaryResetLabel == "5 小时重置", "Simplified Chinese should localize detail labels")
    try expect(simplifiedChinese.resetCreditsLabel == "限额重置", "Simplified Chinese should rename the reset credits label")
    try expect(simplifiedChinese.resetCreditCount(1) == "可用 1 次", "Chinese reset credits should read 可用 N 次")

    let traditionalChinese = UsageLocalization(localeIdentifier: "zh-TW")
    try expect(traditionalChinese.compactSecondaryLabel == "1週", "Traditional Chinese should follow the ChatGPT locale")
    try expect(traditionalChinese.resetCreditsLabel == "限額重置", "Traditional Chinese should use traditional characters")
    try expect(traditionalChinese.resetCreditCount(2) == "可用 2 次", "Traditional Chinese should read 可用 N 次")

    let english = UsageLocalization(localeIdentifier: "en-US")
    try expect(english.compactPrimaryLabel == "5h", "English should localize compact labels")
    try expect(english.primaryResetLabel == "5h reset", "English detail labels should stay short so label and value keep a gap")
    try expect(english.secondaryResetLabel == "1wk reset", "English detail labels should follow the compact 5h/1wk wording")
    try expect(english.resetCreditCount(1) == "1 time", "English should use a singular count unit")
    try expect(english.resetCreditCount(2) == "2 times", "English should use a plural count unit")

    let japanese = UsageLocalization(localeIdentifier: "ja-JP")
    try expect(japanese.primaryResetLabel == "5時間リセット", "Japanese should follow the ChatGPT locale")
    try expect(japanese.resetCreditCount(2) == "2 回", "Japanese should localize the count unit")

    let fallback = UsageLocalization(localeIdentifier: "unsupported")
    try expect(fallback.compactPrimaryLabel == "5h", "unsupported locales should fall back to English")

    try expect(simplifiedChinese.fontSizeMenuTitle == "字号", "Simplified Chinese should localize the font size menu title")
    try expect(traditionalChinese.languageMenuTitle == "語言", "Traditional Chinese should localize the language menu title")
    try expect(english.autoLanguageLabel == "Auto", "English should label the automatic language option")
    try expect(japanese.languageMenuTitle == "言語", "Japanese should localize the language menu title")
    try expect(fallback.languageMenuTitle == "Language", "unsupported locales should fall back to English menu strings")
}

private func makeProcessArgumentData(_ arguments: [String]) -> Data {
    var argumentCount = Int32(arguments.count)
    var data = withUnsafeBytes(of: &argumentCount) { Data($0) }
    data.append(contentsOf: arguments[0].utf8)
    data.append(0)
    data.append(0)
    for argument in arguments {
        data.append(contentsOf: argument.utf8)
        data.append(0)
    }
    return data
}
