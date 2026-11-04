import AppKit
import ApplicationServices
import ServiceManagement
import SwiftUI

@MainActor
final class CandidateAppState: ObservableObject {
    @Published var enabled = false
    @Published var status = FinderWrapMonitor.Status()
    @Published var accessibility = AXIsProcessTrusted()
    @Published var inputMonitoring = CGPreflightListenEventAccess()
    @Published var copied = false
    @Published var launchIssue: String?
    @Published var listWrap = UserDefaults.standard.bool(forKey: "listWrapEnabled")
    @Published var galleryCycle = (UserDefaults.standard.object(forKey: "galleryCycleEnabled") as? Bool) ?? true
    @Published var shiftWrap = (UserDefaults.standard.object(forKey: "shiftWrapEnabled") as? Bool) ?? true
    @Published var hideMenuBarIcon = AppMenuBarIcon.current.isHidden
    @Published var launchAtLogin = false
    @Published var launchAtLoginNeedsApproval = false
    @Published var launchAtLoginError: String?
    private let monitor = FinderWrapMonitor()
    private var timer: Timer?
    /// Set by the menu-bar controller so toggling the icon applies instantly
    /// instead of on the next launch.
    var onHideMenuBarIconChanged: ((Bool) -> Void)?
    var onAppearanceChanged: (() -> Void)?

