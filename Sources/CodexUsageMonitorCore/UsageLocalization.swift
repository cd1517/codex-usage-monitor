import Foundation

public struct UsageLocalization: Equatable, Sendable {
    public let localeIdentifier: String
    public let compactPrimaryLabel: String
    public let compactSecondaryLabel: String
    public let primaryResetLabel: String
    public let secondaryResetLabel: String
    public let resetCreditsLabel: String
    public let resetCreditExpiryLabel: String
    public let resetCreditAvailablePrefix: String
    public let unavailableText: String
    public let unknownText: String
    public let fontSizeMenuTitle: String
    public let languageMenuTitle: String
    public let autoLanguageLabel: String

    private let resetCreditUnit: String
    private let usesEnglishPlural: Bool

    public init(localeIdentifier: String) {
        let normalized = localeIdentifier.replacingOccurrences(of: "_", with: "-")
        let language = Self.languageKey(for: normalized)
        let strings = Self.strings(for: language)
        self.localeIdentifier = language == "en" && !normalized.lowercased().hasPrefix("en")
            ? "en-US"
            : normalized
        compactPrimaryLabel = strings[0]
        compactSecondaryLabel = strings[1]
        primaryResetLabel = strings[2]
        secondaryResetLabel = strings[3]
        resetCreditsLabel = strings[4]
        resetCreditExpiryLabel = strings[5]
        resetCreditAvailablePrefix = strings[9]
        resetCreditUnit = strings[6]
        unavailableText = strings[7]
        unknownText = strings[8]
        usesEnglishPlural = language == "en"
        let menuStrings = Self.menuStrings(for: language)
        fontSizeMenuTitle = menuStrings.fontSize
        languageMenuTitle = menuStrings.language
        autoLanguageLabel = menuStrings.auto
    }

    public func resetCreditCount(_ count: Int?) -> String {
        guard let count else {
            return "--"
        }
        let prefix = resetCreditAvailablePrefix.isEmpty ? "" : resetCreditAvailablePrefix + " "
        if usesEnglishPlural {
            return "\(prefix)\(count) \(count == 1 ? "time" : "times")"
        }
        return "\(prefix)\(count) \(resetCreditUnit)"
    }

    private static func languageKey(for identifier: String) -> String {
        let lowercased = identifier.lowercased()
        if lowercased.hasPrefix("zh") {
            return lowercased.contains("hant")
                || lowercased.contains("-tw")
                || lowercased.contains("-hk")
                || lowercased.contains("-mo")
                ? "zh-Hant"
                : "zh-Hans"
        }
        let supported = [
            "ar", "de", "en", "es", "fr", "hi", "id", "it", "ja", "ko",
            "nl", "pl", "pt", "ru", "th", "tr", "uk", "vi"
        ]
        let language = lowercased.split(separator: "-").first.map(String.init) ?? "en"
        return supported.contains(language) ? language : "en"
    }

