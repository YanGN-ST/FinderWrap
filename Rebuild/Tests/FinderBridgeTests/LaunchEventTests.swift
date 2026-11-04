import AppKit
import XCTest
@testable import FinderBridge

final class LaunchEventTests: XCTestCase {
    private func appleEvent(id: AEEventID) -> NSAppleEventDescriptor {
        NSAppleEventDescriptor(eventClass: AEEventClass(kCoreEventClass),
                               eventID: id,
                               targetDescriptor: nil,
                               returnID: AEReturnID(kAutoGenerateReturnID),
                               transactionID: AETransactionID(kAnyTransactionID))
    }

    func testMissingEventIsNotALoginLaunch() {
        XCTAssertFalse(LaunchEvent.launchedAsLoginItem(from: nil))
    }

    func testPlainOpenEventIsNotALoginLaunch() {
        XCTAssertFalse(LaunchEvent.launchedAsLoginItem(from: appleEvent(id: AEEventID(kAEOpenApplication))))
    }

    func testLoginMarkerInEventPropertyData() {
        let event = appleEvent(id: AEEventID(kAEOpenApplication))
        _ = event.setAttribute(NSAppleEventDescriptor(enumCode: keyAELaunchedAsLogInItem),
                               forKeyword: keyAEPropData)
        XCTAssertTrue(LaunchEvent.launchedAsLoginItem(from: event))
    }

    func testLoginMarkerAsAttribute() {
        let event = appleEvent(id: AEEventID(kAEOpenApplication))
        _ = event.setAttribute(NSAppleEventDescriptor(enumCode: keyAELaunchedAsLogInItem),
                               forKeyword: keyAELaunchedAsLogInItem)
        XCTAssertTrue(LaunchEvent.launchedAsLoginItem(from: event))
    }

    func testLoginMarkerAsParameter() {
        let event = appleEvent(id: AEEventID(kAEOpenApplication))
        _ = event.setParam(NSAppleEventDescriptor(enumCode: keyAELaunchedAsLogInItem),
                           forKeyword: keyAELaunchedAsLogInItem)
        XCTAssertTrue(LaunchEvent.launchedAsLoginItem(from: event))
    }

    func testMarkerOutsideAnOpenApplicationEventIsIgnored() {
        let event = appleEvent(id: AEEventID(kAEQuitApplication))
        _ = event.setAttribute(NSAppleEventDescriptor(enumCode: keyAELaunchedAsLogInItem),
                               forKeyword: keyAEPropData)
        XCTAssertFalse(LaunchEvent.launchedAsLoginItem(from: event))
    }
}
