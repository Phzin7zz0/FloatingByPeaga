import Foundation
import AVFoundation
import AVKit
import UIKit
import CoreMedia

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


    private func setupPiP() {

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status = "PiP não suportado"
            return
        }


        // Configura áudio para manter o app ativo
        do {

            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: []
            )

            try audioSession.setActive(true)

        } catch {

            status = "Erro no áudio: \(error.localizedDescription)"
            return
        }


        // Configuração da camada de vídeo
        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = UIColor.black.cgColor


        // Cria o gerador de frames
        frameProvider = PiPFrameProvider(
            displayLayer: displayLayer
        )


        // Limpa qualquer estado anterior
        displayLayer.flush()


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


            // Começa a enviar frames imediatamente
            startFrameUpdates()


            status = "PiP configurado"
        }
    }


    private func startFrameUpdates() {

        guard !hasStartedRendering else {
            return
        }

        hasStartedRendering = true

        startTime = Date()


        // Renderiza 30 frames por segundo
        renderTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in

            guard let self = self else {
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


            self.frameProvider?.update(
                text: text
            )
        }


        if let renderTimer = renderTimer {

            RunLoop.main.add(
                renderTimer,
                forMode: .common
            )
        }
    }


    func startPiP() {

        guard let pipController = pipController else {

            status = "Controller não criado"
            return
        }


        status = "Preparando PiP..."


        // Espera os frames serem enviados ao display layer
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 3.0
        ) { [weak self] in

            guard let self = self else {
                return
            }


            let possible =
                pipController.isPictureInPicturePossible


            let supported =
                AVPictureInPictureController
                    .isPictureInPictureSupported()


            let layerStatus =
                self.displayLayer.status.rawValue


            let ready =
                self.displayLayer
                    .isReadyForMoreMediaData


            let error =
                self.displayLayer.error?
                    .localizedDescription
                ?? "Nenhum"


            print("")
            print("========== PiP DEBUG ==========")
            print("SUPPORTED:", supported)
            print("POSSIBLE:", possible)
            print("PIP CONTROLLER:", self.pipController != nil)
            print("LAYER STATUS:", layerStatus)
            print("READY:", ready)
            print("ERROR:", error)
            print("DISPLAY LAYER:", self.displayLayer)
            print("FRAME PROVIDER:", self.frameProvider != nil)
            print("================================")
            print("")


            if possible {

                self.status = "Abrindo..."

                pipController.startPictureInPicture()

            } else {

                self.status = """
                PiP indisponível

                Poss: \(possible)
                Layer: \(layerStatus)
                Ready: \(ready)
                Error: \(error)
                """
            }
        }
    }


    func stopPiP() {

        pipController?.stopPictureInPicture()
    }


    deinit {

        renderTimer?.invalidate()
    }
}


// MARK: - PiP Delegate

extension PiPManager:
    AVPictureInPictureControllerDelegate {


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

            self.status =
                "Erro PiP: \(error.localizedDescription)"
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
            duration: CMTime(
                seconds: 3600,
                preferredTimescale: 600
            )
        )
    }


    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {

        return false
    }


    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler:
            @escaping @Sendable () -> Void
    ) {

        completionHandler()
    }


    // Método obrigatório nas versões novas do SDK
    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {

        print(
            "PiP mudou para:",
            newRenderSize.width,
            "x",
            newRenderSize.height
        )
    }
}
