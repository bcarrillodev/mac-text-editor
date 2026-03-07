import SwiftUI
import AppKit
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    private let logger = Logger(subsystem: "mac-text-editor", category: "AppDelegate")
    var shouldTerminateHandler: (() -> NSApplication.TerminateReply)?
    var openFilesHandler: (([String]) -> Void)?
    private var pendingOpenFiles: [String] = []

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

    func application(_ application: NSApplication, open urls: [URL]) {
        let filePaths = urls
            .filter(\.isFileURL)
            .map(\.path)

        logger.info("Received URL open request for \(filePaths.count, privacy: .public) file(s)")
        handleIncomingFiles(filePaths)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        logger.info("Received file open request for \(filenames.count, privacy: .public) file(s)")
        handleIncomingFiles(filenames)
        sender.reply(toOpenOrPrint: .success)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        logger.info("Received single file open request for \(filename, privacy: .public)")
        handleIncomingFiles([filename])
        return true
    }

    func consumePendingOpenFiles() -> [String] {
        let files = pendingOpenFiles
        pendingOpenFiles.removeAll(keepingCapacity: false)
        return files
    }

    func registerOpenFilesHandler(_ handler: @escaping ([String]) -> Void) {
        openFilesHandler = handler
    }

    private func handleIncomingFiles(_ filenames: [String]) {
        var seenPaths = Set<String>()
        let normalizedPaths = filenames
            .map { URL(fileURLWithPath: $0).standardizedFileURL.path }
            .filter { !$0.isEmpty }
            .filter { seenPaths.insert($0).inserted }

        guard !normalizedPaths.isEmpty else { return }

        if let handler = openFilesHandler {
            handler(normalizedPaths)
            return
        }

        pendingOpenFiles.append(contentsOf: normalizedPaths)
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
