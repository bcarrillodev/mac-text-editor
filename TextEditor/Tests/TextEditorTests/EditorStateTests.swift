import XCTest
@testable import TextEditor

class EditorStateTests: XCTestCase {
    var state: EditorState!
    
    override func setUp() {
        super.setUp()
        state = EditorState()
    }
    
    func testOpenFile() {
        state.openFile("/tmp/file1.txt", content: "Hello")
        XCTAssertEqual(state.openTabs.count, 1)
        XCTAssertEqual(state.openTabs[0].filePath, "/tmp/file1.txt")
        XCTAssertEqual(state.openTabs[0].content, "Hello")
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

    func testOpenDuplicateFileSwitchesToExistingTab() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        XCTAssertEqual(state.activeTabIndex, 1)

        state.openFile("/tmp/file1.txt")

        XCTAssertEqual(state.openTabs.count, 2)
        XCTAssertEqual(state.activeTabIndex, 0)
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

    func testCloseTabRemovesUnsavedMarker() {
        state.openFile("/tmp/file1.txt")
        state.updateContent(tabIndex: 0, content: "content1")
        XCTAssertTrue(state.unsavedChanges["/tmp/file1.txt"] ?? false)

        state.closeTab(at: 0)

        XCTAssertNil(state.unsavedChanges["/tmp/file1.txt"])
    }

    func testMarkTabSavedOnlyClearsSpecifiedTab() {
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        state.updateContent(tabIndex: 0, content: "content1")
        state.updateContent(tabIndex: 1, content: "content2")

        state.markTabSaved(at: 0)

        XCTAssertFalse(state.openTabs[0].isModified)
        XCTAssertTrue(state.openTabs[1].isModified)
        XCTAssertNil(state.unsavedChanges["/tmp/file1.txt"])
        XCTAssertTrue(state.unsavedChanges["/tmp/file2.txt"] ?? false)
    }

    func testUpdateTabPathMovesUnsavedMarker() {
        state.createUntitledFile()
        state.updateContent(tabIndex: 0, content: "Draft")
        XCTAssertTrue(state.unsavedChanges["untitled"] ?? false)

        state.updateTabPath(at: 0, newPath: "/tmp/saved.txt")

        XCTAssertEqual(state.openTabs[0].filePath, "/tmp/saved.txt")
        XCTAssertEqual(state.openTabs[0].fileName, "saved.txt")
        XCTAssertNil(state.unsavedChanges["untitled"])
        XCTAssertTrue(state.unsavedChanges["/tmp/saved.txt"] ?? false)
    }

    func testFindMatchCountCaseSensitive() {
        state.openFile("/tmp/file1.txt", content: "Hello hello HELLO")

        XCTAssertEqual(state.findMatchCount(inActiveTab: "Hello"), 1)
        XCTAssertEqual(state.findMatchCount(inActiveTab: "hello"), 1)
        XCTAssertEqual(state.findMatchCount(inActiveTab: "HELLO"), 1)
    }

    func testFindMatchCountCaseInsensitive() {
        state.openFile("/tmp/file1.txt", content: "Hello hello HELLO")

        XCTAssertEqual(state.findMatchCount(inActiveTab: "hello", caseSensitive: false), 3)
    }

    func testReplaceNextInActiveTab() {
        state.openFile("/tmp/file1.txt", content: "cat cat cat")

        let replaced = state.replaceNextInActiveTab(find: "cat", with: "dog")

        XCTAssertTrue(replaced)
        XCTAssertEqual(state.openTabs[0].content, "dog cat cat")
        XCTAssertTrue(state.openTabs[0].isModified)
    }

    func testReplaceAllInActiveTab() {
        state.openFile("/tmp/file1.txt", content: "cat cat cat")

        let replacedCount = state.replaceAllInActiveTab(find: "cat", with: "dog")

        XCTAssertEqual(replacedCount, 3)
        XCTAssertEqual(state.openTabs[0].content, "dog dog dog")
        XCTAssertTrue(state.openTabs[0].isModified)
    }

    func testReplaceAllInActiveTabNoMatch() {
        state.openFile("/tmp/file1.txt", content: "cat cat cat")

        let replacedCount = state.replaceAllInActiveTab(find: "bird", with: "dog")

        XCTAssertEqual(replacedCount, 0)
        XCTAssertEqual(state.openTabs[0].content, "cat cat cat")
    }
}
