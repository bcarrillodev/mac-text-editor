import Foundation
import Testing
@testable import TextEditor

@Suite("SessionPersistence")
struct SessionPersistenceTests {
    private func makeIsolatedService() -> (SessionPersistenceService, UserDefaults, String, String) {
        let suiteName = "SessionPersistenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let key = "EditorSession.\(UUID().uuidString)"
        let service = SessionPersistenceService(sessionKey: key, userDefaults: defaults)
        return (service, defaults, key, suiteName)
    }

    @Test("Save session")
    func saveSession() throws {
        let (service, defaults, key, suiteName) = makeIsolatedService()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = EditorState()
        state.openTabs = [
            FileDocument(filePath: "/tmp/file1.txt", content: "Content 1", fileName: "file1.txt"),
            FileDocument(filePath: "/tmp/file2.txt", content: "Content 2", fileName: "file2.txt")
        ]
        state.activeTabIndex = 1

        try service.saveSession(state: state)
        #expect(defaults.data(forKey: key) != nil)
    }

    @Test("Load session exists")
    func loadSessionExists() throws {
        let (service, defaults, _, suiteName) = makeIsolatedService()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = EditorState()
        state.openTabs = [
            FileDocument(filePath: "/tmp/file1.txt", content: "Content 1", fileName: "file1.txt")
        ]
        state.activeTabIndex = 0

        try service.saveSession(state: state)

        let loadedState = service.loadSession()
        #expect(loadedState != nil)
        #expect(loadedState?.openTabs.count == 1)
        #expect(loadedState?.activeTabIndex == 0)
    }

    @Test("Load session none")
    func loadSessionNone() {
        let (service, defaults, _, suiteName) = makeIsolatedService()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let loadedState = service.loadSession()
        #expect(loadedState == nil)
    }

    @Test("Clear session")
    func clearSession() throws {
        let (service, defaults, key, suiteName) = makeIsolatedService()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = EditorState()
        state.openTabs = [
            FileDocument(filePath: "/tmp/file1.txt", content: "Content 1")
        ]

        try service.saveSession(state: state)
        #expect(defaults.data(forKey: key) != nil)

        service.clearSession()
        #expect(defaults.data(forKey: key) == nil)
    }

    @Test("Restore cursor positions")
    func restoreCursorPositions() throws {
        let (service, defaults, _, suiteName) = makeIsolatedService()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = EditorState()
        var doc = FileDocument(filePath: "/tmp/file1.txt", content: "Content 1")
        doc.cursorPosition = 42
        state.openTabs = [doc]
        state.activeTabIndex = 0

        try service.saveSession(state: state)

        let loadedState = service.loadSession()
        #expect(loadedState?.openTabs.first?.cursorPosition == 42)
    }
}
