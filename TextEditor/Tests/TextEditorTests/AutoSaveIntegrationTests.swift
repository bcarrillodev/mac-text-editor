import XCTest
@testable import TextEditor

class AutoSaveIntegrationTests: XCTestCase {
    func testAutoSaveTriggersCallback() {
        let expectation = XCTestExpectation(description: "Auto-save callback triggered")
        let autoSaveService = AutoSaveService()
        autoSaveService.saveInterval = 0.1
        
        autoSaveService.startAutoSave {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        autoSaveService.stopAutoSave()
    }
    
    func testStopAutoSave() {
        let expectation = XCTestExpectation(description: "Auto-save callback NOT triggered")
        expectation.isInverted = true
        
        let autoSaveService = AutoSaveService()
        autoSaveService.saveInterval = 0.1
        
        autoSaveService.startAutoSave {
            expectation.fulfill()
        }
        
        autoSaveService.stopAutoSave()
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    func testMultipleSavesWork() {
        var callCount = 0
        let autoSaveService = AutoSaveService()
        autoSaveService.saveInterval = 0.05
        
        let expectation = XCTestExpectation(description: "Multiple auto-saves triggered")
        expectation.expectedFulfillmentCount = 3
        
        autoSaveService.startAutoSave {
            callCount += 1
            if callCount <= 3 {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
        autoSaveService.stopAutoSave()
        
        XCTAssertGreaterThanOrEqual(callCount, 3)
    }
}
