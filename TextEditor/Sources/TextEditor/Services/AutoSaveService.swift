import Foundation

class AutoSaveService: ObservableObject {
    var saveInterval: TimeInterval = 10.0
    private var timer: Timer?
    
    func startAutoSave(callback: @escaping () -> Void) {
        stopAutoSave()
        let nextTimer = Timer(timeInterval: saveInterval, repeats: true) { _ in
            callback()
        }
        nextTimer.tolerance = min(1.0, saveInterval * 0.1)
        RunLoop.main.add(nextTimer, forMode: .common)
        timer = nextTimer
    }
    
    func stopAutoSave() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        stopAutoSave()
    }
}
