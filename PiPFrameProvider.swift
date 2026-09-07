import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    init(
        displayLayer: AVSampleBufferDisplayLayer
    ) {

        self.displayLayer = displayLayer
    }


    func update(text: String) {

        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(
                    text: text
                ) else {

            print("❌ ERRO: PixelBuffer não criado")
            return
        }


        var formatDescription:
            CMVideoFormatDescription?


        let formatStatus =
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &formatDescription
            )


        guard formatStatus == noErr,
              let formatDescription =
                formatDescription else {

            print("❌ ERRO: FormatDescription")
            return
        }


        // Usa o relógio atual do sistema.
        // Isso evita que os frames fiquem "atrasados"
        // e travem no primeiro frame.

        let currentTime =
            CMClockGetTime(
                CMClockGetHostTimeClock()
            )


        let duration =
            CMTime(
                value: 1,
                timescale: 30
            )


        var timingInfo =
            CMSampleTimingInfo(
                duration: duration,
                presentationTimeStamp: currentTime,
                decodeTimeStamp: .invalid
            )


        var sampleBuffer: CMSampleBuffer?


        let result =
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescription: formatDescription,
                sampleTiming: &timingInfo,
                sampleBufferOut: &sampleBuffer
            )


        guard result == noErr,
              let sampleBuffer =
                sampleBuffer else {

            print("❌ ERRO: SampleBuffer")
            return
        }


        // Se a layer falhou, limpa
        if displayLayer.status == .failed {

            print(
                "⚠️ DISPLAY LAYER FALHOU:",
                displayLayer.error?
                    .localizedDescription
                    ?? "Erro desconhecido"
            )

            displayLayer.flush()
        }


        // Envia novo frame
        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(
                sampleBuffer
            )

        } else {

            print(
                "⚠️ Layer não pronta"
            )
        }
    }


    func reset() {

        displayLayer.flush()
    }
}