    init() {
        monitor.setListWrap(listWrap)
        monitor.setGalleryCycle(galleryCycle)
        monitor.setShiftWrap(shiftWrap)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            Self.applyStoredAppearance()
            self.refresh()
            self.refreshLaunchAtLogin()
            if UserDefaults.standard.bool(forKey: "navigationEnabled"), self.permissionsReady {
                self.enabled = self.setEnabled(true)
            }
        }
    }

    var permissionsReady: Bool { accessibility && inputMonitoring }

    /// Colour for the compact state dot next to the master toggle.
    var statusTint: Color {
        if launchIssue != nil { return .red }
        if !permissionsReady { return .orange }
        switch status.state {
        case .ready:
            return enabled ? .green : Color(nsColor: .secondaryLabelColor)
        case .starting, .recovering, .permissionRequired, .listenerUnavailable:
            return .orange
        case .paused, .native:
            return Color(nsColor: .secondaryLabelColor)
        }
    }

    /// Localized runtime message; recomputed on every body evaluation so a
    /// language switch applies immediately.
    var message: String {
        let l = L10n.current
        if let launchIssue { return launchIssue }
        switch status.state {
        case .paused:
            return l.t("已暂停", "Paused")
        case .starting:
            return l.t("正在准备图标布局", "Preparing the Finder layout")
        case .ready:
            let detail = l.t("\(status.rowCount) 行 · \(status.itemCount) 个图标",
                             "\(status.rowCount) rows · \(status.itemCount) icons")
            if status.quickLook {
                return l.t("已生效 · Quick Look：", "Active · Quick Look: ") + detail
            }
            return l.t("已生效：", "Active: ") + detail
        case .native:
            switch status.reason {
            case "not-icon-view":
                return l.t("已开启 · 当前视图保持原生", "On · native in this view")
            case "finder-not-active":
                return l.t("已开启 · Finder 不在前台", "On · Finder is not frontmost")
            default:
                return l.t("已开启 · 当前场景保持原生", "On · native behaviour")
            }
        case .recovering:
            return l.t("读取暂时失败，正在重新检查", "Temporary read failure, retrying")
        case .permissionRequired:
            return l.t("等待系统权限", "Waiting for system permissions")
        case .listenerUnavailable:
            return l.t("监听不可用，请暂停后重新启用", "Listener unavailable; pause and re-enable")
        }
    }

    @discardableResult
    func setEnabled(_ value: Bool) -> Bool {
        launchIssue = nil
        if value, NSRunningApplication.runningApplications(withBundleIdentifier: "dev.finderwrap.finderwrap")
            .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            enabled = false
            launchIssue = L10n.current.t(
                "另一个 FinderWrap 正在运行。请先退出它，避免两个版本同时处理按键。",
                "Another FinderWrap is already running. Quit it first so two versions do not handle keys at once.")
            return false
        }
        let started = monitor.setEnabled(value)
        enabled = value && started
        UserDefaults.standard.set(enabled, forKey: "navigationEnabled")
        refresh()
        return enabled
    }

    func refresh() {
        accessibility = AXIsProcessTrusted()
        inputMonitoring = CGPreflightListenEventAccess()
        status = monitor.status
        refreshLaunchAtLogin()
        if enabled && !permissionsReady { _ = setEnabled(false) }
    }

    func refreshLaunchAtLogin() {
        let serviceStatus = SMAppService.mainApp.status
        launchAtLogin = serviceStatus == .enabled || serviceStatus == .requiresApproval
        launchAtLoginNeedsApproval = serviceStatus == .requiresApproval
    }

    func setLaunchAtLogin(_ value: Bool) {
        launchAtLoginError = nil
        do {
            if value {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = error.localizedDescription
        }
        refreshLaunchAtLogin()
    }

    func setListWrap(_ value: Bool) {
        listWrap = value
        UserDefaults.standard.set(value, forKey: "listWrapEnabled")
        monitor.setListWrap(value)
    }

    func setGalleryCycle(_ value: Bool) {
        galleryCycle = value
        UserDefaults.standard.set(value, forKey: "galleryCycleEnabled")
        monitor.setGalleryCycle(value)
    }

    func setShiftWrap(_ value: Bool) {
        shiftWrap = value
        UserDefaults.standard.set(value, forKey: "shiftWrapEnabled")
        monitor.setShiftWrap(value)
    }

    func setHideMenuBarIcon(_ value: Bool) {
        guard hideMenuBarIcon != value else { return }
        hideMenuBarIcon = value
        UserDefaults.standard.set(value, forKey: AppMenuBarIcon.storageKey)
        onHideMenuBarIconChanged?(value)
    }

    func settings(_ suffix: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?" + suffix) {
            NSWorkspace.shared.open(url)
        }
    }

    func copyDiagnostics() {
        let l = L10n.current
        let loginState = launchAtLogin ? l.t("已启用", "on") : l.t("未启用", "off")
        let approval = launchAtLoginNeedsApproval ? l.t("（等待系统设置批准）", " (waiting for approval)") : ""
        let diagnostics = monitor.diagnostics(chinese: l.chinese)
            + "\n" + l.t("开机启动：", "Launch at login: ") + loginState + approval
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(diagnostics, forType: .string)
        copied = true
    }

    func quit() {
        monitor.stop()
        NSApplication.shared.terminate(nil)
    }

    /// Re-reads the stored appearance and lets the menu bar controller follow.
    func refreshAppearance() {
        Self.applyStoredAppearance()
        onAppearanceChanged?()
    }

    /// AppKit-level appearance so the menu-bar panel (and its context menus)
    /// follow the stored choice immediately, not only after a relaunch.
    static func applyStoredAppearance() {
        let raw = UserDefaults.standard.string(forKey: AppAppearance.storageKey) ?? AppAppearance.system.rawValue
        switch AppAppearance.resolved(raw) {
        case .system:
            NSApplication.shared.appearance = nil
        case .light:
            NSApplication.shared.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

/// Menu-bar-only app: AppKit owns the lifecycle because SwiftUI's
/// `MenuBarExtra` cannot hide its own status item, which this app must support.
@main
struct FinderWrapCandidateApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var state: CandidateAppState?
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let state = CandidateAppState()
        let menuBar = MenuBarController(state: state)
        self.state = state
        self.menuBar = menuBar
        // Hidden mode shows the panel only when the user opens the app; a launch
        // by the login item must stay invisible.
        if state.hideMenuBarIcon, !LaunchEvent.launchedAsLoginItem {
            menuBar.presentPanel()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        menuBar?.presentPanel()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

/// Owns the status item and the two panel presentations: a popover while the
/// icon is visible, and a small window while it is hidden (the reopen/"open the
/// app again" path).
@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate, NSWindowDelegate {
    private let state: CandidateAppState
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var panelWindow: PanelWindow?
    private var escapeMonitor: Any?

    init(state: CandidateAppState) {
        self.state = state
        super.init()

        let item = makeStatusItem()
        item.isVisible = !state.hideMenuBarIcon
        statusItem = item

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        state.onAppearanceChanged = { [weak self] in
            self?.refreshPopoverAppearance()
        }
        state.onHideMenuBarIconChanged = { [weak self] hidden in
            self?.applyIconVisibility(hidden: hidden)
        }
    }

    /// Entry point for clicks, reopens and the launch path.
    func presentPanel() {
        if let window = panelWindow, window.isVisible {
            activate()
            window.makeKeyAndOrderFront(nil)
            return
        }
        if statusItem?.isVisible == true {
            showPopover()
        } else {
            showWindow()
        }
    }

    @objc private func togglePanel() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let window = panelWindow, window.isVisible {
            activate()
            window.makeKeyAndOrderFront(nil)
        } else {
            showPopover()
        }
    }

    /// Toggling the icon off must not take the panel away with it, so the open
    /// popover hands the panel over to the window presentation. Turning the icon
    /// back on installs a fresh status item: `isVisible = true` is not reliable
    /// after an item was hidden on recent macOS releases (the item stays gone).
    private func applyIconVisibility(hidden: Bool) {
        if hidden {
            statusItem?.isVisible = false
        } else {
            restoreStatusItem()
        }
        guard hidden else { return }
        if popover.isShown { popover.performClose(nil) }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.state.hideMenuBarIcon else { return }
            self.showWindow()
        }
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = item.button else { return item }
        button.image = LogoMark.statusItemImage(height: 17)
        button.image?.accessibilityDescription = "FinderWrap"
        button.imageScaling = .scaleProportionallyDown
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePanel)
        button.toolTip = "FinderWrap"
        return item
    }

    private func restoreStatusItem() {
        if let existing = statusItem {
            NSStatusBar.system.removeStatusItem(existing)
        }
        let item = makeStatusItem()
        item.isVisible = true
        statusItem = item
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        // The panel lives in exactly one place at a time; clicking the icon
        // takes it away from the window presentation.
        if let window = panelWindow, window.isVisible {
            window.close()
        }
        // A closed popover keeps laying out its detached SwiftUI content, which
        // can inflate `preferredContentSize`; a fresh controller per presentation
        // keeps the size honest.
        let controller = hostingController()
        popover.contentViewController = controller
        popover.contentSize = panelSize(of: controller)
        popover.appearance = storedPopoverAppearance()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        installEscapeMonitor()
    }

    /// A popover anchored to the menu bar otherwise picks up the menu bar's
    /// vibrancy appearance, which can disagree with the panel's own scheme.
    func refreshPopoverAppearance() {
        popover.appearance = storedPopoverAppearance()
    }

    private func storedPopoverAppearance() -> NSAppearance? {
        let raw = UserDefaults.standard.string(forKey: AppAppearance.storageKey) ?? AppAppearance.system.rawValue
        switch AppAppearance.resolved(raw) {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    /// `MenuBarExtra` panels close on Esc; the popover has to do that itself.
    private func installEscapeMonitor() {
        removeEscapeMonitor()
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.keyCode == 53, self.popover.isShown else { return event }
            self.popover.performClose(nil)
            return nil
        }
    }

    private func removeEscapeMonitor() {
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }

    func popoverDidClose(_ notification: Notification) {
        removeEscapeMonitor()
    }

    private func showWindow() {
        if let existing = panelWindow {
            activate()
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let controller = hostingController()
        let window = PanelWindow(contentRect: NSRect(x: 0, y: 0, width: 336, height: 520),
                                 styleMask: [.titled, .closable],
                                 backing: .buffered,
                                 defer: false)
        window.title = "FinderWrap"
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.moveToActiveSpace]
        window.delegate = self
        window.contentViewController = controller
        window.setContentSize(panelSize(of: controller))
        positionUnderMenuBar(window)
        panelWindow = window
        activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func hostingController() -> NSHostingController<CandidateMenuPanel> {
        let controller = NSHostingController(rootView: CandidateMenuPanel(state: state))
        controller.sizingOptions = [.preferredContentSize]
        return controller
    }

    /// SwiftUI needs one layout pass before it reports its height, and popovers
    /// and windows both want an explicit size.
    private func panelSize(of controller: NSViewController) -> NSSize {
        let view = controller.view
        view.frame = NSRect(x: 0, y: 0, width: 336, height: 200)
        view.layoutSubtreeIfNeeded()
        let fitting = view.fittingSize
        return NSSize(width: max(336, fitting.width), height: max(fitting.height, 120))
    }

    private func positionUnderMenuBar(_ window: NSWindow) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else {
            window.center()
            return
        }
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(x: visible.maxX - size.width - 16,
                                      y: visible.maxY - size.height - 16))
    }

    private func activate() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow, closing === panelWindow else { return }
        panelWindow = nil
    }

    /// SwiftUI changes the panel height when the hidden-mode hint appears or
    /// disappears; keep the window tucked under the menu bar's top-right corner.
    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === panelWindow else { return }
        positionUnderMenuBar(window)
    }
}

