import Testing
@testable import TextEditor

@Suite("EditorState")
struct EditorStateTests {
    private func makeState() -> EditorState {
        EditorState()
    }

    @Test("Open file")
    func openFile() {
        let state = makeState()
        state.openFile("/tmp/file1.txt", content: "Hello")

        #expect(state.openTabs.count == 1)
        #expect(state.openTabs[0].filePath == "/tmp/file1.txt")
        #expect(state.openTabs[0].content == "Hello")
        #expect(state.activeTabIndex == 0)
    }

    @Test("Open multiple files")
    func openMultipleFiles() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")

        #expect(state.openTabs.count == 2)
        #expect(state.activeTabIndex == 1)
    }

    @Test("Open duplicate file")
    func openDuplicateFile() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file1.txt")

        #expect(state.openTabs.count == 1)
    }

    @Test("Open duplicate switches to existing tab")
    func openDuplicateFileSwitchesToExistingTab() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        #expect(state.activeTabIndex == 1)

        state.openFile("/tmp/file1.txt")

        #expect(state.openTabs.count == 2)
        #expect(state.activeTabIndex == 0)
    }

    @Test("Close tab")
    func closeTab() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        #expect(state.openTabs.count == 2)

        state.closeTab(at: 0)

        #expect(state.openTabs.count == 1)
        #expect(state.openTabs[0].filePath == "/tmp/file2.txt")
    }

    @Test("Close tab adjusts active index")
    func closeTabAdjustsActiveIndex() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        state.openFile("/tmp/file3.txt")

        state.closeTab(at: 2)
        #expect(state.activeTabIndex == 1)
    }

    @Test("Switch to tab")
    func switchToTab() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        #expect(state.activeTabIndex == 1)

        state.switchToTab(index: 0)
        #expect(state.activeTabIndex == 0)
    }

    @Test("Update content marks modified")
    func updateContent() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.updateContent(tabIndex: 0, content: "New content")

        #expect(state.openTabs[0].content == "New content")
        #expect(state.openTabs[0].isModified)
        #expect(state.unsavedChanges["/tmp/file1.txt"] == true)
    }

    @Test("Get active tab")
    func getActiveTab() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")

        #expect(state.getActiveTab()?.filePath == "/tmp/file2.txt")
    }

    @Test("Mark all saved")
    func markAllSaved() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        state.updateContent(tabIndex: 0, content: "content1")
        state.updateContent(tabIndex: 1, content: "content2")

        #expect(state.unsavedChanges.count > 0)

        state.markAllSaved()
        #expect(state.openTabs[0].isModified == false)
        #expect(state.openTabs[1].isModified == false)
        #expect(state.unsavedChanges.count == 0)
    }

    @Test("Close tab removes unsaved marker")
    func closeTabRemovesUnsavedMarker() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.updateContent(tabIndex: 0, content: "content1")
        #expect(state.unsavedChanges["/tmp/file1.txt"] == true)

        state.closeTab(at: 0)

        #expect(state.unsavedChanges["/tmp/file1.txt"] == nil)
    }

    @Test("Mark tab saved only clears specified tab")
    func markTabSavedOnlyClearsSpecifiedTab() {
        let state = makeState()
        state.openFile("/tmp/file1.txt")
        state.openFile("/tmp/file2.txt")
        state.updateContent(tabIndex: 0, content: "content1")
        state.updateContent(tabIndex: 1, content: "content2")

        state.markTabSaved(at: 0)

        #expect(state.openTabs[0].isModified == false)
        #expect(state.openTabs[1].isModified)
        #expect(state.unsavedChanges["/tmp/file1.txt"] == nil)
        #expect(state.unsavedChanges["/tmp/file2.txt"] == true)
    }

    @Test("Update tab path moves unsaved marker")
    func updateTabPathMovesUnsavedMarker() {
        let state = makeState()
        state.createUntitledFile()
        state.updateContent(tabIndex: 0, content: "Draft")
        #expect(state.unsavedChanges["untitled"] == true)

        state.updateTabPath(at: 0, newPath: "/tmp/saved.txt")

        #expect(state.openTabs[0].filePath == "/tmp/saved.txt")
        #expect(state.openTabs[0].fileName == "saved.txt")
        #expect(state.unsavedChanges["untitled"] == nil)
        #expect(state.unsavedChanges["/tmp/saved.txt"] == true)
    }

    @Test("Find match count case sensitive")
    func findMatchCountCaseSensitive() {
        let state = makeState()
        state.openFile("/tmp/file1.txt", content: "Hello hello HELLO")

        #expect(state.findMatchCount(inActiveTab: "Hello") == 1)
        #expect(state.findMatchCount(inActiveTab: "hello") == 1)
        #expect(state.findMatchCount(inActiveTab: "HELLO") == 1)
    }

    @Test("Find match count case insensitive")
    func findMatchCountCaseInsensitive() {
        let state = makeState()
        state.openFile("/tmp/file1.txt", content: "Hello hello HELLO")

        #expect(state.findMatchCount(inActiveTab: "hello", caseSensitive: false) == 3)
    }

    @Test("Replace next in active tab")
    func replaceNextInActiveTab() {
        let state = makeState()
        state.openFile("/tmp/file1.txt", content: "cat cat cat")

        let replaced = state.replaceNextInActiveTab(find: "cat", with: "dog")

        #expect(replaced)
        #expect(state.openTabs[0].content == "dog cat cat")
        #expect(state.openTabs[0].isModified)
    }

    @Test("Replace all in active tab")
    func replaceAllInActiveTab() {
        let state = makeState()
        state.openFile("/tmp/file1.txt", content: "cat cat cat")

        let replacedCount = state.replaceAllInActiveTab(find: "cat", with: "dog")

        #expect(replacedCount == 3)
        #expect(state.openTabs[0].content == "dog dog dog")
        #expect(state.openTabs[0].isModified)
    }

    @Test("Replace all in active tab no match")
    func replaceAllInActiveTabNoMatch() {
        let state = makeState()
        state.openFile("/tmp/file1.txt", content: "cat cat cat")

        let replacedCount = state.replaceAllInActiveTab(find: "bird", with: "dog")

        #expect(replacedCount == 0)
        #expect(state.openTabs[0].content == "cat cat cat")
    }
}
