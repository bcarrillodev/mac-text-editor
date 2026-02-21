import Foundation

struct FileDocument: Identifiable, Codable {
    let id: UUID
    var filePath: String
    var content: String
    var fileName: String
    var isModified: Bool
    var cursorPosition: Int
    
    init(filePath: String, content: String = "", fileName: String? = nil, cursorPosition: Int = 0) {
        self.id = UUID()
        self.filePath = filePath
        self.content = content
        self.fileName = fileName ?? (filePath as NSString).lastPathComponent
        self.isModified = false
        self.cursorPosition = cursorPosition
    }
}
