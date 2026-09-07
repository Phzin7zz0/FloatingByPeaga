import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var frameCount: Int64 = 0

    private let timescale: CMTimeScale = 30


    init(
        displayLayer: AVSampleBufferDisplayLayer
    ) {

        self.displayLayer = displayLayer
    }


    func update(
        text: String
    ) {

        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(
                    text: text
                )
        else {

            print("❌ PIXEL BUFFER FALHOU")

            return
        }


        var formatDescription:
            CMVideoFormatDescription?


        let formatStatus =
            CMVideoFormatDescriptionCreateForImageBuffer(

                allocator:
                    kCFAllocatorDefault,

                imageBuffer:
                    pixelBuffer,

                formatDescriptionOut:
                    &formatDescription
            )


        guard formatStatus == noErr,
              let formatDescription =
                    formatDescription
        else {

            print(
                "❌ FORMAT DESCRIPTION FALHOU"
            )

            return
        }


        // Timestamp sequencial
        let presentationTime =
            CMTime(

                value: frameCount,

                timescale: timescale
            )


        var timingInfo =
            CMSampleTimingInfo(

                duration:
                    CMTime(

                        value: 1,

                        timescale: timescale
                    ),

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
              let sampleBuffer =
                    sampleBuffer
        else {

            print(
                "❌ SAMPLE BUFFER FALHOU"
            )

            return
        }


        // Se a layer falhou, reseta
        if displayLayer.status == .failed {

            print(
                "❌ DISPLAY LAYER FAILED:",
                displayLayer.error?
                    .localizedDescription
                    ?? "Erro desconhecido"
            )

            displayLayer.flush()

            frameCount = 0
        }


        guard displayLayer.isReadyForMoreMediaData else {

            return
        }


        displayLayer.enqueue(
            sampleBuffer
        )


        frameCount += 1
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0
    }
}
