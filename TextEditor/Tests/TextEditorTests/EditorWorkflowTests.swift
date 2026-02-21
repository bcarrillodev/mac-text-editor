import Foundation
import Testing
@testable import TextEditor

@Suite("EditorWorkflow")
struct EditorWorkflowTests {
    private func makeIsolatedService() -> (SessionPersistenceService, UserDefaults, String) {
        let suiteName = "EditorWorkflowTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let service = SessionPersistenceService(
            sessionKey: "EditorSession.\(UUID().uuidString)",
            userDefaults: defaults
        )
        return (service, defaults, suiteName)
    }

    @Test("Open, edit, save, restore workflow")
    func openEditSaveRestoreWorkflow() throws {
        let (service, defaults, suiteName) = makeIsolatedService()

        let testFilePath = NSTemporaryDirectory() + UUID().uuidString + "_workflow_test.txt"
        defer {
            try? FileManager.default.removeItem(atPath: testFilePath)
            defaults.removePersistentDomain(forName: suiteName)
        }

        try FileService.shared.createNewFile(path: testFilePath, initialContent: "Initial content")

        let state = EditorState()
        state.openFile(testFilePath)
        #expect(state.openTabs.count == 1)

        state.updateContent(tabIndex: 0, content: "Edited content")
        #expect(state.openTabs[0].isModified)

        try FileService.shared.writeFile(path: testFilePath, content: "Edited content")
        state.markAllSaved()

        try service.saveSession(state: state)

        let restoredState = service.loadSession()
        #expect(restoredState != nil)
        #expect(restoredState?.openTabs.count == 1)
        #expect(restoredState?.openTabs[0].filePath == testFilePath)
    }

    @Test("Multiple tabs workflow")
    func multipleTabsWorkflow() throws {
        let file1 = NSTemporaryDirectory() + UUID().uuidString + "_file1.txt"
        let file2 = NSTemporaryDirectory() + UUID().uuidString + "_file2.txt"

        defer {
            try? FileManager.default.removeItem(atPath: file1)
            try? FileManager.default.removeItem(atPath: file2)
        }

        try FileService.shared.createNewFile(path: file1, initialContent: "File 1")
        try FileService.shared.createNewFile(path: file2, initialContent: "File 2")

        let state = EditorState()
        state.openFile(file1)
        state.openFile(file2)

        #expect(state.openTabs.count == 2)
        #expect(state.activeTabIndex == 1)

        state.switchToTab(index: 0)
        #expect(state.activeTabIndex == 0)
    }

    @Test("Content persistence across restarts")
    func contentPersistenceAcrossRestarts() throws {
        let (service, defaults, suiteName) = makeIsolatedService()

        let testFilePath = NSTemporaryDirectory() + UUID().uuidString + "_workflow_test.txt"
        defer {
            try? FileManager.default.removeItem(atPath: testFilePath)
            defaults.removePersistentDomain(forName: suiteName)
        }

        let testContent = "Persistent content"
        try FileService.shared.createNewFile(path: testFilePath, initialContent: "")

        let state1 = EditorState()
        state1.openFile(testFilePath)
        state1.updateContent(tabIndex: 0, content: testContent)
        try FileService.shared.writeFile(path: testFilePath, content: testContent)
        try service.saveSession(state: state1)

        let restoredState = service.loadSession()
        #expect(restoredState?.openTabs[0].content == testContent)
    }
}
