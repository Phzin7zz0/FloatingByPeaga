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
    private var hasStartedRendering = false


    override init() {
        super.init()

        DispatchQueue.main.async {
            self.setupPiP()
        }
    }


    // MARK: - CONFIGURAR PIP

    private func setupPiP() {

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status = "PiP não suportado neste dispositivo"
            return
        }

        status = "Configurando PiP..."

        // Áudio necessário para PiP/background
        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: []
            )

            try audioSession.setActive(true)

        } catch {
            status = "Erro AudioSession: \(error.localizedDescription)"
            return
        }


        // CONFIGURA DISPLAY LAYER

        displayLayer.flush()
        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = UIColor.black.cgColor


        // FRAME PROVIDER

        frameProvider = PiPFrameProvider(
            displayLayer: displayLayer
        )


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

            pipController?.requiresLinearPlayback = false

            pipController?
                .canStartPictureInPictureAutomaticallyFromInline = false


            // Envia vários frames iniciais

            frameProvider?.update(text: "00:00")

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.1
            ) {
                self.frameProvider?.update(text: "00:00")
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.2
            ) {
                self.frameProvider?.update(text: "00:00")
            }


            // Começa renderização contínua

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.3
            ) {
                self.startFrameUpdates()
            }


            status = "PiP configurado"
        }
    }


    // MARK: - GERAR FRAMES

    private func startFrameUpdates() {

        guard !hasStartedRendering else {
            return
        }

        hasStartedRendering = true

        renderTimer?.invalidate()

        startTime = Date()


        renderTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in

            guard let self else {
                return
            }

            let elapsed =
                Int(
                    Date().timeIntervalSince(
                        self.startTime
                    )
                )

            let minutes = elapsed / 60
            let seconds = elapsed % 60

            let text =
                String(
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
            status = "Erro: PiP Controller não criado"
            return
        }


        let supported =
            AVPictureInPictureController
                .isPictureInPictureSupported()


        // Gera frame imediatamente

        let elapsed =
            Int(
                Date().timeIntervalSince(
                    startTime
                )
            )

        let minutes = elapsed / 60
        let seconds = elapsed % 60

        let text =
            String(
                format: "%02d:%02d",
                minutes,
                seconds
            )

        frameProvider?.update(text: text)


        // Aguarda sistema processar os frames

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.0
        ) {

            let possible =
                pipController.isPictureInPicturePossible

            let layerStatus =
                self.displayLayer.status.rawValue

            let layerReady =
                self.displayLayer.isReadyForMoreMediaData

            let layerError =
                self.displayLayer.error?
                    .localizedDescription
                ?? "Nenhum"


            if possible {

                self.status =
                    "Abrindo janela..."

                pipController.startPictureInPicture()

            } else {

                self.status = """
                PiP ainda indisponível

                Sup: \(supported)
                Poss: \(possible)
                Layer: \(layerStatus)
                Ready: \(layerReady)
                Error: \(layerError)
                """
            }
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


// MARK: - PIP DELEGATE

extension PiPManager:
    AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {

        DispatchQueue.main.async {

            self.status =
                "Abrindo janela..."
        }
    }


    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {

        DispatchQueue.main.async {

            self.isPiPActive = true

            self.status =
                "Janela flutuante aberta!"
        }
    }


    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {

        DispatchQueue.main.async {

            self.status =
                "Erro PiP: \(error.localizedDescription)"
        }
    }


    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {

        DispatchQueue.main.async {

            self.isPiPActive = false

            self.status =
                "PiP fechado"
        }
    }
}


// MARK: - PLAYBACK DELEGATE

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
        completion completionHandler:
            @escaping @Sendable () -> Void
    ) {

        completionHandler()
    }
}
