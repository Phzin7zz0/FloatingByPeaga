import Foundation
import AVFoundation
import AVKit

final class PiPManager: NSObject, ObservableObject {

    @Published var isPiPActive = false
    @Published var status = "Preparando PiP..."

    let displayLayer = AVSampleBufferDisplayLayer()

    private var pipController: AVPictureInPictureController?

    override init() {
        super.init()
        setupPiP()
    }

    private func setupPiP() {

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status = "PiP não suportado neste ambiente"
            return
        }

        if #available(iOS 15.0, *) {

            let contentSource =
                AVPictureInPictureController.ContentSource(
                    sampleBufferDisplayLayer: displayLayer,
                    playbackDelegate: self
                )

            pipController =
                AVPictureInPictureController(contentSource: contentSource)

            pipController?.delegate = self
            pipController?.canStartPictureInPictureAutomaticallyFromInline = false
            pipController?.requiresLinearPlayback = false

            status = "PiP configurado"
        }
    }

    func startPiP() {

        guard let pipController else {
            status = "Erro: PiP Controller não criado"
            return
        }

        if pipController.isPictureInPicturePossible {
            status = "Abrindo janela..."
            pipController.startPictureInPicture()
        } else {
            status = "PiP ainda não está disponível"
        }
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
    }
}


// MARK: - PiP Delegate

extension PiPManager: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        DispatchQueue.main.async {
            self.isPiPActive = true
            self.status = "PiP ativo!"
        }
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.status = "Erro PiP: \(error.localizedDescription)"
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
extension PiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {}

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        CMTimeRange(
            start: .zero,
            duration: .positiveInfinity
        )
    }

    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        false
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {}

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping @Sendable () -> Void
    ) {
        completionHandler()
    }
}
