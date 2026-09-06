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

    private var startDate = Date()
    private var timebase: CMTimebase?


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


        do {

            let audioSession = AVAudioSession.sharedInstance()

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


        // Configuração visual
        displayLayer.videoGravity = .resizeAspect


        // Cria um relógio para o AVSampleBufferDisplayLayer
        var newTimebase: CMTimebase?

        let timebaseStatus =
            CMTimebaseCreateWithSourceClock(
                allocator: kCFAllocatorDefault,
                sourceClock: CMClockGetHostTimeClock(),
                timebaseOut: &newTimebase
            )


        if timebaseStatus == noErr,
           let newTimebase = newTimebase {

            timebase = newTimebase

            CMTimebaseSetTime(
                newTimebase,
                time: .zero
            )

            CMTimebaseSetRate(
                newTimebase,
                rate: 1.0
            )

            displayLayer.controlTimebase =
                newTimebase

        } else {

            print("❌ Erro ao criar Timebase")
            status = "Erro ao criar Timebase"
            return
        }


        // Provider dos frames
        frameProvider =
            PiPFrameProvider(
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


            // Pequeno atraso para garantir que tudo foi inicializado
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.5
            ) {

                self.startFrameUpdates()
            }


            status = "Renderizando preview..."
        }
    }


    private func startFrameUpdates() {

        renderTimer?.invalidate()


        startDate = Date()


        renderTimer =
            Timer.scheduledTimer(
                withTimeInterval: 1.0 / 30.0,
                repeats: true
            ) { [weak self] _ in

                guard let self = self else {
                    return
                }


                let elapsed =
                    Int(
                        Date()
                            .timeIntervalSince(
                                self.startDate
                            )
                    )


                let minutes =
                    elapsed / 60


                let seconds =
                    elapsed % 60


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


        RunLoop.main.add(
            renderTimer!,
            forMode: .common
        )


        print("✅ Renderização iniciada")
    }


    func startPiP() {

        guard let pipController = pipController else {

            status = "Controller não criado"
            return
        }


        status = "Verificando PiP..."


        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.0
        ) {

            let possible =
                pipController.isPictureInPicturePossible


            let supported =
                AVPictureInPictureController
                    .isPictureInPictureSupported()


            let layerStatus =
                self.displayLayer.status.rawValue


            let error =
                self.displayLayer.error?
                    .localizedDescription
                ?? "Nenhum"


            print("")
            print("========== PiP DEBUG ==========")
            print("SUPPORTED:", supported)
            print("POSSIBLE:", possible)
            print("LAYER STATUS:", layerStatus)
            print("ERROR:", error)
            print("================================")
            print("")


            if possible {

                self.status = "Abrindo PiP..."

                pipController.startPictureInPicture()

            } else {

                self.status = """
                PiP indisponível

                Poss: \(possible)
                Layer: \(layerStatus)
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
        _ pictureInPictureController:
            AVPictureInPictureController
    ) {

        DispatchQueue.main.async {

            self.isPiPActive = true
            self.status = "Janela flutuante aberta!"
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


    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,

        setPlaying playing: Bool
    ) {
    }


    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController:
            AVPictureInPictureController
    ) -> CMTimeRange {

        return CMTimeRange(
            start: .zero,

            duration:
                CMTime(
                    seconds: 3600,
                    preferredTimescale: 600
                )
        )
    }


    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController:
            AVPictureInPictureController
    ) -> Bool {

        return false
    }


    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,

        skipByInterval skipInterval:
            CMTime,

        completion completionHandler:
            @escaping @Sendable () -> Void
    ) {

        completionHandler()
    }


    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,

        didTransitionToRenderSize newRenderSize:
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