/// The app mark as vector paths, so the header and the status item share one
/// piece of artwork instead of the raster app icon.
private struct LogoMarkView: View {
    var arrow: Color
    var cells: Color

    var body: some View {
        Canvas { context, size in
            let transform = LogoMark.fitTransform(in: CGRect(origin: .zero, size: size))
            for cell in LogoMark.cells {
                var path = Path()
                path.addPath(Path(LogoMark.cellPath(cell)), transform: transform)
                context.fill(path, with: .color(cells))
            }
            let style = StrokeStyle(lineWidth: LogoMark.strokeWidth * transform.a,
                                    lineCap: .round,
                                    lineJoin: .round)
            for line in [LogoMark.shaftPath(), LogoMark.headPath()] {
                var path = Path()
                path.addPath(Path(line), transform: transform)
                context.stroke(path, with: .color(arrow), style: style)
            }
        }
    }
}

/// Titled panel window; Esc behaves like closing a popover.
private final class PanelWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        performClose(nil)
    }
}

/// Everything lives in the menu bar panel; the app has no ordinary window.
private struct CandidateMenuPanel: View {
    @ObservedObject var state: CandidateAppState
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue
    @AppStorage(AppAppearance.storageKey) private var appearanceRaw = AppAppearance.system.rawValue

