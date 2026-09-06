import Foundation
import AVFoundation
import CoreMedia

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer

    private var frameCount: Int64 = 0

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
    }

    func update(text: String) {

        guard let pixelBuffer =
                TimerRenderer.createPixelBuffer(text: text)
        else {
            print("ERRO: PixelBuffer não criado")
            return
        }

        var formatDescription: CMVideoFormatDescription?

        let formatStatus =
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &formatDescription
            )

        guard formatStatus == noErr,
              let formatDescription
        else {
            print("ERRO: FormatDescription")
            return
        }

        let presentationTime = CMTime(
            value: frameCount,
            timescale: 30
        )

        let duration = CMTime(
            value: 1,
            timescale: 30
        )

        var timingInfo = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: presentationTime,
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
              let sampleBuffer
        else {
            print("ERRO: SampleBuffer")
            return
        }

        if displayLayer.isReadyForMoreMediaData {

            displayLayer.enqueue(sampleBuffer)

            frameCount += 1

        } else {

            print("Layer não está pronto")
        }
    }


    func reset() {

        displayLayer.flush()

        frameCount = 0
    }
}
