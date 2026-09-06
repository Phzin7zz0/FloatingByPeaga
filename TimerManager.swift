import Foundation
import Combine

class TimerManager: ObservableObject {

    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = true

    private var timer: Timer?

    init() {
        start()
    }

    func start() {
        guard timer == nil else { return }

        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.elapsedTime += 0.01
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func togglePause() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    func reset() {
        elapsedTime = 0
    }

    func formattedTime() -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let centiseconds = Int((elapsedTime * 100).rounded()) % 100

        return String(format: "%d:%02d.%02d",
                      minutes,
                      seconds,
                      centiseconds)
    }
}