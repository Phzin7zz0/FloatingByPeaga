import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var frameCount: Int64 = 0

    init(
        displayLayer: AVSampleBufferDisplayLayer
    ) {
        self.displayLayer = displayLayer
    }


    func update(text: String) {

        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(
                    text: text
                )
        else {

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
              let formatDescription = formatDescription
        else {

            print("❌ ERRO: FormatDescription")
            return
        }


        // Timeline simples de 30 FPS
        let presentationTime =
            CMTime(
                value: frameCount,
                timescale: 30
            )


        let duration =
            CMTime(
                value: 1,
                timescale: 30
            )


        var timingInfo =
            CMSampleTimingInfo(
                duration: duration,
                presentationTimeStamp: presentationTime,
                decodeTimeStamp: .invalid
            )


        var sampleBuffer:
            CMSampleBuffer?


        let result =
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescription: formatDescription,
                sampleTiming: &timingInfo,
                sampleBufferOut: &sampleBuffer
            )


        guard result == noErr,
              let sampleBuffer = sampleBuffer
        else {

            print("❌ ERRO: SampleBuffer")
            return
        }


        // Se deu erro, reinicia a layer
        if displayLayer.status == .failed {

            print(
                "⚠️ DISPLAY LAYER FALHOU:",
                displayLayer.error?
                    .localizedDescription
                    ?? "Erro desconhecido"
            )

            displayLayer.flush()

            frameCount = 0
        }


        // Envia frame
        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(
                sampleBuffer
            )

            frameCount += 1

        } else {

            print(
                "⚠️ Layer não pronta"
            )
        }
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0
    }
}
