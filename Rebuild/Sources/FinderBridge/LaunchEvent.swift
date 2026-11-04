import AppKit

/// Inspects the Apple event that started the app.
///
/// macOS launches login items through `kAEOpenApplication` and flags them with
/// `keyAELaunchedAsLogInItem` ("lgit"), so the hidden-icon mode can tell "the
/// user opened FinderWrap" apart from "the system started it at login".
public enum LaunchEvent {
    public static func launchedAsLoginItem(from event: NSAppleEventDescriptor?) -> Bool {
        guard let event, event.eventID == AEEventID(kAEOpenApplication) else { return false }
        // macOS has used each of these places for the marker over the years;
        // treat any of them as a login-item launch.
        if event.paramDescriptor(forKeyword: keyAELaunchedAsLogInItem) != nil { return true }
        if event.attributeDescriptor(forKeyword: keyAELaunchedAsLogInItem) != nil { return true }
        guard let propData = event.attributeDescriptor(forKeyword: keyAEPropData) else { return false }
        return propData.enumCodeValue == keyAELaunchedAsLogInItem
            || propData.typeCodeValue == keyAELaunchedAsLogInItem
    }

    /// The launch event currently being handled, if any.
    public static var launchedAsLoginItem: Bool {
        launchedAsLoginItem(from: NSAppleEventManager.shared().currentAppleEvent)
    }
}
