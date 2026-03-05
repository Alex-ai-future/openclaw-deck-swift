import Combine
import Foundation

/// 语言管理器 - 支持 App 内手动切换语言
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    /// 支持的语言列表
    enum Language: String, CaseIterable, Identifiable {
        case chinese = "zh-Hans"
        case english = "en"

        var id: String {
            rawValue
        }

        var displayName: String {
            switch self {
            case .chinese:
                "简体中文"
            case .english:
                "English"
            }
        }

        var locale: Locale {
            Locale(identifier: rawValue)
        }
    }

    /// UserDefaults 存储键
    private let selectedLanguageKey = "selected_language"

    /// 当前选中的语言（使用 @Published 触发 UI 更新）
    @Published var selectedLanguage: Language

    /// 获取当前语言的 Locale
    var currentLocale: Locale {
        selectedLanguage.locale
    }

    /// 初始化
    init() {
        // 从 UserDefaults 读取已保存的语言，或默认跟随系统
        if let code = UserDefaults.standard.string(forKey: selectedLanguageKey),
           let language = Language(rawValue: code)
        {
            selectedLanguage = language
        } else {
            selectedLanguage = Locale.current.language.languageCode?.identifier == "zh" ? .chinese : .english
        }
    }

    /// 切换语言
    /// SwiftUI 会通过 .environment(\.locale) 自动刷新文本，无需手动触发视图重建
    func setLanguage(_ language: Language) {
        selectedLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: selectedLanguageKey)
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }

    /// 重置为系统语言
    func resetToSystemLanguage() {
        UserDefaults.standard.removeObject(forKey: selectedLanguageKey)
        selectedLanguage = Locale.current.language.languageCode?.identifier == "zh" ? .chinese : .english
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - String 扩展

extension String {
    /// 本地化字符串（使用当前选择的语言）
    var localized: String {
        guard let languageCode = LanguageManager.shared.selectedLanguage.rawValue as String? else {
            return NSLocalizedString(self, bundle: .main, comment: "")
        }

        // 查找对应的 .lproj 文件夹
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path)
        {
            return NSLocalizedString(self, bundle: bundle, comment: "")
        }

        //  fallback 到主 bundle
        return NSLocalizedString(self, bundle: .main, comment: "")
    }

    /// 本地化字符串（带参数）
    func localizedWithArgs(_ args: CVarArg...) -> String {
        guard let languageCode = LanguageManager.shared.selectedLanguage.rawValue as String? else {
            return String(format: NSLocalizedString(self, bundle: .main, comment: ""), arguments: args)
        }

        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path)
        {
            return String(format: NSLocalizedString(self, bundle: bundle, comment: ""), arguments: args)
        }

        return String(format: NSLocalizedString(self, bundle: .main, comment: ""), arguments: args)
    }
}
