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
    private var seconds: Int = 0

    override init() {
        super.init()

        DispatchQueue.main.async {
            self.setupPiP()
        }
    }

    private func setupPiP() {

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status = "PiP não suportado neste dispositivo"
            return
        }

        if #available(iOS 15.0, *) {

            let contentSource =
                AVPictureInPictureController.ContentSource(
                    sampleBufferDisplayLayer: displayLayer,
                    playbackDelegate: self
                )

            pipController =
                AVPictureInPictureController(
                    contentSource: contentSource
                )

            pipController?.delegate = self

            pipController?
                .canStartPictureInPictureAutomaticallyFromInline = false

            pipController?.requiresLinearPlayback = false

            frameProvider = PiPFrameProvider(
                displayLayer: displayLayer
            )

            displayLayer.videoGravity = .resizeAspect

            status = "PiP configurado"

            // FRAME INICIAL
            frameProvider?.update(text: "00:00")
        }
    }


    // MARK: - ABRIR PIP

    func startPiP() {

        DispatchQueue.main.async {

            guard let pipController = self.pipController else {
                self.status = "Erro: PiP Controller não criado"
                return
            }

            self.status = "Preparando janela..."

            // Reinicia o display
            self.frameProvider?.reset()

            // Envia alguns frames antes de abrir
            for _ in 0..<5 {
                self.frameProvider?.update(
                    text: self.formattedTime()
                )
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.3
            ) {

                print(
                    "PiP possível:",
                    pipController.isPictureInPicturePossible
                )

                self.status =
                    pipController.isPictureInPicturePossible
                    ? "Abrindo janela..."
                    : "PiP ainda não disponível"

                pipController.startPictureInPicture()

                self.startFrameUpdates()
            }
        }
    }


    // MARK: - ATUALIZAR FRAMES

    private func startFrameUpdates() {

        renderTimer?.invalidate()

        renderTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in

            guard let self = self else { return }

            self.frameProvider?.update(
                text: self.formattedTime()
            )
        }
    }


    // MARK: - FORMATAR TEMPO

    private func formattedTime() -> String {

        let minutes = seconds / 60
        let secs = seconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            secs
        )
    }


    // MARK: - FECHAR PIP

    func stopPiP() {

        renderTimer?.invalidate()
        renderTimer = nil

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
            self.isPiPActive = true
            self.status = "PiP iniciando..."
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

            print("ERRO PIP:", error)

            self.status =
                "Erro PiP: \(error.localizedDescription)"

            self.renderTimer?.invalidate()
            self.renderTimer = nil
        }
    }


    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {

        DispatchQueue.main.async {

            self.isPiPActive = false
            self.status = "PiP fechado"

            self.renderTimer?.invalidate()
            self.renderTimer = nil
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
