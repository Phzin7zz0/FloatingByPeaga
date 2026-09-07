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

    private weak var timerManager: TimerManager?


    override init() {

        super.init()

        DispatchQueue.main.async {
            self.setupPiP()
        }
    }


    func connectTimer(
        _ timerManager: TimerManager
    ) {

        self.timerManager = timerManager

        print("TIMER CONECTADO")
    }


    private func setupPiP() {

        guard AVPictureInPictureController
            .isPictureInPictureSupported()
        else {

            status = "PiP não suportado"

            return
        }


        do {

            let audioSession =
                AVAudioSession.sharedInstance()

            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback
            )

            try audioSession.setActive(true)

        } catch {

            print(
                "ERRO AUDIO:",
                error
            )
        }


        displayLayer.videoGravity = .resizeAspect


        frameProvider =
            PiPFrameProvider(
                displayLayer: displayLayer
            )


        if #available(iOS 15.0, *) {

            let contentSource =
                AVPictureInPictureController
                    .ContentSource(

                        sampleBufferDisplayLayer:
                            displayLayer,

                        playbackDelegate:
                            self
                    )


            pipController =
                AVPictureInPictureController(
                    contentSource:
                        contentSource
                )


            pipController?.delegate = self


            pipController?
                .requiresLinearPlayback = false


            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.3
            ) {

                self.startFrameUpdates()
            }


            status = "Renderizando..."
        }
    }


    private func startFrameUpdates() {

        renderTimer?.invalidate()


        renderTimer =
            Timer.scheduledTimer(

                withTimeInterval:
                    1.0 / 30.0,

                repeats: true

            ) { [weak self] _ in


                guard let self = self
                else {
                    return
                }


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


        print("RENDER INICIADO")
    }


    func startPiP() {

        guard let pipController =
                pipController
        else {

            status = "Controller não criado"

            return
        }


        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.0
        ) {

            print("")
            print("===== DEBUG PIP =====")

            print(
                "STATUS:",
                self.displayLayer
                    .status
                    .rawValue
            )

            print(
                "READY:",
                self.displayLayer
                    .isReadyForMoreMediaData
            )

            print(
                "POSSIBLE:",
                pipController
                    .isPictureInPicturePossible
            )

            print(
                "ERROR:",
                self.displayLayer
                    .error?
                    .localizedDescription
                ?? "Nenhum"
            )

            print("====================")


            if pipController
                .isPictureInPicturePossible {

                pipController
                    .startPictureInPicture()

            } else {

                self.status =
                    "PiP indisponível"
            }
        }
    }


    func stopPiP() {

        pipController?
            .stopPictureInPicture()
    }


    deinit {

        renderTimer?
            .invalidate()
    }
}


// MARK: PiP Controller Delegate

extension PiPManager:
    AVPictureInPictureControllerDelegate {


    func pictureInPictureControllerDidStartPictureInPicture(

        _ pictureInPictureController:
            AVPictureInPictureController

    ) {

        DispatchQueue.main.async {

            self.isPiPActive = true

            self.status = "PiP aberto"
        }
    }


    func pictureInPictureController(

        _ pictureInPictureController:
            AVPictureInPictureController,

        failedToStartPictureInPictureWithError
            error: Error

    ) {

        print(
            "ERRO PIP:",
            error
        )

        self.status =
            error.localizedDescription
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


// MARK: Playback Delegate

@available(iOS 15.0, *)
extension PiPManager:
    AVPictureInPictureSampleBufferPlaybackDelegate {


    func pictureInPictureController(

        _ pictureInPictureController:
            AVPictureInPictureController,

        setPlaying playing:
            Bool

    ) {

        DispatchQueue.main.async {

            if playing {

                self.timerManager?
                    .start()

            } else {

                self.timerManager?
                    .pause()
            }
        }
    }


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

            completionHandler()
        }
    }


    // Necessário nas versões mais recentes do SDK/iOS
    func pictureInPictureController(

        _ pictureInPictureController:
            AVPictureInPictureController,

        didTransitionToRenderSize
            newRenderSize:
                CMVideoDimensions

    ) {

        print(
            "PiP mudou tamanho:",
            newRenderSize.width,
            "x",
            newRenderSize.height
        )
    }
}
