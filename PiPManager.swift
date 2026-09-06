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

    // MARK: - CONFIGURAR PIP

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

            startFrameUpdates()

            status = "PiP configurado"
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

            guard let self = self else {
                return
            }

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

        if let renderTimer {
            RunLoop.main.add(
                renderTimer,
                forMode: .common
            )
        }
    }


    // MARK: - ABRIR PIP

    func startPiP() {

        guard let pipController else {
            status = "ERRO: Controller nil"
            return
        }

        let supported =
            AVPictureInPictureController.isPictureInPictureSupported()

        let possible =
            pipController.isPictureInPicturePossible

        print("========== PiP DEBUG ==========")
        print("SUPPORTED:", supported)
        print("POSSIBLE:", possible)
        print("LAYER STATUS:", displayLayer.status.rawValue)
        print(
            "LAYER ERROR:",
            displayLayer.error?.localizedDescription ?? "nenhum"
        )
        print(
            "READY:",
            displayLayer.isReadyForMoreMediaData
        )
        print("================================")

        status = """
        Sup: \(supported)
        Poss: \(possible)
        Layer: \(displayLayer.status.rawValue)
        """

        if possible {
            status = "Abrindo janela..."
            pipController.startPictureInPicture()
        }
    }


    // MARK: - FECHAR PIP

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
