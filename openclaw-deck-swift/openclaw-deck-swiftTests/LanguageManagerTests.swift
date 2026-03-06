// LanguageManagerTests.swift
// OpenClaw Deck Swift
//
// LanguageManager 单元测试

@testable import openclaw_deck_swift
import XCTest

final class LanguageManagerTests: XCTestCase {
    var languageManager: LanguageManager!

    override func setUp() {
        super.setUp()
        languageManager = LanguageManager.shared
    }

    override func tearDown() {
        // 恢复默认语言
        languageManager.resetToSystemLanguage()
        languageManager = nil
        super.tearDown()
    }

    // MARK: - 初始化测试

    func testSharedInstance() {
        // 验证单例存在
        XCTAssertNotNil(LanguageManager.shared, "shared 实例不应该为空")
    }

    func testSharedInstance_isSingleton() {
        // 验证单例唯一性
        let instance1 = LanguageManager.shared
        let instance2 = LanguageManager.shared
        XCTAssertTrue(instance1 === instance2, "应该是同一个单例实例")
    }

    // MARK: - 当前语言检测

    func testCurrentLocale() {
        // 验证当前语言设置
        let locale = languageManager.currentLocale
        // Locale 不为空即可
        XCTAssertNotNil(locale.identifier, "当前语言 identifier 不应该为空")
    }

    func testCurrentLocale_isConsistent() {
        // 多次调用应该返回相同结果
        let locale1 = languageManager.currentLocale.identifier
        let locale2 = languageManager.currentLocale.identifier
        XCTAssertEqual(locale1, locale2, "多次调用应该返回一致的结果")
    }

    func testCurrentLocale_initialValue() {
        // 初始语言应该是中文或英文
        let locale = languageManager.currentLocale.identifier
        XCTAssertTrue(
            locale.hasPrefix("zh") || locale.hasPrefix("en"),
            "初始语言应该是中文或英文"
        )
    }

    // MARK: - 语言切换

    func testSetLanguage_chinese() {
        // 测试切换到中文
        languageManager.setLanguage(.chinese)
        let locale = languageManager.currentLocale.identifier
        XCTAssertTrue(
            locale.hasPrefix("zh"),
            "切换到中文后应该以 zh 开头"
        )
    }

    func testSetLanguage_english() {
        // 测试切换到英文
        languageManager.setLanguage(.english)
        let locale = languageManager.currentLocale.identifier
        XCTAssertTrue(
            locale.hasPrefix("en"),
            "切换到英文后应该以 en 开头"
        )
    }

    func testSetLanguage_persistence() {
        // 测试语言设置持久化
        languageManager.setLanguage(.english)
        let newManager = LanguageManager.shared
        XCTAssertEqual(
            newManager.selectedLanguage,
            .english,
            "语言设置应该被保存"
        )
    }

    func testSetLanguage_triggersNotification() {
        // 测试切换语言发送通知
        let expectation = XCTestExpectation(description: "Language change notification")

        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        languageManager.setLanguage(.english)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - 重置为系统语言

    func testResetToSystemLanguage() {
        // 测试重置为系统语言
        languageManager.setLanguage(.english)
        languageManager.resetToSystemLanguage()

        // 应该恢复到系统语言
        let locale = languageManager.currentLocale.identifier
        // 不验证具体值，只要不崩溃即可
        XCTAssertNotNil(locale)
    }

    func testResetToSystemLanguage_clearsUserDefaults() {
        // 测试重置会清除 UserDefaults
        let key = "selected_language"
        languageManager.setLanguage(.english)
        XCTAssertNotNil(UserDefaults.standard.string(forKey: key), "应该保存了语言设置")

        languageManager.resetToSystemLanguage()
        XCTAssertNil(UserDefaults.standard.string(forKey: key), "重置后应该清除 UserDefaults")
    }

    // MARK: - 支持的语言列表

    func testLanguageEnum_allCases() {
        // 测试语言枚举的所有情况
        let allCases = LanguageManager.Language.allCases
        XCTAssertFalse(allCases.isEmpty, "语言列表不应该为空")

        // 应该包含中文和英文
        XCTAssertTrue(allCases.contains(.chinese), "应该包含中文")
        XCTAssertTrue(allCases.contains(.english), "应该包含英文")
    }

    func testLanguage_displayName() {
        // 测试语言显示名称
        XCTAssertFalse(
            LanguageManager.Language.chinese.displayName.isEmpty,
            "中文显示名称不应该为空"
        )
        XCTAssertFalse(
            LanguageManager.Language.english.displayName.isEmpty,
            "英文显示名称不应该为空"
        )
    }

    func testLanguage_locale() {
        // 测试语言 locale
        let chineseLocale = LanguageManager.Language.chinese.locale
        XCTAssertEqual(chineseLocale.identifier, "zh-Hans", "中文 locale 应该是 zh-Hans")

        let englishLocale = LanguageManager.Language.english.locale
        XCTAssertEqual(englishLocale.identifier, "en", "英文 locale 应该是 en")
    }

    func testLanguage_id() {
        // 测试语言 ID
        XCTAssertEqual(
            LanguageManager.Language.chinese.id,
            "zh-Hans",
            "中文 ID 应该是 zh-Hans"
        )
        XCTAssertEqual(
            LanguageManager.Language.english.id,
            "en",
            "英文 ID 应该是 en"
        )
    }

    // MARK: - selectedLanguage 属性

    func testSelectedLanguage_get() {
        // 测试获取当前选择的语言
        let language = languageManager.selectedLanguage
        // 应该是中文或英文
        XCTAssertTrue(
            language == .chinese || language == .english,
            "当前语言应该是中文或英文"
        )
    }

    func testSelectedLanguage_set() {
        // 测试设置当前选择的语言
        languageManager.selectedLanguage = .english
        XCTAssertEqual(languageManager.selectedLanguage, .english, "应该能设置语言")

        languageManager.selectedLanguage = .chinese
        XCTAssertEqual(languageManager.selectedLanguage, .chinese, "应该能切换回中文")
    }

    // MARK: - 本地化字符串扩展

    func testLocalizedString_ok() {
        // 测试本地化字符串
        let localized = "ok".localized
        XCTAssertFalse(localized.isEmpty, "本地化字符串不应该为空")
    }

    func testLocalizedString_cancel() {
        // 测试另一个本地化字符串
        let localized = "cancel".localized
        XCTAssertFalse(localized.isEmpty, "本地化字符串不应该为空")
    }

    // MARK: - 通知测试

    func testNotificationCenter() {
        // 确保通知中心正常工作
        let expectation = XCTestExpectation(description: "Notification received")

        let observer = NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        languageManager.setLanguage(.english)
        wait(for: [expectation], timeout: 1.0)

        NotificationCenter.default.removeObserver(observer)
    }
}
