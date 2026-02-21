import Foundation

class FileService {
    static let shared = FileService()
    
    func readFile(path: String) throws -> String {
        let url = URL(fileURLWithPath: path)
        let content = try String(contentsOf: url, encoding: .utf8)
        return content
    }
    
    func writeFile(path: String, content: String) throws {
        let url = URL(fileURLWithPath: path)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func fileExists(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    func createNewFile(path: String, initialContent: String = "") throws {
        if !fileExists(path: path) {
            try initialContent.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