    private var l10n: L10n { L10n(chinese: AppLanguage.resolved(languageRaw).isChinese) }
    private var colorScheme: ColorScheme? {
        guard let forcedDark = AppAppearance.resolved(appearanceRaw).forcedDark else { return nil }
        return forcedDark ? .dark : .light
    }

    var body: some View {
        let l = l10n
        VStack(alignment: .leading, spacing: 16) {
            header(l)
            Divider()
            mainControl(l)
            section(l.t("权限", "Permissions")) {
                permissionRow(l.t("辅助功能", "Accessibility"), icon: "hand.raised",
                              allowed: state.accessibility) {
                    state.settings("Privacy_Accessibility")
                }
                permissionRow(l.t("输入监控", "Input Monitoring"), icon: "keyboard",
                              allowed: state.inputMonitoring) {
                    state.settings("Privacy_ListenEvent")
                }
            }
            section(l.t("视图", "Views")) {
                toggleRow(l.t("列表左右键切项", "List: left/right steps"),
                          icon: "list.bullet.rectangle",
                          isOn: Binding(get: { state.listWrap }, set: { state.setListWrap($0) }),
                          help: l.t("左右键在列表视图里切换上一项/下一项；到首尾不循环，也不会展开或折叠文件夹。",
                                    "Left/right steps through list rows. It stops at the first and last row and never expands or collapses folders."))
                toggleRow(l.t("画廊到头循环", "Gallery: cycle at ends"),
                          icon: "rectangle.on.rectangle",
                          isOn: Binding(get: { state.galleryCycle }, set: { state.setGalleryCycle($0) }),
                          help: l.t("画廊视图里从第一张继续左键会回到最后一张，从最后一张继续右键会回到第一张。",
                                    "In Gallery view, left at the first item wraps to the last; right at the last item wraps to the first."))
                toggleRow(l.t("Shift 跨行扩选", "Shift: extend across rows"),
                          icon: "shift",
                          isOn: Binding(get: { state.shiftWrap }, set: { state.setShiftWrap($0) }),
                          help: l.t("按住 Shift 扩选时，到行尾/行首继续跨到相邻行；关闭后保持 Finder 原生，到行尾就停住。",
                                    "Hold Shift and extend across row boundaries; when off, Finder keeps its native behaviour and stops at the row edge."))
            }
            section(l.t("启动", "Startup")) {
                toggleRow(l.t("开机启动", "Launch at login"),
                          icon: "power",
                          isOn: Binding(get: { state.launchAtLogin }, set: { state.setLaunchAtLogin($0) }),
                          help: l.t("登录时自动启动 FinderWrap；系统可能要求你在“系统设置 → 通用 → 登录项”中允许。",
                                    "Start FinderWrap automatically at login. macOS may ask you to allow it under System Settings → General → Login Items."))
                if state.launchAtLoginNeedsApproval {
                    Text(l.t("需要在“系统设置 → 通用 → 登录项”中允许 FinderWrap。",
                             "Allow FinderWrap in System Settings → General → Login Items."))
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.leading, 24)
                }
                if let message = state.launchAtLoginError {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .padding(.leading, 24)
                }
            }
            section(l.t("界面", "Interface")) {
                toggleRow(l.t("隐藏菜单栏图标", "Hide menu bar icon"),
                          icon: "menubar.rectangle",
                          isOn: Binding(get: { state.hideMenuBarIcon },
                                        set: { state.setHideMenuBarIcon($0) }),
                          help: l.t("隐藏后 FinderWrap 仍在后台工作。需要打开本面板时，重新打开 FinderWrap 即可；它会以窗口形式出现。",
                                    "Hidden keeps FinderWrap running in the background. To open this panel again, just open FinderWrap; it appears as a window."))
                if state.hideMenuBarIcon {
                    Text(l.t("菜单栏图标已隐藏，FinderWrap 仍在后台运行；重新打开 FinderWrap 会以窗口形式再次显示本面板。",
                             "Menu bar icon hidden. FinderWrap keeps running in the background; open FinderWrap again to show this panel as a window."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 24)
                }
                optionRow(l.t("语言", "Language"), icon: "globe", selection: $languageRaw) {
                    Text(l.t("跟随系统", "System")).tag(AppLanguage.system.rawValue)
                    Text("中文").tag(AppLanguage.chinese.rawValue)
                    Text("English").tag(AppLanguage.english.rawValue)
                }
                optionRow(l.t("外观", "Appearance"), icon: "circle.lefthalf.filled", selection: $appearanceRaw) {
                    Text(l.t("跟随系统", "System")).tag(AppAppearance.system.rawValue)
                    Text(l.t("浅色", "Light")).tag(AppAppearance.light.rawValue)
                    Text(l.t("深色", "Dark")).tag(AppAppearance.dark.rawValue)
                }
            }
            Divider()
            footer(l)
        }
        .padding(16)
        .frame(width: 336)
        .preferredColorScheme(colorScheme)
        .onChange(of: appearanceRaw) { _ in state.refreshAppearance() }
    }

