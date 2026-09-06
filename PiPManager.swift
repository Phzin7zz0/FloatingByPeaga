import Foundation
import AVFoundation
import AVKit

final class PiPManager: NSObject, ObservableObject {

    @Published var isPiPActive = false

    let displayLayer = AVSampleBufferDisplayLayer()

    private var pipController: AVPictureInPictureController?

    override init() {
        super.init()
        setupPiP()
    }

    private func setupPiP() {

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("PiP não é suportado neste dispositivo")
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
            pipController?.requiresLinearPlayback = true
        }
    }

    func startPiP() {
        guard let pipController else { return }

        if pipController.isPictureInPicturePossible {
            pipController.startPictureInPicture()
        } else {
            print("PiP ainda não está disponível")
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
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        DispatchQueue.main.async {
            self.isPiPActive = false
        }
    }
}


// MARK: - Playback Delegate

@available(iOS 15.0, *)
extension PiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        // Cronômetro é conteúdo ao vivo
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
        // Não precisamos fazer nada aqui
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping @Sendable () -> Void
    ) {
        completionHandler()
    }
}
}
