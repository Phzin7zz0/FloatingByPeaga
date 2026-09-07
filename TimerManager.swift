import Foundation
import Combine
import AVFoundation

final class TimerManager: ObservableObject {

    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false

    private var timer: Timer?
    private var pipFrameProvider: PiPFrameProvider?

    private var lastPiPUpdate: Date = .distantPast

    // Conecta o cronômetro ao Picture-in-Picture
    func connectPiP(displayLayer: AVSampleBufferDisplayLayer) {
        pipFrameProvider = PiPFrameProvider(displayLayer: displayLayer)

        updatePiP()
    }

    // Iniciar cronômetro
    func start() {

        guard !isRunning else { return }

        isRunning = true

        let startDate = Date().addingTimeInterval(-elapsedTime)

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.01,
            repeats: true
        ) { [weak self] _ in

            guard let self else { return }

            DispatchQueue.main.async {

                self.elapsedTime =
                    Date().timeIntervalSince(startDate)

                // Atualiza PiP aproximadamente a 30 FPS
                let now = Date()

                if now.timeIntervalSince(
                    self.lastPiPUpdate
                ) >= (1.0 / 30.0) {

                    self.lastPiPUpdate = now
                    self.updatePiP()
                }
            }
        }
    }

    // Pausar cronômetro
    func pause() {

        timer?.invalidate()
        timer = nil

        isRunning = false

        updatePiP()
    }

    // Reiniciar cronômetro
    func reset() {

        pause()

        elapsedTime = 0

        updatePiP()
    }

    // Atualiza conteúdo do PiP
    private func updatePiP() {

        pipFrameProvider?.update(
            text: formattedTime
        )
    }

    // Formato: 5:59.77
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
