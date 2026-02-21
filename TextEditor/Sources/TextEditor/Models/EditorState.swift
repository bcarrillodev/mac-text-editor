import Foundation

class EditorState: ObservableObject {
    @Published var openTabs: [FileDocument] = []
    @Published var activeTabIndex: Int = 0
    @Published var unsavedChanges: [String: Bool] = [:]
    
    func openFile(_ path: String, content: String = "") {
        if let existingIndex = openTabs.firstIndex(where: { $0.filePath == path }) {
            activeTabIndex = existingIndex
            return
        }

        let doc = FileDocument(filePath: path, content: content)
        openTabs.append(doc)
        activeTabIndex = openTabs.count - 1
    }
    
    func closeTab(at index: Int) {
        guard index >= 0 && index < openTabs.count else { return }
        let removedPath = openTabs[index].filePath
        openTabs.remove(at: index)
        unsavedChanges.removeValue(forKey: removedPath)
        if activeTabIndex >= openTabs.count {
            activeTabIndex = max(0, openTabs.count - 1)
        }
    }
    
    func switchToTab(index: Int) {
        guard index >= 0 && index < openTabs.count else { return }
        activeTabIndex = index
    }
    
    func updateContent(tabIndex: Int, content: String) {
        guard tabIndex >= 0 && tabIndex < openTabs.count else { return }
        guard openTabs[tabIndex].content != content else { return }
        openTabs[tabIndex].content = content
        openTabs[tabIndex].isModified = true
        unsavedChanges[openTabs[tabIndex].filePath] = true
    }
    
    func getActiveTab() -> FileDocument? {
        guard activeTabIndex >= 0 && activeTabIndex < openTabs.count else { return nil }
        return openTabs[activeTabIndex]
    }
    
    func createUntitledFile() {
        let doc = FileDocument(filePath: "untitled", content: "", fileName: "Untitled")
        openTabs.append(doc)
        activeTabIndex = openTabs.count - 1
    }

    func markAllSaved() {
        for i in 0..<openTabs.count {
            openTabs[i].isModified = false
        }
        unsavedChanges.removeAll()
    }

    func markTabSaved(at index: Int) {
        guard index >= 0 && index < openTabs.count else { return }
        openTabs[index].isModified = false
        unsavedChanges.removeValue(forKey: openTabs[index].filePath)
    }

    func updateTabPath(at index: Int, newPath: String) {
        guard index >= 0 && index < openTabs.count else { return }

        let oldPath = openTabs[index].filePath
        let wasUnsaved = unsavedChanges.removeValue(forKey: oldPath) ?? false

        openTabs[index].filePath = newPath
        openTabs[index].fileName = (newPath as NSString).lastPathComponent

        if wasUnsaved {
            unsavedChanges[newPath] = true
        }
    }
}
