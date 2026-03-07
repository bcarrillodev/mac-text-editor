import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    var shouldTerminateHandler: (() -> NSApplication.TerminateReply)?

    override init() {
        super.init()
        Self.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        applyAppIcon()

        DispatchQueue.main.async { [weak self] in
            self?.applyAppIcon()
            NSApp.windows.first { $0.canBecomeKey }?.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        shouldTerminateHandler?() ?? .terminateNow
    }
    
    private func applyAppIcon() {
        // Prefer Swift Package resource, then asset, then main bundle fallback
        if let iconURL = Bundle.module.url(forResource: "app_icon", withExtension: "png"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = iconImage
        } else if let image = NSImage(named: "app_icon") {
            NSApp.applicationIconImage = image
        } else if let iconURL = Bundle.main.url(forResource: "app_icon", withExtension: "png"),
                  let iconImage = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = iconImage
        }
    }
}

@main
struct TextEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