    private func header(_ l: L10n) -> some View {
        HStack(spacing: 10) {
            LogoMarkView(arrow: .accentColor, cells: Color.accentColor.opacity(0.38))
                .frame(width: 34, height: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("FinderWrap").font(.system(size: 13, weight: .semibold))
                Text("1.0.14").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func mainControl(_ l: L10n) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(l.t("左右键自动换行", "Wrap left/right arrows"))
                    .font(.system(size: 13, weight: .medium))
                statusLine(l)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(get: { state.enabled }, set: { _ = state.setEnabled($0) }))
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(!state.enabled && !state.permissionsReady)
                .accessibilityLabel(l.t("左右键自动换行", "Wrap left/right arrows"))
                .help(l.t("开启后，左右键在图标视图的行尾会换到下一行；关闭时完全保持 Finder 原生行为。",
                          "When on, arrow keys wrap at row ends in icon views. When off, Finder keeps its native behaviour."))
        }
    }

    private func statusLine(_ l: L10n) -> some View {
        HStack(spacing: 5) {
            Circle().fill(state.statusTint).frame(width: 5, height: 5)
                .accessibilityHidden(true)
            Text(state.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func permissionRow(_ title: String, icon: String, allowed: Bool,
                               action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(title)
            Spacer(minLength: 8)
            if allowed {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                    Text(l10n.t("已允许", "Allowed")).font(.caption)
                }
                .foregroundStyle(.green)
                .accessibilityElement(children: .combine)
            } else {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(l10n.t("前往授权", "Grant"))
                        Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .semibold))
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.orange)
                .help(l10n.t("打开系统设置里对应的权限页面。授权后回到这里即可开启换行。",
                             "Opens the matching System Settings privacy pane. Come back here to turn wrapping on."))
            }
        }
        .font(.callout)
        .frame(minHeight: 22)
    }

    private func toggleRow(_ title: String, icon: String, isOn: Binding<Bool>, help: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(title).font(.callout)
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .accessibilityLabel(Text(title))
                .help(help)
        }
        .frame(minHeight: 22)
    }

    private func optionRow<Content: View>(_ title: String, icon: String, selection: Binding<String>,
                                          @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(title).font(.callout)
            Spacer(minLength: 8)
            Picker("", selection: selection) { content() }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 124)
                .accessibilityLabel(Text(title))
        }
        .frame(minHeight: 24)
    }

    private func footer(_ l: L10n) -> some View {
        HStack {
            Button(action: state.copyDiagnostics) {
                Label(state.copied ? l.t("已复制", "Copied") : l.t("复制诊断信息", "Copy diagnostics"),
                      systemImage: state.copied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Spacer()
            Button(l.t("退出", "Quit"), action: state.quit)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .keyboardShortcut("q", modifiers: .command)
        }
    }
}