    private static func strings(for language: String) -> [String] {
        switch language {
        case "zh-Hans":
            return ["5小时", "1周", "5 小时重置", "1 周重置", "限额重置", "有效期至", "次", "不可用", "未知", "可用"]
        case "zh-Hant":
            return ["5小時", "1週", "5 小時重置", "1 週重置", "限額重置", "有效期至", "次", "無法使用", "未知", "可用"]
        case "ja":
            return ["5時間", "1週間", "5時間リセット", "1週間リセット", "リセットクレジット", "有効期限", "回", "利用不可", "不明", ""]
        case "ko":
            return ["5시간", "1주", "5시간 초기화", "1주 초기화", "초기화 크레딧", "유효 기간", "회", "사용 불가", "알 수 없음", ""]
        case "fr":
            return ["5 h", "1 sem.", "Réinit. 5 h", "Réinit. 1 sem.", "Crédits de réinit.", "Valable jusqu’au", "fois", "Indisponible", "Inconnu", ""]
        case "de":
            return ["5 Std.", "1 Wo.", "Reset nach 5 Std.", "Reset nach 1 Wo.", "Reset-Guthaben", "Gültig bis", "Mal", "Nicht verfügbar", "Unbekannt", ""]
        case "es":
            return ["5 h", "1 sem.", "Reinicio de 5 h", "Reinicio semanal", "Créditos de reinicio", "Válido hasta", "veces", "No disponible", "Desconocido", ""]
        case "pt":
            return ["5 h", "1 sem.", "Redefinição de 5 h", "Redefinição semanal", "Créditos de redefinição", "Válido até", "vezes", "Indisponível", "Desconhecido", ""]
        case "it":
            return ["5 h", "1 sett.", "Ripristino 5 h", "Ripristino settimanale", "Crediti di ripristino", "Valido fino al", "volte", "Non disponibile", "Sconosciuto", ""]
        case "ru":
            return ["5 ч", "1 нед.", "Сброс через 5 ч", "Недельный сброс", "Кредиты сброса", "Действительно до", "раз", "Недоступно", "Неизвестно", ""]
        case "ar":
            return ["5 س", "أسبوع", "إعادة تعيين 5 س", "إعادة تعيين أسبوعية", "أرصدة إعادة التعيين", "صالح حتى", "مرة", "غير متاح", "غير معروف", ""]
        case "nl":
            return ["5 u", "1 wk", "Reset na 5 u", "Wekelijkse reset", "Resetcredits", "Geldig tot", "keer", "Niet beschikbaar", "Onbekend", ""]
        case "pl":
            return ["5 godz.", "1 tydz.", "Reset po 5 godz.", "Reset tygodniowy", "Kredyty resetu", "Ważne do", "razy", "Niedostępne", "Nieznane", ""]
        case "tr":
            return ["5 sa.", "1 hf.", "5 saatlik sıfırlama", "Haftalık sıfırlama", "Sıfırlama kredileri", "Geçerlilik", "kez", "Kullanılamıyor", "Bilinmiyor", ""]
        case "uk":
            return ["5 год", "1 тиж.", "Скидання через 5 год", "Тижневе скидання", "Кредити скидання", "Дійсно до", "раз", "Недоступно", "Невідомо", ""]
        case "vi":
            return ["5 giờ", "1 tuần", "Đặt lại sau 5 giờ", "Đặt lại hằng tuần", "Lượt đặt lại", "Có hiệu lực đến", "lần", "Không khả dụng", "Không rõ", ""]
        case "id":
            return ["5 jam", "1 mgg.", "Reset 5 jam", "Reset mingguan", "Kredit reset", "Berlaku hingga", "kali", "Tidak tersedia", "Tidak diketahui", ""]
        case "th":
            return ["5 ชม.", "1 สัปดาห์", "รีเซ็ต 5 ชม.", "รีเซ็ตรายสัปดาห์", "เครดิตรีเซ็ต", "ใช้ได้ถึง", "ครั้ง", "ไม่พร้อมใช้งาน", "ไม่ทราบ", ""]
        case "hi":
            return ["5 घंटे", "1 सप्ताह", "5 घंटे रीसेट", "साप्ताहिक रीसेट", "रीसेट क्रेडिट", "मान्य अवधि", "बार", "उपलब्ध नहीं", "अज्ञात", ""]
        default:
            return ["5h", "1wk", "5-hour reset", "1-week reset", "Reset credits", "Valid until", "times", "Unavailable", "Unknown", ""]
        }
    }

    private static func menuStrings(
        for language: String
    ) -> (fontSize: String, language: String, auto: String) {
        switch language {
        case "zh-Hans":
            return ("字号", "语言", "自动")
        case "zh-Hant":
            return ("字號", "語言", "自動")
        case "ja":
            return ("文字サイズ", "言語", "自動")
        case "ko":
            return ("글자 크기", "언어", "자동")
        case "fr":
            return ("Taille de police", "Langue", "Automatique")
        case "de":
            return ("Schriftgröße", "Sprache", "Automatisch")
        case "es":
            return ("Tamaño de fuente", "Idioma", "Automático")
        case "pt":
            return ("Tamanho da fonte", "Idioma", "Automático")
        case "it":
            return ("Dimensione carattere", "Lingua", "Automatico")
        case "ru":
            return ("Размер шрифта", "Язык", "Автоматически")
        case "ar":
            return ("حجم الخط", "اللغة", "تلقائي")
        case "nl":
            return ("Tekengrootte", "Taal", "Automatisch")
        case "pl":
            return ("Rozmiar czcionki", "Język", "Automatycznie")
        case "tr":
            return ("Yazı tipi boyutu", "Dil", "Otomatik")
        case "uk":
            return ("Розмір шрифту", "Мова", "Автоматично")
        case "vi":
            return ("Cỡ chữ", "Ngôn ngữ", "Tự động")
        case "id":
            return ("Ukuran font", "Bahasa", "Otomatis")
        case "th":
            return ("ขนาดฟอนต์", "ภาษา", "อัตโนมัติ")
        case "hi":
            return ("फ़ॉन्ट आकार", "भाषा", "स्वतः")
        default:
            return ("Font Size", "Language", "Auto")
        }
    }
}
