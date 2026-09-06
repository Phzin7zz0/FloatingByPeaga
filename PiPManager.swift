import Foundation
import AVFoundation
import AVKit
import UIKit

final class PiPManager: NSObject, ObservableObject {

    @Published var isPiPActive = false
    @Published var status = "Inicializando..."

    let displayLayer = AVSampleBufferDisplayLayer()

    private var pipController: AVPictureInPictureController?
    private var frameProvider: PiPFrameProvider?
    private var renderTimer: Timer?

    private var startTime = Date()

    override init() {
        super.init()

        DispatchQueue.main.async {
            self.setupPiP()
        }
    }

    private func setupPiP() {

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status = "PiP não suportado"
            return
        }

        status = "Configurando PiP..."

        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = UIColor.black.cgColor

        if #available(iOS 15.0, *) {

            frameProvider = PiPFrameProvider(
                displayLayer: displayLayer
            )

            let contentSource =
                AVPictureInPictureController.ContentSource(
                    sampleBufferDisplayLayer: displayLayer,
                    playbackDelegate: self
                )

            pipController = AVPictureInPictureController(
                contentSource: contentSource
            )

            pipController?.delegate = self
            pipController?.requiresLinearPlayback = false

            // COMEÇA A GERAR FRAMES IMEDIATAMENTE
            startFrameUpdates()

            status = "Aguardando PiP ficar disponível..."
        }
    }


    // MARK: - GERAR FRAMES

    private func startFrameUpdates() {

        renderTimer?.invalidate()

        startTime = Date()

        renderTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in

            guard let self else { return }

            let elapsed = Int(
                Date().timeIntervalSince(self.startTime)
            )

            let minutes = elapsed / 60
            let seconds = elapsed % 60

            let text = String(
                format: "%02d:%02d",
                minutes,
                seconds
            )

            self.frameProvider?.update(text: text)
        }

        RunLoop.main.add(
            renderTimer!,
            forMode: .common
        )
    }


    // MARK: - ABRIR PIP

    func startPiP() {

        guard let pipController else {
            status = "Erro: PiP Controller não criado"
            return
        }

        status = "Verificando PiP..."

        // Força mais alguns frames
        for _ in 0..<30 {
            frameProvider?.update(text: "00:00")
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.0
        ) {

            print(
                "PiP Supported:",
                AVPictureInPictureController.isPictureInPictureSupported()
            )

            print(
                "PiP Possible:",
                pipController.isPictureInPicturePossible
            )

            if pipController.isPictureInPicturePossible {

                self.status = "Abrindo janela..."

                pipController.startPictureInPicture()

            } else {

                self.status = "PiP ainda não disponível"
            }
        }
    }


    // MARK: - FECHAR

    func stopPiP() {

        pipController?.stopPictureInPicture()
    }


    deinit {
        renderTimer?.invalidate()
    }
}


// MARK: - PiP Delegate

extension PiPManager: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {

        DispatchQueue.main.async {
            self.status = "Abrindo..."
        }
    }


    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {

        DispatchQueue.main.async {
            self.isPiPActive = true
            self.status = "Janela flutuante aberta!"
        }
    }


    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {

        DispatchQueue.main.async {
            self.status = "Erro: \(error.localizedDescription)"
            print("ERRO PIP:", error)
        }
    }


    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {

        DispatchQueue.main.async {
            self.isPiPActive = false
            self.status = "PiP fechado"
        }
    }
}


// MARK: - Playback Delegate

@available(iOS 15.0, *)
extension PiPManager:
    AVPictureInPictureSampleBufferPlaybackDelegate {

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
    }


    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {

        return CMTimeRange(
            start: .zero,
            duration: .positiveInfinity
        )
    }


    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {

        return false
    }


    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {
    }


    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping @Sendable () -> Void
    ) {

        completionHandler()
    }
}
