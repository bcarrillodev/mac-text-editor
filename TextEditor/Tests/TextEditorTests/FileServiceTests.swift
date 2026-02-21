import XCTest
@testable import TextEditor

class FileServiceTests: XCTestCase {
    let testFilePath = NSTemporaryDirectory() + "test_file.txt"
    
    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testFilePath)
        super.tearDown()
    }
    
    func testReadFileSuccess() throws {
        let content = "Hello, World!"
        try content.write(toFile: testFilePath, atomically: true, encoding: .utf8)
        
        let readContent = try FileService.shared.readFile(path: testFilePath)
        XCTAssertEqual(readContent, content)
    }
    
    func testReadFileMissing() {
        let missingPath = NSTemporaryDirectory() + "nonexistent.txt"
        XCTAssertThrowsError(try FileService.shared.readFile(path: missingPath))
    }
    
    func testWriteFile() throws {
        let content = "Test content"
        try FileService.shared.writeFile(path: testFilePath, content: content)
        
        let readContent = try String(contentsOfFile: testFilePath, encoding: .utf8)
        XCTAssertEqual(readContent, content)
    }
    
    func testFileExists() {
        let nonexistentPath = NSTemporaryDirectory() + "nonexistent.txt"
        XCTAssertFalse(FileService.shared.fileExists(path: nonexistentPath))
        
        try? "test".write(toFile: testFilePath, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileService.shared.fileExists(path: testFilePath))
    }
    
    func testCreateNewFile() throws {
        let newPath = NSTemporaryDirectory() + "new_file.txt"
        defer { try? FileManager.default.removeItem(atPath: newPath) }
        
        try FileService.shared.createNewFile(path: newPath, initialContent: "Initial")
        XCTAssertTrue(FileService.shared.fileExists(path: newPath))
        
        let content = try String(contentsOfFile: newPath, encoding: .utf8)
        XCTAssertEqual(content, "Initial")
    }
}
