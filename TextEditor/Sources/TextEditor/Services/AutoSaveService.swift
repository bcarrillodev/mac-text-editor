import Foundation

class AutoSaveService: ObservableObject {
    var saveInterval: TimeInterval = 10.0
    private var timer: Timer?
    
    func startAutoSave(callback: @escaping () -> Void) {
        stopAutoSave()
        timer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { _ in
            callback()
        }
    }
    
    func stopAutoSave() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopAutoSave()
    }
}
