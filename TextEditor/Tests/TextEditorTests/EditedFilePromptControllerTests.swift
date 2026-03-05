import Foundation
import Testing
@testable import TextEditor

@Suite("EditedFilePromptController")
struct EditedFilePromptControllerTests {
    @Test("Modified tab save decision requires a successful save")
    func modifiedTabSaveDecisionRequiresSuccessfulSave() {
        let state = EditorState()
        state.openFile("/tmp/file1.txt", content: "original")
        state.updateContent(tabIndex: 0, content: "edited")

        let promptService = StubPromptService(decisions: [.save])
        var saveCalls: [Int] = []

        let controller = EditedFilePromptController(
            promptService: promptService,
            saveDocument: { index in
                saveCalls.append(index)
                return true
            },
            discardDocument: { _ in Issue.record("Discard should not run") }
        )

        #expect(controller.confirmCloseTab(in: state, at: 0))
        #expect(saveCalls == [0])
    }

    @Test("Modified tab cancel decision keeps the tab open")
    func modifiedTabCancelDecisionKeepsTabOpen() {
        let state = EditorState()
        state.openFile("/tmp/file1.txt", content: "original")
        state.updateContent(tabIndex: 0, content: "edited")

        let controller = EditedFilePromptController(
            promptService: StubPromptService(decisions: [.cancel]),
            saveDocument: { _ in
                Issue.record("Save should not run")
                return true
            },
            discardDocument: { _ in Issue.record("Discard should not run") }
        )

        #expect(controller.confirmCloseTab(in: state, at: 0) == false)
    }

    @Test("Close all discards each modified tab")
    func closeAllDiscardsEachModifiedTab() {
        let state = EditorState()
        state.openFile("/tmp/file1.txt", content: "one")
        state.openFile("/tmp/file2.txt", content: "two")
        state.updateContent(tabIndex: 0, content: "one edited")
        state.updateContent(tabIndex: 1, content: "two edited")

        var discardedIndices: [Int] = []
        let controller = EditedFilePromptController(
            promptService: StubPromptService(decisions: [.discard, .discard]),
            saveDocument: { _ in
                Issue.record("Save should not run")
                return true
            },
            discardDocument: { index in
                discardedIndices.append(index)
            }
        )

        #expect(controller.confirmCloseAll(in: state))
        #expect(discardedIndices == [1, 0])
    }

    @Test("Close all stops when a prompt is cancelled")
    func closeAllStopsWhenPromptCancelled() {
        let state = EditorState()
        state.openFile("/tmp/file1.txt", content: "one")
        state.openFile("/tmp/file2.txt", content: "two")
        state.updateContent(tabIndex: 0, content: "one edited")
        state.updateContent(tabIndex: 1, content: "two edited")

        var discardedIndices: [Int] = []
        let controller = EditedFilePromptController(
            promptService: StubPromptService(decisions: [.discard, .cancel]),
            saveDocument: { _ in
                Issue.record("Save should not run")
                return true
            },
            discardDocument: { index in
                discardedIndices.append(index)
            }
        )

        #expect(controller.confirmCloseAll(in: state) == false)
        #expect(discardedIndices == [1])
    }
}

private struct StubPromptService: SavePrompting {
    let decisions: [SavePromptDecision]
    private let fallbackDecision: SavePromptDecision
    private let counter = LockedCounter()

    init(decisions: [SavePromptDecision], fallbackDecision: SavePromptDecision = .cancel) {
        self.decisions = decisions
        self.fallbackDecision = fallbackDecision
    }

    func promptToSave(documentName: String) -> SavePromptDecision {
        let index = counter.next()
        guard index < decisions.count else { return fallbackDecision }
        return decisions[index]
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let current = value
        value += 1
        return current
    }
}
