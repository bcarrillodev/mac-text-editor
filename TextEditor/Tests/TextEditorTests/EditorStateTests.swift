import XCTest
@testable import TextEditor

class EditorStateTests: XCTestCase {
    var state: EditorState!
    
    override func setUp() {
        super.setUp()
        state = EditorState()
    }
    
    func testOpenFile() {
        state.openFile("/tmp/file1.txt")
        XCTAssertEqual(state.openTabs.count, 1)
        XCTAssertEqual(state.openTabs[0].filePath, "/tmp/file1.txt")
        XCTAssertEqual(state.activeTabIndex, 0)
    }
    
    func testOpenMultipleFiles() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        XCTAssertEqual(state.openTabs.count, 2)
        XCTAssertEqual(state.activeTabIndex, 1)
    }
    
    func testOpenDuplicateFile() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file1.txt")
        XCTAssertEqual(state.openTabs.count, 1)
    }
    
    func testCloseTab() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        XCTAssertEqual(state.openTabs.count, 2)
        
        state.closeTab(at: 0)
        XCTAssertEqual(state.openTabs.count, 1)
        XCTAssertEqual(state.openTabs[0].filePath, "/tmp/file2.txt")
    }
    
    func testCloseTabAdjustsActiveIndex() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        state.openFile("/tmp/file3.txt")
        
        state.closeTab(at: 2)
        XCTAssertEqual(state.activeTabIndex, 1)
    }
    
    func testSwitchToTab() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        XCTAssertEqual(state.activeTabIndex, 1)
        
        state.switchToTab(index: 0)
        XCTAssertEqual(state.activeTabIndex, 0)
    }
    
    func testUpdateContent() {
        state.openFile("/tmp/file1.txt")
        state.updateContent(tabIndex: 0, content: "New content")
        
        XCTAssertEqual(state.openTabs[0].content, "New content")
        XCTAssertTrue(state.openTabs[0].isModified)
        XCTAssertTrue(state.unsavedChanges["/tmp/file1.txt"] ?? false)
    }
    
    func testGetActiveTab() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        
        let activeTab = state.getActiveTab()
        XCTAssertEqual(activeTab?.filePath, "/tmp/file2.txt")
    }
    
    func testMarkAllSaved() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        state.updateContent(tabIndex: 0, content: "content1")
        state.updateContent(tabIndex: 1, content: "content2")
        
        XCTAssertTrue(state.unsavedChanges.count > 0)
        
        state.markAllSaved()
        XCTAssertFalse(state.openTabs[0].isModified)
        XCTAssertFalse(state.openTabs[1].isModified)
        XCTAssertEqual(state.unsavedChanges.count, 0)
    }
}
