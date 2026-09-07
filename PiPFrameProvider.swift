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
                formatDescriptionOut: &formatDescription
            )


        guard formatStatus == noErr,
              let formatDescription = formatDescription
        else {

            print("❌ Erro FormatDescription")
            return
        }


        /*
         IMPORTANTE:

         Para conteúdo gerado manualmente,
         usamos timestamps simples e crescentes.
        */

        let currentTime =
            CMTime(
                seconds:
                    CACurrentMediaTime(),
                preferredTimescale: 600
            )


        var timingInfo =
            CMSampleTimingInfo(
                duration:
                    CMTime(
                        value: 1,
                        timescale: 30
                    ),

                presentationTimeStamp:
                    currentTime,

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
              let sampleBuffer = sampleBuffer
        else {

            print("❌ Erro SampleBuffer")
            return
        }


        // Se deu erro, limpa a layer

        if displayLayer.status == .failed {

            print(
                "⚠️ Layer falhou:",
                displayLayer.error?
                    .localizedDescription
                    ?? "Erro desconhecido"
            )

            displayLayer.flush()
        }


        // Envia frame

        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(
                sampleBuffer
            )

        } else {

            print(
                "⚠️ Layer não está pronta"
            )
        }
    }


    func reset() {

        displayLayer.flush()
    }
}
