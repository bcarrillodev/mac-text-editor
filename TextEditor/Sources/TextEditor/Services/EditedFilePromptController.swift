import Foundation

final class EditedFilePromptController {
    private let promptService: SavePrompting
    private let saveDocument: (Int) -> Bool
    private let discardDocument: (Int) -> Void

    init(
        promptService: SavePrompting,
        saveDocument: @escaping (Int) -> Bool,
        discardDocument: @escaping (Int) -> Void
    ) {
        self.promptService = promptService
        self.saveDocument = saveDocument
        self.discardDocument = discardDocument
    }

    func confirmCloseTab(in state: EditorState, at index: Int) -> Bool {
        guard index >= 0, index < state.openTabs.count else { return false }
        guard state.openTabs[index].isModified else { return true }

        switch promptService.promptToSave(documentName: state.openTabs[index].fileName) {
        case .save:
            return saveDocument(index)
        case .discard:
            return true
        case .cancel:
            return false
        }
    }

    func confirmCloseAll(in state: EditorState) -> Bool {
        var index = state.openTabs.count - 1
        while index >= 0 {
            guard index < state.openTabs.count else {
                index -= 1
                continue
            }

            let tab = state.openTabs[index]
            guard tab.isModified else {
                index -= 1
                continue
            }

            switch promptService.promptToSave(documentName: tab.fileName) {
            case .save:
                guard saveDocument(index) else { return false }
            case .discard:
                discardDocument(index)
            case .cancel:
                return false
            }

            index -= 1
        }

        return true
    }
}
