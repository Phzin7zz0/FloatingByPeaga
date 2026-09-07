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

            print("❌ PixelBuffer não criado")
            return
        }


        var formatDescription:
            CMVideoFormatDescription?


        let formatStatus =
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut:
                    &formatDescription
            )


        guard formatStatus == noErr,
              let formatDescription
        else {

            print("❌ FormatDescription falhou")
            return
        }


        // Timestamp sequencial: 0, 1/30, 2/30...

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
                presentationTimeStamp:
                    presentationTime,
                decodeTimeStamp:
                    .invalid
            )


        var sampleBuffer:
            CMSampleBuffer?


        let result =
            CMSampleBufferCreateReadyWithImageBuffer(
                allocator:
                    kCFAllocatorDefault,

                imageBuffer:
                    pixelBuffer,

                formatDescription:
                    formatDescription,

                sampleTiming:
                    &timingInfo,

                sampleBufferOut:
                    &sampleBuffer
            )


        guard result == noErr,
              let sampleBuffer
        else {

            print("❌ SampleBuffer falhou")
            return
        }


        // Verifica erro

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

            print(
                "✅ FRAME ENVIADO:",
                frameCount
            )

            frameCount += 1

        } else {

            print(
                "⚠️ DISPLAY LAYER NÃO PRONTA"
            )
        }
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0
    }
}
