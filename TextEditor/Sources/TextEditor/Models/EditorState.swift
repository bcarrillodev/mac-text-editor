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
        openTabs.remove(at: index)
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
        openTabs[tabIndex].content = content
        openTabs[tabIndex].isModified = true
        unsavedChanges[openTabs[tabIndex].filePath] = true
    }
    
    func getActiveTab() -> FileDocument? {
        guard activeTabIndex >= 0 && activeTabIndex < openTabs.count else { return nil }
        return openTabs[activeTabIndex]
    }
    
    func markAllSaved() {
        for i in 0..<openTabs.count {
            openTabs[i].isModified = false
        }
        unsavedChanges.removeAll()
    }
}
