import AppKit

enum SavePromptDecision {
    case save
    case discard
    case cancel
}

protocol SavePrompting {
    func promptToSave(documentName: String) -> SavePromptDecision
}

struct SavePromptService: SavePrompting {
    func promptToSave(documentName: String) -> SavePromptDecision {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Do you want to save the changes made to \(documentName)?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .save
        case .alertSecondButtonReturn:
            return .discard
        default:
            return .cancel
        }
    }
}
