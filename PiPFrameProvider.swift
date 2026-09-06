import Foundation
import AVFoundation
import CoreMedia

final class PiPFrameProvider {

    private let displayLayer: AVSampleBufferDisplayLayer
    private var startTime: CMTime?

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
    }

    func update(text: String) {

        guard let pixelBuffer = TimerRenderer.createPixelBuffer(text: text) else {
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
              let formatDescription else {
            return
        }

        // Tempo baseado no relógio do sistema
        let currentTime = CMClockGetTime(CMClockGetHostTimeClock())

        if startTime == nil {
            startTime = currentTime
        }

        guard let startTime else {
            return
        }

        let presentationTime =
            CMTimeSubtract(currentTime, startTime)

        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(
                value: 1,
                timescale: 30
            ),
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
              let sampleBuffer else {
            return
        }

        if displayLayer.isReadyForMoreMediaData {
            displayLayer.enqueue(sampleBuffer)
        }
    }

    func reset() {
        displayLayer.flush()
        startTime = nil
    }
}
