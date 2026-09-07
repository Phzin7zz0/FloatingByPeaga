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

    // Referência ao cronômetro principal
    private weak var timerManager: TimerManager?


    override init() {

        super.init()

        DispatchQueue.main.async {
            self.setupPiP()
        }
    }


    // MARK: - Conectar cronômetro

    func connectTimer(
        _ timerManager: TimerManager
    ) {

        self.timerManager = timerManager

        print("✅ Timer conectado ao PiP")
    }


    // MARK: - Configurar PiP

    private func setupPiP() {

        guard AVPictureInPictureController
            .isPictureInPictureSupported()
        else {

            status = "PiP não suportado"
            return
        }


        // MARK: Áudio

        do {

            let audioSession =
                AVAudioSession.sharedInstance()

            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: []
            )

            try audioSession.setActive(true)

        } catch {

            status = "Erro no áudio"

            print("Erro áudio:", error)

            return
        }


        // MARK: Display Layer

        displayLayer.videoGravity =
            .resizeAspect


        // MARK: Provider dos frames

        frameProvider =
            PiPFrameProvider(
                displayLayer: displayLayer
            )


        // MARK: Controller PiP

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

            // Permite controles
            pipController?
                .requiresLinearPlayback = false


            // Começa a gerar frames
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.5
            ) {

                self.startFrameUpdates()
            }


            status = "Renderizando preview..."
        }
    }


    // MARK: - Atualização dos frames

    private func startFrameUpdates() {

        renderTimer?.invalidate()


        renderTimer =
            Timer.scheduledTimer(
                withTimeInterval: 1.0 / 30.0,
                repeats: true
            ) { [weak self] _ in

                guard let self = self else {
                    return
                }


                // Sempre pega o tempo atual do cronômetro
                let text =
                    self.timerManager?
                        .formattedTime
                    ?? "0:00.00"


                self.frameProvider?
                    .update(
                        text: text
                    )
            }


        RunLoop.main.add(
            renderTimer!,
            forMode: .common
        )


        print("✅ Renderização iniciada")
    }


    // MARK: - Abrir PiP

    func startPiP() {

        guard let pipController = pipController else {

            status = "Controller não criado"

            return
        }


        status = "Verificando PiP..."


        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.5
        ) {

            let possible =
                pipController.isPictureInPicturePossible


            print("")
            print("========== PiP DEBUG ==========")
            print(
                "SUPPORTED:",
                AVPictureInPictureController
                    .isPictureInPictureSupported()
            )
            print("POSSIBLE:", possible)
            print(
                "LAYER STATUS:",
                self.displayLayer.status.rawValue
            )
            print(
                "ERROR:",
                self.displayLayer.error?
                    .localizedDescription
                ?? "Nenhum"
            )
            print("================================")
            print("")


            if possible {

                self.status = "Abrindo PiP..."

                pipController
                    .startPictureInPicture()

            } else {

                self.status =
                    "PiP ainda não está disponível"
            }
        }
    }


    // MARK: - Fechar PiP

    func stopPiP() {

        pipController?
            .stopPictureInPicture()
    }


    deinit {

        renderTimer?
            .invalidate()
    }
}


// MARK: - PiP Delegate

extension PiPManager:
    AVPictureInPictureControllerDelegate {


    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController:
            AVPictureInPictureController
    ) {

        DispatchQueue.main.async {

            self.isPiPActive = true

            self.status =
                "Janela flutuante aberta!"
        }
    }


    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,

        failedToStartPictureInPictureWithError
            error: Error
    ) {

        DispatchQueue.main.async {

            self.status =
                "Erro: \(error.localizedDescription)"
        }
    }


    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController:
            AVPictureInPictureController
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


    // ▶️ Botão PLAY do PiP

    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,

        setPlaying playing: Bool
    ) {

        DispatchQueue.main.async {

            if playing {

                self.timerManager?
                    .start()

                print(
                    "▶️ Cronômetro iniciado pelo PiP"
                )

            } else {

                self.timerManager?
                    .pause()

                print(
                    "⏸️ Cronômetro pausado pelo PiP"
                )
            }
        }
    }


    // Define se o PiP está pausado

    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController:
            AVPictureInPictureController
    ) -> Bool {

        return !(
            timerManager?
                .isRunning
            ?? false
        )
    }


    // Tempo fictício para habilitar controles

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController:
            AVPictureInPictureController
    ) -> CMTimeRange {

        return CMTimeRange(
            start: .zero,

            duration:
                CMTime(
                    seconds: 86400,
                    preferredTimescale: 600
                )
        )
    }


    // ⏪ / ⏩ = RESET

    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,

        skipByInterval
            skipInterval:
                CMTime,

        completion
            completionHandler:
                @escaping @Sendable () -> Void
    ) {

        DispatchQueue.main.async {

            self.timerManager?
                .reset()

            print(
                "🔄 Cronômetro reiniciado pelo PiP"
            )

            completionHandler()
        }
    }


    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,

        didTransitionToRenderSize
            newRenderSize:
                CMVideoDimensions
    ) {

        print(
            "📐 Novo tamanho PiP:",
            newRenderSize.width,
            "x",
            newRenderSize.height
        )
    }
}
