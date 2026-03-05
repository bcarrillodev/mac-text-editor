import Foundation
import Testing
@testable import TextEditor

@Suite("NativeTextEditor Backspace")
struct NativeTextEditorBackspaceTests {
    @Test("Blocks backspace line merge on non-last line")
    func blocksBackspaceMergeOnNonLastLine() {
        let text = "one\ntwo\nthree" as NSString
        let shouldBlock = NativeTextEditor.Coordinator.shouldPreventBackspaceLineMerge(
            in: text,
            selectionRange: NSRange(location: 4, length: 0),
            affectedCharRange: NSRange(location: 3, length: 1),
            replacementString: ""
        )

        #expect(shouldBlock)
    }

    @Test("Allows backspace line merge on last line")
    func allowsBackspaceMergeOnLastLine() {
        let text = "one\ntwo\nthree" as NSString
        let shouldBlock = NativeTextEditor.Coordinator.shouldPreventBackspaceLineMerge(
            in: text,
            selectionRange: NSRange(location: 8, length: 0),
            affectedCharRange: NSRange(location: 7, length: 1),
            replacementString: ""
        )

        #expect(shouldBlock == false)
    }

    @Test("Does not block regular character deletion")
    func doesNotBlockRegularCharacterDeletion() {
        let text = "one\ntwo\nthree" as NSString
        let shouldBlock = NativeTextEditor.Coordinator.shouldPreventBackspaceLineMerge(
            in: text,
            selectionRange: NSRange(location: 6, length: 0),
            affectedCharRange: NSRange(location: 5, length: 1),
            replacementString: ""
        )

        #expect(shouldBlock == false)
    }

    @Test("Backspace target moves caret to previous line")
    func backspaceTargetMovesCaretToPreviousLine() {
        let text = "one\ntwo\nthree" as NSString
        let target = NativeTextEditor.Coordinator.backspaceNavigationTarget(
            in: text,
            cursorLocation: 4
        )

        #expect(target == 0)
    }

    @Test("Backspace target is nil on first line")
    func backspaceTargetIsNilOnFirstLine() {
        let text = "one\ntwo\nthree" as NSString
        let target = NativeTextEditor.Coordinator.backspaceNavigationTarget(
            in: text,
            cursorLocation: 0
        )

        #expect(target == nil)
    }
}
