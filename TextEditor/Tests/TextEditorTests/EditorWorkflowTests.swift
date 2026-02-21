import XCTest
@testable import TextEditor

class EditorWorkflowTests: XCTestCase {
    let testFilePath = NSTemporaryDirectory() + "workflow_test.txt"
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testFilePath)
        SessionPersistenceService.shared.clearSession()
        super.tearDown()
    }
    
    func testOpenEditSaveRestoreWorkflow() throws {
        // Create a test file
        try FileService.shared.createNewFile(path: testFilePath, initialContent: "Initial content")
        
        // Step 1: Open file
        let state = EditorState()
        state.openFile(testFilePath)
        XCTAssertEqual(state.openTabs.count, 1)
        
        // Step 2: Edit content
        state.updateContent(tabIndex: 0, content: "Edited content")
        XCTAssertTrue(state.openTabs[0].isModified)
        
        // Step 3: Save to file
        try FileService.shared.writeFile(path: testFilePath, content: "Edited content")
        state.markAllSaved()
        
        // Step 4: Save session
        try SessionPersistenceService.shared.saveSession(state: state)
        
        // Step 5: Load session (simulating app restart)
        SessionPersistenceService.shared.clearSession()
        let restoredState = SessionPersistenceService.shared.loadSession()
        
        XCTAssertNotNil(restoredState)
        XCTAssertEqual(restoredState?.openTabs.count, 1)
        XCTAssertEqual(restoredState?.openTabs[0].filePath, testFilePath)
    }
    
    func testMultipleTabsWorkflow() throws {
        let file1 = NSTemporaryDirectory() + "file1.txt"
        let file2 = NSTemporaryDirectory() + "file2.txt"
        
        defer {
            try? FileManager.default.removeItem(atPath: file1)
            try? FileManager.default.removeItem(atPath: file2)
        }
        
        try FileService.shared.createNewFile(path: file1, initialContent: "File 1")
        try FileService.shared.createNewFile(path: file2, initialContent: "File 2")
        
        let state = EditorState()
        state.openFile(file1)
        state.openFile(file2)
        
        XCTAssertEqual(state.openTabs.count, 2)
        XCTAssertEqual(state.activeTabIndex, 1)
        
        state.switchToTab(index: 0)
        XCTAssertEqual(state.activeTabIndex, 0)
    }
    
    func testContentPersistenceAcrossRestarts() throws {
        let testContent = "Persistent content"
        try FileService.shared.createNewFile(path: testFilePath, initialContent: "")
        
        let state1 = EditorState()
        state1.openFile(testFilePath)
        state1.updateContent(tabIndex: 0, content: testContent)
        try FileService.shared.writeFile(path: testFilePath, content: testContent)
        try SessionPersistenceService.shared.saveSession(state: state1)
        
        // Simulate restart
        SessionPersistenceService.shared.clearSession()
        let restoredState = SessionPersistenceService.shared.loadSession()
        
        XCTAssertEqual(restoredState?.openTabs[0].content, testContent)
    }
}
