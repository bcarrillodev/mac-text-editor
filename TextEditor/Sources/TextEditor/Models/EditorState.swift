import Foundation

class EditorState: ObservableObject {
    static let untitledPath = "untitled"
    static let untitledName = "Untitled"

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
        guard isValidTabIndex(index) else { return }
        let removedPath = openTabs[index].filePath
        openTabs.remove(at: index)
        unsavedChanges.removeValue(forKey: removedPath)
        if activeTabIndex >= openTabs.count {
            activeTabIndex = max(0, openTabs.count - 1)
        }
    }

    func switchToTab(index: Int) {
        guard isValidTabIndex(index) else { return }
        activeTabIndex = index
    }

    func updateContent(tabIndex: Int, content: String) {
        guard isValidTabIndex(tabIndex) else { return }
        guard openTabs[tabIndex].content != content else { return }
        openTabs[tabIndex].content = content
        markTabModified(at: tabIndex)
    }

    func getActiveTab() -> FileDocument? {
        guard isValidTabIndex(activeTabIndex) else { return nil }
        return openTabs[activeTabIndex]
    }

    func createUntitledFile() {
        let doc = FileDocument(filePath: Self.untitledPath, content: "", fileName: Self.untitledName)
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
        guard isValidTabIndex(index) else { return }
        openTabs[index].isModified = false
        unsavedChanges.removeValue(forKey: openTabs[index].filePath)
    }

    func updateTabPath(at index: Int, newPath: String) {
        guard isValidTabIndex(index) else { return }

        let oldPath = openTabs[index].filePath
        let wasUnsaved = unsavedChanges.removeValue(forKey: oldPath) ?? false

        openTabs[index].filePath = newPath
        openTabs[index].fileName = (newPath as NSString).lastPathComponent

        if wasUnsaved {
            unsavedChanges[newPath] = true
        }
    }

    func findMatchCount(inActiveTab query: String, caseSensitive: Bool = true) -> Int {
        guard !query.isEmpty else { return 0 }
        guard let tab = getActiveTab() else { return 0 }

        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        var count = 0
        var searchRange = tab.content.startIndex..<tab.content.endIndex

        while let range = tab.content.range(of: query, options: options, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<tab.content.endIndex
        }

        return count
    }

    @discardableResult
    func replaceAllInActiveTab(find query: String, with replacement: String, caseSensitive: Bool = true) -> Int {
        guard !query.isEmpty else { return 0 }
        guard isValidTabIndex(activeTabIndex) else { return 0 }

        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        let matchCount = findMatchCount(inActiveTab: query, caseSensitive: caseSensitive)
        guard matchCount > 0 else { return 0 }

        let updated = openTabs[activeTabIndex].content.replacingOccurrences(of: query, with: replacement, options: options)
        updateContent(tabIndex: activeTabIndex, content: updated)
        return matchCount
    }

    @discardableResult
    func replaceNextInActiveTab(find query: String, with replacement: String, caseSensitive: Bool = true) -> Bool {
        guard !query.isEmpty else { return false }
        guard isValidTabIndex(activeTabIndex) else { return false }

        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        let original = openTabs[activeTabIndex].content
        guard let range = original.range(of: query, options: options) else { return false }

        var updated = original
        updated.replaceSubrange(range, with: replacement)
        updateContent(tabIndex: activeTabIndex, content: updated)
        return true
    }

    func updateCursorPosition(tabIndex: Int, position: Int) {
        guard isValidTabIndex(tabIndex) else { return }
        openTabs[tabIndex].cursorPosition = position
    }

    private func isValidTabIndex(_ index: Int) -> Bool {
        index >= 0 && index < openTabs.count
    }

    private func markTabModified(at index: Int) {
        openTabs[index].isModified = true
        unsavedChanges[openTabs[index].filePath] = true
    }
}
