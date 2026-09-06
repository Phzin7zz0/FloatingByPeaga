import Foundation
import Combine

class TimerManager: ObservableObject {
    
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    
    private var timer: Timer?
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.elapsedTime += 0.01
            }
        }
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func reset() {
        pause()
        elapsedTime = 0
    }
    
    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime * 100).truncatingRemainder(dividingBy: 100))
        
        return String(format: "%02d:%02d.%02d",
                      minutes,
                      seconds,
                      milliseconds)
    }
}
