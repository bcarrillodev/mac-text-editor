import SwiftUI
import AppKit
import OSLog

struct ContentView: View {
    private let logger = Logger(subsystem: "mac-text-editor", category: "ContentView")
    @StateObject private var state = EditorState()
    @StateObject private var autoSaveService = AutoSaveService()

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(
                state: state,
                onClose: closeTab,
                onSelect: selectTab,
                onAddTab: state.createUntitledFile
            )

            EditorView(state: state)
        }
        .frame(minWidth: 600, minHeight: 400)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    openFileFromDisk()
                } label: {
                    Image(systemName: "folder")
                }
                .keyboardShortcut("o", modifiers: .command)
                .help("Open File")

                Button("Save") {
                    saveActiveTab()
                }
                .keyboardShortcut("s", modifiers: .command)

            }
        }
        .onAppear {
            loadSession()
            startAutoSave()
            activateAppWindow()
        }
        .onDisappear {
            saveSession()
            autoSaveService.stopAutoSave()
        }
    }

    private func closeTab(_ index: Int) {
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
        saveTab(at: state.activeTabIndex, allowSaveAsForUntitled: true)
        saveSession()
    }

    private func saveModifiedTabsForAutoSave() {
        for index in state.openTabs.indices {
            guard state.openTabs[index].isModified else { continue }
            saveTab(at: index, allowSaveAsForUntitled: false)
        }
        saveSession()
    }

    private func saveTab(at index: Int, allowSaveAsForUntitled: Bool) {
        guard index >= 0 && index < state.openTabs.count else { return }

        let tab = state.openTabs[index]
        var pathToSave = tab.filePath

        if tab.filePath == EditorState.untitledPath {
            guard allowSaveAsForUntitled, let selectedPath = promptSavePath(defaultName: tab.fileName) else {
                return
            }
            state.updateTabPath(at: index, newPath: selectedPath)
            pathToSave = selectedPath
        }

        do {
            try FileService.shared.writeFile(path: pathToSave, content: state.openTabs[index].content)
            state.markTabSaved(at: index)
        } catch {
            logger.error("Failed to save tab at path \(pathToSave, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return
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

    private func activateAppWindow() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first { $0.canBecomeKey }?.makeKeyAndOrderFront(nil)
        }
    }
}
