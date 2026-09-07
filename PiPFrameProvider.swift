import Foundation
import AVFoundation
import CoreMedia

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var frameCount: Int64 = 0

    private let frameRate: Int32 = 30


    init(
        displayLayer: AVSampleBufferDisplayLayer
    ) {

        self.displayLayer = displayLayer
    }


    func update(
        text: String
    ) {

        print(
            "▶️ UPDATE CHAMADO:",
            text
        )


        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(
                    text: text
                )
        else {

            print(
                "❌ PIXEL BUFFER FALHOU"
            )

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
              let formatDescription
        else {

            print(
                "❌ FORMAT DESCRIPTION FALHOU"
            )

            return
        }


        let presentationTime =
            CMTime(

                value:
                    frameCount,

                timescale:
                    frameRate
            )


        var timingInfo =
            CMSampleTimingInfo(

                duration:
                    CMTime(

                        value: 1,

                        timescale: frameRate
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
              let sampleBuffer
        else {

            print(
                "❌ SAMPLE BUFFER FALHOU"
            )

            return
        }


        if displayLayer.status == .failed {

            print(
                "❌ DISPLAY LAYER FAILED:",
                displayLayer.error?
                    .localizedDescription
                    ?? "desconhecido"
            )


            displayLayer.flush()

            frameCount = 0
        }


        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(
                sampleBuffer
            )


            frameCount += 1


            print(
                "✅ FRAME ENVIADO:",
                text
            )

        } else {

            print(
                "⚠️ LAYER NÃO PRONTO"
            )
        }
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0
    }
}
