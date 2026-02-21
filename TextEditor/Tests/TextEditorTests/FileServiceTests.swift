import Foundation
import Testing
@testable import TextEditor

@Suite("FileService")
struct FileServiceTests {
    @Test("Read file success")
    func readFileSuccess() throws {
        let testFilePath = NSTemporaryDirectory() + UUID().uuidString + "_test_file.txt"
        defer { try? FileManager.default.removeItem(atPath: testFilePath) }

        let content = "Hello, World!"
        try content.write(toFile: testFilePath, atomically: true, encoding: .utf8)

        let readContent = try FileService.shared.readFile(path: testFilePath)
        #expect(readContent == content)
    }

    @Test("Read file missing throws")
    func readFileMissing() {
        let missingPath = NSTemporaryDirectory() + UUID().uuidString + "_nonexistent.txt"
        var didThrow = false

        do {
            _ = try FileService.shared.readFile(path: missingPath)
        } catch {
            didThrow = true
        }

        #expect(didThrow)
    }

    @Test("Write file")
    func writeFile() throws {
        let testFilePath = NSTemporaryDirectory() + UUID().uuidString + "_test_file.txt"
        defer { try? FileManager.default.removeItem(atPath: testFilePath) }

        let content = "Test content"
        try FileService.shared.writeFile(path: testFilePath, content: content)

        let readContent = try String(contentsOfFile: testFilePath, encoding: .utf8)
        #expect(readContent == content)
    }

    @Test("File exists")
    func fileExists() {
        let testFilePath = NSTemporaryDirectory() + UUID().uuidString + "_test_file.txt"
        defer { try? FileManager.default.removeItem(atPath: testFilePath) }

        #expect(FileService.shared.fileExists(path: testFilePath) == false)

        try? "test".write(toFile: testFilePath, atomically: true, encoding: .utf8)
        #expect(FileService.shared.fileExists(path: testFilePath))
    }

    @Test("Create new file")
    func createNewFile() throws {
        let newPath = NSTemporaryDirectory() + UUID().uuidString + "_new_file.txt"
        defer { try? FileManager.default.removeItem(atPath: newPath) }

        try FileService.shared.createNewFile(path: newPath, initialContent: "Initial")
        #expect(FileService.shared.fileExists(path: newPath))

        let content = try String(contentsOfFile: newPath, encoding: .utf8)
        #expect(content == "Initial")
    }
}
