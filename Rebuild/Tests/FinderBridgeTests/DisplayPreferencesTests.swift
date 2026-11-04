import XCTest
@testable import FinderBridge

final class DisplayPreferencesTests: XCTestCase {
    func testLanguageResolutionFallsBackToSystem() {
        XCTAssertEqual(AppLanguage.resolved("chinese"), .chinese)
        XCTAssertEqual(AppLanguage.resolved("english"), .english)
        XCTAssertEqual(AppLanguage.resolved("system"), .system)
        XCTAssertEqual(AppLanguage.resolved("fr"), .system)
        XCTAssertTrue(AppLanguage.chinese.isChinese)
        XCTAssertFalse(AppLanguage.english.isChinese)
    }

    func testAppearanceResolutionAndForcedScheme() {
        XCTAssertEqual(AppAppearance.resolved("dark"), .dark)
        XCTAssertEqual(AppAppearance.resolved("light"), .light)
        XCTAssertEqual(AppAppearance.resolved("garbage"), .system)
        XCTAssertEqual(AppAppearance.dark.forcedDark, true)
        XCTAssertEqual(AppAppearance.light.forcedDark, false)
        XCTAssertNil(AppAppearance.system.forcedDark)
    }

    func testPreferenceKeysAreStable() {
        XCTAssertEqual(AppLanguage.storageKey, "displayLanguage")
        XCTAssertEqual(AppAppearance.storageKey, "appAppearance")
        XCTAssertEqual(AppMenuBarIcon.storageKey, "hideMenuBarIcon")
    }

    func testMenuBarIconResolution() {
        XCTAssertEqual(AppMenuBarIcon.resolved(storedHidden: false), .visible)
        XCTAssertEqual(AppMenuBarIcon.resolved(storedHidden: true), .hidden)
        XCTAssertFalse(AppMenuBarIcon.visible.isHidden)
        XCTAssertTrue(AppMenuBarIcon.hidden.isHidden)
        XCTAssertEqual(AppMenuBarIcon.hidden.storedValue, true)
        XCTAssertEqual(AppMenuBarIcon.visible.storedValue, false)
    }
}
