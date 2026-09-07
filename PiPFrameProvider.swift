import Foundation
import AVFoundation
import CoreMedia
import CoreVideo

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var frameNumber: Int64 = 0

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
              let formatDescription =
                formatDescription else {

            return
        }


        // Timestamp sequencial
        let presentationTime =
            CMTime(
                value: frameNumber,
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
              let sampleBuffer =
                sampleBuffer else {

            return
        }


        // Se der erro, reinicia a layer
        if displayLayer.status == .failed {

            displayLayer.flush()

            frameNumber = 0
        }


        // Adiciona frame
        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(
                sampleBuffer
            )

            frameNumber += 1
        }
    }


    func reset() {

        displayLayer.flush()

        frameNumber = 0
    }
}
