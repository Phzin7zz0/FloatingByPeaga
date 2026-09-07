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
 
    // Conexão com o cronômetro principal
    weak var timerManager: TimerManager?
 
    // Chamado sempre que o usuário toca no play/pause da janela flutuante (PiP)
    var onPiPInteraction: (() -> Void)?
 
    // Timer para atualizar visualmente o PiP
    private var renderTimer: Timer?
 
    private var timebase: CMTimebase?
 
    override init() {
        super.init()
 
        DispatchQueue.main.async {
            self.setupPiP()
        }
    }
 
 
    // MARK: - Setup
 
    private func setupPiP() {
 
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status = "PiP não suportado"
            return
        }
 
        // Áudio necessário para manter PiP funcionando
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
 
 
        // Configuração da camada de vídeo
        displayLayer.videoGravity = .resizeAspect
 
 
        // MARK: Timebase
 
        var newTimebase: CMTimebase?
 
        let result = CMTimebaseCreateWithSourceClock(
            allocator: kCFAllocatorDefault,
            sourceClock: CMClockGetHostTimeClock(),
            timebaseOut: &newTimebase
        )
 
        guard result == noErr,
              let newTimebase = newTimebase else {
 
            print("Erro ao criar Timebase")
            status = "Erro Timebase"
            return
        }
 
        timebase = newTimebase
 
        // IMPORTANTE: o timebase precisa começar no MESMO relógio absoluto
        // (host time clock) que o PiPFrameProvider usa para os
        // presentationTimeStamp dos sample buffers. Se começar em .zero,
        // o timebase e os frames ficam em "linhas do tempo" diferentes e
        // a AVSampleBufferDisplayLayer nunca consegue alcançar o PTS dos
        // frames novos — por isso o Preview travava num valor antigo.
        CMTimebaseSetTime(
            newTimebase,
            time: CMClockGetTime(CMClockGetHostTimeClock())
        )
 
        CMTimebaseSetRate(
            newTimebase,
            rate: 1.0
        )
 
        displayLayer.controlTimebase = newTimebase
 
 
        // MARK: Frame Provider
 
        frameProvider = PiPFrameProvider(
            displayLayer: displayLayer
        )
 
 
        // MARK: PiP Controller
 
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
 
            // Permite controles no PiP
            pipController?.requiresLinearPlayback = false
 
 
            // Começa a enviar frames
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.5
            ) {
 
                self.startFrameUpdates()
            }
 
            status = "Preview pronto"
        }
    }
 
 
    // MARK: - Conectar TimerManager
 
    func connectTimer(
        _ timerManager: TimerManager
    ) {
 
        self.timerManager = timerManager
 
        print("TimerManager conectado ao PiP")
 
        updateFrame()
    }
 
 
    // MARK: - Atualização dos frames
 
    private func startFrameUpdates() {
 
        renderTimer?.invalidate()
 
        renderTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in
 
            guard let self = self else {
                return
            }
 
            self.updateFrame()
        }
 
        RunLoop.main.add(
            renderTimer!,
            forMode: .common
        )
 
        print("Renderização PiP iniciada")
    }
 
 
    private func updateFrame() {
 
        guard let timerManager = timerManager else {
 
            // Preview inicial
            frameProvider?.update(
                text: "00:00.00"
            )
 
            return
        }
 
 
        frameProvider?.update(
            text: timerManager.formattedTime
        )
    }
 
 
    // MARK: - Abrir PiP
 
    func startPiP() {
 
        guard let pipController = pipController else {
 
            status = "Controller não criado"
            return
        }
 
 
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.3
        ) {
 
            if pipController.isPictureInPicturePossible {
 
                self.status = "Abrindo PiP..."
 
                pipController.startPictureInPicture()
 
            } else {
 
                self.status = "PiP indisponível"
 
                print(
                    "PiP não disponível"
                )
 
                print(
                    "Layer:",
                    self.displayLayer.status.rawValue
                )
            }
        }
    }
 
 
    // MARK: - Fechar PiP
 
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
 
            self.status =
                "PiP fechado"
        }
    }
}
 
 
// MARK: - Controles do PiP
 
@available(iOS 15.0, *)
extension PiPManager:
    AVPictureInPictureSampleBufferPlaybackDelegate {
 
 
    // Quando usuário aperta Play/Pause no PiP
    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,
 
        setPlaying playing: Bool
    ) {
 
        DispatchQueue.main.async {
 
            guard let timerManager =
                    self.timerManager else {
                return
            }
 
 
            if playing {
 
                timerManager.start()
 
            } else {
 
                timerManager.pause()
            }
 
            self.onPiPInteraction?()
        }
    }
 
 
    // Diz ao sistema se está pausado
    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController:
            AVPictureInPictureController
    ) -> Bool {
 
        guard let timerManager =
                timerManager else {
 
            return true
        }
 
        return !timerManager.isRunning
    }
 
 
    // Tempo disponível para reprodução
    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController:
            AVPictureInPictureController
    ) -> CMTimeRange {
 
        return CMTimeRange(
            start: .zero,
 
            duration: CMTime(
                seconds: 86400,
                preferredTimescale: 600
            )
        )
    }
 
 
    // Botão avançar/voltar (versão assíncrona)
    // O Swift gera automaticamente a versão "completion handler"
    // por baixo dos panos a partir desta função async, então não
    // é necessário (nem permitido) implementar as duas juntas.
    func pictureInPictureController(
        _ pictureInPictureController:
            AVPictureInPictureController,
 
        skipByInterval skipInterval:
            CMTime
    ) async {
 
        if skipInterval.seconds > 0 {
 
            await MainActor.run {
                self.timerManager?.reset()
            }
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
            "Novo tamanho:",
            newRenderSize.width,
            "x",
            newRenderSize.height
        )
    }
}
