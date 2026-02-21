import XCTest
@testable import TextEditor

class SessionPersistenceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        SessionPersistenceService.shared.clearSession()
    }
    
    override func tearDown() {
        SessionPersistenceService.shared.clearSession()
        super.tearDown()
    }
    
    func testSaveSession() throws {
        let state = EditorState()
        state.openTabs = [
            FileDocument(filePath: "/tmp/file1.txt", content: "Content 1", fileName: "file1.txt"),
            FileDocument(filePath: "/tmp/file2.txt", content: "Content 2", fileName: "file2.txt")
        ]
        state.activeTabIndex = 1
        
        try SessionPersistenceService.shared.saveSession(state: state)
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "EditorSession"))
    }
    
    func testLoadSessionExists() throws {
        let state = EditorState()
        state.openTabs = [
            FileDocument(filePath: "/tmp/file1.txt", content: "Content 1", fileName: "file1.txt")
        ]
        state.activeTabIndex = 0
        
        try SessionPersistenceService.shared.saveSession(state: state)
        
        let loadedState = SessionPersistenceService.shared.loadSession()
        XCTAssertNotNil(loadedState)
        XCTAssertEqual(loadedState?.openTabs.count, 1)
        XCTAssertEqual(loadedState?.activeTabIndex, 0)
    }
    
    func testLoadSessionNone() {
        SessionPersistenceService.shared.clearSession()
        let loadedState = SessionPersistenceService.shared.loadSession()
        XCTAssertNil(loadedState)
    }
    
    func testClearSession() throws {
        let state = EditorState()
        state.openTabs = [
            FileDocument(filePath: "/tmp/file1.txt", content: "Content 1")
        ]
        
        try SessionPersistenceService.shared.saveSession(state: state)
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "EditorSession"))
        
        SessionPersistenceService.shared.clearSession()
        XCTAssertNil(UserDefaults.standard.data(forKey: "EditorSession"))
    }
    
    func testRestoreCursorPositions() throws {
        let state = EditorState()
        var doc = FileDocument(filePath: "/tmp/file1.txt", content: "Content 1")
        doc.cursorPosition = 42
        state.openTabs = [doc]
        state.activeTabIndex = 0
        
        try SessionPersistenceService.shared.saveSession(state: state)
        
        let loadedState = SessionPersistenceService.shared.loadSession()
        XCTAssertEqual(loadedState?.openTabs.first?.cursorPosition, 42)
    }
}
