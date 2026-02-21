import Foundation
import Testing
@testable import TextEditor

@Suite("AutoSaveIntegration")
struct AutoSaveIntegrationTests {
    @Test("Auto-save triggers callback")
    @MainActor
    func autoSaveTriggersCallback() async throws {
        var didFire = false
        let autoSaveService = AutoSaveService()
        autoSaveService.saveInterval = 0.1
        defer { autoSaveService.stopAutoSave() }

        autoSaveService.startAutoSave {
            didFire = true
        }

        for _ in 0..<100 {
            if didFire { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        #expect(didFire)
    }

    @Test("Stop auto-save prevents callback")
    @MainActor
    func stopAutoSavePreventsCallback() async throws {
        var callCount = 0
        let autoSaveService = AutoSaveService()
        autoSaveService.saveInterval = 0.1

        autoSaveService.startAutoSave {
            callCount += 1
        }

        autoSaveService.stopAutoSave()
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(callCount == 0)
    }

    @Test("Multiple auto-saves work")
    @MainActor
    func multipleSavesWork() async throws {
        var callCount = 0
        let autoSaveService = AutoSaveService()
        autoSaveService.saveInterval = 0.05
        defer { autoSaveService.stopAutoSave() }

        autoSaveService.startAutoSave {
            callCount += 1
        }

        for _ in 0..<200 {
            if callCount >= 3 { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        #expect(callCount >= 3)
    }
}
