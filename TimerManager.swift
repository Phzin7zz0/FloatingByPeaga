import Foundation
import Combine

final class TimerManager: ObservableObject {

    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false

    private var timer: Timer?

    func start() {

        guard !isRunning else {
            return
        }

        isRunning = true

        let startDate = Date().addingTimeInterval(-elapsedTime)

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.01,
            repeats: true
        ) { [weak self] _ in

            guard let self = self else {
                return
            }

            DispatchQueue.main.async {

                self.elapsedTime =
                    Date().timeIntervalSince(startDate)
            }
        }

        if let timer = timer {

            RunLoop.main.add(
                timer,
                forMode: .common
            )
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

        let centiseconds = Int(
            (elapsedTime * 100)
                .truncatingRemainder(dividingBy: 100)
        )

        return String(
            format: "%d:%02d.%02d",
            minutes,
            seconds,
            centiseconds
        )
    }
}
