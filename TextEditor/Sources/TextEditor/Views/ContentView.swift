import SwiftUI
import AppKit
import OSLog

struct ContentView: View {
    private let logger = Logger(subsystem: "mac-text-editor", category: "ContentView")
    @StateObject private var state = EditorState()
    @StateObject private var autoSaveService = AutoSaveService()
    private let promptService: SavePrompting

    init(promptService: SavePrompting = SavePromptService()) {
        self.promptService = promptService
    }

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(
                state: state,
                onClose: closeTab,
                onSelect: selectTab,
                onAddTab: state.createUntitledFile,
                onOpenFile: openFileFromDisk,
                onSave: saveActiveTab
            )

            EditorView(state: state)
        }
        .background(
            WindowCloseInterceptor(onShouldClose: confirmWindowClose)
        )
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            AppDelegate.shared?.shouldTerminateHandler = confirmApplicationTermination
            loadSession()
            AppDelegate.shared?.registerOpenFilesHandler { paths in
                openFilesFromExternalSource(paths)
            }
            if let startupFiles = AppDelegate.shared?.consumePendingOpenFiles(), !startupFiles.isEmpty {
                openFilesFromExternalSource(startupFiles)
            } else {
                openFilesFromProcessArguments()
            }
            startAutoSave()
            activateAppWindow()
        }
        .onOpenURL { url in
            guard url.isFileURL else { return }
            openFilesFromExternalSource([url.path])
        }
        .onDisappear {
            if AppDelegate.shared?.shouldTerminateHandler != nil {
                AppDelegate.shared?.shouldTerminateHandler = nil
            }
            saveSession()
            autoSaveService.stopAutoSave()
        }
    }

    private func closeTab(_ index: Int) {
        guard makePromptController().confirmCloseTab(in: state, at: index) else { return }
        state.closeTab(at: index)
    }

    private func selectTab(_ index: Int) {
        state.switchToTab(index: index)
    }

    private func loadSession() {
        if let savedState = SessionPersistenceService.shared.loadSession() {
            state.openTabs = savedState.openTabs
            state.activeTabIndex = savedState.activeTabIndex
        }

        if state.openTabs.isEmpty {
            state.createUntitledFile()
        }
    }

    private func saveSession() {
        do {
            try SessionPersistenceService.shared.saveSession(state: state)
        } catch {
            logger.error("Failed to save editor session: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func saveActiveTab() {
        guard state.activeTabIndex >= 0 && state.activeTabIndex < state.openTabs.count else { return }
        _ = saveTab(at: state.activeTabIndex, allowSaveAsForUntitled: true)
        saveSession()
    }

    private func saveModifiedTabsForAutoSave() {
        for index in state.openTabs.indices {
            guard state.openTabs[index].isModified else { continue }
            _ = saveTab(at: index, allowSaveAsForUntitled: false)
        }
        saveSession()
    }

    private func saveTab(at index: Int, allowSaveAsForUntitled: Bool) -> Bool {
        guard index >= 0 && index < state.openTabs.count else { return false }

        let tab = state.openTabs[index]
        var pathToSave = tab.filePath

        if tab.filePath == EditorState.untitledPath {
            guard allowSaveAsForUntitled, let selectedPath = promptSavePath(defaultName: tab.fileName) else {
                return false
            }
            state.updateTabPath(at: index, newPath: selectedPath)
            pathToSave = selectedPath
        }

        do {
            try FileService.shared.writeFile(path: pathToSave, content: state.openTabs[index].content)
            state.markTabSaved(at: index)
            return true
        } catch {
            logger.error("Failed to save tab at path \(pathToSave, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func promptSavePath(defaultName: String) -> String? {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultName
        panel.title = "Save File"
        panel.message = "Choose a location to save this file."

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }
        return url.path
    }

    private func startAutoSave() {
        autoSaveService.startAutoSave {
            saveModifiedTabsForAutoSave()
        }
    }

    private func openFileFromDisk() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.title = "Open File"

        guard panel.runModal() == .OK, let fileURL = panel.url else { return }

        do {
            let fileContent = try FileService.shared.readFile(path: fileURL.path)
            state.openFile(fileURL.path, content: fileContent)
        } catch {
            logger.error("Failed to open file at path \(fileURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return
        }
    }

    private func openFilesFromExternalSource(_ filePaths: [String]) {
        for filePath in filePaths {
            do {
                let fileContent = try FileService.shared.readFile(path: filePath)
                logger.info("Opening external file at path \(filePath, privacy: .public)")
                state.openFile(filePath, content: fileContent)
            } catch {
                logger.error("Failed to open file at path \(filePath, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func openFilesFromProcessArguments() {
        let args = ProcessInfo.processInfo.arguments
        guard args.count > 1 else { return }

        let fileArgs = args
            .dropFirst()
            .filter { !$0.hasPrefix("-") }
            .filter { FileService.shared.fileExists(path: $0) }

        if !fileArgs.isEmpty {
            openFilesFromExternalSource(fileArgs)
        }
    }

    private func activateAppWindow() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first { $0.canBecomeKey }?.makeKeyAndOrderFront(nil)
        }
    }

    private func makePromptController() -> EditedFilePromptController {
        EditedFilePromptController(
            promptService: promptService,
            saveDocument: { index in
                self.saveTab(at: index, allowSaveAsForUntitled: true)
            },
            discardDocument: discardChangesForSessionPersistence
        )
    }

    private func discardChangesForSessionPersistence(at index: Int) {
        guard index >= 0 && index < state.openTabs.count else { return }

        let tab = state.openTabs[index]
        if tab.filePath == EditorState.untitledPath {
            state.closeTab(at: index)
            return
        }

        do {
            let currentCursor = state.openTabs[index].cursorPosition
            let persistedContent = try FileService.shared.readFile(path: tab.filePath)
            state.restoreContent(tabIndex: index, content: persistedContent)
            state.updateCursorPosition(
                tabIndex: index,
                position: min(currentCursor, (persistedContent as NSString).length)
            )
        } catch {
            logger.error("Failed to discard changes for path \(tab.filePath, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func confirmWindowClose() -> Bool {
        makePromptController().confirmCloseAll(in: state)
    }

    private func confirmApplicationTermination() -> NSApplication.TerminateReply {
        confirmWindowClose() ? .terminateNow : .terminateCancel
    }
}
