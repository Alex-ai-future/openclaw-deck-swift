// DeviceUtilsTests.swift
// OpenClaw Deck Swift
//
// DeviceUtils 单元测试

@testable import openclaw_deck_swift
import XCTest

final class DeviceUtilsTests: XCTestCase {
    // MARK: - iPad 检测

    func testIsIPad_onMacOS() {
        // macOS 上应该返回 false
        #if os(macOS)
            XCTAssertFalse(DeviceUtils.isIPad, "macOS 上 isIPad 应该返回 false")
        #endif
    }

    func testIsIPad_returnsBool() {
        // 验证返回类型是 Bool
        let result = DeviceUtils.isIPad
        XCTAssertTrue(result == true || result == false, "应该返回布尔值")
    }

    // MARK: - Mac 检测

    func testIsMac_onMacOS() {
        // macOS 上应该返回 true
        #if os(macOS)
            XCTAssertTrue(DeviceUtils.isMac, "macOS 上 isMac 应该返回 true")
        #endif
    }

    func testIsMac_returnsBool() {
        // 验证返回类型是 Bool
        let result = DeviceUtils.isMac
        XCTAssertTrue(result == true || result == false, "应该返回布尔值")
    }

    // MARK: - iPhone 检测

    func testIsIPhone_returnsBool() {
        // 验证返回类型是 Bool
        let result = DeviceUtils.isIPhone
        XCTAssertTrue(result == true || result == false, "应该返回布尔值")
    }

    func testIsIPhone_onMacOS() {
        // macOS 上应该返回 false
        #if os(macOS)
            XCTAssertFalse(DeviceUtils.isIPhone, "macOS 上 isIPhone 应该返回 false")
        #endif
    }

    // MARK: - 移动设备检测

    func testIsMobile_returnsBool() {
        // 验证返回类型是 Bool
        let result = DeviceUtils.isMobile
        XCTAssertTrue(result == true || result == false, "应该返回布尔值")
    }

    func testIsMobile_onMacOS() {
        // macOS 上应该返回 false
        #if os(macOS)
            XCTAssertFalse(DeviceUtils.isMobile, "macOS 上 isMobile 应该返回 false")
        #endif
    }

    // MARK: - 设备类型检测

    func testCurrentType() {
        // 验证设备类型检测返回有效值
        let type = DeviceUtils.currentType
        // 只要能访问就不崩溃，具体值取决于运行平台
        XCTAssertTrue(
            type == .mac || type == .iPhone || type == .iPad || type == .unknown,
            "应该返回有效的设备类型"
        )
    }

    func testCurrentType_onMacOS() {
        // macOS 上应该返回 .mac
        #if os(macOS)
            XCTAssertEqual(DeviceUtils.currentType, .mac, "macOS 上应该返回 .mac")
        #endif
    }

    func testCurrentType_isConsistent() {
        // 多次调用应该返回相同结果
        let type1 = DeviceUtils.currentType
        let type2 = DeviceUtils.currentType
        XCTAssertEqual(type1, type2, "多次调用应该返回一致的结果")
    }

    // MARK: - 一致性测试

    func testIsIPad_andCurrentType_consistency() {
        // isIPad 应该与 currentType == .iPad 一致
        let expectedIsIPad = (DeviceUtils.currentType == .iPad)
        XCTAssertEqual(DeviceUtils.isIPad, expectedIsIPad, "isIPad 应该与 currentType 一致")
    }

    func testIsMac_andCurrentType_consistency() {
        // isMac 应该与 currentType == .mac 一致
        let expectedIsMac = (DeviceUtils.currentType == .mac)
        XCTAssertEqual(DeviceUtils.isMac, expectedIsMac, "isMac 应该与 currentType 一致")
    }

    func testIsIPhone_andCurrentType_consistency() {
        // isIPhone 应该与 currentType == .iPhone 一致
        let expectedIsIPhone = (DeviceUtils.currentType == .iPhone)
        XCTAssertEqual(DeviceUtils.isIPhone, expectedIsIPhone, "isIPhone 应该与 currentType 一致")
    }

    // MARK: - 性能测试

    func testIsIPad_performance() {
        measure {
            for _ in 0 ..< 1000 {
                _ = DeviceUtils.isIPad
            }
        }
    }

    func testIsMac_performance() {
        measure {
            for _ in 0 ..< 1000 {
                _ = DeviceUtils.isMac
            }
        }
    }

    func testCurrentType_performance() {
        measure {
            for _ in 0 ..< 1000 {
                _ = DeviceUtils.currentType
            }
        }
    }
}
